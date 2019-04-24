;https://sites.google.com/site/afcwrf/home/analysis/typhoon/ave_azimuth
; Compute averages in azimuth direction
;https://www.ncl.ucar.edu/Applications/height_lat.shtml
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;=================
; files location  
;================					;???############
dir_a="/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/2010/mosaic/nest/full/"
dir_b="/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/2010/mosaic/nest/full-turnoffdust/"
;dir_a="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/full/"
;dir_b="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/full-turnoffdust/"	
;dir_b="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/other/"		

	
namelist_t = "/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/ncl/namelist-cross" 
				 			;???###### if you plot the wrf restart, just use wrfout*, don't need to create another namelist 	
filename = asciiread(namelist_t,-1,"string") 	; -1 mean only one dimension
ntimes   = dimsizes(filename)
print(filename)

set=$id						;???########

;----set time
start_time=0				;???### 0 is the first time, you can specify 
end_time=8			;???### 999 means at the end of time, you can specify

if (end_time.eq.999)then
	time_end=ntimes-1
else
	time_end=end_time
end if
;---------------
auto_range=False				;???### not apply to the amuth average
have_diff=True				;??? subtraction between two files
nest=True					;???### for plot the slp to show the postion of the center
have_slp_plot=False
rr0=468.0 					;??#### radius of the hurricane,units: km, at 2400, aug, 2010, 500km is the maximum
;clat0_a=12.0	;15;		;????### initial value for the center in file 1		
;clon0_a=-22.0 ;-28.0; 
;clat0_b=12.0	;15;		;????### initial value for the center in file 2
;clon0_b=-22.0  ;-28;
;same_center=False			;???###  if true, use the center in the file1
;center_search_half_size0=10  ;??####  depend on the model resolution

add_zero_temperatureline=True ;tc must be in your varialbe list.
vertical_type=1				;???####1 is the height coordinate, 2 is pressure coordinate; right now, only 1 works
zmax0=15					;???###
angle=(/999.,0.,45.,90.,135./)			;???### first is 999. , do not change. other number are in degree, anticlockwise ,0 is positive x asix direction

;-----------
; hurricane position, ;!! be careful, the time here should match  namelist , otherwise, if start_time .ne.0, may cause mismatch
;----------------------
		;A: Coarse domain

	;full  3hr  from 2112 to 2700
	;clat_a=(/17.11,16.88,16.47,16.83,20.59,17.69,17.37,16.67,17.07,16.59,16.35,17.08,18.44,18.12,\
	;		18.47,17.83,17.85,15.31,14.02,14.02,11.77,13.05,13.38,14.34,14.66,15.30,15.61,15.92,\
	;		16.23,16.54,16.84,17.14,17.44,17.75,18.05,18.34,18.63,18.59,18.85,18.83,18.79,18.74,18.36,18.66,18.63/)

	;clon_a=(/0.40,-0.32,0.31,-2.70,-4.33,-4.65,-8.79,-7.81,-8.79,-11.20,-12.57,-14.22,-15.86,-16.21,-16.88,\
	;		-17.24,-17.92,-21.00,-22.00,-22.00,-21.35,-21.01,-22.00,-22.33,-23.00,-24.01,-24.68,-25.36,-26.04,\
	;		-26.72,-27.41,-28.09,-28.78,-29.14,-29.83,-30.53,-31.23,-31.91,-32.95,-33.30,-33.98,-34.66,-35.31,-35.68,-36.02/)




	;other 3hr  from 2112 to 2700
	;clat_b=(/17.11,16.51,16.47,16.80,20.59,17.72,17.37,16.40,16.48,16.67,17.66,17.09,18.07,18.12,\
	;		18.46,18.16,17.86,15.31,13.70,14.02,13.37,13.70,14.02,14.34,14.66,14.65,14.96,15.60,\
	;		15.91,16.22,16.84,16.82,17.45,17.43,18.06,18.68,18.97,18.93,18.89,18.85,19.13,19.08,19.04,19.01,19.28/)

	;clon_b=(/0.40,-0.02,0.31,-2.37,-4.33,-4.99,-8.43,-8.51,-9.52,-12.55,-12.83,-14.55,-14.85,-16.21,-16.54,\
	;		-17.57,-18.26,-21.00,-22.00,-22.33,-20.68,-21.34,-22.00,-22.67,-23.67,-24.33,-25.01,-25.35,-26.03,\
	;		-26.71,-27.41,-28.08,-28.44,-29.12,-29.49,-30.20,-30.91,-31.59,-32.27,-32.95,-33.66,-34.34,-35.03,-35.37,-36.08/)


			;B. Nest domain
	;fullnodust, 3hr interval from 2400-2700
	clat_a=(/11.66,12.47,12.55,12.76,11.96,12.34,12.24,13.71,14.13,16.07,16.02,\
	16.62,16.27,16.45,17.01,17.56,17.85,18.24,19.39,19.22,19.74,19.96,20.43,20.77,20.43/)

	clon_a=(/-22.73,-23.86,-23.75,-24.16,-25.02,-25.43,-26.71,-27.78,-28.16,-27.94,\
	-28.39,-28.71,-29.30,-29.27,-29.63,-30.26,-30.92,-31.09,-31.73,-32.25,-33.71,-33.68,-34.14,-35.02,-36.18/)


	;fullnodust, 3hr interval from 2400-2700
	clat_b=(/11.66,12.47,12.55,12.76,11.96,12.34,12.24,13.71,14.13,16.07,16.02,\
	16.62,16.27,16.45,17.01,17.56,17.85,18.24,19.39,19.22,19.74,19.96,20.43,20.77,20.43/)

	clon_b=(/-22.73,-23.86,-23.75,-24.16,-25.02,-25.43,-26.71,-27.78,-28.16,-27.94,\
	-28.39,-28.71,-29.30,-29.27,-29.63,-30.26,-30.92,-31.09,-31.73,-32.25,-33.71,-33.68,-34.14,-35.02,-36.18/)



	;#################### 1hr interval  from 2400-2700   fullnodust center


	;clat_a=(/11.66,12.30,12.37,12.47,13.22,12.48,12.55,12.98,13.55,12.76,11.94,12.35,11.96,12.38,10.66,\
	;12.34,12.58,11.97,12.24,13.86,13.11,13.71,12.92,13.51,14.13,16.08,16.04,16.07,\
	;16.17,16.06,16.02,16.55,16.05,16.62,16.45,16.79,16.27,16.27,16.34,16.45,16.63,\
	;16.80,17.01,17.22,17.23,17.56,17.69,17.79,17.85,17.99,18.48,18.24,19.57,19.42,\
	;19.39,19.30,19.08,19.22,19.32,19.49,19.74,19.79,20.98,19.96,20.12,20.17,20.43,20.56,20.64,20.77,20.85,20.97,20.43/)


	;clon_a=(/-22.73,-23.17,-23.35,-23.86,-23.91,-23.64,-23.75,-23.21,-23.69,-24.16,-23.89,-24.85,\
	;-25.02,-25.43,-25.90,-25.43,-25.95,-27.00,-26.71,-27.64,-27.53,-27.78,-27.94,-28.36,\
	;-28.16,-27.64,-27.79,-27.94,-28.17,-28.28,-28.39,-28.45,-28.46,-28.71,-29.19,-28.83,\
	;-29.30,-29.30,-29.26,-29.27,-29.31,-29.43,-29.63,-29.83,-30.36,-30.26,-30.53,-30.76,\
	;-30.92,-31.08,-31.30,-31.09,-31.70,-31.92,-31.73,-31.34,-32.13,-32.25,-32.34,-32.50,\
	;-33.71,-32.87,-32.95,-33.68,-33.93,-34.35,-34.14,-34.85,-34.74,-35.02,-35.37,-35.65,-36.18/)

	;clat_b=(/11.66,12.30,12.37,12.47,13.22,12.48,12.55,12.98,13.55,12.76,11.94,12.35,11.96,12.38,10.66,\
	;12.34,12.58,11.97,12.24,13.86,13.11,13.71,12.92,13.51,14.13,16.08,16.04,16.07,\
	;16.17,16.06,16.02,16.55,16.05,16.62,16.45,16.79,16.27,16.27,16.34,16.45,16.63,\
	;16.80,17.01,17.22,17.23,17.56,17.69,17.79,17.85,17.99,18.48,18.24,19.57,19.42,\
	;19.39,19.30,19.08,19.22,19.32,19.49,19.74,19.79,20.98,19.96,20.12,20.17,20.43,20.56,20.64,20.77,20.85,20.97,20.43/)


	;clon_b=(/-22.73,-23.17,-23.35,-23.86,-23.91,-23.64,-23.75,-23.21,-23.69,-24.16,-23.89,-24.85,\
	;-25.02,-25.43,-25.90,-25.43,-25.95,-27.00,-26.71,-27.64,-27.53,-27.78,-27.94,-28.36,\
	;-28.16,-27.64,-27.79,-27.94,-28.17,-28.28,-28.39,-28.45,-28.46,-28.71,-29.19,-28.83,\
	;-29.30,-29.30,-29.26,-29.27,-29.31,-29.43,-29.63,-29.83,-30.36,-30.26,-30.53,-30.76,\
	;-30.92,-31.08,-31.30,-31.09,-31.70,-31.92,-31.73,-31.34,-32.13,-32.25,-32.34,-32.50,\
	;-33.71,-32.87,-32.95,-33.68,-33.93,-34.35,-34.14,-34.85,-34.74,-35.02,-35.37,-35.65,-36.18/)



average_time=True    
  
good_picture=True
if nest then
	good_picture=False		;???### very slow if use areafill in the nest domain
end if	

							
;===================
; variable list					
;==================    
	;----------------	
	;examples 101-104 , don't modify, for test
	;-----------------
if (set.eq.101)then							;(1)  only one  variable				
var_name=(/"th"/)									
exist_both_file=(/True/)
var_res=(/"cn"/)										; cn is contour, sh is shaded 
smooth=(/False/)										; in vertical plot, may try smooth is False
isoverlay=(/False/)										;  overlay for data_1, data_2
isoverlay_diff=(/False/)								;  overlay for diff.  Set to False if only plot one variables
in_restart_file=(/False/)								;  some variables are only available in restart files
end if

		
if (set.eq.102)then							;(2)  more than one variable, no overlay, can be many variables in the list			
var_name=(/"CCN_total","QCLOUD"/)									
exist_both_file=(/True,True/)
var_res=(/"cn","sh"/)				
smooth=(/False,False/)
isoverlay=(/False,False/)								;all False	
isoverlay_diff=(/False,False/)	
in_restart_file=(/True,False/)							;can from the restart			
end if

if (set.eq.103)then							;(3) more than one variable,  overlay   ;maximum of overlay variables is 3 	
var_name=(/"QVAPOR","QCLOUD"/)									
exist_both_file=(/True,True/)
var_res=(/"cn","sh"/)				
smooth=(/False,False/)
isoverlay=(/True,True/)			
isoverlay_diff=(/True,True/)							;True
in_restart_file=(/False,False/)					
end if


if (set.eq.104)then				;(4) more than one variable,  overlay mix with no overlay, with no overlay at the end, can be many 								
var_name=(/"QVAPOR","QCLOUD","QNDROP"/)									
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","sh"/)				
smooth=(/False,False,False/)
isoverlay=(/True,True,False/)		;overlay variable must place before the no overlay variable. (/False,True,True/) or (/True,False,True/) are wrong! 
isoverlay_diff=(/True,True,False/)		
in_restart_file=(/False,False,False/)						
end if


;------------------ end of example

;--------------
; test
;---------------

if (set.eq.105)then				;(4) more than one variable,  overlay mix with no overlay, with no overlay at the end, can be many 								
var_name=(/"tan_wind","rad_wind","QNDROP"/)									
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","sh"/)				
smooth=(/False,False,False/)
isoverlay=(/True,True,False/)		;overlay variable must place before the no overlay variable. (/False,True,True/) or (/True,False,True/) are wrong! 
isoverlay_diff=(/True,True,False/)		
in_restart_file=(/False,False,False/)						
end if


;----------------
; combine the variables
;-----------------------

if (set.eq.50)then									
var_name=(/"CCN_total","EXTCOF55","QNDROP"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","cn","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/True,True,True,True,False/)		;  overlay for diff
in_restart_file=(/True,False,False/)						;  some variables are only available in restart files
end if

if (set.eq.51)then									
var_name=(/"tc","QICE","QCLOUD"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","cn","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/True,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False,False/)						;  some variables are only available in restart files
end if


if (set.eq.52)then									
var_name=(/"tc","snow_graup","QRAIN"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","cn","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/True,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False,False/)						;  some variables are only available in restart files
end if


if (set.eq.53)then									
var_name=(/"th","QVAPOR"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","sh","sh","sh","sh","sh"/)				
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			
isoverlay_diff=(/True,True,True,True,False/)		
in_restart_file=(/False,False,False/)						
end if


if (set.eq.54)then
var_name=(/"EXTCOF55","H_DIABATIC"/) 
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if


if (set.eq.55)then
var_name=(/"EXTCOF55","total_tendency"/)  
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.56)then									
var_name=(/"H_DIABATIC","T_deviation"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/True,True,True,True,False/)		;  overlay for diff
in_restart_file=(/True,False,False/)						;  some variables are only available in restart files
end if

if (set.eq.57)then									
var_name=(/"wind_vector","rad_wind"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"vc","sh","sh","sh","sh"/)				
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			
isoverlay_diff=(/True,True,True,True,False/)		
in_restart_file=(/False,False/)						
end if


if (set.eq.58)then									
var_name=(/"tan_wind","wa"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","sh","sh","sh","sh","sh"/)			
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			
isoverlay_diff=(/True,True,True,True,False/)	
in_restart_file=(/False,False,False/)						
end if

if (set.eq.59)then									
var_name=(/"tan_wind","rad_wind"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/True,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False,False/)						;  some variables are only available in restart files
end if

if (set.eq.60)then									
var_name=(/"rad_wind","tan_wind"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/True,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False,False/)						;  some variables are only available in restart files
end if


if (set.eq.61)then
var_name=(/"EXTCOF55","RTHRATSW"/) 
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.62)then
var_name=(/"EXTCOF55","RTHRATLW"/) 
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if


if (set.eq.63)then
var_name=(/"EXTCOF55","RTHRATEN"/)  
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.64)then
var_name=(/"EXTCOF55","RTHBLTEN"/)  
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.65)then
var_name=(/"EXTCOF55","rh"/)  
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,False/)
end if


if (set.eq.66)then									
var_name=(/"tc"/)	
add_zero_temperatureline=False								
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

;---------------
;single variable
;----------------
if (set.eq.1)then									
var_name=(/"rad_wind"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.2)then									
var_name=(/"tan_wind"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if


if (set.eq.3)then									
var_name=(/"EXTCOF55"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.4)then									
var_name=(/"wa"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.5)then									
var_name=(/"dbz"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.6)then									
var_name=(/"QVAPOR"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.7)then									
var_name=(/"QCLOUD"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.8)then									
var_name=(/"QNDROP"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.9)then									
var_name=(/"QRAIN"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if


if (set.eq.10)then									
var_name=(/"QICE"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.11)then									
var_name=(/"QGRAUP"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if


if (set.eq.12)then									
var_name=(/"snow_graup"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","cn","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False,False/)						;  some variables are only available in restart files
end if

if (set.eq.13)then									
var_name=(/"th"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.14)then									
var_name=(/"tc"/)	
add_zero_temperatureline=False								
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.15)then									
var_name=(/"rh"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if



if (set.eq.16)then									
var_name=(/"H_DIABATIC"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/True,False/)						;  some variables are only available in restart files
end if


if (set.eq.17)then									
var_name=(/"total_dust"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.18)then									
var_name=(/"CCN1"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/True,False/)						;  some variables are only available in restart files
end if


if (set.eq.19)then									
var_name=(/"CCN_total"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","cn","sh","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/False,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/False,True,True,True,False/)		;  overlay for diff
in_restart_file=(/True,False,False/)						;  some variables are only available in restart files
end if



; open work station
tmpname1=str_sub_str(filename(start_time),":","_")
tmpname2=str_sub_str(filename(time_end),":","_")
var_numbers=dimsizes(var_name)	
if (var_numbers.eq.1) then
	wks_name="azimuth-"+var_name(0)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.eq.2) then
	wks_name="azimuth-"+var_name(0)+"-"+var_name(1)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.eq.3) then
	wks_name="azimuth-"+var_name(0)+"-"+var_name(1)+"-"+var_name(2)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.gt.3) then
	wks_name="azimuth-"+var_name(0)+"-"+var_name(1)+"-"+var_name(2)+"-other-"+tmpname1+"-"+tmpname2  
end if
wks=gsn_open_wks("pdf",wks_name) 

rmfile="rm "+wks_name+".txt"
system(rmfile)

; gsn_define_colormap(wks,"WhViBlGrYeOrReWh")        ;???#################
gsn_define_colormap(wks,"cmp_flux")
if (set.eq.7)then		
;	gsn_define_colormap(wks,"BlAqGrYeOrReVi200")	;???###### for AOD
end if

;=======================
; define the plot array						
;=======================	
plot_1=new((/50,10/),"graphic") 			;store the data_1 
plot_2=new((/50,10/),"graphic")			;store the data_2 
plot_diff=new((/50,10/),"graphic")		; store the diff
plot_1_avgtime=new((/50,10/),"graphic") 			
plot_2_avgtime=new((/50,10/),"graphic")			
plot_diff_avgtime=new((/50,10/),"graphic")		

contour_data_1=new((/10,10/),"graphic")
contour_data_2=new((/10,10/),"graphic")	
contour_diff=new((/10,10/),"graphic")	;contour for different variable,different cross section
contour_data_1_avgtime=new((/10,10/),"graphic")
contour_data_2_avgtime=new((/10,10/),"graphic")	
contour_diff_avgtime=new((/10,10/),"graphic")	

plot1_overlay1=new((/10/),"graphic")
plot1_overlay2=new((/10/),"graphic")
plot2_overlay1=new((/10/),"graphic")
plot2_overlay2=new((/10/),"graphic")
plot_diff_overlay1=new((/10/),"graphic")
plot_diff_overlay2=new((/10/),"graphic")
plot1_overlay1_avgtime=new((/10/),"graphic")
plot1_overlay2_avgtime=new((/10/),"graphic")
plot2_overlay1_avgtime=new((/10/),"graphic")
plot2_overlay2_avgtime=new((/10/),"graphic")
plot_diff_overlay1_avgtime=new((/10/),"graphic")
plot_diff_overlay2_avgtime=new((/10/),"graphic")

units=new((/50/),"string")		

;-=====================
; user-defined function
;===============
undef("substring")
function substring (instr[1]:string, first[1]:numeric, last[1]:numeric)

local instr, first, last, main, p2

begin
   main = stringtochar (instr)		; convert input string to char array
					; terminal null character is included   
   
   if (last .ge. first) then		; check requested end position
      p2 = last				; go to last position specified
   else					; but if less than first:
      p2 = dimsizes (main) - 2		; go to last avail char in main string
   end if
   
   return (chartostring (main(first:p2)))	; extract substring
end
;==========================================	
time_name=new((/ntimes/),"string")
do it=0,ntimes-1
	time_name(it)=substring(filename(it),11,29)
end do


num_angle=dimsizes(angle)
do i=0,num_angle-1
	if(angle(i).ne.999.)then
		angle(i)=angle(i)*3.1415/180.
	end if
end do
;----------------
; count the total number of overlay variables
;---------------
total_num_overlay=0
total_num_overlay_diff=0
var_numbers=dimsizes(var_name)

do id=0,var_numbers-1
	if(isoverlay(id))then
		total_num_overlay=total_num_overlay+1
	end if

	if(isoverlay_diff(id))then
		total_num_overlay_diff=total_num_overlay_diff+1
  	end if
end do

if(total_num_overlay.eq.1.or.total_num_overlay_diff.eq.1)then
	isoverlay(0)=False
	isoverlay_diff(0)=False
end if

; we to read the restart file if the variable is only exist in the restart file
restart_files=False
do id=0,var_numbers-1
	if(in_restart_file(id))then
		restart_files=True
	end if
end do

;---------------
; map for plotting the horizontal plot 
;----------------------

lat_s=new((/1000/),"float")
lat_n=new((/1000/),"float")
lon_w=new((/1000/),"float")
lon_e=new((/1000/),"float")


if nest then
	do i=0,499;nested domain	 
		lat_s(i)=5.0		;????######set the domain
		lat_n(i)=30.0
		lon_w(i)=-40.0
		lon_e(i)=-10.0	
	end do
else
	do i=0,499
		lat_s(i)=0.0		;????######set the domain
		lat_n(i)=35.0
		lon_w(i)=-65.0
		lon_e(i)=25.0
	end do
end if


FirstTime = True


;========================
;begin the time loop
;=======================	

																			
do it=start_time,time_end,1	
	print("begin  "+ filename(it))
	;filename_a=dir_a+filename(it)+"_prior"+".nc"		; this is for the diff in the da cycle
	;filename_b=dir_b+filename(it)+"_prior"+".nc"
	; filename_a=dir_a+filename(it)+"_post"+".nc"		
	; filename_b=dir_b+filename(it)+"_post"+".nc"
	filename_a=dir_a+filename(it)+".nc"				;???######## this is for the forecast stage
	filename_b=dir_b+filename(it)+".nc"
	print("read files")
	a = addfile(filename_a,"r")
	b = addfile(filename_b,"r")

	if restart_files then
		filename_t=str_sub_str(filename(it),"wrfout","wrfrst")
		filename_c=dir_a+filename_t+".nc"			
		filename_d=dir_b+filename_t+".nc"
		c=addfile(filename_c, "r") 
		d=addfile(filename_d, "r") 
		print(filename_c)
		print(filename_d)
	end if
	
	
	;res@TimeLabel = filename(it)   


	;---------
    ;get some useful variable 
    ;-----------   

	z1  = wrf_user_getvar(a, "z",0)        ; grid point height
	z2  = wrf_user_getvar(b, "z",0)        ; grid point height
	z=z1

	p1  = wrf_user_getvar(a, "pressure",0) 
	p2  = wrf_user_getvar(b, "pressure",0) 
	p=p1
	
	if have_slp_plot then
		slp_a = wrf_user_getvar(a, "slp",0)
		slp_b = wrf_user_getvar(b, "slp",0)
		slp_diff=slp_a-slp_b
	end if


	;------------
	;creat new array   ;only do it once
	;------------
	if(it.eq.start_time)	
		
		ua=wrf_user_getvar(a,"ua",0) ;for dimension information
		mdims = dimsizes(ua)
		nd = dimsizes(mdims)	;number of dimensions
	
		nlon=mdims(nd-1)	;length of the rigt-most dimension, number of grid points in the lon direction ;375
		nlat=mdims(nd-2)	;length of the second right-most dimension 	;162
		klev=mdims(nd-3)

		dx = a@DX 			;[m]	;36000m
		dy = a@DY 			;[m]
		print("grid resolusion is "+dx/1000+"  km")
		xlon=wrf_user_getvar(a,"XLONG",0) 
		xlat=wrf_user_getvar(a,"XLAT",0) 
	
		;lat and lon of pressure minimum
		lat_min_a=new(ntimes,float)
		lon_min_a=new(ntimes,float)
		lat_min_b=new(ntimes,float)
		lon_min_b=new(ntimes,float)

		; for polar coordinate
		print("original radius is "+rr0+"  km")
		dr=dx 						;interval in meters, according to the grid space				
		rr0=rr0*1000				;convert radius units from km to m
		nr0=floattointeger(rr0/dr)	
		nr0=nr0+1					;initial number of grid in x axis, for defining the vertical plan array purpose

		rr=rr0		
		nr=floattointeger(rr/dr)	;number of intervals in the radius direction
		nr=nr+1						;r begin from 0, so add one more dimension
		r=new(nr,float)  	
		do ir=0,nr-1
			r(ir)=ir*dr				;0,4,8,...  	
		end do 

		da=dx/rr   					;azimuth resolution, in radians		
		na=floattointeger(2*3.1415926/da)
		print("how many grids in a circle: "+na)

		; arry for rectilinear grid
		xmax=nlon*dx				;[m]		;375*36000
		ymax=nlat*dy 				;[m]		;162*36000
		xi=fspan(dx/2,xmax-dx/2,nlon)  ; x position, in [m]		 dx/2 means the center position of the grid   
		yi=fspan(dy/2,ymax-dy/2,nlat)


		

	end if

	;--------------------------
	; default resources for the plot
	;------------------------

			;---------------
			; for contour  
			;--------------- 
	opts_cn=True     
	opts_cn@cnLineColor = (/"black"/)
	opts_cn@cnLineThicknesses=(/8.0/)
	;opts_cn@ContourParameters = (/ 0.25 /)
	;opts_cn@gsnContourLineThicknessesScale = 2.0
	opts_cn@cnInfoLabelOn = False
	opts_cn@cnLineLabelsOn =True
	opts_cn@cnLineLabelPerimOn =True
	opts_cn@cnLineLabelPlacementMode   = "Constant"
	;opts_cn@cnLineLabelPerimThicknessF=0.15
	;opts_cn@cnMinLevelValF       = 0
	;opts_cn@cnMaxLevelValF       = 4
	;opts_cn@cnLevelSpacingF      =  0.25
	;opts_cn@cnLineDashPattern= 0
	;opts_cn@cnLineDashSegLenF          = 0.2          ; assist in controlling concentration
	;opts_cn@cnConstFLabelOrthogonalPosF= 0.1
	;opts_cn@cnLineLabelInterval        = 0.1   
	opts_cn@cnFillOn=False
	opts_cn@gsnContourPosLineDashPattern  =0
	opts_cn@gsnContourNegLineDashPattern  =4
	opts_cn@gsnContourZeroLineThicknessF =1.4

			;-----------------
			; for shading
			;------------------

	opts_sh=True
	opts_sh@cnLinesOn=False 			; turn off contour lines
	opts_sh@cnLineLabelsOn       =  False
	opts_sh@cnFillOn=True 
	if good_picture then
		opts_sh@cnFillMode="AreaFill"  
    else
		opts_sh@cnFillMode="RasterFill"   
    	opts_sh@cnRasterSmoothingOn=True
	end if  
	opts_sh@cnMissingValFillPattern = -1 
	opts_sh@cnMissingValFillColor=-1
	opts_sh@gsnSpreadColors =True   ; use the entire color spectrum
	opts_sh@gsnSpreadColorStart =  3 ; 2 is default
	opts_sh@gsnSpreadColorEnd = -3   ; -1 is default
	opts_sh@lbBottomMarginF= -0.1
	opts_sh@lbLabelBarOn        = True           ; turn on/off individual cb's
	opts_sh@lbTitleOn           = False			 ;title for the label
	;opts_sh@lbOrientation        = "Vertical"   ; vertical label bar

			;------------
			; for vector
			;---------------
	opts_vc=True
	;opts_vc@FieldTitle        = "wind vector"       ; Overwrite Field Title
	opts_vc@NumVectors        = 24           ; wind barb density
	;opts_vc@gsnAddCyclic            = False            ; regional data 
	opts_vc@vcRefMagnitudeF         = 10.0             ; define vector ref mag
	opts_vc@vcRefLengthF            = 0.028            ; define length of vec ref
	opts_vc@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
	;opts_vc@vcGlyphStyle   ="WindBarb"
	opts_vc@vcMinDistanceF          = 0.037		;control the density
	opts_vc@vcWindBarbLineThicknessF=1.1

	;===================================
	;plot  slp and the position 				
	;=================================
	if have_slp_plot then
		;pl@LatLonOverlay = True
		opts_slp = opts_sh
		opts_slp@gsnFrame= False
		opts_slp@gsnDraw = False
		opts_slp@gsnMaximize=False
		opts_slp@tiMainString=time_name(it)
		opts_slp@mpProjection ="CylindricalEquidistant"
		opts_slp@mpLimitMode="LatLon"
		opts_slp@mpGridAndLimbOn=True
		opts_slp@mpGridLineDashPattern =2
		opts_slp@mpGridAndLimbDrawOrder ="PostDraw"
		opts_slp@mpGridLineThicknessF=1.0
		opts_slp@mpGridSpacingF =10. 
		opts_slp@pmTickMarkDisplayMode = "Always"
		opts_slp@tmXTOn=False                               ;tick turn off at the top of the figure
		opts_slp@mpGridLineDashSegLenF=0.08

		maxlon=lon_e(it)
		minlon=lon_w(it)
		minlat=lat_s(it)
		maxlat=lat_n(it)

		if(maxlon.gt.max(xlon))then
				maxlon=max(xlon)
		end if
		if(minlon.lt.min(xlon))then
				minlon=min(xlon)
		end if
		if(minlat.lt.min(xlat))then
				minlat=min(xlat)
		end if
		if(maxlat.gt.max(xlat))then
				maxlat=max(xlat)
		end if

		opts_slp@mpMaxLonF=maxlon
		opts_slp@mpMinLonF=minlon
		opts_slp@mpMaxLatF=maxlat
		opts_slp@mpMinLatF=minlat

		opts_slp@cnFillOn = True
		opts_slp@lbTitleOn = False
		opts_slp@tiMainString=time_name(it)
		opts_slp@cnLevelSelectionMode =  "ManualLevels" 
		opts_slp@cnMinLevelValF       = 990.
		opts_slp@cnMaxLevelValF       = 1020.
		opts_slp@cnLevelSpacingF      = 2.5
		opts_slp_diff=opts_slp
		opts_slp_diff@cnMinLevelValF       = -1.1
		opts_slp_diff@cnMaxLevelValF       = 1.0
		opts_slp_diff@cnLevelSpacingF      = 0.1
		slp_a@lon2d=xlon
		slp_a@lat2d=xlat
		slp_b@lon2d=xlon
		slp_b@lat2d=xlat
		slp_diff@lon2d=xlon
		slp_diff@lat2d=xlat

		contour_slp_a  = gsn_csm_contour_map(wks,slp_a,opts_slp)
		contour_slp_b  = gsn_csm_contour_map(wks,slp_b,opts_slp)
		contour_slp_diff=gsn_csm_contour_map(wks,slp_diff,opts_slp_diff)
		plot_slp_1=contour_slp_a
		plot_slp_2=contour_slp_b
		plot_slp_diff=contour_slp_diff
	end if
	; end of plotting slp

	num_overlay=0					; the initial value is 0, it increase one when meet one overlay variable
	num_overlay_diff=0

	;=========================
	; get hurricane center
	;===========================
		; (1) file1
	lat_min_a(it) = clat_a(it)   	; insert the latitude index into the lat coordinate variable
	lon_min_a(it) = clon_a(it)		; insert the longitude index into the lon coordinate variable
	print("lat_min and lon_min in file1  "+lat_min_a(it) + " " + lon_min_a(it))

	nm_a=getind_latlon2d(xlat,xlon,lat_min_a(it),lon_min_a(it))
			; Pivot point
	idx_pivlon_a = nm_a(0,1)  ;second dimension indicate lat/lon, 1 is lon, 0 is lat. first dimension means how many pairs of lat,lon you specify
	idx_pivlat_a = nm_a(0,0)
	xpiv_a=(int2flt(idx_pivlon_a)-0.5)*dx   ;int2flt: Converts values of type integer to values of type float and preserves metadata. 
	ypiv_a=(int2flt(idx_pivlat_a)-0.5)*dy
	;print("xpiv_a, ypiv_a  "+xpiv_a+"  "+ypiv_a)

		;(2) file2
	lat_min_b(it) = clat_b(it) 
	lon_min_b(it) = clon_b(it)  
	print("lat_min and lon_min in file2  "+lat_min_b(it) + " " + lon_min_b(it))

	nm_b=getind_latlon2d(xlat,xlon,lat_min_b(it),lon_min_b(it))
			; Pivot point
	idx_pivlon_b = nm_b(0,1)
	idx_pivlat_b = nm_b(0,0)
	xpiv_b=(int2flt(idx_pivlon_b)-0.5)*dx   
	ypiv_b=(int2flt(idx_pivlat_b)-0.5)*dy


	;-----------------end of getting hurricane center
	
	;=================
	;check whether the hurricane radius is out of bound
	;==================

			
	rr=rr0
	boundary_south_a=ypiv_a-rr0
	boundary_north_a=ypiv_a+rr0
	boundary_west_a=xpiv_a-rr0
	boundary_east_a=xpiv_a+rr0

	boundary_south_b=ypiv_b-rr0
	boundary_north_b=ypiv_b+rr0
	boundary_west_b=xpiv_b-rr0
	boundary_east_b=xpiv_b+rr0

	if( (boundary_south_a.lt.0) .or. (boundary_north_a.gt.ymax) .or. (boundary_west_a.lt.0) .or. (boundary_east_a.gt.xmax) .or. \
		(boundary_south_b.lt.0) .or. (boundary_north_b.gt.ymax) .or. (boundary_west_b.lt.0) .or. (boundary_east_b.gt.xmax)	)then

		rr_tem=new((/8/),"float")

		if(	boundary_south_a.lt.0)then
			rr_tem(0)=ypiv_a
		end if

		if(boundary_north_a.gt.ymax)then
			rr_tem(1)=ymax-ypiv_a
		end if

		if(boundary_west_a.lt.0)then
			rr_tem(2)=xpiv_a
		end if

		if(boundary_east_a.gt.xmax)then
			rr_tem(3)=xmax-xpiv_a
		end if
		
		if(boundary_south_b.lt.0)then
			rr_tem(4)=ypiv_b
		end if

		if(boundary_north_b.gt.ymax)then
			rr_tem(5)=ymax-ypiv_b
		end if

		if(boundary_west_b.lt.0)then
			rr_tem(6)=xpiv_b
		end if

		if(boundary_east_b.gt.xmax)then
			rr_tem(7)=xmax-xpiv_b
		end if

		rr=min(rr_tem)	;change radius
		delete(rr_tem)
	end if

	if(rr.lt.rr0)then
		print("new radius is "+rr/1000+"  km")
	else
		print("remain original radius is "+rr0/1000+"  km")
	end if

	nr=floattointeger(rr/dr)	;number of intervals in the radius direction
	nr=nr+1

	da=dx/rr   ;azimuth resolution, in radians		
	na=floattointeger(2*3.1415926/da)
	print("how many  grids in a circle  "+na)
	
	;coordinate in polar grid
	azrad=new(na,float)
	xc_a=new( (/nr,na/),float)	; x position, in [m]
	yc_a=new( (/nr,na/),float)	; y position
	xc_b=new( (/nr,na/),float)
	yc_b=new( (/nr,na/),float)

	lonc_a=new( (/nr,na/),float) ;x position in [degree]
	latc_a=lonc_a				
	lonc_b=new( (/nr,na/),float)	
	latc_b=lonc_b
	
	;===================
	; vertical coordinate
	;==================

	if(it.eq.start_time)then
		rr_tmp=rr/1000/111  ; find a radius for average, in [degree]
		lon_tmp_e=clon_a(it)+rr_tmp
		lon_tmp_w=clon_a(it)-rr_tmp
		lat_tmp_n=clat_a(it)+rr_tmp
		lat_tmp_s=clat_a(it)-rr_tmp
		loc1 = wrf_user_ll_to_ij(a, lon_tmp_w, lat_tmp_n, True)
		loc2 = wrf_user_ll_to_ij(a, lon_tmp_e, lat_tmp_s, True)
		x_start = loc1(0) 
		x_end   = loc2(0) 
		y_start = loc2(1) 
		y_end   = loc1(1) 

		; height coordinate in WRF
		if(vertical_type.eq.1)then
			h_profile=dim_avg_n(z(:,y_start:y_end,x_start:x_end),(/1,2/))/1000.    ;height convert from m to km
		else	
			h_profile=dim_avg_n(p(:,y_start:y_end,x_start:x_end),(/1,2/))			 ;pressure , hPa
		end if

		;height coordinate I want to interpolate to
		z_max = max(h_profile)
		z_min = 0. 
		dz = 0.01 * z_max
		nlevels = tointeger( z_max/dz )
		height_coordinate = new( (/nlevels/), typeof(h_profile))
		height_coordinate(0) = z_min

		do i=1, nlevels-1
			height_coordinate(i) = height_coordinate(0)+i*dz
		end do

		data_1_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float) ; use the inital radius( the largest ) to define the x axis, prevent run out 
		data_2_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float)
		diff_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float)	
		data_1_uu_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float)	
		data_2_uu_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float)	
		data_1_ww_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float)	
		data_2_ww_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float)	
		diff_uu_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float)	
		diff_ww_plane=new( (/ntimes,var_numbers,num_angle,nlevels,2*nr0-1/),float)
	end if



	;======================
	; loop over variable				;???### add your variable here
	;=====================

	do  var_id=0,var_numbers-1,1
		
		print("working on variable   "+var_name(var_id))
		checkfile="echo working on time "+time_name(it)+" variable "+var_name(var_id)+" >>"+wks_name+".txt"
		system(checkfile)

		if(var_name(var_id) .ne. "wind_speed" .and.var_name(var_id) .ne. "rad_wind".and.var_name(var_id) .ne. "tan_wind"\
		 .and. var_name(var_id) .ne. "wind_vector" .and. var_name(var_id) .ne. "t_td" .and. var_name(var_id) .ne. "rvo" \
		.and. var_name(var_id) .ne. "total_dust"  .and. var_name(var_id) .ne. "total_tendency".and. \
				var_name(var_id).ne. "total_moist_tendency".and. var_name(var_id) .ne. "CCN_total".and. var_name(var_id) .ne. "T_deviation"\
				.and. var_name(var_id) .ne. "snow_graup")then 
												;???######## modify here after you add the variable calculation
			if .not. in_restart_file(var_id) then
		  		data_1 = wrf_user_getvar(a,var_name(var_id),0) 			

		  		if(exist_both_file(var_id) )then
					data_2 = wrf_user_getvar(b,var_name(var_id),0)
				else							
					data_2=data_1		;???##### if that variable is not present in data_2,then just copy data_1 to data_2
				end if
			else
		  		data_1 = wrf_user_getvar(c,var_name(var_id),0) 			

		  		if(exist_both_file(var_id) )then
					data_2 = wrf_user_getvar(d,var_name(var_id),0)
				else							
					data_2=data_1
				end if
			end if

		end if	
		;=======================
		; add variable calculation here
		;=======================

		;---------------------
		;T deviation
		;---------------
		if(var_name(var_id) .eq. "T_deviation" )then
			data_1=wrf_user_getvar(a,"tc",0) 
			data_2=wrf_user_getvar(b,"tc",0) 
		;	tmp1_profile=dim_avg_n(tmp1,(/1,2/))
		;	tmp2_profile=dim_avg_n(tmp2,(/1,2/))

		;	do k=0,klev-1
		;		tmp1(k,:,:)=tmp1(k,:,:)-tmp1_profile(k)
		;		tmp2(k,:,:)=tmp2(k,:,:)-tmp2_profile(k)
		;	end do
		;	data_1=tmp1
		;	data_2=tmp2
		;	
			data_1@units = "K"
		end if

		;----------------
		; total ccn
		;----------------
		if(var_name(var_id) .eq. "CCN_total" )then
			data_1=wrf_user_getvar(c,"CCN1",0)+wrf_user_getvar(c,"CCN2",0)+wrf_user_getvar(c,"CCN3",0)+\
							wrf_user_getvar(c,"CCN4",0)+wrf_user_getvar(c,"CCN5",0)+wrf_user_getvar(c,"CCN6",0)
			data_2=wrf_user_getvar(d,"CCN1",0)+wrf_user_getvar(d,"CCN2",0)+wrf_user_getvar(d,"CCN3",0)+\
							wrf_user_getvar(d,"CCN4",0)+wrf_user_getvar(d,"CCN5",0)+wrf_user_getvar(d,"CCN6",0)
			data_1@units = "/cm3"
		end if

		;-----------
		;wind speed
		;------------
		if(var_name(var_id) .eq. "wind_speed" )then
				tmp1=wrf_user_getvar(a,"ua",0) 
				tmp2=wrf_user_getvar(a,"va",0)
				data_1 = sqrt(tmp1^2+tmp2^2)
				tmp3=wrf_user_getvar(b,"ua",0)
				tmp4=wrf_user_getvar(b,"va",0) 
				data_2 = sqrt(tmp3^2+tmp4^2)
				data_1@units = "m/s"
		end if
		;------------------
		; relative vorticity
		;----------------

		if(var_name(var_id).eq."rvo")then

			avo_1 = wrf_user_getvar(a,"avo",0)*1e-5 	
			avo_2 = wrf_user_getvar(b,"avo",0)*1e-5	
			ff=wrf_user_getvar(a,"F",0) 

			dimmm=dimsizes(avo_1)
			klev=dimmm(0)
			nlat=dimmm(1)
			mlon=dimmm(2)

			if(it.eq.start_time)
				rvo_1=new((/klev,nlat,mlon/),"float")
				rvo_2=new((/klev,nlat,mlon/),"float")
			end if

			do lev=0,klev-1
				rvo_1(lev,:,:)=avo_1(lev,:,:)-ff(:,:)
				rvo_2(lev,:,:)=avo_2(lev,:,:)-ff(:,:)
			end do

			data_1=rvo_1*1e5
			data_2=rvo_2*1e5
			data_1@units="1e-5/s"

		end if

		if(var_name(var_id).eq."t_td")then
			tc_1 = wrf_user_getvar(a,"tc",0) 
			td_1 = wrf_user_getvar(a,"td",0) 
		    	data_1 = tc_1-td_1
			tc_2 = wrf_user_getvar(b,"tc",0) 
			td_2 = wrf_user_getvar(b,"td",0) 
		    	data_2 = tc_2-td_2
			data_1@units = "K"
		end if

		;------------------
		; total dust
		;----------------
		if(var_name(var_id).eq."total_dust")then
		    oina01_a = wrf_user_getvar(a,"oin_a01",0)
		    oina02_a = wrf_user_getvar(a,"oin_a02",0)
		    oina03_a = wrf_user_getvar(a,"oin_a03",0)
		    oina04_a = wrf_user_getvar(a,"oin_a04",0)
		    oina05_a = wrf_user_getvar(a,"oin_a05",0)
		    oina06_a = wrf_user_getvar(a,"oin_a06",0)
		    oina07_a = wrf_user_getvar(a,"oin_a07",0)
		    oina08_a = wrf_user_getvar(a,"oin_a08",0)
		    data_1=oina01_a+oina02_a+oina03_a+oina04_a+oina05_a+oina06_a+oina07_a+oina08_a
		    if exist_both_file(var_id) then
			    oina01_b = wrf_user_getvar(b,"oin_a01",0)
			    oina02_b = wrf_user_getvar(b,"oin_a02",0)
			    oina03_b = wrf_user_getvar(b,"oin_a03",0)
			    oina04_b = wrf_user_getvar(b,"oin_a04",0)
			    oina05_b = wrf_user_getvar(b,"oin_a05",0)
			    oina06_b = wrf_user_getvar(b,"oin_a06",0)
			    oina07_b = wrf_user_getvar(b,"oin_a07",0)
			    oina08_b = wrf_user_getvar(b,"oin_a08",0)

			    data_2=oina01_b+oina02_b+oina03_b+oina04_b+oina05_b+oina06_b+oina07_b+oina08_b
		    else 
			data_2=data_1
		    end if
			data_1@units="ug/kg-dryair"
		end if


		;----------
		;  THETA TENDENCY(UNCOUPLED)   
		;-------------------

		if(var_name(var_id).eq."RTHRATSW".or.var_name(var_id).eq."RTHRATLW".or.var_name(var_id).eq."RTHRATEN" \
					.or. var_name(var_id).eq."H_DIABATIC".or.var_name(var_id).eq."RTHCUTEN".or.var_name(var_id).eq."RTHBLTEN")then
			;data_1=data_1/((1000./(p1*100.))^0.286)	; convert from potential temperature to temperature	
			;data_2=data_2/((1000./(p2*100.))^0.286)		
			data_1=data_1*3600					;???### heating per hour	
			data_2=data_2*3600	
			data_1@units="K/hour"
		end if


		;-----------------------------
		; convert couple to uncouple
		;---------------------------
		;if(var_name(var_id).eq."RTHCUTEN".or.var_name(var_id).eq."RTHRATEN".or.var_name(var_id).eq."RTHBLTEN")then
		;	data_1=data_1/dry_p_3d_a		
		;	data_2=data_2/dry_p_3d_b		
		;	data_1=data_1*3600		;???###				
		;	data_2=data_2*3600
		;end if

		if(var_name(var_id).eq."total_tendency")then		
			RTHFTEN_c=wrf_user_getvar(c,"RTHFTEN",0)	; when take the horizontal average, they cancel each other except the boundary, for profile, we ignore now
			RTHFTEN_d=wrf_user_getvar(d,"RTHFTEN",0)
			if nest then								;???### in nest domain, I don't use cumulus scheme
				RTHCUTEN_c=0.0
				RTHCUTEN_d=0.0
			else
				RTHCUTEN_c=wrf_user_getvar(c,"RTHCUTEN",0)
				RTHCUTEN_d=wrf_user_getvar(d,"RTHCUTEN",0)
			end if
			
			RTHRATEN_c=wrf_user_getvar(c,"RTHRATEN",0)
			RTHRATEN_d=wrf_user_getvar(d,"RTHRATEN",0)
			RTHBLTEN_c=wrf_user_getvar(c,"RTHBLTEN",0)
			RTHBLTEN_d=wrf_user_getvar(d,"RTHBLTEN",0)
			H_DIABATIC_c=wrf_user_getvar(c,"H_DIABATIC",0)
			H_DIABATIC_d=wrf_user_getvar(d,"H_DIABATIC",0)
			;data_1_total_tendency=(RTHCUTEN_c+RTHRATEN_c+RTHBLTEN_c)/dry_p_3d_a+H_DIABATIC_c	;version before 3.9
			;data_2_total_tendency=(RTHCUTEN_d+RTHRATEN_d+RTHBLTEN_d)/dry_p_3d_b+H_DIABATIC_d	
			data_1_total_tendency=RTHCUTEN_c+RTHRATEN_c+RTHBLTEN_c+H_DIABATIC_c+RTHFTEN_c	
			data_2_total_tendency=RTHCUTEN_d+RTHRATEN_d+RTHBLTEN_d+H_DIABATIC_d+RTHFTEN_d
			data_1_total_tendency=data_1_total_tendency*3600						
			data_2_total_tendency=data_2_total_tendency*3600
			data_1=data_1_total_tendency
			data_2=data_2_total_tendency
			data_1@units="K/hour"
		end if	
		
		if(var_name(var_id).eq."total_moist_tendency")then		
			if nest then
				RTHCUTEN_c=0.0
				RTHCUTEN_d=0.0
			else
				RTHCUTEN_c=wrf_user_getvar(c,"RTHCUTEN",0)
				RTHCUTEN_d=wrf_user_getvar(d,"RTHCUTEN",0)
			end if

			H_DIABATIC_c=wrf_user_getvar(c,"H_DIABATIC",0)
			H_DIABATIC_d=wrf_user_getvar(d,"H_DIABATIC",0)

			data_1_total_moist_tendency=RTHCUTEN_c+H_DIABATIC_c	
			data_2_total_moist_tendency=RTHCUTEN_d+H_DIABATIC_d	
			data_1_total_moist_tendency=data_1_total_moist_tendency*3600						
			data_2_total_moist_tendency=data_2_total_moist_tendency*3600
			data_1=data_1_total_moist_tendency
			data_2=data_2_total_moist_tendency
			data_1@units="K/hour"
		end if

			;radius wind tangential wind
		if(var_name(var_id) .eq. "rad_wind".or.var_name(var_id) .eq. "tan_wind".or.var_name(var_id) .eq. "wind_vector")then		
		    data_1_uu=wrf_user_getvar(a,"ua",0) 
		    data_1_vv=wrf_user_getvar(a,"va",0) 				
		    data_1_ww=wrf_user_getvar(a,"wa",0)	;???##########
		    data_2_uu=wrf_user_getvar(b,"ua",0) 
		    data_2_vv=wrf_user_getvar(b,"va",0) 
			data_2_ww=wrf_user_getvar(b,"wa",0)
		end if



		if(var_name(var_id) .eq. "QCLOUD".or.var_name(var_id) .eq. "QRAIN".or.var_name(var_id) .eq. "QICE".or.\
			var_name(var_id) .eq. "QSNOW".or.var_name(var_id) .eq. "QGRAUP".or.var_name(var_id) .eq. "QVAPOR")then
			data_1=data_1*1000.
			data_2=data_2*1000.
			data_1@units="g/kg"
		end if

		if(var_name(var_id) .eq."snow_graup")then
			data_1=(wrf_user_getvar(a,"QSNOW",0)+wrf_user_getvar(a,"QGRAUP",0))*1000.
			data_2=(wrf_user_getvar(b,"QSNOW",0)+wrf_user_getvar(b,"QGRAUP",0))*1000.
			data_1@units="g/kg"
		end if

		if(var_name(var_id) .eq. "QNDROP")then
			data_1=data_1*1e-6
			data_2=data_2*1e-6
			data_1@units="1e+06/kg"
		end if
		

		;====================
		; end of add variable
		;==================
		;-------------
		; assign units
		;-------------
		if(var_name(var_id) .ne."wind_vector" .and.var_name(var_id) .ne."rad_wind" .and.var_name(var_id) .ne."tan_wind" )then
			units(var_id)=data_1@units
		end if

		if(var_name(var_id) .eq."rad_wind" .or.var_name(var_id) .eq."tan_wind")then
			units(var_id)="m/s "
		end if

		if(var_name(var_id) .eq."wind_vector" )then
			units(var_id)=" "
		end if

														
		;===============
		; count the number of the overlay variables up to current time
		;=================
		if(isoverlay(var_id))then
				num_overlay=num_overlay+1		;for data_1
		end if
		if(isoverlay_diff(var_id))then
				num_overlay_diff=num_overlay_diff+1		;for diff
		end if


		;---------------------------
		; set to different resource for variable
		;--------------------------
																					
		if(var_res(var_id) .eq. "sh" )then			
			opts=opts_sh
			opts@cnLevelSelectionMode =  "ManualLevels"
		end if
		if(var_res(var_id) .eq. "cn")then			
			opts=opts_cn
			opts@cnLevelSelectionMode =  "ManualLevels"
		end if
		if(var_res(var_id) .eq. "vc")then			
			opts=opts_vc
		end if


		;-----------------
		;common resources
		;-----------------

		opts@gsnFrame= False
		opts@gsnDraw = False
		opts@gsnMaximize=False
		opts@tiMainString=time_name(it)

		;===============
		; title information  ; If your data has a long_name and units attribute, they will be placed in 
		;the gsnLeftString and gsnRightString respectively. You can turn these automatic labels off by setting the
		; string resource to a null string " ".
		;===============	
		opts@UnitLabel =" " 
		if .not. isoverlay(var_id) then

			opts@FieldTitle=var_name(var_id)+"  ("+units(var_id)+")" 	

		end if

		if  isoverlay(var_id) then
			if (total_num_overlay.eq.2) then
				if(var_id.eq.1)then
					opts@FieldTitle=var_name(0)+" ("+units(0)+")"+"~C~"+var_name(1)+" ("+units(1)+")"
				else
					opts@FieldTitle=" "	
				end if
			end if

			if (total_num_overlay.eq.3) then
				if(var_id.eq.2)then
					opts@FieldTitle=var_name(0)+" ("+units(0)+")"+"~C~"+var_name(1)+" ("+units(1)+")"+"~C~"+var_name(2)+" ("+units(2)+")"
				else
					opts@FieldTitle=" "	
				end if
			end if
		end if

		

		;------------------
		; make polar coordinate
		;------------------------
			;new array
		data_1_rad_polar=new( (/klev,nr,na/),float)
		data_1_tan_polar=new( (/klev,nr,na/),float)
		data_2_rad_polar=new( (/klev,nr,na/),float)
		data_2_tan_polar=new( (/klev,nr,na/),float)
		data_1_polar_cross=new( (/klev,2*nr-1/),float)
		data_2_polar_cross=new( (/klev,2*nr-1/),float)
		data_1_uu_polar_cross=new( (/klev,2*nr-1/),float)
		data_1_ww_polar_cross=new( (/klev,2*nr-1/),float)
		data_2_uu_polar_cross=new( (/klev,2*nr-1/),float)
		data_2_ww_polar_cross=new( (/klev,2*nr-1/),float)
	
		do ir=0,nr-1			; LOOP FOR RIDIAL DIRECTIOJN
			do ia=0,na-1		;   LOOP FOR AZIMUTH DIRECTION

				azrad(ia)=ia*da	
				;file1
				xc_a(ir,ia)=xpiv_a + r(ir)*cos(azrad(ia))	
				yc_a(ir,ia)=ypiv_a + r(ir)*sin(azrad(ia))
				;idc_a=floattointeger(xc_a(ir,ia)/dx)
				;jdc_a=floattointeger(yc_a(ir,ia)/dy)
				;lonc_a(ir,ia)=xlon(jdc_a,idc_a)		;diagnostic
				;latc_a(ir,ia)=xlat(jdc_a,idc_a)
				;file2
				xc_b(ir,ia)=xpiv_b + r(ir)*cos(azrad(ia))
				yc_b(ir,ia)=ypiv_b + r(ir)*sin(azrad(ia))
				;idc_b=floattointeger(xc_b(ir,ia)/dx)
				;jdc_b=floattointeger(yc_b(ir,ia)/dy)
				;lonc_b(ir,ia)=xlon(jdc_b,idc_b)
				;latc_b(ir,ia)=xlat(jdc_b,idc_b)

			end do ;ia
		end do   
		; end of polar coordinate

		;----------------------
		; convert rectilinear grid to unstructured grid. 
		;------------------------
		xc_a_1D=ndtooned(xc_a)			; xc_a and yc_a are both 2D variables, need to convert to 1D to do the interpolation. 
		yc_a_1D=ndtooned(yc_a)			; from 2D array (nr,na) to 1D array nr*na
		xc_b_1D=ndtooned(xc_b)					
		yc_b_1D=ndtooned(yc_b)	
										
		if(var_name(var_id) .eq. "rad_wind".or.var_name(var_id) .eq. "tan_wind".or.var_name(var_id) .eq. "wind_vector")then

			data_1_uu_tmp=linint2_points(xi,yi,data_1_uu, False, xc_a_1D, yc_a_1D, 0)
			data_1_uu_polar=onedtond(ndtooned(data_1_uu_tmp),(/klev,nr,na/))  
			delete(data_1_uu_tmp)

			data_1_vv_tmp=linint2_points(xi,yi,data_1_vv, False, xc_a_1D, yc_a_1D, 0)
			data_1_vv_polar=onedtond(ndtooned(data_1_vv_tmp),(/klev,nr,na/))
			delete(data_1_vv_tmp)

			data_1_ww_tmp=linint2_points(xi,yi,data_1_ww, False, xc_a_1D, yc_a_1D, 0)
			data_1_ww_polar=onedtond(ndtooned(data_1_ww_tmp),(/klev,nr,na/)) 
			delete(data_1_ww_tmp)

			data_2_uu_tmp=linint2_points(xi,yi,data_2_uu, False, xc_a_1D, yc_a_1D, 0)
			data_2_uu_polar=onedtond(ndtooned(data_2_uu_tmp),(/klev,nr,na/))  
			delete(data_2_uu_tmp)

			data_2_vv_tmp=linint2_points(xi,yi,data_2_vv, False, xc_a_1D, yc_a_1D, 0)
			data_2_vv_polar=onedtond(ndtooned(data_2_vv_tmp),(/klev,nr,na/)) 
			delete(data_2_vv_tmp)

			data_2_ww_tmp=linint2_points(xi,yi,data_2_ww, False, xc_a_1D, yc_a_1D, 0)
			data_2_ww_polar=onedtond(ndtooned(data_2_ww_tmp),(/klev,nr,na/)) 
			delete(data_2_ww_tmp)

		else  		; not wind variable

			data_1_tmp=linint2_points(xi,yi,data_1, False, xc_a_1D, yc_a_1D, 0) ;data_1 is array (klev,nlat,nlon) to data_1_tmp(klev,nr*na)	 				
			data_1_polar=onedtond(ndtooned(data_1_tmp),(/klev,nr,na/))  ; ndtooned(data_1_tmp) is 1D array (klev*nr*na), data_1_polar is 3D (klev,nr,na)
			delete(data_1_tmp)

			data_2_tmp=linint2_points(xi,yi,data_2, False, xc_b_1D, yc_b_1D, 0) 				
			data_2_polar=onedtond(ndtooned(data_2_tmp),(/klev,nr,na/)) 
			delete(data_2_tmp)
	
		end if		;end of conversion of coordinate
		

		; For wind, transform to CYLINDLICAL COORDINATES
		if(var_name(var_id) .eq. "rad_wind".or.var_name(var_id) .eq. "tan_wind".or.var_name(var_id) .eq. "wind_vector")then
			do ia=0,na-1
				; RADIAL VELOCITY
				data_1_rad_polar(:,:,ia) = data_1_uu_polar(:,:,ia)*cos(azrad(ia)) + data_1_vv_polar(:,:,ia)*sin(azrad(ia))
				data_2_rad_polar(:,:,ia) = data_2_uu_polar(:,:,ia)*cos(azrad(ia)) + data_2_vv_polar(:,:,ia)*sin(azrad(ia))
				;TANGENTIAL VELOCITY
				data_1_tan_polar(:,:,ia) = -data_1_uu_polar(:,:,ia)*sin(azrad(ia)) + data_1_vv_polar(:,:,ia)*cos(azrad(ia))
				data_2_tan_polar(:,:,ia) = -data_2_uu_polar(:,:,ia)*sin(azrad(ia)) + data_2_vv_polar(:,:,ia)*cos(azrad(ia))
			end do 

			if(var_name(var_id) .eq. "rad_wind")then
				data_1_polar=data_1_rad_polar
				data_2_polar=data_2_rad_polar	
			end if
			
			if(var_name(var_id) .eq. "tan_wind")then
				data_1_polar=data_1_tan_polar
				data_2_polar=data_2_tan_polar	
			end if

		end if

		;====================================
		;loop over different cross sections
		;==================================

		do angle_id=0,num_angle-1
		
			if(angle_id.eq.0)then	;(1) AZIMUTH AVERAGE		
				print(" AZIMUTH AVERAGE ")
				if(	var_name(var_id) .ne. "wind_vector".and.var_name(var_id) .ne. "T_deviation")then
					data_1_polar_avg=dim_avg_n(data_1_polar, 2)
					data_2_polar_avg=dim_avg_n(data_2_polar, 2)
				end if

				if(var_name(var_id) .eq. "wind_vector")then
					data_1_uu_polar_avg=dim_avg_n(data_1_rad_polar, 2)
					data_2_uu_polar_avg=dim_avg_n(data_2_rad_polar, 2)
					data_1_ww_polar_avg=dim_avg_n(data_1_ww_polar, 2)
					data_2_ww_polar_avg=dim_avg_n(data_2_ww_polar, 2)			
				end if

				if(var_name(var_id) .eq. "T_deviation")then
					tmp1=dim_avg_n(data_1_polar, 2)
					tmp2=dim_avg_n(data_2_polar, 2)
					tmp1_profile=dim_avg_n(tmp1,1)
					tmp2_profile=dim_avg_n(tmp2,1)
					do k=0,klev-1
						tmp1(k,:)=tmp1(k,:)-tmp1_profile(k)
						tmp2(k,:)=tmp2(k,:)-tmp2_profile(k)
					end do
					data_1_polar_avg=tmp1
					data_2_polar_avg=tmp2
					data_1_polar_avg@units="K"
					data_2_polar_avg@units="K"
					delete(tmp1)
					delete(tmp2)
					delete(tmp1_profile)
					delete(tmp2_profile)
				end if


			else 					; (2)other cross sections 
				print("working on cross section, agnle is  "+angle(angle_id))

				if(var_name(var_id) .eq. "wind_vector")then
					do ir=0,nr-2
						angle_grid=tointeger((angle(angle_id)+3.1415)/da)
						data_1_uu_polar_cross(:,ir)=-data_1_rad_polar(:,nr-1-ir,angle_grid)	;opposite
						data_1_ww_polar_cross(:,ir)=data_1_ww_polar(:,nr-1-ir,angle_grid)
						data_2_uu_polar_cross(:,ir)=-data_2_rad_polar(:,nr-1-ir,angle_grid)
						data_2_ww_polar_cross(:,ir)=data_2_ww_polar(:,nr-1-ir,angle_grid)
					end do
				
					do ir=nr-1,2*(nr-1)
						angle_grid=tointeger(angle(angle_id)/da)
						data_1_uu_polar_cross(:,ir)=data_1_rad_polar(:,ir-(nr-1),angle_grid)
						data_1_ww_polar_cross(:,ir)=data_1_ww_polar(:,ir-(nr-1),angle_grid)
						data_2_uu_polar_cross(:,ir)=data_2_rad_polar(:,ir-(nr-1),angle_grid)
						data_2_ww_polar_cross(:,ir)=data_2_ww_polar(:,ir-(nr-1),angle_grid)
					end do

				else

					do ir=0,nr-2
						angle_grid=tointeger((angle(angle_id)+3.1415)/da)
						data_1_polar_cross(:,ir)=data_1_polar(:,nr-1-ir,angle_grid)
						data_2_polar_cross(:,ir)=data_2_polar(:,nr-1-ir,angle_grid)
						if(var_name(var_id) .eq. "tan_wind".or.var_name(var_id) .eq. "rad_wind") ;opposite
							data_1_polar_cross(:,ir)=-data_1_polar_cross(:,ir)
							data_2_polar_cross(:,ir)=-data_2_polar_cross(:,ir)
						end if
					end do
				
					do ir=nr-1,2*(nr-1)
						angle_grid=tointeger(angle(angle_id)/da)
						data_1_polar_cross(:,ir)=data_1_polar(:,ir-(nr-1),angle_grid)
						data_2_polar_cross(:,ir)=data_2_polar(:,ir-(nr-1),angle_grid)
					end do
				end if

			end if  ;end of making different cross section


			;-------------------
			; interpolate to height coordinate
			;---------------------
			if(angle_id.eq.0)then			;azimuth average

				do ir=0,nr-1
					if(var_name(var_id) .eq. "wind_vector")then
						data_1_uu_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_1_uu_polar_avg(:,ir), h_profile, height_coordinate)
						data_1_ww_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_1_ww_polar_avg(:,ir), h_profile, height_coordinate)
						data_2_uu_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_2_uu_polar_avg(:,ir), h_profile, height_coordinate)
						data_2_ww_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_2_ww_polar_avg(:,ir), h_profile, height_coordinate)
					else
						data_1_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_1_polar_avg(:,ir), h_profile, height_coordinate)
						data_2_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_2_polar_avg(:,ir), h_profile, height_coordinate)
					end if
				end do

			else   							;other cross section

				do ir=0,2*(nr-1)
					if(var_name(var_id) .eq. "wind_vector")then
						data_1_uu_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_1_uu_polar_cross(:,ir), h_profile, height_coordinate)
						data_1_ww_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_1_ww_polar_cross(:,ir), h_profile, height_coordinate)
						data_2_uu_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_2_uu_polar_cross(:,ir), h_profile, height_coordinate)
						data_2_ww_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_2_ww_polar_cross(:,ir), h_profile, height_coordinate)
					else
						data_1_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_1_polar_cross(:,ir), h_profile, height_coordinate)
						data_2_plane(it,var_id,angle_id,:,ir) = wrf_interp_1d( data_2_polar_cross(:,ir), h_profile, height_coordinate)
					end if

				end do

			end if

			;-------------------
			; get the difference
			;--------------------
			if have_diff then
				if(var_name(var_id) .ne. "wind_vector"  )then
					if exist_both_file(var_id) then
						diff_plane(it,var_id,angle_id,:,:)=data_1_plane(it,var_id,angle_id,:,:)-data_2_plane(it,var_id,angle_id,:,:)

						if(add_zero_temperatureline.and.var_name(var_id).eq."tc")then  ;add zero temperature line to the difference plot
							diff_plane(it,var_id,angle_id,:,:)=data_2_plane(it,var_id,angle_id,:,:)		;???### use the 0 temperature line  in the second file
						end if
						
					else
						diff_plane(it,var_id,angle_id,:,:)=data_1_plane(it,var_id,angle_id,:,:)
					end if
				else
					if exist_both_file(var_id) then
						diff_uu_plane(it,var_id,angle_id,:,:)=data_1_uu_plane(it,var_id,angle_id,:,:)-data_2_uu_plane(it,var_id,angle_id,:,:)
						diff_ww_plane(it,var_id,angle_id,:,:)=data_1_ww_plane(it,var_id,angle_id,:,:)-data_2_ww_plane(it,var_id,angle_id,:,:)
					else
						diff_uu_plane(it,var_id,angle_id,:,:)=data_1_uu_plane(it,var_id,angle_id,:,:)
						diff_ww_plane(it,var_id,angle_id,:,:)=data_1_ww_plane(it,var_id,angle_id,:,:)
					end if
				end if
			end if

			;===========================
			;get the average at the final time
			;==================
			if average_time then
				if(it.eq.time_end)then
					data_1_plane_avgtime=dim_avg_n(data_1_plane,0)
					data_2_plane_avgtime=dim_avg_n(data_2_plane,0)
					if have_diff then
						diff_plane_avgtime=dim_avg_n(diff_plane,0)
					end if

					data_1_uu_plane_avgtime=dim_avg_n(data_1_uu_plane,0)
					data_1_ww_plane_avgtime=dim_avg_n(data_1_ww_plane,0)
					data_2_uu_plane_avgtime=dim_avg_n(data_2_uu_plane,0)
					data_2_ww_plane_avgtime=dim_avg_n(data_2_ww_plane,0)

					if have_diff then
						diff_uu_plane_avgtime=dim_avg_n(diff_uu_plane,0)
						diff_ww_plane_avgtime=dim_avg_n(diff_ww_plane,0)
					end if
				end if
			end if

					
	
			;================================
			; Options for XY Plots												
			;================================   

			;  opts@PlotOrientation         = data_1_plane_a@Orientation

			opts@InitTime= False 
			opts@ValidTime = False 
			opts@NoHeaderFooter= True 
			opts@Footer= False 
			opts@cnMissingValPerimOn     = True
			opts@cnMissingValFillColor   = -1
			opts@cnMissingValFillPattern = -1	 		

			; y axis
			if (vertical_type .eq.1)then   
				opts@tiYAxisString           = "Height (km)"
			else
				opts@tiYAxisString           = "Pressure (mb)"		
			end if

	 		zmin = 0.
			zmax=zmax0					
			nz   = floattoint(zmax + 1)	
			zspan=closest_val(zmax,height_coordinate)	;find the top index

			opts@tiYAxisFontHeightF      = 0.020  		;Sets the font height in NDC coordinates to use for the Y-Axis title. 
			opts@tmYROn                  = False		;Setting True turns on the right tick marks
			opts@tmYLMajorLengthF        = 0.02			;Sets the length of the Y-Axis left major tick marks in NDC coordinates.
			opts@tmYLLabelFontHeightF    = 0.015		;Sets the height of the Y-Axis left labels in NDC coordinates.
			opts@tmYLMode                = "Explicit"   ;need to set @tmYLValues   and @tmYLLabels
			opts@tmYLValues              = fspan(0,zspan,nz)    ; Create tick marks, this is the position indice for tickmark. 
																;the same range for variable. tc(0:zspan), 
			opts@tmYLLabels              = sprintf("%.1f",fspan(zmin,zmax,nz))  ; Create labels
			opts@tmYLLabelStride		=1
			;opts@tmYLStyle="Linear"
			;opts@tmYLMode                = "Manual"   
			;opts@tmYLDataTopF              = model_vertical_index      
			;opts@tmYLDataBottomF              = 0.0


			;X axis
	
			X_desc = "Radius (km)"
			opts@tiXAxisString           = X_desc    ; string is longtitude or latitude
			opts@tiXAxisFontHeightF      = 0.020
			opts@tmXTOn                  = False		;Setting True turns on top tick marks
			opts@tmXBMajorLengthF        = 0.02			;Sets the length of the X-Axis bottom major tick marks in NDC coordinates. 
			opts@tmXBLabelFontHeightF    = 0.015		;Sets the font height in NDC coordinates for the bottom X Axis labels. 
			opts@tmXBMode                = "Explicit"	;need to set tmXBValues and tmXBLabels after that

			if(angle_id.eq.0)then

				xxmin  = 0.
				xxmax  = (nr-1)*dr/1000.
				xleft=0
				xright = nr-1					;last index
				if(dx.ge.36000)then				;???###
					nx=nr
				else
					nx=(nr-1)/9+1
				end if
				opts@tmXBLabelStride		=1

			else

				xxmin  =  -(nr-1)*dr/1000.
				xxmax  =  (nr-1)*dr/1000.

				xleft=0
				xright = 2*(nr-1)					;last index

				if(dx.ge.36000)then				;???###
					nx=nr
				else
					nx=(nr-1)/9+1
				end if
				opts@tmXBLabelStride		=1
			end if

			delete(opts@tmXBValues)
			delete(opts@tmXBLabels )
			opts@tmXBValues              = fspan(xleft,xright,nx)                    ; Create tick marks
			opts@tmXBLabels              = sprintf("%.0f",fspan(xxmin,xxmax,nx))  ; Create labels

			;==============
			;set different range for different variables   		;????########## the range here is fine tuned towards hurricane earl 2010
			;==============

			if(var_name(var_id) .eq. "DUST_1" .or.var_name(var_id) .eq. "DUST_2"  .or.var_name(var_id) .eq. "DUST_3"\	
			 .or.var_name(var_id) .eq. "DUST_4" .or.var_name(var_id) .eq. "DUST_5")then
			   
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 20.
				opts@cnLevelSpacingF      = 0.5
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -10.0
				opts_diff@cnMaxLevelValF       = 10.0
				opts_diff@cnLevelSpacingF      = 0.5
			end if   

			if(var_name(var_id) .eq. "oin_a01" .or. var_name(var_id) .eq. "oin_a02")then

				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 50.
				opts@cnLevelSpacingF      = 5.0
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -50.
				opts_diff@cnMaxLevelValF       =50.
				opts_diff@cnLevelSpacingF      = 5.
			end if 

			if(var_name(var_id) .eq. "oin_a05" .or. var_name(var_id) .eq. "oin_a04")then

				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 100.
				opts@cnLevelSpacingF      = 10.0
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -50.
				opts_diff@cnMaxLevelValF       =50.
				opts_diff@cnLevelSpacingF      = 5.
			end if 

			if(var_name(var_id) .eq. "total_dust")then
			   
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 60.
				opts@cnLevelSpacingF      = 5.
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -60.0
				opts_diff@cnMaxLevelValF       = 60.0
				opts_diff@cnLevelSpacingF      = 10.
			end if  

			if(var_name(var_id) .eq. "rvo")then
				opts@cnMinLevelValF       = -40.
				opts@cnMaxLevelValF       = 40.
				opts@cnLevelSpacingF      = 5.
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -40.
				opts_diff@cnMaxLevelValF       = 40.
				opts_diff@cnLevelSpacingF      = 5.
			end if 

			if(var_name(var_id) .eq. "pvo")then
				opts@cnMinLevelValF       = -1.6
				opts@cnMaxLevelValF       = 1.6
				opts@cnLevelSpacingF      = 0.2
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -1.0
				opts_diff@cnMaxLevelValF       = 1.0
				opts_diff@cnLevelSpacingF      = 0.2
			end if 

		

			if(var_name(var_id) .eq. "geopt"  )then
				opts@cnLineColor=(/18/)
				opts_diff=opts  
				opts_diff@gsnContourPosLineDashPattern  =0.
				opts_diff@gsnContourNegLineDashPattern  =4.
				opts_diff@gsnContourZeroLineThicknessF =1.4 
				opts_diff@cnMinLevelValF       = -100.0 
				opts_diff@cnMaxLevelValF       = 100.0
				opts_diff@cnLevelSpacingF      = 50.
			end if


			if(var_name(var_id) .eq. "t_td"  )then
				opts@cnLineColor = (/8/)
				opts@cnMinLevelValF       = 0.0
				opts@cnMaxLevelValF       = 20.0
				opts@cnLevelSpacingF      = 2.0
				opts_diff=opts	
				opts_diff@gsnContourPosLineDashPattern  =0.
				opts_diff@gsnContourNegLineDashPattern  =4.
				opts_diff@gsnContourZeroLineThicknessF =1.4
				opts_diff@cnMinLevelValF       = -20.0
				opts_diff@cnMaxLevelValF       = 20.0
				opts_diff@cnLevelSpacingF      = 4.0
			end if


			if (var_name(var_id).eq."H_DIABATIC".or.var_name(var_id).eq."RTHCUTEN".or.var_name(var_id).eq."RTHRATEN".or.var_name(var_id).eq."RTHBLTEN".or.var_name(var_id).eq."total_tendency".or.var_name(var_id).eq."RTHRATSW".or.var_name(var_id).eq."RTHRATLW") then
				opts@cnMinLevelValF       = -2.4;  -14.;-1.2 
				opts@cnMaxLevelValF       = 2.4; 14.;1.0
				opts@cnLevelSpacingF      = 0.3; 2.;0.1
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -1.6; -10.;-0.08
				opts_diff@cnMaxLevelValF       = 1.6; 10.;0.08 
				opts_diff@cnLevelSpacingF      = 0.2; 2.;0.01 
				if(var_res(var_id).eq."cn")then
					opts@cnMinLevelValF       = -5.;-1.2 
					opts@cnMaxLevelValF       = 14.;1.0
					opts@cnLevelSpacingF      = 0.1;0.1
					opts@cnLineLabelInterval =2
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -10.;-0.08
					opts_diff@cnMaxLevelValF       = 10.;0.08 
					opts_diff@cnLevelSpacingF      = 0.1;0.01 
				end if
			end if

			if (var_name(var_id).eq."RTHFTEN") then		
				opts@cnMinLevelValF       = -1.2 
				opts@cnMaxLevelValF       = 1.0
				opts@cnLevelSpacingF      = 0.1
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.08
				opts_diff@cnMaxLevelValF       = 0.08 
				opts_diff@cnLevelSpacingF      = 0.01 
		end if

			if(var_name(var_id) .eq. "rh")then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 100.
				opts@cnLevelSpacingF      = 5.
				opts@cnLineColor = (/8/)
				opts_diff=opts
				opts_diff@cnLineColor = (/18/)	
				opts_diff@cnMinLevelValF       = -8.0; -40.0
				opts_diff@cnMaxLevelValF       = 8.0; 40.0
				opts_diff@cnLevelSpacingF      = 1.0; 8.
			end if 

			if(var_name(var_id) .eq. "eth" .or. var_name(var_id) .eq. "th" )then
				opts@cnMinLevelValF       = 280.0;300.  ;320.
				opts@cnMaxLevelValF       = 364.0;400.  ;350.
				opts@cnLevelSpacingF      = 4.0;2.0
				opts_diff=opts	
				opts_diff@cnMinLevelValF       = -4.0
				opts_diff@cnMaxLevelValF       = 4.0
				opts_diff@cnLevelSpacingF      = 0.5
				if(var_res(var_id).eq."cn")then
					opts@cnMinLevelValF       = 280.0;300.  ;320.
					opts@cnMaxLevelValF       = 364.0;400.  ;350.
					opts@cnLevelSpacingF      = 4.0
					opts@cnLineLabelInterval =1
					opts_diff=opts	
					; opts_diff@cnLineColor = (/18/)
					opts_diff@cnMinLevelValF       = -4.0
					opts_diff@cnMaxLevelValF       = 4.0
					opts_diff@cnLevelSpacingF      = 0.1
				end if
			
			end if


			if(var_name(var_id) .eq. "EXTCOF55"  )then
				;opts@cnMinLevelValF       = 0.0
				;opts@cnMaxLevelValF       = 0.25
				;opts@cnLevelSpacingF      = 0.05
				opts@cnMinLevelValF       = 0.0
				opts@cnMaxLevelValF       =0.5
				opts@cnLevelSpacingF      = 0.05
				opts_diff=opts	
				opts_diff@cnMinLevelValF       = -0.5
				opts_diff@cnMaxLevelValF       = 0.5
				opts_diff@cnLevelSpacingF      = 0.05
				if(var_res(var_id).eq."cn")then
					opts@cnMinLevelValF       = 0.0
					opts@cnMaxLevelValF       = 1.0
					opts@cnLevelSpacingF      = 0.02
					opts@cnLineLabelInterval =1
					opts_diff=opts	
					opts_diff@cnMinLevelValF       = -1.0
					opts_diff@cnMaxLevelValF       = 1.0
					opts_diff@cnLevelSpacingF      = 0.02
				end if
			end if

			if(var_name(var_id) .eq. "CCN1")then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 20
				opts@cnLevelSpacingF      = 1.
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -10
				opts_diff@cnMaxLevelValF       = 10
				opts_diff@cnLevelSpacingF      = 2
			end if 

			if(var_name(var_id) .eq. "CCN_total")then
				;opts@cnLevelSelectionMode="AutomaticLevels"
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 5000
				opts@cnLevelSpacingF      = 400
				opts@cnLineColor=(/18/)
				opts@cnLineThicknessF=1.0
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -100
				opts_diff@cnMaxLevelValF       = 4000
				opts_diff@cnLevelSpacingF      = 250
			end if 

			if(var_name(var_id) .eq. "tc"  )then
				if(.not.add_zero_temperatureline) then
					opts@cnLineColor=(/18/)
					opts@cnMinLevelValF       = -20. 
					opts@cnMaxLevelValF       = 40.
					opts@cnLevelSpacingF      =5.  
					opts_diff=opts  
					opts_diff@gsnContourPosLineDashPattern  =0
					opts_diff@gsnContourNegLineDashPattern  =4
					opts_diff@gsnContourZeroLineThicknessF =2.0
					opts_diff@cnMinLevelValF       = -0.8; -3.2 
					opts_diff@cnMaxLevelValF       = 0.8; 3.0
					opts_diff@cnLevelSpacingF      = 0.1
				else
					opts@cnLineColor=(/18/)
					opts@cnLevelSelectionMode = "ExplicitLevels"   ; set explicit contour levels
					opts@cnLevels    = (/ 0./) 
					opts_diff=opts  
				end if
			end if

			if(var_name(var_id) .eq. "T_deviation")then
				opts@cnMinLevelValF       = -1.6; -4.
				opts@cnMaxLevelValF       = 1.6; 4.0
				opts@cnLevelSpacingF      = 0.2; 0.5
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.64; -1.5
				opts_diff@cnMaxLevelValF       = 0.64; 1.5
				opts_diff@cnLevelSpacingF      = 0.08; 0.3
			end if 

			if(var_name(var_id) .eq. "RAINNC")then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 300.
				opts@cnLevelSpacingF      = 50 
				opts@cnLineLabelInterval =1
				opts@cnLineColor = (/"purple"/)
				opts@cnLineThicknesses=(/10.0/)
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -200.
				opts_diff@cnMaxLevelValF       = 200.
				opts_diff@cnLevelSpacingF      = 40.
			end if 


			if(var_name(var_id) .eq. "QVAPOR" )then
				factor=1e-4
				opts@cnMinLevelValF       = 0. ;0.02 
				opts@cnMaxLevelValF       = 16.0; 25.;0.
				opts@cnLevelSpacingF      = 1.0; 1.5; 0.002
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.8; -3.0 ;-0.006 
				opts_diff@cnMaxLevelValF       = 0.8; 3.0 ;0.006
				opts_diff@cnLevelSpacingF      = 0.1; 0.5 ; 0.001 
			end if 


			if(var_name(var_id) .eq. "QCLOUD")then
				opts@cnMinLevelValF       = 0.;0.0015
				opts@cnMaxLevelValF       = 0.04; 0.15;0.
				opts@cnLevelSpacingF      = 0.004; 0.015;0.0001

				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.032; -0.18;-5.5e-4
				opts_diff@cnMaxLevelValF       = 0.032; 0.18;5.e-4
				opts_diff@cnLevelSpacingF      = 0.004; 0.03; 5e-5
				end if 

			if( var_name(var_id) .eq. "QRAIN" )then
				opts@cnMinLevelValF       =  0.
				opts@cnMaxLevelValF       = 0.16; 1.5
				opts@cnLevelSpacingF      = 0.01; 0.1
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.16; -0.9
				opts_diff@cnMaxLevelValF       = 0.16; 0.9
				opts_diff@cnLevelSpacingF      =  0.02; 0.15
			end if

			if( var_name(var_id) .eq. "QICE" )then
				opts@cnMinLevelValF       =  0.
				opts@cnMaxLevelValF       = 0.03
				opts@cnLevelSpacingF      = 0.003
				opts@cnLineLabelInterval =1
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.015
				opts_diff@cnMaxLevelValF       = 0.015
				opts_diff@cnLevelSpacingF      =  0.003
			end if

			if( var_name(var_id) .eq. "QSNOW" .or.var_name(var_id) .eq. "snow_graup" )then
				opts@cnMinLevelValF       =  0.
				opts@cnMaxLevelValF       = 0.12;0.1
				opts@cnLevelSpacingF      = 0.01;0.01
				opts@cnLineLabelInterval =1
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.12; -0.1
				opts_diff@cnMaxLevelValF       = 0.12;0.1
				opts_diff@cnLevelSpacingF      =  0.015; 0.03;0.01
			end if

			if( var_name(var_id) .eq. "QGRAUP" )then
				opts@cnMinLevelValF       =  0.
				opts@cnMaxLevelValF       = 0.1
				opts@cnLevelSpacingF      = 0.01
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.1
				opts_diff@cnMaxLevelValF       = 0.1
				opts_diff@cnLevelSpacingF      =  0.02
			end if

			if(var_name(var_id).eq."QNDROP")then
				opts@cnMinLevelValF       = 0.;5e7
				opts@cnMaxLevelValF       = 8.0; 50; 20;55.;0.
				opts@cnLevelSpacingF      = 0.8; 2; 2;5.;5e6
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -8.0; -50; -18;-50;-5.5e7
				opts_diff@cnMaxLevelValF       = 8.0; 50; 18;50;5e7
				opts_diff@cnLevelSpacingF      = 1.0; 10;3;10 ;5e6
			end if

	  		if(var_name(var_id) .eq. "dbz" )then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 40.
				opts@cnLevelSpacingF      = 2.0
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -40.0
				opts_diff@cnMaxLevelValF       = 40.0
				opts_diff@cnLevelSpacingF      = 8.   
			end if 

			if(var_name(var_id) .eq. "wind_vector" )then
				opts_diff=opts	
			end if


			if( var_name(var_id) .eq. "wind_speed")then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 60.
				opts@cnLevelSpacingF      = 5.
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -8.0
				opts_diff@cnMaxLevelValF       = 8.0
				opts_diff@cnLevelSpacingF      = 2.0   
			end if 


			if(var_name(var_id) .eq. "rad_wind" )then
				opts@cnMinLevelValF       = -4.0; -8.0	; -10.0
				opts@cnMaxLevelValF       = 4.0; 8.0		; 10.0
				opts@cnLevelSpacingF      = 0.5; 1.0  ;   2.5
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.8; -4.0;-8.0
				opts_diff@cnMaxLevelValF       = 0.8; 4.0; 8.0
				opts_diff@cnLevelSpacingF      = 0.1; 0.8; 1.0
				if(var_res(var_id).eq."cn")then
					opts@cnMinLevelValF       = -10.0
					opts@cnMaxLevelValF       = 10.0
					opts@cnLevelSpacingF      = 0.25
					opts@cnLineLabelInterval =1
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -8.0
					opts_diff@cnMaxLevelValF       = 8.0
					opts_diff@cnLevelSpacingF      = 0.1
				end if
			end if

			if(var_name(var_id) .eq. "tan_wind")then
				opts@cnMinLevelValF       = -5.0
				opts@cnMaxLevelValF       = 15.0
				opts@cnLevelSpacingF      = 1.0
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -2.0; -7.0
				opts_diff@cnMaxLevelValF       = 2.0; 7.0
				opts_diff@cnLevelSpacingF      = 0.25; 1.0
				if(var_res(var_id).eq."cn")then
					opts@cnMinLevelValF       = -5.0
					opts@cnMaxLevelValF       = 30.0
					opts@cnLevelSpacingF      = 1.0
					opts@cnLineLabelInterval =2
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -8.0
					opts_diff@cnMaxLevelValF       = 8.0
					opts_diff@cnLevelSpacingF      = 0.25
				end if
			end if

			if(var_name(var_id) .eq. "wa" )then
				if(var_res(var_id).eq."cn")then
					opts@cnMinLevelValF       = -0.8 ;-1.5
					opts@cnMaxLevelValF       = 0.8 ; 1.5
					opts@cnLevelSpacingF      = 0.04	;0.05
					opts@cnLineLabelInterval =1
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -0.8;-0.2;-1.0 
					opts_diff@cnMaxLevelValF       = 0.8;0.2;1.0
					opts_diff@cnLevelSpacingF      = 0.02;0.05
				else
					opts@cnMinLevelValF       = -0.2; -0.8  ;-1.5
					opts@cnMaxLevelValF       = 0.2; 0.8	;1.5
					opts@cnLevelSpacingF      = 0.025; 0.1 ;0.1
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -0.08;-0.2	;-1.0
					opts_diff@cnMaxLevelValF       = 0.08;0.2	;1.0
					opts_diff@cnLevelSpacingF      = 0.01;0.025	;0.1
				end if
			end if

			;==================
			;  calculate the range for other cross section, base on the athimuthally average, enlarge the data range
			;=================
			if(angle_id.ne.0)then
				;common variable setting
				if(var_name(var_id).ne."tc".and.var_name(var_id).ne."rh".and.var_name(var_id).ne."T_deviation".and.var_name(var_id).ne."wind_vector")then

					if(opts@cnMinLevelValF .gt.0)then
						opts@cnMinLevelValF       = 0.5*opts@cnMinLevelValF
					else
						opts@cnMinLevelValF       = 2*opts@cnMinLevelValF 
					end if

					if(opts@cnMaxLevelValF .gt.0)then
						opts@cnMaxLevelValF       = 2*opts@cnMaxLevelValF  
					else
						opts@cnMaxLevelValF       = 0.5*opts@cnMaxLevelValF  
					end if				

					opts@cnLevelSpacingF      = 2*opts@cnLevelSpacingF

				end if

					;for difference
				if(var_name(var_id).ne."tc".and.var_name(var_id).ne."wind_vector")then

					opts_diff@cnMinLevelValF       = 2*opts_diff@cnMinLevelValF  
					opts_diff@cnMaxLevelValF       = 2*opts_diff@cnMaxLevelValF 
					opts_diff@cnLevelSpacingF      = 2*opts_diff@cnLevelSpacingF

				end if

				;special variable setting

				if(var_name(var_id).eq."H_DIABATIC")then
					if(var_res(var_id).eq."cn")then
						opts@cnMinLevelValF       = 4*opts@cnMinLevelValF 
						opts@cnMaxLevelValF       = 4*opts@cnMaxLevelValF  
						opts@cnLevelSpacingF      = 4*opts@cnLevelSpacingF
						opts_diff@cnMinLevelValF       = 4*opts_diff@cnMinLevelValF  
						opts_diff@cnMaxLevelValF       = 4*opts_diff@cnMaxLevelValF 
						opts_diff@cnLevelSpacingF      = 4*opts_diff@cnLevelSpacingF
					end if
				end if

				if(var_name(var_id).eq."rad_wind")then

					opts@cnMinLevelValF       = 4*opts@cnMinLevelValF 
					opts@cnMaxLevelValF       = 4*opts@cnMaxLevelValF  
					opts@cnLevelSpacingF      = 4*opts@cnLevelSpacingF
					opts_diff@cnMinLevelValF       = 4*opts_diff@cnMinLevelValF  
					opts_diff@cnMaxLevelValF       = 4*opts_diff@cnMaxLevelValF 
					opts_diff@cnLevelSpacingF      = 4*opts_diff@cnLevelSpacingF
				end if

				if(var_name(var_id).eq."snow_graup")then
					if(var_res(var_id).eq."cn")then
						opts@cnMinLevelValF       = 4*opts@cnMinLevelValF 
						opts@cnMaxLevelValF       = 4*opts@cnMaxLevelValF  
						opts@cnLevelSpacingF      = 4*opts@cnLevelSpacingF
						opts_diff@cnMinLevelValF       = 4*opts_diff@cnMinLevelValF  
						opts_diff@cnMaxLevelValF       = 4*opts_diff@cnMaxLevelValF 
						opts_diff@cnLevelSpacingF      = 4*opts_diff@cnLevelSpacingF
					end if
				end if



			end if


			;#### auto color
			if auto_range then



				if(var_name(var_id).ne."wind_vector")then		; auto algorithm

					min_range= min(data_1_plane)
					max_range=max(data_1_plane)
					
					if(var_name(var_id).eq."wa".or.var_name(var_id).eq."pvo".or.var_name(var_id).eq."rvo".or.\
										var_name(var_id).eq."ua".or.var_name(var_id).eq."va")then
						if(abs(min_range).gt.abs(max_range))then
							max_range=-min_range
						else
							min_range=-max_range
						end if
					end if

					spacing=(max_range-min_range)/16
					opts@cnMinLevelValF       = min_range
					opts@cnMaxLevelValF       = max_range
					opts@cnLevelSpacingF      = spacing


					if have_diff then
						;for diff , make the range symmetric
						min_diff_range= min(diff_plane)
						max_diff_range= max(diff_plane)
						if(abs(min_diff_range).gt.abs(max_diff_range))then
							max_diff_range=-min_diff_range
						else
							min_diff_range=-max_diff_range
						end if
						spacing_diff=(max_diff_range-min_diff_range)/16
						opts_diff=opts
						opts_diff@cnMinLevelValF       = min_diff_range
						opts_diff@cnMaxLevelValF       = max_diff_range
						opts_diff@cnLevelSpacingF      = spacing_diff
					end if
				end if



			end if

			;============
			; smooth the variable before plot		;???###### you can change the smooth factor
			;================
			if (smooth(var_id).and. (var_name(var_id) .ne. "wind_vector") )then

					wrf_smooth_2d( data_1_plane, 3 )
					wrf_smooth_2d( data_2_plane, 3 )	
					if have_diff then			
						wrf_smooth_2d( diff_plane, 3 )		
					end if						

			end if

			;----------------------
			;begin the plot
			;------------------------

			opts_a=opts
			opts_b=opts

			if(var_name(var_id) .ne. "wind_vector" )then 
				contour_data_1(var_id,angle_id) = wrf_contour(a,wks,data_1_plane(it,var_id,angle_id,0:zspan,xleft:xright),opts_a)	
				contour_data_2(var_id,angle_id) = wrf_contour(b,wks,data_2_plane(it,var_id,angle_id,0:zspan,xleft:xright),opts_b)	
				if average_time then
					if(it.eq.time_end)then	;average
				   	 	contour_data_1_avgtime(var_id,angle_id) = wrf_contour(a,wks,data_1_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright),opts_a)	
						contour_data_2_avgtime(var_id,angle_id) = wrf_contour(b,wks,data_2_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright),opts_b)	
					end if	
				end if		
			else
				contour_data_1(var_id,angle_id)= wrf_vector(a,wks,data_1_uu_plane(it,var_id,angle_id,0:zspan,xleft:xright),\
															data_1_ww_plane(it,var_id,angle_id,0:zspan,xleft:xright)*100,opts_a) ;???### *100
				contour_data_2(var_id,angle_id)= wrf_vector(b,wks,data_2_uu_plane(it,var_id,angle_id,0:zspan,xleft:xright),\	
															data_2_ww_plane(it,var_id,angle_id,0:zspan,xleft:xright)*100,opts_b)
				if average_time then
					if(it.eq.time_end)then	;average
				 		contour_data_1_avgtime(var_id,angle_id)= wrf_vector(a,wks,data_1_uu_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright),\
																 data_1_ww_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright)*100,opts_a)	;???### *100
						contour_data_2_avgtime(var_id,angle_id)= wrf_vector(b,wks,data_2_uu_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright),\		
																 data_2_ww_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright)*100,opts_b)
					end if	
				end if			
			end if

			if(have_diff)then

				if(var_name(var_id) .ne. "wind_vector" )then				
					contour_diff(var_id,angle_id)= wrf_contour(a,wks,diff_plane(it,var_id,angle_id,0:zspan,xleft:xright),opts_diff)	
					if average_time then
						if(it.eq.time_end)then	;average
							contour_diff_avgtime(var_id,angle_id)= wrf_contour(a,wks,diff_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright),opts_diff)	
						end if
					end if
				else
				    contour_diff(var_id,angle_id)= wrf_vector(b,wks,diff_uu_plane(it,var_id,angle_id,0:zspan,xleft:xright),\
																	diff_ww_plane(it,var_id,angle_id,0:zspan,xleft:xright)*100,opts_diff) 
																																		;???### *100
					if average_time then
						if(it.eq.time_end)then	;average
							contour_diff_avgtime(var_id,angle_id)= wrf_vector(b,wks,diff_uu_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright),\
																	   diff_ww_plane_avgtime(var_id,angle_id,0:zspan,xleft:xright)*100,opts_diff)	;???### *100
						end if
					end if
				end if
			end if

			;======================
			; overlay the map
			;=======================      


			;===================
			; decide overlay, only work for 2 and 3 variable overlay currently		;???##############
			;===================

			if(num_overlay .eq. 2)then
				plot1_overlay1(angle_id)=contour_data_1(0,angle_id)
				plot2_overlay1(angle_id)=contour_data_2(0,angle_id)
				if average_time then
					if(it.eq.time_end)then	;average
						plot1_overlay1_avgtime(angle_id)=contour_data_1_avgtime(0,angle_id)
						plot2_overlay1_avgtime(angle_id)=contour_data_2_avgtime(0,angle_id)
					end if
				end if
			end if

			if(num_overlay .eq. 3)then				
			 	plot1_overlay2(angle_id)=	contour_data_1(1,angle_id);the 2nd variable give to plot1_overlay2(angle_id)
			 	plot2_overlay2(angle_id)=	contour_data_2(1,angle_id)
				if average_time then
					if(it.eq.time_end)then	;average
				 		plot1_overlay2_avgtime(angle_id)=	contour_data_1_avgtime(1,angle_id);the 2nd variable give to plot1_overlay2(angle_id)
				 		plot2_overlay2_avgtime(angle_id)=	contour_data_2_avgtime(1,angle_id)
					end if
				end if
			end if				


			if(isoverlay(var_id) .and.(num_overlay .eq. total_num_overlay) )then; only the last variable will be 
	;combined to previous overlay variables and output, for examplem if isoverlay=(/True,True,True/) , plot_1_3d(it,0,level) and plot_1_3d(it,1,level) are missing value, only output plot_1_3d(it,2,level)

				last_overlay_id=var_id	; record for the panel plot				
				if( num_overlay .eq. 2 )then
		   			overlay(contour_data_1(var_id,angle_id),plot1_overlay1(angle_id))   
					plot_1(var_id,angle_id) = contour_data_1(var_id,angle_id)
		   			overlay(contour_data_2(var_id,angle_id),plot2_overlay1(angle_id))	
					plot_2(var_id,angle_id) = contour_data_2(var_id,angle_id)
					if average_time then
						if(it.eq.time_end)then	;average
				   			overlay(contour_data_1_avgtime(var_id,angle_id),plot1_overlay1_avgtime(angle_id))   
							plot_1_avgtime(var_id,angle_id) = contour_data_1_avgtime(var_id,angle_id)
				   			overlay(contour_data_2_avgtime(var_id,angle_id),plot2_overlay1_avgtime(angle_id))	
							plot_2_avgtime(var_id,angle_id) = contour_data_2_avgtime(var_id,angle_id)
						end if
					end if
			  	end if

			  	if( num_overlay .eq. 3 )then
		   			overlay(contour_data_1(var_id,angle_id),plot1_overlay1(angle_id))   
		   			overlay(contour_data_1(var_id,angle_id),plot1_overlay2(angle_id))   
					plot_1(var_id,angle_id) = contour_data_1(var_id,angle_id)
		   			overlay(contour_data_2(var_id,angle_id),plot2_overlay1(angle_id))	
		   			overlay(contour_data_2(var_id,angle_id),plot2_overlay2(angle_id))	
					plot_2(var_id,angle_id) = contour_data_2(var_id,angle_id)
					if average_time then
						if(it.eq.time_end)then	;average
				   			overlay(contour_data_1_avgtime(var_id,angle_id),plot1_overlay1_avgtime(angle_id))   
				   			overlay(contour_data_1_avgtime(var_id,angle_id),plot1_overlay2_avgtime(angle_id))   
							plot_1_avgtime(var_id,angle_id) = contour_data_1_avgtime(var_id,angle_id)
				   			overlay(contour_data_2_avgtime(var_id,angle_id),plot2_overlay1_avgtime(angle_id))	
				   			overlay(contour_data_2_avgtime(var_id,angle_id),plot2_overlay2_avgtime(angle_id))	
							plot_2_avgtime(var_id,angle_id) = contour_data_2_avgtime(var_id,angle_id)
						end if
					end if
			  	end if

			else	; this is the situation when overlay =false, ;if only one variable,isoverlay is false as well	

				if(.not.isoverlay(var_id) )then
					plot_1(var_id,angle_id) = contour_data_1(var_id,angle_id)
					plot_2(var_id,angle_id) = contour_data_2(var_id,angle_id)
					if average_time then
						if(it.eq.time_end)then	;average
							plot_1_avgtime(var_id,angle_id) = contour_data_1_avgtime(var_id,angle_id)
							plot_2_avgtime(var_id,angle_id) = contour_data_2_avgtime(var_id,angle_id)
						end if
					end if
				end if

			end if

			;---------------------
			; for the difference
			;----------------------
			if(have_diff)then

				if(num_overlay_diff .eq. 2)then
					plot_diff_overlay1(angle_id)=contour_diff(0,angle_id) 
					if average_time then
						if(it.eq.time_end)then	;average
							plot_diff_overlay1_avgtime(angle_id)=contour_diff_avgtime(0,angle_id) 
						end if	
					end if
				end if

				if(num_overlay_diff .eq. 3)then
					plot_diff_overlay2(angle_id)=contour_diff(1,angle_id) 	
					if average_time then
						if(it.eq.time_end)then	;average
							plot_diff_overlay2_avgtime(angle_id)=contour_diff_avgtime(1,angle_id) 	
						end if
					end if
				end if

				if(isoverlay_diff(var_id) .and.  (num_overlay_diff .eq. total_num_overlay_diff))then	
					if( num_overlay_diff .eq. 2 )then
						overlay(contour_diff(var_id,angle_id),plot_diff_overlay1(angle_id)) 
						plot_diff(var_id,angle_id) =   contour_diff(var_id,angle_id)
						if average_time then
							if(it.eq.time_end)then	;average
								overlay(contour_diff_avgtime(var_id,angle_id),plot_diff_overlay1_avgtime(angle_id)) 
								plot_diff_avgtime(var_id,angle_id) =   contour_diff_avgtime(var_id,angle_id)
							end if
						end if
					end if

					if( num_overlay_diff .eq. 3)then
						overlay(contour_diff(var_id,angle_id),plot_diff_overlay1(angle_id)) 
						overlay(contour_diff(var_id,angle_id),plot_diff_overlay2(angle_id)) 
						plot_diff(var_id,angle_id) =   contour_diff(var_id,angle_id)
						if average_time then
							if(it.eq.time_end)then	;average
								overlay(contour_diff_avgtime(var_id,angle_id),plot_diff_overlay1_avgtime(angle_id)) 
								overlay(contour_diff_avgtime(var_id,angle_id),plot_diff_overlay2_avgtime(angle_id)) 
								plot_diff_avgtime(var_id,angle_id) =   contour_diff_avgtime(var_id,angle_id)
							end if
						end if
					end if

				else		
					if(.not.isoverlay_diff(var_id) )then
						plot_diff(var_id,angle_id) = contour_diff(var_id,angle_id)
					end if
					if average_time then
						if(it.eq.time_end)then ;average
							plot_diff_avgtime(var_id,angle_id) = contour_diff_avgtime(var_id,angle_id)
						end if
					end if
				end if												

			end if

			;------------------------
			; Delete options and fields, so we don't have carry over
			;-------------------


			delete(opts_a)
			delete(opts_b)
			delete(opts_diff)


		end do ; end of cross section

		;-------------
		; Delete options and fields
		;-----------------------
		delete(opts)
		delete(data_1_uu_polar_cross)
		delete(data_1_ww_polar_cross)
		delete(data_2_uu_polar_cross)
		delete(data_2_ww_polar_cross)
		delete(data_1_rad_polar)
		delete(data_1_tan_polar)
		delete(data_2_rad_polar)
		delete(data_2_tan_polar)
		delete(data_1_polar_cross)
		delete(data_2_polar_cross)

		if(var_name(var_id) .eq. "wind_vector" )then		
			delete(data_1_uu_polar)
			delete(data_1_vv_polar)
			delete(data_1_ww_polar)
			delete(data_2_uu_polar)
			delete(data_2_vv_polar)
			delete(data_2_ww_polar)

			delete(data_1_uu_polar_avg)
			delete(data_2_uu_polar_avg)
			delete(data_1_ww_polar_avg)
			delete(data_2_ww_polar_avg)
		end if

		if(var_name(var_id) .eq. "rad_wind".or.var_name(var_id) .eq. "tan_wind")then	
			delete(data_1_uu_polar)
			delete(data_1_vv_polar)
			delete(data_1_ww_polar)
			delete(data_2_uu_polar)
			delete(data_2_vv_polar)
			delete(data_2_ww_polar	)

			delete(data_1_polar)
			delete(data_2_polar)
			delete(data_1_polar_avg)
			delete(data_2_polar_avg)

		end if

		if(var_name(var_id) .ne. "wind_vector" .and. var_name(var_id) .ne. "rad_wind".and.var_name(var_id) .ne. "tan_wind")then		

			delete(data_1_polar)
			delete(data_2_polar)
			delete(data_1_polar_avg)
			delete(data_2_polar_avg)

		end if



	end do    ; END OF VARIABLE LOOP

	delete(xc_a)
	delete(yc_a)
	delete(xc_b)
	delete(yc_b)
	delete(lonc_a)
	delete(latc_a)
	delete(lonc_b)
	delete(latc_b)
	delete(azrad)
	delete(xc_a_1D)
	delete(yc_a_1D)
	delete(xc_b_1D)
	delete(yc_b_1D)

	;-----------
	;add the position
	;----------------
	if have_slp_plot then
		dotres = True
		dotres@gsMarkerColor = "Black"
		dotres@gsMarkerIndex = 16
		dotres@gsMarkerSizeF = 0.001

		plot_slp_1_dot=gsn_add_polymarker(wks,plot_slp_1,lon_min_a(it) ,lat_min_a(it),dotres)
		plot_slp_2_dot=gsn_add_polymarker(wks,plot_slp_2,lon_min_b(it) ,lat_min_b(it),dotres)
	end if

	;------------------
	;panel plot
	;------------------

 
	resP            = True                         ; modify the panel plot_1
	resP@gsnPanelLabelBar    = False                ; add common colorbar  , first,all plots should be set to the same interval
	;resP@pmLabelBarOrthogonalPosF=0.01
	;resP@lbLabelFontHeightF  = 0.007       ; make labels smaller
	resP@gsnMaximize=True
	;resP@gsnFrame         = False                  ; don't advance panel plot_1,by default,after call gsn_panel below,it will automatically 
		                                            ;advance the frame, now i manually set it stand still if I want to add something on it.
	resP@gsnPanelRowSpec = True                   ; tell panel what order to plt
	resP@gsnPaperOrientation="portrait"  			;or landscape

	;-------which portion in a page I want to draw--------             
	;resP@gsnPanelBottom   = 0.1          
	;resP@gsnPanelTop  = 0.9                  
	;resP@gsnPanelLeft=0.0
	;resP@gsnPanelFigureStrings= (/"a)","b)","c)","d)","e)","f)"/) ; add strings to panel
	;resP@amJust="BottomLeft"
	;resP@gsnPanelFigureStringsBackgroundFillColor=0
	;resP@gsnPanelFigureStringsPerimOn=False
	;resP@gsnPanelYWhiteSpacePercent = 0.01
	;resP@gsnPanelXWhiteSpacePercent = 0.5		;??? ### if you have some overlap in the panel plot, use this one to adjust
	;resP@gsnPanelLeft=0.1
	;resP@gsnPanelRight=0.9

	 do var_id=0,var_numbers-1,1
		
		resP@gsnPanelMainString = time_name(it) 

		if(	.not. isoverlay(var_id).or.(isoverlay(var_id).and.var_id.eq.last_overlay_id) )then	

            if(have_diff)then

				if have_slp_plot then
                	gsn_panel(wks,(/plot_1(var_id,0),plot_2(var_id,0),plot_diff(var_id,0),\
									plot_1(var_id,1),plot_2(var_id,1),plot_diff(var_id,1),\
									plot_1(var_id,2),plot_2(var_id,2),plot_diff(var_id,2),\
									plot_1(var_id,3),plot_2(var_id,3),plot_diff(var_id,3),\
									plot_1(var_id,4),plot_2(var_id,4),plot_diff(var_id,4),\
									plot_slp_1,plot_slp_2,plot_slp_diff/),(/3,3,3,3,3,1,1,1/),resP)
				else	
					gsn_panel(wks,(/plot_1(var_id,0),plot_2(var_id,0),plot_diff(var_id,0),\
									plot_1(var_id,1),plot_2(var_id,1),plot_diff(var_id,1),\
									plot_1(var_id,2),plot_2(var_id,2),plot_diff(var_id,2),\
									plot_1(var_id,3),plot_2(var_id,3),plot_diff(var_id,3),\
									plot_1(var_id,4),plot_2(var_id,4),plot_diff(var_id,4)/),(/3,3,3,3,3/),resP)
				end if			    
				  

				if average_time then
					if(it.eq.time_end)then	;average
						resP@gsnPanelMainString="time average"
		            	gsn_panel(wks,(/plot_1_avgtime(var_id,0),plot_2_avgtime(var_id,0),plot_diff_avgtime(var_id,0),\
										plot_1_avgtime(var_id,1),plot_2_avgtime(var_id,1),plot_diff_avgtime(var_id,1),\
										plot_1_avgtime(var_id,2),plot_2_avgtime(var_id,2),plot_diff_avgtime(var_id,2),\
										plot_1_avgtime(var_id,3),plot_2_avgtime(var_id,3),plot_diff_avgtime(var_id,3),\
										plot_1_avgtime(var_id,4),plot_2_avgtime(var_id,4),plot_diff_avgtime(var_id,4)/),(/3,3,3,3,3/),resP)

					end if
				end if

            else	

				if have_slp_plot then
                	gsn_panel(wks,(/plot_1(var_id,0),plot_2(var_id,0),\
									plot_1(var_id,1),plot_2(var_id,1),\
									plot_1(var_id,2),plot_2(var_id,2),\
									plot_1(var_id,3),plot_2(var_id,3),\
									plot_1(var_id,4),plot_2(var_id,4),\
									plot_slp_1,plot_slp_2/),(/2,2,2,2,2,1,1/),resP)
				else
                	gsn_panel(wks,(/plot_1(var_id,0),plot_2(var_id,0),\
									plot_1(var_id,1),plot_2(var_id,1),\
									plot_1(var_id,2),plot_2(var_id,2),\
									plot_1(var_id,3),plot_2(var_id,3),\
									plot_1(var_id,4),plot_2(var_id,4)/),(/2,2,2,2,2/),resP)
				end if


				if average_time then
					if(it.eq.time_end)then	;average
						resP@gsnPanelMainString="time average"	
		            	gsn_panel(wks,(/plot_1_avgtime(var_id,0),plot_2_avgtime(var_id,0),\
										plot_1_avgtime(var_id,1),plot_2_avgtime(var_id,1),\
										plot_1_avgtime(var_id,2),plot_2_avgtime(var_id,2),\
										plot_1_avgtime(var_id,3),plot_2_avgtime(var_id,3),\
										plot_1_avgtime(var_id,4),plot_2_avgtime(var_id,4)/),(/2,2,2,2,2/),resP)

					end if
				end if

            end if

		end if

	end do

end do       ; END OF TIME LOOP
  


end

