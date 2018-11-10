#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

# add a sleep time to help use better the resources since the grade pipeline send the 5 setup project simmultaneously
#sleep 360

echo "Setting up user permissions on projects ${GUID}-parks-dev"
# Allow Jenkins to manipulate objects in Dev project
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev

# Allow Prod project to pull images from Dev project
oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev

# Default permissions
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev

echo "Setting up MongoDB Database in the project ${GUID}-parks-dev"
# Set up a MongoDB database in the development project + its configmap
oc new-app mongodb-persistent --name=mongodb -p MONGODB_USER=mongodb -p MONGODB_PASSWORD=mongodb -p MONGODB_DATABASE=parks -n ${GUID}-parks-dev
oc rollout status dc/mongodb -w -n ${GUID}-parks-dev
oc create configmap parksdb-conf -n ${GUID}-parks-dev \
       --from-literal=DB_HOST=mongodb \
       --from-literal=DB_PORT=27017 \
       --from-literal=DB_USERNAME=mongodb \
       --from-literal=DB_PASSWORD=mongodb \
       --from-literal=DB_NAME=parks


echo "Setting up MLBparks microservice in the project ${GUID}-parks-dev"
# MLBParks backend microservice
# Binary Build Config (+ imagestream)
oc new-build --binary=true --name=mlbparks jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
# Deployment config placeholder linked with previously created imagestream
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --allow-missing-imagestream-tags=true --name=mlbparks -l type=parksmap-backend -n ${GUID}-parks-dev
# Allowing only manual deployments (e.g. no auto-redeploy on config change)
oc set triggers dc/mlbparks --remove-all -n ${GUID}-parks-dev
# Exposing port
oc expose dc/mlbparks --port 8080 -n ${GUID}-parks-dev
# Probes
oc set probe dc/mlbparks --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev
oc set probe dc/mlbparks --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev
# ConfigMap
oc create configmap mlbparks-conf --from-literal=APPNAME="MLB Parks (Dev)" -n ${GUID}-parks-dev
# Configure Deployment Config based on ConfigMap
oc set env dc/mlbparks --from=configmap/parksdb-conf -n ${GUID}-parks-dev
oc set env dc/mlbparks --from=configmap/mlbparks-conf -n ${GUID}-parks-dev
# Post deployment hook to populate database once deployment strategy completes 
oc set deployment-hook dc/mlbparks --post -- curl -s http://mlbparks:8080/ws/data/load/ -n ${GUID}-parks-dev


echo "Setting up NationalParks microservice in the project ${GUID}-parks-dev"
# NationalParks backend microservice
# Binary Build Config
oc new-build --binary=true --name=nationalparks redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/nationalparks:0.0-0 --allow-missing-imagestream-tags=true --name=nationalparks -l type=parksmap-backend -n ${GUID}-parks-dev
oc set triggers dc/nationalparks --remove-all -n ${GUID}-parks-dev
oc expose dc/nationalparks --port 8080 -n ${GUID}-parks-dev
# Probes
oc set probe dc/nationalparks --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev
oc set probe dc/nationalparks --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev
# ConfigMap
oc create configmap nationalparks-conf --from-literal=APPNAME="National Parks (Dev)" -n ${GUID}-parks-dev
# Configure Deployment Config based on ConfigMap
oc set env dc/nationalparks --from=configmap/parksdb-conf -n ${GUID}-parks-dev
oc set env dc/nationalparks --from=configmap/nationalparks-conf -n ${GUID}-parks-dev
# Post deployment hook to populate database once deployment strategy completes -n ${GUID}-parks-dev
oc set deployment-hook dc/nationalparks --post -- curl -s http://nationalparks:8080/ws/data/load/ -n ${GUID}-parks-dev


echo "Setting up ParksMap microservice in the project ${GUID}-parks-dev"
# ParksMap frontend microservice
# Binary Build Config
oc new-build --binary=true --name=parksmap redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/parksmap:0.0-0 --allow-missing-imagestream-tags=true --name=parksmap -l type=parksmap-frontend -n ${GUID}-parks-dev
oc set triggers dc/parksmap --remove-all -n ${GUID}-parks-dev
oc expose dc/parksmap --port 8080 -n ${GUID}-parks-dev
# Probes
oc set probe dc/parksmap --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev
oc set probe dc/parksmap --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev
# ConfigMap
oc create configmap parksmap-conf --from-literal=APPNAME="ParksMap (Dev)" -n ${GUID}-parks-dev
# Configure Deployment Config based on ConfigMap
oc set env dc/parksmap --from=configmap/parksmap-conf -n ${GUID}-parks-dev
# Expose frontend service
oc expose svc/parksmap -n ${GUID}-parks-dev

