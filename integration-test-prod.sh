#!/bin/bash

sleep 5s

PORT=80

echo $PORT
echo $applicationURLProd:$PORT$applicationURI

if [[ ! -z "$PORT" ]];
then

    responce=$(curl -s $applicationURLProd:$PORT$applicationURI)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" $applicationURLProd:$PORT$applicationURI)

    if [[ "$responce" == 100 ]];
        then
            echo  "Increment test Passed"
        else
            echo  "Increment test Failed"
            exit 1;
    fi

    if [[ "$http_code" == 200 ]];
        then
            echo "HTTP status code test Passed"
        else
            echo "HTTP status code is not 200"
            exit 1;
    fi
else
        echo "The service has issues"
        exit 1;
fi