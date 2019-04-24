load "$NCARG_ROOT/lib/ncarg/nclex/gsun/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/home/liangjia/soft/ncl/myNCL-function.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;http://www2.mmm.ucar.edu/wrf/OnLineTutorial/Graphics/NCL/Examples/CROSS_SECTION/wrf_CrossSection4.ncl
;https://www.ncl.ucar.edu/Applications/height_lat.shtml
; bug: setting for nx_a, xleft,xright, have problems, no tick mark output, I cannot fix them
begin

;=================
; files location  
;================					;???###
dir_a="/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/2010/mosaic/coarse/full/"
dir_b="/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/2010/mosaic/coarse/seas-sulfate-bc-oc/"
 	
;dir_a="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/full/"
;dir_b="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/full-turnoffdust/"	
;dir_b="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/other/"		
	
namelist_t = "/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/ncl/namelist-cross" 
				 					;???### if you plot the wrf restart, just use wrfout*, don't need to create another namelist 	
filename     = asciiread(namelist_t,-1,"string") 	; -1 mean only one dimension
ntimes   = dimsizes(filename)
print(filename)

;----set time----
start_time=0					;???### 0 is the first time, you can specify 
end_time=0						;???### 999 means at the end of time, you can specify
if (end_time.eq.999)then
	time_end=ntimes-1
else
	time_end=end_time
end if
;--------------
fix_cross=True					;???###
moving_cross=False				;???###

same_plane=True					;???### ture is the same plane for data1 and data2.  fix_cross or moving_cross can set this 
maxip=1							; how many cross section for each plot
;-----------------
average_lon=False				;???###
d_lon=5						;???###
;-----------------
pivot_cross=False				;???### 
angle=(/90.,45.,0.,-45./)
if pivot_cross then
	maxip=dimsizes(angle)						;???### following the hurricane. make several cross section
end if
d_center=6.0
;-----------------------
zmax0=10.						; if your top is 200hpa, write 200.(keep the decimal point), if it is 10km, write 10. (keep the decimal point) 
have_diff=True						;???###### set to True when the cross sections are the same in two data sets, then they can be compared
add_dot=False					;???########### add the dot to the horizontal plane, for diagnose 
nest=False						;???###
good_picture=False
if nest then
	good_picture=False			;???### very slow if use areafill in the nest domain
end if	
vertical_type=1					;???### 1 is the height coordinate, 2 is pressure coordinate
set=22		        ;???########
average_time=True				;??? not completed yet. the cross sections have different length
auto_range=False
;=======================
; define the plot array						
;=======================	
plot_1=new((/50,50/),"graphic") 			;store the data_1 
plot_2=new((/50,50/),"graphic")			;store the data_2 
plot_diff=new((/50,50/),"graphic")		; store the diff
plot_1_avgtime=new((/50,10/),"graphic") 			
plot_2_avgtime=new((/50,10/),"graphic")			
plot_diff_avgtime=new((/50,10/),"graphic")	

plot_slp_1_line=new((/10/),"graphic")
plot_slp_1_dot=new((/10/),"graphic")

plot_slp_2_line=new((/10/),"graphic")
plot_slp_2_dot=new((/10/),"graphic")
contour_data_1=new((/10,50/),"graphic")
contour_data_2=new((/10,50/),"graphic")	
contour_diff=new((/10,50/),"graphic")			;contour for different variable,different cross section
contour_data_1_avgtime=new((/10,10/),"graphic")
contour_data_2_avgtime=new((/10,10/),"graphic")	
contour_diff_avgtime=new((/10,10/),"graphic")	
lat1_array_a=new((/ntimes,10/),"float")         ; cross sections
lat2_array_a=new((/ntimes,10/),"float")
lon1_array_a=new((/ntimes,10/),"float")
lon2_array_a=new((/ntimes,10/),"float")
lat1_array_b=new((/ntimes,10/),"float")         ; cross sections
lat2_array_b=new((/ntimes,10/),"float")
lon1_array_b=new((/ntimes,10/),"float")
lon2_array_b=new((/ntimes,10/),"float")
lat_dot_a=new((/ntimes,10/),"float")
lon_dot_a=new((/ntimes,10/),"float")
lat_dot_b=new((/ntimes,10/),"float")
lon_dot_b=new((/ntimes,10/),"float")
units=new((/50/),"string")

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

;======================================
; set up cross sections locations				;???####  different line  in different time,
;======================================			;first dimension is time, second is cross section id. 
												;!! be careful, the time here should match  namelist , otherwise, if start_time .ne.0, may cause mismatch

	;(1) fix cross-section

if fix_cross then

								;??### ip=0,0 only one cross section at one time. can give multiple cross section if ip=0,n
	lat1_array_a(:,0)=11.			;??### lat1_array_a must be less than lat2_array_a, 
	lat2_array_a(:,0)=26.			
	lon1_array_a(:,0)=0.
	lon2_array_a(:,0)=0.

	;ip=1
	;lat1_array_a(:,1)=10.			;??###  seconde cross section
	;lat2_array_a(:,1)=28.			
	;lon1_array_a(:,1)=10.
	;lon2_array_a(:,1)=10.
	;
	if same_plane then				;for data2
		lat1_array_b=lat1_array_a           			
		lat2_array_b=lat2_array_a
		lon1_array_b=lon1_array_a
		lon2_array_b=lon2_array_a  
	end if
end if

	;(2) moving cross-section

if moving_cross then

	;(A) first cross section
						
	;  ;coarse domain , full
	lat1_array_a(:44,0)=3.		;lon1_array_a(:2,ip)=(/-3,-5,-10/)	;different cross section at different time
	lat2_array_a(:44,0)=32.		; lon2_array_a(:2,ip)=(/-3,-5,-10/)
	
	lon1_array_a(:44,0)=(/1.83,0.60,0.28,0.31,-0.38,-1.40,-2.73,-2.69,-4.35,-6.39,-6.62,-9.06,-11.31,\
		-12.89,-15.23,-16.85,-18.47,-18.78,-18.76,-20.02,-19.68,-21.34,-21.34,-22.33,\
		-23.00,-24.01,-24.71,-25.37,-26.05,-26.74,-28.09,-28.44,-28.78,-29.14,-29.49,-30.55,-31.23,-31.93,-32.64,-33.30,-33.98,-35.00,-35.31,-35.68,-36.02/)


	lon2_array_a(:44,0)=(/1.83,0.60,0.28,0.31,-0.38,-1.40,-2.73,-2.69,-4.35,-6.39,-6.62,-9.06,-11.31,\
		-12.89,-15.23,-16.85,-18.47,-18.78,-18.76,-20.02,-19.68,-21.34,-21.34,-22.33,\
		-23.00,-24.01,-24.71,-25.37,-26.05,-26.74,-28.09,-28.44,-28.78,-29.14,-29.49,-30.55,-31.23,-31.93,-32.64,-33.30,-33.98,-35.00,-35.31,-35.68,-36.02/)

	
	; for comparing callipso

	;lat1_array_a(:,0)=(/0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0/)
	;lat2_array_a(:,0)=(/35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35.,35./)
	; lon1_array_a(:,0)=(/0,-5,-5,-8,-13,-14,-15,-18,-20,-21,-23,-23,-25,-25,-28,-29,-30,-30,-31/)
	;lon2_array_a(:,0)=(/0,-5,-5,-8,-13,-14,-15,-18,-20,-21,-23,-23,-25,-25,-28,-29,-30,-30,-31/)


	;data2	;coarse domain, other
	lat1_array_b(:44,0)=3.
	lat2_array_b(:44,0)=32.   			
	lon1_array_b(:44,0)=(/1.83,0.60,0.28,0.31,-0.38,-1.07,-2.73,-2.41,-3.02,-4.68,-6.24,-8.60,-9.51,-11.88,-14.27,-15.13,-16.76,-17.74,\
		-18.72,-20.69,-21.02,-21.01,-21.67,-23.00,-23.67,-24.33,-24.68,-25.69,-26.03,-26.72,-27.76,-28.09,-28.44,-28.80,-29.17,\
		-29.88,-30.91,-31.59,-32.29,-32.98,-33.66,-34.34,-34.69,-35.37,-36.08/)

	lon2_array_b(:44,0)=(/1.83,0.60,0.28,0.31,-0.38,-1.07,-2.73,-2.41,-3.02,-4.68,-6.24,-8.60,-9.51,-11.88,-14.27,-15.13,-16.76,-17.74,\
		-18.72,-20.69,-21.02,-21.01,-21.67,-23.00,-23.67,-24.33,-24.68,-25.69,-26.03,-26.72,-27.76,-28.09,-28.44,-28.80,-29.17,\
		-29.88,-30.91,-31.59,-32.29,-32.98,-33.66,-34.34,-34.69,-35.37,-36.08/)

	;(B) seconde cross section
						 
	;lat1_array_a(:2,1)=10.
	;lat2_array_a(:2,1)=30.
	;lon1_array_a(:2,1)=(/-7.5,-9,-15/)
	;lon2_array_a(:2,1)=(/-7.5,-9,-15/)

	if same_plane then				;for data2
		lat1_array_b=lat1_array_a           			
		lat2_array_b=lat2_array_a
		lon1_array_b=lon1_array_a
		lon2_array_b=lon2_array_a  
	end if

end if

if pivot_cross then

		;A: Coarse domain

	;full  3hr  from 2112 to 2700
	clat_a=(/17.11,16.88,16.47,16.83,20.59,17.69,17.37,16.67,17.07,16.59,16.35,17.08,18.44,18.12,\
			18.47,17.83,17.85,15.31,14.02,14.02,11.77,13.05,13.38,14.34,14.66,15.30,15.61,15.92,\
			16.23,16.54,16.84,17.14,17.44,17.75,18.05,18.34,18.63,18.59,18.85,18.83,18.79,18.74,18.36,18.66,18.63/)

	clon_a=(/0.40,-0.32,0.31,-2.70,-4.33,-4.65,-8.79,-7.81,-8.79,-11.20,-12.57,-14.22,-15.86,-16.21,-16.88,\
			-17.24,-17.92,-21.00,-22.00,-22.00,-21.35,-21.01,-22.00,-22.33,-23.00,-24.01,-24.68,-25.36,-26.04,\
			-26.72,-27.41,-28.09,-28.78,-29.14,-29.83,-30.53,-31.23,-31.91,-32.95,-33.30,-33.98,-34.66,-35.31,-35.68,-36.02/)




	;other 3hr  from 2112 to 2700
	clat_b=(/17.11,16.51,16.47,16.80,20.59,17.72,17.37,16.40,16.48,16.67,17.66,17.09,18.07,18.12,\
			18.46,18.16,17.86,15.31,13.70,14.02,13.37,13.70,14.02,14.34,14.66,14.65,14.96,15.60,\
			15.91,16.22,16.84,16.82,17.45,17.43,18.06,18.68,18.97,18.93,18.89,18.85,19.13,19.08,19.04,19.01,19.28/)

	clon_b=(/0.40,-0.02,0.31,-2.37,-4.33,-4.99,-8.43,-8.51,-9.52,-12.55,-12.83,-14.55,-14.85,-16.21,-16.54,\
			-17.57,-18.26,-21.00,-22.00,-22.33,-20.68,-21.34,-22.00,-22.67,-23.67,-24.33,-25.01,-25.35,-26.03,\
			-26.71,-27.41,-28.08,-28.44,-29.12,-29.49,-30.20,-30.91,-31.59,-32.27,-32.95,-33.66,-34.34,-35.03,-35.37,-36.08/)


		;full  3hr
clat_a=(/11.70,11.06,13.27,12.87,12.44,13.58,12.00,12.74,12.88,13.36,15.38,16.70,16.93,16.51,17.06,\
16.65,16.93,17.15,17.39,17.90,19.23,18.77,19.23,19.29,20.32,20.41,20.70/)
clon_a=(/-20.80,-21.09,-22.66,-23.32,-23.61,-23.73,-24.73,-26.58,-26.80,-27.58,-27.10,-27.33,\
-28.01,-28.71,-29.33,-29.69,-29.85,-30.54,-30.67,-31.30,-32.06,-31.92,-33.17,-33.41,-34.25,-34.99,-35.40/)


;fullnodust 3hr
clat_b=(/11.34,11.34,11.66,12.47,12.55,12.76,11.96,12.34,12.24,13.71,14.13,16.07,16.02,\
16.62,16.27,16.45,17.01,17.56,17.85,18.24,19.39,19.22,19.74,19.96,20.43,20.77,20.43/)
clon_b=(/-20.33,-21.60,-22.73,-23.86,-23.75,-24.16,-25.02,-25.43,-26.71,-27.78,-28.16,-27.94,\
-28.39,-28.71,-29.30,-29.27,-29.63,-30.26,-30.92,-31.09,-31.73,-32.25,-33.71,-33.68,-34.14,-35.02,-36.18/)


;other 3hr
;clat_b=(/12.52,11.73,11.98,13.13,13.66,13.84,13.54,12.20,12.99,13.99,12.83,15.73,17.06,17.04,\
;17.14,17.12,17.08,17.24,17.54,17.93,17.77,18.10,18.60,19.26,19.14,19.37,19.44/)
;clon_b=(/-21.16,-21.02,-23.35,-22.04,-22.70,-22.41,-24.54,-25.50,-26.77,-27.86,-28.48,-27.22,-28.47,\
;-29.03,-30.01,-30.43,-31.10,-31.60,-32.07,-32.74,-33.03,-33.96,-34.00,-35.43,-36.07,-36.36,-37.21/)


end if

if add_dot then
	do ip=0,0
		lat_dot_a(:3,ip)=(/15.0,30.0,30.0,30.0/)
		lon_dot_a(:3,ip)=(/-25.0,-30.0,-30.0,-30.0/)
		lat_dot_b(:3,ip)=(/15.0,30.0,30.0,30.0/)
		lon_dot_b(:3,ip)=(/-25.0,-30.0,-30.0,-30.0/)
	end do
end if


;===================
; variable list					
;==================    
	;----------------	
	;examples 101-104 , don't modify
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

if (set.eq.1)then									
var_name=(/"wa","wind_vector","pvo"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","vc","sh","sh","sh"/)				;cn is contour, sh is shaded 
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)			;  overlay for data_1
isoverlay_diff=(/True,True,True,True,False/)		;  overlay for diff
in_restart_file=(/False,False/)						;  some variables are only available in restart files
end if

if (set.eq.2)then									
var_name=(/"wind_vector","wa","rvo"/)									
exist_both_file=(/True,True,True/)
var_res=(/"vc","cn","sh"/)				
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)				
isoverlay_diff=(/True,True,True/)	
in_restart_file=(/False,False/)					
end if

if (set.eq.3)then									
var_name=(/"eth","rh"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"cn","sh"/)				
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)				
isoverlay_diff=(/True,True,True,True,False/)	
in_restart_file=(/False,False/)					
end if

if (set.eq.4)then									
var_name=(/"th","ua"/)									
exist_both_file=(/True,True,True,True,True/)
var_res=(/"sh","cn","vc","sh","sh"/)				 
smooth=(/False,False,False/)
isoverlay=(/True,True,True,False,False/)				
isoverlay_diff=(/True,True,True,True,False/)	
in_restart_file=(/False,False/)					
end if


if (set.eq.10)then									
var_name=(/"total_dust","tc"/)									
exist_both_file=(/False,True,True/)
var_res=(/"cn","sh","cn"/)				
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)				
isoverlay_diff=(/True,True,True/)	
in_restart_file=(/False,False/)		
end if

;restart file
if (set.eq.15)then
var_name=(/"EXTCOF55","H_DIABATIC"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.16)then
var_name=(/"EXTCOF55","RTHCUTEN"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.17)then
var_name=(/"EXTCOF55","total_moist_tendency"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,False/)
end if


if (set.eq.18)then
var_name=(/"EXTCOF55","RTHRATSW"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.19)then
var_name=(/"EXTCOF55","RTHRATLW"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if


if (set.eq.20)then
var_name=(/"EXTCOF55","RTHRATEN"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.21)then
var_name=(/"EXTCOF55","RTHBLTEN"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

if (set.eq.22)then
var_name=(/"EXTCOF55","RTHFTEN"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if


if (set.eq.23)then
var_name=(/"EXTCOF55","total_tendency"/)  ;ACCUMULATED TOTAL GRID SCALE PRECIPITATION
exist_both_file=(/True,True,True/)
var_res=(/"cn","sh","cn","sh","vc"/)
smooth=(/False,False,False/)
isoverlay=(/True,True,True/)
isoverlay_diff=(/True,True,True,True/)
in_restart_file=(/False,True/)
end if

;3d single variable 


if (set.eq.608)then	
	var_name=(/"pvo"/)
	exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.609)then
   var_name=(/"rvo"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.610)then
   var_name=(/"th"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.611)then
   var_name=(/"eth"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.612)then
   var_name=(/"tc"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.613)then
   var_name=(/"rh"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.614)then
   var_name=(/"QVAPOR"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.615)then
   var_name=(/"QCLOUD"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.616)then
   var_name=(/"QNDROP"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.617)then
   var_name=(/"QRAIN"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.618)then
   var_name=(/"QICE"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.619)then
   var_name=(/"snow_graup"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.620)then
   var_name=(/"wa"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.621)then
   var_name=(/"wind_speed"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.622)then
   var_name=(/"t_td"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.623)then
   var_name=(/"total_dust"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.624)then
   var_name=(/"ua"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if


; 3d  adding EXtcof
if (set.eq.708)then	
	var_name=(/"EXTCOF55","pvo"/)
	exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.709)then
   var_name=(/"EXTCOF55","rvo"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.710)then
   var_name=(/"EXTCOF55","th"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.711)then
   var_name=(/"EXTCOF55","eth"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.712)then
   var_name=(/"EXTCOF55","tc"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.713)then
   var_name=(/"EXTCOF55","rh"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.714)then
   var_name=(/"EXTCOF55","QVAPOR"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.715)then
   var_name=(/"EXTCOF55","QCLOUD"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.716)then
   var_name=(/"EXTCOF55","QNDROP"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.717)then
   var_name=(/"EXTCOF55","QRAIN"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.718)then
   var_name=(/"EXTCOF55","QICE"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.719)then
   var_name=(/"EXTCOF55","snow_graup"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.720)then
   var_name=(/"EXTCOF55","wa"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.721)then
   var_name=(/"EXTCOF55","wind_speed"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.722)then
   var_name=(/"EXTCOF55","t_td"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.723)then
   var_name=(/"EXTCOF55","total_dust"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if


if (set.eq.724)then
   var_name=(/"EXTCOF55","ua"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

;3d variable, add stream line
if (set.eq.808)then	
	var_name=(/"wind_vector","pvo"/)
	exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.809)then
   var_name=(/"wind_vector","rvo"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.810)then
   var_name=(/"wind_vector","th"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.811)then
   var_name=(/"wind_vector","eth"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.812)then
   var_name=(/"wind_vector","tc"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.813)then
   var_name=(/"wind_vector","rh"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.814)then
   var_name=(/"wind_vector","QVAPOR"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.815)then
   var_name=(/"wind_vector","QCLOUD"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.816)then
   var_name=(/"wind_vector","QNDROP"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.817)then
   var_name=(/"wind_vector","QRAIN"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.818)then
   var_name=(/"wind_vector","QICE"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.819)then
   var_name=(/"wind_vector","snow_graup"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.820)then
   var_name=(/"wind_vector","wa"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.821)then
   var_name=(/"wind_vector","wind_speed"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.822)then
   var_name=(/"wind_vector","t_td"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.823)then
   var_name=(/"wind_vector","total_dust"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.824)then
   var_name=(/"wind_vector","ua"/)
    exist_both_file=(/True,True/)
	
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if



; open work station
tmpname1=str_sub_str(filename(start_time),":","_")
tmpname2=str_sub_str(filename(time_end),":","_")
var_numbers=dimsizes(var_name)	
if (var_numbers.eq.1) then
	wks_name="cross-section-"+var_name(0)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.eq.2) then
	wks_name="cross-section-"+var_name(0)+"-"+var_name(1)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.eq.3) then
	wks_name="cross-section-"+var_name(0)+"-"+var_name(1)+"-"+var_name(2)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.gt.3) then
	wks_name="cross-section-"+var_name(0)+"-"+var_name(1)+"-"+var_name(2)+"-other-"+tmpname1+"-"+tmpname2  
end if
wks=gsn_open_wks("pdf",wks_name) 

rmfile="rm "+wks_name+".txt"
system(rmfile)
 

; gsn_define_colormap(wks,"WhViBlGrYeOrReWh")                ;???#################
gsn_define_colormap(wks,"cmp_flux")
if (set.eq.7)then		
	;gsn_define_colormap(wks,"BlAqGrYeOrReVi200")	;???###### for AOD
end if

if (set.eq.624.or.set.eq.724.or.set.eq.824)then			;ua
gsn_define_colormap(wks,"t2m_29lev")
end if
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
	do i=0,999				;nested domain	 
		lat_s(i)=5.0		;????######set the domain
		lat_n(i)=30.0
		lon_w(i)=-40.0
		lon_e(i)=-10.0	
	end do
else
	do i=0,999
		lat_s(i)=0.0		;????######set the domain
		lat_n(i)=35.0
		lon_w(i)=-65.0
		lon_e(i)=25.0
	end do
end if



;========================
;begin the time loop
;=======================	
FirstTime = True																				
do it=start_time,time_end,1	

	;-----------------------------------------		;???#######
	;if(it.ge.15.and.it.le.20.or.it.eq.14) then  ; only pickup some time to draw the cross section
	;-------------------------------------------						
	print("workng on "+ filename(it))
	;filename_a=dir_a+filename(it)+"_prior"+".nc"		; this is for the diff in the da cycle
	;filename_b=dir_b+filename(it)+"_prior"+".nc"
	; filename_a=dir_a+filename(it)+"_post"+".nc"		
	; filename_b=dir_b+filename(it)+"_post"+".nc"
	filename_a=dir_a+filename(it)+".nc"				;???######## this is for the forecast stage
	filename_b=dir_b+filename(it)+".nc"

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

	; Set some basic resources
	;res = True
	; res@MainTitle = "REAL-TIME WRF"
	;res@vpWidthF = 1.0               ; overwrite basic plot_1 size
	;res@vpHeightF = 1.0
	;pltres = True

	print("Working on time: " + filename(it) )
	;res@TimeLabel = filename(it)   


	;---------
    ;get some useful variable 
    ;-----------   
	z1  = wrf_user_getvar(a, "z",0)        ; grid point height
	z2  = wrf_user_getvar(b, "z",0)        ; grid point height
	z=z1
	slp_a = wrf_user_getvar(a, "slp",0)
	slp_b = wrf_user_getvar(b, "slp",0)

	p1  = wrf_user_getvar(a, "pressure",0) ; grid point total pressure
	p2  = wrf_user_getvar(b, "pressure",0) 
	p=p1
	ter = wrf_user_getvar(a, "HGT",0)
	;mu1= wrf_user_getvar(a, "MU",0)		;dry pressure, convert from couple to uncouple
	;mub1= wrf_user_getvar(a, "MUB",0)
	;mu2= wrf_user_getvar(b, "MU",0)
	;mub2= wrf_user_getvar(b, "MUB",0)
	
	;------------
	;creat new array
	;------------
	if(it.eq.start_time) then
		dsizes_x = dimsizes(z)
		klev     = dsizes_x(0)
		nlat     = dsizes_x(1)
		mlon     = dsizes_x(2)
		;---------------
		; dry pressure, for calculation convenience
		;dry_p_3d_a=new((/klev,nlat,mlon/),"float")
		;dry_p_3d_b=new((/klev,nlat,mlon/),"float")
	
		;do k=0,klev-1		
		;	dry_p_3d_a(k,:,:)=mub1(:,:)+mu1(:,:)
		;	dry_p_3d_b(k,:,:)=mub2(:,:)+mu2(:,:)
		;end do
	end if
	
	;-----------------------------
	; get the coordinate information
	;----------------------------

	xlat = wrf_user_getvar(a, "XLAT",0)
	xlon = wrf_user_getvar(a, "XLONG",0)
	mdims = getfilevardimsizes(a,"P") ; get some dimension sizes for the file
	nd = dimsizes(mdims)

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
	opts_sh@lbBottomMarginF= 0.0
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

			;------------
			; for stream line
			;---------------
	opts_str=True
	opts_str@stArrowLengthF     = 0.008                ; default is dynamic
	;opts_str@stLengthCheckCount = 15                   ; default is 35
	;opts_str@stArrowStride      = 5
	;opts_str@stMinArrowSpacingF = 0.0               ; default is 0.0             
	;opts_str@stStepSizeF        = 0.001                ; default is dynamic
	;opts_str@stLineStartStride  = 8                    ; default is 2,  control density
	opts_str@stLineThicknessF=0.5
	if nest then
		opts_str@stMinDistanceF=0.05
	else
		opts_str@stMinDistanceF=0.05
	end if

	;===================================
	;plotthe terrain or slp and the position of the  plane_a				
	;=================================
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
	slp_a@lon2d=xlon
	slp_a@lat2d=xlat
	slp_b@lon2d=xlon
	slp_b@lat2d=xlat

	contour_slp_a  = gsn_csm_contour_map(wks,slp_a,opts_slp)
	contour_slp_b  = gsn_csm_contour_map(wks,slp_b,opts_slp)
	plot_slp_1=contour_slp_a
	plot_slp_2=contour_slp_b


	num_overlay=0				; the initial value is 0, it increase one when meet one overlay variable
	num_overlay_diff=0
	;======================
	; loop over variable				;???### add your variable here
	;=====================

	do  var_id=0,var_numbers-1,1
	
		print("Working on Variable  "+var_name(var_id))

		if(var_name(var_id) .ne. "wind_speed" .and. var_name(var_id) .ne. "wind_vector" \
		.and. var_name(var_id) .ne. "t_td" .and. var_name(var_id) .ne. "rvo" \
		.and. var_name(var_id) .ne. "total_dust"  .and. var_name(var_id) .ne. "total_tendency".and. var_name(var_id).ne. "total_moist_tendency"\
		.and. var_name(var_id) .ne. "CCN_total".and. var_name(var_id) .ne. "T_deviation".and. var_name(var_id) .ne. "snow_graup")then 
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
		; add variable calculation here			;???###
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
			RTHFTEN_c=wrf_user_getvar(c,"RTHFTEN",0)	
			RTHFTEN_d=wrf_user_getvar(d,"RTHFTEN",0)
			if nest then								;???### in nest domain, I don't use cumulus scheme
				RTHCUTEN_c=0.0
				RTHCUTEN_d=0.0
			else
				RTHCUTEN_c=wrf_user_getvar(c,"RTHCUTEN",0)
				RTHCUTEN_d=wrf_user_getvar(d,"RTHCUTEN",0)
			end if
			RTHFTEN_c=wrf_user_getvar(c,"RTHFTEN",0)	
			RTHFTEN_d=wrf_user_getvar(d,"RTHFTEN",0)
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
		; end of adding new variable
		;==================

		;-------------
		; assign units
		;-------------
		if(var_name(var_id) .ne."wind_vector" )then
			units(var_id)=data_1@units
		else
			units(var_id)=" "
		end if

		;-------------------
		; get the difference
		;-------------------------
		;if have_diff then
		;	if(var_name(var_id) .ne. "wind_vector"  )then
		;		if exist_both_file(var_id) then
		;			diff=data_1-data_2
		;		else
		;			diff=data_1
		;		end if
		;	end if
		;end if
														
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

		if(var_res(var_id) .eq. "str")then				
		    opts=opts_str
		end if


		if(var_name(var_id) .eq. "tc")then
			opts@gsnContourNegLineDashPattern  =0
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

		;=================================
		; several cross sections for the same variable at the same time	
		;=====================================   			

		do ip=0,maxip-1      	
			

			print("working on the "+ ip+" cross section")
			checkfile="echo working on time "+time_name(it)+" variable "+var_name(var_id)+" cross section number"+ip+"  >>"+wks_name+".txt"
			system(checkfile)

		    ;-----------
		    ;project wind vector to the plane
		    ;------------
			if .not.pivot_cross then
				if(var_name(var_id) .eq. "wind_vector" )then
					if(lat1_array_a(it,ip).eq.lat2_array_a(it,ip))then
						data_1_uu=wrf_user_getvar(a,"ua",0) 
						data_1_ww=wrf_user_getvar(a,"wa",0)*100	;???##########
						data_2_uu=wrf_user_getvar(b,"ua",0)
						data_2_ww=wrf_user_getvar(b,"wa",0)*100
					end if
					if(lon1_array_a(it,ip).eq.lon2_array_a(it,ip))then
						data_1_uu=wrf_user_getvar(a,"va",0) 
						data_1_ww=wrf_user_getvar(a,"wa",0)*100
						data_2_uu=wrf_user_getvar(b,"va",0)
						data_2_ww=wrf_user_getvar(b,"wa",0)*100;
					end if	
				end if
			end if
			

			;=================================   
		    ; make the plane_a, plane_b
		    ;==================================   
 
 			if .not.pivot_cross then
				lat1_a=lat1_array_a(it,ip)
				lon1_a=lon1_array_a(it,ip)			
				lat2_a=lat2_array_a(it,ip)
				lon2_a=lon2_array_a(it,ip) 
				plane_a = new(4,float)
				loc1_a=wrf_user_ll_to_ij(a,lon1_a,lat1_a,True)
				loc2_a=wrf_user_ll_to_ij(a,lon2_a,lat2_a,True)
				plane_a=(/loc1_a(0)-1,loc1_a(1)-1,loc2_a(0)-1,loc2_a(1)-1 /)
				print(loc1_a(0)+" "+loc1_a(1)+" "+loc2_a(0)+" "+loc2_a(1))

				lat1_b=lat1_array_b(it,ip)
				lon1_b=lon1_array_b(it,ip)			
				lat2_b=lat2_array_b(it,ip)
				lon2_b=lon2_array_b(it,ip) 
				plane_b = new(4,float)
				loc1_b=wrf_user_ll_to_ij(a,lon1_b,lat1_b,True)
				loc2_b=wrf_user_ll_to_ij(a,lon2_b,lat2_b,True)
				plane_b=(/loc1_b(0)-1,loc1_b(1)-1,loc2_b(0)-1,loc2_b(1)-1 /)
				print(loc1_b(0)+" "+loc1_b(1)+" "+loc2_b(0)+" "+loc2_b(1))

				angle(ip)= 0.	
				plane_a_0=plane_a
				plane_b_0=plane_b								
			else			;plane for pivot
				 
				plane_a = new(2,float)
				loc_a=wrf_user_ll_to_ij(a,clon_a(it),clat_a(it),True)
				plane_a=(/loc_a(0),loc_a(1)/)
				print("lon loc_a(0) "+loc_a(0)+"lat loc_a(1)"+loc_a(1))

				 
				plane_b = new(2,float)
				loc_b=wrf_user_ll_to_ij(a,clon_b(it),clat_b(it),True)   
				plane_b=(/loc_b(0),loc_b(1)/)
				print("lon loc_b(0) "+loc_b(0)+"lat loc_b(1)"+loc_b(1))
			
					
  			end if


			;======================
			; interpolate to the plane_a, plane_b, all the variable become two dimension
			;=========================
			print("interpolate variables to the plane")

			if (vertical_type .eq. 1)then
				v_type=z                ; Array of vertical coordinates to interpolate to; z is the height array, p is the pressure array, 
			else
				v_type=p
			end if 
     
			if(var_name(var_id) .ne. "wind_vector" )then
	
				if .not. pivot_cross then	
					if .not.average_lon then
						data_1_plane=wrf_user_intrp3d(data_1,v_type,"v",plane_a,angle(ip),True)	 
						data_2_plane=wrf_user_intrp3d(data_2,v_type,"v",plane_b,angle(ip),True)
					else	;zonal average
						;get dimension info
						data_1_plane=wrf_user_intrp3d(data_1,v_type,"v",plane_a,angle(ip),True)	 
						data_2_plane=wrf_user_intrp3d(data_2,v_type,"v",plane_b,angle(ip),True)
						
						dims_a=dimsizes(data_1_plane)
						plane_length_a=dims_a(1)
						plane_levels=dims_a(0)
						data_1_plane_ilon=new( (/tointeger(4*d_lon)+1,plane_levels,plane_length_a/),float)
	
						dims_b=dimsizes(data_2_plane)
						plane_length_b=dims_b(1)
						data_2_plane_ilon=new( (/tointeger(4*d_lon)+1,plane_levels,plane_length_b/),float)	

						lon1_a=lon1_a-d_lon-0.5		;inital longitude	
						lon2_a=lon2_a-d_lon-0.5	

						lon1_b=lon1_b-d_lon-0.5			
						lon2_b=lon2_b-d_lon-0.5	

						do ilon=0,tointeger(4*d_lon)			;from -10 to +10						
							lon1_a=lon1_a+0.5		
							lon2_a=lon2_a+0.5
							loc1_a=wrf_user_ll_to_ij(a,lon1_a,lat1_a,True)
							loc2_a=wrf_user_ll_to_ij(a,lon2_a,lat2_a,True)
							plane_a=(/loc1_a(0)-1,loc1_a(1)-1,loc2_a(0)-1,loc2_a(1)-1 /)
							;print(loc1_a(0)+" "+loc1_a(1)+" "+loc2_a(0)+" "+loc2_a(1))

							lon1_b=lon1_b+0.5		
							lon2_b=lon2_b+0.5
							loc1_b=wrf_user_ll_to_ij(a,lon1_b,lat1_b,True)
							loc2_b=wrf_user_ll_to_ij(a,lon2_b,lat2_b,True)
							plane_b=(/loc1_b(0)-1,loc1_b(1)-1,loc2_b(0)-1,loc2_b(1)-1 /)
							;print(loc1_b(0)+" "+loc1_b(1)+" "+loc2_b(0)+" "+loc2_b(1))

							print("data1 data2 new lon "+lon1_a+" "+lon1_b)

							data_1_plane_ilon_tmp=wrf_user_intrp3d(data_1,v_type,"v",plane_a,angle(ip),True)	 
							data_2_plane_ilon_tmp=wrf_user_intrp3d(data_2,v_type,"v",plane_b,angle(ip),True)

							dims_a=dimsizes(data_1_plane_ilon_tmp)
							dims_b=dimsizes(data_2_plane_ilon_tmp)
							plane_length_a_new=dims_a(1)
							plane_length_b_new=dims_b(1)


							if(plane_length_a_new.ge.plane_length_a)then
								data_1_plane_ilon(ilon,:,:)=data_1_plane_ilon_tmp(:,0:plane_length_a-1)								
							else
								data_1_plane_ilon(ilon,:,0:plane_length_a_new-1)=data_1_plane_ilon_tmp(:,:)							
							end if

							if(plane_length_b_new.ge.plane_length_b)then
								data_2_plane_ilon(ilon,:,:)=data_2_plane_ilon_tmp(:,0:plane_length_b-1)								
							else
								data_2_plane_ilon(ilon,:,0:plane_length_b_new-1)=data_2_plane_ilon_tmp(:,:)							
							end if

							delete(data_1_plane_ilon_tmp)
							delete(data_2_plane_ilon_tmp)
						end do

						data_1_plane=dim_avg_n(data_1_plane_ilon,0)
						data_2_plane=dim_avg_n(data_2_plane_ilon,0)
						delete(data_1_plane_ilon)
						delete(data_2_plane_ilon)
					end if

				else ;pivot
					data_1_plane=wrf_user_intrp3d(data_1,v_type,"v",plane_a,angle(ip),False)	 
					data_2_plane=wrf_user_intrp3d(data_2,v_type,"v",plane_b,angle(ip),False)
				end if

				if(have_diff)then
					if exist_both_file(var_id) then

						dims_a=dimsizes(data_1_plane)
						dims_b=dimsizes(data_2_plane)
						plane_length_a=dims_a(1)
						plane_length_b=dims_b(1)

						if(plane_length_a.ge.plane_length_b)then
							diff_plane=data_1_plane(:,0:plane_length_b-1)-data_2_plane		
						else
							diff_plane=data_1_plane-data_2_plane(:,0:plane_length_a-1)			
						end if

					else		
						diff_plane=data_1_plane
					end if
				end if

			else
				if .not. pivot_cross then

					if .not.average_lon then
						data_1_uu_plane	=wrf_user_intrp3d(data_1_uu,v_type,"v",plane_a,angle(ip),True)	; convert to knots
						data_1_ww_plane	=wrf_user_intrp3d(data_1_ww,v_type,"v",plane_a,angle(ip),True)
						data_2_uu_plane	=wrf_user_intrp3d(data_2_uu,v_type,"v",plane_b,angle(ip),True)
						data_2_ww_plane	=wrf_user_intrp3d(data_2_ww,v_type,"v",plane_b,angle(ip),True)
					else
						;get dimension info
						data_1_uu_plane=wrf_user_intrp3d(data_1_uu,v_type,"v",plane_a,angle(ip),True)
						data_1_ww_plane=wrf_user_intrp3d(data_1_ww,v_type,"v",plane_a,angle(ip),True)	 	 
						data_2_uu_plane=wrf_user_intrp3d(data_2_uu,v_type,"v",plane_b,angle(ip),True)
						data_2_ww_plane=wrf_user_intrp3d(data_2_ww,v_type,"v",plane_b,angle(ip),True)
						
						dims_a=dimsizes(data_1_uu_plane)
						plane_length_a=dims_a(1)
						plane_levels=dims_a(0)
						data_1_uu_plane_ilon=new( (/tointeger(4*d_lon)+1,plane_levels,plane_length_a/),float)
						data_1_ww_plane_ilon=new( (/tointeger(4*d_lon)+1,plane_levels,plane_length_a/),float)
	
						dims_b=dimsizes(data_2_uu_plane)
						plane_length_b=dims_b(1)
						data_2_uu_plane_ilon=new( (/tointeger(4*d_lon)+1,plane_levels,plane_length_b/),float)	
						data_2_ww_plane_ilon=new( (/tointeger(4*d_lon)+1,plane_levels,plane_length_b/),float)	

						lon1_a=lon1_a-d_lon-0.5		;inital longitude	
						lon2_a=lon2_a-d_lon-0.5

						lon1_b=lon1_b-d_lon-0.5	
						lon2_b=lon2_b-d_lon-0.5

						do ilon=0,tointeger(4*d_lon)			;from -5 to +5						
							lon1_a=lon1_a+0.5		
							lon2_a=lon2_a+0.5
							loc1_a=wrf_user_ll_to_ij(a,lon1_a,lat1_a,True)
							loc2_a=wrf_user_ll_to_ij(a,lon2_a,lat2_a,True)
							plane_a=(/loc1_a(0)-1,loc1_a(1)-1,loc2_a(0)-1,loc2_a(1)-1 /)
							;print(loc1_a(0)+" "+loc1_a(1)+" "+loc2_a(0)+" "+loc2_a(1))

							lon1_b=lon1_b+0.5		
							lon2_b=lon2_b+0.5
							loc1_b=wrf_user_ll_to_ij(a,lon1_b,lat1_b,True)
							loc2_b=wrf_user_ll_to_ij(a,lon2_b,lat2_b,True)
							plane_b=(/loc1_b(0)-1,loc1_b(1)-1,loc2_b(0)-1,loc2_b(1)-1 /)
							;print(loc1_b(0)+" "+loc1_b(1)+" "+loc2_b(0)+" "+loc2_b(1))

							print("data1 data2 new lon "+lon1_a+" "+lon1_b)

							data_1_uu_plane_ilon_tmp=wrf_user_intrp3d(data_1_uu,v_type,"v",plane_a,angle(ip),True)	 
							data_1_ww_plane_ilon_tmp=wrf_user_intrp3d(data_1_ww,v_type,"v",plane_a,angle(ip),True)	 
							data_2_uu_plane_ilon_tmp=wrf_user_intrp3d(data_2_uu,v_type,"v",plane_b,angle(ip),True)
							data_2_ww_plane_ilon_tmp=wrf_user_intrp3d(data_2_ww,v_type,"v",plane_b,angle(ip),True)

							dims_a=dimsizes(data_1_uu_plane_ilon_tmp)
							dims_b=dimsizes(data_2_uu_plane_ilon_tmp)
							plane_length_a_new=dims_a(1)
							plane_length_b_new=dims_b(1)

							if(plane_length_a_new.ge.plane_length_a)then
								data_1_uu_plane_ilon(ilon,:,:)=data_1_uu_plane_ilon_tmp(:,0:plane_length_a-1)	
								data_1_ww_plane_ilon(ilon,:,:)=data_1_ww_plane_ilon_tmp(:,0:plane_length_a-1)													
							else
								data_1_uu_plane_ilon(ilon,:,0:plane_length_a_new-1)=data_1_uu_plane_ilon_tmp(:,:)
								data_1_ww_plane_ilon(ilon,:,0:plane_length_a_new-1)=data_1_ww_plane_ilon_tmp(:,:)												
							end if

							if(plane_length_b_new.ge.plane_length_b)then
								data_2_uu_plane_ilon(ilon,:,:)=data_2_uu_plane_ilon_tmp(:,0:plane_length_b-1)
								data_2_ww_plane_ilon(ilon,:,:)=data_2_ww_plane_ilon_tmp(:,0:plane_length_b-1)													
							else
								data_2_uu_plane_ilon(ilon,:,0:plane_length_b_new-1)=data_2_uu_plane_ilon_tmp(:,:)	
								data_2_ww_plane_ilon(ilon,:,0:plane_length_b_new-1)=data_2_ww_plane_ilon_tmp(:,:)												
							end if

							delete(data_1_uu_plane_ilon_tmp)
							delete(data_1_ww_plane_ilon_tmp)
							delete(data_2_uu_plane_ilon_tmp)
							delete(data_2_ww_plane_ilon_tmp)
						end do

						data_1_uu_plane=dim_avg_n(data_1_uu_plane_ilon,0)
						data_1_ww_plane=dim_avg_n(data_1_ww_plane_ilon,0)
						data_2_uu_plane=dim_avg_n(data_2_uu_plane_ilon,0)
						data_2_ww_plane=dim_avg_n(data_2_ww_plane_ilon,0)
						delete(data_1_uu_plane_ilon)
						delete(data_1_ww_plane_ilon)
						delete(data_2_uu_plane_ilon)
						delete(data_2_ww_plane_ilon)

					end if

					if(have_diff)then
						dims_a=dimsizes(data_1_uu_plane)
						dims_b=dimsizes(data_2_uu_plane)
						plane_length_a=dims_a(1)
						plane_length_b=dims_b(1)

						if(plane_length_a.ge.plane_length_b)then
							diff_uu_plane=data_1_uu_plane(:,0:plane_length_b-1)-data_2_uu_plane
							diff_ww_plane=data_1_ww_plane(:,0:plane_length_b-1)-data_2_ww_plane

						else
							diff_uu_plane=data_1_uu_plane-data_2_uu_plane(:,0:plane_length_a-1)
							diff_ww_plane=data_1_ww_plane-data_2_ww_plane(:,0:plane_length_a-1)
						end if
	

					end if

				end if

			end if

			if .not. pivot_cross then	
				;p_plane_a = wrf_user_intrp3d(p1,v_type,"v",plane_a,angle(ip),True)	
				;p_plane_b = wrf_user_intrp3d(p2,v_type,"v",plane_b,angle(ip),True)	
			else 
				;p_plane_a = wrf_user_intrp3d(p1,v_type,"v",plane_a,angle(ip),False)	
				;p_plane_b = wrf_user_intrp3d(p2,v_type,"v",plane_b,angle(ip),False)	
			end if

			;-------------
			;set array for time average, only works for two point plane, and the same plane at all time
			;-----------------------------
			if(it.eq.start_time.and.var_id.eq.0.and.ip.eq.0)
				if(var_name(var_id) .ne. "wind_vector" )then

					dims_a=dimsizes(data_1_plane)
					plane_length_a_time0=dims_a(1)
					plane_levels_time0=dims_a(0)
					dims_b=dimsizes(data_2_plane)
					plane_length_b_time0=dims_b(1)


					if(plane_length_a_time0.ge.plane_length_b_time0)then
						plane_length_diff_time0=plane_length_b_time0
					else
						plane_length_diff_time0=plane_length_a_time0
					end if

				else
					dims_a=dimsizes(data_1_uu_plane)
					plane_length_a_time0=dims_a(1)
					plane_levels_time0=dims_a(0)
					dims_b=dimsizes(data_2_uu_plane)
					plane_length_b_time0=dims_b(1)


					if(plane_length_a_time0.ge.plane_length_b_time0)then
						plane_length_diff_time0=plane_length_b_time0
					else
						plane_length_diff_time0=plane_length_a_time0
					end if
				end if



				if average_time then

					print("plane_length_a_time0 "+plane_length_a_time0)
					print("plane_length_b_time0 "+plane_length_b_time0)
					print("plane_length_diff_time0 "+plane_length_diff_time0)
					print("plane_levels_time0 "+plane_levels_time0)

					data_1_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_a_time0/),float) 
					data_2_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_b_time0/),float)
					diff_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_diff_time0/),float)	

					data_1_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_a_time0/),float) 
					data_2_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_b_time0/),float)
					diff_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_diff_time0/),float)

					data_1_uu_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_a_time0/),float)	
					data_2_uu_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_b_time0/),float)	
					data_1_ww_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_a_time0/),float)	
					data_2_ww_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_b_time0/),float)	
					diff_uu_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_diff_time0/),float)	
					diff_ww_plane_tmp=new( (/ntimes,var_numbers,maxip,plane_levels_time0,plane_length_diff_time0/),float)

					data_1_uu_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_a_time0/),float)	
					data_2_uu_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_b_time0/),float)	
					data_1_ww_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_a_time0/),float)	
					data_2_ww_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_b_time0/),float)	
					diff_uu_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_diff_time0/),float)	
					diff_ww_plane_avgtime=new( (/var_numbers,maxip,plane_levels_time0,plane_length_diff_time0/),float)
				end if

			end if
			;end of setting original array

			if average_time then

				if(var_name(var_id) .ne. "wind_vector" )then
					dims_a=dimsizes(data_1_plane)
					dims_b=dimsizes(data_2_plane)
					plane_length_a_new=dims_a(1)
					plane_levels_new=dims_a(0)
					plane_length_b_new=dims_b(1)

					if(plane_length_a_new.ge.plane_length_b_new)then
						plane_length_diff_new=plane_length_b_new
					else
						plane_length_diff_new=plane_length_a_new
					end if


					print("plane_length_a_new "+plane_length_a_new)
					print("plane_length_b_new "+plane_length_b_new)
					print("plane_length_diff_new "+plane_length_diff_new)
					print("plane_levels_new "+plane_levels_new)

					if(plane_length_a_new.ge.plane_length_a_time0)then

						if(plane_levels_new.ge.plane_levels_time0)then

							data_1_plane_tmp(it,var_id,ip,:,:)=data_1_plane(0:plane_levels_time0-1,0:plane_length_a_time0-1)
						else
							data_1_plane_tmp(it,var_id,ip,0:plane_levesl_new,:)=data_1_plane(:,0:plane_length_a_time0-1)
						end if

					else

						if(plane_levels_new.ge.plane_levels_time0)then
							data_1_plane_tmp(it,var_id,ip,:,0:plane_length_a_new-1)=data_1_plane(0:plane_levels_time0-1,:)
						else
							data_1_plane_tmp(it,var_id,ip,0:plane_levesl_new,0:plane_length_a_new-1)=data_1_plane(:,:)
						end if

					end if

					if(plane_length_b_new.ge.plane_length_b_time0)then

						if(plane_levels_new.ge.plane_levels_time0)then
							data_2_plane_tmp(it,var_id,ip,:,:)=data_2_plane(0:plane_levels_time0-1,0:plane_length_b_time0-1)
						else
							data_2_plane_tmp(it,var_id,ip,0:plane_levesl_new,:)=data_2_plane(:,0:plane_length_b_time0-1)
						end if

					else

						if(plane_levels_new.ge.plane_levels_time0)then
							data_2_plane_tmp(it,var_id,ip,:,0:plane_length_b_new-1)=data_2_plane(0:plane_levels_time0-1,:)
						else
							data_2_plane_tmp(it,var_id,ip,0:plane_levesl_new,0:plane_length_b_new-1)=data_2_plane(:,:)
						end if

					end if

						
				else

					dims_a=dimsizes(data_1_uu_plane)
					dims_b=dimsizes(data_2_uu_plane)
					plane_length_a_new=dims_a(1)
					plane_levels_new=dims_a(0)
					plane_length_b_new=dims_b(1)

					if(plane_length_a_new.ge.plane_length_b_new)then
						plane_length_diff_new=plane_length_b_new
					else
						plane_length_diff_new=plane_length_a_new
					end if


					print("plane_length_a_new "+plane_length_a_new)
					print("plane_length_b_new "+plane_length_b_new)
					print("plane_length_diff_new "+plane_length_diff_new)
					print("plane_levels_new "+plane_levels_new)

					if(plane_length_a_new.ge.plane_length_a_time0)then

						if(plane_levels_new.ge.plane_levels_time0)then
							data_1_uu_plane_tmp(it,var_id,ip,:,:)=data_1_uu_plane(0:plane_levels_time0-1,0:plane_length_a_time0-1)
							data_1_ww_plane_tmp(it,var_id,ip,:,:)=data_1_ww_plane(0:plane_levels_time0-1,0:plane_length_a_time0-1)
						else
							data_1_uu_plane_tmp(it,var_id,ip,0:plane_levesl_new,:)=data_1_uu_plane(:,0:plane_length_a_time0-1)
							data_1_ww_plane_tmp(it,var_id,ip,0:plane_levesl_new,:)=data_1_ww_plane(:,0:plane_length_a_time0-1)
						end if

					else

						if(plane_levels_new.ge.plane_levels_time0)then
							data_1_uu_plane_tmp(it,var_id,ip,:,0:plane_length_a_new-1)=data_1_uu_plane(0:plane_levels_time0-1,:)
							data_1_ww_plane_tmp(it,var_id,ip,:,0:plane_length_a_new-1)=data_1_ww_plane(0:plane_levels_time0-1,:)
						else
							data_1_uu_plane_tmp(it,var_id,ip,0:plane_levesl_new,0:plane_length_a_new-1)=data_1_uu_plane(:,:)
							data_1_ww_plane_tmp(it,var_id,ip,0:plane_levesl_new,0:plane_length_a_new-1)=data_1_ww_plane(:,:)
						end if

					end if

					if(plane_length_b_new.ge.plane_length_b_time0)then

						if(plane_levels_new.ge.plane_levels_time0)then
							data_2_uu_plane_tmp(it,var_id,ip,:,:)=data_2_uu_plane(0:plane_levels_time0-1,0:plane_length_b_time0-1)
							data_2_ww_plane_tmp(it,var_id,ip,:,:)=data_2_ww_plane(0:plane_levels_time0-1,0:plane_length_b_time0-1)
						else
							data_2_uu_plane_tmp(it,var_id,ip,0:plane_levesl_new,:)=data_2_uu_plane(:,0:plane_length_b_time0-1)
							data_2_ww_plane_tmp(it,var_id,ip,0:plane_levesl_new,:)=data_2_ww_plane(:,0:plane_length_b_time0-1)
						end if

					else

						if(plane_levels_new.ge.plane_levels_time0)then
							data_2_uu_plane_tmp(it,var_id,ip,:,0:plane_length_b_new-1)=data_2_uu_plane(0:plane_levels_time0-1,:)
							data_2_ww_plane_tmp(it,var_id,ip,:,0:plane_length_b_new-1)=data_2_ww_plane(0:plane_levels_time0-1,:)
						else
							data_2_uu_plane_tmp(it,var_id,ip,0:plane_levesl_new,0:plane_length_b_new-1)=data_2_uu_plane(:,:)
							data_2_ww_plane_tmp(it,var_id,ip,0:plane_levesl_new,0:plane_length_b_new-1)=data_2_ww_plane(:,:)
						end if

					end if

				end if


				if(it.eq.time_end)then
					if(var_name(var_id) .ne. "wind_vector" )then
						data_1_plane_avgtime(var_id,ip,:,:)=dim_avg_n(data_1_plane_tmp(:,var_id,ip,:,:),0)
						data_2_plane_avgtime(var_id,ip,:,:)=dim_avg_n(data_2_plane_tmp(:,var_id,ip,:,:),0)
						if have_diff then
							if(plane_length_a_time0.ge.plane_length_b_time0)then
								diff_plane_avgtime(var_id,ip,:,:)=data_1_plane_avgtime(var_id,ip,:,0:plane_length_b_time0-1)-data_2_plane_avgtime(var_id,ip,:,:)
							else
								diff_plane_avgtime(var_id,ip,:,:)=data_1_plane_avgtime(var_id,ip,:,:)-data_2_plane_avgtime(var_id,ip,:,0:plane_length_a_time0-1)
							end if
								
						end if
					else
						data_1_uu_plane_avgtime=dim_avg_n(data_1_uu_plane_tmp(:,var_id,ip,:,:),0)
						data_1_ww_plane_avgtime=dim_avg_n(data_1_ww_plane_tmp(:,var_id,ip,:,:),0)
						data_2_uu_plane_avgtime=dim_avg_n(data_2_uu_plane_tmp(:,var_id,ip,:,:),0)
						data_2_ww_plane_avgtime=dim_avg_n(data_2_ww_plane_tmp(:,var_id,ip,:,:),0)

						if have_diff then
							if(plane_length_a_time0.ge.plane_length_b_time0)then
								diff_uu_plane_avgtime(var_id,ip,:,:)=data_1_uu_plane_avgtime(var_id,ip,:,0:plane_length_b_time0-1)-data_2_uu_plane_avgtime(var_id,ip,:,:)
								diff_ww_plane_avgtime(var_id,ip,:,:)=data_1_ww_plane_avgtime(var_id,ip,:,0:plane_length_b_time0-1)-data_2_ww_plane_avgtime(var_id,ip,:,:)
							else
								diff_uu_plane_avgtime(var_id,ip,:,:)=data_1_uu_plane_avgtime(var_id,ip,:,:)-data_2_uu_plane_avgtime(var_id,ip,:,0:plane_length_a_time0-1)
								diff_ww_plane_avgtime(var_id,ip,:,:)=data_1_ww_plane_avgtime(var_id,ip,:,:)-data_2_ww_plane_avgtime(var_id,ip,:,0:plane_length_a_time0-1)
							end if
						end if
					end if

				end if

			end if

			;============
			; smooth the data  # !! must do after interpolation. 
			;============

			if (smooth(var_id).and. (var_name(var_id) .ne. "wind_vector") )then
				wrf_smooth_2d( data_1_plane, 3 )		;???##### smooth factor
				wrf_smooth_2d( data_2_plane, 3 )

	      		if(have_diff)then
					wrf_smooth_2d( diff_plane, 3 )	
				end if	
			end if
    

			;===========================================
			; Vertical Axis , Find the index where  your height is - only need to do this once, vertical axis is always the same 
			;============================================


       		if( vertical_type .ne. 1)then	;(1) pressure coordinate
		      zmin = 1000.0
			  zmax=zmax0
			  p_tmp= fspan(1000.0,0.0,101)
		      zspan=closest_val(zmax,p_tmp)

		      nz = floattoint((zmin-zmax)/50+1) ;nz means how many grid points.50 is the interval 50hPa. 
												;corresponding to tickmark position: fspan(0,zspan,nz) , and tickmark value: fspan(zmin,zmax,nz) 
	     	else							;(2) height coordinate
		      zmin = 0.
		    ; zmax = max(z)/1000.			; use the heighest level
	          zmax=zmax0					;
		      nz   = floattoint(zmax + 1)	
			  if .not. pivot_cross then
		      	zz = wrf_user_intrp3d(z,z,"v",plane_a,0,True)		;zz become two dimensional
			  else
				zz = wrf_user_intrp3d(z,z,"v",plane_a,0,False)
			  end if	
		      tem = ind(zz(:,0) .gt. zmax*1000. )	;Returns the indices where the input is True. all the indices where the height is higher than zmax
		      zmax_pos = tem(0) - 1
		      if ( abs(zz(zmax_pos,0)-zmax*1000.) .lt. abs(zz(zmax_pos+1,0)-zmax*1000.) ) then  ;determine which height in zz is closer to zmax you specify
		        zspan = tem(0) - 1
		      else
		        zspan = tem(0)
		      end if
		      delete(zz)
		      delete(tem)
	      	end if
			
			print("zspan  "+zspan)
								

			
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

			;y axis
			if (vertical_type .eq.1)then   
				opts@tiYAxisString           = "Height (km)"
			else
				opts@tiYAxisString           = "Pressure (hPa)"		
			end if

			opts@tiYAxisFontHeightF      = 0.020  		;Sets the font height in NDC coordinates to use for the Y-Axis title. 
			opts@tmYROn                  = False		;Setting True turns on the right tick marks
			opts@tmYLMajorLengthF        = 0.02			;Sets the length of the Y-Axis left major tick marks in NDC coordinates.
			opts@tmYLLabelFontHeightF    = 0.015		;Sets the height of the Y-Axis left labels in NDC coordinates.
			opts@tmYLMode                = "Explicit"   ;need to set @tmYLValues   and @tmYLLabels
			opts@tmYLValues              = fspan(0,zspan,nz)    ; Create tick marks, this is the position indice for tickmark. 
																;the same range for variable. tc(0:zspan)
			opts@tmYLLabels              = sprintf("%.0f",fspan(zmin,zmax,nz))  ; Create labels

			;x axis
			opts@tiXAxisFontHeightF      = 0.020
			opts@tmXTOn                  = False		;Setting True turns on top tick marks
			opts@tmXBMajorLengthF        = 0.02			;Sets the length of the X-Axis bottom major tick marks in NDC coordinates. 
			opts@tmXBLabelFontHeightF    = 0.015		;Sets the font height in NDC coordinates for the bottom X Axis labels. 
			opts@tmXBMode                = "Explicit"	;need to set tmXBValues and tmXBLabels after that
		
			opts@tmXBLabelStride		=10

			;================================
			; X axis;  interpolate coordinate variable to the plane_a,plane_b
			;================================

				;--------------
				; (1) plane_a
				;-------------
			if .not. pivot_cross then

				if((lat1_array_a(it,ip).ne.lat2_array_a(it,ip)).and. (lon1_array_a(it,ip).ne.lon2_array_a(it,ip)))then	
		    		X_plane_a = wrf_user_intrp2d(xlat,plane_a_0,0,True) ;xlat is 2d coordinate variable, X_plane_a becomes 1-d variable
					X_desc_a = "Latitude"	;???##### some tricks here, plot twice, first use latitude, then longitude, then combine the two axis 
					;X_plane_a = wrf_user_intrp2d(xlon,plane_a,angle(ip),opts)					
					;X_desc_a = "Longitude"
				else
					if(lat1_array_a(it,ip).eq.lat2_array_a(it,ip))then
						X_plane_a = wrf_user_intrp2d(xlon,plane_a_0,0,True)
						X_desc_a = "Longitude"
					end if

					if(lon1_array_a(it,ip).eq.lon2_array_a(it,ip))then
						X_plane_a = wrf_user_intrp2d(xlat,plane_a_0,0,True)
						X_desc_a = "Latitude"
					end if
		  
		        end if

			    ; X-axis lables
				dimsX_a = dimsizes(X_plane_a)

				xxmin_a  = X_plane_a(0)
				xxmax_a  = X_plane_a(dimsX_a-1)
				xleft_a=0
				xright_a = dimsX_a-1
				;nx_a    = floattoint( abs(xmax_a-xmin_a)/2 + 1)  ; nx means how many grid points,is not the interval, fspan(0,xspan,nx)   ,fspan(xmin,xmax,nx)
				nx_a=xright_a-xleft_a+1

				if (average_time .and.it.eq.start_time)then
					xright_a_time0=xright_a
				end if

			else ;pivot

				if(angle(ip).eq.0)then	
		    		X_plane_a = wrf_user_intrp2d(xlat,plane_a,angle(ip),False) ;xlat is 2d coordinate variable, X_plane_a becomes 1-d variable
					X_desc_a = "Latitude"	
					xxmin_a=clat_a(it)-d_center		;only plot +- 6 degree range
					xxmax_a=clat_a(it)+d_center
					xleft_a=closest_val(xxmin_a,X_plane_a)		;get the array index for the range
					xright_a=closest_val(xxmax_a,X_plane_a)
				end if

				if(angle(ip).eq.45.0 .or.angle(ip).eq.-45.)then	
		    		X_plane_a = wrf_user_intrp2d(xlat,plane_a,angle(ip),False) ;xlat is 2d coordinate variable, X_plane_a becomes 1-d variable
					X_desc_a = "Latitude"	;???##### some tricks here, plot twice, first use latitude, then longitude, then combine the two axis 
					;X_plane_a = wrf_user_intrp2d(xlon,plane_a,angle(ip),opts)					
					;X_desc_a = "Longitude"
					xxmin_a=clat_a(it)-d_center
					xxmax_a=clat_a(it)+d_center
					xleft_a=closest_val(xxmin_a,X_plane_a)
					xright_a=closest_val(xxmax_a,X_plane_a)
				end if

				if(angle(ip).eq.90.0)then				
					X_plane_a = wrf_user_intrp2d(xlon,plane_a,angle(ip),False)
					X_desc_a = "Longitude"

					xxmin_a=clon_a(it)-d_center
					xxmax_a=clon_a(it)+d_center
					xleft_a=closest_val(xxmin_a,X_plane_a)
					xright_a=closest_val(xxmax_a,X_plane_a)
				end if

				print("xxmin_a, xxmax, xleft, xright  "+xxmin_a+"  "+xxmax_a+"  "+xleft_a+"  "+xright_a)

				if(xleft_a.gt.xright_a)then
					tem=xleft_a
					xleft_a=xright_a
					xright_a=tem
					delete(tem)
					tem=xxmin_a
					xxmin_a=xxmax_a
					xxmax_a=tem
					delete(tem)
				end if

				print("xxmin_a, xxmax, xleft, xright  "+xxmin_a+"  "+xxmax_a+"  "+xleft_a+"  "+xright_a)

				nx_a=xright_a-xleft_a+1
				
			end if

				;------------------
				; (2) plane_b
				;-----------------
			if .not. pivot_cross then

				if((lat1_array_b(it,ip).ne.lat2_array_b(it,ip)).and. (lon1_array_b(it,ip).ne.lon2_array_b(it,ip)))then	
		    		X_plane_b = wrf_user_intrp2d(xlat,plane_b_0,0,True) ;xlat is 2d coordinate variable, X_plane_b becomes 1-d variable
					X_desc_b = "Latitude"	;???##### some tricks here, plot twice, first use latitude, then longitude, then combine the two axis 
					;X_plane_b = wrf_user_intrp2d(xlon,plane_b,angle(ip),opts)					
					;X_desc_b = "Longitude"
				else
					if(lat1_array_b(it,ip).eq.lat2_array_b(it,ip))then
						X_plane_b = wrf_user_intrp2d(xlon,plane_b_0,0,True)
						X_desc_b = "Longitude"
					end if

					if(lon1_array_b(it,ip).eq.lon2_array_b(it,ip))then
						X_plane_b = wrf_user_intrp2d(xlat,plane_b_0,0,True)
						X_desc_b = "Latitude"
					end if
		  
		        end if

			    ; X-axis lables
				dimsX_b = dimsizes(X_plane_b)

				xxmin_b  = X_plane_b(0)
				xxmax_b  = X_plane_b(dimsX_b-1)
				xleft_b=0
				xright_b = dimsX_b-1
				;nx_b    = floattoint( abs(xmax_b-xmin_b)/2 + 1)  ; nx means how many grid points,is not the interval, fspan(0,xspan,nx)   ,fspan(xmin,xmax,nx)
				nx_b=xright_b-xleft_b+1

				if (average_time .and.it.eq.start_time)then
					xright_b_time0=xright_b
				end if

			else ;pivot

				if(angle(ip).eq.0)then	
		    		X_plane_b = wrf_user_intrp2d(xlat,plane_b,angle(ip),False) ;xlat is 2d coordinate variable, X_plane_b becomes 1-d variable
					X_desc_b = "Latitude"	

					xxmin_b=clat_b(it)-d_center		;only plot +- 6 degree range
					xxmax_b=clat_b(it)+d_center
					xleft_b=closest_val(xxmin_b,X_plane_b)		;get the array index for the range
					xright_b=closest_val(xxmax_b,X_plane_b)
				end if

				if(angle(ip).eq.45.0 .or.angle(ip).eq.-45.)then	
		    		X_plane_b = wrf_user_intrp2d(xlat,plane_b,angle(ip),False) ;xlat is 2d coordinate variable, X_plane_b becomes 1-d variable
					X_desc_b = "Latitude"	;???##### some tricks here, plot twice, first use latitude, then longitude, then combine the two axis 
					;X_plane_b = wrf_user_intrp2d(xlon,plane_b,angle(ip),opts)					
					;X_desc_b = "Longitude"
					xxmin_b=clat_b(it)-d_center
					xxmax_b=clat_b(it)+d_center
					xleft_b=closest_val(xxmin_b,X_plane_b)
					xright_b=closest_val(xxmax_b,X_plane_b)
				end if

				if(angle(ip).eq.90.0)then				
					X_plane_b = wrf_user_intrp2d(xlon,plane_b,angle(ip),False)
					X_desc_b = "Longitude"

					xxmin_b=clon_b(it)-d_center
					xxmax_b=clon_b(it)+d_center
					xleft_b=closest_val(xxmin_b,X_plane_b)
					xright_b=closest_val(xxmax_b,X_plane_b)
				end if

				print("xxmin_b, xxmax, xleft, xright  "+xxmin_b+"  "+xxmax_b+"  "+xleft_b+"  "+xright_b)

				if(xleft_b.gt.xright_b)then
					tem=xleft_b
					xleft_b=xright_b
					xright_b=tem
					delete(tem)
					tem=xxmin_b
					xxmin_b=xxmax_b
					xxmax_b=tem
					delete(tem)
				end if

				print("xxmin_b, xxmax, xleft, xright  "+xxmin_b+"  "+xxmax_b+"  "+xleft_b+"  "+xright_b)
				nx_b=xright_b-xleft_b+1
				
			end if

	
			
			;==============
			;set different range for different variables   		;????##########, copy from azimuth.ncl
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
				opts@cnMinLevelValF       = -24.
				opts@cnMaxLevelValF       = 24.
				opts@cnLevelSpacingF      = 3.
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -8.
				opts_diff@cnMaxLevelValF       = 8.
				opts_diff@cnLevelSpacingF      = 1.
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
				opts@cnMaxLevelValF       = 30.0
				opts@cnLevelSpacingF      = 2.0
				opts_diff=opts	
				;opts_diff@gsnContourPosLineDashPattern  =0.
				;opts_diff@gsnContourNegLineDashPattern  =4.
				;opts_diff@gsnContourZeroLineThicknessF =1.4
				opts_diff@cnMinLevelValF       = -4.0
				opts_diff@cnMaxLevelValF       = 4.0
				opts_diff@cnLevelSpacingF      = 0.5
			end if


			if (var_name(var_id).eq."H_DIABATIC".or.var_name(var_id).eq."RTHCUTEN".or.var_name(var_id).eq."RTHRATEN".or.var_name(var_id).eq."RTHBLTEN".or.var_name(var_id).eq."total_tendency".or.var_name(var_id).eq."RTHRATSW".or.var_name(var_id).eq."RTHRATLW".or.var_name(var_id).eq."RTHFTEN") then
				opts@cnMinLevelValF       = -1.2; coarse: -1.2   nest:-14
				opts@cnMaxLevelValF       = 1.0; coarse:1.0   nest:14
				opts@cnLevelSpacingF      = 0.1; coarse:0.1   nest:2
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.08; coarse:-0.08   nest:-10
				opts_diff@cnMaxLevelValF       = 0.08; coarse:0.08    nest:10
				opts_diff@cnLevelSpacingF      = 0.01; coarse:0.01    nest:2
				if(var_res(var_id).eq."cn")then
					opts@cnMinLevelValF       = -1.2; coarse:-1.2    nest:-5
					opts@cnMaxLevelValF       = 1.0; coarse:1.0   nest:14
					opts@cnLevelSpacingF      = 0.1; coarse:0.1   nest:0.5
					opts@cnLineLabelInterval =1
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -0.08; coarse:-0.08   nest:-10
					opts_diff@cnMaxLevelValF       = 0.08; coarse:0.08    nest:10
					opts_diff@cnLevelSpacingF      = 0.01; coarse:0.01    nest:0.5
				end if
			end if


			if(var_name(var_id) .eq. "rh")then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 100.
				opts@cnLevelSpacingF      = 5.
				opts@cnLineColor = (/8/)
				opts_diff=opts
				opts_diff@cnLineColor = (/18/)	
				opts_diff@cnMinLevelValF       = -16.0
				opts_diff@cnMaxLevelValF       = 16.0
				opts_diff@cnLevelSpacingF      = 2.
			end if 

			if(var_name(var_id) .eq. "eth"  )then
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

			if(var_name(var_id) .eq. "th" )then
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
					opts_diff@cnMinLevelValF       = -1.6
					opts_diff@cnMaxLevelValF       = 1.6
					opts_diff@cnLevelSpacingF      = 0.2
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

					opts@cnLineColor=(/18/)
					opts@cnMinLevelValF       = -20. 
					opts@cnMaxLevelValF       = 50.
					opts@cnLevelSpacingF      =5.  
					opts_diff=opts  
					opts_diff@gsnContourPosLineDashPattern  =0
					opts_diff@gsnContourNegLineDashPattern  =4
					opts_diff@gsnContourZeroLineThicknessF =2.0
					opts_diff@cnMinLevelValF       = -1.6 
					opts_diff@cnMaxLevelValF       = 1.6
					opts_diff@cnLevelSpacingF      = 0.2
			
			end if

			if(var_name(var_id) .eq. "T_deviation")then
				opts@cnMinLevelValF       = -4.
				opts@cnMaxLevelValF       = 4.0
				opts@cnLevelSpacingF      = 0.5
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -1.5
				opts_diff@cnMaxLevelValF       = 1.5
				opts_diff@cnLevelSpacingF      = 0.3
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
				opts@cnMaxLevelValF       = 25.;0.
				opts@cnLevelSpacingF      = 1.5; 0.002
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -3.0 ;-0.006 
				opts_diff@cnMaxLevelValF       = 3.0 ;0.006
				opts_diff@cnLevelSpacingF      = 0.5 ; 0.001 
			end if 


			if(var_name(var_id) .eq. "QCLOUD")then
				opts@cnMinLevelValF       = 0.;0.0015
				opts@cnMaxLevelValF       = 0.15;0.
				opts@cnLevelSpacingF      = 0.015;0.0001


					;if(it.eq.start_time)then
					  ;  q_max=max(data_1)
					  ;  q_interval=q_max/10.
					;end if

				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.18;-5.5e-4
				opts_diff@cnMaxLevelValF       = 0.18;5.e-4
				opts_diff@cnLevelSpacingF      = 0.03; 5e-5
				;opts@cnMinLevelValF       = 0.
				;opts@cnMaxLevelValF       = q_max
				;opts@cnLevelSpacingF      = q_interval
				;opts_diff=opts
				;opts_diff@cnMinLevelValF       = -q_max/2
				;opts_diff@cnMaxLevelValF       =q_max/2
				;opts_diff@cnLevelSpacingF      =  q_interval

			end if 

			if( var_name(var_id) .eq. "QRAIN" )then
				opts@cnMinLevelValF       =  0.
				opts@cnMaxLevelValF       = 1.5
				opts@cnLevelSpacingF      = 0.1
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.9
				opts_diff@cnMaxLevelValF       =0.9
				opts_diff@cnLevelSpacingF      =  0.15
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
				opts_diff@cnLevelSpacingF      =  0.03;0.01
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
				opts@cnMaxLevelValF       = 50.; 20;55.;0.
				opts@cnLevelSpacingF      = 2.; 2;5.;5e6
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -50.; -18;-50;-5.5e7
				opts_diff@cnMaxLevelValF       = 50.; 18;50;5e7
				opts_diff@cnLevelSpacingF      = 10.;3;10 ;5e6
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
				opts@cnMaxLevelValF       = 30.
				opts@cnLevelSpacingF      = 2.
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -4.0
				opts_diff@cnMaxLevelValF       = 4.0
				opts_diff@cnLevelSpacingF      = 0.5  
			end if 

			if(var_name(var_id) .eq. "ua" .or.var_name(var_id) .eq. "va")then
					opts@cnMinLevelValF       = -36.0
					opts@cnMaxLevelValF       = 10.0
					opts@cnLevelSpacingF      = 2.0
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -5.0
					opts_diff@cnMaxLevelValF       = 5.0
					opts_diff@cnLevelSpacingF      = 0.5
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
					opts@cnMinLevelValF       = -0.4  ;-1.5
					opts@cnMaxLevelValF       = 0.4	;1.5
					opts@cnLevelSpacingF      = 0.05 ;0.1
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -0.4;-0.2	;-1.0
					opts_diff@cnMaxLevelValF       = 0.4;0.2	;1.0
					opts_diff@cnLevelSpacingF      = 0.05;0.025	;0.1
				end if
			end if

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


            ;=======================
            ; set  X axis for data_1 and data_2
            ;========================
				
	        opts_a=opts
			opts_a@tiXAxisString           = X_desc_a    ; string is longtitude or latitude
			opts_a@tmXBValues              = fspan(xleft_a,xright_a,nx_a)                    ; Create tick marks
			opts_a@tmXBLabels              = sprintf("%.1f",fspan(xxmin_a,xxmax_a,nx_a))  ; Create labels
	        opts_b=opts
			opts_b@tiXAxisString           = X_desc_b    ; string is longtitude or latitude
			opts_b@tmXBValues              = fspan(xleft_b,xright_b,nx_b)                   
			opts_b@tmXBLabels              = sprintf("%.1f",fspan(xxmin_b,xxmax_b,nx_b)) 

			;----------------------
			;begin the plot
			;------------------------

			if(var_name(var_id) .ne. "wind_vector" )then 
				contour_data_1(var_id,ip) = wrf_contour(a,wks,data_1_plane(0:zspan,xleft_a:xright_a),opts_a)	
				contour_data_2(var_id,ip) = wrf_contour(a,wks,data_2_plane(0:zspan,xleft_b:xright_b),opts_b)

				if average_time then
					if(it.eq.time_end)then	;average

				   	 	contour_data_1_avgtime(var_id,ip) = wrf_contour(a,wks,data_1_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),opts_a)	
						contour_data_2_avgtime(var_id,ip) = wrf_contour(b,wks,data_2_plane_avgtime(var_id,ip,0:zspan,xleft_b:xright_b_time0),opts_b)	
					end if	
				end if	
							
			else

				if .not. pivot_cross then

					if(var_res(var_id).eq."vc")then
						contour_data_1(var_id,ip)= wrf_vector(a,wks,data_1_uu_plane(0:zspan,xleft_a:xright_a),data_1_ww_plane(0:zspan,xleft_a:xright_a),opts_a)
						contour_data_2(var_id,ip)= wrf_vector(a,wks,data_2_uu_plane(0:zspan,xleft_b:xright_b),data_2_ww_plane(0:zspan,xleft_b:xright_b),opts_b)
						if average_time then
							if(it.eq.time_end)then	;average
						 		contour_data_1_avgtime(var_id,ip)= wrf_vector(a,wks,data_1_uu_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),\
																		 data_1_ww_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),opts_a)	
								contour_data_2_avgtime(var_id,ip)= wrf_vector(b,wks,data_2_uu_plane_avgtime(var_id,ip,0:zspan,xleft_b:xright_b_time0),\		
																		 data_2_ww_plane_avgtime(var_id,ip,0:zspan,xleft_b:xright_b_time0),opts_b)
							end if	
						end if	
					end if

					if(var_res(var_id).eq."str")then
						contour_data_1(var_id,ip)= gsn_csm_streamline(wks,data_1_uu_plane(0:zspan,xleft_a:xright_a),\
																		data_1_ww_plane(0:zspan,xleft_a:xright_a),opts_a)
						contour_data_2(var_id,ip)= gsn_csm_streamline(wks,data_2_uu_plane(0:zspan,xleft_b:xright_b),\
																		data_2_ww_plane(0:zspan,xleft_b:xright_b),opts_b)
						if average_time then
							if(it.eq.time_end)then	;average
						 		contour_data_1_avgtime(var_id,ip)= gsn_csm_streamline(wks,data_1_uu_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),\
																		 data_1_ww_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),opts_a)	
								contour_data_2_avgtime(var_id,ip)= gsn_csm_streamline(wks,data_2_uu_plane_avgtime(var_id,ip,0:zspan,xleft_b:xright_b_time0),\		
																		 data_2_ww_plane_avgtime(var_id,ip,0:zspan,xleft_b:xright_b_time0),opts_b)
							end if	
						end if
					end if

				end if

			end if

			if(have_diff)then
	            opts_diff@tmXBValues              = fspan(xleft_a,xright_a,nx_a)                   
			    opts_diff@tmXBLabels              = sprintf("%.1f",fspan(xxmin_a,xxmax_a,nx_a))  

				if(var_name(var_id) .ne. "wind_vector" )then				
					contour_diff(var_id,ip) = wrf_contour(a,wks,diff_plane(0:zspan,xleft_a:xright_a),opts_diff)	

					if average_time then
						if(it.eq.time_end)then	;average

							opts_diff@cnMinLevelValF       = 0.2*opts_diff@cnMinLevelValF  
							opts_diff@cnMaxLevelValF       = 0.2*opts_diff@cnMaxLevelValF 
							opts_diff@cnLevelSpacingF      = 0.2*opts_diff@cnLevelSpacingF
							contour_diff_avgtime(var_id,ip)= wrf_contour(a,wks,diff_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),opts_diff)	
						end if
					end if

				else
					if .not. pivot_cross then

						if(var_res(var_id).eq."vc")then
							contour_diff(var_id,ip)= wrf_vector(a,wks,diff_uu_plane(0:zspan,xleft_a:xright_a),diff_ww_plane(0:zspan,xleft_a:xright_a),opts_diff)

							if average_time then
								if(it.eq.time_end)then	;average
									contour_diff_avgtime(var_id,ip)= wrf_vector(b,wks,diff_uu_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),\
																			 diff_ww_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),opts_diff)	
								end if
							end if
						end if

						if(var_res(var_id).eq."str")then
							contour_diff(var_id,ip)= gsn_csm_streamline(wks,diff_uu_plane(0:zspan,xleft_a:xright_a),\
																		diff_ww_plane(0:zspan,xleft_a:xright_a),opts_diff)

							if average_time then
								if(it.eq.time_end)then	;average
									contour_diff_avgtime(var_id,ip)= gsn_csm_streamline(wks,diff_uu_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),\
																			 diff_ww_plane_avgtime(var_id,ip,0:zspan,xleft_a:xright_a_time0),opts_diff)	
								end if
							end if
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
				plot1_overlay1(ip)=contour_data_1(0,ip)
				plot2_overlay1(ip)=contour_data_2(0,ip)
				if average_time then
					if(it.eq.time_end)then	;average
						plot1_overlay1_avgtime(ip)=contour_data_1_avgtime(0,ip)
						plot2_overlay1_avgtime(ip)=contour_data_2_avgtime(0,ip)
					end if
				end if
			end if

			if(num_overlay .eq. 3)then				
			 	plot1_overlay2(ip)=	contour_data_1(1,ip);the 2nd variable give to plot1_overlay2(ip)
			 	plot2_overlay2(ip)=	contour_data_2(1,ip)
				if average_time then
					if(it.eq.time_end)then	;average
				 		plot1_overlay2_avgtime(ip)=	contour_data_1_avgtime(1,ip);the 2nd variable give to plot1_overlay2(angle_id)
				 		plot2_overlay2_avgtime(ip)=	contour_data_2_avgtime(1,ip)
					end if
				end if

			end if				


			if(isoverlay(var_id) .and.(num_overlay .eq. total_num_overlay) )then; only the last variable will be 
;combined to previous overlay variables and output, for examplem if isoverlay=(/True,True,True/) , plot_1_3d(it,0,level) and plot_1_3d(it,1,level) are missing value, only output plot_1_3d(it,2,level)
				last_overlay_id=var_id	; record for the panel plot				
				if( num_overlay .eq. 2 )then
		   			overlay(contour_data_1(var_id,ip),plot1_overlay1(ip))   
					plot_1(var_id,ip) = contour_data_1(var_id,ip)
		   			overlay(contour_data_2(var_id,ip),plot2_overlay1(ip))	
					plot_2(var_id,ip) = contour_data_2(var_id,ip)
					if average_time then
						if(it.eq.time_end)then	;average
				   			overlay(contour_data_1_avgtime(var_id,ip),plot1_overlay1_avgtime(ip))   
							plot_1_avgtime(var_id,ip) = contour_data_1_avgtime(var_id,ip)
				   			overlay(contour_data_2_avgtime(var_id,ip),plot2_overlay1_avgtime(ip))	
							plot_2_avgtime(var_id,ip) = contour_data_2_avgtime(var_id,ip)
						end if
					end if
				end if

			  	if( num_overlay .eq. 3 )then
		   			overlay(contour_data_1(var_id,ip),plot1_overlay1(ip))   
		   			overlay(contour_data_1(var_id,ip),plot1_overlay2(ip))   
					plot_1(var_id,ip) = contour_data_1(var_id,ip)
		   			overlay(contour_data_2(var_id,ip),plot2_overlay1(ip))	
		   			overlay(contour_data_2(var_id,ip),plot2_overlay2(ip))	
					plot_2(var_id,ip) = contour_data_2(var_id,ip)
					if average_time then
						if(it.eq.time_end)then	;average
				   			overlay(contour_data_1_avgtime(var_id,ip),plot1_overlay1_avgtime(ip))   
				   			overlay(contour_data_1_avgtime(var_id,ip),plot1_overlay2_avgtime(ip))   
							plot_1_avgtime(var_id,ip) = contour_data_1_avgtime(var_id,ip)
				   			overlay(contour_data_2_avgtime(var_id,ip),plot2_overlay1_avgtime(ip))	
				   			overlay(contour_data_2_avgtime(var_id,ip),plot2_overlay2_avgtime(ip))	
							plot_2_avgtime(var_id,ip) = contour_data_2_avgtime(var_id,ip)
						end if
					end if


			  	end if

			else	; this is the situation when overlay =false, ;if only one variable,isoverlay is false as well	

				if(.not.isoverlay(var_id) )then
					plot_1(var_id,ip) = contour_data_1(var_id,ip)
					plot_2(var_id,ip) = contour_data_2(var_id,ip)
					if average_time then
						if(it.eq.time_end)then	;average
							plot_1_avgtime(var_id,ip) = contour_data_1_avgtime(var_id,ip)
							plot_2_avgtime(var_id,ip) = contour_data_2_avgtime(var_id,ip)
						end if
					end if
				end if
			end if

			;---------------------
			; for the difference
			;----------------------
			if(have_diff)then

				if(num_overlay_diff .eq. 2)then
					plot_diff_overlay1(ip)=contour_diff(0,ip) 	
					if average_time then
						if(it.eq.time_end)then	;average
							plot_diff_overlay1_avgtime(ip)=contour_diff_avgtime(0,ip) 
						end if	
					end if			
				end if

				if(num_overlay_diff .eq. 3)then
					plot_diff_overlay2(ip)=contour_diff(1,ip) 	
					if average_time then
						if(it.eq.time_end)then	;average
							plot_diff_overlay2_avgtime(ip)=contour_diff_avgtime(1,ip) 	
						end if
					end if		
				end if

				if(isoverlay_diff(var_id) .and.  (num_overlay_diff .eq. total_num_overlay_diff))then	
					if( num_overlay_diff .eq. 2 )then
						overlay(contour_diff(var_id,ip),plot_diff_overlay1(ip)) 
						plot_diff(var_id,ip) =   contour_diff(var_id,ip)
						if average_time then
							if(it.eq.time_end)then	;average
								overlay(contour_diff_avgtime(var_id,ip),plot_diff_overlay1_avgtime(ip)) 
								plot_diff_avgtime(var_id,ip) =   contour_diff_avgtime(var_id,ip)
							end if
						end if
					end if
					if( num_overlay_diff .eq. 3)then
						overlay(contour_diff(var_id,ip),plot_diff_overlay1(ip)) 
						overlay(contour_diff(var_id,ip),plot_diff_overlay2(ip)) 
						plot_diff(var_id,ip) =   contour_diff(var_id,ip)
						if average_time then
							if(it.eq.time_end)then	;average
								overlay(contour_diff_avgtime(var_id,ip),plot_diff_overlay1_avgtime(ip)) 
								overlay(contour_diff_avgtime(var_id,ip),plot_diff_overlay2_avgtime(ip)) 
								plot_diff_avgtime(var_id,ip) =   contour_diff_avgtime(var_id,ip)
							end if
						end if
					end if

				else		
					if(.not.isoverlay_diff(var_id) )then
						plot_diff(var_id,ip) = contour_diff(var_id,ip)
					end if
					if average_time then
						if(it.eq.time_end)then ;average
							plot_diff_avgtime(var_id,ip) = contour_diff_avgtime(var_id,ip)
						end if
					end if
				end if												

			end if

			;=================
			;pressure
			;=================

			opts_p = opts_a
			opts_p@cnInfoLabelOrthogonalPosF = 0.00
			; opts_p@ContourParameters  = (/1. /)
			;opts_p@cnLineColor="Blue"
			opts_p@cnInfoLabelOn= False  
			;contour_p=wrf_contour(a,wks,p_plane_a(0:zspan,xleft_a:xright_a),opts_p)


			;------------
			; add the line to slp
			;----------------
			if .not.pivot_cross then
				lat_plane_a = wrf_user_intrp2d(xlat,plane_a_0,angle(ip),True)
				lon_plane_a = wrf_user_intrp2d(xlon,plane_a_0,angle(ip),True)
				lat_plane_b = wrf_user_intrp2d(xlat,plane_b_0,angle(ip),True)
				lon_plane_b = wrf_user_intrp2d(xlon,plane_b_0,angle(ip),True)
			else
				lat_plane_a = wrf_user_intrp2d(xlat,plane_a,angle(ip),False)
				lon_plane_a = wrf_user_intrp2d(xlon,plane_a,angle(ip),False)
				lat_plane_b = wrf_user_intrp2d(xlat,plane_b,angle(ip),False)
				lon_plane_b = wrf_user_intrp2d(xlon,plane_b,angle(ip),False)
			end if

			lnres = True
			lnres@gsLineThicknessF = 3.0
			lnres@gsLineColor = "Blue"

			if .not. pivot_cross then

				end_point_a=dimsX_a-1
				end_point_b=dimsX_b-1
				plot_slp_1_line(ip)=gsn_add_polyline(wks,plot_slp_1 ,(/lon_plane_a(0),lon_plane_a(end_point_a)/),\
																(/lat_plane_a(0),lat_plane_a(end_point_a)/),lnres)
				plot_slp_2_line(ip)=gsn_add_polyline(wks,plot_slp_2 ,(/lon_plane_b(0),lon_plane_b(end_point_b)/),\
																(/lat_plane_b(0),lat_plane_b(end_point_b)/),lnres)
			else
				
				plot_slp_1_line(ip)=gsn_add_polyline(wks,plot_slp_1 ,(/clon_a(it)-d_center,clon_a(it)+d_center/),\
																(/clat_a(it)-d_center,clat_a(it)+d_center/),lnres)
				plot_slp_2_line(ip)=gsn_add_polyline(wks,plot_slp_2 ,(/clon_b(it)-d_center,clon_b(it)+d_center/),\
																(/clat_b(it)-d_center,clat_b(it)+d_center/),lnres)		
			end if
			delete(lon_plane_a)
			delete(lat_plane_a)
			delete(lon_plane_b)
			delete(lat_plane_b)



			;-----------
			;add the dot for the trajectory
			;----------------
			if(add_dot)then
				dotres = True
				dotres@gsMarkerColor = "Black"
				dotres@gsMarkerIndex = 16
				dotres@gsMarkerSizeF = 0.02
				
				if .not. pivot_cross then
					loc_a=wrf_user_ll_to_ij(a,lon_dot_a(it,ip),lat_dot_a(it,ip),True)
					loc_b=wrf_user_ll_to_ij(b,lon_dot_b(it,ip),lat_dot_b(it,ip),True)
				else
					loc_a=wrf_user_ll_to_ij(a,clon_a(it),clat_a(it),True)
					loc_b=wrf_user_ll_to_ij(b,clon_b(it),clat_b(it),True)
				end if					

				print("dot lon_a "+loc_a(0))
				print("dot lat_a "+loc_a(1))
				print("dot lon_b "+loc_b(0))
				print("dot lat_b "+loc_b(1))

				plot_slp_1_dot(ip)=gsn_add_polymarker(wks,plot_slp_1,loc_a(0),loc_a(1),dotres)
				plot_slp_2_dot(ip)=gsn_add_polymarker(wks,plot_slp_2,loc_b(0),loc_b(1),dotres)

			end if

		

			;======================
			; Delete options and fields, so we don't have carry over
			;==============================


			delete(opts_a)
			delete(opts_b)
			delete(opts_diff)
			delete(plane_a)
			delete(plane_b)
			;delete(p_plane_a)
			;delete(p_plane_b)

			delete(X_plane_a)
			delete(X_plane_b)



			if(var_name(var_id) .ne. "wind_vector" )then	

				delete(data_1_plane)
				delete(data_2_plane)
				if(have_diff)then
					delete(diff_plane)
				end if
			else
				if .not. pivot_cross then
					delete(data_1_uu_plane)
					delete(data_1_ww_plane)
					delete(data_2_uu_plane)
					delete(data_2_ww_plane)

					if(have_diff)then
						delete(diff_uu_plane)
						delete(diff_ww_plane)
					end if
				end if
			end if

		end do         ; END OF cross sections  for the same variable at the same time

		delete(opts)
		if(var_name(var_id) .ne. "wind_vector" )then	
			delete(data_1)
			delete(data_2)	
		
		else
			if .not. pivot_cross then
			
				delete(data_1_uu)
				delete(data_1_ww)
				delete(data_2_uu)
				delete(data_2_ww)
			
			end if
		end if

	end do    ; END OF VARIABLE LOOP


	;========================
	;begin the panel plot_1 
	;========================  
	   
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


	resP@gsnPanelMainString = time_name(it) 

	do var_id=0,var_numbers-1,1		
		if(	.not. isoverlay(var_id).or.(isoverlay(var_id).and.var_id.eq.last_overlay_id) )then
			if .not.pivot_cross then
				do ip=0,maxip-1
				    if(have_diff)then
				        gsn_panel(wks,(/plot_1(var_id,ip),plot_2(var_id,ip),plot_diff(var_id,ip),plot_slp_1,plot_slp_2/),(/3,1,1/),resP)

						if average_time then
							if(it.eq.time_end)then	;average
								resP@gsnPanelMainString="time average"
			print("haha")
						    	gsn_panel(wks,(/plot_1_avgtime(var_id,0),plot_2_avgtime(var_id,0),plot_diff_avgtime(var_id,0)/),(/3/),resP)

							end if
						end if

				    else
				        gsn_panel(wks,(/plot_1(var_id,ip),plot_2(var_id,ip),plot_slp_1,plot_slp_2/),(/3/),resP)	
						if average_time then
							if(it.eq.time_end)then	;average
								resP@gsnPanelMainString="time average"
						    	gsn_panel(wks,(/plot_1_avgtime(var_id,0),plot_2_avgtime(var_id,0)/),(/2/),resP)

							end if
						end if		
				    end if
				      
				end do
			else ;pivot
			    if(have_diff)then
			        gsn_panel(wks,(/plot_1(var_id,0),plot_2(var_id,0),plot_diff(var_id,0),\
									plot_1(var_id,1),plot_2(var_id,1),plot_diff(var_id,1),\
									plot_1(var_id,2),plot_2(var_id,2),plot_diff(var_id,2),\
									plot_1(var_id,3),plot_2(var_id,3),plot_diff(var_id,3),\
									plot_slp_1,plot_slp_2/),(/3,3,3,3,1,1/),resP)
			    else
					gsn_panel(wks,(/plot_1(var_id,0),plot_2(var_id,0),\
									plot_1(var_id,1),plot_2(var_id,1),\
									plot_1(var_id,2),plot_2(var_id,2),\
									plot_1(var_id,3),plot_2(var_id,3),plot_slp_1,plot_slp_2/),(/2,2,2,2,1,1/),resP)
			    end if
			      
				
			end if
		end if
	end do


end do       ; END OF TIME LOOP
  
  



end

