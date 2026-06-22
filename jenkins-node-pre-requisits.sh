#!/bin/bash

# Jenkins Node Configuration Script
# This script installs Java, OpenShift CLI (oc), configures certificates for GitLab access,
# and sets up SSH key authentication

set -e  # Exit on any error
set -u  # Exit on undefined variables

echo "########### Jenkins Node Configuration Started ###########"
echo ""

# Instll Docker and Git
echo "===== Installing Docker and Git ====="
sudo dnf install docker git -y
docker --version
git --version
echo "✓ docker and git installed successfully"
echo ""

# Install Java 17
echo "===== Installing Java 17 ====="
sudo dnf install -y java-17-openjdk
java --version
echo "✓ Java installed successfully"
echo ""

# Install OpenShift CLI (oc)
echo "===== Installing OpenShift CLI (oc) ====="
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux-ppc64le.tar.gz
tar -xzf openshift-client-linux-ppc64le.tar.gz
sudo mv oc /usr/local/bin/
sudo mv kubectl /usr/local/bin/
sudo chmod +x /usr/local/bin/oc /usr/local/bin/kubectl
rm -f openshift-client-linux-ppc64le.tar.gz  # Clean up downloaded archive
oc version
echo "✓ OpenShift CLI installed successfully"
echo ""

# Configure certificates for GitLab
echo "===== Configuring Certificates for GitLab ====="
echo "Fetching certificate chain from gitlab.cee.redhat.com..."
openssl s_client -showcerts -connect gitlab.cee.redhat.com:443 </dev/null 2>/dev/null | \
    awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > gitlab-chain.pem

echo "Splitting certificate chain..."
csplit -f cert- gitlab-chain.pem '/-----BEGIN CERTIFICATE-----/' '{*}' 2>/dev/null || true

echo "Installing root and intermediate certificates..."
if [ -f cert-03 ]; then
    sudo cp cert-03 /etc/pki/ca-trust/source/anchors/redhat-internal-root-ca.crt
    sudo update-ca-trust extract
    echo "✓ Root certificate installed"
fi

if [ -f cert-02 ]; then
    sudo cp cert-02 /etc/pki/ca-trust/source/anchors/redhat-rhcsv2-intermediate.crt
    sudo update-ca-trust extract
    echo "✓ Intermediate certificate installed"
fi

# Clean up certificate files
rm -f gitlab-chain.pem cert-*

echo "Verifying GitLab access..."
if curl -s -o /dev/null -w "%{http_code}" https://gitlab.cee.redhat.com | grep -q "200\|301\|302"; then
    echo "✓ GitLab access verified successfully"
else
    echo "⚠ Warning: GitLab access verification returned unexpected status"
fi
echo ""

# Configure SSH key authentication
echo "===== Configuring SSH Key Authentication ====="
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    echo "✓ Created .ssh directory"
fi

# Prompt for public SSH key
echo "Please paste your public SSH key (or press Ctrl+D to skip):"
read -r PUBLIC_KEY

if [ -n "$PUBLIC_KEY" ]; then
    # Add the public key to authorized_keys
    echo "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
    echo "✓ SSH public key added to authorized_keys"
else
    echo "⚠ No SSH key provided, skipping SSH configuration"
fi
echo ""

echo "########### Jenkins Node Configuration Completed Successfully ###########"

