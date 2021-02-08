#!/bin/bash
if [ -z "$BUILDID" ]
then
cp "/home/gitlabci/bitstreams/${CI_PROJECT_PATH_SLUG}/${CI_COMMIT_SHORT_SHA}.bit" main.bit
else
cp "/home/gitlabci/bitstreams/${CI_PROJECT_PATH_SLUG}/${BUILDID}.bit" main.bit
fi
env LC_ALL=en_US.utf8 /opt/Xilinx/Vivado/2018.2/bin/vivado -mode batch -source program.tcl
