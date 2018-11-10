#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
TMPL_DIR=$(dirname $0)/../templates

echo "Setting up Sonarqube in project $GUID-sonarqube"

# add a sleep time to help use better the resources since the grade pipeline send the 5 setup project simmultaneously
#sleep 120


# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student
oc new-app -f ${TMPL_DIR}/hgp-sonarqube.yaml -n $GUID-sonarqube
oc rollout status dc/sonarqube -w -n $GUID-sonarqube
