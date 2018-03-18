#!/bin/bash
set -vx

date_text=`date '+%Y-%m'`

output_folder=~/results
#output_folder=~/scripts/monitor/results
output_filename=${output_folder}/ac_sum_${date_text}.txt

# create output file.
mkdir -p ${output_folder}
touch $output_filename

# log ac summary
ac -d -p > $output_filename
