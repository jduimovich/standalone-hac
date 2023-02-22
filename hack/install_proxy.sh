#!/bin/bash  
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"  
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/..
PROXY=$ROOT/../crc-k8s-proxy 

# echo "Proxy no longer installed separately" 
# exit 0

if [ -d $PROXY ]; then
  (cd $PROXY; bash run-util crc)
else
  echo "No proxy found in $PROXY" 
  echo "git clone  https://github.com/jduimovich/crc-k8s-proxy.git" 
  echo "into the parent directory ../crc-k8s-proxy"
  echo "and re-reun this script" 
  exit 1 
fi 