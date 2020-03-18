#!/bin/bash
#set -x

dir=$1
source /home/jede9131/miniconda3/bin/activate test_env_2

module load bedtools_2.26.0 samtools_1.3.1 bowtie2_bowtie2-2.2.3

bowtie=$(which bowtie2)
samtools=$(which samtools)
bedtools=$(which bedtools)
filter_db="/databases/bowtie/Human_phiX174/Human_phix174"
tar="/bin/tar"

#atropos_param="-a ATCTCGTATGCCGTCTTCTGCTTG -A GTGTAGATCTCGGTGGTCGCCGTATCATT -q 15 --minimum-length 100 --pair-filter any"

atropos_param="-a GATCGGAAGAGCACACGTCTGAACTCCAGTCAC -A GATCGGAAGAGCGTCGTGTAGGGAAAGGAGTGT -q 15 --minimum-length 100 --pair-filter any"
#atropos_param="-a GGGGGGGGGG -A GGGGGGGGGG -q 15 --nextseq-trim 1 --insert-match-error-rate 0.2 -e 0.1 --minimum-length 100 --pair-filter any"
atropos_qc_output=$dir/atropos_qc

pushd $dir

for file in `find $dir -maxdepth 1 -type f -name "*.fastq.gz" | grep R1`;
do
  parent_dir=$(dirname $file)
  project_dir=$(echo $parent_dir | cut -f 2 -d"/")
      ### actual filename minus the preceding path
  filename1=$(basename "$file") ### .fastq.gz)
      ### strip fastq.gz for better file naming regarding output
  filename1_short=$(basename "$filename1" .fastq.gz)
      ### replace R1 with R2 to be able to pass both forward and reverse reads to bowtie
  filename2=$(echo "$filename1" | sed -e 's/_R1_/_R2_/g')
  filename2_short=$(basename "$filename2" .fastq.gz)

  if [[ ! -d $atropos_qc_output ]]; then
    mkdir $atropos_qc_output
		mkdir ${atropos_qc_output}/atropos_logs
  fi

  atropos --threads 16 ${atropos_param} --report-file ${atropos_qc_output}/atropos_logs/${filename1_short}.log --report-formats txt -o ${atropos_qc_output}/${filename1_short}.fastq -p ${atropos_qc_output}/${filename2_short}.fastq -pe1 $filename1 -pe2 $filename2

# echo filename1 == $filename1
# echo filesystem location == $PWD
done

###pushd ${atropos_qc_output}

for file in `find ${atropos_qc_output} -maxdepth 1 -type f -name "*.fastq" | grep _R1_`;
do
	final_output=./filtered_sequences
	###final_output=$dir/filtered_sequences
	if [[ ! -d ${final_output} ]]; then
		mkdir ${final_output}
		mkdir ${final_output}/trim_logs
	fi

	###touch "${final_output}/bowtie_output.log"
	###touch "${final_output}/trim_logs/${filename1_short}.log"

	parent_dir=$(dirname $file)
  project_dir=$(echo $parent_dir | cut -f 2 -d"/")
      ### actual filename minus the preceding path
  filename1=$(basename "$file") ### .fastq.gz)
      ### strip fastq.gz for better file naming regarding output
  filename1_short=$(basename "$filename1" .fastq)
	filename1_trim=$(echo "filename1_short" | sed -e 's/atropos//g')
      ### replace R1 with R2 to be able to pass both forward and reverse reads to bowtie
  filename2=$(echo "$filename1" | sed -e 's/_R1_/_R2_/g')
  filename2_short=$(basename "$filename2" .fastq)
	filename2_trim=$(echo "filename2_short" | sed -e 's/atropos//g')

        $bowtie -p 16 -x ${filter_db} --very-sensitive -1 ${atropos_qc_output}/$filename1 -2 ${atropos_qc_output}/$filename2 | $samtools view -f 12 -F 256 | $samtools sort -@ 16 -n | $samtools view -bS | $bedtools bamtofastq -i - -fq $final_output/${filename1_short}.trimmed.fastq -fq2 $final_output/${filename2_short}.trimmed.fastq &> $final_output/trim_logs/${filename1_short}.log
#        gzip ${final_output}/${filename1_short}.filtered.fastq.gz ${final_output}/${filename1_short}.trimmed.fastq
#        gzip ${final_output}/${filename2_short}.filtered.fastq.gz ${final_output}/${filename2_short}.trimmed.fastq
#		$bowtie -p 16 -x ${filter_db} --very-sensitive -1 ${atropos_qc_output}/$filename1 -2 ${atropos_qc_output}/$filename2 | $samtools view -f 12 -F 256 | $samtools sort -@ 16 -n | $samtools view -bS | $bedtools bamtofastq -i - -fq $final_output/${filename1_short}.fastq -fq2 $final_output/${filename2_short}.fastq &> $final_output/trim_logs/${filename1_short}.log

	gzip -f ${final_output}/${filename1_short}.trimmed.fastq
	gzip -f ${final_output}/${filename2_short}.trimmed.fastq

		#$tar --remove-files -czvf ${final_output}/${filename1_short}.filtered.fastq.gz ${final_output}/${filename1_short}.trimmed.fastq
		#$tar --remove-files -czvf ${final_output}/${filename2_short}.filtered.fastq.gz ${final_output}/${filename2_short}.trimmed.fastq	

	mv $atropos_qc_output/$filename1 $atropos_qc_output/processed_qc
  mv $atropos_qc_output/$filename2 $atropos_qc_output/processed_qc

done

#	if [[ ! -d ${final_output}/index_files ]]; then
#		mkdir ${final_output}/index_files}
#	fi
#	mv $final_output/*I[12]*.filtered.fastq.gz

popd
