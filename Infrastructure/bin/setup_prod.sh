#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
TMPL_DIR=$(dirname $0)/../templates

echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student


echo "Setting up MongoDb Database Cluster in project ${GUID}-parks-prod"
# Config MongoDB configmap
oc -n ${GUID}-parks-prod create configmap parksdb-conf \
       --from-literal=DB_REPLICASET=rs0 \
       --from-literal=DB_HOST=mongodb \
       --from-literal=DB_PORT=27017 \
       --from-literal=DB_USERNAME=mongodb \
       --from-literal=DB_PASSWORD=mongodb \
       --from-literal=DB_NAME=parks

# Setup replicated MongoDB from templates + configure it via ConfigMap
oc -n ${GUID}-parks-prod new-app -f ${TMPL_DIR}/mongodb.yaml -p MONGO_CONFIGMAP_NAME=parksdb-conf
# oc -n ${GUID}-parks-prod rollout status sts/mongodb -w
echo -n "Checking if replicated MongoDB is ready "
while : ; do
  oc get pod -n ${GUID}-parks-prod|grep '\-2'|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo -n "."
  sleep 5
done
echo " [done]


