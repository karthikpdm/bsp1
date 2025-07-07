#!/bin/bash

# calico-node-userdata.sh
# Custom bootstrap script for EKS nodes with Calico optimization

set -o xtrace

# Set cluster variables
CLUSTER_NAME="${cluster_name}"
CLUSTER_ENDPOINT="${cluster_endpoint}"
CLUSTER_CA_DATA="${cluster_ca_data}"
BOOTSTRAP_ARGS="${bootstrap_arguments}"
NODE_ROLE="${node_role}"

# Update system packages
yum update -y

# Optimize for Calico networking
echo "Optimizing system for Calico CNI..."

# Set kernel parameters for Calico
cat <<EOF > /etc/sysctl.d/99-calico.conf
# Calico networking optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 300000
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-calico.conf

# Ensure required kernel modules are loaded
modprobe br_netfilter
modprobe overlay
modprobe iptable_nat
modprobe iptable_filter

# Make modules persistent
cat <<EOF > /etc/modules-load.d/calico.conf
br_netfilter
overlay
iptable_nat
iptable_filter
EOF

# Set up log rotation for CNI logs
cat <<EOF > /etc/logrotate.d/calico-cni
/var/log/calico/cni/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Create CNI log directory
mkdir -p /var/log/calico/cni

# Set MTU for AWS optimized networking
echo "MTU=1410" >> /etc/sysconfig/network

# Bootstrap the EKS node
/etc/eks/bootstrap.sh $CLUSTER_NAME $BOOTSTRAP_ARGS

# Add custom labels after node joins cluster
cat <<EOF > /opt/calico-label-node.sh
#!/bin/bash
# Wait for kubelet to be ready
while ! systemctl is-active --quiet kubelet; do
  echo "Waiting for kubelet to be active..."
  sleep 5
done

# Wait for node to register
sleep 30

# Get node name
NODE_NAME=\$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

# Apply Calico labels (backup in case Terraform labels don't apply)
/usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME kubernetes.io/os=linux --overwrite || true
/usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME projectcalico.org/operator-node-migration=migrated --overwrite || true

# Apply node role specific labels
case "${NODE_ROLE}" in
  "istio")
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME node-role=osdu-istio-keycloak --overwrite || true
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME workload-type=istio --overwrite || true
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME component=service-mesh --overwrite || true
    ;;
  "backend")
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME node-role=osdu-backend --overwrite || true
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME workload-type=database --overwrite || true
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME component=backend-services --overwrite || true
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME storage-optimized=true --overwrite || true
    ;;
  "frontend")
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME node-role=osdu-frontend --overwrite || true
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME workload-type=microservices --overwrite || true
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME component=osdu-apis --overwrite || true
    /usr/bin/kubectl --kubeconfig /var/lib/kubelet/kubeconfig label node \$NODE_NAME compute-optimized=true --overwrite || true
    ;;
esac

echo "Calico node labels applied successfully for role: ${NODE_ROLE}"
EOF

# Make script executable and run it in background
chmod +x /opt/calico-label-node.sh
nohup /opt/calico-label-node.sh > /var/log/calico-label-node.log 2>&1 &

echo "Calico-optimized EKS node bootstrap completed for role: ${NODE_ROLE}"