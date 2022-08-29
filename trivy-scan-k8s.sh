#!/bin/bash

echo $imageName # Getting image name from env variable

docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 0 --severity LOW,MEDIUM,HIGH --light $imageName
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 1 --severity CRITICAL --light $imageName

     #TRIVY SCAN RESULT PROCESSING
     exit_code=$?
     echo "Exit Code : $exit_code"

     #CHECK SCAN RESULTS
     if [[ ${exit_code} == 1 ]]; then
          echo "Image scanning failed. Vulnerabilities found"
          exit 1;
     else
          echo "Image scanning Passed. No Vulnerabilities found"
     fi