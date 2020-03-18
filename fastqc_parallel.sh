#!/bin/bash

set -x

dir=$1
#trim_file=$2
NPROCS=$2
suffix=R*.fastq*
data_prefix=/var/www/html/seq_fastqc

source /home/jede9131/miniconda3/bin/activate test_env_2

pushd $dir

fastq_raw=$dir
atropos_qc_output=$dir/atropos_qc
fastq_trimmed=$atropos_qc_output/filtered_sequences

fastqc_output_dir=$(basename $(dirname $(pwd)) )/$(basename `pwd`)

if [[ ! -d ${data_prefix}/${fastqc_output_dir} ]];
  then
    ssh 10.210.38.59 "mkdir ${data_prefix}/${fastqc_output_dir}/{fastqc_raw,fastqc_atropos,fastqc_trimmed}"
    #mkdir ${data_prefix}/${fastqc_output_dir}/fastqc_raw
    #mkdir ${data_prefix}/${fastqc_output_dir}/fastq_atropos
    #mkdir ${data_prefix}/${fastqc_output_dir}/fastqc_trimmed
fi

#sleep 5

for location in $fastq_raw $atropos_qc_output $fastq_trimmed; do
	if [[ ! -d $location/fastqc_output ]]; then
		mkdir $location/fastqc_output
	fi

	find $location -name  "*$suffix" -maxdepth 1 -type f -exec fastqc {} -t ${NPROCS} -o $location/fastqc_output \;
	#find $atropos_qc_output -name "*$suffix" -maxdepth 1 -type f -exec fastqc {} -t ${NPROCS} -o $atropos_qc_output/atropos_fastqc \;
	#cd $atropos_qc_output/atropos_fastqc
	pushd $location/atropos_fastqc
		multiqc ./

#fastqc_output_dir=$(basename $(dirname $(pwd)) )/$(basename `pwd`)

popd
done

#	cp multiqc_report.html ${data_prefix}/${fastq_output_dir}
	cp -rf $dir/fastqc_output/*.html $dir/fastqc_output/multiqc_data ${data_prefix}/${fastqc_output}/fastqc_raw/
	cp -rf $atropos_qc_output/fastqc_output/*.html $atropos_qc_output/fastqc_output/multiqc_data ${data_prefix}/${fastqc_output}/fastqc_atropos/
	cp -rf $fastq_trimmed/fastqc_output/*.html $fastq_trimmed/fastqc_output/multiqc_data ${data_prefix}/${fastqc_output}/fastqc_trimmed/
	#cp $location/fastqc_output/*.html $location/fastqc_output/multiqc_data ${data_prefix}/${fastq_output_dir}/fastqc_

	cd ${data_prefix}/${fastqc_output_dir}/fastqc_raw && tree -H '.' -L 1 --noreport --charset utf-8 > index.html
	cd ${data_prefix}/${fastqc_output_dir}/fastqc_atropos && tree -H '.' -L 1 --noreport --charset utf-8 > index.html
	cd ${data_prefix}/${fastqc_output_dir}/fastqc_trimmed && tree -H '.' -L 1 --noreport --charset utf-8 > index.html

	cd ${data_prefix} && tree -H '.' -L 1 --noreport --charset utf-8 > index.html
