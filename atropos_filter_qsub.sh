#!/bin/bash

### usage:
### sh atropos_filter_qsub.sh <directory to filter> <split file name prefix> <number of files to split into>

set -x

if [[ $# != 3 ]]; then
	echo not enough arguments
	echo Usage: sh atropos_filter_qsub.sh source directory split_file_prefix num_split_files
	exit 1
fi

if [[ ! -d $1 ]]; then
	echo source directory $1 does not exist
	exit 2
fi

if [[ $3 > 8 ]]; then
	echo script not built to handle $3 split files
	echo please select split file < 9
	exit 3
fi


dir=$1
trim_file=$2
split_count=$3 ### must be less than 9
job_count=$(($split_count + 1))

file_base=$(basename $dir)

pushd $dir

for proj_dir in $(ls */ -d | egrep -v 'Stats|Reports|moved|sample');
do
pushd $proj_dir

find . -maxdepth 1 -name "*.fastq.gz" -type f | grep "_R1_" | cut -f2 -d"/" > ${file_base}_file_list.txt
#ls | grep *.fastq.gz > ${file_base}_file_list.txt
line_count=$(cat ${file_base}_file_list.txt | wc -l)

split -l $(( $line_count / $split_count)) -d ${file_base}_file_list.txt split_file_

if [[ $? == 0 ]]; then
	rm ${file_base}_file_list.txt
fi

#qsub -v dir="$dir",trim_file="$trim_file" -t 0-$(($split_count + 1)) ~/filter_job_parallel.sh
pbs_job_id=$(qsub -v dir="${dir}/${proj_dir}",trim_file="$trim_file" -t 0-$(($split_count + 1)) -N ${dir}/${proj_dir} ~/filter_job_parallel.sh)

#qsub -v dir="${dir}/${proj_dir}" -lnodes=1:ppn=16 -lpmem=1gb ~/fastqc_parallel.sh -W depend=afterokarray:$pbs_job_id

popd
 
done

