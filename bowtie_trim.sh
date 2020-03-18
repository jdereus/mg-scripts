#!/bin/bash

set -x

dir=$1
trim_file=$2

source /home/jede9131/miniconda3/bin/activate test_env_2

module load bedtools_2.26.0 samtools_1.3.1 bowtie2_bowtie2-2.2.3

bowtie=$(which bowtie2)
samtools=$(which samtools)
bedtools=$(which bedtools)
filter_db="/databases/bowtie/Human_phiX174/Human_phix174"
tar="/bin/tar"

atropos_param="-a GATCGGAAGAGCACACGTCTGAACTCCAGTCAC -A GATCGGAAGAGCGTCGTGTAGGGAAAGGAGTGT -q 15 --minimum-length 100 --pair-filter any"

atropos_qc_output=$dir/atropos_qc

if [[ ! -d $atropos_qc_output/processed_qc ]]; then
	mkdir $atropos_qc_output/processed_qc
fi

pushd $dir
touch /tmp/now

### for reversing fastq output
for file in `find ${atropos_qc_output} -maxdepth 1 -type f -name "*.fastq" | sort -k2 --field-separator="_" | grep R1`;
#for file in `find ${atropos_qc_output} ! -newer /tmp/now -maxdepth 1 -type f -name "*.fastq" | grep R1`;
#for file in `cat ${atropos_qc_output}/${trim_file}`; 
#for file in `cat ${atropos_qc_output}/${trim_file} | cut -f 8 -d "/" | cut -f 1,2 -d"."`;
do
	echo PWD = $PWD
	echo $file
#	sleep 5

  final_output=$dir/filtered_sequences
  if [[ ! -d ${final_output} ]]; then
    mkdir ${final_output}
    mkdir ${final_output}/trim_logs
  fi

  touch "${final_output}/bowtie_output.log"
  touch "${final_output}/trim_logs/${filename1_short}.log"

  parent_dir=$(dirname $file)
  project_dir=$(echo $parent_dir | cut -f 2 -d"/")
      ### actual filename minus the preceding path
  filename1=$(basename "$file") ### .fastq.gz)
      ### strip fastq.gz for better file naming regarding output
  filename1_short=$(basename "$filename1" .fastq)
#  filename1_trim=$(echo "filename1_short" | sed -e 's/atropos//g')
      ### replace R1 with R2 to be able to pass both forward and reverse reads to bowtie
  filename2=$(echo "$filename1" | sed -e 's/R1/R2/g')
  filename2_short=$(basename "$filename2" .fastq)
#  filename2_trim=$(echo "filename2_short" | sed -e 's/atropos//g')

    $bowtie -p 16 -x ${filter_db} --very-sensitive -1 ${atropos_qc_output}/$filename1 -2 ${atropos_qc_output}/$filename2 | $samtools view -f 12 -F 256 | $samtools sort -@ 16 -n | $samtools view -bS | $bedtools bamtofastq -i - -fq $final_output/${filename1_short}.trimmed.fastq -fq2 $final_output/${filename2_short}.trimmed.fastq &> $final_output/trim_logs/${filename1_short}.log
#    $tar -czvf ${filename1_short}.fastq.gz ${filename1_short}.trimmed.fastq
#    $tar -czvf ${filename2_short}.fastq.gz ${filename2_short}.trimmed.fastq
		gzip -f ${final_output}/${filename1_short}.trimmed.fastq
		gzip -f ${final_output}/${filename2_short}.trimmed.fastq

		mv $atropos_qc_output/$filename1 $atropos_qc_output/processed_qc
		mv $atropos_qc_output/$filename2 $atropos_qc_output/processed_qc

		#echo "removing /tmp file"
		#rm /tmp/now

done
	rm /tmp/now
popd
