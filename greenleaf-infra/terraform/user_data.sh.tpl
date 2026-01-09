#!/bin/bash
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -xe

REPO_URL="${ansible_repo_url}"
REPO_BRANCH="${ansible_repo_branch}"

WORKROOT="/opt"
REPODIR="greenleaf-infra"
WORKDIR="$WORKROOT/$REPODIR/$REPODIR"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git python3 python3-pip ansible
ansible --version

rm -rf "$WORKROOT/$REPODIR"
git clone --branch "$REPO_BRANCH" "$REPO_URL" "$WORKROOT/$REPODIR"

if [ ! -d "$WORKDIR/ansible" ]; then
  echo "ERROR: $WORKDIR/ansible not found"
  find "$WORKROOT/$REPODIR" -maxdepth 3 -type d -print
  exit 1
fi

cd "$WORKDIR/ansible"


cat > inventory.ini <<'EOF'
[magento]
localhost ansible_connection=local
EOF

mkdir -p group_vars
set +x
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

magento_public_key: "${magento_public_key}"
magento_private_key: "${magento_private_key}"

opensearch_host: "${opensearch_host}"
opensearch_port: "${opensearch_port}"
EOF
set -x

cat > ansible.cfg <<EOF
[defaults]
roles_path = ./roles:./playbooks/roles:./playbooks
EOF

ansible-playbook -i inventory.ini playbooks/site.yml
