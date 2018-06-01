#!/bin/bash
NAME=credentials ./create-file-secret.sh credentials
NAME=config ./create-file-secret.sh config
oc create -f openshift.yaml