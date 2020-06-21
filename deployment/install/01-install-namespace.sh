#!/usr/bin/env bash

cd ..

oc apply -f ./src/ns --validate=false --insecure-skip-tls-verify=true 

# kubectl annotate --overwrite namespace service-discovery3-chn-ns mcm.ibm.com/accountID='46b0-718d' --insecure-skip-tls-verify=true
# kubectl annotate --overwrite namespace service-discovery3-app-ns mcm.ibm.com/accountID='46b0-718d' --insecure-skip-tls-verify=true
