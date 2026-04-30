#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./qdel.sh <start_job_id>"
    echo "Example: ./qdel.sh 80000"
    exit 1
fi

ini_id=$1

for ((i=0 ; i<200; i++))
do 
    qdel $((ini_id+i))
done
