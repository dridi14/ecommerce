#!/bin/bash
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -xe

REPO_URL="${ansible_repo_url}"
REPO_BRANCH="${ansible_repo_branch}"
WORKDIR="/opt/greenleaf-infra"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git python3 python3-pip ansible
ansible --version

rm -rf "$WORKDIR"
git clone --branch "$REPO_BRANCH" "$REPO_URL" "$WORKDIR"

cd "$WORKDIR/ansible"

cat > inventory.ini <<'EOF'
[magento]
localhost ansible_connection=local
EOF

mkdir -p group_vars
cat > group_vars/all.yml <<EOF
magento_base_url: "${magento_base_url}"
magento_backend_frontname: "${magento_backend_frontname}"
magento_admin_email: "${magento_admin_email}"
magento_admin_firstname: "${magento_admin_firstname}"
magento_admin_lastname: "${magento_admin_lastname}"
magento_admin_username: "${magento_admin_username}"
magento_admin_password: "${magento_admin_password}"

db_host: "${db_host}"
db_name: "${db_name}"
db_username: "${db_username}"
db_password: "${db_password}"
EOF

ansible-playbook -i inventory.ini playbooks/site.yml
