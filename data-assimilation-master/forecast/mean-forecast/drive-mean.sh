#!/bin/bash

((option=3))


#-------------------
# no chem, convension 	 
#---------------------
if [[ $option = 1 ]]; then 


export NAMELIST_INPUT=namelist.input.gocart.turnoff.chem.template
export DART_RUN_DIR=$S/test/dart/dart-nochem-assim-conv-30mem
export CHEM=false
export SCRIPT_NAME=mean-dart-nochem-assim-conv-30mem.sh
export INITIAL_DATE_FORECAST=2010082400
export PRI_POST_MEAN_DIR=$S/test/dart/prior-post-mean-dart-nochem-assim-conv-30mem
export FORECAST_RUN_DIR=$S/test/dart/mean-forecast-dart-nochem-assim-conv-30mem

fi

#-------------------
# no chem, convension+airs	 
#---------------------

if [[ $option = 2 ]]; then 


export NAMELIST_INPUT=namelist.input.gocart.turnoff.chem.template
export DART_RUN_DIR=$S/test/dart/dart-nochem-assim-conv-airs-30mem
export CHEM=false
export SCRIPT_NAME=mean-dart-nochem-assim-conv-airs-30mem.sh
export INITIAL_DATE_FORECAST=2010082400
export PRI_POST_MEAN_DIR=$S/test/dart/prior-post-mean-dart-nochem-assim-conv-airs-30mem
export FORECAST_RUN_DIR=$S/test/dart/mean-forecast-dart-nochem-assim-conv-airs-30mem

fi

#-------------------
# chem, convension+modis	 
#---------------------

if [[ $option = 3 ]]; then 


export NAMELIST_INPUT=namelist.input.gocart.template
export DART_RUN_DIR=$SS/test/dart/dart-chem-assim-conv-aod-30mem-2
export CHEM=true
export SCRIPT_NAME=mean-dart-chem-assim-conv-modis-30mem.sh
export INITIAL_DATE_FORECAST=2010082212
export PRI_POST_MEAN_DIR=$SS/test/dart/prior-post-mean-dart-chem-assim-conv-modis-30mem
export FORECAST_RUN_DIR=$SS/test/dart/mean-forecast-dart-chem-assim-conv-modis-30mem

fi



##############
## calculate the mean
############
cd $S/test/shell/					#??
m4 -D_DART_RUN_DIR_=$DART_RUN_DIR -D_PRI_POST_MEAN_DIR_=$PRI_POST_MEAN_DIR  \
prior-mean-post-mean.sh  > make-mean.sh

chmod u+x   make-mean.sh								
#llsubmit make-mean.sh
qsub make-mean.sh		#qsub or ./

###########
# submit the forecast
#############
 m4  -D_NAME_LIST_=$NAMELIST_INPUT  -D_CHEM_=$CHEM  \
-D_SCRIPT1_=$SCRIPT_NAME   -D_INITIAL_DATE_FORECAST_=$INITIAL_DATE_FORECAST  \
-D_FORECAST_RUN_DIR_=$FORECAST_RUN_DIR -D_PRI_POST_MEAN_DIR_=$PRI_POST_MEAN_DIR \
 mean.sh  >   $SCRIPT_NAME

chmod u+x $SCRIPT_NAME
#qsub $SCRIPT_NAME







