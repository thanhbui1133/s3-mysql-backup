#!/bin/bash
NAME=credentials ./create-file-secret.sh credentials
NAME=s3-mysql-backup ./create-env-secret.sh .env
oc create -f openshift.yaml