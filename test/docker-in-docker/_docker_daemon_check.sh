#!/bin/bash

# Try 'docker ps' up to 5 times, waiting 2 seconds between each attempt
attempts=5
delay=2
for i in $(seq 1 $attempts); do
    if docker ps > /dev/null 2>&1; then
        echo "Docker daemon started successfully."
        exit 0
    elif [ "$i" -eq $attempts ]; then
        echo "Failed to connect to Docker daemon after $attempts attempts"
        exit 1
    else
        sleep $delay
    fi
done