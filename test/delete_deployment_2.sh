#!/bin/bash

kubectl delete deployment echo-server -n test2
kubectl delete deployment echo-client -n test2
