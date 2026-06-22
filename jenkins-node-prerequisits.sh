#!/bin/bash

echo "########### 'Jenkins Node configuration started' ##########"

echo " -----Installing Java -----"
sh ' sudo dnf install java-17-openjdk'
sh 'java --version'
echo "-----Java installed successfully-----"


echo " ----- Installing OC -----"
sh 'curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux-ppc64le.tar.gz'
sh 'tar -xzf openshift-client-linux-ppc64le*.tar.gz'
sh 'sudo mv oc /usr/local/bin/'
sh 'sudo mv kubectl /usr/local/bin/'
sh 'sudo chmod +x /usr/local/bin/oc /usr/local/bin/kubectl'
sh 'oc version'
echo "-----OC installed successfully-----"

echo "Cert update for https://gitlab.cee.redhat.com"
sh 'openssl s_client -showcerts -connect gitlab.cee.redhat.com:443 </dev/null 2>/dev/null | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > gitlab-chain.pem'
sh 'csplit -f cert- gitlab-chain.pem \'/-----BEGIN CERTIFICATE-----/\' \'{*}\''
sh 'sudo cp cert-03 /etc/pki/ca-trust/source/anchors/redhat-internal-root-ca.crt'
sh 'sudo update-ca-trust extract'
sh 'sudo cp cert-02 /etc/pki/ca-trust/source/anchors/redhat-rhcsv2-intermediate.crt'
sh 'sudo update-ca-trust extract'
echo "verifying access - https://gitlab.cee.redhat.com"
sh 'curl https://gitlab.cee.redhat.com'
echo "Certificate config done"

echo "########### 'Jenkins Node configuration done' ##########"





