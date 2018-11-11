#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3

#Set the dir name of the templates to use
TMPL_DIR=$(dirname $0)/../templates

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student


#Setting up Jenkins project base on Jenkins Template build on the course with Pavel
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# add a sleep time to help use better the resources since the grade pipeline send the 5 setup project simmultaneously
#sleep 240

oc new-app -f ${TMPL_DIR}/hgp-jenkins.yaml -n $GUID-jenkins
oc rollout status dc/jenkins -w -n $GUID-jenkins

echo "Configuring Jenkins Slave Maven"
oc new-app -f ${TMPL_DIR}/hgp-jenkins-configmap.yaml --param GUID=${GUID} -n ${GUID}-jenkins

#Setting up jenkins pipelines on Openshift 
echo "Creating and configuring Build Configs for 3 pipelines"
oc new-build ${REPO} --name="mlbparks-pipeline" --strategy=pipeline --context-dir="MLBParks" -n $GUID-jenkins
oc set env bc/mlbparks-pipeline CLUSTER=${CLUSTER} GUID=${GUID} -n $GUID-jenkins

oc new-build ${REPO} --name="nationalparks-pipeline" --strategy=pipeline --context-dir="Nationalparks" -n $GUID-jenkins
oc set env bc/nationalparks-pipeline CLUSTER=${CLUSTER} GUID=${GUID} -n $GUID-jenkins

oc new-build ${REPO} --name="parksmap-pipeline" --strategy=pipeline --context-dir="ParksMap" -n $GUID-jenkins
oc set env bc/parksmap-pipeline CLUSTER=${CLUSTER} GUID=${GUID} -n $GUID-jenkins

#Delete the empty build created by default
sleep 10
oc delete build/mlbparks-pipeline-1 -n $GUID-jenkins
oc delete build/nationalparks-pipeline-1 -n $GUID-jenkins
oc delete build/parksmap-pipeline-1 -n $GUID-jenkins
