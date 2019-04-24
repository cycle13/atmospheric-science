#!/bin/bash
# generate the wrfinput files in every interval, as a mean state
#PBS -l nodes=1
#PBS -l walltime=1:00:00			 
###PBS -q qfbb@mp2		
#PBS -q qwork@mp2
#PBS -N piano					
#PBS -e	output.icbc.err				
#PBS -o	output.icbc					 
export ppn=24
# ------- test block--------
#export MAX_DOM=1
#export NEST_I_PARENT_START=1							
#export NEST_J_PARENT_START=1
#export INITIAL_DATE_ICBC=2010082400						
#export DA_TIME_WINDOW=216
#export WRFVAR_DIR=$S/wrf/wrfda
#export TOOL_DIR=$WRFVAR_DIR/var/da			
#export TEMPLATE_DIR=$S/test/template
#export WPS_RUN_DIR=$S/test/wps
#export WRF_CHEM_DIR=$S/wrf/bluefire/wrfchem
#export WRF_DIR=$S/wrf/wrfv3
#export WRF_RUN_DIR=$S/test/wrf/run
#export CHEM_BACKGROUND=$S/test/chem-spinup
#export ICBC_STAGE='DA' 							
#export CHEM=false		
#-------------------------------

# ----------------
# copy/link necessary files
# ----------------
set -x
cd $WRF_RUN_DIR
 ln -sf $WPS_RUN_DIR/$INITIAL_DATE_WPS/met_em.d0*  .		#$INITIAL_DATE_WPS should be different in DA stage and forecast stage  		

if [[ $CHEM = true ]];then	
ln -sf $CHEM_BACKGROUND/wrfchemi*  .
fi
#===========================
# copy file needed by chem, for DA stage ICBC  #?? need to improve this in the future
#=============================
#if [[ $ICBC_STAGE == 'DA' ]]; then
#		if [[ $CHEM = true ]];then							
#			start_date_w=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_ICBC 0 -w)
#			ln -sf  $CHEM_BACKGROUND/wrfout_d01_${start_date_w}   wrf_chem_input_d01
#			ln -sf $CHEM_BACKGROUND/wrfchemi*  .
#		fi 
#fi

#=======================
# link to  wrf 
# 
#=======================f
	ln -sf $WRF_CHEM_DIR/run/* .
	\rm namelist.input	
	\rm wrfinput_d01
	\rm wrfbdy_d01		

#================= 
# set namelist
#==============
	yyyy=$(echo $start_date | cut -c 1-4)
  	mm=$(echo $start_date | cut -c 5-6)
  	dd=$(echo $start_date | cut -c 7-8)
  	hh=$(echo $start_date | cut -c 9-10)
	yyyy_end=$(echo $end_date | cut -c 1-4)
  	mm_end=$(echo $end_date | cut -c 5-6)
  	dd_end=$(echo $end_date | cut -c 7-8)
  	hh_end=$(echo $end_date | cut -c 9-10)


echo $this_date $this_end_date

if [[ $CHEM = true ]];then
   m4 -D_FCST_=0 -D_MAX_DOM_=$MAX_DOM \
   -D_START_YEAR_=$yyyy -D_START_MONTH_=$mm -D_START_DAY_=$dd -D_START_HOUR_=$hh \
   -D_END_YEAR_=$yyyy_end -D_END_MONTH_=$mm_end -D_END_DAY_=$dd_end -D_END_HOUR_=$hh_end \
   -D_HISTORY_INTERVAL_1_=60 -D_HISTORY_INTERVAL_2_=60 -D_all_ic_times_=.true.\
   -D_TIMESTEP_=$timestep  \
   $TEMPLATE_DIR/namelist.input-mosaic-indirect-effect-tem  > namelist.input					#?
else
		m4 -D_FCST_=$fcst_hour -D_MAX_DOM_=$MAX_DOM \
   -D_START_YEAR_=$yyyy -D_START_MONTH_=$mm -D_START_DAY_=$dd -D_START_HOUR_=$hh \
   -D_END_YEAR_=$yyyy_end -D_END_MONTH_=$mm_end -D_END_DAY_=$dd_end -D_END_HOUR_=$hh_end \
   -D_HISTORY_INTERVAL_1_=60 -D_HISTORY_INTERVAL_2_=60 -D_all_ic_times_=.true. \
   -D_TIMESTEP_=$timestep  \
   $TEMPLATE_DIR/namelist.input.turnoff.chem.template  > namelist.input	
fi

########
## mp2
#####
  mpdboot -n $PBS_NUM_NODES -f $PBS_NODEFILE > /dev/null 2>&1
   mpiexec  -f $PBS_NODEFILE  -n $[PBS_NUM_NODES*ppn] -ppn $ppn   ./real.exe  >>stout.real

#####################

############
### IBM
#####

###
# Serial
#####
#./real.exe
#######3
# parallel
####
#m4 -D_LLDIR_='#@ initialdir ='$WRF_RUN_DIR  $SCRIPT_DIR/run_real_template.sh > run_real.sh
#llsubmit run_real.sh

#while true
#do 
#	if [[ $(grep -c "SUCCESS COMPLETE REAL_EM INIT" rsl.error.0000)  -ne 1 ]];then
# 		echo "waiting for real to finish , sleep 1min" >>wait-real.log
# 		sleep 60
#	else
#		break
#		sleep 15
#	fi
#done

