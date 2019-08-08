${KEY_FILENAME}#!/bin/sh
set -e
# HOME=/github/workspace
SSH_PATH="/root/.ssh"
KEY_FILENAME="id_rsa"
mkdir -p "${SSH_PATH}/.ssh"
chmod 700 "${SSH_PATH}/.ssh"

if [ "$DEPLOY_KEY_PRIVATE" = "" ]
then
   echo "DEPLOY_KEY_PRIVATE Does not exist"
   exit 1
fi

if [ "$DEPLOY_KEY_PUBLIC" = "" ]
then
   echo "DEPLOY_KEY_PUBLIC Does not exist"
   exit 1
fi

printf "%s" "$DEPLOY_KEY_PRIVATE" > "${SSH_PATH}/.ssh/${KEY_FILENAME}"
chmod 600 "${SSH_PATH}/.ssh/${KEY_FILENAME}"
wc -c "${SSH_PATH}/.ssh/${KEY_FILENAME}"

printf "%s" "$DEPLOY_KEY_PUBLIC" > "${SSH_PATH}/.ssh/${KEY_FILENAME}.pub"
chmod 644 "${SSH_PATH}/.ssh/${KEY_FILENAME}.pub"
wc -c "${SSH_PATH}/.ssh/${KEY_FILENAME}.pub"

echo -e "Host github.com\n\tIdentityFile ~/.ssh/${KEY_FILENAME}\n\tStrictHostKeyChecking no\n\tAddKeysToAgent yes\n" >> "${SSH_PATH}/.ssh/config"
chmod 644 "${SSH_PATH}/.ssh/config"

eval "$(ssh-agent)"
ssh-add "${SSH_PATH}/.ssh/${KEY_FILENAME}"

ssh-keyscan github.com > "${SSH_PATH}/.ssh/known_hosts"
chmod 644 "${SSH_PATH}/.ssh/known_hosts"
# Debug ssh:
set +e
ssh -o "IdentitiesOnly=yes" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i "${SSH_PATH}/.ssh/${KEY_FILENAME}" -F /dev/null -Tv git@github.com
set -e
echo "set git"
git config --global user.email "$EMAIL"
git config --global user.name "$GITHUB_ACTOR"
git config --global core.sshCommand 'ssh -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa -F /dev/null'


cd $GITHUB_WORKSPACE
ls -la "${SSH_PATH}/.ssh"
printf "\033[0;32mSubmodule Safety Engaged...\033[0m\n"
git submodule sync --recursive && git submodule update --init --recursive
printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"


hugo

# Go To Public folder
cd public

# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master
printf "\033[0;32mDone for now\033[0m\n"
