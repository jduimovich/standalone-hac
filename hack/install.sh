#!/bin/bash  
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"  
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/..

source $SCRIPTDIR/validate-access.sh 
 
# update for clowder to ignore minikube 
export KUBECTL_CMD=kubectl
$SCRIPTDIR/install_clowder.sh  
$SCRIPTDIR/preview.sh  
 
  