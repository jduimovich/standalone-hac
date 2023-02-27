#!/bin/bash -e
set -o pipefail

# call this script prior to validate the configuration 
# for new things, place in this script
# this script must be run as source validate-access.sh as it will set and configure
# automatic shell vars (SOUP_USER, SOUP_USER_NS, SOUP_HOSTNAME)

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"  
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/..

if [ "$(oc auth can-i '*' '*' --all-namespaces)" != "yes" ]; then
  echo
  echo "[ERROR] User '$(oc whoami)' does not have the required 'cluster-admin' role." 1>&2
  echo "Log into the cluster with a user with the required privileges (e.g. kubeadmin) and retry."
  exit 1
fi

# TODO: We can compute this user name  
export SOUP_USER=user1
export SOUP_USER_NS=$SOUP_USER-tenant
oc get ns $SOUP_USER_NS > /dev/null 2>&1
ERR=$? 
if [ $ERR != 0 ] ; then
  echo 
  echo "[ERROR] Missing $SOUP_USER_NS, you need to goto the registration page and login."
  echo "This will create the proper user and namespace for this install to continue."
  echo 
  echo "https://"$(kubectl get routes -n toolchain-host-operator registration-service -o jsonpath={.spec.host})
  echo 
  echo "Tips: If you see errors on this page, you may be having CERT/TLS errors from untrusted servers."
  echo "Click on the following URL(s), and approve the access to the site"
  echo
  echo "- https://"$(kubectl get routes -n toolchain-host-operator registration-service -o jsonpath={.spec.host})"/landingpage.js"
  echo "- https://"$(kubectl get routes -n dev-sso keycloak -o jsonpath={.spec.host})"/auth/js/keycloak.js"
  echo 
  exit
else  
  echo 
  echo "[INFO] $SOUP_USER and namespace $SOUP_USER_NS" is present
fi   

if [ -z "$SOUP_HOSTNAME" ]; then
    echo "[INFO] SOUP_HOSTNAME is not set so will be computed if possible."
    IS_CRC_DOMAIN=$(kubectl get ingresses.config.openshift.io cluster -o jsonpath={".spec.domain"})
    if [ "$IS_CRC_DOMAIN" == "apps-crc.testing" ]; then 
        export SOUP_HOSTNAME="env-boot-local-127-0-0-1.nip.io"  
    else 
        export SOUP_HOSTNAME="hac.$IS_CRC_DOMAIN"   
    fi 
    if nslookup  $SOUP_HOSTNAME  >/dev/null 2>&1; then
        echo "[INFO] Computed SOUP_HOSTNAME=$SOUP_HOSTNAME is a valid DNS address."
    else 
        echo "[ERROR] $SOUP_HOSTNAME fails nslookup, exiting because this install will not succeed"
        echo "If you want to uses this name regardless, set SOUP_HOSTNAME and re-run"
        echo "export SOUP_HOSTNAME=$SOUP_HOSTNAME"   
        exit
    fi
fi    
 
