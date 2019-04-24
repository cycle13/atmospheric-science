#!/bin/bash

((option=2))
#-------------
# no chem wrf, 
#----------------
if [[ $option = 1 ]];then
export INPUT_NML=input-assim-meo-no-chem.adapt
export NAMELIST_INPUT=namelist.input.turnoff.chem
export CHEM=false
export SCRIPT_NAME=new-forecast-no-chem-wrf-assim-meo.sh
export FORECAST_RUN_DIR=$S/test/ensemble-forecast-no-chem-from-assim-meto-20mem-icbc
export PRE_RUN_DIR=$S/test/icbc/2010081900
export ICBC_RUN_DIR=$S/test/icbc/2010081900

fi
#-------------------
# chem wrf 
#---------------------
if [[ $option = 2 ]];then
export INPUT_NML=input-assim-meo-no-chem.adapt
export NAMELIST_INPUT=namelist.input.chem
export CHEM=true
export SCRIPT_NAME=new-forecast-chem-wrf-assim-meo.sh
export FORECAST_RUN_DIR=$S/test/ensemble-forecast-chem-from-assim-meto-20mem-icbc-fft-2
export PRE_RUN_DIR=$S/test/fft
export ICBC_RUN_DIR=$S/test/icbc/2010081900
fi



cd $S/test/shell/
chmod +x forecast1.sh
m4 -D_INPUT_NML_=$INPUT_NML -D_NAME_LIST_=$NAMELIST_INPUT     \
-D_CHEM_=$CHEM	   	-D_INITIAL_DATE_FORECAST_=$INITIAL_DATE_FORECAST  \
 -D_FORECAST_RUN_DIR_=$FORECAST_RUN_DIR   -D_PRE_RUN_DIR_=$PRE_RUN_DIR -D_ICBC_RUN_DIR_=$ICBC_RUN_DIR \
 forecast1.sh  >   $SCRIPT_NAME
 
chmod +x $SCRIPT_NAME
 ./$SCRIPT_NAME









