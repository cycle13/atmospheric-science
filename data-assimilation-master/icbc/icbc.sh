#!/bin/bash

#-----------------------------------------------------------------------
# Script run_ens_icbc.ksh
# usage: qsub -t 1-10 icbc.sh       
# Purpose:  generating perturbed IC/BC's using WRFVAR
#PBS -l nodes=1
#PBS -l walltime=8:00:00			 
###PBS -q qfbb@mp2		
#PBS -q qwork@mp2
#PBS -N piano					
#PBS -e	output.icbc.err				
#PBS -o	output.icbc					 
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
set -x
#export DART_DIR=$S/dart/kodiak
#export TEMPLATE_DIR=$S/test/template
#export ICBC_RUN_DIR=$S/test/icbc
#export WRF_RUN_DIR=$S/test/wrf/run
#export WRF_DIR=$S/wrf/wrfv3
#export WRFVAR_DIR=$S/wrf/wrfda
#export TOOL_DIR=$WRFVAR_DIR/var/da
#export ENS_SIZE=50							
#export DA_TIME_WINDOW=264				
#export INITIAL_DATE_ICBC=2010081300			
#export ICBC_STAGE='DA'
#export LBC_FREQ=6               
#export MAX_DOM=1
#export FCST_RANGE                                                                  
##################
####
## mp2
#######
#module unload mvapich2_pgi64/1.6_ofed																				#?
#module load  mvapich_pgi64/1.2.0_ofed
###################

export ie=$PBS_ARRAYID
if [[ $ICBC_STAGE == 'DA' ]]; then
   start_date=$INITIAL_DATE_ICBC
   end_date=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_ICBC $DA_TIME_WINDOW)
   fcst_hour=$DA_TIME_WINDOW
else
   start_date=$($TOOL_DIR/da_advance_time.exe $INITIAL_DATE_ICBC $DA_TIME_WINDOW)
   end_date=$($TOOL_DIR/da_advance_time.exe $start_date $FCST_RANGE)				#?
   fcst_hour=$FCST_RANGE
fi
export NANALYSIS=$(expr $fcst_hour \/ $LBC_FREQ \+ 1)
	cd $ICBC_RUN_DIR/working
	if [[ -d $ie ]]; then rm -rf $ie; fi
	mkdir $ie
	cd $ie
	ln -sf $WRFVAR_DIR/run/LANDUSE.TBL .
	ln -sf $WRFVAR_DIR/run/gribmap.txt .		
	ln -sf $WRFVAR_DIR/var/run/be.dat.cv3 be.dat
	ln -sf $WRFVAR_DIR/var/build/da_wrfvar.exe .
	ln -sf $DART_DIR/models/wrf/work/pert_wrf_bc .
	echo >ob.ascii
  ICBC_DATA_DIR=${ICBC_RUN_DIR}/${start_date}								

   m4 -D_FIRST_OBS_DAYS_=-1 -D_FIRST_OBS_SECONDS_=-1 \
      -D_LAST_OBS_DAYS_=-1 -D_LAST_OBS_SECONDS_=-1 \
      -D_MAX_DOM_=$MAX_DOM -D_ENS_SIZE_=$ENS_SIZE \
      $TEMPLATE_DIR/input.nml.back > input.nml 								#?
										
#-------------run 3dvar and update the bdy, the input are from the working/$start_date directory
 #----------
 # run wrf 3dvar
 #-------------
   this_date=$start_date		
   cd $ICBC_RUN_DIR/working/$ie
   it=1
   while [[ $it -le $NANALYSIS ]] ; do
      temp=$($TOOL_DIR/da_advance_time.exe $this_date 0 -g)
  		g_date[0]=$(echo $temp|cut -f1 -d' ')
  		g_date[1]=$(echo $temp|cut -f2 -d' ')
      this_date_wrf=$($TOOL_DIR/da_advance_time.exe $this_date 0 -w)
      this_date_seed=$($TOOL_DIR/da_advance_time.exe $this_date 0 -f hhddmmyycc)		# hhddmmyycc, the order is reversed, so it change a lot in every time   
      seed_array1=$this_date_seed													
      (( seed_array2 = ie * 100000 ))
      var_scaling0=1.0
      if [[ $ICBC_STAGE == 'DA' ]]; then
         var_scaling1=$var_scaling0
         var_scaling2=$var_scaling0
         var_scaling3=$var_scaling0
         var_scaling4=$var_scaling0
         var_scaling5=$var_scaling0
      else
         (( fc_hour = ( it - 1 ) * LBC_FREQ ))
         var_scaling1=$(echo "sqrt(sqrt($fc_hour)) + $var_scaling0" |bc -l)
         var_scaling2=$var_scaling1
         var_scaling3=$var_scaling1
         var_scaling4=$var_scaling1
         var_scaling5=$var_scaling1
      fi
      yyyy=$(echo $this_date | cut -c 1-4)
        mm=$(echo $this_date | cut -c 5-6)
        dd=$(echo $this_date | cut -c 7-8)
        hh=$(echo $this_date | cut -c 9-10)
      m4 -D_ANALYSIS_DATE_=$this_date_wrf \
         -D_SEED_ARRAY1_=$seed_array1 -D_SEED_ARRAY2_=$seed_array2 \
         -D_VAR_SCALING1_=$var_scaling1 -D_VAR_SCALING2_=$var_scaling2 \
         -D_VAR_SCALING3_=$var_scaling3 -D_VAR_SCALING4_=$var_scaling4 \
         -D_VAR_SCALING5_=$var_scaling5 \
         -D_START_YEAR_=$yyyy -D_START_MONTH_=$mm -D_START_DAY_=$dd -D_START_HOUR_=$hh \
         -D_END_YEAR_=$yyyy -D_END_MONTH_=$mm -D_END_DAY_=$dd -D_END_HOUR_=$hh \
         $TEMPLATE_DIR/namelist.input.3dvar  > namelist.input						          #?
      ln -sf $ICBC_DATA_DIR/wrfinput_d01_mean_${g_date[0]}_${g_date[1]} ./fg

#--------------------------------------------
# use mvapich here, not working on mvapich2		#?
#--------------------------------------------
   mpdboot -n $PBS_NUM_NODES -f $PBS_NODEFILE > /dev/null 2>&1
   mpiexec  -f $PBS_NODEFILE  -n $[PBS_NUM_NODES*ppn] -ppn $ppn   ./da_wrfvar.exe >> stdout

########
# IBM
########
#\rm rsl.error.* rsl.out*
#m4 -D_LLDIR_='#@ initialdir ='$ICBC_RUN_DIR/working/$ie  $SCRIPT_DIR/run_icbc_template.sh > run_icbc.sh
#llsubmit run_icbc.sh
#cd $ICBC_RUN_DIR/working/$ie 
#./da_wrfvar.exe			>>da_error.txt

if [[ ! -e wrfvar_output ]];then 
exit  
 fi

#while true
#do 
#	if [[ $(grep -c "successfully" rsl.error.0000)  -ne 1 ]];then
# 		echo "waiting for da to finish , sleep 1min" >>wait-wrf.log
# 		sleep 60
#	else
		
#		echo "finish da, sleep 5s" >>wait-wrf.log
#	 sleep 5
#		break
#	fi
#done

 
#export NETCDF=/scinet/tcs/Libraries/netcdf-4.1.2_nc3
#export PATH=$NETCDF/bin:$PATH
#export LD_LIBRARY_PATH=$NETCDF/lib:$LD_LIBRARY_PATH

#############################
  cp $ICBC_DATA_DIR/wrfinput_d01_mean_${g_date[0]}_${g_date[1]} .
   ncks -A -v U,V,W,PH,T,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,QNICE,MUB,MU,MAPFAC_U,MAPFAC_V,MAPFAC_M,P,TH2,T2,Q2,PSFC wrfvar_output wrfinput_d01_mean_${g_date[0]}_${g_date[1]}   #???????
   mv wrfinput_d01_mean_${g_date[0]}_${g_date[1]} $ICBC_DATA_DIR/wrfinput_d01_${g_date[0]}_${g_date[1]}_$ie


       # -------------------------
      # update wrfbdy
      # -------------------------

      if [[ it -eq 1 ]] ; then
         ln -sf $ICBC_DATA_DIR/wrfinput_d01_${g_date[0]}_${g_date[1]}_$ie wrfinput_this
      else
         ln -sf $ICBC_DATA_DIR/wrfinput_d01_${g_date[0]}_${g_date[1]}_$ie wrfinput_next
         cp $ICBC_DATA_DIR/wrfbdy_d01_mean_${g_date[0]}_${g_date[1]} wrfbdy_this
         ./pert_wrf_bc > output.pert_wrf_bc.${g_date[0]}_${g_date[1]} 2>&1
         mv wrfbdy_this $ICBC_DATA_DIR/wrfbdy_${g_date[0]}_${g_date[1]}_$ie
         ln -sf $ICBC_DATA_DIR/wrfinput_d01_${g_date[0]}_${g_date[1]}_$ie wrfinput_this
      fi

      (( it = it + 1 ))
      this_date=$($TOOL_DIR/da_advance_time.exe $this_date $LBC_FREQ)
   done

   cd ..


#----------------------------------command about summitting the job , ignore in this cluster --------------------------------------------
# ------------------------------
# create a command-file for mpmd
# ------------------------------
#É   if [[ -f $mpmd_cmdfile && ie -eq 1 ]]; then \rm $mpmd_cmdfile ; fi																#?
#É   echo $ie/run_wrfvar_script.ksh $ie $start_date >> $mpmd_cmdfile
#É   if [[ ie -eq $ENS_SIZE ]]; then echo wait >> $mpmd_cmdfile ; fi

#  (( ie = ie + 1 ))
# done
#-----------------------------------------------------------------------------------------
# -------------------------
# for DA, create filter_ics 

#------  see another script
#      ./creat-filter-ics.sh

# -------------------------
# for Forcast , merge perturbed bc
# -------------------------
#if [[ $ICBC_STAGE == 'FC' ]]; then															#?? if you want to merge in the DA stage, delete this "if"
   cd $ICBC_DATA_DIR
#?   ie=1
#?   while [[ ie -le ENS_SIZE ]]; do


      ncrcat -O wrfbdy_[1-9][0-9]????_*_$ie wrfbdy_d01_$ie	#combine all the bdy data
#	    ncrcat -O wrfbdy_??????_*_$ie wrfbdy_d01_$ie

#      (( ie = ie + 1 ))
#   done
#fi

cd $ICBC_RUN_DIR

# ----------------
# clean working dir
# ----------------
#if $CLEAN; then
#   \rm -rf $ICBC_RUN_DIR/working
#fi


