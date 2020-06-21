#!/usr/bin/env bash

cd ..

kubectl delete -f ./src/ns --insecure-skip-tls-verify=true 

