#!/bin/bash

############
## mp2
###########
#PBS -l nodes=5																
#PBS -l walltime=8:00:00			 
#PBS -q qwork@mp2													
###PBS -q qfbb@mp2	
#PBS -N piano					
#PBS -e	output.mean-forecast.err				
#PBS -o	output.mean-forecast		 
export ppn=24
#########################dart-chem-assim-meo

############
# IBM
#################
# LoadLeveler submission script for SciNet TCS: MPI job
#@ job_name        = forecast-mean
#_LLDIR_
#@ executable      = 
#@ arguments       = 
#
#@ tasks_per_node  = 64
#@ node            = 3
#@ wall_clock_limit= 03:00:00
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
##
#
# Submit the job
#
#@ queue
###################################

set -x
export NAME_LIST=_NAME_LIST_
export FORECAST_RUN_DIR=_FORECAST_RUN_DIR_
export CHEM=_CHEM_																							
export INITIAL_DATE_FORECAST=_INITIAL_DATE_FORECAST_				#? which day you want to pick up
export  PRI_POST_MEAN_DIR=_PRI_POST_MEAN_DIR_			#????????
export PRE_CHEM_CYCLE=$S/test/chem-background	
export WPS_RUN_DIR=$S/test/wps
export ICBC_RUN_DIR=$S/test/icbc 
export WRFVAR_DIR=$HOME/wrf/wrfda-3.4.1			#??????
export TOOL_DIR=$WRFVAR_DIR/var/da
export DART_DIR=$HOME/kodiak
export SCRIPT_DIR=$S/test/shell				#???
export TEMPLATE_DIR=$HOME/template
export WRF_ARW_DIR=$HOME/wrf/wrfarw-3.4.1				#IBM
export WRF_CHEM_DIR=$S/test/wrfchem-3.6.1      #? IBM , 
export INITIAL_DATE_ICBC=2010081000	#? !! important, icbc DIR for forecast, contain the wrfbdy for forecast, this is different from the $INITIAL_DATE_FORECAST									
export LBC_FREQ=6	
export timestep=180
DAYS=6																					#? how many days you want to forecast
export DA_PERIOD_SECONDS=$((DAYS*3600*24))				
export ENS_SIZE=20															#?
export MAX_DOM=1 

#----------------
# create directory, link file
#----------------

   if [[ -d $FORECAST_RUN_DIR ]]; then \rm -rf $FORECAST_RUN_DIR; fi
   mkdir -p $FORECAST_RUN_DIR
   cd $FORECAST_RUN_DIR


    	ln -sf $WRF_CHEM_DIR/run/* .

    	\rm namelist.input
      if [[ -e wrfinput_d* ]];then \rm wrfinput_d*; fi
      if [[ -e wrfbdy_d01 ]];then \rm wrfbdy_d01; fi

  ln -sf ${DART_DIR}/models/wrf/work/update_wrf_bc	 .	
  
#=======================
# set the time
#=======================

   export THIS_DA_START_DATE=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_FORECAST 0 -f "ccyymmddhhnnss")
   export THIS_DA_END_DATE=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE ${DA_PERIOD_SECONDS}s -f "ccyymmddhhnnss")
   this_start_date_w=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE 0 -w)
   
#---------------
#   if run chem, copy the chemistry background files
#----------------------

if [[ $CHEM = true ]]; then
	 ln -sf $PRE_CHEM_CYCLE/wrfchemi_00z_d01 .
   ln -sf $PRE_CHEM_CYCLE/wrfchemi_12z_d01  .
   ln -sf $PRE_CHEM_CYCLE/wrfchemi_gocart_bg_d01 .
fi 


   # --------------------------
   # create namelist files
   # --------------------------
   (( fcst_hour = $DA_PERIOD_SECONDS / 3600 ))
   (( fcst_minute = $DA_PERIOD_SECONDS / 60 ))
   yyyy=$(echo $THIS_DA_START_DATE | cut -c 1-4)
     mm=$(echo $THIS_DA_START_DATE | cut -c 5-6)
     dd=$(echo $THIS_DA_START_DATE | cut -c 7-8)
     hh=$(echo $THIS_DA_START_DATE | cut -c 9-10)
   yyyy_end=$(echo $THIS_DA_END_DATE | cut -c 1-4)
     mm_end=$(echo $THIS_DA_END_DATE | cut -c 5-6)
     dd_end=$(echo $THIS_DA_END_DATE | cut -c 7-8)
     hh_end=$(echo $THIS_DA_END_DATE | cut -c 9-10)

   
       m4 -D_FCST_=$fcst_hour -D_MAX_DOM_=$MAX_DOM \
      -D_START_YEAR_=$yyyy -D_START_MONTH_=$mm -D_START_DAY_=$dd -D_START_HOUR_=$hh \
      -D_END_YEAR_=$yyyy_end -D_END_MONTH_=$mm_end -D_END_DAY_=$dd_end -D_END_HOUR_=$hh_end \
      -D_HISTORY_INTERVAL_1_=360 -D_HISTORY_INTERVAL_2_=$fcst_minute -D_all_ic_times_=.false. \
	-D_TIMESTEP_=$timestep \
      $TEMPLATE_DIR/$NAME_LIST > namelist.input												


    m4 -D_FIRST_OBS_DAYS_=-1 -D_FIRST_OBS_SECONDS_=-1 \
      -D_LAST_OBS_DAYS_=-1 -D_LAST_OBS_SECONDS_=-1 \
      -D_MAX_DOM_=$MAX_DOM -D_ENS_SIZE_=$ENS_SIZE \
      $TEMPLATE_DIR/input-assim-meo-aod.adapt  > input.nml		#?
###########
## IBM
##########
#module load netcdf/4.1.2_nc3
#module load nco/4.0.8

#--------------
#  wrfinput
#---------------

cp  $PRI_POST_MEAN_DIR/wrfout_d01_${this_start_date_w}_post wrfinput_d01
echo "cp $PRI_POST_MEAN_DIR/wrfout_d01_${this_start_date_w}_post wrfinput_d01" >>log
	if [[ $CHEM = true ]];then
		ncatted -O -a MMINLU,global,m,c,"USGS" wrfinput_d01				#?????
	fi
#--------
# wrfbdy
#------------
cp  $ICBC_RUN_DIR/$INITIAL_DATE_ICBC/wrfbdy_d01 . 
echo "  cp  $ICBC_RUN_DIR/$INITIAL_DATE_ICBC/wrfbdy_d01 . " >>log


   ./update_wrf_bc > output.update_wrf_bc 2>&1


 #-----------------------------------
   # run wrf.exe
   #-----------------------------------

###########
## mp2
######### 
   mpdboot -n $PBS_NUM_NODES -f $PBS_NODEFILE > /dev/null 2>&1
  mpiexec  -f $PBS_NODEFILE  -n $[PBS_NUM_NODES*ppn] -ppn $ppn  ./wrf.exe
	
########
## IBM
######			
#	./wrf.exe

