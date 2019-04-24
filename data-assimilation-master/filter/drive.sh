#!/bin/bash
# Purpose: run filter


export SCRIPT_DIR=$S/test/shell	
((option=3))
cd $SCRIPT_DIR

#-------------------
# no chem, convension 	 
#---------------------
if [[ $option = 1 ]]; then 

export INPUT_NML_APT=input.nml.conv
export NAMELIST_INPUT=namelist.input.gocart.turnoff.chem.template
export DART_RUN_DIR=$S/test/dart/dart-nochem-assim-conv-30mem
export FILTER_DIR=$S/test/dart/filter-nochem-assim-conv-30mem
export CHEM=false
export DART_DIR=$HOME/lanai                                                    #?  dart2 have locolizaton,
export SCRIPT_NAME=dart-nochem-assim-conv-30mem.sh
export PRE_RUN_DIR=none
export READ_PREVIOUS_INFLATION=false        #?	# if fail in the middle,  set it to true


#-------------------
# no chem, convension+airs	 
#---------------------
elif [[ $option = 2 ]]; then 
export INPUT_NML_APT=input.nml.conv.airs
export NAMELIST_INPUT=namelist.input.gocart.turnoff.chem.template
export DART_RUN_DIR=$S/test/dart/dart-nochem-assim-conv-airs-30mem-2
export FILTER_DIR=$S/test/dart/filter-nochem-assim-conv-airs-30mem
export CHEM=false
export DART_DIR=/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/lanai-openmpi-2                                                   
export SCRIPT_NAME=dart-nochem-assim-conv-airs-30mem.sh
export PRE_RUN_DIR=$S/test/dart/dart-nochem-assim-conv-airs-30mem		
export READ_PREVIOUS_INFLATION=true       

#----------------------
# with chem, convension +aod
#--------------------
elif [[ $option = 3 ]]; then 
export INPUT_NML_APT=input.nml.conv.aod
export NAMELIST_INPUT=namelist.input.gocart.template
export DART_RUN_DIR=$SS/test/dart/dart-chem-assim-conv-aod-30mem-3
export FILTER_DIR=$SS/test/dart/filter-chem-assim-conv-aod-30mem
export CHEM=true
export DART_DIR=$HOME/lanai-mvp                                                   
export SCRIPT_NAME=dart-chem-assim-conv-aod-30mem.sh
export PRE_RUN_DIR=$SS/test/dart/dart-chem-assim-conv-aod-30mem-3
export READ_PREVIOUS_INFLATION=true        

#----------------------
# with chem, convension +airs+aod
#--------------------
elif [[ $option = 4 ]]; then 
export INPUT_NML_APT=input.nml.conv.airs.aod
export NAMELIST_INPUT=namelist.input.gocart.chem.template
export DART_RUN_DIR=$S/test/dart/dart-chem-assim-conv-airs-aod-30mem
export FILTER_DIR=$S/test/dart/filter-chem-assim-conv-airs-aod-30mem
export CHEM=true
export DART_DIR=$HOME/lanai                                                   
export SCRIPT_NAME=dart-chem-assim-conv-airs-aod-30mem.sh
export PRE_RUN_DIR=none
export READ_PREVIOUS_INFLATION=false        



fi
#=-==================


cd  $SCRIPT_DIR
chmod +x run_dart_wrf_1.sh
m4 -D_INPUT_NML_APT_=$INPUT_NML_APT  -D_INPUT_NML_FIX_=$INPUT_NML_FIX -D_NAME_LIST_=$NAMELIST_INPUT   \
-D_DART_RUN_DIR_=$DART_RUN_DIR  -D_FILTER_RUN_DIR_=$FILTER_DIR   -D_CHEM_=$CHEM	  \
-D_SCRIPT1_=$SCRIPT_NAME  -D_DART_DIR_=$DART_DIR -D_PRE_RUN_DIR_=$PRE_RUN_DIR	 \
-D_READ_PREVIOUS_INFLATION_=$READ_PREVIOUS_INFLATION     run_dart_wrf_1.sh  >   $SCRIPT_NAME
 
chmod +x $SCRIPT_NAME
qsub $SCRIPT_NAME	#? 		

#======================
# back up the namelist
#=======================
if [[ ! -d $DART_RUN_DIR/working ]]; then 
	mkdir -p $DART_RUN_DIR/working
fi

cd $DART_RUN_DIR

if [[ ! -d ${DART_RUN_DIR}/namelist ]]; then 
	mkdir -p ${DART_RUN_DIR}/namelist
fi

cd ${DART_RUN_DIR}/namelist
cp ${SCRIPT_DIR}/drive.sh .
cp ${SCRIPT_DIR}/run_dart_wrf_1.sh  .
cp ${SCRIPT_DIR}/run_dart_wrf_2.sh    .
cp ${SCRIPT_DIR}/$SCRIPT_NAME  .
cp $HOME/template/$INPUT_NML_APT  .
cp $HOME/template/$NAMELIST_INPUT .







