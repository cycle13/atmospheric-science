#!/bin/bash
#PBS -l nodes=8
#PBS -l walltime=3:30:00
#PBS -q qwork@mp2
#PBS -e output.err                               
#PBS -o output 
#PBS -N piano 
#PBS -r n
 
export ppn=24


######################

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
#@ wall_clock_limit= 01:00:00
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



set -x
#--------------------------- Self test block---------------------
#export WRF_DIR=$S/wrf/wrfv3
#export WRF_RUN_DIR=$s/test/wrf
#export DART_RUN_DIR=$S/test/dart
#export WRFVAR_DIR=$S/wrf/wrfda
#export DART_DIR=$S/dart/kodiak
#export TOOL_DIR=$WRFVAR_DIR/var/da
#export num_wrf_per_job      # default is 1 if you do not specify
#export ENS_SIZE=2									# delete
#export INITIAL_DATE_DART=20100824			# delete
#export DA_START_DATE=20100824000000    # delete
#export DA_END_DATE=20100824000000    # delete
#export THIS_DA_BDY_DATE=20100824000000		# delete
#export THIS_ANALYSIS_DIR=$DART_RUN_DIR/20100824000000    # delete
##########################################

LSB_JOBINDEX=$PBS_ARRAYID
echo $LSB_JOBINDEX  >> $DART_RUN_DIR/check
#LSB_JOBINDEX=$((PBS_ARRAYID+1))		


(( mem_start = ( LSB_JOBINDEX - 1 ) * num_wrf_per_job + 1 ))
(( mem_end =  LSB_JOBINDEX * num_wrf_per_job ))
mem=$mem_start

while (( $mem <= $mem_end  &&  $mem <= $ENS_SIZE )); do

	memdir=${DART_RUN_DIR}/working/${mem}

	if [[ ! -e $memdir ]]; then 
		mkdir -p $memdir; 
	fi

	cd $memdir

	#--------------
	# time 
	#---------------
	temp=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE 0 -g)
	this_start_date_g[0]=$(echo $temp|cut -f1 -d' ')
	this_start_date_g[1]=$(echo $temp|cut -f2 -d' ')
	this_start_date_w=$($TOOL_DIR/da_advance_time.exe $THIS_DA_START_DATE 0 -w)

	temp=$($TOOL_DIR/da_advance_time.exe $THIS_DA_BDY_DATE 0 -g)
	this_bdy_date_g[0]=$(echo $temp|cut -f1 -d' ')
	this_bdy_date_g[1]=$(echo $temp|cut -f2 -d' ')
	 
	temp=$($TOOL_DIR/da_advance_time.exe $THIS_DA_END_DATE 0 -g)
	this_end_date_g[0]=$(echo $temp|cut -f1 -d' ')
	this_end_date_g[1]=$(echo $temp|cut -f2 -d' ')	 
	this_end_date_w=$($TOOL_DIR/da_advance_time.exe $THIS_DA_END_DATE 0 -w)
	start_date_icbc=$INITIAL_DATE_ICBC

	#--------------
	# check if the fold has been sucessuflly ran before
	#-------------------

	if [[ -e wrfout_d01_${this_end_date_w}.prior ]];then

		(( mtmp = 10000 + mem ))
		mm=$(echo $mtmp |cut -c2-5)

		../wrf_to_dart  > output.wrf-to-dart 2>&1
		mv  dart_wrf_vector  $FILTER_RUN_DIR/filter_ics.$mm		

	else

		#-----------------
		# link and remove 
		#---------------
		ln -sf $WRF_CHEM_DIR/run/* .

		\rm namelist.input

		if [[ -e wrfinput_d* ]];then 
			\rm wrfinput_d*; 
		fi
		if [[ -e wrfbdy_d01 ]];then 
			\rm wrfbdy_d01; 
		fi

		cp ../namelist.input .
		cp ../input.nml .

		if [[ $(ls rsl.* |wc -l) -ne 0 ]]; then 
			\rm rsl.* ; 
		fi

		#-----------------------------------
		# prepare wrfinput and wrfbdy files
		#-----------------------------------

		#(1) wrfinput: 
		(( mtmp = 10000 + mem ))
		mm=$(echo $mtmp |cut -c2-5)
	   

		# -----------------
		# copy emission file
		#------------------
	 
		#if [[ $CHEM = true ]]; then
		#	cp  ../wrfchemi_00z_d01 .		#? may be different emission file in the future
	  	#	cp  ../wrfchemi_12z_d01  .
	  	#	cp  ../wrfchemi_gocart_bg_d01  .
		#fi
	   	
		
		# [1] NOT SKIP filter
		if [[ $SKIP_FILTER_AT_BEGINNING = false  ]]; then			


			if [[ $HAVE_OBS == true ]]; then									 
				cp ../filter_restart.$mm dart_wrf_vector
			fi
	  
			# --------------
			# creat wrfinput_d01 template,  it is very important, especially for Chem, be careful 
			#-------------
			if [[ -e wrfinput_d01 ]]; then 
				\rm wrfinput_d01; 
			fi		
	  
			if $ISFIRST; then			
				if $IS_FROM_ICBC; then	
					echo "ln -sf   $ICBC_RUN_DIR/$start_date_icbc/wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_$mem  wrfinput_d01" >>log
					cp    $ICBC_RUN_DIR/$start_date_icbc/wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_$mem  wrfinput_d01
				else					
					echo "ln -sf   $PRE_RUN_DIR/working/$mem/wrfout_d01_${this_start_date_w}.prior  wrfinput_d01" >> log    
					cp   $PRE_RUN_DIR/working/$mem/wrfout_d01_${this_start_date_w}.prior  wrfinput_d01
				fi

				cp    wrfinput_d01    wrfout_d01_${this_start_date_w}.prior      # keep the record, use in the post analysis
							
	  		else     									
	  	    	echo "ln -sf   wrfout_d01_${this_start_date_w}.prior  wrfinput_d01" >>log  # use the previous wrfoutput in the same directory
	  			cp wrfout_d01_${this_start_date_w}.prior  wrfinput_d01
			fi

	
			#----------------
			# update wrfinput_d01
			#----------------			
			../dart_to_wrf  > output.dart-to-wrf
			cp wrfinput_d01 wrfout_d01_${this_start_date_w}.post

			###
			if [[ $CHEM = true ]]; then
				####
				# IBM
				#######

				#    module unload netcdf/4.0.1_nc3
				#   module load netcdf/4.1.2_nc3
				#    export NETCDF=/scinet/tcs/Libraries/netcdf-4.1.2_nc3
				#   export PATH=$NETCDF/bin:$PATH
				#   export LD_LIBRARY_PATH=$NETCDF/lib:$LD_LIBRARY_PATH
				#    module load nco/4.0.8

				####
				#   module unload netcdf/4.1.2_nc3
				#   module load netcdf/4.0.1_nc3
				#   export NETCDF=/scinet/tcs/Libraries/netcdf-4.0.1_nc3
				#   export PATH=$NETCDF/bin:$PATH
				#   export LD_LIBRARY_PATH=$NETCDF/lib:$LD_LIBRARY_PATH
				echo "haha"	
				#########
				#ncatted -O -a MMINLU,global,m,c,"USGS" wrfinput_d01  	
			fi

			#-------------------------
			#  link and update bdy: 
			#---------------------------

			if [[ -e wrfbdy_d01 ]]; then 
				\rm wrfbdy_d01; 
			fi				

			cp  ../WRF/wrfbdy_${this_bdy_date_g[0]}_${this_bdy_date_g[1]}_$mem wrfbdy_d01
			echo "cp  ../WRF/wrfbdy_${this_bdy_date_g[0]}_${this_bdy_date_g[1]}_$mem wrfbdy_d01" >> wrfinput-wrfbdy.log

			# or  cp ../WRF/wrfbdy_d01_$mem wrfbdy_d01	     # for forecast,update the whole wrfbdy file
			
			../update_wrf_bc > output.update_wrf_bc 2>&1         #  update bdy

			#  ln -sf ../WRF/wrflowinp_d01 .

		#[2] SKIP filter
		else 			# if skip the first time, , use the preexist wrfinput_d01, do not need to read filter_restart.

			if $IS_FROM_ICBC; then
				ln -sf  ../WRF/wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_$mem wrfinput_d01		
				echo "wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_$mem" >>wrfinput-wrfbdy.log
				ln -sf   ../WRF/wrfbdy_${this_bdy_date_g[0]}_${this_bdy_date_g[1]}_$mem    wrfbdy_d01
				echo "wrfbdy_${this_bdy_date_g[0]}_${this_bdy_date_g[1]}_$mem"  >wrfinput-wrfbdy.log	
			else
				ln -sf  ${PRE_RUN_DIR}/wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_$mem wrfinput_d01		
				echo "${PRE_RUN_DIR}/wrfinput_d01_${this_start_date_g[0]}_${this_start_date_g[1]}_$mem" >>wrfinput-wrfbdy.log
				ln -sf   ${PRE_RUN_DIR}/wrfbdy_${this_bdy_date_g[0]}_${this_bdy_date_g[1]}_$mem    wrfbdy_d01
				echo "${PRE_RUN_DIR}/wrfbdy_${this_bdy_date_g[0]}_${this_bdy_date_g[1]}_$mem"  >wrfinput-wrfbdy.log
			fi

		fi 				

		#-----------------------------------
		# run wrf.exe
		#-----------------------------------
		echo $THIS_DA_START_DATE >>run-time
		echo 'Begin-run' $(date) >>run-time

		#########
		### mp2
		########  
		#openmpi
		#mpiexec -n $[PBS_NUM_NODES*ppn] -npernode $ppn ./wrf.exe  >> stdout

		########  
		mpdboot -n $PBS_NUM_NODES -f $PBS_NODEFILE > /dev/null 2>&1
		mpiexec  -f $PBS_NODEFILE  -n $[PBS_NUM_NODES*ppn] -ppn $ppn  ./wrf.exe   >>run_wrf.log


		##########
		# IBM
		##############
		#./wrf.exe

		echo 'End-run' $(date) >>run-time

		########################################

		#  mv wrfinput_d01 wrfinput_d01_last_post			
		#  mv wrfinput_d02 wrfinput_d02_last_post

		#-----------------------

		if [[ -e dart_wrf_vector ]]; then 
			\rm dart_wrf_vector; 
		fi


		if [[ $(grep -c "wrf: SUCCESS COMPLETE WRF" rsl.out.0000 )  -eq 0 ]]; then	#run wrf fail
			echo $mem >> ${DART_RUN_DIR}/working/fail_${THIS_DA_END_DATE}.out
			exit
			#     cp wrfinput_d01_last_post wrfinput_d01
			#     cp wrfinput_d02_last_post wrfinput_d02
	
			#---------------------
			# if that member fail, reduce the time step and resubmitt it again
			#------------------------

			# while [[ $(grep -c "wrf: SUCCESS COMPLETE WRF" rsl.out.0000 )  -eq 0 && ($timestep -gt 0)  ]];do
			#	(( timestep2=timestep-20 ))
			#	sed  "s/${timestep}/${timestep2}/g" namelist.input >namelist.input.2
			#	(( timestep=timestep2 ))

			#	rm namelist.input
			#	mv namelist.input.2 namelist.input
			#	rm rsl.*

			#	echo $THIS_DA_START_DATE >>run-time
			#	echo 'Begin-run' $(date) >>run-time
			#	mpdboot -n $PBS_NUM_NODES -f $PBS_NODEFILE > /dev/null 2>&1
			#	mpiexec  -f $PBS_NODEFILE  -n $[PBS_NUM_NODES*ppn] -ppn $ppn  ./wrf.exe
			#	echo 'End-run' $(date) >>run-time

			#done 

			#if [[ $(grep -c "wrf: SUCCESS COMPLETE WRF" rsl.out.0000 )  -eq 0 ]]; then	#run wrf fail
			#	echo "${mem}fail finally" >> ${DART_RUN_DIR}/working/fail_${this_end_date_w}_${this_end_date_g[0]}_${this_end_date_g[1]}.out
			#	exit
			#else  	# If succussful

			#	rm wrfout_d01_${this_end_date_w}.prior wrfinput_d01
			#	cp wrfout_d01_${this_end_date_w} wrfout_d01_${this_end_date_w}.prior  # need to backup or next cycles's prior 
			#	cp wrfout_d01_${this_end_date_w} wrfinput_d01			    # rename , for wrf_to_dart
			#	cp wrfout_d02_${this_end_date_w} wrfinput_d02	
			#fi 

		else

			\rm wrfout_d01_${this_end_date_w}.prior wrfinput_d01
			cp wrfout_d01_${this_end_date_w} wrfout_d01_${this_end_date_w}.prior  # need to backup or next cycles's prior 
			cp wrfout_d01_${this_end_date_w} wrfinput_d01			   			 # rename , for wrf_to_dart
			#     cp wrfout_d02_${this_end_date_w} wrfinput_d02	
			
		fi

		../wrf_to_dart  > output.wrf-to-dart 2>&1
		   

		mv  dart_wrf_vector  $FILTER_RUN_DIR/filter_ics.$mm									

	fi	# end of simulation for that member

	(( mem = mem + 1 ))

done

exit



