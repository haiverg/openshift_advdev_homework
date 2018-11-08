#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student
oc patch route mlbparks -p '{"spec":{"to":{"name":"mlbparks-green"}}}' -n ${GUID}-parks-prod || echo "mlbparks is already green"
oc patch route nationalparks  -p '{"spec":{"to":{"name":"nationalparks-green"}}}' -n ${GUID}-parks-prod || echo "nationalparks is already green"
oc patch route parksmap  -p '{"spec":{"to":{"name":"parksmap-green"}}}' -n ${GUID}-parks-prod || echo "parksmap is already green"


