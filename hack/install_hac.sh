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

# hac-dev assumes you only have one project, so this installs one starting with aaaa- 
# to ensure it picks that as your default. 
kubectl apply -f $ROOT/hack/default-appstudio-namespace.yaml
 
REPO_PATH=argo-cd-apps/overlays/crc 
REPO=$(git ls-remote --get-url $MY_GIT_FORK_REMOTE | sed 's|^git@github.com:|https://github.com/|')
REVISION=$(git rev-parse --abbrev-ref HEAD)

# localize it 
yq '.spec.source.path="'$REPO_PATH'"' $ROOT/argo-cd-apps/app-of-apps/all-applications.yaml | \
      yq '.spec.source.repoURL="'$REPO'"' | \
      yq '.spec.source.targetRevision="'$REVISION'"' | \
      kubectl apply -f -

kubectl create secret docker-registry redhat-appstudio-staginguser-pull-secret --from-file=.dockerconfigjson="$ROOT/hack/nocommit/quay-io-auth.json" --dry-run=client -o yaml | \
kubectl apply -f - -n $SOUP_USER_NS
oc secrets link pipeline redhat-appstudio-staginguser-pull-secret --for=pull,mount
# switch to the correct single namespace 
oc project $SOUP_USER_NS
