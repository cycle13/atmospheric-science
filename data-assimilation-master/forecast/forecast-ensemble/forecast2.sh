#!/bin/bash

#####################################
#IBM
#####################
#@ job_name      = Richard
#@ initialdir      =
#@ executable      =
#@ arguments       =
#
#@ tasks_per_node  = 64
#@ node            = 1
#@ wall_clock_limit= 10:00:00
#@ output          = $(job_name).$(jobid).out
#@ error           = $(job_name).$(jobid).err
#
#@ notification = never
#
# Don't change anything below here unless you know exactly
# why you are changing it.
#
#@ job_type        = parallel
#@ class           = verylong
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

#@ queue
####################

##############
# mp2
##############
#PBS -l nodes=3												
#PBS -l walltime=7:00:00			 
#PBS -q qwork@mp2			
##PBS -q qfbb@mp2							
#PBS -N piano					
#PBS -e	output.filter.err				
#PBS -o	output.filter					 			 
export ppn=24

set -x

LSB_JOBINDEX=$PBS_ARRAYID
echo $LSB_JOBINDEX  
#LSB_JOBINDEX=$((PBS_ARRAYID+1))			# in qsub system, the job array index begin from 0, in LSF, from 1


# define function
link_wrf_run_files(){

    	ln -sf $WRF_CHEM_DIR/run/* .

    	\rm namelist.input
      if [[ -e wrfinput_d* ]];then \rm wrfinput_d*; fi
      if [[ -e wrfbdy_d01 ]];then \rm wrfbdy_d01; fi
}

(( mem_start = ( LSB_JOBINDEX - 1 ) * num_wrf_per_job + 1 ))
(( mem_end =  LSB_JOBINDEX * num_wrf_per_job ))
mem=$mem_start

while [[ $mem -le $mem_end && $mem -le $ENS_SIZE ]]; do
   memdir=${FORECAST_RUN_DIR}/working/${mem}
   if [[ ! -e $memdir ]]; then mkdir -p $memdir; fi
   cd $memdir
   link_wrf_run_files

   ln -sf ../namelist.input .
   ln -sf ../input.nml .
  if [[ $(ls rsl.* |wc -l) -ne 0 ]]; then \rm rsl.* ; fi

#--------------
# time 
#---------------
	 temp=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE 0 -g)
   this_start_date_g[0]=$(echo $temp|cut -f1 -d' ')
	 this_start_date_g[1]=$(echo $temp|cut -f2 -d' ')
   this_start_date_w=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE 0 -w)
   this_end_date_w=$($TOOL_DIR/da_advance_time.exe $THIS_DA_END_DATE 0 -w)

#---------------
      	 
    (( mtmp = 10000 + mem ))
   mm=$(echo $mtmp |cut -c2-5)

 #  	ln -sf $DART_RUN_DIR/$THIS_DA_START_DATE/filter_restart.$mm dart_wrf_vector


if [[ $CHEM = true ]]; then

	cp  ../wrfchemi_00z_d01 .
  	cp  ../wrfchemi_12z_d01  .	#? may link to different file in the future
  	cp  ../wrfchemi_gocart_bg_d01  .
fi

####
# IBM
#######
#export NETCDF=/scinet/tcs/Libraries/netcdf-4.1.2_nc3
#export PATH=$NETCDF/bin:$PATH
#export LD_LIBRARY_PATH=$NETCDF/lib:$LD_LIBRARY_PATH
		
#########

#----------------
#  new  wrfinput																					
#----------------
if $IS_FROM_ICBC; then	
     ln -sf    $PRE_RUN_DIR/wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_$mem   wrfinput_d01

else
     echo "ln -sf  $PRE_RUN_DIR/working/$mem/wrfout_d01_${this_start_date_w}	wrfinput_d01" >> log 				
    cp   $PRE_RUN_DIR/working/$mem/wrfout_d01_${this_start_date_w}  wrfinput_d01   #????????? this is the posterior, 
	ncatted -O -a MMINLU,global,m,c,"USGS"  wrfinput_d01	#??????														
fi		
#---------------
# update wrfbdy
#---------------	
	  
 		if [[ -e wrfbdy_d01 ]]; then \rm wrfbdy_d01; fi				# we need the perturb boundary
  	ln -sf    ${ICBC_RUN_DIR}/wrfbdy_d01_$mem  wrfbdy_d01
  										
if [[ $IS_FROM_ICBC = false ]] ; then		
		#  update bdy
   	../update_wrf_bc > output.update_wrf_bc 2>&1
fi

   #-----------------------------------
   # run wrf.exe
   #-----------------------------------
    rm rsl*
##############
## MP2
###########    
  mpdboot -n $PBS_NUM_NODES -f $PBS_NODEFILE > /dev/null 2>&1
   mpiexec  -f $PBS_NODEFILE  -n $[PBS_NUM_NODES*ppn] -ppn $ppn  ./wrf.exe
###############################

#./wrf.exe

   
#   if [[ $(grep "wrf: SUCCESS COMPLETE WRF" rsl.out.0000 | wc -l)  -eq 0 ]]; then
#      echo $mem >> ${FORECAST_RUN_DIR}/working/blown_${this_end_date_w}.out
#			exit 
#	 fi							

   (( mem = mem + 1 ))
done

exit

