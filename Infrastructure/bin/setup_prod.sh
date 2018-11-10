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

# add a sleep time to help use better the resources since the grade pipeline send the 5 setup project simmultaneously
#sleep 480

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student


echo "Setting up user permissions in project ${GUID}-parks-prod"
# Allow Jenkins to manipulate objects in Prod project
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod
# Default permissions
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-prod

echo "Setting up MongoDb Database Cluster in project ${GUID}-parks-prod"
# Config MongoDB configmap
oc create configmap parksdb-conf -n ${GUID}-parks-prod \
       --from-literal=DB_REPLICASET=rs0 \
       --from-literal=DB_HOST=mongodb \
       --from-literal=DB_PORT=27017 \
       --from-literal=DB_USERNAME=mongodb \
       --from-literal=DB_PASSWORD=mongodb \
       --from-literal=DB_NAME=parks

# Setup replicated MongoDB from templates + configure it via ConfigMap
oc new-app -f ${TMPL_DIR}/hgp-mongodb.yaml -p MONGO_CONFIGMAP_NAME=parksdb-conf -n ${GUID}-parks-prod
# oc rollout status sts/mongodb -w -n ${GUID}-parks-prod
echo -n "Checking if replicated MongoDB is ready "
while : ; do
  oc get pod -n ${GUID}-parks-prod|grep '\-2'|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo -n "."
  sleep 5
done
echo " [done]"

echo "Configuring MLB Parks backend microservice (Blue) in project ${GUID}-parks-prod"
# Configuring MLB Parks backend microservice (Blue)
oc new-app ${GUID}-parks-dev/mlbparks:0.0 --allow-missing-images=true --allow-missing-imagestream-tags=true --name=mlbparks-blue -l type=parksmap-backend -n ${GUID}-parks-prod
oc set triggers dc/mlbparks-blue --remove-all -n ${GUID}-parks-prod
oc expose dc/mlbparks-blue --port 8080 -n ${GUID}-parks-prod
oc set probe dc/mlbparks-blue --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc set probe dc/mlbparks-blue --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc create configmap mlbparks-blue-conf --from-literal=APPNAME="MLB Parks (Blue)" -n ${GUID}-parks-prod
oc set env dc/mlbparks-blue --from=configmap/mlbparks-blue-conf -n ${GUID}-parks-prod
oc set env dc/mlbparks-blue --from=configmap/parksdb-conf -n ${GUID}-parks-prod
oc set deployment-hook dc/mlbparks-blue --post -- curl -s http://mlbparks-blue:8080/ws/data/load/ -n ${GUID}-parks-prod

echo " # Configuring MLB Parks backend microservice (Green) in project ${GUID}-parks-prod"
# Configuring MLB Parks backend microservice (Green)
oc new-app ${GUID}-parks-dev/mlbparks:0.0 --allow-missing-images=true --allow-missing-imagestream-tags=true --name=mlbparks-green -l type=parksmap-backend-reserve -n ${GUID}-parks-prod
oc set triggers dc/mlbparks-green --remove-all -n ${GUID}-parks-prod
oc expose dc/mlbparks-green --port 8080 -n ${GUID}-parks-prod
oc set probe dc/mlbparks-green --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc set probe dc/mlbparks-green --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc create configmap mlbparks-green-conf --from-literal=APPNAME="MLB Parks (Green)" -n ${GUID}-parks-prod
oc set env dc/mlbparks-green --from=configmap/mlbparks-green-conf -n ${GUID}-parks-prod
oc set env dc/mlbparks-green --from=configmap/parksdb-conf -n ${GUID}-parks-prod
oc set deployment-hook dc/mlbparks-green --post -- curl -s http://mlbparks-green:8080/ws/data/load/ -n ${GUID}-parks-prod


echo "Configuring National Parks backend microservice (Blue)in project ${GUID}-parks-prod"
# Configuring National Parks backend microservice (Blue)
oc new-app ${GUID}-parks-dev/nationalparks:0.0 --allow-missing-images=true --allow-missing-imagestream-tags=true --name=nationalparks-blue -l type=parksmap-backend -n ${GUID}-parks-prod
oc set triggers dc/nationalparks-blue --remove-all -n ${GUID}-parks-prod
oc expose dc/nationalparks-blue --port 8080 -n ${GUID}-parks-prod
oc set probe dc/nationalparks-blue --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc set probe dc/nationalparks-blue --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc create configmap nationalparks-blue-conf --from-literal=APPNAME="National Parks (Blue)" -n ${GUID}-parks-prod
oc set env dc/nationalparks-blue --from=configmap/nationalparks-blue-conf -n ${GUID}-parks-prod
oc set env dc/nationalparks-blue --from=configmap/parksdb-conf -n ${GUID}-parks-prod
oc set deployment-hook dc/nationalparks-blue --post -- curl -s http://nationalparks-blue:8080/ws/data/load/ -n ${GUID}-parks-prod


echo "Configuring National Parks backend microservice (Green) in project ${GUID}-parks-prod"
# Configuring National Parks backend microservice (Green)
oc new-app ${GUID}-parks-dev/nationalparks:0.0 --allow-missing-images=true --allow-missing-imagestream-tags=true --name=nationalparks-green -l type=parksmap-backend-reserve -n ${GUID}-parks-prod
oc set triggers dc/nationalparks-green --remove-all -n ${GUID}-parks-prod
oc expose dc/nationalparks-green --port 8080 -n ${GUID}-parks-prod
oc set probe dc/nationalparks-green --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc set probe dc/nationalparks-green --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc create configmap nationalparks-green-conf --from-literal=APPNAME="National Parks (Green)" -n ${GUID}-parks-prod
oc set env dc/nationalparks-green --from=configmap/nationalparks-green-conf -n ${GUID}-parks-prod
oc set env dc/nationalparks-green --from=configmap/parksdb-conf -n ${GUID}-parks-prod
oc set deployment-hook dc/nationalparks-green --post -- curl -s http://nationalparks-green:8080/ws/data/load/ -n ${GUID}-parks-prod


echo "Configuring Parks Map frontend microservice (Blue) in project ${GUID}-parks-prod"
# Configuring Parks Map frontend microservice (Blue)
oc new-app ${GUID}-parks-dev/parksmap:0.0 --allow-missing-images=true --allow-missing-imagestream-tags=true --name=parksmap-blue -l type=parksmap-frontend -n ${GUID}-parks-prod
oc set triggers dc/parksmap-blue --remove-all -n ${GUID}-parks-prod
oc expose dc/parksmap-blue --port 8080 -n ${GUID}-parks-prod
oc set probe dc/parksmap-blue --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc set probe dc/parksmap-blue --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc create configmap parksmap-blue-conf --from-literal=APPNAME="ParksMap (Blue)" -n ${GUID}-parks-prod
oc set env dc/parksmap-blue --from=configmap/parksmap-blue-conf -n ${GUID}-parks-prod


echo " Configuring Parks Map frontend microservice (Green) in project ${GUID}-parks-prod"
# Configuring Parks Map frontend microservice (Green)
oc new-app ${GUID}-parks-dev/parksmap:0.0 --allow-missing-images=true --allow-missing-imagestream-tags=true --name=parksmap-green -l type=parksmap-frontend -n ${GUID}-parks-prod
oc set triggers dc/parksmap-green --remove-all -n ${GUID}-parks-prod
oc expose dc/parksmap-green --port 8080 -n ${GUID}-parks-prod
oc set probe dc/parksmap-green --readiness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc set probe dc/parksmap-green --liveness --initial-delay-seconds 30 --failure-threshold 3 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod
oc create configmap parksmap-green-conf --from-literal=APPNAME="ParksMap (Green)" -n ${GUID}-parks-prod
oc set env dc/parksmap-green --from=configmap/parksmap-green-conf -n ${GUID}-parks-prod

echo "Exposing services in Green Deployment in project ${GUID}-parks-prod"
# Expose services
oc expose svc/parksmap-green --name parksmap -n ${GUID}-parks-prod
oc expose svc/mlbparks-green --name mlbparks -n ${GUID}-parks-prod
oc expose svc/nationalparks-green --name nationalparks -n ${GUID}-parks-prod

