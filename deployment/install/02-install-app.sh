#!/usr/bin/env bash

cd ..

oc apply -f ./src/app --validate=false --insecure-skip-tls-verify=true 

