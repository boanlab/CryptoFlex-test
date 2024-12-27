#!/bin/bash

# set default
if [ "$CNI" == "" ]; then
    echo "Usage: CNI={flannel|weave|calico|cilium} $0"
    exit
fi

# check supported CNI
if [ "$CNI" != "flannel" ] && [ "$CNI" != "weave" ] && [ "$CNI" != "calico" ] && [ "$CNI" != "cilium" ]; then
    echo "Usage: CNI={flannel|weave|calico|cilium} $0"
    exit
fi

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/calico.yaml
