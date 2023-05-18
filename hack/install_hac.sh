#!/bin/bash  
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"  
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/..

if [ "$(oc auth can-i '*' '*' --all-namespaces)" != "yes" ]; then
  echo
  echo "[ERROR] User '$(oc whoami)' does not have the required 'cluster-admin' role." 1>&2
  echo "Log into the cluster with a user with the required privileges (e.g. kubeadmin) and retry."
  exit 1
fi 
 
QUAY_IO_KUBESECRET=$ROOT/hack/nocommit/my-secret.yml

if [ -n "$QUAY_IO_KUBESECRET" ]; then
    TMP_QUAY=$(mktemp)
    cp $QUAY_IO_KUBESECRET $TMP_QUAY
    yq e -i '.metadata.name = "quay-cloudservices-pull"' $TMP_QUAY
    if ! kubectl get namespace boot &>/dev/null; then
      kubectl create namespace boot
    fi
    if kubectl get secret quay-cloudservices-pull --namespace=boot &>/dev/null; then
      kubectl delete secret quay-cloudservices-pull --namespace=boot
    fi 
    kubectl create -f $TMP_QUAY --namespace=boot
    rm $TMP_QUAY
fi
 
REPO_PATH=argo-cd-apps/overlays/crc 
REPO=$(git ls-remote --get-url $MY_GIT_FORK_REMOTE | sed 's|^git@github.com:|https://github.com/|')
REVISION=$(git rev-parse --abbrev-ref HEAD)

# localize it 
yq '.spec.source.path="'$REPO_PATH'"' $ROOT/argo-cd-apps/app-of-apps/all-applications.yaml | \
      yq '.spec.source.repoURL="'$REPO'"' | \
      yq '.spec.source.targetRevision="'$REVISION'"' | \
      kubectl apply -f -


echo "Note: Increasing the Quota for PVC to 100 (run more pipelines) and Routes to 32 (more applications)"
oc patch ResourceQuota/storage -n $SOUP_USER_NS --type merge -p \
  '{"spec":{"hard":{"count/persistentvolumeclaims": "100" }}}'
oc patch clusterresourcequota/for-$SOUP_USER-routes --type merge -p  \
  '{"spec":{"quota":{"hard":{"count/ingresses.extensions": "32" }}}}'
oc patch clusterresourcequota/for-$SOUP_USER-routes --type merge -p  \
  '{"spec":{"quota":{"hard":{"count/routes.route.openshift.io": "32" }}}}'
  
kubectl create secret docker-registry redhat-appstudio-staginguser-pull-secret --from-file=.dockerconfigjson="$ROOT/hack/nocommit/quay-io-auth.json" --dry-run=client -o yaml | \
kubectl apply -f - -n $SOUP_USER_NS
oc secrets link appstudio-pipeline redhat-appstudio-staginguser-pull-secret --for=pull,mount
# switch to the correct single namespace 
oc project $SOUP_USER_NS
