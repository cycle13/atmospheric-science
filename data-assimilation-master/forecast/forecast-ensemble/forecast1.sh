#!/bin/bash

set -x 
export NAME_LIST=_NAME_LIST_
export INPUT_NML=_INPUT_NML_
export FORECAST_RUN_DIR=_FORECAST_RUN_DIR_
export CHEM=_CHEM_						
export INITIAL_DATE_FORECAST=_INITIAL_DATE_FORECAST_
export PRE_RUN_DIR=_PRE_RUN_DIR_
export ICBC_RUN_DIR=_ICBC_RUN_DIR_

export PRE_CHEM_CYCLE=$S/test/chem-background	 
export WRFVAR_DIR=$HOME/wrf/wrfda-3.6.1	
export DART_DIR=$HOME/kodiak
export TOOL_DIR=$WRFVAR_DIR/var/da
export SCRIPT_DIR=$S/test/shell
export TEMPLATE_DIR=$HOME/template
#export WRF_ARW_DIR=$HOME/wrf/wrfarw-3.4.1				#IBM
export WRF_CHEM_DIR=$S/test/wrfchem-3.6.1
export INITIAL_DATE_FORECAST=2010082000
export LBC_FREQ=6	
export timestep=180
DAYS=6		#? How many days you want to forecast				
export DA_PERIOD_SECONDS=$((DAYS*3600*24))				
export ENS_SIZE=20																#???
export MAX_DOM=1 
export NEST_I_PARENT_START=1
export NEST_J_PARENT_START=1
export IS_FROM_ICBC=true				#???

export num_wrf_per_job=${num_wrf_per_job:-1}		#? 

   if [[ -d $FORECAST_RUN_DIR/working ]]; then \rm -rf $FORECAST_RUN_DIR/working; fi
   mkdir -p $FORECAST_RUN_DIR/working 
   cd $FORECAST_RUN_DIR/working

   export THIS_DA_START_DATE=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_FORECAST 0 -f "ccyymmddhhnnss")
   export THIS_DA_END_DATE=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE ${DA_PERIOD_SECONDS}s -f "ccyymmddhhnnss")
   
   ln -sf ${DART_DIR}/models/wrf/work/dart_to_wrf .	
   ln -sf ${DART_DIR}/models/wrf/work/wrf_to_dart .
   ln -sf ${DART_DIR}/models/wrf/work/update_wrf_bc	 .							
   ln -sf ${ICBC_RUN_DIR} WRF
#---------------
#   if run chem, copy the chemistry background files
#----------------------

if [[ $CHEM = true ]]; then
   ln -sf $PRE_CHEM_CYCLE/wrfchemi_00z_d01 .	#? may be change later
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

                          
   m4 -D_FIRST_OBS_DAYS_=  -D_FIRST_OBS_SECONDS_= \
      -D_LAST_OBS_DAYS_= -D_LAST_OBS_SECONDS_= \
      -D_MAX_DOM_=$MAX_DOM -D_ENS_SIZE_=$ENS_SIZE \
      $TEMPLATE_DIR/$INPUT_NML > input.nml							
   
      # ---------------------------------------------------------------------
      # submit job array to run wrf ensemble forecast
      # ---------------------------------------------------------------------
      (( n_batch_dart_f = ENS_SIZE / num_wrf_per_job ))
      if (( ENS_SIZE % num_wrf_per_job > 0 )); then
         (( n_batch_dart_f = n_batch_dart_f + 1 ))
      fi

#################
## MP2
#############      

VAR="WRF_CHEM_DIR=$WRF_CHEM_DIR,num_wrf_per_job=$num_wrf_per_job,ENS_SIZE=$ENS_SIZE,FORECAST_RUN_DIR=$FORECAST_RUN_DIR,\
TOOL_DIR=$TOOL_DIR,THIS_DA_START_DATE=$THIS_DA_START_DATE,THIS_DA_START_DATE=$THIS_DA_START_DATE,THIS_DA_END_DATE=$THIS_DA_END_DATE,\
CHEM=$CHEM,IS_FROM_ICBC=$IS_FROM_ICBC,PRE_RUN_DIR=$PRE_RUN_DIR,ICBC_RUN_DIR=$ICBC_RUN_DIR"
		echo $VAR  >>check.export.varible
	ssh ip14 "cd $SCRIPT_DIR;qsub -t 1-${n_batch_dart_f} -v $VAR forecast2.sh"


##############
##  IBM
#############

#cd $SCRIPT_DIR
#id=1
#while [[ $id -le ${n_batch_dart_f} ]];do
#export PBS_ARRAYID=$id
#chmod +x forecast2.sh
#llsubmit forecast2.sh	
#./forecast2.sh
#(( id=id+1 ))
#done



