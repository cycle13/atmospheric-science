#!/bin/bash
#PBS -l nodes=10
#PBS -l walltime=10:00:00
#PBS -q qwork@mp2
#PBS -e output.err                               
#PBS -o output 
#PBS -N piano 
#PBS -r n
 
export ppn=24

#####################################
#IBM
#####################
#@ job_name      = Richard
#@ initialdir      =
#@ executable      =
#@ arguments       =
#
#@ tasks_per_node  = 64
#@ node            = 2
#@ wall_clock_limit= 05:00:00
#@ output          = $(job_name).$(jobid).out
#@ error           = $(job_name).$(jobid).err
#
#@ notification = never
#
# Do not change anything below here unless you know exactly
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
# @ queue
#####################################################

set -x
export NAME_LIST=_NAME_LIST_			
export INPUT_NML_APT=_INPUT_NML_APT_
export INPUT_NML_FIX=_INPUT_NML_FIX_
export DART_RUN_DIR=_DART_RUN_DIR_
export FILTER_RUN_DIR=_FILTER_RUN_DIR_
export CHEM=_CHEM_											
export NEW_SCRIPT_NAME=_SCRIPT1_
export DART_DIR=_DART_DIR_				#?  dart2 have locolizaton,
export PRE_RUN_DIR=_PRE_RUN_DIR_
export READ_PREVIOUS_INFLATION=_READ_PREVIOUS_INFLATION_

export WPS_RUN_DIR=$S/test/wps
export PRE_CHEM_CYCLE=''
export ICBC_RUN_DIR=$S/test/icbc

export WRF_CHEM_DIR=$HOME/wrf/wrfchem-3.9.1-gocart-dust0.5-seas0.4-mvp	#????
export WRFVAR_DIR=$HOME/wrf/wrfda-3.7-mvp	#?	
export TOOL_DIR=$WRFVAR_DIR/var/da				
export SCRIPT_DIR=$S/test/shell			#??		
export TEMPLATE_DIR=$HOME/template
export OBS_SEQ_DIR=$S/test/data/dart-obs/seq-ncep-cimss-track-airs-gps-modis		#??     
export INITIAL_DATE_ICBC=2010082112		#? use to find the icbc directory,should be earlier or equal to the INITIAL_DATE_DART
export INITIAL_DATE_DART=2010082218		#? the start day of dart, if use chem, it will find the corresponding file in the wrfout in chem spin up 
export DA_TIME_WINDOW=120				#? 144.The whole time window , may include a lot of cycle
export timestep=120
export IS_FROM_ICBC=false				#? the first time is from icbc or from the forecast output

if [[ $IS_FROM_ICBC = true ]];then
	export SKIP_FILTER_AT_BEGINNING=${SKIP_FILTER_AT_BEGINNING:-true}   #? default run for 6hours, make it stable then assimilate
else
	export SKIP_FILTER_AT_BEGINNING=${SKIP_FILTER_AT_BEGINNING:-false} 
fi
 
export ADAPT_INFLATION=${ADAPT_INFLATION:-true}		
export num_wrf_per_job=${num_wrf_per_job:-6}			#? how many wrf you run in one node
export ENS_SIZE=30										#?
export LBC_FREQ=6										#? for finding the corresponding lbc file name in ICBC directory
export HOURS=6											#? the interval for each cycle , For this script, DA_PERIOD_SECONDS must less than the LBC_FREQ	
export DA_PERIOD_SECONDS=$((HOURS*3600))				
export DA_HALF_OBS_WINDOW_SECONDS=10800					#? which time window is appropiate? can cut in the observation
export NEST_I_PARENT_START=1
export NEST_J_PARENT_START=1
export ICBC_STAGE='DA'
export MAX_DOM=1 
export READ_INFLATION=${READ_INFLATION:-.false.}		# must in the form .false. , can not be false

#-------
# Have observation in some time or not 
#--------------
export HAVE_OBS=true									#? by default , there is observation to be assimilated unless there is not



#===========================================================
#  First cycle, link/copy necessary files
#===========================================================
export ISFIRST=${ISFIRST:-true}
if $ISFIRST; then										# ISFIRST will always be false after the first cycle , will not inter this 'if' block

	if [[  -d $FILTER_RUN_DIR ]]; then \rm -r $FILTER_RUN_DIR; fi
	mkdir $FILTER_RUN_DIR

	if [[ $SKIP_FILTER_AT_BEGINNING	= false ]];then	  	# create filter.ics for the initial time. For restart purpose due to error, from the previous run. 
														# if start from ICBC or no error, do not enter this block 	
		. $SCRIPT_DIR/creat_filter_ics_only.sh	        # will not run this script in the following cycle,filter.ics was given by wrf output  
	fi

	if [[ ! -d $DART_RUN_DIR/working ]]; then 
		mkdir -p $DART_RUN_DIR/working
	fi

	cd $DART_RUN_DIR/working

	export DA_START_DATE=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_DART 0 -f "ccyymmddhhnnss")
	export DA_END_DATE=$($TOOL_DIR/da_advance_time.exe   $INITIAL_DATE_DART $DA_TIME_WINDOW -f "ccyymmddhhnnss")
	export THIS_DA_START_DATE=$($TOOL_DIR/da_advance_time.exe $DA_START_DATE 0 -f "ccyymmddhhnnss")
	export THIS_DA_END_DATE=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE ${DA_PERIOD_SECONDS}s -f "ccyymmddhhnnss")
	export THIS_DA_BDY_DATE=$($TOOL_DIR/da_advance_time.exe $DA_START_DATE $LBC_FREQ -f "ccyymmddhhnnss")
	
	# --------------------------
	# copy/link necessary files
	# -------------------------- 
	ln -sf ${DART_DIR}/models/wrf/work/dart_to_wrf .	
	ln -sf ${DART_DIR}/models/wrf/work/wrf_to_dart .
	ln -sf ${DART_DIR}/models/wrf/work/update_wrf_bc	 .	
	ln -sf ${DART_DIR}/models/wrf/work/filter .							
	ln -sf ${ICBC_RUN_DIR}/${INITIAL_DATE_ICBC} WRF
	\rm fail_${THIS_DA_END_DATE}.out
	#---------------
	#   if run chem, copy the chemistry background files
	#----------------------
	#if [[ $CHEM = true ]]; then
	#	ln -sf $PRE_CHEM_CYCLE/wrfchemi_00z_d01 .
	#	ln -sf $PRE_CHEM_CYCLE/wrfchemi_12z_d01  .
	#	ln -sf $PRE_CHEM_CYCLE/wrfchemi_gocart_bg_d01 .
	#fi 

	#---------------
	# if restart, copy the inflation restart file
	#-----------------
	if [[ $SKIP_FILTER_AT_BEGINNING	= false ]];then	
		if [[ $READ_PREVIOUS_INFLATION = true ]];then      #???? if not add aod, then use the previous inflation file, 
			if [[ $ADAPT_INFLATION = true ]];then
				temp=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE -${DA_PERIOD_SECONDS}s -f "ccyymmddhhnnss")	
				echo "cp $PRE_RUN_DIR/$temp/prior_inflate_restart ." >> restart-inflation.log
				cp $PRE_RUN_DIR/$temp/prior_inflate_restart .				
				if [ $(echo $?) -eq 0 ];then
		  			READ_INFLATION=.true.
				fi
			fi
	 	fi
	fi
 
fi  
#===========================
# 	end First cycle link
#===========================

#=====================================
#				begin the following cycle
#===================================
cd $DART_RUN_DIR/working

#-------------------
# observation
#-------------------																						  
this_obs_seq_date=$(echo $THIS_DA_START_DATE |cut -c1-10)
ln -sf ${OBS_SEQ_DIR}/obs_seq${this_obs_seq_date}*  obs_seq.out		#?? format of the name

#================
# set the time
#================
temp=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE 0 -g)
this_start_date_g[0]=$(echo $temp|cut -f1 -d' ')
this_start_date_g[1]=$(echo $temp|cut -f2 -d' ') 
this_start_date_w=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE 0 -w)
# start_date_wrf=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_DART 0 -w)    

#--------------------------------------------------
#  copy wrfinput_d01, use by filter, as a template    
#--------------------------------------------------
if [[ -e wrfinput_d01 ]];then \rm wrfinput_d01 ; fi

if $ISFIRST; then
	if $IS_FROM_ICBC; then	
  		echo "ln -sf    WRF/wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_1 wrfinput_d01" >>log
  		cp WRF/wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_1 wrfinput_d01		
	else					
		echo "ln -sf   $PRE_RUN_DIR/working/1/wrfout_d01_${this_start_date_w}.prior  wrfinput_d01"  >>log  
		ln -sf  $PRE_RUN_DIR/working/1/wrfout_d01_${this_start_date_w}.prior  wrfinput_d01
	fi
else
	echo "ln -sf   ./1/wrfout_d01_${this_start_date_w}.prior  wrfinput_d01"  >>log
 	ln -sf  ./1/wrfout_d01_${this_start_date_w}.prior  wrfinput_d01
   						  								  		
fi	
													
#-------
#	link filter.ics
#-----------
if [[ $SKIP_FILTER_AT_BEGINNING	= false ]];then 
	\rm filter_restart.*   filter_ics.*   
	ln -sf $FILTER_RUN_DIR/filter_ics.* .		  				
fi
#---------------------  									

# --------------------------
# create wrf namelist 
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
-D_HISTORY_INTERVAL_1_=$fcst_minute -D_HISTORY_INTERVAL_2_=$fcst_minute -D_all_ic_times_=.false. \
-D_TIMESTEP_=$timestep  $TEMPLATE_DIR/$NAME_LIST > namelist.input
cp $TEMPLATE_DIR/$NAME_LIST namelist.template

# --------------------------
# create DART namelist 
# --------------------------

temp=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE  -${DA_HALF_OBS_WINDOW_SECONDS}s+1s -g)
first_obs_gdate[0]=$(echo $temp|cut -f1 -d' ')
first_obs_gdate[1]=$(echo $temp|cut -f2 -d' ')

temp=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE  +${DA_HALF_OBS_WINDOW_SECONDS}s -g)
last_obs_gdate[0]=$(echo $temp|cut -f1 -d' ')
last_obs_gdate[1]=$(echo $temp|cut -f2 -d' ')                          
                        

if [[ $ADAPT_INFLATION = true ]];then
 	m4 -D_FIRST_OBS_DAYS_=${first_obs_gdate[0]} -D_FIRST_OBS_SECONDS_=${first_obs_gdate[1]} \
      -D_LAST_OBS_DAYS_=${last_obs_gdate[0]} -D_LAST_OBS_SECONDS_=${last_obs_gdate[1]} \
      -D_MAX_DOM_=$MAX_DOM -D_ENS_SIZE_=$ENS_SIZE -D_INFLATION_READ_=$READ_INFLATION  \
      $TEMPLATE_DIR/$INPUT_NML_APT > input.nml	
else
	m4 -D_FIRST_OBS_DAYS_=${first_obs_gdate[0]} -D_FIRST_OBS_SECONDS_=${first_obs_gdate[1]} \
      -D_LAST_OBS_DAYS_=${last_obs_gdate[0]} -D_LAST_OBS_SECONDS_=${last_obs_gdate[1]} \
      -D_MAX_DOM_=$MAX_DOM -D_ENS_SIZE_=$ENS_SIZE  $TEMPLATE_DIR/$INPUT_NML_FIX > input.nml	
fi

#---------------
# run filter
#--------------

if $SKIP_FILTER_AT_BEGINNING; then

	echo ... SKIP filter at the very beginning ...

else
		
	if [[ -e dart_log.out ]]; then \rm dart_log.out ; fi
	if [[ -e dart_log.nml  ]]; then \rm dart_log.nml  ; fi

	#----------
	# adaptive inflation
	#-------------	
	if [[ $READ_INFLATION	!= ".false." ]];then 
		\rm prior_inflate_ics
		mv prior_inflate_restart prior_inflate_ics
		fi
	export READ_INFLATION=".true."
	   
	######
	##mp2
	####################
	# openmpi
	 #mpiexec -n $[PBS_NUM_NODES*ppn] -npernode $ppn ./filter  >> stdout

	mpdboot -n $PBS_NUM_NODES -f $PBS_NODEFILE > /dev/null 2>&1
	mpiexec  -f $PBS_NODEFILE  -n $[PBS_NUM_NODES*ppn] -ppn $ppn ./filter  >>jobout

	###########
	## IBM
	############
	#poe ./filter >>stout
	#m4 -D_LLDIR_='#@ initialdir ='${DART_RUN_DIR}'/working'  $SCRIPT_DIR/run_filter_template.sh > run_filter.sh
	#llsubmit run_filter.sh
	 #./filter  >>stout
	#################

	RC=$?
	if [[ $RC -ne 0 ]]; then	# filter fail
		if [[ $(grep -c "All obs in sequence are after" dart_log.out )  -ne 1 ]]; then   			
			echo "filter run is failed with error $RC"
			exit $RC
		fi
		HAVE_OBS=false				# give error because no observation, do not exit program yet, but no filter_restart
		echo "no observation at this time" >>log
		exit $RC
	fi

	if [[ $HAVE_OBS == true ]];then	   # only sucessful assimilate, then create that DIR, otherwise, do not creat and do not move filter_ics
		export THIS_ANALYSIS_DIR=${DART_RUN_DIR}/$THIS_DA_START_DATE
		if [[ ! -e $THIS_ANALYSIS_DIR ]]; then 
			mkdir -p $THIS_ANALYSIS_DIR
		fi

		mv Prior_Diag.nc Posterior_Diag.nc  obs_seq.final obs_seq.out dart_log.nml dart_log.out  $THIS_ANALYSIS_DIR	
		cp  prior_inflate_restart input.nml $THIS_ANALYSIS_DIR

		\rm $FILTER_RUN_DIR/filter_ics*  
	fi


fi
#-------------------------
# end of running filter, if SKIP is true, this block will not execute
#-------------------------


cd ${DART_RUN_DIR}/working     
 
# -----------------------------------------------------
# advance wrfbdy time if end time exceeds wrfbdy time, for running wrf
# -----------------------------------------------------
if [[ $THIS_DA_END_DATE -gt $THIS_DA_BDY_DATE && $THIS_DA_END_DATE -le $DA_END_DATE ]]; then
    export THIS_DA_BDY_DATE=$($TOOL_DIR/da_advance_time.exe $THIS_DA_BDY_DATE $LBC_FREQ -f "ccyymmddhhnnss")
fi


# ---------------------------------------------------------------------
# submit job array to run wrf ensemble forecast
# ---------------------------------------------------------------------
(( n_batch_dart_f = ENS_SIZE / num_wrf_per_job ))
if (( ENS_SIZE % num_wrf_per_job > 0 )); then
	(( n_batch_dart_f = n_batch_dart_f + 1 ))
fi


##########
## mp2
##############    
VAR="WRF_CHEM_DIR=$WRF_CHEM_DIR,FILTER_RUN_DIR=$FILTER_RUN_DIR,DART_RUN_DIR=$DART_RUN_DIR,TOOL_DIR=$TOOL_DIR,num_wrf_per_job=$num_wrf_per_job,ENS_SIZE=$ENS_SIZE,THIS_DA_START_DATE=$THIS_DA_START_DATE,THIS_DA_BDY_DATE=$THIS_DA_BDY_DATE,THIS_DA_END_DATE=$THIS_DA_END_DATE,INITIAL_DATE_ICBC=$INITIAL_DATE_ICBC,CHEM=$CHEM,SKIP_FILTER_AT_BEGINNING=$SKIP_FILTER_AT_BEGINNING,HAVE_OBS=$HAVE_OBS,ISFIRST=$ISFIRST,IS_FROM_ICBC=$IS_FROM_ICBC,ICBC_RUN_DIR=$ICBC_RUN_DIR,PRE_RUN_DIR=$PRE_RUN_DIR,timestep=$timestep"   # do not put any space between ,
  	
echo $VAR  >>check.export.varible
WRFJOB=$(ssh ip14 "cd $SCRIPT_DIR;qsub -t 1-${n_batch_dart_f} -v $VAR run_dart_wrf_2.sh") 

##############
##  IBM
#############

#echo "submit wrf, enter $SCRIPT_DIR " >>submit
#echo "cd $SCRIPT_DIR" > ip14Cmd.sh
#echo "id=1"                   >> ip14Cmd.sh
#echo 'while [[ $id -le ${n_batch_dart_f} ]];do
#export PBS_ARRAYID=$id
#chmod +x run_dart_wrf_2.sh
#qsub run_dart_wrf_2.sh
#(( id=id+1 ))
#done'                               >> ip14Cmd.sh

#chmod u+x ip14Cmd.sh
#ssh ip14 `pwd`/ip14Cmd.sh


##########################################

export SKIP_FILTER_AT_BEGINNING=false		# will not skip filter after run wrf
export ISFIRST=false	
   
# ---------------------------------------------------------------------
# submit itself again to do analysis if time not end
# ---------------------------------------------------------------------

#=====================
# change the time, do that only after submit the WRF ensemble forecast
#====================      
export THIS_DA_START_DATE=$THIS_DA_END_DATE
export THIS_DA_END_DATE=$($TOOL_DIR/da_advance_time.exe $THIS_DA_END_DATE ${DA_PERIOD_SECONDS}s -f "ccyymmddhhnnss")
#==============

if [[ $THIS_DA_START_DATE -lt $DA_END_DATE ]]; then

	##############
	### mp2 
	############# 				# do not put any space between ,
	VAR="SKIP_FILTER_AT_BEGINNING=$SKIP_FILTER_AT_BEGINNING,ISFIRST=$ISFIRST,READ_INFLATION=$READ_INFLATION,DA_START_DATE=$DA_START_DATE,DA_END_DATE=$DA_END_DATE,THIS_DA_START_DATE=$THIS_DA_START_DATE,THIS_DA_END_DATE=$THIS_DA_END_DATE,THIS_DA_BDY_DATE=$THIS_DA_BDY_DATE"

	echo "after submit WRF, submit the script itself" >>check.export.varible
	echo $VAR >>check.export.varible	
									
	ssh ip14 "cd $SCRIPT_DIR;qsub -W depend=afterokarray:$WRFJOB  -v $VAR $NEW_SCRIPT_NAME" 



	#############
	#IBM
	###################
	#while true
	#do 
	#	if [[ $(ls $FILTER_RUN_DIR/filter_ics.* |wc -l)  -ne $ENS_SIZE ]];then
	# 		echo "waiting for wrf to finish, sleep 30" >> ${DART_RUN_DIR}/working/wait-wrf.log
	# 		sleep 30
	#	else
	#		echo "finish wrf,sleep 30s" >> ${DART_RUN_DIR}/working/wait-wrf.log
	#		sleep 30
	#		break
	#	fi
	#done

	# cd $SCRIPT_DIR
	#qsub $NEW_SCRIPT_NAME
	# cd -
	############################################# 
 
fi
																																								

cd $DART_RUN_DIR


