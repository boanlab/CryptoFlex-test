#!/bin/bash
kubectl apply -f ./deployment/client_depl.yaml -n test
kubectl apply -f ./deployment/server_service.yaml -n test
kubectl apply -f ./deployment/server_depl.yaml -n test
