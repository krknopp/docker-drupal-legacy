#!/bin/bash

# Need env vars:
# CONF_REPO
# CONF_REPO_BRANCH

# Clone CONF_REPO to /root/config-repo
mkdir -p /root/config-repo
git clone -b CONF_REPO $CONF_REPO /root/config-repo

grep -q -F 'config-repo"' /root/cronts.conf || echo "*/15 * * * * . /root/project_env.sh; cd /root/config-repo && git pull origin $CONF_REPO_BRANCH"

if [[ -e /root/config-repo/000-default.conf ]] ; then
  cp /root/config-repo/000-default.conf /etc/apache2/sites-enabled/000-default.conf
fi

if [[ -e /root/config-repo/php.ini ]] ; then
  cp /root/config-repo/php.ini /etc/php5/fpm/php.ini
  supervisorctl restart php-fpm
fi
