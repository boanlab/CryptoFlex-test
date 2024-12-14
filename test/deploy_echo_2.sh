#!/bin/bash
kubectl apply -f ./deployment/client2_depl.yaml -n test2
kubectl apply -f ./deployment/server2_service.yaml -n test2
kubectl apply -f ./deployment/server2_depl.yaml -n test2
