#!/bin/bash

set -eo pipefail

#####################################
# Tests executed against simulation #
#####################################

# Kill background simulation on exit
trap 'echo "Stop simulation!" ; kill $(ps --ppid $$ -o pid= -n )' EXIT SIGTERM

echo -e "\033[94m##### Executing Integration Tests against Simulation #####\033[0m"

echo "Start simulation!"
make trace.ghw > /dev/null 2>&1 &
t=$!

#Build time for simulation
sleep 10

echo "Start test!"
python3 connector/full_test.py simulation
