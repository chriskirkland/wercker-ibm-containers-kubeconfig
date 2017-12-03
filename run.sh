#!/bin/bash

# environment variables
if [ -z "${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLUSTER_NAME}" ]; then
  fail "ic-cluster-name cannot be empty. run \`bx cs clusters\` to find a valid cluster name."
fi

if [ -z "${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_CLI_VERSION}" ]; then
  fail "ic-cli-version cannot be empty. valid options are \"latest\" or semver (i.e. 0.3.2). See https://console.bluemix.net/docs/cli/reference/bluemix_cli/all_versions.html for available options."
fi

if [ -z "${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLI_VERSION}" ]; then
  fail "ic-cli-version cannot be empty. valid options are \"latest\" or semver (i.e. 0.3.2)"
fi

if [ -z "${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_USERNAME}" ]; then
  fail "bx-username is required and must not be empty"
fi

if [ -n "${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_ORG_NAME}" ] && [ -n "${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_SPACE_NAME}" ]; then
  BX_TARGET="-o ${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_ORG_NAME} -s ${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_SPACE_NAME}"
fi

BX_LOGIN_CREDENTIALS="-u ${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_USERNAME}"
if [ -n "${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_PASSWORD}" ]; then
  BX_LOGIN_CREDENTIALS="${BX_LOGIN_CREDENTIALS} -p ${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_PASSWORD}"
elif [ -n "${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_API_KEY}" ]; then
  BX_LOGIN_CREDENTIALS="${BX_LOGIN_CREDENTIALS} --apikey ${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_API_KEY}"
else
  fail "either bx-password (\$BLUEMIX_PASSWORD) or bx-api-key (\$BLUEMIX_API_KEY) must be specified."
fi

if [ -n "${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLI_VERSION}" ]; then
  IC_CLI_VERSION_FLAG="-v ${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLI_VERSION}"
fi

if [ -n "${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_ADMIN_KUBECONFIG}" ]; then
  IC_ADMIN_FLAG="--admin"
fi

# install bluemix cli
wget -O Bluemix_CLI.tar.gz https://clis.ng.bluemix.net/download/bluemix-cli/${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLI_VERSION}/linux64
tar -xvf Bluemix_CLI.tar.gz
cd Bluemix_CLI
./install_bluemix_cli

# login to bluemix cli
bx login -a ${WERCKER_IBM_CONTAINERS_KUBECONFIG_BX_URL} ${BX_TARGET} ${BX_LOGIN_CREDENTIALS}

# install ibm containers cli
bx plugin install containers-service -r Bluemix ${IC_CLI_VERSION_FLAG}

# get kubeconfig
bx cs cluster-config ${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLUSTER_NAME} ${IC_ADMIN_FLAG}

# export kubeconfig
DATACENTER=$(bx cs cluster-get ${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLUSTER_NAME} | grep "^Datacenter:" | awk '{ print $2 }')
export KUBECONFIG=$(readlink -f ~/.bluemix/plugins/container-service/clusters/${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLUSTER_NAME}/kube-config-${DATACENTER}-${WERCKER_IBM_CONTAINERS_KUBECONFIG_IC_CLUSTER_NAME}.yml)
