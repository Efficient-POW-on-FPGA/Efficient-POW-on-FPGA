#!/bin/bash

set -eo pipefail

###################################
# Tests executed after deployment #
###################################

echo -e "\033[94m##### Executing Integration Tests against FPGA #####\033[0m"

echo -e "\033[36m##### Test all cores! #####\033[0m"
python3 connector/full_test.py fpga

echo -e "\033[36m##### Performance test #####\033[0m"
python3 connector/cli.py count
