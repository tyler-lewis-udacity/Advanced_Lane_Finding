#!/bin/bash

# This script will activate the P4 conda environment and launch 
# the P4_advanced_lane_finding.ipynb jupyter notebook:

cd "/home/ty/Udacity/T1/P4_advanced_lane_finding"
source "/home/ty/anaconda3/bin/activate" P4
jupyter notebook P4_advanced_lane_finding.ipynb

