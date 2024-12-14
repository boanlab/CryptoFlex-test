#!/bin/bash

POD_NAME=${POD_NAME}
NAMESPACE=${NAMESPACE}

# 파드 이름과 네임스페이스가 설정되어 있는지 확인
if [[ -z "$POD_NAME" || -z "$NAMESPACE" ]]; then
  echo "Usage: POD_NAME=<pod-name> NAMESPACE=<namespace> ./script.sh"
  exit 1
fi

# get pod ip from k8s cluster
POD_IP=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.podIP}')

TIMESTAMP=$(date %m%d%H%M)
FILENAME="./${TIMESTAMP}_${POD_NAME}_${NAMESPACE}.pcap"

# execute tcpdump
sudo tcpdump -i any '(src '$POD_IP' or dst '$POD_IP')' -w $FILENAME

