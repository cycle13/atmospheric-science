#!/bin/bash

#PBS -l nodes=1
#PBS -l walltime=2:00:00
#PBS -q qtest@mp2
#PBS -e output.err                               
#PBS -o output 
#PBS -N piano 
#PBS -r n
 
set -x
############
# IBM
#################
# LoadLeveler submission script for SciNet TCS: MPI job
#@ job_name        = mean
#_LLDIR_
#@ executable      = 
#@ arguments       = 
#
#@ tasks_per_node  = 1
#@ node            = 1
#@ wall_clock_limit= 01:30:00
#@ output          = $(job_name).$(jobid).out
#@ error           = $(job_name).$(jobid).err
#

#
# Don't change anything below here unless you know exactly
# why you are changing it.
#
#@ job_type        = parallel
#@ class           = verylong
#@ node_usage      = not_shared
#@ rset = rset_mcm_affinity
#@ mcm_affinity_options = mcm_distribute mcm_mem_req mcm_sni_none
#@ cpus_per_core=2
#@ task_affinity=cpu(1)
#@ environment = COPY_ALL; MEMORY_AFFINITY=MCM; MP_SYNC_QP=YES; \
#                MP_RFIFO_SIZE=16777216; MP_SHM_ATTACH_THRESH=500000; \
#                MP_EUIDEVELOP=min; MP_USE_BULK_XFER=yes; \
#                MP_RDMA_MTU=4K; MP_BULK_MIN_MSG_SIZE=64k; MP_RC_MAX_QP=8192; \
#                PSALLOC=early; NODISCLAIM=true
#
#module load netcdf/4.1.2_nc3
#export NETCDF=/scinet/tcs/Libraries/netcdf-4.1.2_nc3
#export PATH=$NETCDF/bin:$PATH
#export LD_LIBRARY_PATH=$NETCDF/lib:$LD_LIBRARY_PATH
#module load nco/4.0.8

###################################
# export WRFVAR_DIR=$S/wrf/wrfda
export WRFVAR_DIR=$HOME/wrf/wrfda-3.7-openmpi					# 
export TOOL_DIR=$WRFVAR_DIR/var/da
export  DART_RUN_DIR=_DART_RUN_DIR_  			#????? the da cycle DIR
export  PRI_POST_MEAN_DIR=_PRI_POST_MEAN_DIR_   #?????? The DIR which store the mean file
export  DA_TIME_WINDOW=6	         	#?
export  INITIAL_DATE=2010082206		
export LBC_FREQ=6
#------------------------------------
if [[ ! -d $PRI_POST_MEAN_DIR ]];then mkdir -p $PRI_POST_MEAN_DIR; fi
cd $DART_RUN_DIR/working
start_date=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE 0 -f 'ccyymmddhh')
end_date=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE $DA_TIME_WINDOW -f 'ccyymmddhh')

this_date=$start_date

while [[ $this_date -le $end_date ]];do
	this_date_w=$($TOOL_DIR/da_advance_time.exe $this_date 0 -w)

	echo $this_date_w   >> $DART_RUN_DIR/working/filename
	echo "working on $this_date_w" >> $PRI_POST_MEAN_DIR/check-progress

	if [[ $this_date == $start_date ]];then  
		ncea  */wrfout_d01_${this_date_w}  wrfout_d01_${this_date_w}.prior #? if you don't have prior copy for wrfinput_d01, use the block, otherwise, don't need it 
		cp wrfout_d01_${this_date_w}.prior	 wrfout_d01_${this_date_w}.post	
	else
		ncea  */wrfout_d01_${this_date_w}.prior  wrfout_d01_${this_date_w}.prior				#? diff name
		ncea  */wrfout_d01_${this_date_w}.post wrfout_d01_${this_date_w}.post
	fi

	mv wrfout_d01_${this_date_w}.prior wrfout_d01_${this_date_w}.post $PRI_POST_MEAN_DIR

	this_date=$($TOOL_DIR/da_advance_time.exe $this_date $LBC_FREQ)	

done

#@ queue
