#!/bin/bash
# convert the wrfinput at the "initial time",need it only once,  don't need to qsub this file
# the output will be in $FILTER_RUN_DIR, these files are needed to run_dart_1.sh
set -x
cd $FILTER_RUN_DIR
start_date_dart=$INITIAL_DATE_DART
start_date_icbc=$INITIAL_DATE_ICBC

start_date_wrf=$($TOOL_DIR/da_advance_time.exe $start_date_dart 0 -w)
temp=$($TOOL_DIR/da_advance_time.exe $start_date_dart 0 -g)
g_date[0]=$(echo $temp|cut -f1 -d' ')
g_date[1]=$(echo $temp|cut -f2 -d' ')

#-----------------------------------
# create the namelist and link file
#------------------------------------    
if [[ $ADAPT_INFLATION = true ]];then
m4 -D_FIRST_OBS_DAYS_=-1 -D_FIRST_OBS_SECONDS_=-1 \
  -D_LAST_OBS_DAYS_=-1 -D_LAST_OBS_SECONDS_=-1 \
  -D_MAX_DOM_=$MAX_DOM -D_ENS_SIZE_=$ENS_SIZE \
  $TEMPLATE_DIR/$INPUT_NML_APT > input.nml 													
else
  m4 -D_FIRST_OBS_DAYS_=-1 -D_FIRST_OBS_SECONDS_=-1 \
  -D_LAST_OBS_DAYS_=-1 -D_LAST_OBS_SECONDS_=-1 \
  -D_MAX_DOM_=$MAX_DOM -D_ENS_SIZE_=$ENS_SIZE \
  $TEMPLATE_DIR/$INPUT_NML_FIX > input.nml 		
fi
 
ln -sf $DART_DIR/models/wrf/work/wrf_to_dart .

if [[ MAX_DOM -gt 2 ]]; then
  echo MAX_DOM=$MAX_DOM is not supported. Stop!		#?
  exit
fi

#----------------------
#  begin the loop 
#----------------------
ie=1
while [[ ie -le ENS_SIZE ]]; do
	(( mtmp = 10000 + ie ))
	mm=$(echo $mtmp |cut -c2-5)
	if [[ $IS_FROM_ICBC = false ]]; then			# begin from the previous cycle
		ln -sf $PRE_RUN_DIR/working/$ie/wrfout_d01_${start_date_wrf}.prior  wrfinput_d01	#?
	else      
		ln -sf $ICBC_RUN_DIR/$start_date_icbc/wrfinput_d01_${g_date[0]}_${g_date[1]}_$ie wrfinput_d01   # DA immidiately after the icbc
	fi

	if [[ MAX_DOM -eq 2 ]]; then
		ln -sf $ICBC_DATA_DIR/wrfinput_d01_${g_date[0]}_${g_date[1]}_$ie wrfout_d01_${start_date_wrf}
		ln -sf $ICBC_DATA_DIR/wrfinput_d02_mean_${g_date[0]}_${g_date[1]} wrfndi_d02
	#?         mpirun.lsf ndown.exe
	fi

	./wrf_to_dart 
	mv dart_wrf_vector filter_ics.$mm

	(( ie = ie + 1 ))
done

