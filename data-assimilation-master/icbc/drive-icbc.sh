#!/bin/bash
#instruction, run as  a normal shell script,  don't need to submit,it will do the following
# or you can use nohup to submit this scripts to the background
# the scrip will do
# (1) submit job to run real.exe
# (2)  wait real.exe to finish, then 
#      rename the wrfinput to wrf_mean, split the wrfbdy
# (3) submit icbc.sh
# how to change, when switch between DA icbc and FC icbc, 
#change  ICBC_STAGE, INITIAL_DATE_WPS, CHEM. right now, don't need to change, just use 'DA', use fnl in the forecast
set -x
export SCRIPT_DIR=$SSS/test/shell
export ICBC_RUN_DIR=$SSS/test/icbc 	
export WRFVAR_DIR=$HOME/wrf/wrfda-3.7
export TOOL_DIR=$WRFVAR_DIR/var/da
export TEMPLATE_DIR=$HOME/template									
export WPS_RUN_DIR=$SSS/test/wps
export WRF_CHEM_DIR=$HOME/wrf/wrfchem-3.9.1-gocart-dust0.5-seas0.4
export WRF_RUN_DIR=$SSS/test/wrf/run-wrf	#?? can change to a different DIR in forecast stage
export CHEM_BACKGROUND=''					#? copy emission files,initial chem file, to this directory
export DART_DIR=$HOME/lanai					
	

export INITIAL_DATE_ICBC=2010082112			#?  can be different from  initial wps
export DA_TIME_WINDOW=144					#?144
export INITIAL_DATE_WPS=new  			    #? time as well as name of the wps directory which contain met_em*, its different in Da and forecast
	 										#   if you manually run real.exe already , this setting is not matter
export LBC_FREQ=6		            		# lateral boundary condition frequency
export MAX_DOM=1	
export FCST_RANGE=192						#??? forecast length after the DA_TIME_WINDOW
export NEST_I_PARENT_START=1
export NEST_J_PARENT_START=1
export ICBC_STAGE='DA' 						#? short term or long term 'DA' or 'FC'
export CHEM=true							#? with chem or without chem, if it is forecast stage, no chem
export RUN_REAL_MANUALLY=true				#? have you already run real.exe , if yes, set to true, then copy wrfinput_d01, wrfinput_d01.* wrfbdy to $WRF_RUN_DIR
export timestep=180							#?  wrf timestep	
#===========
export ENS_SIZE=40							#? if you change the ens_size, do not need to perturb agian, change add_member to true
export first_new_member_id=1		     	#? add_member or you want to perturb again,
export add_member=false						#? add_member or you want to perturb again,
#export all_ic_times=false
#=================

if [[ $add_member = false ]]; then			# skip this block if we add new member

	if [[ ! -d $WRF_RUN_DIR ]];then mkdir -p $WRF_RUN_DIR ; fi


	#=======================================
	# set the different time for data assimilation stage and forecast stage
	#=============================================

	if [[ $ICBC_STAGE == 'DA' ]]; then
		export  start_date=$INITIAL_DATE_ICBC
		export  end_date=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_ICBC $DA_TIME_WINDOW)
		export  fcst_hour=$DA_TIME_WINDOW
	else
		export  start_date=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_ICBC $DA_TIME_WINDOW)
		export  end_date=$($TOOL_DIR/da_advance_time.exe $start_date $FCST_RANGE)		#?
		export  fcst_hour=$FCST_RANGE
	fi
	# ---------------------------------------------------------------------------------
	
	cd $WRF_RUN_DIR

	if [[ $RUN_REAL_MANUALLY != true ]];then   #run  real.exe     see another script real.sh	

		######
		#MP2
		######

		VAR="WRF_RUN_DIR=$WRF_RUN_DIR,WPS_RUN_DIR=$WPS_RUN_DIR,INITIAL_DATE_WPS=$INITIAL_DATE_WPS,WRF_CHEM_DIR=$WRF_CHEM_DIR,start_date=$start_date,end_date=$end_date,CHEM=$CHEM,MAX_DOM=$MAX_DOM,timestep=$timestep,TEMPLATE_DIR=$TEMPLATE_DIR,fcst_hour=$fcst_hour,TEMPLATE_DIR=$TEMPLATE_DIR,CHEM_BACKGROUND=$CHEM_BACKGROUND"				

		WRFJOB=$(ssh ip14 "qsub -v $VAR $SCRIPT_DIR/real.sh")

		while [[ $(grep -c "SUCCESS COMPLETE REAL_EM INIT" rsl.out.0000 )  -eq 0 ]];do
			sleep 10
		done


		##########
		## IBM
		########

		#	$SCRIPT_DIR/real.sh

		########


		# IBM setting
		#module load netcdf/4.1.2_nc3
		#module load nco/4.0.8

		#export NETCDF=/scinet/tcs/Libraries/netcdf-4.1.2_nc3
		#export PATH=$NETCDF/bin:$PATH
		#export LD_LIBRARY_PATH=$NETCDF/lib:$LD_LIBRARY_PATH
		########																	#rename files 
		# ----------------------------------------------------------------------------------------------
	fi

	#---------------------------------------
	# 	link the files in the Run directory to the $ICBC_DATA_DIR directory, 
	#   different start time has different  ICBC_DATA_DIR
	#---------------------------------------
	export ICBC_DATA_DIR=${ICBC_RUN_DIR}/${start_date}

									
	if [[ ! -d $ICBC_DATA_DIR ]]; then mkdir -p $ICBC_DATA_DIR; fi

	cd $ICBC_DATA_DIR
	cp -sf $WRF_RUN_DIR/wrfbdy* .
	ln -sf $WRF_RUN_DIR/wrfinput* .

	#---------------------------
	# do loop to rename the wrfinput file , and split the wrfbdy file into small files
	#---------------------------

	export NANALYSIS=$(expr $fcst_hour \/ $LBC_FREQ \+ 1)

	it=1
	this_date=$start_date
	while [[ $it -le $NANALYSIS ]] ; do
		temp=$($TOOL_DIR/da_advance_time.exe $this_date 0 -g)
		g_date[0]=$(echo $temp|cut -f1 -d' ')
		g_date[1]=$(echo $temp|cut -f2 -d' ')				# g_date is the ID of this time
		this_date_wrf=$($TOOL_DIR/da_advance_time.exe $this_date 0 -w)			#this_date_wrf is the time in wrf format 
		echo $g_date[0] $g_date[1] $this_date_wrf
																			
		if [[ $it -eq 1 ]] ; then	#(1)change name for wrfinput_d01

			id=1
			while [[ $id -le $MAX_DOM ]] ; do
				cp wrfinput_d0$id  $ICBC_DATA_DIR/wrfinput_d0${id}_mean_${g_date[0]}_${g_date[1]}
				#####
				# add chemistry   #?? 	
				########
				#if [[ $CHEM = true ]];then	
				#  	ncks -A -v BACKG_H2O2,BACKG_NO3,BACKG_OH,BC1,BC2,DUST_1,DUST_2,DUST_3,\
				#DUST_4,DUST_5,EROD,DMS_0,OC1,OC2,P10,P25,SEAS_1,SEAS_2,SEAS_3,SEAS_4,dms,msa,qke,so2,sulf  $CHEM_BACKGROUND/wrfout_d01_${this_date_wrf}   $ICBC_DATA_DIR/wrfinput_d0${id}_mean_${g_date[0]}_${g_date[1]}
				#fi																													       
				 
				(( id = id + 1 ))
			done

		else						#(2)change name for wrfinput_d01.???			

			(( itp1 = it - 1 ))		#it begin from 2 in this condition, so itp1 begin from 1, the first index in the fortran array	
			cp wrfinput_d01.${this_date_wrf}  $ICBC_DATA_DIR/wrfinput_d01_mean_${g_date[0]}_${g_date[1]} 

			##########
			# add chemistry		#?
			#######
			#if [[ $CHEM = true ]];then	
			#     ncks -A -v BACKG_H2O2,BACKG_NO3,BACKG_OH,BC1,BC2,DUST_1,DUST_2,DUST_3,\
			#DUST_4,DUST_5,EROD,DMS_0,OC1,OC2,P10,P25,SEAS_1,SEAS_2,SEAS_3,SEAS_4,dms,msa,qke,so2,sulf  $CHEM_BACKGROUND/wrfout_d01_${this_date_wrf}   $ICBC_DATA_DIR/wrfinput_d01_mean_${g_date[0]}_${g_date[1]} 																											  																																		
			  # fi
		 																																		
			ncks -F -O -d Time,${itp1}  $WRF_RUN_DIR/wrfbdy_d01 $ICBC_DATA_DIR/wrfbdy_d01_mean_${g_date[0]}_${g_date[1]}		#-F is in Fortran arry 
		fi

		(( it = it + 1 ))
		this_date=$($TOOL_DIR/da_advance_time.exe $this_date $LBC_FREQ)

	done

fi 	
# -------------  the result is: the number of wrfinput files is one more than the wrfbdy files.-----------------



#--------------------
# run icbc.sh				can add new member
#---------------------   

if [[ -d $ICBC_RUN_DIR/working ]];then
	if [[ $add_member = false ]]; then
		\rm -rf $ICBC_RUN_DIR/working
		mkdir $ICBC_RUN_DIR/working
	fi
else 
	mkdir $ICBC_RUN_DIR/working
fi


####
# mp2
######
VAR="ICBC_STAGE=$ICBC_STAGE,INITIAL_DATE_ICBC=$INITIAL_DATE_ICBC,TOOL_DIR=$TOOL_DIR,DA_TIME_WINDOW=$DA_TIME_WINDOW,\
FCST_RANGE=$FCST_RANGE,LBC_FREQ=$LBC_FREQ,ICBC_RUN_DIR=$ICBC_RUN_DIR,WRFVAR_DIR=$WRFVAR_DIR,DART_DIR=$DART_DIR,\
MAX_DOM=$MAX_DOM,ENS_SIZE=$ENS_SIZE,TEMPLATE_DIR=$TEMPLATE_DIR,ICBC_DATA_DIR=$ICBC_DATA_DIR"


 ssh ip14  "qsub -t ${first_new_member_id}-$ENS_SIZE -W depend=afterokarray:$WRFJOB  -v $VAR $SCRIPT_DIR/icbc.sh"

###
#IBM
###

#id=${first_new_member_id}
#while [[ $id -le $ENS_SIZE ]];do
#export PBS_ARRAYID=$id
#chmod +x $SCRIPT_DIR/icbc.sh
#llsubmit $SCRIPT_DIR/icbc.sh 
#(( id=id+1 ))
#done



