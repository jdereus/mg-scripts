#!/bin/bash

### #PBS -N $expname 
#PBS -l nodes=1:ppn=16
#PBS -V
#PBS -l walltime=96:00:00
#PBS -l pmem=10G
#PBS -o /home/jede9131/filter_jobs/  ###${job_o_out} 
#PBS -e /home/jede9131/filter_jobs/ ###${job_e_out}

#PBS -m abe
#PBS -M jdereus@ucsd.edu,jenya.kopylov@gmail.com ###gail.ackermann50@gmail.com

dataprefix="/sequencing/ucsd/complete_runs"

#cd ${dataprefix}/${dataloc}
cd ${seqdir}

#if [ "x$PBS_O_WORKDIR" != "x" ]; then
#        cd $PBS_O_WORKDIR
#fi

cmd="sh ~/bowtie_trim.sh $dir"

date
echo "Executing: $cmd"
eval $cmd
date
