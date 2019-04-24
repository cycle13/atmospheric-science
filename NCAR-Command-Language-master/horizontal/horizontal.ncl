load "$NCARG_ROOT/lib/ncarg/nclex/gsun/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin
;--------------
; some pitfalls  
;---------------
;(1) gsn_panel: Error: all of the plots passed to gsn_panel appear to be invalid. solution: if plot only one variable, set the isoverlay=False. or
												;the plot resource type is not set up properly. vector need to be "vc" 
; (2) if plot the  restart file, the namelist should not contain the first file
; (3) fatal:Variable (mono_fill_scl) is undefinedfatal:Variable (mono_fill_scl) is undefinedfatal:Variable (mono_fill_scl) is undefinedfatal:Variable (mono_fill_scl) is undefined. The gsnPanelLabelBar resource cannot be applied to XY plots anyway, so the solution is to simply not set this resource.
;------------
;-----------------------------------
; if the file contain multiple time, use this block			
;---------------------------
;  times  = wrf_user_list_times(a)  ; get times in the file
;  ntimes = dimsizes(times)         ; number of times in the file
;  mdims = getfilevardimsizes(a,"DUST_1") ; get some dimension sizes for the file
;  nd = dimsizes(mdims)
;--------------------------------
;--------------
;instructions
;---------------- 
; (1) just plot variable, dont' want hurricane center and center output ,hurricane_center_2d=False, search_hurricane_center=False, hurricane_center_dot=False
; (2) plot variable, want center output, but don't want the dot on the plot, hurricane_center_2d=True or search_hurricane_center=True(3d variable),  
	 																									;hurricane_center_dot=False
; (3) just want the location, only plot slp and set hurricane_center_2d=True  hurricane_center_dot=True,  have_diff=False
; (4) want to find the tracks: hurricane_center_2d, search_hurricane_center=True, set=2, set search_method, under 'search hurricane center' section, check the 
; blocks correct or not. I use some criteria to search at some time, should change based on different need.
;-------------------

dir_a="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/full/"
dir_b="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/seas-sulfate-bc-oc/"
;dir_a="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/full/"
;dir_b="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/full-turnoffdust/"
;dir_b="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/nest/other/"

;dir_a="/mnt/parallel_scratch_mp2_wipe_on_december_2017/chen/liangjia/test/case/2010/wrf-no-chem-different-initial-experiment-2/20100821120000/progn1/3.9.1/"
;dir_b="/mnt/parallel_scratch_mp2_wipe_on_december_2017/chen/liangjia/test/case/2010/wrf-no-chem-different-initial-experiment-2/20100821120000/progn1/3.9/"

	
namelist_t = "/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/ncl/namelist-horizontal"  	;???######
filename = asciiread(namelist_t,-1,"string") 	; -1 mean only one dimension
ntimes   = dimsizes(filename)
print(filename)

nest=False					;???######## 

;--------------
;output figure
;---------------
plot_figure=True			;???### 
good_picture=False			;???####
if nest then
	good_picture=False
end if	

;------------
;set time
;--------------
start_time=0				;???### 0 is the first time, you can specify 
end_time=999				;???### 999 means at the end of time, you can specify
time_step=1					;???### not used yet

if (end_time.eq.999)then
	time_end=ntimes-1
else
	time_end=end_time
end if

;-------; levels type: model level(1), Height(2),pressure(3) 	
level_type=3				;???####	
have_diff=True			;???###### plot the difference plot or not

;-------------------
; hurricane center
;----------------------

hurricane_center_dot=True							;???#### 


;--------------------
; (1) search the  center
;--------------------
search_hurricane_center=False							;???###### 

;initial value for the center 
clat0_a=15.;12.98;12.0;18.0;12.;17.0	;15;						;????### 	
clon0_a= 0.;-22.07;-22.0;0.0;-22.;-15.0 ;-28.0; 
clat0_b=15.;12.98;12.0; 18.0;;12.;17.0	;15;		
clon0_b=0.;-22.07;-22.0;0.0;-22.0 ;-15.0  ;-28;

search_method=new((/ntimes/),"float")
center_search_half_size_a=new((/ntimes/),"integer")
center_search_half_size_b=new((/ntimes/),"integer")
lat_min_a=new(ntimes,float)
lon_min_a=new(ntimes,float)
lat_min_b=new(ntimes,float)
lon_min_b=new(ntimes,float)


;search radius
do it=start_time,time_end,1	
						
	if nest then
		center_search_half_size_a(it)=80		
		center_search_half_size_b(it)=80
		;if(it.eq.10)then							;???####  at 2318
		;	center_search_half_size_a(it)=160		
		;	center_search_half_size_b(it)=160
		;end if
	else
		center_search_half_size_a(it)=8		
		center_search_half_size_b(it)=8
	end if
end do

;searching method
do it=start_time,time_end,1

	search_method(it)=5					;???### 1: minimum pressure 2: minimum wind at surface 3:maximum pvo , 4:maximum rvo, 5:minimum wind at 850	

	

	if nest then

		;if(it.eq.10)then								;???### at 2318
		;	search_method(it)=3	;maximum pvo
		;end if

		if(it.ge.0 .and. it.le.10)then					;???### 2400-2418
			search_method(it)=2	;minimum wind
		end if
		;if(it.ge.11 .and. it.le.999)then					
		;	search_method(it)=4	;minimum wind at 4km		;???####
		;end if

	end if	

end do

if search_hurricane_center then
	system("rm center_1.txt")
	system("rm center_2.txt")
end if

;---------------
; (2) read the center
;-----------------
read_center=True				;??? check the center first, then make the position list

if search_hurricane_center then
	read_center=False
end if

if read_center then

	
	search_hurricane_center=False

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





	;B: NEST center

	;full  3hr

	;clat_a=(/11.70,11.06,13.27,12.87,12.44,13.58,12.00,12.74,12.88,13.36,15.38,16.70,16.93,16.51,17.06,\
	;16.65,16.93,17.15,17.39,17.90,19.23,18.77,19.23,19.29,20.32,20.41,20.70/)
	;clon_a=(/-20.80,-21.09,-22.66,-23.32,-23.61,-23.73,-24.73,-26.58,-26.80,-27.58,-27.10,-27.33,\
	;-28.01,-28.71,-29.33,-29.69,-29.85,-30.54,-30.67,-31.30,-32.06,-31.92,-33.17,-33.41,-34.25,-34.99,-35.40/)


	;full nodust 3hr
	;clat_b=(/11.34,11.34,11.66,12.47,12.55,12.76,11.96,12.34,12.24,13.71,14.13,16.07,16.02,\
	;16.62,16.27,16.45,17.01,17.56,17.85,18.24,19.39,19.22,19.74,19.96,20.43,20.77,20.43/)
	;clon_b=(/-20.33,-21.60,-22.73,-23.86,-23.75,-24.16,-25.02,-25.43,-26.71,-27.78,-28.16,-27.94,\
	;-28.39,-28.71,-29.30,-29.27,-29.63,-30.26,-30.92,-31.09,-31.73,-32.25,-33.71,-33.68,-34.14,-35.02,-36.18/)


	;other 3hr
	;clat_b=(/12.52,11.73,11.98,13.13,13.66,13.84,13.54,12.20,12.99,13.99,12.83,15.73,17.06,17.04,\
	;17.14,17.12,17.08,17.24,17.54,17.93,17.77,18.10,18.60,19.26,19.14,19.37,19.44/)
	;clon_b=(/-21.16,-21.02,-23.35,-22.04,-22.70,-22.41,-24.54,-25.50,-26.77,-27.86,-28.48,-27.22,-28.47,\
	;-29.03,-30.01,-30.43,-31.10,-31.60,-32.07,-32.74,-33.03,-33.96,-34.00,-35.43,-36.07,-36.36,-37.21/)

end if

;--------------
; average and correlation , then output text
;---------------------
 average_domain=False		;???###


lat_s0=12.0					;???### set the domain for average , the same as in the vertical-profile.ncl
lat_n0=25.0
lon_w0=-15.0
lon_e0=10.0

average_around_center=True		;???###   need to set read_center=True	or search_hurricane_center=True
deviation_from_center=3		;???###

	
height_lev=(/100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,1000/)   ; for correlation


if average_around_center .or. average_domain then
	have_diff=True
	plot_figure=False
end if

;------------------
; output station variable
;-----------------------
output_station=False		;???###### 


if output_station then
	station_lat=(/13.541,13.278,9.760, 16.733,  14.394/)				;#########
	station_lon=(/2.665,-5.934,  1.599,-22.935,-16.959/)
	station_name=(/"Banizoumbou","IER_Cinzana","Djougou","Capo_Verde","Dakar"/)
	dimstation=dimsizes(station_name)
	num_stations=dimstation(0)

end if



;--------------------
; add position for diagostic 
;--------------------

add_dot=False		;????##### add the dot you want, for diagnostic purpose
dot_3d=False		;???###### set True for 3d variable
lat_dot=(/15.0,30.0,30.0,30.0,30.0,30.0,30.0,30.0,30.0/)
lon_dot=(/-25.0,-30.0,-30.0,-30.0,-30.0,-30.0,-30.0,-30.0,-30.0/)
;lat_dot=(/15.0/)  ; no airs
;lon_dot=(/-25.0/)	
lat_dot=(/13.0/)  ; with airs
lon_dot=(/-27.0/)

;--------------------
; map domain
;--------------------
lat_s=new((/500/),"float")
lat_n=new((/500/),"float")
lon_w=new((/500/),"float")
lon_e=new((/500/),"float")

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

;--------------------
;the variables plot 
;--------------------	
set=527					;???######

	;----------------	
	;examples 1001-1008 , don't modify, test them when have new code
	;-----------------
if (set.eq.2001)then					;(1) example for plot only one 2D variable
	var_name=(/"slp"/) 	
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"cn"/)
	smooth=(/True/)
	isoverlay=(/False/)							;set to False if only one variable					
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.2002)then					;(2) example for plot only one 3D variable
	var_name=(/"tc"/)
	exist_both_file=(/True/)
	if_2d_var=(/False/)
	var_res=(/"cn"/)
	smooth=(/True/)
	isoverlay=(/False/)							;False			
	isoverlay_diff=(/False/)					
	in_restart_file=(/False/)
end if


if (set.eq.2003)then
    var_name=(/"slp","SST"/) 		;(3) plot more than one 2D variable,  no overlay  ,can be many variables in the list	
    exist_both_file=(/True,True/) 				
    if_2d_var=(/True,True/)
    var_res=(/"sh","sh"/)
    smooth=(/True,True/)
    isoverlay=(/False,False/)   			;All False			
    isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if

if (set.eq.2004)then
        var_name=(/"slp","SST"/) 	;(4) plot more than one 2D variable,  overlay   ;maximum of overlay variables is 3 
        exist_both_file=(/True,True/) 				
        if_2d_var=(/True,True/)
        var_res=(/"cn","sh"/)					;cn and vc must before sh
        smooth=(/True,True/)
        isoverlay=(/True,True/)   				;True			
        isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if



if (set.eq.2005)then					;(5) plot more than one 2D variable,  overlay mix with no overlay
	var_name=(/"wind_vector_2d","SST","slp"/)  ;"wind_vector_2d","SST","slp".....,   can add more no overlay variables at the end 
	exist_both_file=(/True,True,True/)
	if_2d_var=(/True,True,True/)
	var_res=(/"vc","sh","sh","sh","vc"/)
	smooth=(/True,True,False/)
	isoverlay=(/True,True,False/)		;overlay variable must place before the no overlay variable. (/False,True,True/) or (/True,False,True/) are wrong! 
	isoverlay_diff=(/True,True,False/)	
	in_restart_file=(/False,False,False/)
end if



if (set.eq.2006)then					;(6) plot more than one 3D variable, no overlay,can be many variables in the list	
	var_name=(/"rh","tc"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/True,True/)
	isoverlay=(/False,False/)			;All False
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if

if (set.eq.2007)then					;(7) plot more than one 3D variable, overlay
	var_name=(/"rh","tc"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/True,True/)
	isoverlay=(/True,True/)				;True
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if


if (set.eq.2008)then					;(8) plot more than one 3D variable,  overlay mix with no overlay
	var_name=(/"wind_vector","rh","tc"/)
	exist_both_file=(/True,True,True/)
	if_2d_var=(/False,False,False/)
	var_res=(/"vc","cn","sh"/)
	smooth=(/True,True,True/)
	isoverlay=(/True,True,False/)		;overlay variable must place before the no overlay variable. (/False,True,True/) or (/True,False,True/) are wrong! 
	isoverlay_diff=(/True,True,False/)
	in_restart_file=(/False,False,False/)
end if



;---------------end of example

;------------
; test
;-------------
if (set.eq.400)then
    var_name=(/"rh_mean","slp"/)
    exist_both_file=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
    if_2d_var=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
    var_res=(/"vc","vc","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh"/)
    smooth=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
    isoverlay=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)     
    isoverlay_diff=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
	in_restart_file=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
end if

if (set.eq.401)then
	var_name=(/"rh","eth"/)
	exist_both_file=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)	 
	if_2d_var=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)		
	var_res=(/"sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh"/)
	smooth=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
	isoverlay=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/) 
	isoverlay_diff=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
	in_restart_file=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)	
end if

if (set.eq.403)then
    var_name=(/"wind_speed_2d","slp","rh","eth"/)
    exist_both_file=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,\
											True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
    if_2d_var=(/True,True,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
    var_res=(/"sh","sh","sh","sh","sh","sh","sh","sh",\
			"sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh"/)
    smooth=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,\
																		False,False,False,False,False,False,False,False,False,False,False,False/)   
    isoverlay=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,\
																		False,False,False,False,False,False,False,False,False,False,False,False/)     
    isoverlay_diff=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,\
																		False,False,False,False,False,False,False,False,False,False,False,False/)  
	in_restart_file=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,\
																		False,False,False,False,False,False,False,False,False,False,False,False/)  
end if


if (set.eq.404)then
        var_name=(/"SST"/) 	;(4) plot more than one 2D variable,  overlay   ;maximum of overlay variables is 3 
        exist_both_file=(/True,True/) 				
        if_2d_var=(/True,True/)
        var_res=(/"sh","sh"/)					;cn and vc must before sh
        smooth=(/True,True/)
        isoverlay=(/False,True/)   				;True			
        isoverlay_diff=(/False,True/)
	in_restart_file=(/False,False/)
end if

;----------------------
; correlation		put 2D variabe before 3D,  my code can correlate all these variable togerther, set.eq.500
					; but it is slow, so I divided the variable , only correlate two variable, 2D to 3D. set>500
;------------------
if (set.eq.500)then
    var_name=(/"aod","slp","shear_wind_speed","wind_speed_2d","mdbz","RAINNC","mcape","rh_mean",\
			"total_dust","EXTCOF55","pvo","rvo","th","eth","tc","rh","QVAPOR","QCLOUD","QNDROP","QRAIN","QICE","snow_graup","wa","wind_speed","t_td"/)
    	exist_both_file=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,\
											True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
    if_2d_var=(/True,True,True,True,True,True,True,True,\
				False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
    var_res=(/"sh","sh","sh","sh","sh","sh","sh","sh",\
			"sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh"/)
    smooth=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,\
																		False,False,False,False,False,False,False,False,False,False,False,False/)   
    isoverlay=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,\
																		False,False,False,False,False,False,False,False,False,False,False,False/)     
    isoverlay_diff=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,\
																		False,False,False,False,False,False,False,False,False,False,False,False/)  
	in_restart_file=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,\
																		False,False,False,False,False,False,False,False,False,False,False,False/)  
end if

				; set from 501 to 522 ,submit job to cluster

if (set.eq.501)then
   var_name=(/"min_slp","SST"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if

if (set.eq.502)then
   var_name=(/"min_slp","aod"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.503)then
   var_name=(/"min_slp","shear_wind_speed"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.504)then
   var_name=(/"min_slp","mdbz"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.505)then
   var_name=(/"min_slp","RAINNC"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.506)then
   var_name=(/"min_slp","rh_mean"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.507)then
   var_name=(/"min_slp","mcape"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.508)then
   var_name=(/"min_slp","EXTCOF55"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.509)then
   var_name=(/"min_slp","pvo"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.510)then
   var_name=(/"min_slp","rvo"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.511)then
   var_name=(/"min_slp","th"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.512)then
   var_name=(/"min_slp","eth"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.513)then
   var_name=(/"min_slp","tc"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.514)then
   var_name=(/"min_slp","rh"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.515)then
   var_name=(/"min_slp","QVAPOR"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.516)then
   var_name=(/"min_slp","QCLOUD"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.517)then
   var_name=(/"min_slp","QNDROP"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.518)then
   var_name=(/"min_slp","QRAIN"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.519)then
   var_name=(/"min_slp","QICE"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.520)then
   var_name=(/"min_slp","snow_graup"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.521)then
   var_name=(/"min_slp","wa"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.522)then
   var_name=(/"min_slp","wind_speed"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.523)then
   var_name=(/"min_slp","t_td"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if


if (set.eq.524)then
   var_name=(/"min_slp","ua"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if




if (set.eq.601)then
   var_name=(/"max_wind","SST"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if

if (set.eq.602)then
   var_name=(/"max_wind","aod"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.603)then
   var_name=(/"max_wind","shear_wind_speed"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.604)then
   var_name=(/"max_wind","mdbz"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.605)then
   var_name=(/"max_wind","RAINNC"/)
exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.606)then
   var_name=(/"max_wind","rh_mean"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.607)then
   var_name=(/"max_wind","mcape"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.608)then
   var_name=(/"max_wind","EXTCOF66"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.609)then
   var_name=(/"max_wind","pvo"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.610)then
   var_name=(/"max_wind","rvo"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.611)then
   var_name=(/"max_wind","th"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.612)then
   var_name=(/"max_wind","eth"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.613)then
   var_name=(/"max_wind","tc"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.614)then
   var_name=(/"max_wind","rh"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.615)then
   var_name=(/"max_wind","QVAPOR"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.616)then
   var_name=(/"max_wind","QCLOUD"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.617)then
   var_name=(/"max_wind","QNDROP"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.618)then
   var_name=(/"max_wind","QRAIN"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.619)then
   var_name=(/"max_wind","QICE"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.620)then
   var_name=(/"max_wind","snow_graup"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.621)then
   var_name=(/"max_wind","wa"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.622)then
   var_name=(/"max_wind","wind_speed"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if
if (set.eq.623)then
   var_name=(/"max_wind","t_td"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if


if (set.eq.624)then
   var_name=(/"max_wind","ua"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,False/)				
	isoverlay_diff=(/False,False/)
	in_restart_file=(/False,False/)
end if

;-----------------------
;horizontal plot		submit job to cluster  601 to 622 or 701 to 722 or 801 to 822
;-------------------
;(A) single variable


;------- 2d variable
if (set.eq.701)then
   var_name=(/"SST"/)
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.702)then
   var_name=(/"aod"/)
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.703)then
   var_name=(/"shear_wind_speed"/)
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.704)then
   var_name=(/"mdbz"/)
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.705)then
	var_name=(/"RAINNC"/)
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.706)then
   var_name=(/"rh_mean"/)	
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.707)then
   var_name=(/"mcape"/)	
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"sh"/)
	smooth=(/False,False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

;--- 3D variable
if (set.eq.708)then	
	var_name=(/"EXTCOF55"/)
	exist_both_file=(/True/)
	if_2d_var=(/False/)
	var_res=(/"sh"/)
	smooth=(/False/)
	isoverlay=(/False/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.709)then	
	var_name=(/"pvo"/)
	exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.710)then
   var_name=(/"rvo"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.711)then
   var_name=(/"th"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.712)then
   var_name=(/"eth"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.713)then
   var_name=(/"tc"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.714)then
   var_name=(/"rh"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.715)then
   var_name=(/"QVAPOR"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.716)then
   var_name=(/"QCLOUD"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.717)then
   var_name=(/"QNDROP"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.718)then
   var_name=(/"QRAIN"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.719)then
   var_name=(/"QICE"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.720)then
   var_name=(/"snow_graup"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.721)then
   var_name=(/"wa"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.722)then
   var_name=(/"wind_speed"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.723)then
   var_name=(/"t_td"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if
if (set.eq.724)then
   var_name=(/"total_dust"/)
    exist_both_file=(/True/)
	if_2d_var=(/False,False/)
	var_res=(/"sh","sh"/)
	smooth=(/False,False/)
	isoverlay=(/False,True/)				
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

;(B) add slp to 2d and add ext to 3d
;------- 2d variable
if (set.eq.801)then
   var_name=(/"slp","SST"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.802)then
   var_name=(/"slp","aod"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.803)then
   var_name=(/"slp","shear_wind_speed"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.804)then
   var_name=(/"slp","mdbz"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.805)then
	var_name=(/"slp","RAINNC"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.806)then
   var_name=(/"slp","rh_mean"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.807)then
   var_name=(/"slp","mcape"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

;--- 3D variable

if (set.eq.808)then	
	var_name=(/"EXTCOF55","pvo"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.809)then
   var_name=(/"EXTCOF55","rvo"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.810)then
   var_name=(/"EXTCOF55","th"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.811)then
   var_name=(/"EXTCOF55","eth"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.812)then
   var_name=(/"EXTCOF55","tc"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.813)then
   var_name=(/"EXTCOF55","rh"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.814)then
   var_name=(/"EXTCOF55","QVAPOR"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.815)then
   var_name=(/"EXTCOF55","QCLOUD"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.816)then
   var_name=(/"EXTCOF55","QNDROP"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.817)then
   var_name=(/"EXTCOF55","QRAIN"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.818)then
   var_name=(/"EXTCOF55","QICE"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.819)then
   var_name=(/"EXTCOF55","snow_graup"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.820)then
   var_name=(/"EXTCOF55","wa"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.821)then
   var_name=(/"EXTCOF55","wind_speed"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.822)then
   var_name=(/"EXTCOF55","t_td"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.823)then
   var_name=(/"EXTCOF55","total_dust"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"cn","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

;(c) add wind vector
;------- 2d variable
if (set.eq.901)then
    var_name=(/"wind_vector_2d","SST"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.902)then
    var_name=(/"wind_vector_2d","aod"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.903)then
    var_name=(/"wind_vector_2d","shear_wind_speed"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.904)then
    var_name=(/"wind_vector_2d","mdbz"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.905)then
	var_name=(/"wind_vector_2d","RAINNC"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.906)then
    var_name=(/"wind_vector_2d","rh_mean"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.907)then
    var_name=(/"wind_vector_2d","mcape"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

;--- 3D variable
if (set.eq.908)then	
	var_name=(/"wind_vector","EXTCOF55"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.909)then	
	var_name=(/"wind_vector","pvo"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.910)then
    var_name=(/"wind_vector","rvo"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.911)then
    var_name=(/"wind_vector","th"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.912)then
    var_name=(/"wind_vector","eth"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.913)then
    var_name=(/"wind_vector","tc"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.914)then
    var_name=(/"wind_vector","rh"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.915)then
    var_name=(/"wind_vector","QVAPOR"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.916)then
    var_name=(/"wind_vector","QCLOUD"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.917)then
    var_name=(/"wind_vector","QNDROP"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.918)then
    var_name=(/"wind_vector","QRAIN"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.919)then
    var_name=(/"wind_vector","QICE"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.920)then
    var_name=(/"wind_vector","snow_graup"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.921)then
    var_name=(/"wind_vector","wa"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.922)then
    var_name=(/"wind_vector","wind_speed"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.923)then
    var_name=(/"wind_vector","t_td"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.924)then
    var_name=(/"wind_vector","total_dust"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"vc","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if



;(c) add stream line
;------- 2d variable
if (set.eq.1001)then
    var_name=(/"wind_vector_2d","SST"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.1002)then
    var_name=(/"wind_vector_2d","aod"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1003)then
    var_name=(/"wind_vector_2d","shear_wind_speed"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1004)then
    var_name=(/"wind_vector_2d","mdbz"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1005)then
	var_name=(/"wind_vector_2d","RAINNC"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1006)then
    var_name=(/"wind_vector_2d","rh_mean"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.1007)then
    var_name=(/"wind_vector_2d","mcape"/)	
	exist_both_file=(/True,True/)
	if_2d_var=(/True,True/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

;--- 3D variable
if (set.eq.1008)then	
	var_name=(/"wind_vector","EXTCOF55"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.1009)then	
	var_name=(/"wind_vector","pvo"/)
	exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.1010)then
    var_name=(/"wind_vector","rvo"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1011)then
    var_name=(/"wind_vector","th"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1012)then
    var_name=(/"wind_vector","eth"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1013)then
    var_name=(/"wind_vector","tc"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1014)then
    var_name=(/"wind_vector","rh"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1015)then
    var_name=(/"wind_vector","QVAPOR"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1016)then
    var_name=(/"wind_vector","QCLOUD"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1017)then
    var_name=(/"wind_vector","QNDROP"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1018)then
    var_name=(/"wind_vector","QRAIN"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1019)then
    var_name=(/"wind_vector","QICE"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1020)then
    var_name=(/"wind_vector","snow_graup"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1021)then
    var_name=(/"wind_vector","wa"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1022)then
    var_name=(/"wind_vector","wind_speed"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if
if (set.eq.1023)then
    var_name=(/"wind_vector","t_td"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if

if (set.eq.1024)then
    var_name=(/"wind_vector","total_dust"/)
    exist_both_file=(/True,True/)
	if_2d_var=(/False,False/)
	var_res=(/"str","sh"/)
	smooth=(/False,False/)
	isoverlay=(/True,True/)				
	isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)
end if


;--------
;plot all  2d
;----------
if (set.eq.200)then
    var_name=(/"wind_vector_2d","shear_vector","aod","slp","wind_speed_2d","SST","mdbz","RAINNC","mcape","rh_mean"/)
    exist_both_file=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
    if_2d_var=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
    var_res=(/"vc","vc","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh"/)
    smooth=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
    isoverlay=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)     
    isoverlay_diff=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
	in_restart_file=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
end if
;---------
;plot all 3d
;------------
if (set.eq.300)then
	var_name=(/"wind_vector","total_dust","EXTCOF55","pvo","rvo","th","eth","tc","rh","QVAPOR","QCLOUD","QNDROP","QRAIN","wa","wind_speed","t_td"/)
	exist_both_file=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)	 
	if_2d_var=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)		
	var_res=(/"vc","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh","sh"/)
	smooth=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
	isoverlay=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/) 
	isoverlay_diff=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)
	in_restart_file=(/False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False/)	
end if


;--------------
; surface flux
;-----------


;ACSWUPB 	:ACCUMULATED UPWELLING SHORTWAVE FLUX AT BOTTOM
;ACSWUPBC  	:ACCUMULATED UPWELLING CLEAR SKY SHORTWAVE FLUX AT BOTTOM
;ACSWDNB	"ACCUMULATED DOWNWELLING SHORTWAVE FLUX AT BOTTOM" ;
;ACSWDNBC	ACCUMULATED DOWNWELLING CLEAR SKY SHORTWAVE FLUX AT BOTTOM" ;
;ACLWUPB    	ACCUMULATED UPWELLING LONGWAVE FLUX AT BOTTOM" 
;ACLWUPBC  	"ACCUMULATED UPWELLING CLEAR SKY LONGWAVE FLUX AT BOTTOM" ;
;ACLWDNB   	"ACCUMULATED DOWNWELLING LONGWAVE FLUX AT BOTTOM" ;
;ACLWDNBC   	"ACCUMULATED DOWNWELLING CLEAR SKY LONGWAVE FLUX AT BOTTOM" ;

if (set.eq.101)then
        var_name=(/"TSK","ACHFX2","ACLHF2","net_sw_down","ACLWUPB2","ACLWDNB2","net_lw_down","net_sw_lw_down"/)
        exist_both_file=(/True,True,True,True,True,True,True,True,True/)
        if_2d_var=(/True,True,True,True,True,True,True,True,True/)
        var_res=(/"sh","sh","sh","sh","sh","sh","sh","sh"/)
        smooth=(/True,True,True,True,True,True,True,True/)
        isoverlay=(/False,False,False,False,False,False,False,False/)     
        isoverlay_diff=(/False,False,False,False,False,False,False,False/)
	in_restart_file=(/False,False,False,False,False,False,False,False,False,False/)
end if

if (set.eq.102)then
        var_name=(/"SWDOWN"/);SWDOWN: DOWNWARD SHORT WAVE FLUX AT GROUND SURFACE, instant flux
				;SWNORM: NORMAL SHORT WAVE FLUX AT GROUND SURFACE (SLOPE-DEPENDENT)" ;
			;SWDOWN is different from GSW, GSW consider the surface albedo
	;set opts@gsnFrame= True ; opts@gsnDraw = True  , and disable panel plot. it is very slow
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.103)then
        var_name=(/"GLW","GSW"/) ;GSW: NET SHORT WAVE FLUX AT GROUND SURFACE" GLW:DOWNWARD LONG WAVE FLUX AT GROUND SURFACE ; instant flux
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.104)then
        var_name=(/"TSK"/) ;TSK:"SURFACE SKIN TEMPERATURE"; HFX:"UPWARD HEAT FLUX AT THE SURFACE" 
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)
end if



if (set.eq.105)then
        var_name=(/"QFX","LH"/) ;QFX:"UPWARD MOISTURE FLUX AT THE SURFACE" ;LH: "LATENT HEAT FLUX AT THE SURFACE"; instant flux, different from ACLHF
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.106)then
        var_name=(/"ACLHF","ACHFX"/) ;ACHFX:"ACCUMULATED UPWARD HEAT FLUX AT THE SURFACE" 
				;ACLHF: ACCUMULATED UPWARD LATENT HEAT FLUX AT THE SURFACE" ; the current time, this is different from ACHFX2
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.107)then
        var_name=(/"ACHFX2"/)   ;ACCUMULATED UPWARD HEAT FLUX AT THE SURFACE, current time - previous time. use this set to show the flux within time window
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.108)then
        var_name=(/"ACLHF2"/) 	;current time - previous time. use this set to show the flux within time window
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.109)then
        var_name=(/"achfx2_aclhfx2"/)  ; current time - previous time. combination of ACLHF2 and ACHFX2
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if



if (set.eq.110)then
        var_name=(/"ACSWUPB2"/) 	;ACCUMULATED UPWELLING CLEAR SKY SHORTWAVE FLUX AT BOTTOM;  current time - previous time
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.111)then
        var_name=(/"ACSWUPBC2"/)  	;ACSWUPBC  	:ACCUMULATED UPWELLING CLEAR SKY SHORTWAVE FLUX AT BOTTOM; current time - previous time
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.112)then
        var_name=(/"ACSWDNB2"/) 	;ACSWDNB	"ACCUMULATED DOWNWELLING SHORTWAVE FLUX AT BOTTOM" ;current time - previous time
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.113)then
        var_name=(/"ACSWDNBC2"/) 	;ACSWDNBC	ACCUMULATED DOWNWELLING CLEAR SKY SHORTWAVE FLUX AT BOTTOM" ;current time - previous time
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.114)then
        var_name=(/"net_sw_down"/) 	; ACCUMULATED shortwave downard - shortwave upward; ;current time - previous time
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.115)then
        var_name=(/"ACSWDNB2","net_sw_down"/) 
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if


if (set.eq.116)then
        var_name=(/"ACLWUPB2"/) 	;ACLWUPB    	ACCUMULATED UPWELLING LONGWAVE FLUX AT BOTTOM" ;current time - previous time
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.117)then		;ACLWUPBC  	"ACCUMULATED UPWELLING CLEAR SKY LONGWAVE FLUX AT BOTTOM" ;;current time - previous time
        var_name=(/"ACLWUPBC2"/) 
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.118)then		;ACLWDNB   	"ACCUMULATED DOWNWELLING LONGWAVE FLUX AT BOTTOM" ;current time - previous time
        var_name=(/"ACLWDNB2"/) 
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.119)then		;ACLWDNBC   	"ACCUMULATED DOWNWELLING CLEAR SKY LONGWAVE FLUX AT BOTTOM" ;current time - previous time
        var_name=(/"ACLWDNBC2"/) 
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.120)then
        var_name=(/"net_lw_down"/) 	;ACCUMULATED longwave down- longwave up(ACLWDNB2-ACLWUPB2); ;current time - previous time 
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)

	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.121)then
        var_name=(/"ACLWUPB2","net_lw_down"/) 
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.122)then
        var_name=(/"net_sw_lw_down"/)    ;ACSWDNB-ACSWUPB; ;current time - previous time
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.123)then
        var_name=(/"ACGRDFLX2"/) 		;ACCUMULATED GROUND HEAT FLUX
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

if (set.eq.124)then
        var_name=(/"net_ground_total"/) 	;residual , combine all the flux at the surface ;??? not completed yet
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"sh","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	in_restart_file=(/True,True,True,False,False/)
end if

;------------
; 2D variable
;----------------

		;----- slp-----------
if (set.eq.1)then
	var_name=(/"slp"/)
	exist_both_file=(/True/)
	if_2d_var=(/True/)
	var_res=(/"sh"/)
	smooth=(/True/)
	isoverlay=(/False/)						
	isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.2)then
	var_name=(/"wind_vector_2d","slp"/)
	exist_both_file=(/True,True,True/)
	if_2d_var=(/True,True,True/)
	var_res=(/"vc","sh","cn","sh","vc"/)
	smooth=(/False,True,True/)
	isoverlay=(/True,True,True/)						
	isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)

end if


if (set.eq.3)then
    var_name=(/"aod","slp"/) 
    exist_both_file=(/True,True/)
    if_2d_var=(/True,True/)
    var_res=(/"cn","sh"/)
    smooth=(/True,True/)
    isoverlay=(/True,True/)
    isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)

end if

if (set.eq.4)then
	var_name=(/"wind_vector_2d","RAINNC","slp"/)
	exist_both_file=(/True,True,True/)
	if_2d_var=(/True,True,True/)
	var_res=(/"vc","cn","sh","sh","vc"/)
	smooth=(/False,True,True/)
	isoverlay=(/True,True,True/)						
	isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)

end if

		;--------AOD-----------
if (set.eq.5)then
    var_name=(/"aod"/)
    exist_both_file=(/True/) 
    if_2d_var=(/True/)
    var_res=(/"sh"/)
    smooth=(/True/)
    isoverlay=(/False/)      		
    isoverlay_diff=(/False/)
	in_restart_file=(/False/)
end if

if (set.eq.6)then
    var_name=(/"slp","aod"/) 
    exist_both_file=(/True,True/)
    if_2d_var=(/True,True/)
    var_res=(/"cn","sh"/)
    smooth=(/True,True/)
    isoverlay=(/True,True/)
    isoverlay_diff=(/True,True/)
	in_restart_file=(/False,False/)

end if


if (set.eq.7)then
        var_name=(/"slp","wind_vector_2d","SST"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","vc","sh","cn","sh","vc"/)
        smooth=(/True,False,True/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.8)then
        var_name=(/"slp","RAINNC"/)  ; ACCUMULATED TOTAL GRID SCALE PRECIPITATION
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.9)then
        var_name=(/"slp","mcape"/) 
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","sh","cn","sh","vc"/)
        smooth=(/True,True,True/)
        isoverlay=(/True,True/)
        isoverlay_diff=(/True,True,True/)
	in_restart_file=(/False,False,False/)
end if



if (set.eq.10)then
        var_name=(/"slp","mdbz"/)  
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.11)then
        var_name=(/"slp","wind_speed_2d"/)  
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.12)then
        var_name=(/"shear_vector","slp"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"vc","sh","cn","sh","vc"/)
        smooth=(/False,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.13)then
        var_name=(/"slp","rh_mean"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/True,True,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

;----------
;3D variable
;------------

			;-----------tc,rh----------

if (set.eq.50)then
	var_name=(/"wind_vector","t_td","tc"/)
	exist_both_file=(/True,True,True/)	 
	if_2d_var=(/False,False,False/)		
	var_res=(/"vc","cn","sh"/)
	smooth=(/False,False,False/)
	isoverlay=(/True,True,True/) 
	isoverlay_diff=(/True,True,True/)
	  	
	in_restart_file=(/False,False,False,False,False/)	
end if

if (set.eq.51)then
        var_name=(/"wind_vector","tc"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"vc","sh","cn","sh","vc"/)
        smooth=(/False,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.52)then
	var_name=(/"wind_vector","tc","rh"/)
	exist_both_file=(/True,True,True/)
	if_2d_var=(/False,False,False/)
	var_res=(/"vc","cn","sh"/)
	smooth=(/False,True,True/)
	isoverlay=(/True,True,True/)						
	isoverlay_diff=(/True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.53)then
        var_name=(/"wind_vector","rh"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"vc","sh","cn","sh","vc"/)
        smooth=(/False,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

			;-------- th-------------
if (set.eq.54)then
	var_name=(/"rh","eth"/)
	exist_both_file=(/True,True,True,True,True,True/)
	if_2d_var=(/False,False,False,True,True,True/)
	var_res=(/"cn","sh","vc","cn","sh","vc"/)
	smooth=(/True,True,False,True,True,False/)
	isoverlay=(/True,True,True,True,True,True/)						
	isoverlay_diff=(/True,True,True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if

if (set.eq.55)then
        var_name=(/"th"/)  
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"sh","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.56)then
        var_name=(/"rvo","th"/)  
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


			;------- wind speed------------

if (set.eq.57)then
        var_name=(/"wind_speed"/)  
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"sh","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.58)then
        var_name=(/"wind_vector","wind_speed"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"vc","sh","sh","vc"/)
        smooth=(/False,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if

if (set.eq.59)then
        var_name=(/"wind_vector","wind_speed"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"str","sh","sh","vc"/)		;stream line
        smooth=(/False,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if

if (set.eq.60)then
	var_name=(/"wind_speed","tc"/)
	exist_both_file=(/True,True,True,True,True,True/)
	if_2d_var=(/False,False,False,True,True,True/)
	var_res=(/"cn","sh","vc","cn","sh","vc"/)
	smooth=(/True,True,False,True,True,False/)
	isoverlay=(/True,True,True,True,True,True/)						
	isoverlay_diff=(/True,True,True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if


if (set.eq.61)then
        var_name=(/"rvo","wind_speed"/)  
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


			;----pvo,rvo---------------
if (set.eq.62)then
	var_name=(/"pvo"/)
	exist_both_file=(/True,True,True,True,True,True/)
	if_2d_var=(/False,False,False,True,True,True/)
	var_res=(/"sh","sh","cn","vc","cn","sh","vc"/)
	smooth=(/False,True,False,True,True,False/)
	isoverlay=(/False,True,True,True,True,True/)						
	isoverlay_diff=(/False,True,True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if

if (set.eq.63)then
	var_name=(/"wa","pvo"/)
	exist_both_file=(/True,True,True,True,True,True/)
	if_2d_var=(/False,False,False,True,True,True/)
	var_res=(/"cn","sh","cn","vc","cn","sh","vc"/)
	smooth=(/True,True,False,True,True,False/)
	isoverlay=(/True,True,True,True,True,True/)						
	isoverlay_diff=(/True,True,True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if


if (set.eq.64)then
        var_name=(/"wind_vector","wind_speed","pvo"/)
        exist_both_file=(/True,True,True,True,True,True/)
        if_2d_var=(/False,False,False,True,True,True/)
        var_res=(/"vc","cn","sh","cn","sh","vc"/)
        smooth=(/False,True,True,False,True,True,False/)
        isoverlay=(/True,True,True,True,True,True/)
        isoverlay_diff=(/True,True,True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if
if (set.eq.65)then
        var_name=(/"wind_vector","rvo"/)
        exist_both_file=(/True,True,True,True,True,True/)
        if_2d_var=(/False,False,False,True,True,True/)
        var_res=(/"vc","sh","vc","cn","sh","vc"/)
        smooth=(/True,True,False,True,True,False/)
        isoverlay=(/True,True,True,True,True,True/)
        isoverlay_diff=(/True,True,True,True,True,True/)
	in_restart_file=(/False,False,False,False,False/)
	  
end if

if (set.eq.66)then
	var_name=(/"wa","rvo"/)
	exist_both_file=(/True,True,True,True,True,True/)
	if_2d_var=(/False,False,False,True,True,True/)
	var_res=(/"cn","sh","cn","vc","cn","sh","vc"/)
	smooth=(/True,True,False,True,True,False/)
	isoverlay=(/True,True,True,True,True,True/)						
	isoverlay_diff=(/True,True,True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if


		;-----vertical-----------
if (set.eq.67)then
        var_name=(/"wa"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"sh","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/False,True,True/)     
        isoverlay_diff=(/False,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.68)then
        var_name=(/"rvo","wa"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if



		;--------  moist content


if (set.eq.69)then
        var_name=(/"QVAPOR"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"sh","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/False,True,True/)     
        isoverlay_diff=(/False,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.70)then
	var_name=(/"wind_vector","QVAPOR"/)
	exist_both_file=(/True,True,True/)
	if_2d_var=(/False,False,True/)
	var_res=(/"vc","sh","vc","cn","sh","vc"/)
	smooth=(/True,True,False/)
	isoverlay=(/True,True,True/)						
	isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if

if (set.eq.71)then
        var_name=(/"rvo","QVAPOR"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if



if (set.eq.72)then
        var_name=(/"QCLOUD"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"sh","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/False,True,True/)     
        isoverlay_diff=(/False,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.73)then
        var_name=(/"QCLOUD","QNDROP"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if

if (set.eq.74)then
        var_name=(/"rvo","QCLOUD"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.75)then
        var_name=(/"QNDROP"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"sh","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/False,True,True/)     
        isoverlay_diff=(/False,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.76)then
        var_name=(/"rvo","QNDROP"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.77)then
        var_name=(/"QRAIN"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"sh","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/False,True,True/)     
        isoverlay_diff=(/False,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.78)then
        var_name=(/"wind_vector","QRAIN"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"vc","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.79)then
        var_name=(/"rvo","QRAIN"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"cn","sh","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.80)then
        var_name=(/"RTHRATSW"/)  
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,True,True/)
        var_res=(/"sh","cn","cn","sh","vc"/)
        smooth=(/False,True,False/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
          
	in_restart_file=(/False,False,False,False,False/)
end if

if (set.eq.81)then
        var_name=(/"RTHRATLW"/)  
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,True,True/)
        var_res=(/"sh","cn","cn","sh","vc"/)
        smooth=(/False,True,False/)
        isoverlay=(/False,True,True/)
        isoverlay_diff=(/False,True,True,True/)
          
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.82)then
        var_name=(/"wind_vector","geopt"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"vc","sh","vc","cn","sh","vc"/)
        smooth=(/True,True,False/)
        isoverlay=(/True,True,True/)
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)

end if

		;-------aerosol------------

if (set.eq.83)then
        var_name=(/"wind_vector","EXTCOF55"/)
        exist_both_file=(/True,True,True/)
        if_2d_var=(/False,False,True/)
        var_res=(/"vc","sh","cn","sh","vc"/)
        smooth=(/False,True,False/)
        isoverlay=(/True,True,True/)     
        isoverlay_diff=(/True,True,True,True/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.84)then
	var_name=(/"DUST_1","DUST_2","DUST_3","DUST_4","DUST_5"/)
	exist_both_file=(/True,True,True,True,True/)
	if_2d_var=(/False,False,False,False,False/)
	var_res=(/"sh","sh","sh","sh","sh"/)
	smooth=(/True,True,True,True,True/)
	isoverlay=(/False,False,False,False,False/)						
	isoverlay_diff=(/False,False,False,False,False/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if


if (set.eq.85)then
	var_name=(/"total_dust"/)
	exist_both_file=(/True,True,True,True,True/)
	if_2d_var=(/False,False,False,False,False/)
	var_res=(/"sh","sh","sh","sh","sh"/)
	smooth=(/True,True,True,True,True/)
	isoverlay=(/False,False,False,False,False/)						
	isoverlay_diff=(/False,False,False,False,False/)
	  
	in_restart_file=(/False,False,False,False,False/)
end if



;----modify some default setting-----
if if_2d_var(0) then
	plot_3d=False
else
	plot_3d=True
end if

if hurricane_center_dot then
	if if_2d_var(0) then
		hurricane_center_dot_3d=False							
		hurricane_center_dot_2d=True
	else
		hurricane_center_dot_3d=True							
		hurricane_center_dot_2d=False
	end if
end if						

var_numbers=dimsizes(var_name)	
if output_station then
	station_data1=new((/ntimes, var_numbers,num_stations/),"float")
	station_data2=new((/ntimes, var_numbers,num_stations/),"float")
end if


; open work station
tmpname1=str_sub_str(filename(start_time),":","_")
tmpname2=str_sub_str(filename(time_end),":","_")
var_numbers=dimsizes(var_name)	
if (var_numbers.eq.1) then
	wks_name="horizontal-"+var_name(0)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.eq.2) then
	wks_name="horizontal-"+var_name(0)+"-"+var_name(1)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.eq.3) then
	wks_name="horizontal-"+var_name(0)+"-"+var_name(1)+"-"+var_name(2)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.gt.3) then
	wks_name="horizontal-"+var_name(0)+"-"+var_name(1)+"-"+var_name(2)+"-other-"+tmpname1+"-"+tmpname2  
end if
wks=gsn_open_wks("pdf",wks_name) 

rmfile="rm "+wks_name+".txt"
system(rmfile)
 

; gsn_define_colormap(wks,"WhViBlGrYeOrReWh")                ;???#################
 ;gsn_define_colormap(wks,"BlRe")                   
gsn_define_colormap(wks,"cmp_flux")
if (set.eq.5.or.set.eq.6.or.set.eq.702.or.set.eq.802.or.set.eq.902.or.set.eq.1002)then		
	gsn_define_colormap(wks,"BlAqGrYeOrReVi200")			;???###### for AOD
end if



;--------------------
; define the plot array						
;--------------------
plot_1_3d=new((/50,70/),"graphic") 		;store data1, plot_1_3d(time,variable,level) ;store the 2d variable
plot_2_3d=new((/50,70/),"graphic")	
plot_diff_3d=new((/50,70/),"graphic") 
plot_dot1_3d=new((/50,70/),"graphic") 								
plot_dot2_3d=new((/50,70/),"graphic") 
plot_dot_diff_3d=new((/50,70/),"graphic") 
plot_hcenter1_3d=new((/50,70/),"graphic") 								
plot_hcenter2_3d=new((/50,70/),"graphic") 
plot_hcenter1_wind_3d=new((/50,70/),"graphic") 								
plot_hcenter2_wind_3d=new((/50,70/),"graphic") 

				
plot_1_2d=new((/50/),"graphic")			;store the 2d variable
plot_2_2d=new((/50/),"graphic")			
plot_diff_2d=new((/50/),"graphic") 		
plot_dot1_2d=new((/50/),"graphic") 			
plot_dot2_2d=new((/50/),"graphic") 
plot_dot_diff_2d=new((/50/),"graphic") 
plot_hcenter1_2d=new((/50/),"graphic") 
plot_hcenter2_2d=new((/50/),"graphic") 						
plot_hcenter1_wind_2d=new((/50/),"graphic") 
plot_hcenter2_wind_2d=new((/50/),"graphic") 	

contour_data_1_3d=new((/50,70/),"graphic")		;(variable,level)
contour_data_2_3d=new((/50,70/),"graphic")			
contour_diff_3d=new((/50,70/),"graphic")	
contour_data_1_2d=new((/70/),"graphic")		
contour_data_2_2d=new((/70/),"graphic")			
contour_diff_2d=new((/70/),"graphic")	
plot3=new((/50,70/),"graphic") 			;height or pressure 
plot4=new((/50,70/),"graphic") 
plot5=new((/50,70/),"graphic")

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

;--------
;new time name
;-----------
time_name=new((/ntimes/),"string")
time_name2=new((/ntimes/),"string")
do it=0,ntimes-1
	time_name(it)=substring(filename(it),11,29)
	time_name2(it)=substring(filename(it),19,20)+substring(filename(it),22,23)
end do

;=========
; count the total number of overlay variables before go to the variable loop
;===========
last_overlay_id=999
total_num_overlay_3d=0
total_num_overlay_diff_3d=0
total_num_overlay_2d=0
total_num_overlay_diff_2d=0
var_numbers=dimsizes(var_name)	
	
do id=0,var_numbers-1

	if(isoverlay(id))then
	  if(.not.if_2d_var(id))then
		total_num_overlay_3d=total_num_overlay_3d+1
	  else
	  	total_num_overlay_2d=total_num_overlay_2d+1
	  end if
	end if

	if(isoverlay_diff(id))then
	   if(.not.if_2d_var(id))then
	       total_num_overlay_diff_3d=total_num_overlay_diff_3d+1
 	   else
	       total_num_overlay_diff_2d=total_num_overlay_diff_2d+1	
	   end if
	end if		
end do

restart_files=False
do id=0,var_numbers-1
	if(in_restart_file(id))then
		restart_files=True
	end if
end do

;============
;begin the time loop
;==============  
do it=start_time,time_end,time_step			;go to 2000
	; filename_a=dir_a+filename(it)+"_prior"+".nc"		;???######?? this is for the diff in the da cycle
	;  filename_b=dir_b+filename(it)+"_prior"+".nc"
	; filename_a=dir_a+filename(it)+".post"+".nc"		
	;filename_b=dir_b+filename(it)+".post"+".nc"
	;filename_b=dir_b+"/wrfinput_d01.nc"
	filename_a=dir_a+filename(it)+".nc"			; this is for the forecast stage
	filename_b=dir_b+filename(it)+".nc"

	a=addfile(filename_a, "r") 
	b=addfile(filename_b, "r") 
	print(filename_a)
	print(filename_b)

	if restart_files then	;need to read the restart file
		filename_t=str_sub_str(filename(it),"wrfout","wrfrst")
		filename_c=dir_a+filename_t+".nc"			
		filename_d=dir_b+filename_t+".nc"
		c=addfile(filename_c, "r") 
		d=addfile(filename_d, "r") 
		print(filename_c)
		print(filename_d)
	end if
	;-----------
	;print time information
	;---------------
	times = wrf_user_getvar(a,"times",-1)  
	print("Working on time: " + times(0) )


	;----------------
	;get dimension, and create the new variable here   
	;--------------
if(it.eq.start_time)then

	p  = wrf_user_getvar(a, "pressure",0)	
	dim2=dimsizes(p)
	klev=dim2(0)
	nlat=dim2(1)
	mlon=dim2(2)

	;for 2D average
	data_1_avgdomain_2d=new((/ntimes,50/),"float")
	data_2_avgdomain_2d=new((/ntimes,50/),"float")
	if have_diff then
		diff_avgdomain_2d=new((/ntimes,50/),"float")
		diff_percentage_avgdomain_2d=new((/ntimes,50/),"float")
	end if

	;for 3D average
	nheight=dimsizes(height_lev)  	; find the index according to the specified height
				;model level
	data_1_avgdomain_3d_modellevel=new((/ntimes,50,klev/),"float")
	data_2_avgdomain_3d_modellevel=new((/ntimes,50,klev/),"float")
	if have_diff then
		diff_avgdomain_3d_modellevel=new((/ntimes,50,klev/),"float")
		diff_percentage_avgdomain_3d_modellevel=new((/ntimes,50,klev/),"float")
	end if
				;pressure level
	data_1_avgdomain_3d=new((/ntimes,50,nheight/),"float")
	data_2_avgdomain_3d=new((/ntimes,50,nheight/),"float")
	if have_diff then
		diff_avgdomain_3d=new((/ntimes,50,nheight/),"float")
		diff_percentage_avgdomain_3d=new((/ntimes,50,nheight/),"float")
	end if

	;--------------------
	; calculate model height
	;---------------------------
	if average_around_center then
		lon_tmp_e=clon_a(start_time)+deviation_from_center
		lon_tmp_w=clon_a(start_time)-deviation_from_center
		lat_tmp_n=clat_a(start_time)+deviation_from_center
		lat_tmp_s=clat_a(start_time)-deviation_from_center
		loc1 = wrf_user_ll_to_ij(a, lon_tmp_w, lat_tmp_n, True)
		loc2 = wrf_user_ll_to_ij(a, lon_tmp_e, lat_tmp_s, True)
		x_start = loc1(0) 
		x_end   = loc2(0) 
		y_start = loc2(1) 
		y_end   = loc1(1) 


		h_profile=dim_avg_n(p(:,y_start:y_end,x_start:x_end),(/1,2/))			 ;pressure , hPa

		model_vertical_index=new((/nheight/),"integer")

		do k=0,nheight-1
			model_vertical_index(k)=closest_val(height_lev(k),h_profile)
		end do

		level_info2=new((/nheight/),"string")
		do k=0,nheight-1
			level_info2(k) = height_lev(k) + "hPa"
		end do
	end if

end if

	;================
	; get the variable
	;==================
	xlat = a->XLAT(0,:,:)
	xlon = a->XLONG(0,:,:)
	z  = wrf_user_getvar(a, "z",0)      
	p  = wrf_user_getvar(a, "pressure",0)
	p@lon2d=xlon
	p@lat2d=xlat
	z@lon2d=xlon
	z@lat2d=xlat
	dx = a@DX ;[m]		;36000
	dy = a@DY ;[m]

	;=============
	; domain information , for average later
	;==================
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

	loc1 = wrf_user_ll_to_ij(a, minlon, maxlat, True)
	loc2 = wrf_user_ll_to_ij(a, maxlon, minlat, True)

	x_start = loc1(0) - 1
	x_end   = loc2(0) - 1
	y_start = loc2(1) - 1
	y_end   = loc1(1) - 1


	;==========================
	; map information
	;============================

	opts=True
 	opts@mpProjection ="CylindricalEquidistant"
 	;pl@LatLonOverlay = True
    opts@mpMaxLonF=maxlon
	opts@mpMinLonF=minlon
	opts@mpMaxLatF=maxlat
	opts@mpMinLatF=minlat
	
	opts@mpLimitMode="LatLon"
    opts@mpGridAndLimbOn=True
    opts@mpGridLineDashPattern =2
    opts@mpGridAndLimbDrawOrder ="PostDraw"
    opts@mpGridLineThicknessF=1.0
	opts@mpGridSpacingF =10. 
	opts@pmTickMarkDisplayMode = "Always"
	opts@tmXTOn=False				;tick turn off at the top of the figure
	opts@mpGridLineDashSegLenF=0.08


	;====================
	; default resources for the plot
	;=========================

	opts@gsnFrame= False
	opts@gsnDraw = False
	opts@gsnMaximize=False	
	opts@tiMainString=" "	; filename(it)
			;---------------
			; for contour  
			;--------------- 
	opts_cn=opts     
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

	opts_sh=opts
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
	opts_vc=opts
	;opts_vc@gsnAddCyclic            = False            ; regional data 
	opts_vc@vcRefMagnitudeF         = 10.0             ; define vector ref mag
	opts_vc@vcRefLengthF            = 0.028            ; define length of vec ref
	;opts_vc@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
	opts_vc@vcGlyphStyle   ="WindBarb"
	opts_vc@vcMinDistanceF          = 0.03		;control the density 0.035
	opts_vc@vcWindBarbLineThicknessF=1.1

			;------------
			; for stream line
			;---------------
	opts_str=opts
	opts_str@stArrowLengthF     = 0.005                ; arrwo size, default is dynamic
	opts_str@stArrowStride      = 4
	;opts_str@stLengthCheckCount = 15                   ; default is 35
	;opts_str@stMinArrowSpacingF = 0.001               ; default is 0.0             
	;opts_str@stStepSizeF        = 0.001                ; default is dynamic

	opts_str@stLineThicknessF=0.5
	if nest then
		opts_str@stMinDistanceF=0.05
	else
		opts_str@stMinDistanceF=0.05
	end if



	;======================
	; loop over variable
	;=====================
	num_overlay_3d=0	   ;this is the initial value for the next variable loop, it will increase one when meet one overlay variable
	num_overlay_diff_3d=0
	num_overlay_2d=0		
	num_overlay_diff_2d=0

	do var_id=0,var_numbers-1,1		;go to 3000

		print("Working on Variable  "+var_name(var_id))
		if(var_name(var_id) .ne. "wind_speed" .and. var_name(var_id) .ne. "wind_vector" .and. var_name(var_id) .ne."wind_vector_2d" \
			.and. var_name(var_id) .ne. "wind_speed_2d".and. var_name(var_id) .ne. "t_td" .and.  var_name(var_id) .ne. "rvo" \
			.and. var_name(var_id) .ne. "aod" .and. var_name(var_id) .ne. "total_dust" .and.var_name(var_id) .ne. "ACHFX2" \
			.and.var_name(var_id) .ne. "ACLHF2" .and.var_name(var_id) .ne. "ACSWUPB2" .and.var_name(var_id) .ne. "ACSWUPBC2" \		
			.and.var_name(var_id) .ne. "ACSWDNB2" .and.var_name(var_id) .ne. "ACSWDNBC2" .and.var_name(var_id) .ne. "ACLWUPB2" \	
			.and.var_name(var_id) .ne. "ACLWUPBC2" .and.var_name(var_id) .ne. "ACLWDNB2" .and.var_name(var_id) .ne. "ACLWDNBC2" \
			.and.var_name(var_id) .ne. "ACGRDFLX2".and.var_name(var_id) .ne. "net_ground_total".and.var_name(var_id) .ne. "net_sw_down"\
			.and.var_name(var_id) .ne. "net_lw_down".and.var_name(var_id) .ne. "net_sw_lw_down" .and.var_name(var_id) .ne. "achfx2_aclhfx2"\
			.and.var_name(var_id) .ne. "mcape".and.var_name(var_id).ne."shear_vector".and.var_name(var_id).ne."rh_mean"\
			.and.var_name(var_id).ne."shear_wind_speed".and. var_name(var_id) .ne. "snow_graup".and.var_name(var_id) .ne. "AEJ_max"\
			.and.var_name(var_id) .ne. "AEJ_avg".and.var_name(var_id) .ne. "min_slp".and.var_name(var_id) .ne. "max_wind"\
			.and.var_name(var_id) .ne. "surface_max_wind")then

;read common variables , not wind variables, not the variable you calculate,;????##### add your calculation variable name here to exclude them  
			if .not. in_restart_file(var_id) then
				data_1 = wrf_user_getvar(a,var_name(var_id),0) 			

				if(exist_both_file(var_id) )then
					data_2 = wrf_user_getvar(b,var_name(var_id),0)
				else							
					data_2=data_1                   ;???##### if that variable is not present in data_2,then just copy data_1 to data_2
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
		;==========================================
		;????###### add your variable calculation in the following section
		;=======================================

		if(var_name(var_id).eq."T2".or. var_name(var_id).eq."SST".or. var_name(var_id).eq."TSK".or. var_name(var_id).eq."TSK_SAVE")then
			data_1=data_1-273.16 
			data_2=data_2-273.16 
			data_1@units = "C"
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

		if(var_name(var_id).eq."mcape")then	
			mcape1 = wrf_user_getvar(a,"cape_2d",0) 
			data_1=mcape1(0,:,:)
			mcape2 = wrf_user_getvar(b,"cape_2d",0) 
			data_2=mcape2(0,:,:)	
			data_1@units="J/kg"
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

		;-----------------
		;accumulated variables			;?? when plot the varible within 1hr from the 
				;accumulated variable, in the namelist,need to include one hour before the hour you want to plot
		;------------------
		if(var_name(var_id).eq."ACHFX2")then		

			if(it.eq.start_time)then
				data_1_ACHFX=new((/ntimes,nlat,mlon/),"float")
				data_2_ACHFX=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACHFX(it,:,:)=wrf_user_getvar(a,"ACHFX",0)
				data_2_ACHFX(it,:,:)=wrf_user_getvar(b,"ACHFX",0)

			if(it.eq.start_time)then
				data_1=data_1_ACHFX(it,:,:)	
				data_2=data_2_ACHFX(it,:,:)
			else
				data_1=data_1_ACHFX(it,:,:)-data_1_ACHFX(it-1,:,:)
				data_2=data_2_ACHFX(it,:,:)-data_2_ACHFX(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACLHF2")then		

			if(it.eq.start_time)then
				data_1_ACLHF=new((/ntimes,nlat,mlon/),"float")
				data_2_ACLHF=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACLHF(it,:,:)=wrf_user_getvar(a,"ACLHF",0)
				data_2_ACLHF(it,:,:)=wrf_user_getvar(b,"ACLHF",0)

			if(it.eq.start_time)then
				data_1=data_1_ACLHF(it,:,:)
				data_2=data_2_ACLHF(it,:,:)
			else
				data_1=data_1_ACLHF(it,:,:)-data_1_ACLHF(it-1,:,:)
				data_2=data_2_ACLHF(it,:,:)-data_2_ACLHF(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if


		if(var_name(var_id).eq."achfx2_aclhfx2")then		

			if(it.eq.start_time)then
				data_1_hfx_lhfx=new((/ntimes,nlat,mlon/),"float")
				data_2_hfx_lhfx=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_hfx_lhfx(it,:,:)=wrf_user_getvar(a,"ACHFX",0)+wrf_user_getvar(a,"ACLHF",0)
				data_2_hfx_lhfx(it,:,:)=wrf_user_getvar(b,"ACHFX",0)+wrf_user_getvar(b,"ACLHF",0)

			if(it.eq.start_time)then
				data_1=data_1_hfx_lhfx(it,:,:)
				data_2=data_2_hfx_lhfx(it,:,:)
			else
				data_1=data_1_hfx_lhfx(it,:,:)-data_1_hfx_lhfx(it-1,:,:)
				data_2=data_2_hfx_lhfx(it,:,:)-data_2_hfx_lhfx(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACSWUPB2")then		

			if(it.eq.start_time)then
				data_1_ACSWUPB=new((/ntimes,nlat,mlon/),"float")
				data_2_ACSWUPB=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACSWUPB(it,:,:)=wrf_user_getvar(a,"ACSWUPB",0)
				data_2_ACSWUPB(it,:,:)=wrf_user_getvar(b,"ACSWUPB",0)

			if(it.eq.start_time)then
				data_1=data_1_ACSWUPB(it,:,:)
				data_2=data_2_ACSWUPB(it,:,:)
			else
				data_1=data_1_ACSWUPB(it,:,:)-data_1_ACSWUPB(it-1,:,:)
				data_2=data_2_ACSWUPB(it,:,:)-data_2_ACSWUPB(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACSWUPBC2")then		

			if(it.eq.start_time)then
				data_1_ACSWUPBC=new((/ntimes,nlat,mlon/),"float")
				data_2_ACSWUPBC=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACSWUPBC(it,:,:)=wrf_user_getvar(a,"ACSWUPBC",0)
				data_2_ACSWUPBC(it,:,:)=wrf_user_getvar(b,"ACSWUPBC",0)

			if(it.eq.start_time)then
				data_1=data_1_ACSWUPBC(it,:,:)
				data_2=data_2_ACSWUPBC(it,:,:)
			else
				data_1=data_1_ACSWUPBC(it,:,:)-data_1_ACSWUPBC(it-1,:,:)
				data_2=data_2_ACSWUPBC(it,:,:)-data_2_ACSWUPBC(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACSWDNB2")then		

			if(it.eq.start_time)then
				data_1_ACSWDNB=new((/ntimes,nlat,mlon/),"float")
				data_2_ACSWDNB=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACSWDNB(it,:,:)=wrf_user_getvar(a,"ACSWDNB",0)
				data_2_ACSWDNB(it,:,:)=wrf_user_getvar(b,"ACSWDNB",0)

			if(it.eq.start_time)then
				data_1=data_1_ACSWDNB(it,:,:)
				data_2=data_2_ACSWDNB(it,:,:)
			else
				data_1=data_1_ACSWDNB(it,:,:)-data_1_ACSWDNB(it-1,:,:)
				data_2=data_2_ACSWDNB(it,:,:)-data_2_ACSWDNB(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACSWDNBC2")then		

			if(it.eq.start_time)then
				data_1_ACSWDNBC=new((/ntimes,nlat,mlon/),"float")
				data_2_ACSWDNBC=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACSWDNBC(it,:,:)=wrf_user_getvar(a,"ACSWDNBC",0)
				data_2_ACSWDNBC(it,:,:)=wrf_user_getvar(b,"ACSWDNBC",0)

			if(it.eq.start_time)then
				data_1=data_1_ACSWDNBC(it,:,:)
				data_2=data_2_ACSWDNBC(it,:,:)
			else
				data_1=data_1_ACSWDNBC(it,:,:)-data_1_ACSWDNBC(it-1,:,:)
				data_2=data_2_ACSWDNBC(it,:,:)-data_2_ACSWDNBC(it-1,:,:)
			end if	
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACLWUPB2")then		

			if(it.eq.start_time)then
				data_1_ACLWUPB=new((/ntimes,nlat,mlon/),"float")
				data_2_ACLWUPB=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACLWUPB(it,:,:)=wrf_user_getvar(a,"ACLWUPB",0)
				data_2_ACLWUPB(it,:,:)=wrf_user_getvar(b,"ACLWUPB",0)

			if(it.eq.start_time)then
				data_1=data_1_ACLWUPB(it,:,:)
				data_2=data_2_ACLWUPB(it,:,:)
			else
				data_1=data_1_ACLWUPB(it,:,:)-data_1_ACLWUPB(it-1,:,:)
				data_2=data_2_ACLWUPB(it,:,:)-data_2_ACLWUPB(it-1,:,:)
			end if	
		data_1@units="J m-2"
		data_2@units="J m-2"		
		end if

		if(var_name(var_id).eq."ACLWUPBC2")then		

			if(it.eq.start_time)then
				data_1_ACLWUPBC=new((/ntimes,nlat,mlon/),"float")
				data_2_ACLWUPBC=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACLWUPBC(it,:,:)=wrf_user_getvar(a,"ACLWUPBC",0)
				data_2_ACLWUPBC(it,:,:)=wrf_user_getvar(b,"ACLWUPBC",0)

			if(it.eq.start_time)then
				data_1=data_1_ACLWUPBC(it,:,:)
				data_2=data_2_ACLWUPBC(it,:,:)
			else
				data_1=data_1_ACLWUPBC(it,:,:)-data_1_ACLWUPBC(it-1,:,:)
				data_2=data_2_ACLWUPBC(it,:,:)-data_2_ACLWUPBC(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACLWDNB2")then		

			if(it.eq.start_time)then
				data_1_ACLWDNB=new((/ntimes,nlat,mlon/),"float")
				data_2_ACLWDNB=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACLWDNB(it,:,:)=wrf_user_getvar(a,"ACLWDNB",0)
				data_2_ACLWDNB(it,:,:)=wrf_user_getvar(b,"ACLWDNB",0)

			if(it.eq.start_time)then
				data_1=data_1_ACLWDNB(it,:,:)
				data_2=data_2_ACLWDNB(it,:,:)
			else
				data_1=data_1_ACLWDNB(it,:,:)-data_1_ACLWDNB(it-1,:,:)
				data_2=data_2_ACLWDNB(it,:,:)-data_2_ACLWDNB(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACLWDNBC2")then		

			if(it.eq.start_time)then
				data_1_ACLWDNBC=new((/ntimes,nlat,mlon/),"float")
				data_2_ACLWDNBC=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACLWDNBC(it,:,:)=wrf_user_getvar(a,"ACLWDNBC",0)
				data_2_ACLWDNBC(it,:,:)=wrf_user_getvar(b,"ACLWDNBC",0)

			if(it.eq.start_time)then
				data_1=data_1_ACLWDNBC(it,:,:)
				data_2=data_2_ACLWDNBC(it,:,:)
			else
				data_1=data_1_ACLWDNBC(it,:,:)-data_1_ACLWDNBC(it-1,:,:)
				data_2=data_2_ACLWDNBC(it,:,:)-data_2_ACLWDNBC(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."ACGRDFLX2")then		

			if(it.eq.start_time)then
				data_1_ACGRDFLX=new((/ntimes,nlat,mlon/),"float")
				data_2_ACGRDFLX=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_ACGRDFLX(it,:,:)=wrf_user_getvar(a,"ACGRDFLX",0)
				data_2_ACGRDFLX(it,:,:)=wrf_user_getvar(b,"ACGRDFLX",0)

			if(it.eq.start_time)then
				data_1=data_1_ACGRDFLX(it,:,:)
				data_2=data_2_ACGRDFLX(it,:,:)
			else
				data_1=data_1_ACGRDFLX(it,:,:)-data_1_ACGRDFLX(it-1,:,:)
				data_2=data_2_ACGRDFLX(it,:,:)-data_2_ACGRDFLX(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."net_sw_down")then		

			if(it.eq.start_time)then
				data_1_net_sw_down=new((/ntimes,nlat,mlon/),"float")
				data_2_net_sw_down=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_net_sw_down(it,:,:)=wrf_user_getvar(a,"ACSWDNB",0)-wrf_user_getvar(a,"ACSWUPB",0)
				data_2_net_sw_down(it,:,:)=wrf_user_getvar(b,"ACSWDNB",0)-wrf_user_getvar(b,"ACSWUPB",0)


			if(it.eq.start_time)then
				data_1=data_1_net_sw_down(it,:,:)
				data_2=data_2_net_sw_down(it,:,:)
			else
				data_1=data_1_net_sw_down(it,:,:)-data_1_net_sw_down(it-1,:,:)
				data_2=data_2_net_sw_down(it,:,:)-data_2_net_sw_down(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."net_lw_down")then		

			if(it.eq.start_time)then
				data_1_net_lw_down=new((/ntimes,nlat,mlon/),"float")
				data_2_net_lw_down=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_net_lw_down(it,:,:)=wrf_user_getvar(a,"ACLWDNB",0)-wrf_user_getvar(a,"ACLWUPB",0)
				data_2_net_lw_down(it,:,:)=wrf_user_getvar(b,"ACLWDNB",0)-wrf_user_getvar(b,"ACLWUPB",0)


			if(it.eq.start_time)then
				data_1=data_1_net_lw_down(it,:,:)
				data_2=data_2_net_lw_down(it,:,:)
			else
				data_1=data_1_net_lw_down(it,:,:)-data_1_net_lw_down(it-1,:,:)
				data_2=data_2_net_lw_down(it,:,:)-data_2_net_lw_down(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if

		if(var_name(var_id).eq."net_sw_lw_down")then		

			if(it.eq.start_time)then
				data_1_net_sw_lw_down=new((/ntimes,nlat,mlon/),"float")
				data_2_net_sw_lw_down=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_net_sw_lw_down(it,:,:)=wrf_user_getvar(a,"ACSWDNB",0)-wrf_user_getvar(a,"ACSWUPB",0)+wrf_user_getvar(a,"ACLWDNB",0)-wrf_user_getvar(a,"ACLWUPB",0)
				data_2_net_sw_lw_down(it,:,:)=wrf_user_getvar(b,"ACSWDNB",0)-wrf_user_getvar(b,"ACSWUPB",0)+wrf_user_getvar(b,"ACLWDNB",0)-wrf_user_getvar(b,"ACLWUPB",0)


			if(it.eq.start_time)then
				data_1=data_1_net_sw_lw_down(it,:,:)
				data_2=data_2_net_sw_lw_down(it,:,:)
			else
				data_1=data_1_net_sw_lw_down(it,:,:)-data_1_net_sw_lw_down(it-1,:,:)
				data_2=data_2_net_sw_lw_down(it,:,:)-data_2_net_sw_lw_down(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if


		if(var_name(var_id).eq."net_ground_total")then		
									;??## not completed yet, the energy is not balance here, why?
			if(it.eq.start_time)then
				data_1_net_ground_total=new((/ntimes,nlat,mlon/),"float")
				data_2_net_ground_total=new((/ntimes,nlat,mlon/),"float")
			end if

				data_1_net_ground_total(it,:,:)=wrf_user_getvar(a,"ACSWDNB",0)-wrf_user_getvar(a,"ACSWUPB",0)+wrf_user_getvar(a,"ACLWDNB",0)-wrf_user_getvar(a,"ACLWUPB",0)-wrf_user_getvar(a,"ACHFX",0)-wrf_user_getvar(a,"ACLHF",0)-wrf_user_getvar(a,"ACGRDFLX",0)
				data_2_net_ground_total(it,:,:)=wrf_user_getvar(b,"ACSWDNB",0)-wrf_user_getvar(b,"ACSWUPB",0)+wrf_user_getvar(b,"ACLWDNB",0)-wrf_user_getvar(b,"ACLWUPB",0)-wrf_user_getvar(b,"ACHFX",0)-wrf_user_getvar(b,"ACLHF",0)-wrf_user_getvar(b,"ACGRDFLX",0)
	

  			if(it.eq.start_time)then
				data_1=data_1_net_ground_total(it,:,:)
				data_2=data_2_net_ground_total(it,:,:)
			else
				data_1=data_1_net_ground_total(it,:,:)-data_1_net_ground_total(it-1,:,:)
				data_2=data_2_net_ground_total(it,:,:)-data_2_net_ground_total(it-1,:,:)
			end if
		data_1@units="J m-2"
		end if


		;-------------------
		;AOD
		;--------------------
		if(var_name(var_id).eq."aod")then

			ext_1=wrf_user_getvar(a,"EXTCOF55",0)
			ext_2=wrf_user_getvar(b,"EXTCOF55",0)

			ph1=wrf_user_getvar(a,"PH",0)
			phb1=wrf_user_getvar(a,"PHB",0)
			zz1=(ph1+phb1)/9.81/1000
			ph2=wrf_user_getvar(b,"PH",0)
			phb2=wrf_user_getvar(b,"PHB",0)
			zz2=(ph2+phb2)/9.81/1000

			dsizes_x = dimsizes(zz1)
			klev     = dsizes_x(0)
			nlat     = dsizes_x(1)
			mlon     = dsizes_x(2)

			dz1=zz1(1:klev-1,:,:)-zz1(0:klev-2,:,:)
			dz2=zz2(1:klev-1,:,:)-zz2(0:klev-2,:,:)

			data_1=dim_sum_n(ext_1*dz1,0)
			data_2=dim_sum_n(ext_2*dz2,0)
			data_1@units=" "

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
		data_1@units="10-5 s-1"
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
		    oina01_b = wrf_user_getvar(b,"oin_a01",0)
		    oina02_b = wrf_user_getvar(b,"oin_a02",0)
		    oina03_b = wrf_user_getvar(b,"oin_a03",0)
		    oina04_b = wrf_user_getvar(b,"oin_a04",0)
		    oina05_b = wrf_user_getvar(b,"oin_a05",0)
		    oina06_b = wrf_user_getvar(b,"oin_a06",0)
		    oina07_b = wrf_user_getvar(b,"oin_a07",0)
		    oina08_b = wrf_user_getvar(b,"oin_a08",0)
		    data_1=oina01_a+oina02_a+oina03_a+oina04_a+oina05_a+oina06_a+oina07_a+oina08_a
		    data_2=oina01_b+oina02_b+oina03_b+oina04_b+oina05_b+oina06_b+oina07_b+oina08_b
		data_1@units="ug/kg-dryair"
		end if

		if(var_name(var_id) .eq. "rh_mean" )then

			p=wrf_user_getvar(a,"pressure",0) 
			p_avg=   dim_avg_n(p, (/1,2/))  
		    lower_index=closest_val(700,p_avg) 
			upper_index=closest_val(500,p_avg) 

			rh_temp_a=wrf_user_getvar(a,"rh",0) 
			rh_mean_a=dim_avg_n(rh_temp_a(lower_index:upper_index,:,:),(/0/))
			rh_temp_b=wrf_user_getvar(b,"rh",0) 
			rh_mean_b=dim_avg_n(rh_temp_b(lower_index:upper_index,:,:),(/0/))
		
			data_1=rh_mean_a
			data_2=rh_mean_b
			data_1@units="%"
		end if


		;-----------
		;wind speed
		;------------
		if(var_name(var_id) .eq. "wind_speed" )then
				u1=wrf_user_getvar(a,"ua",0) 
				v1=wrf_user_getvar(a,"va",0)
				wind_speed_1=sqrt(u1^2+v1^2)
				data_1 = wind_speed_1
				u2=wrf_user_getvar(b,"ua",0)
				v2=wrf_user_getvar(b,"va",0) 
				wind_speed_2=sqrt(u2^2+v2^2)	
				data_2 = wind_speed_2			
				data_1@units = "m/s"
		end if

		if(var_name(var_id) .eq. "AEJ_max" .or.var_name(var_id) .eq. "AEJ_avg")then
			p=wrf_user_getvar(a,"pressure",0) 
			p_avg=   dim_avg_n(p, (/1,2/))  

		    L1=closest_val(600,p_avg) 
		    L2=closest_val(550,p_avg) 
		    L3=closest_val(500,p_avg)
 
			u1=wrf_user_getvar(a,"ua",0) 
			v1=wrf_user_getvar(a,"va",0)
			wind_speed_1=sqrt(u1^2+v1^2) 

			u2=wrf_user_getvar(b,"ua",0)
			v2=wrf_user_getvar(b,"va",0) 
			wind_speed_2=sqrt(u2^2+v2^2)
	
			AEJ_1=(wind_speed_1(L1,:,:)+wind_speed_1(L2,:,:)+wind_speed_1(L3,:,:))/3
			AEJ_2=(wind_speed_2(L1,:,:)+wind_speed_2(L2,:,:)+wind_speed_2(L3,:,:))/3
			data_1 = AEJ_1
			data_2 = AEJ_2			
			data_1@units = "m/s"
		end if

		if(var_name(var_id) .eq. "wind_speed_2d" )then
				u_2d_1=wrf_user_getvar(a,"U10",0) 
				v_2d_1=wrf_user_getvar(a,"V10",0)
				data_1 = sqrt(u_2d_1^2+v_2d_1^2)
				u_2d_2=wrf_user_getvar(b,"U10",0)
				v_2d_2=wrf_user_getvar(b,"V10",0) 
				data_2 = sqrt(u_2d_2^2+v_2d_2^2)
				data_1@units = "m/s"
		end if


		;-----------
		;wind vector
		;------------
		if(var_name(var_id) .eq. "wind_vector" )then
				data_1_uu=wrf_user_getvar(a,"ua",0) 
				data_1_vv=wrf_user_getvar(a,"va",0)
				data_2_uu=wrf_user_getvar(b,"ua",0)
				data_2_vv=wrf_user_getvar(b,"va",0)

		end if

		if(var_name(var_id) .eq. "wind_vector_2d" )then
				data_1_uu=wrf_user_getvar(a,"U10",0) 
				data_1_vv=wrf_user_getvar(a,"V10",0)
				data_2_uu=wrf_user_getvar(b,"U10",0)
				data_2_vv=wrf_user_getvar(b,"V10",0)
		end if

		if(var_name(var_id) .eq. "shear_vector" .or. var_name(var_id) .eq. "shear_wind_speed" )then

				p=wrf_user_getvar(a,"pressure",0) 
				p_avg=   dim_avg_n(p, (/1,2/))  
			    lower_index=closest_val(850,p_avg) 
				upper_index=closest_val(200,p_avg) 

				ua_temp_a=wrf_user_getvar(a,"ua",0) 
				va_temp_a=wrf_user_getvar(a,"va",0) 
				shear_uu_a=ua_temp_a(upper_index,:,:)-ua_temp_a(lower_index,:,:)
				shear_vv_a=va_temp_a(upper_index,:,:)-va_temp_a(lower_index,:,:)
				data_1_uu=shear_uu_a
				data_1_vv=shear_vv_a

				ua_temp_b=wrf_user_getvar(b,"ua",0) 
				va_temp_b=wrf_user_getvar(b,"va",0) 
				shear_uu_b=ua_temp_b(upper_index,:,:)-ua_temp_b(lower_index,:,:)
				shear_vv_b=va_temp_b(upper_index,:,:)-va_temp_b(lower_index,:,:)
				data_2_uu=shear_uu_b
				data_2_vv=shear_vv_b
				if(var_name(var_id) .eq. "shear_wind_speed" )then
					
					data_1 = sqrt(data_1_uu^2+data_1_vv^2)
					data_2 = sqrt(data_2_uu^2+data_2_vv^2)
					data_1@units = "m/s"
				end if
		end if

		if(var_name(var_id) .eq. "min_slp" .or. var_name(var_id) .eq. "max_wind"  .or. var_name(var_id) .eq. "surface_max_wind" )then
			data_1=0.
			data_2=0.
		end if

		;--------------------
		; get the difference
		;-------------------------
		if have_diff then
			if(var_name(var_id) .eq. "wind_vector" .or.  var_name(var_id) .eq."wind_vector_2d" .or.var_name(var_id) .eq."shear_vector")then
		   		diff_uu=data_1_uu-data_2_uu
		   		diff_vv=data_1_vv-data_2_vv	
			else
				diff=data_1-data_2
			end if
		end if

		;=============
		; end of adding variable calculation
		;===============

		;-------------
		; data dimension information
		;------------------
		if .not. if_2d_var(var_id) then
			if(var_name(var_id) .eq. "wind_vector" .or.  var_name(var_id) .eq."wind_vector_2d" .or.var_name(var_id) .eq."shear_vector")then
				dimmm=dimsizes(data_1_uu)

			else
				dimmm=dimsizes(data_1)
			end if
			klev=dimmm(0)
			nlat=dimmm(1)
			mlon=dimmm(2)
		end if

		;-------------
		; assign units
		;-------------
		if(var_name(var_id) .ne."wind_vector_2d" .and. var_name(var_id) .ne."wind_vector".and.var_name(var_id) .ne."shear_vector")then
			units(var_id)=data_1@units
		else
			units(var_id)=" "
		end if

		;========================
		; give coordinate
		;=======================
		if(var_name(var_id) .ne."wind_vector_2d" .and. var_name(var_id) .ne."wind_vector".and.var_name(var_id) .ne."shear_vector")then
			data_1@lon2d=xlon
			data_1@lat2d=xlat
			data_2@lon2d=xlon
			data_2@lat2d=xlat
			if have_diff then
				diff@lon2d=xlon
				diff@lat2d=xlat
			end if
		else
			data_1_uu@lon2d=xlon
			data_1_uu@lat2d=xlat
			data_1_vv@lon2d=xlon
			data_1_vv@lat2d=xlat
			data_2_uu@lon2d=xlon
			data_2_uu@lat2d=xlat
			data_2_vv@lon2d=xlon
			data_2_vv@lat2d=xlat	
			if have_diff then
				diff_uu@lon2d=xlon
				diff_uu@lat2d=xlat
				diff_vv@lon2d=xlon
				diff_vv@lat2d=xlat
			end if
		end if
																					   
		;===============
		; count the number of the overlay variables up to current time
		;=================

		if(isoverlay(var_id))then
			if(.not.if_2d_var(var_id))then
				num_overlay_3d=num_overlay_3d+1			;for data_1,data_2
			else
				num_overlay_2d=num_overlay_2d+1		
			end if
		end if

		if have_diff then
			if(isoverlay_diff(var_id))then
				if(.not.if_2d_var(var_id))then
					num_overlay_diff_3d=num_overlay_diff_3d+1	;for diff
				else
					num_overlay_diff_2d=num_overlay_diff_2d+1	
				end if	
			end if			
		end if


		;=================
		; set to different resource for different variable	
		;===================
																				
		if(var_res(var_id) .eq. "sh" )then				
			opts=opts_sh
			opts@cnLevelSelectionMode =  "ManualLevels"
			;opts@cnLevelSelectionMode =  "AutomaticLevels"
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

		if(var_name(var_id) .eq. "tc" .or. var_name(var_id) .eq. "t_td" )then
		       opts@gsnContourNegLineDashPattern  =0
		end if

	
		;============================================
		; 	(AAAAAAA) 			3-D variable
		;================================================
		if(.not. if_2d_var(var_id) )then		;???#################  ;go to 4000 3d variable or 2d variable

		
																		
			if(level_type .eq. 1)then
				dimsv = dimsizes(p)          
				nlevels=dimsv(0)
				d_levels=5			;the interval of the levels ##############
			end if		

			if(level_type .eq.2)then					
				height_levels = (/ 15000,5000,3000,1500,250./)   ; in meter ;????################
				;height_levels =  (/	0, 200, 400, 600,  800, 1000,  2000, 3000, 4000,  5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000/)
				nlevels       = dimsizes(height_levels)  
				d_levels=1   						;????################
			end if

			if(level_type .eq.3)then	   
				;pressure_levels = (/100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,1000/)   		;????################	
				;pressure_levels = (/200, 300,  500, 600, 700, 800, 850,900, 1000/) 	
				;pressure_levels = (/ 500,700,850, 1000 /) 
				pressure_levels = (/ 850/)   	
				nlevels         = dimsizes(pressure_levels) 
				d_levels=1    							;????################
			end if

			if(var_name(var_id) .ne. "wind_vector" .and. var_name(var_id) .ne. "shear_vector")then
				data_1_plane=new((/nlevels,nlat,mlon/),"float")
				data_2_plane=new((/nlevels,nlat,mlon/),"float")
				diff_plane=new((/nlevels,nlat,mlon/),"float")
			else
				data_1_uu_plane=new((/nlevels,nlat,mlon/),"float")
				data_1_vv_plane=new((/nlevels,nlat,mlon/),"float")
				data_2_uu_plane=new((/nlevels,nlat,mlon/),"float")
				data_2_vv_plane=new((/nlevels,nlat,mlon/),"float")
				diff_uu_plane=new((/nlevels,nlat,mlon/),"float")
				diff_vv_plane=new((/nlevels,nlat,mlon/),"float")
			end if


			level_info=new((/nlevels/),"string")
		
			;===========================
			; loop over different levels 
			;===========================

			checkfile="echo working on time "+time_name(it)+"   variable "+var_name(var_id)+  ">>"+wks_name+".txt"
			if(.not.average_domain .and. .not.average_around_center)

				do level =0,nlevels-1,d_levels 		;go to 5000 loop over level		
					if (level  .eq. 1 .and. var_name(var_id) .eq. "tc") then
						;print("max="+max(diff(:,48:90,155:155)))		;????################
						;print("min="+min(diff(:,48:90,155:155)))
					end if

	
					;===============
					; title information  ; If your data has a long_name and units attribute, they will be placed in 
					;the gsnLeftString and gsnRightString respectively. You can turn these automatic labels off by setting the
					; string resource to a null string " ".
					;===============	
														
					if(level_type .eq.1)then	 
						level_info(level) = "Eta Level  " + level
					end if
					if(level_type .eq.2)then
						level_info(level) = height_levels(level)/1000. + "km"
					end if
					if(level_type .eq.3)then
						level_info(level) = pressure_levels(level) + "hPa"
					end if 
					print("working on"+ level_info(level) )

					checkfile="echo working on time "+time_name(it)+"   variable "+var_name(var_id)+" level"+level_info(level)+"  >>"+wks_name+".txt"
					system(checkfile)

					if .not. isoverlay(var_id) then
							opts@gsnLeftString = level_info(level)
							opts@gsnCenterString=var_name(var_id) 
							opts@gsnRightString= units(var_id) 				
					end if

					if isoverlay(var_id) then

						if (total_num_overlay_3d.eq.2) then
							if(var_id.eq.1)then
								opts@gsnLeftString = level_info(level)
								opts@gsnCenterString=var_name(0) +"~C~"+var_name(1) 
								opts@gsnRightString= units(0) +"~C~"+units(1) 	
							else
								opts@gsnLeftString = " "
								opts@gsnCenterString= " "
								opts@gsnRightString=  " "
							end if
						end if

						if (total_num_overlay_3d.eq.3) then
							if(var_id.eq.2)then
		
								opts@gsnLeftString =level_info(level)
								opts@gsnCenterString=var_name(0) +"~C~"+var_name(1) +"~C~"+var_name(2) +"~C~"
								opts@gsnRightString= units(0) +"~C~"+units(1) +"~C~"+units(2) +"~C~"	
							else
								opts@gsnLeftString = " "
								opts@gsnCenterString= " "
								opts@gsnRightString=  " "
							end if
						end if

					end if
		 
					;==============
					; interpolate
					;================

					;--------------------------------
					; (1) Model eta level, do not need to interpolate
					;--------------------------------
					if(level_type .eq.1)then	

						if(var_name(var_id) .ne. "wind_vector" .and. var_name(var_id) .ne. "shear_vector")then
							data_1_plane(level,:,:) =data_1(level,:,:)
							data_2_plane(level,:,:) =data_2(level,:,:)
							if have_diff then
								diff_plane(level,:,:)=diff(level,:,:)
							end if
						else
							data_1_uu_plane(level,:,:)  = data_1_uu(level,:,:)
							data_1_vv_plane(level,:,:)  = data_1_vv(level,:,:)
							data_2_uu_plane(level,:,:)  = data_2_uu(level,:,:)
							data_2_vv_plane(level,:,:)  = data_2_vv(level,:,:)
							if(var_res(var_id).eq."vc")then
								data_1_uu_plane(level,:,:) = data_1_uu_plane(level,:,:) *1.94386     ; kts
								data_1_vv_plane(level,:,:) = data_1_vv_plane(level,:,:) *1.94386     					
								data_2_uu_plane(level,:,:) = data_2_uu_plane(level,:,:) *1.94386     
								data_2_vv_plane(level,:,:) = data_2_vv_plane(level,:,:) *1.94386   
							else
								data_1_uu_plane(level,:,:) = data_1_uu_plane(level,:,:)  
								data_1_vv_plane(level,:,:) = data_1_vv_plane(level,:,:) 					
								data_2_uu_plane(level,:,:) = data_2_uu_plane(level,:,:)
								data_2_vv_plane(level,:,:) = data_2_vv_plane(level,:,:) 
							end if
  
							if have_diff then
								diff_uu_plane(level,:,:)=diff_uu(level,:,:)
								diff_vv_plane(level,:,:)=diff_vv(level,:,:)
								if(var_res(var_id).eq."vc")then
									diff_uu_plane(level,:,:) = diff_uu_plane(level,:,:) *1.94386    
									diff_vv_plane(level,:,:) = diff_vv_plane(level,:,:) *1.94386  
								else
									diff_uu_plane(level,:,:) = diff_uu_plane(level,:,:) 
									diff_vv_plane(level,:,:) = diff_vv_plane(level,:,:) 
								end if  
							end if
						end if

					end if

					;-----------
					; (2) Height
					;------------
					if(level_type .eq.2)then	

						height = height_levels(level)	; heitht_levels is an array, height is the element in the array
						p_plane  = wrf_user_intrp3d( p,z,"h",height,0.,False)
						p_plane@lon2d=xlon
						p_plane@lat2d=xlat
			
						if(var_name(var_id) .ne. "wind_vector".and. var_name(var_id) .ne. "shear_vector" )then
							data_1_plane(level,:,:)  = wrf_user_intrp3d( data_1,z,"h",height,0.,False) 
							data_2_plane(level,:,:) = wrf_user_intrp3d( data_2,z,"h",height,0.,False)
							if have_diff then
								diff_plane(level,:,:)=wrf_user_intrp3d( diff,z,"h",height,0.,False)
							end if
						else
							data_1_uu_plane(level,:,:)  = wrf_user_intrp3d( data_1_uu,z,"h",height,0.,False) 
							data_1_vv_plane(level,:,:)  = wrf_user_intrp3d( data_1_vv,z,"h",height,0.,False)
							data_2_uu_plane(level,:,:)  = wrf_user_intrp3d( data_2_uu,z,"h",height,0.,False) 
							data_2_vv_plane(level,:,:)  = wrf_user_intrp3d( data_2_vv,z,"h",height,0.,False)
							if(var_res(var_id).eq."vc")then
								data_1_uu_plane(level,:,:) = data_1_uu_plane(level,:,:) *1.94386     ; kts
								data_1_vv_plane(level,:,:) = data_1_vv_plane(level,:,:) *1.94386     
								data_2_uu_plane(level,:,:) = data_2_uu_plane(level,:,:) *1.94386     
								data_2_vv_plane(level,:,:) = data_2_vv_plane(level,:,:) *1.94386   
							else
  								data_1_uu_plane(level,:,:) = data_1_uu_plane(level,:,:)   
								data_1_vv_plane(level,:,:) = data_1_vv_plane(level,:,:)  
								data_2_uu_plane(level,:,:) = data_2_uu_plane(level,:,:)   
								data_2_vv_plane(level,:,:) = data_2_vv_plane(level,:,:)
							end if

							if have_diff then
								diff_uu_plane(level,:,:)=wrf_user_intrp3d( diff_uu,z,"h",height,0.,False)
								diff_vv_plane(level,:,:)=wrf_user_intrp3d( diff_vv,z,"h",height,0.,False)
							if(var_res(var_id).eq."vc")then
								diff_uu_plane(level,:,:) = diff_uu_plane(level,:,:) *1.94386    
								diff_vv_plane(level,:,:) = diff_vv_plane(level,:,:) *1.94386    
							else
								diff_uu_plane(level,:,:) = diff_uu_plane(level,:,:)    
								diff_vv_plane(level,:,:) = diff_vv_plane(level,:,:) 
							end if		
							end if			
						end if

					end if
					;-----------
					; (3) Pressure
					;------------
					if(level_type .eq.3)then	
						pressure = pressure_levels(level)		
						z_plane  = wrf_user_intrp3d( z,p,"h",pressure,0.,False)
						z_plane@lon2d=xlon
						z_plane@lat2d=xlat
						if(var_name(var_id) .ne. "wind_vector" .and. var_name(var_id) .ne. "shear_vector" )then	
							data_1_plane(level,:,:)  = wrf_user_intrp3d( data_1,p,"h",pressure,0.,False)
							data_2_plane(level,:,:)  = wrf_user_intrp3d( data_2,p,"h",pressure,0.,False)
							if have_diff then
								diff_plane(level,:,:)=wrf_user_intrp3d( diff,p,"h",pressure,0.,False)
							end if
						else
							data_1_uu_plane(level,:,:)  = wrf_user_intrp3d( data_1_uu,p,"h",pressure,0.,False)
							data_1_vv_plane(level,:,:)  = wrf_user_intrp3d( data_1_vv,p,"h",pressure,0.,False)
							data_2_uu_plane(level,:,:)  = wrf_user_intrp3d( data_2_uu,p,"h",pressure,0.,False)
							data_2_vv_plane(level,:,:)  = wrf_user_intrp3d( data_2_vv,p,"h",pressure,0.,False)

							if(var_res(var_id).eq."vc")then
								data_1_uu_plane(level,:,:) = data_1_uu_plane(level,:,:) *1.94386     ; kts
								data_1_vv_plane(level,:,:) = data_1_vv_plane(level,:,:) *1.94386     ; kts
								data_2_uu_plane(level,:,:) = data_2_uu_plane(level,:,:) *1.94386     ; kts
								data_2_vv_plane(level,:,:) = data_2_vv_plane(level,:,:) *1.94386     ; kts
							else
								data_1_uu_plane(level,:,:) = data_1_uu_plane(level,:,:) 
								data_1_vv_plane(level,:,:) = data_1_vv_plane(level,:,:) 
								data_2_uu_plane(level,:,:) = data_2_uu_plane(level,:,:) 
								data_2_vv_plane(level,:,:) = data_2_vv_plane(level,:,:) 
							end if

							if have_diff then
								diff_uu_plane(level,:,:)=wrf_user_intrp3d( diff_uu,p,"h",pressure,0.,False)
								diff_vv_plane(level,:,:)=wrf_user_intrp3d( diff_vv,p,"h",pressure,0.,False)
								if(var_res(var_id).eq."vc")then
									diff_uu_plane(level,:,:) = diff_uu_plane(level,:,:) *1.94386    
									diff_vv_plane(level,:,:) = diff_vv_plane(level,:,:) *1.94386   
								else
									diff_uu_plane(level,:,:) = diff_uu_plane(level,:,:) 
									diff_vv_plane(level,:,:) = diff_vv_plane(level,:,:) 
								end if	 
							end if

						end if
					end if

					;========================
					; give coordinate
					;=======================
					if(var_name(var_id) .ne."wind_vector_2d" .and. var_name(var_id) .ne."wind_vector".and.var_name(var_id) .ne."shear_vector")then
						data_1_plane@lon2d=xlon
						data_1_plane@lat2d=xlat
						data_2_plane@lon2d=xlon
						data_2_plane@lat2d=xlat
						if have_diff then
							diff_plane@lon2d=xlon
							diff_plane@lat2d=xlat
						end if
					else
						data_1_uu_plane@lon2d=xlon
						data_1_uu_plane@lat2d=xlat
						data_1_vv_plane@lon2d=xlon
						data_1_vv_plane@lat2d=xlat
						data_2_uu_plane@lon2d=xlon
						data_2_uu_plane@lat2d=xlat
						data_2_vv_plane@lon2d=xlon
						data_2_vv_plane@lat2d=xlat	
						if have_diff then
							diff_uu_plane@lon2d=xlon
							diff_uu_plane@lat2d=xlat
							diff_vv_plane@lon2d=xlon
							diff_vv_plane@lat2d=xlat
						end if
					end if

					;============
					; smooth the variable before plot		;???###### you can change the smooth factor
					;================
					if plot_figure then
						if (smooth(var_id).and. (var_name(var_id) .ne. "wind_vector") )then
		
								wrf_smooth_2d( data_1_plane(level,:,:), 3 )
								wrf_smooth_2d( data_2_plane(level,:,:), 3 )	
								if have_diff then			
									wrf_smooth_2d( diff_plane(level,:,:), 3 )		
								end if						

						end if
					end if

					;=======================
					; (1)  plot data1 and data2
					;=======================


					;==============
					;set different range 3D variables   ;???####		
					;==============

				

					if(level_type .eq.3)then			;????########## pressure level

						if(var_name(var_id).ne."wind_vector")then		; auto algorithm

							min_range= min(data_1_plane(level,:,:))
							max_range=max(data_1_plane(level,:,:))
							
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
								min_diff_range= min(diff_plane(level,:,:))
								max_diff_range= max(diff_plane(level,:,:))
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
		
						

						if(var_name(var_id) .eq. "eth")then
							opts@cnMinLevelValF       = 320.
							opts@cnMaxLevelValF       = 370.
							opts@cnLevelSpacingF      = 2.0
							;opts@cnLevelSelectionMode =  "AutomaticLevels"
							opts_diff=opts	
							; opts_diff@cnLineColor = (/18/)
							opts_diff@cnMinLevelValF       = -16
							opts_diff@cnMaxLevelValF       = 16
							opts_diff@cnLevelSpacingF      = 2
						end if

						if(var_name(var_id) .eq. "rh".or.var_name(var_id) .eq. "rh_mean")then
							opts@cnMinLevelValF       = 0.
							opts@cnMaxLevelValF       = 100.
							opts@cnLevelSpacingF      = 10.
							opts@cnLineColor = (/8/)
							opts_diff=opts
							opts_diff@cnLineColor = (/18/)	
							opts_diff@cnMinLevelValF       = -80.0
							opts_diff@cnMaxLevelValF       = 80.0
							opts_diff@cnLevelSpacingF      =  10.
						end if 

						if(var_name(var_id) .eq. "wind_speed".or.var_name(var_id) .eq. "shear_wind_speed")then
								opts@cnMinLevelValF       = 0.
								opts@cnMaxLevelValF       = 46.
								opts@cnLevelSpacingF      = 2.
								opts_diff=opts
								opts_diff@cnMinLevelValF       = -14.0
								opts_diff@cnMaxLevelValF       = 14.0
								opts_diff@cnLevelSpacingF      = 2.0   
						end if 

						if(var_name(var_id) .eq. "pvo")then
							opts@cnMinLevelValF       = -6.4
							opts@cnMaxLevelValF       = 6.4
							opts@cnLevelSpacingF      = 0.8
							opts_diff=opts
							opts_diff@cnMinLevelValF       = -4.8
							opts_diff@cnMaxLevelValF       = 4.8
							opts_diff@cnLevelSpacingF      = 0.6
						end if 

						if(var_name(var_id) .eq. "rvo")then
							opts@cnMinLevelValF       = -40
							opts@cnMaxLevelValF       = 40
							opts@cnLevelSpacingF      = 5
							opts_diff=opts
							opts_diff@cnMinLevelValF       = -40
							opts_diff@cnMaxLevelValF       = 40
							opts_diff@cnLevelSpacingF      = 5
						end if 

						if(var_name(var_id) .eq. "t_td"  )then
							opts@cnLineColor = (/8/)
							opts@cnMinLevelValF       = 0.0
							opts@cnMaxLevelValF       = 50.0
							opts@cnLevelSpacingF      = 4.0
							opts_diff=opts	
							opts_diff@gsnContourPosLineDashPattern  =0
							opts_diff@gsnContourNegLineDashPattern  =4
							opts_diff@gsnContourZeroLineThicknessF =1.4
							opts_diff@cnMinLevelValF       = -20.0
							opts_diff@cnMaxLevelValF       = 20.0
							opts_diff@cnLevelSpacingF      = 2.5
						end if

					end if     		; end of setting for pressure level




					;--------------------------
					;begin to plot
					;-----------------------
					if plot_figure then

						if(var_name(var_id) .ne. "wind_vector" )then

							if(isoverlay(var_id) .and.  (num_overlay_3d .eq. total_num_overlay_3d).or. .not.isoverlay(var_id))then

				 				contour_data_1_3d(var_id,level)= gsn_csm_contour_map(wks,data_1_plane(level,:,:),opts)
				 				contour_data_2_3d(var_id,level)= gsn_csm_contour_map(wks,data_2_plane(level,:,:),opts)

							else
								contour_data_1_3d(var_id,level)= gsn_csm_contour(wks,data_1_plane(level,:,:),opts)
				 				contour_data_2_3d(var_id,level)= gsn_csm_contour(wks,data_2_plane(level,:,:),opts)	

							end if	

						else
							if(isoverlay(var_id) .and.  (num_overlay_3d .eq. total_num_overlay_3d).or. .not.isoverlay(var_id))then
								if(var_res(var_id).eq."vc")then
									contour_data_1_3d(var_id,level)= gsn_csm_vector_map(wks,data_1_uu_plane(level,:,:),data_1_vv_plane(level,:,:),opts)
									contour_data_2_3d(var_id,level)= gsn_csm_vector_map(wks,data_2_uu_plane(level,:,:),data_2_vv_plane(level,:,:),opts)
								end if
								if(var_res(var_id).eq."str")then
									contour_data_1_3d(var_id,level)= gsn_csm_streamline_map_ce(wks,data_1_uu_plane(level,:,:),data_1_vv_plane(level,:,:),opts)
									contour_data_2_3d(var_id,level)= gsn_csm_streamline_map_ce(wks,data_2_uu_plane(level,:,:),data_2_vv_plane(level,:,:),opts)
								end if
							else
								if(var_res(var_id).eq."vc")then
									contour_data_1_3d(var_id,level)= gsn_csm_vector(wks,data_1_uu_plane(level,:,:),data_1_vv_plane(level,:,:),opts)
									contour_data_2_3d(var_id,level)= gsn_csm_vector(wks,data_2_uu_plane(level,:,:),data_2_vv_plane(level,:,:),opts)
								end if
								if(var_res(var_id).eq."str")then
									contour_data_1_3d(var_id,level)= gsn_csm_streamline(wks,data_1_uu_plane(level,:,:),data_1_vv_plane(level,:,:),opts)
									contour_data_2_3d(var_id,level)= gsn_csm_streamline(wks,data_2_uu_plane(level,:,:),data_2_vv_plane(level,:,:),opts)
								end if
							end if

						end if

						;=======================
						; (2)   plot the "diff"
						;=========================  
						if have_diff then
							if(var_name(var_id) .ne. "wind_vector" )then	
								if(isoverlay_diff(var_id) .and.  (num_overlay_diff_3d .eq. total_num_overlay_diff_3d).or. .not.isoverlay_diff(var_id))then		
									contour_diff_3d(var_id,level) = gsn_csm_contour_map(wks,diff_plane(level,:,:),opts_diff)
								else
									contour_diff_3d(var_id,level) = gsn_csm_contour(wks,diff_plane(level,:,:),opts_diff)
								end if
							else  
								opts_diff=opts
								if(isoverlay_diff(var_id) .and.  (num_overlay_diff_3d .eq. total_num_overlay_diff_3d).or. .not.isoverlay_diff(var_id))then
									if(var_res(var_id).eq."vc")then		
										contour_diff_3d(var_id,level)=gsn_csm_vector_map(wks,diff_uu_plane(level,:,:),diff_vv_plane(level,:,:),opts_diff)
									end if
									if(var_res(var_id).eq."str")then
										contour_diff_3d(var_id,level)=gsn_csm_streamline_map_ce(wks,diff_uu_plane(level,:,:),diff_vv_plane(level,:,:),opts_diff)
									end if

								else

									if(var_res(var_id).eq."vc")then									
										contour_diff_3d(var_id,level)=gsn_csm_vector(wks,diff_uu_plane(level,:,:),diff_vv_plane(level,:,:),opts_diff)
									end if

									if(var_res(var_id).eq."str")then
										contour_diff_3d(var_id,level)=gsn_csm_streamline(wks,diff_uu_plane(level,:,:),diff_vv_plane(level,:,:),opts_diff)
									end if

								end if

							end if

						end if

						;=================
						; (3) plot the height or pressure		
						;=======================
						if(level_type .eq.1)then
							contour_p=gsn_csm_contour_map(wks,p(level,:,:),opts)  			
						end if
						if(level_type .eq.2)then
							contour_p =  gsn_csm_contour_map(wks,p_plane,opts)  			
						end if
						if(level_type .eq.3)then
							contour_height =  gsn_csm_contour_map(wks,z_plane,opts)  		
						end if

						;=========================
						; overlay
						;=============================
		
						  
						if(num_overlay_3d .eq. 2)then	;if you overlay, number of overlay variables must be >=2
							plot1_overlay1=contour_data_1_3d(0,level)	;store the first variable
							plot2_overlay1=contour_data_2_3d(0,level)
						end if		

						if(num_overlay_3d .eq. 3)then				
						 	plot1_overlay2=	contour_data_1_3d(1,level);the 2nd variable give to plot1_overlay2
						 	plot2_overlay2=	contour_data_2_3d(1,level)
						end if			

				;????###### if you want to overy 4 variables, follow the above block, write three 'if' to find the previous 3 overlay variables, and assign them to plot1_overlay1,plot1_overlay2,plot1_overlay3
		
						if(isoverlay(var_id) .and.(num_overlay_3d .eq. total_num_overlay_3d) )then; only the last variable will be 
		;combined to previous overlay variables and output, for examplem if isoverlay=(/True,True,True/) , plot_1_3d(it,0,level) and plot_1_3d(it,1,level) are missing value, only output plot_1_3d(it,2,level)
							last_overlay_id=var_id	; record for the panel plot		 
							if( num_overlay_3d .eq. 2 )then
					   			overlay(contour_data_1_3d(var_id,level),plot1_overlay1)   
								plot_1_3d(var_id,level) = contour_data_1_3d(var_id,level)
					   			overlay(contour_data_2_3d(var_id,level),plot2_overlay1)	
								plot_2_3d(var_id,level) = contour_data_2_3d(var_id,level)
						  	end if

						  	if( num_overlay_3d .eq. 3 )then
					   			overlay(contour_data_1_3d(var_id,level),plot1_overlay1)   
					   			overlay(contour_data_1_3d(var_id,level),plot1_overlay2)   
								plot_1_3d(var_id,level) = contour_data_1_3d(var_id,level)
					   			overlay(contour_data_2_3d(var_id,level),plot2_overlay1)	
					   			overlay(contour_data_2_3d(var_id,level),plot2_overlay2)	
								plot_2_3d(var_id,level) = contour_data_2_3d(var_id,level)

						  	end if


						else	; this is the situation when overlay =false, ;if only one variable,isoverlay is false as well	

							if(.not.isoverlay(var_id) )then
								plot_1_3d(var_id,level) = contour_data_1_3d(var_id,level)
								plot_2_3d(var_id,level) = contour_data_2_3d(var_id,level)
							end if
						end if

				
						;---------------------
						; for the difference
						;----------------------
						if have_diff then
							if(num_overlay_diff_3d .eq. 2)then
								plot_diff_3d_overlay1=contour_diff_3d(0,level) 				
							end if

							if(num_overlay_diff_3d .eq. 3)then
								plot_diff_3d_overlay2=contour_diff_3d(1,level) 			
							end if

							if(isoverlay_diff(var_id) .and.  (num_overlay_diff_3d .eq. total_num_overlay_diff_3d))then	
								if( num_overlay_diff_3d .eq. 2 )then
									overlay(contour_diff_3d(var_id,level),plot_diff_3d_overlay1) 
									plot_diff_3d(var_id,level) =   contour_diff_3d(var_id,level)
								end if
								if( num_overlay_diff_3d .eq. 3)then
									overlay(contour_diff_3d(var_id,level),plot_diff_3d_overlay1) 
									overlay(contour_diff_3d(var_id,level),plot_diff_3d_overlay2) 
									plot_diff_3d(var_id,level) =   contour_diff_3d(var_id,level)
								end if

							else		
								if(.not.isoverlay_diff(var_id) )then
									plot_diff_3d(var_id,level) = contour_diff_3d(var_id,level)
								end if
							end if
						end if

						if (level_type .eq. 1 .or. level_type .eq. 2)then    ;????#####
						  plot3(var_id,level) = contour_p
						else 
						  plot3(var_id,level) = contour_height  
						end if  

					end if	   ;end of 				if plot_figure 

	 			end do              ; END OF LEVEL LOOP  5000

			end if
			;==================
			; (BBBBBBBBBBBB)   surface 2d variable   ;4000   
			;==================
		else		

			checkfile="echo working on time "+time_name(it)+" variable "+var_name(var_id)+"  >>"+wks_name+".txt"
			system(checkfile)
			;---------------------
			;set range for 2D variable  			???####	
			;----------------------------------
			opts_diff=opts
			

			if(var_name(var_id) .eq. "aod")then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 1.5
				opts@cnLevelSpacingF      = 0.1
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -0.4
				opts_diff@cnMaxLevelValF       = 0.4
				opts_diff@cnLevelSpacingF      = 0.05
			end if 

			if(var_name(var_id) .eq. "slp")then
				opts@cnMinLevelValF       = 990.
				opts@cnMaxLevelValF       = 1020.
				opts@cnLevelSpacingF      = 2.5

				if(var_res(var_id).eq."cn")then		;????#####
					;opts@cnLineColor = (/8/)
					opts@cnLineThicknesses=(/80.0/)
					opts@cnLineColor = (/1/)
					;if(set.eq.2)then
						;opts@cnLineColor = (/201/)
					;else

					;end if
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -6.
					opts_diff@cnMaxLevelValF       = 6.
					opts_diff@cnLevelSpacingF      = 1.

				else
					opts_diff=opts
					opts_diff@cnMinLevelValF       = -1.1
					opts_diff@cnMaxLevelValF       = 1.0
					opts_diff@cnLevelSpacingF      = 0.1
				end if


			end if 

			if(var_name(var_id) .eq. "RAINNC" .or. var_name(var_id) .eq. "RAINC")then

				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 150.
				opts@cnLevelSpacingF      = 15 
				opts@cnLineLabelInterval =1
				opts@cnLineColor = (/"purple"/)
				opts@cnLineThicknesses=(/10.0/)
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -80
				opts_diff@cnMaxLevelValF       = 80
				opts_diff@cnLevelSpacingF      = 10

			end if 



			if(var_name(var_id) .eq. "HFX"  .or.var_name(var_id) .eq. "LH" )then
				opts@cnMinLevelValF       = -100
				opts@cnMaxLevelValF       = 800
				opts@cnLevelSpacingF      = 40
				opts_diff=opts	
				opts_diff@cnMinLevelValF       = -30
				opts_diff@cnMaxLevelValF       = 30
				opts_diff@cnLevelSpacingF      = 5
			end if

			if( var_name(var_id) .eq. "ACHFX2" .or. var_name(var_id) .eq. "ACLHF2" \
					.or. var_name(var_id) .eq. "ACSWUPB2".or. var_name(var_id) .eq. "ACSWUPBC2"\				
					.or. var_name(var_id) .eq. "ACSWDNB2".or. var_name(var_id) .eq. "ACSWDNBC2"\
					.or. var_name(var_id) .eq. "ACLWUPB2".or. var_name(var_id) .eq. "ACLWUPBC2"\					
					.or. var_name(var_id) .eq. "ACLWDNB2".or. var_name(var_id) .eq. "ACLWDNBC2"\
					.or. var_name(var_id) .eq. "ACGRDFLX2".or. var_name(var_id) .eq. "net_ground_total"\
					.or. var_name(var_id) .eq. "net_sw_down".or. var_name(var_id) .eq. "net_lw_down"\
					.or. var_name(var_id) .eq. "net_sw_lw_down".or. var_name(var_id) .eq. "achfx2_aclhfx2")then
				opts@cnMinLevelValF       = -100*3000
				opts@cnMaxLevelValF       = 800*3000
				opts@cnLevelSpacingF      = 40*3000
				opts_diff=opts	
				opts_diff@cnMinLevelValF       = -30*3000
				opts_diff@cnMaxLevelValF       = 30*3000
				opts_diff@cnLevelSpacingF      = 5*3000
			end if

			if( var_name(var_id) .eq. "ACHFX"  )then
				opts@cnMinLevelValF       = -40*10E4
				opts@cnMaxLevelValF       = 400*10E4
				opts@cnLevelSpacingF      = 20*10E4
				opts_diff=opts	
				opts_diff@cnMinLevelValF       = -15*10E4
				opts_diff@cnMaxLevelValF       = 15*10E4
				opts_diff@cnLevelSpacingF      = 3*10E4
			end if

			if(var_name(var_id) .eq. "SWDOWN"  .or.var_name(var_id) .eq. "GSW" )then
				opts@cnMinLevelValF       = -80.
				opts@cnMaxLevelValF       = 1200.
				opts@cnLevelSpacingF      = 50.
				opts_diff=opts	
				opts_diff@cnMinLevelValF       = -150.
				opts_diff@cnMaxLevelValF       = 150.
				opts_diff@cnLevelSpacingF      = 30.

			end if



			if(var_name(var_id) .eq. "mcape"  )then
				opts@cnMinLevelValF       = 0.0
				opts@cnMaxLevelValF       = 4000.0
				opts@cnLevelSpacingF      = 400.0
				opts_diff=opts	
				opts_diff@cnMinLevelValF       = -1200.0
				opts_diff@cnMaxLevelValF       = 1200.0
				opts_diff@cnLevelSpacingF      = 200.0
			end if


			if(var_name(var_id) .eq. "T2" .or. var_name(var_id) .eq. "SST"  )then
				opts@cnLineColor = (/8/)
				opts_diff=opts	
				opts_diff@cnLineColor = (/18/)
				opts_diff@gsnContourPosLineDashPattern  =0
				opts_diff@gsnContourNegLineDashPattern  =4
				opts_diff@gsnContourZeroLineThicknessF =1.4
				opts_diff@cnMinLevelValF       = -5.0
				opts_diff@cnMaxLevelValF       = 5.0
				opts_diff@cnLevelSpacingF      = 0.5
			end if

			if( var_name(var_id) .eq. "TSK" .or. var_name(var_id) .eq. "TSK_SAVE"  )then
				opts@cnMinLevelValF       = -10.0
				opts@cnMaxLevelValF       = 60.
				opts@cnLevelSpacingF      = 5.
				opts@cnLineColor = (/18/)
				opts_diff=opts	
			;	opts_diff@gsnContourPosLineDashPattern  =0
			;	opts_diff@gsnContourNegLineDashPattern  =4
			;	opts_diff@gsnContourZeroLineThicknessF =1.4
				opts_diff@cnMinLevelValF       = -2.0
				opts_diff@cnMaxLevelValF       = 2.0
				opts_diff@cnLevelSpacingF      = 0.25
			end if

			if(var_name(var_id) .eq. "mdbz" )then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 70.
				opts@cnLevelSpacingF      = 5.
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -40.0
				opts_diff@cnMaxLevelValF       = 40.0
				opts_diff@cnLevelSpacingF      = 5   
			end if 

			if(var_name(var_id) .eq. "wind_speed_2d" )then
				opts@cnMinLevelValF       = 0.
				opts@cnMaxLevelValF       = 30.
				opts@cnLevelSpacingF      = 2.
				opts_diff=opts
				opts_diff@cnMinLevelValF       = -10.0
				opts_diff@cnMaxLevelValF       = 10.0
				opts_diff@cnLevelSpacingF      = 2.0   
			end if 


			;-----------------------
			; set the title
			;-----------------------
		

			if .not. isoverlay(var_id) then
					opts@gsnLeftString = " "
					opts@gsnCenterString=var_name(var_id) 
					opts@gsnRightString= units(var_id) 					
			end if

			if  isoverlay(var_id) then
				if (total_num_overlay_2d.eq.2) then
					if(var_id.eq.1)then
						opts@gsnLeftString = " "
						opts@gsnCenterString=var_name(0) +"~C~"+var_name(1) 
						opts@gsnRightString= units(0) +"~C~"+units(1) 	
					else
						opts@gsnLeftString = " "
						opts@gsnCenterString= " "
						opts@gsnRightString=  " "
					end if
				end if

				if (total_num_overlay_2d.eq.3) then
					if(var_id.eq.2)then
	
						opts@gsnLeftString =" "
						opts@gsnCenterString=var_name(0) +"~C~"+var_name(1) +"~C~"+var_name(2) +"~C~"
						opts@gsnRightString= units(0) +"~C~"+units(1) +"~C~"+units(2) +"~C~"	
					else
						opts@gsnLeftString = " "
						opts@gsnCenterString= " "
						opts@gsnRightString=  " "
					end if
				end if
			end if
			;==========
			; smooth the surface variable
			;==============
			if plot_figure then

				if (smooth(var_id).and.(var_name(var_id).ne."wind_vector_2d".and.var_name(var_id) .ne."shear_vector"))then	
						wrf_smooth_2d( data_1, 3 )			;????#####
						wrf_smooth_2d( data_2, 3 )	
						if have_diff then
							wrf_smooth_2d( diff, 3 )
						end if				
				end if


				if(var_name(var_id) .ne. "wind_vector_2d" .and.var_name(var_id) .ne."shear_vector")then	;contour
					if(isoverlay(var_id) .and.  (num_overlay_2d .eq. total_num_overlay_2d).or. .not.isoverlay(var_id))then
						contour_data_1_2d(var_id) = gsn_csm_contour_map(wks,data_1,opts);only the last overlay variable use map
						contour_data_2_2d(var_id) = gsn_csm_contour_map(wks,data_2,opts)
						if have_diff then
							contour_diff_2d(var_id) = gsn_csm_contour_map(wks,diff,opts_diff)
						end if
					else
						contour_data_1_2d(var_id) = gsn_csm_contour(wks,data_1,opts)
						contour_data_2_2d(var_id) = gsn_csm_contour(wks,data_2,opts)
						if have_diff then
							contour_diff_2d(var_id) = gsn_csm_contour(wks,diff,opts_diff)
						end if
					end if
				else	;wind
					if(isoverlay(var_id) .and.  (num_overlay_2d .eq. total_num_overlay_2d).or. .not.isoverlay(var_id))then
						if(var_res(var_id).eq."vc")then
							contour_data_1_2d(var_id)= gsn_csm_vector_map(wks,data_1_uu,data_1_vv,opts)
							contour_data_2_2d(var_id)= gsn_csm_vector_map(wks,data_2_uu,data_2_vv,opts)
						end if
						if(var_res(var_id).eq."str")then
							contour_data_1_2d(var_id)= gsn_csm_streamline_map_ce(wks,data_1_uu,data_1_vv,opts)
							contour_data_2_2d(var_id)= gsn_csm_streamline_map_ce(wks,data_2_uu,data_2_vv,opts)
						end if

						if have_diff then

							if(var_res(var_id).eq."vc")then
								contour_diff_2d(var_id) = gsn_csm_vector_map(wks,diff_uu,diff_vv,opts_diff)
							end if
							if(var_res(var_id).eq."str")then
								contour_diff_2d(var_id) = gsn_csm_streamline_map_ce(wks,diff_uu,diff_vv,opts_diff)
							end if

						end if
					else
						if(var_res(var_id).eq."vc")then
							contour_data_1_2d(var_id)= gsn_csm_vector(wks,data_1_uu,data_1_vv,opts)
							contour_data_2_2d(var_id)= gsn_csm_vector(wks,data_2_uu,data_2_vv,opts)
						end if
						if(var_res(var_id).eq."str")then
							contour_data_1_2d(var_id)= gsn_csm_streamline(wks,data_1_uu,data_1_vv,opts)
							contour_data_2_2d(var_id)= gsn_csm_streamline(wks,data_2_uu,data_2_vv,opts)
						end if

						if have_diff then
							if(var_res(var_id).eq."vc")then
								contour_diff_2d(var_id) = gsn_csm_vector(wks,diff_uu,diff_vv,opts_diff)
							end if
							if(var_res(var_id).eq."str")then
								contour_diff_2d(var_id) = gsn_csm_streamline(wks,diff_uu,diff_vv,opts_diff)
							end if

						end if

					end if

				end if

				; overlay
				if(num_overlay_2d .eq. 2)then
					plot1_overlay1_2d=contour_data_1_2d(0)
					plot2_overlay1_2d=contour_data_2_2d(0)
				end if		

				if(num_overlay_2d .eq. 3)then
					plot1_overlay2_2d=contour_data_1_2d(1)
					plot2_overlay2_2d=contour_data_2_2d(1)
				end if			


				if(isoverlay(var_id) .and.  (num_overlay_2d .eq. total_num_overlay_2d) )then ; only the last variable will be overlay
					last_overlay_id=var_id  ; plot panel plot				
					if( num_overlay_2d .eq. 2 )then
					
						overlay(contour_data_1_2d(var_id),plot1_overlay1_2d)
						plot_1_2d(var_id) = contour_data_1_2d(var_id)

						overlay(contour_data_2_2d(var_id),plot2_overlay1_2d)	
						plot_2_2d(var_id) = contour_data_2_2d(var_id)

					end if

					if( num_overlay_2d .eq. 3 )then


						overlay(contour_data_1_2d(var_id),plot1_overlay1_2d)
						overlay(contour_data_1_2d(var_id),plot1_overlay2_2d)
						plot_1_2d(var_id) = contour_data_1_2d(var_id)

						overlay(contour_data_2_2d(var_id),plot2_overlay1_2d)
						overlay(contour_data_2_2d(var_id),plot2_overlay2_2d)	
						plot_2_2d(var_id) = contour_data_2_2d(var_id)
	
					end if

				else		; this is the situation when overlay =false
					if(.not.isoverlay(var_id))then

						plot_1_2d(var_id) = contour_data_1_2d(var_id)
						plot_2_2d(var_id) = contour_data_2_2d(var_id)

					end if
				end if

				;---------------------
				; for the difference
				;----------------------
				if have_diff then
					if(num_overlay_diff_2d .eq. 2)then
							 	plot_diff_overlay1_2d=contour_diff_2d(0) 				
					end if

					if(num_overlay_diff_2d .eq. 3)then
							 	plot_diff_overlay2_2d=contour_diff_2d(1) 			
					end if

					if(isoverlay_diff(var_id) .and.  (num_overlay_diff_2d .eq. total_num_overlay_diff_2d))then	
						if( num_overlay_diff_2d .eq. 2 )then

							overlay(contour_diff_2d(var_id),plot_diff_overlay1_2d)
							plot_diff_2d(var_id) =   contour_diff_2d(var_id)
						end if

						if( num_overlay_diff_2d .eq. 3)then

							overlay(contour_diff_2d(var_id),plot_diff_overlay1_2d)
							overlay(contour_diff_2d(var_id),plot_diff_overlay2_2d)
							plot_diff_2d(var_id) =   contour_diff_2d(var_id)
						end if

					else		
						if(.not.isoverlay_diff(var_id) )then
							plot_diff_2d(var_id) = contour_diff_2d(var_id)
						end if
					end if
				end if

			end if 			;end of	if plot_figure 

		end if	; end of 3d or surface variable 4000	

		;===========================
		; search hurricane center 	;center lat and lon for hurricane are determined by min slp or by min wind, max rvo/pvo at some time
		;===========================
		if(search_hurricane_center )then
			if(var_id.eq.0) then		;only search once for one time.
				print("search hurricane center in file1")

				;--------------- 
				;(1)search in file1
				;--------------
				if(it.eq.start_time)then
					clat_a = clat0_a				
					clon_a = clon0_a

					p  = wrf_user_getvar(a, "pressure",0)
					dom_size=dimsizes(p)
					klev=dom_size(0)
				end if


				real_ijloc_a = wrf_user_ll_to_ij (a, clon_a, clat_a, True)	; clon and clat were updated from the last cycle
				ic_a = round(real_ijloc_a(0),3)
				jc_a = round(real_ijloc_a(1),3)

				yymin_a = max( (/0,jc_a-center_search_half_size_a(it)/) )
				yymax_a = min( (/dom_size(1)-1,jc_a+center_search_half_size_a(it)/) )
				xxmin_a = max( (/0,ic_a-center_search_half_size_a(it)/) )
				xxmax_a = min( (/dom_size(2)-1,ic_a+center_search_half_size_a(it)/) )

				slp_a = wrf_user_getvar(a, "slp",0)
				u10_a = wrf_user_getvar(a,"U10",0) 
				v10_a= wrf_user_getvar(a,"V10",0)  
				wind10_a = sqrt(u10_a^2+v10_a^2)
				u_a = wrf_user_getvar(a,"ua",0) 
				v_a= wrf_user_getvar(a,"va",0)  
				wind_a = sqrt(u_a^2+v_a^2)
				

				;----------------------
				;search the box
				;----------------------

				;search for maximum wind, always search around the cneter
				wind10_max_a=wind10_a(jc_a,ic_a);initial wind value at this time
						;search the box
				do j = yymin_a,yymax_a
					do i = xxmin_a,xxmax_a	
						if( wind10_a(j,i).ge.wind10_max_a)then
							iwind10_max_a = i
							jwind10_max_a = j
							wind10_max_a=wind10_a(j,i)
						end if
					end do
				end do	

				;(1) search for minimum pressure 
				if(search_method(it).eq.1)then
						;xxmax_a=ic_a
					if(it.eq.14.or.it.eq.19)then		;???##### find the center on the south west, from 2312-2318,
						yymax_a=jc_a
						xxmax_a=ic_a
					end if

					slp_min_a = slp_a(jc_a,ic_a)	;initial pressure value at this time

					;search the box
					do j = yymin_a,yymax_a
						do i = xxmin_a,xxmax_a		
							if (  slp_a(j,i) .le. slp_min_a) then
								islp_a = i
								jslp_a = j
								slp_min_a= slp_a(j,i)
							end if
						end do
					end do	

				end if

				; (2) search for minimum wind		
				if(search_method(it).eq.2)then

					wind10_min_a=wind10_a(jc_a,ic_a);initial wind value at this time

					;search the box
					do j = yymin_a,yymax_a
						do i = xxmin_a,xxmax_a	
							if( wind10_a(j,i).le.wind10_min_a)then
								iwind10_min_a = i
								jwind10_min_a = j
								wind10_min_a=wind10_a(j,i)
							end if
						end do
					end do	

				end if


				;(3) search for maximum potential vorticity
				if(search_method(it).eq.3)then
					;if(it.eq.10)then		;???##### find the center on the south west, at 2318, on the nest domain
					;	yymax_a=jc_a
					;	xxmax_a=ic_a
					;end if
					p_avg=   dim_avg_n(p, (/1,2/))  ; ==> zAvg(nlat,nlon)
					vorticity_level_index=closest_val(600,p_avg) ;use 850hpa vorticity maximum
					pvo1_a = wrf_user_getvar(a,"pvo",0) 
					pvo_a=pvo1_a(vorticity_level_index,:,:)	
					pvo_max_a= pvo_a(jc_a,ic_a) ;initial vorticity at this time
					wind_max_a=wind_a(vorticity_level_index,jc_a,ic_a) 

					;search the box
					do j = yymin_a,yymax_a
						do i = xxmin_a,xxmax_a
				
							if ( pvo_a(j,i).ge. pvo_max_a) then
								ipvo_a = i
								jpvo_a = j
								pvo_max_a = pvo_a(j,i)
							end if

							if( wind_a(vorticity_level_index,j,i).ge.wind_max_a)then
								iwind_max_a = i
								jwind_max_a = j
								wind_max_a=wind_a(vorticity_level_index,j,i)
							end if


						end do
					end do	

				end if

				;(4) search for maximum relative vorticity
				if(search_method(it).eq.4)then

					;-------------read rvo
					avo_1 = wrf_user_getvar(a,"avo",0)*1e-5 	

					ff=wrf_user_getvar(a,"F",0) 

					dimmm=dimsizes(avo_1)
					klev=dimmm(0)
					nlat=dimmm(1)
					mlon=dimmm(2)

					if(it.eq.start_time)
						rvo_1=new((/klev,nlat,mlon/),"float")

					end if

					do lev=0,klev-1
						rvo_1(lev,:,:)=avo_1(lev,:,:)-ff(:,:)

					end do

						rvo_1=rvo_1*1e5

					;--------------

						
					if(it.gt.0)then		;???##### find the center on the south west, at 2318, on the nest domain
						;yymax_a=jc_a
						xxmax_a=ic_a
					end if
					p_avg=   dim_avg_n(p, (/1,2/))  ; ==> zAvg(nlat,nlon)
					vorticity_level_index=closest_val(600,p_avg) ;use 850hpa vorticity maximum
					rvo_a=rvo_1(vorticity_level_index,:,:)	
					rvo_max_a= rvo_a(jc_a,ic_a) ;initial vorticity at this time
					wind_max_a=wind_a(vorticity_level_index,jc_a,ic_a) 
					;search the box
					do j = yymin_a,yymax_a
						do i = xxmin_a,xxmax_a
				
							if ( rvo_a(j,i).ge. rvo_max_a) then
								irvo_a = i
								jrvo_a = j
								rvo_max_a = rvo_a(j,i)
							end if

							if( wind_a(vorticity_level_index,j,i).ge.wind_max_a)then
								iwind_max_a = i
								jwind_max_a = j
								wind_max_a=wind_a(vorticity_level_index,j,i)
							end if

						end do
					end do	

				end if

				; (5) search for minimum wind at 850hPa
				if(search_method(it).eq.5)then
					p_avg=   dim_avg_n(p, (/1,2/))  
					wind_level_index=closest_val(850,p_avg) ;use 850 minimum wind
					wind_plane_a=wind_a(wind_level_index,:,:)	
					wind_min_a=wind_plane_a(jc_a,ic_a);initial wind value at this time
					wind_max_a=wind_a(wind_level_index,jc_a,ic_a) 
					if(it.gt.0.and.it.le.20)then	;before 2400UTC	
						;yymax_a=jc_b
						xxmax_a=ic_a
					end if
					;search the box
					do j = yymin_a,yymax_a
						do i = xxmin_a,xxmax_a	
							if( wind_plane_a(j,i).le.wind_min_a)then
								iwind_min_a = i
								jwind_min_a = j
								wind_min_a=wind_plane_a(j,i)
							end if

							if( wind_a(wind_level_index,j,i).ge.wind_max_a)then
								iwind_max_a = i
								jwind_max_a = j
								wind_max_a=wind_a(wind_level_index,j,i)
							end if

						end do
					end do	

				end if

				;end of searching 

				;---------------------------
				;update center: clat, clon
				;-----------------------

				if (search_method(it).eq.1)then
					ii_a=islp_a
					jj_a=jslp_a
				end if

				if (search_method(it).eq.2)then
					ii_a=iwind_min_a 
					jj_a=jwind_min_a
				end if


				if (search_method(it).eq.3)then
					ii_a=ipvo_a 
					jj_a=jpvo_a 
				end if

				if (search_method(it).eq.4)then
					ii_a=irvo_a 
					jj_a=jrvo_a 
				end if

				if (search_method(it).eq.5)then
					ii_a=iwind_min_a 
					jj_a=jwind_min_a
				end if

				clat_a = xlat(jj_a,ii_a)		
				clon_a = xlon(jj_a,ii_a)
				slp_center_a=slp_a(jj_a,ii_a) ;position pressure
							
			
				; maxinumu wind position
				if (search_method(it).eq.3.or.search_method(it).eq.4.or.search_method(it).eq.5)then
					clat_wind_a = xlat(jwind_max_a,iwind_max_a)
					clon_wind_a = xlon(jwind_max_a,iwind_max_a)
				else
					clat_wind_a = xlat(jwind10_max_a,iwind10_max_a)
					clon_wind_a = xlon(jwind10_max_a,iwind10_max_a)
				end if

				;output center coordinate to the screen, just for review
				lat_min_a(it) = xlat(jj_a,ii_a) 
				lon_min_a(it) = xlon(jj_a,ii_a)  
				print("lat_min and lon_min in file1  "+lat_min_a(it) + " " + lon_min_a(it))
				print("slp_center_a= "+slp_center_a)

				;--------------- 
				;(2)search in file2
				;--------------
				if(it.eq.start_time)then
					clat_b = clat0_b				
					clon_b = clon0_b

					p  = wrf_user_getvar(b, "pressure",0)
					dom_size=dimsizes(p)
					klev=dom_size(0)
				end if


				real_ijloc_b = wrf_user_ll_to_ij (b, clon_b, clat_b, True)	; clon and clat were updated from the last cycle
				ic_b = round(real_ijloc_b(0),3)
				jc_b = round(real_ijloc_b(1),3)

				yymin_b = max( (/0,jc_b-center_search_half_size_b(it)/) )
				yymax_b = min( (/dom_size(1)-1,jc_b+center_search_half_size_b(it)/) )
				xxmin_b = max( (/0,ic_b-center_search_half_size_b(it)/) )
				xxmax_b = min( (/dom_size(2)-1,ic_b+center_search_half_size_b(it)/) )

				slp_b = wrf_user_getvar(b, "slp",0)
				u10_b = wrf_user_getvar(b,"U10",0) 
				v10_b= wrf_user_getvar(b,"V10",0)  
				wind10_b = sqrt(u10_b^2+v10_b^2)
				u_b = wrf_user_getvar(b,"ua",0) 
				v_b= wrf_user_getvar(b,"va",0)  
				wind_b = sqrt(u_b^2+v_b^2)
				

				;----------------------
				;search the box
				;----------------------

				;search for maximum wind, always search around the cneter
				wind10_max_b=wind10_b(jc_b,ic_b);initial wind value at this time
						;search the box
				do j = yymin_b,yymax_b
					do i = xxmin_b,xxmax_b	
						if( wind10_b(j,i).ge.wind10_max_b)then
							iwind10_max_b = i
							jwind10_max_b = j
							wind10_max_b=wind10_b(j,i)
						end if
					end do
				end do	

				;(1) search for minimum pressure 
				if(search_method(it).eq.1)then
						;xxmax_b=ic_b
					if(it.eq.14.or.it.eq.19)then		;???##### find the center on the south west, from 2312-2318,
						yymax_b=jc_b
						xxmax_b=ic_b
					end if

					slp_min_b = slp_b(jc_b,ic_b)	;initial pressure value at this time

					;search the box
					do j = yymin_b,yymax_b
						do i = xxmin_b,xxmax_b		
							if (  slp_b(j,i) .le. slp_min_b) then
								islp_b = i
								jslp_b = j
								slp_min_b= slp_b(j,i)
							end if
						end do
					end do	

				end if

				; (2) search for minimum wind		
				if(search_method(it).eq.2)then

					wind10_min_b=wind10_b(jc_b,ic_b);initial wind value at this time

					;search the box
					do j = yymin_b,yymax_b
						do i = xxmin_b,xxmax_b	
							if( wind10_b(j,i).le.wind10_min_b)then
								iwind10_min_b = i
								jwind10_min_b = j
								wind10_min_b=wind10_b(j,i)
							end if
						end do
					end do	

				end if


				;(3) search for maximum potential vorticity
				if(search_method(it).eq.3)then
					;if(it.eq.10)then		;???##### find the center on the south west, at 2318, on the nest domain
					;	yymax_b=jc_b
					;	xxmax_b=ic_b
					;end if
					p_avg=   dim_avg_n(p, (/1,2/))  ; ==> zAvg(nlat,nlon)
					vorticity_level_index=closest_val(600,p_avg) ;use 850hpa vorticity maximum
					pvo1_b = wrf_user_getvar(b,"pvo",0) 
					pvo_b=pvo1_b(vorticity_level_index,:,:)	
					pvo_max_b= pvo_b(jc_b,ic_b) ;initial vorticity at this time
					wind_max_b=wind_b(vorticity_level_index,jc_b,ic_b) 

					;search the box
					do j = yymin_b,yymax_b
						do i = xxmin_b,xxmax_b
				
							if ( pvo_b(j,i).ge. pvo_max_b) then
								ipvo_b = i
								jpvo_b = j
								pvo_max_b = pvo_b(j,i)
							end if

							if( wind_b(vorticity_level_index,j,i).ge.wind_max_b)then
								iwind_max_b = i
								jwind_max_b = j
								wind_max_b=wind_b(vorticity_level_index,j,i)
							end if


						end do
					end do	

				end if


				;(4) search for maximum relative vorticity
				if(search_method(it).eq.4)then

					;-------------read rvo
					avo_2 = wrf_user_getvar(b,"avo",0)*1e-5 	

					ff=wrf_user_getvar(b,"F",0) 

					dimmm=dimsizes(avo_2)
					klev=dimmm(0)
					nlat=dimmm(1)
					mlon=dimmm(2)

					if(it.eq.start_time)
						rvo_2=new((/klev,nlat,mlon/),"float")

					end if

					do lev=0,klev-1
						rvo_2(lev,:,:)=avo_2(lev,:,:)-ff(:,:)

					end do

						rvo_2=rvo_2*1e5

					;--------------


					if(it.gt.0)then		;???##### find the center on the south west, at 2318, on the nest domain
						;yymax_b=jc_b
						xxmax_b=ic_b
					end if
					p_avg=   dim_avg_n(p, (/1,2/))  ; ==> zAvg(nlat,nlon)
					vorticity_level_index=closest_val(600,p_avg) ;use 850hpa vorticity maximum
					rvo_b=rvo_2(vorticity_level_index,:,:)	
					rvo_max_b= rvo_b(jc_b,ic_b) ;initial vorticity at this time
					wind_max_b=wind_b(vorticity_level_index,jc_b,ic_b) 

					;search the box
					do j = yymin_b,yymax_b
						do i = xxmin_b,xxmax_b
				
							if ( rvo_b(j,i).ge. rvo_max_b) then
								irvo_b = i
								jrvo_b = j
								rvo_max_b = rvo_b(j,i)
							end if

							if( wind_b(vorticity_level_index,j,i).ge.wind_max_b)then
								iwind_max_b = i
								jwind_max_b = j
								wind_max_b=wind_b(vorticity_level_index,j,i)
							end if

						end do
					end do	

				end if

				; (5) search for minimum wind at 4km
				if(search_method(it).eq.5)then
					p_avg=   dim_avg_n(p, (/1,2/))  
					wind_level_index=closest_val(850,p_avg) ;use 850 minimum wind
					wind_plane_b=wind_b(wind_level_index,:,:)	
					wind_min_b=wind_plane_b(jc_b,ic_b);initial wind value at this time
					wind_max_b=wind_b(wind_level_index,jc_b,ic_b) 
					if(it.gt.0.and.it.le.20)then		;before 2400
						;yymax_a=jc_b
						xxmax_b=ic_b
					end if
					;search the box
					do j = yymin_b,yymax_b
						do i = xxmin_b,xxmax_b	
							if( wind_plane_b(j,i).le.wind_min_b)then
								iwind_min_b = i
								jwind_min_b = j
								wind_min_b=wind_plane_b(j,i)
							end if

							if( wind_b(wind_level_index,j,i).ge.wind_max_b)then
								iwind_max_b = i
								jwind_max_b = j
								wind_max_b=wind_b(wind_level_index,j,i)
							end if

						end do
					end do	

				end if

				;end of searching 

				;---------------------------
				;update center: clat, clon
				;-----------------------

				if (search_method(it).eq.1)then
					ii_b=islp_b
					jj_b=jslp_b
				end if

				if (search_method(it).eq.2)then
					ii_b=iwind_min_b 
					jj_b=jwind_min_b
				end if


				if (search_method(it).eq.3)then
					ii_b=ipvo_b 
					jj_b=jpvo_b 
				end if

				if (search_method(it).eq.4)then
					ii_b=irvo_b 
					jj_b=jrvo_b 
				end if

				if (search_method(it).eq.5)then
					ii_b=iwind_min_b 
					jj_b=jwind_min_b
				end if

				clat_b = xlat(jj_b,ii_b)		
				clon_b = xlon(jj_b,ii_b)
				slp_center_b=slp_b(jj_b,ii_b) ;position pressure
							
			
				; maxinumu wind position
				if (search_method(it).eq.3.or.search_method(it).eq.4.or.search_method(it).eq.5)then
					clat_wind_b = xlat(jwind_max_b,iwind_max_b)
					clon_wind_b = xlon(jwind_max_b,iwind_max_b)
				else
					clat_wind_b = xlat(jwind10_max_b,iwind10_max_b)
					clon_wind_b = xlon(jwind10_max_b,iwind10_max_b)
				end if

				;output center coordinate to the screen, just for review
				lat_min_b(it) = xlat(jj_b,ii_b) 
				lon_min_b(it) = xlon(jj_b,ii_b)  
				print("lat_min and lon_min in file1  "+lat_min_b(it) + " " + lon_min_b(it))
				print("slp_center_b= "+slp_center_b)

				;---------------
				;output the position to the file
				;-----------------

				timess  = a->Times  ; get times in the file
				time_char = stringtochar(timess)
				yyyy = stringtoint(chartostring(time_char(0:3)))
				mm = stringtoint(chartostring(time_char(5:6)))
				dd = stringtoint(chartostring(time_char(8:9)))
				hh = stringtoint(chartostring(time_char(11:12)))

				if (search_method(it).eq.3)then
					alist_a=[/yyyy,mm,dd,hh,ii_a,jj_a,clat_a,clon_a,slp_center_a,iwind_max_a,jwind_max_a,wind_max_a,pvo_max_a/]
					alist_b=[/yyyy,mm,dd,hh,ii_b,jj_b,clat_b,clon_b,slp_center_b,iwind_max_b,jwind_max_b,wind_max_b,pvo_max_b/]
					write_table("center_1.txt", "a", alist_a, "%4.4i %0.2i %0.2i %0.2i %5.0i %5.0i %9.2f %9.2f %9.2f %5.0i %5.0i %9.2f %9.2f")
					write_table("center_2.txt", "a", alist_b, "%4.4i %0.2i %0.2i %0.2i %5.0i %5.0i %9.2f %9.2f %9.2f %5.0i %5.0i %9.2f %9.2f")
				end if

				if (search_method(it).eq.4)then
					alist_a=[/yyyy,mm,dd,hh,ii_a,jj_a,clat_a,clon_a,slp_center_a,iwind_max_a,jwind_max_a,wind_max_a,rvo_max_a/]
					alist_b=[/yyyy,mm,dd,hh,ii_b,jj_b,clat_b,clon_b,slp_center_b,iwind_max_b,jwind_max_b,wind_max_b,rvo_max_b/]
					write_table("center_1.txt", "a", alist_a, "%4.4i %0.2i %0.2i %0.2i %5.0i %5.0i %9.2f %9.2f %9.2f %5.0i %5.0i %9.2f %9.2f")
					write_table("center_2.txt", "a", alist_b, "%4.4i %0.2i %0.2i %0.2i %5.0i %5.0i %9.2f %9.2f %9.2f %5.0i %5.0i %9.2f %9.2f")
				end if

				if (search_method(it).eq.5)then
					alist_a=[/yyyy,mm,dd,hh,ii_a,jj_a,clat_a,clon_a,slp_center_a,iwind_max_a,jwind_max_a,wind_max_a/]
					alist_b=[/yyyy,mm,dd,hh,ii_b,jj_b,clat_b,clon_b,slp_center_b,iwind_max_b,jwind_max_b,wind_max_b/]
					write_table("center_1.txt", "a", alist_a, "%4.4i %0.2i %0.2i %0.2i %5.0i %5.0i %9.2f %9.2f %9.2f %5.0i %5.0i %9.2f")
					write_table("center_2.txt", "a", alist_b, "%4.4i %0.2i %0.2i %0.2i %5.0i %5.0i %9.2f %9.2f %9.2f %5.0i %5.0i %9.2f")
				end if

				if (search_method(it).ge.1.and.search_method(it).le.2)then
					alist_a=[/yyyy,mm,dd,hh,ii_a,jj_a,clat_a,clon_a,slp_center_a,iwind10_max_a,jwind10_max_a,wind10_max_a/]
					alist_b=[/yyyy,mm,dd,hh,ii_b,jj_b,clat_b,clon_b,slp_center_b,iwind10_max_b,jwind10_max_b,wind10_max_b/]
					write_table("center_1.txt", "a", alist_a, "%4.4i %0.2i %0.2i %0.2i %5.0i %5.0i %9.2f %9.2f %9.2f %5.0i %5.0i %9.2f ")
					write_table("center_2.txt", "a", alist_b, "%4.4i %0.2i %0.2i %0.2i %5.0i %5.0i %9.2f %9.2f %9.2f %5.0i %5.0i %9.2f ")
				end if

			end if  ; only search once every time step

			;-----------------
			; add the dot
			;------------------
			if (plot_figure.and.hurricane_center_dot)then

					
				;------------resources
				dotres = True
				dotres@gsMarkerColor = "Black"
				dotres@gsMarkerIndex = 16
				dotres@gsMarkerSizeF = 0.005
				dotres_wind=dotres
				dotres_wind@gsMarkerColor = "Green"

				;loc_a=wrf_user_ll_to_ij(a,clon_a,clat_a,res)
				;loc_b=wrf_user_ll_to_ij(b,clon_b,clat_b,res)
				;print("dot lon "+loc_a(0))
				;print("dot lat "+loc_a(1))

				if hurricane_center_dot_3d then
					do  level =0,nlevels-1,d_levels 	 ;???### only add to the last variable which was overlay. or add to a single variable
						if(var_id.eq.last_overlay_id.or. .not.isoverlay(var_id) )then

								plot_hcenter1_3d(var_id,level)=gsn_add_polymarker(wks,plot_1_3d(var_id,level),clon_a,clat_a,dotres)
								plot_hcenter1_wind_3d(var_id,level)=gsn_add_polymarker(wks,plot_1_3d(var_id,level),clon_wind_a,clat_wind_a,dotres_wind)
								plot_hcenter2_3d(var_id,level)=gsn_add_polymarker(wks,plot_2_3d(var_id,level),clon_b,clat_b,dotres)
								plot_hcenter2_wind_3d(var_id,level)=gsn_add_polymarker(wks,plot_2_3d(var_id,level),clon_wind_b,clat_wind_b,dotres_wind)
				
						end if
					end do
				end if

				if hurricane_center_dot_2d then
					if(var_id.eq.last_overlay_id .or. .not.isoverlay(var_id) )then

							plot_hcenter1_2d(var_id)=gsn_add_polymarker(wks,plot_1_2d(var_id),clon_a,clat_a,dotres)
							plot_hcenter1_wind_2d(var_id)=gsn_add_polymarker(wks,plot_1_2d(var_id),clon_wind_a,clat_wind_a,dotres_wind)
							plot_hcenter2_2d(var_id)=gsn_add_polymarker(wks,plot_2_2d(var_id),clon_b,clat_b,dotres)
							plot_hcenter2_wind_2d(var_id)=gsn_add_polymarker(wks,plot_2_2d(var_id),clon_wind_b,clat_wind_b,dotres_wind)
				

					end if
				end if
					

			end if  ;end of adding dot

		end if  
		;end of search hurricane center

		;------------------------
		;read hurricane center and add the dot
		;-----------------

		
		if (plot_figure.and.read_center.and.hurricane_center_dot) then

		

			;------------resources
			dotres = True
			dotres@gsMarkerColor = "Black"
			dotres@gsMarkerIndex = 16
			dotres@gsMarkerSizeF = 0.005
			dotres_wind=dotres
			dotres_wind@gsMarkerColor = "Green"

			;loc_a=wrf_user_ll_to_ij(a,clon_a,clat_a,res)
			;loc_b=wrf_user_ll_to_ij(b,clon_b,clat_b,res)
			;print("dot lon "+loc_a(0))
			;print("dot lat "+loc_a(1))

			if hurricane_center_dot_3d then
				do  level =0,nlevels-1,d_levels 	
					if(var_id.eq.last_overlay_id.or. .not.isoverlay(var_id) )then							
							plot_hcenter1_3d(var_id,level)=gsn_add_polymarker(wks,plot_1_3d(var_id,level),clon_a(it),clat_a(it),dotres)
							plot_hcenter2_3d(var_id,level)=gsn_add_polymarker(wks,plot_2_3d(var_id,level),clon_b(it),clat_b(it),dotres)
					end if
				end do
			end if

			if hurricane_center_dot_2d then
				if(var_id.eq.last_overlay_id .or. .not.isoverlay(var_id) )then				
						plot_hcenter1_2d(var_id)=gsn_add_polymarker(wks,plot_1_2d(var_id),clon_a(it),clat_a(it),dotres)
						plot_hcenter2_2d(var_id)=gsn_add_polymarker(wks,plot_2_2d(var_id),clon_b(it),clat_b(it),dotres)
				end if
			end if



		end if 



		;----------------
		;add the dot for the trajectory 	;????#################
		;----------------
		if (plot_figure.and.add_dot) then


			dotres = True
			dotres@gsMarkerColor = "Red"
			dotres@gsMarkerIndex = 16
			dotres@gsMarkerSizeF = 0.005

			loc=wrf_user_ll_to_ij(a,lon_dot(it),lat_dot(it),res)
			print("dot lon "+loc(0))
			print("dot lat "+loc(1))

			if dot_3d then  ; have dots at all levels
				if((num_overlay_3d .eq. total_num_overlay_3d) .or. .not.isoverlay(var_id) )then	
									;only add after overlay all variables finished
					do level =0,nlevels-1,d_levels 	
	 		plot_dot1_3d(var_id,level)=gsn_add_polymarker(wks,plot_1_3d(var_id,level),lon_dot(it),lat_dot(it),dotres)
	 		plot_dot2_3d(var_id,level)=gsn_add_polymarker(wks,plot_2_3d(var_id,level),lon_dot(it),lat_dot(it),dotres)
					end do
				end if
			else
				if((num_overlay_2d .eq. total_num_overlay_2d) .or. .not.isoverlay(var_id) )then	
				plot_dot1_2d(var_id)=gsn_add_polymarker(wks,plot_1_2d(var_id),lon_dot(it),lat_dot(it),dotres)
	 			plot_dot2_2d(var_id)=gsn_add_polymarker(wks,plot_2_2d(var_id),lon_dot(it),lat_dot(it),dotres)
				end if
			end if

		end if
		

		;=================
		; calculate average for some variables
		;====================	

		if ( average_domain .or. average_around_center) then
				
			if ( average_domain ) then			;???### set the domain, the same as in the vertical-profile.ncl

				lat_s_a=lat_s0							
				lat_n_a=lat_n0
				lon_w_a=lon_w0
				lon_e_a=lon_e0
				lat_s_b=lat_s_a							
				lat_n_b=lat_n_a
				lon_w_b=lon_w_a
				lon_e_b=lon_e_a
			end if

			if (average_around_center)then	
		
				if search_hurricane_center then
					lat_s_a=clat_a-deviation_from_center						
					lat_n_a=clat_a+deviation_from_center
					lon_w_a=clon_a-deviation_from_center
					lon_e_a=clon_a+deviation_from_center

					lat_s_b=clat_b-deviation_from_center							
					lat_n_b=clat_b+deviation_from_center
					lon_w_b=clon_b-deviation_from_center
					lon_e_b=clon_b+deviation_from_center
				end if

				if read_center then
					lat_s_a=clat_a(it)-deviation_from_center						
					lat_n_a=clat_a(it)+deviation_from_center
					lon_w_a=clon_a(it)-deviation_from_center
					lon_e_a=clon_a(it)+deviation_from_center

					lat_s_b=clat_b(it)-deviation_from_center							
					lat_n_b=clat_b(it)+deviation_from_center
					lon_w_b=clon_b(it)-deviation_from_center
					lon_e_b=clon_b(it)+deviation_from_center

					if(var_name(var_id).eq."AEJ_max")then
						lat_s_a=max( (/0,clat_a(it)-10./) )						
						lat_n_a=clat_a(it)
						lon_w_a=clon_a(it)-5.0
						lon_e_a=clon_a(it)+5.0

						lat_s_b=max( (/0,clat_b(it)-10./) )							
						lat_n_b=clat_b(it)
						lon_w_b=clon_b(it)-5.0
						lon_e_b=clon_b(it)+5.0
					end if

					if(var_name(var_id).eq."AEJ_avg")then
						lat_s_a=10.					
						lat_n_a=15.0
						lon_w_a=clon_a(it)-5.0
						lon_e_a=clon_a(it)+5.0

						lat_s_b=10.						
						lat_n_b=15.
						lon_w_b=clon_b(it)-5.0
						lon_e_b=clon_b(it)+5.0
					end if

				end if

			end if

			loc1_a = wrf_user_ll_to_ij(a, lon_w_a, lat_n_a, True)
			loc2_a = wrf_user_ll_to_ij(a, lon_e_a, lat_s_a, True)
			x_start_a = loc1_a(0) - 1
			x_end_a  = loc2_a(0) - 1
			y_start_a = loc2_a(1) - 1
			y_end_a   = loc1_a(1) - 1

			loc1_b = wrf_user_ll_to_ij(b, lon_w_b, lat_n_b, True)
			loc2_b = wrf_user_ll_to_ij(b, lon_e_b, lat_s_b, True)
			x_start_b = loc1_b(0) - 1
			x_end_b  = loc2_b(0) - 1
			y_start_b = loc2_b(1) - 1
			y_end_b   = loc1_b(1) - 1

			if(var_name(var_id).ne."wind_vector_2d".and.var_name(var_id).ne."wind_vector".and.var_name(var_id).ne."shear_vector")then		
				if(if_2d_var(var_id))then  ;(1) average for 2D variable

					if(var_name(var_id).ne."min_slp".and.var_name(var_id).ne."max_wind".and.var_name(var_id).ne."surface_max_wind".and.\
										var_name(var_id).ne."AEJ_max")then

						data_1_avgdomain_2d(it,var_id)=avg(data_1(y_start_a:y_end_a,x_start_a:x_end_a))
						data_2_avgdomain_2d(it,var_id)=avg(data_2(y_start_b:y_end_b,x_start_b:x_end_b))

						if have_diff then
							diff_avgdomain_2d(it,var_id)=data_1_avgdomain_2d(it,var_id)-data_2_avgdomain_2d(it,var_id)	
							if(data_2_avgdomain_2d(it,var_id).ne.0) then
								diff_percentage_avgdomain_2d(it,var_id)=diff_avgdomain_2d(it,var_id)/abs(data_2_avgdomain_2d(it,var_id))*100
							else
								diff_percentage_avgdomain_2d(it,var_id)=0.
							end if
						end if

					end if			

					if(var_name(var_id).eq."min_slp")then; use the minimum pressure for slp , not use slp average, they are different		;###???
						if search_hurricane_center then
							data_1_avgdomain_2d(it,var_id)=slp_center_a
							data_2_avgdomain_2d(it,var_id)=slp_center_b
						else

							slp_a = wrf_user_getvar(a, "slp",0)
							slp_b = wrf_user_getvar(b, "slp",0)

							;initial value for wind maximum
							slp_min_a=slp_a(y_start_a,x_start_a) 
							slp_min_b=slp_b(y_start_b,x_start_b) 

							;search the box
							do j = y_start_a,y_end_a
								do i = x_start_a,x_end_a	
									if (  slp_a(j,i) .le. slp_min_a) then
										i_a = i
										j_a = j
										slp_min_a= slp_a(j,i)
									end if
								end do
							end do	

							do j = y_start_b,y_end_b
								do i = x_start_b,x_end_b	
									if (  slp_b(j,i) .le. slp_min_b) then
										i_b = i
										j_b = j
										slp_min_b= slp_b(j,i)
									end if
								end do
							end do	

							data_1_avgdomain_2d(it,var_id)=slp_min_a
							data_2_avgdomain_2d(it,var_id)=slp_min_b
							lon_min_slp_a=xlon(j_a,i_a)
							lat_min_slp_a=xlat(j_a,i_a)
							lon_min_slp_b=xlon(j_b,i_b)
							lat_min_slp_b=xlat(j_b,i_b)

							print("minimum slp lon lat in file1 "+lon_min_slp_a+" "+lat_min_slp_a)
							print("minimum slp lon lat in file2 "+lon_min_slp_b+" "+lat_min_slp_b)

							checkfile="echo minimum slp lon lat in file1 "+lon_min_slp_a+" "+lat_min_slp_a+"  >>"+wks_name+".txt"
							system(checkfile)
							checkfile="echo  minimum slp lon lat in file2 "+lon_min_slp_b+" "+lat_min_slp_b+"  >>"+wks_name+".txt"
							system(checkfile)

							
						end if

						print("minimum pressure is  "+data_1_avgdomain_2d(it,var_id)+" "+data_2_avgdomain_2d(it,var_id))
						checkfile="echo minimum slp is "+data_1_avgdomain_2d(it,var_id)+" "+data_2_avgdomain_2d(it,var_id)+"  >>"+wks_name+".txt"
						system(checkfile)
						
						if have_diff then
							diff_avgdomain_2d(it,var_id)=data_1_avgdomain_2d(it,var_id)-data_2_avgdomain_2d(it,var_id)	
							diff_percentage_avgdomain_2d(it,var_id)=diff_avgdomain_2d(it,var_id)/\
																				abs(data_2_avgdomain_2d(it,var_id))*100						
						end if

					end if

					if(var_name(var_id).eq."max_wind".or.var_name(var_id).eq."surface_max_wind")then


						u_a = wrf_user_getvar(a,"ua",0) 
						v_a= wrf_user_getvar(a,"va",0)  
						wind_a = sqrt(u_a^2+v_a^2)
						u_b = wrf_user_getvar(b,"ua",0) 
						v_b= wrf_user_getvar(b,"va",0)  
						wind_b = sqrt(u_b^2+v_b^2)

						u10_a = wrf_user_getvar(a,"U10",0) 
						v10_a= wrf_user_getvar(a,"V10",0)  
						wind10_a = sqrt(u10_a^2+v10_a^2)
						u10_b = wrf_user_getvar(b,"U10",0) 
						v10_b= wrf_user_getvar(b,"V10",0)  
						wind10_b = sqrt(u10_b^2+v10_b^2)

						;initial value for wind maximum
						if (var_name(var_id).eq."max_wind")then

							p_avg=   dim_avg_n(p, (/1,2/))  
							wind_level_index=closest_val(850,p_avg) 	;???###		use 850 maximum wind
							wind_plane_a=wind_a(wind_level_index,:,:)
							wind_plane_b=wind_b(wind_level_index,:,:)


						else	;10meter wind

							wind_plane_a=wind10_a(:,:)
							wind_plane_b=wind10_b(:,:) 	

						end if

						wind_max_a=wind_plane_a(y_start_a,x_start_a) 
						wind_max_b=wind_plane_b(y_start_b,x_start_b) 

						;search the box
						do j = y_start_a,y_end_a
							do i = x_start_a,x_end_a	
								if( wind_plane_a(j,i).ge.wind_max_a)then 
									i_a = i
									j_a = j
									wind_max_a=wind_plane_a(j_a,i_a)
								end if
							end do
						end do	

						do j = y_start_b,y_end_b
							do i = x_start_b,x_end_b	
								if( wind_plane_b(j,i).ge.wind_max_b)then 
									i_b = i
									j_b = j
									wind_max_b=wind_plane_b(j_b,i_b)
								end if
							end do
						end do	
			
						data_1_avgdomain_2d(it,var_id)=wind_max_a
						data_2_avgdomain_2d(it,var_id)=wind_max_b
						lon_wind_max_a=xlon(j_a,i_a)
						lat_wind_max_a=xlat(j_a,i_a)
						lon_wind_max_b=xlon(j_b,i_b)
						lat_wind_max_b=xlat(j_b,i_b)

						print("maximum wind is  "+data_1_avgdomain_2d(it,var_id)+" "+data_2_avgdomain_2d(it,var_id))
						print("maximum wind lon lat in file1 "+lon_wind_max_a+" "+lat_wind_max_a)
						print("maximum wind lon lat in file2 "+lon_wind_max_b+" "+lat_wind_max_b)

						checkfile="echo maximum wind is "+data_1_avgdomain_2d(it,var_id)+" "+data_2_avgdomain_2d(it,var_id)+"  >>"+wks_name+".txt"
						system(checkfile)
						checkfile="echo maximum wind lon lat in file1 "+lon_wind_max_a+" "+lat_wind_max_a+"  >>"+wks_name+".txt"
						system(checkfile)
						checkfile="echo  maximum wind lon lat in file2 "+lon_wind_max_b+" "+lat_wind_max_b+"  >>"+wks_name+".txt"
						system(checkfile)

						if have_diff then
							diff_avgdomain_2d(it,var_id)=data_1_avgdomain_2d(it,var_id)-data_2_avgdomain_2d(it,var_id)	
							diff_percentage_avgdomain_2d(it,var_id)=diff_avgdomain_2d(it,var_id)/\
																				abs(data_2_avgdomain_2d(it,var_id))*100						
						end if

					end if	

					if(var_name(var_id).eq."AEJ_max")then

						AEJ_max_a=AEJ_1(y_start_a,x_start_a)
						AEJ_max_b=AEJ_2(y_start_b,x_start_b)
						;search the box
						do j = y_start_a,y_end_a
							do i = x_start_a,x_end_a	
								if( AEJ_1(j,i).ge.AEJ_max_a)then ;ua is negative
									i_a = i
									j_a = j
									AEJ_max_a=AEJ_1(j_a,i_a)
								end if
							end do
						end do	

						;search the box
						do j = y_start_b,y_end_b
							do i = x_start_b,x_end_b	
								if( AEJ_2(j,i).ge.AEJ_max_b)then
									i_b = i
									j_b = j
									AEJ_max_b=AEJ_2(j_b,i_b)
								end if
							end do
						end do	

						data_1_avgdomain_2d(it,var_id)=AEJ_max_a
						data_2_avgdomain_2d(it,var_id)=AEJ_max_b
						lon_AEJ_a=xlon(j_a,i_a)
						lat_AEJ_a=xlat(j_a,i_a)
						lon_AEJ_b=xlon(j_b,i_b)
						lat_AEJ_b=xlat(j_b,i_b)
						print("maximum wind is  "+data_1_avgdomain_2d(it,var_id)+" "+data_2_avgdomain_2d(it,var_id))
						print("maximum wind lon lat in file1 "+lon_AEJ_a+" "+lat_AEJ_a)
						print("maximum wind lon lat in file2 "+lon_AEJ_b+" "+lat_AEJ_b)

						checkfile="echo maximum wind is "+data_1_avgdomain_2d(it,var_id)+" "+data_2_avgdomain_2d(it,var_id)+"  >>"+wks_name+".txt"
						system(checkfile)
						checkfile="echo maximum wind lon lat in file1 "+lon_AEJ_a+" "+lat_AEJ_a+"  >>"+wks_name+".txt"
						system(checkfile)
						checkfile="echo  maximum wind lon lat in file2 "+lon_AEJ_b+" "+lat_AEJ_b+"  >>"+wks_name+".txt"
						system(checkfile)

						if have_diff then
							diff_avgdomain_2d(it,var_id)=data_1_avgdomain_2d(it,var_id)-data_2_avgdomain_2d(it,var_id)	
							diff_percentage_avgdomain_2d(it,var_id)=diff_avgdomain_2d(it,var_id)/\
																				abs(data_2_avgdomain_2d(it,var_id))*100						
						end if

					end if					
		
				else   	;(2)average for 3D variable


					data_1_avgdomain_3d_modellevel(it,var_id,:)=dim_avg_n(data_1(:,y_start_a:y_end_a,x_start_a:x_end_a),(/1,2/))
					data_2_avgdomain_3d_modellevel(it,var_id,:)=dim_avg_n(data_2(:,y_start_b:y_end_b,x_start_b:x_end_b),(/1,2/))

					if have_diff then
						diff_avgdomain_3d_modellevel(it,var_id,:)=data_1_avgdomain_3d_modellevel(it,var_id,:)-data_2_avgdomain_3d_modellevel(it,var_id,:)	
						do k=0,klev-1
							if(data_2_avgdomain_3d_modellevel(it,var_id,k).ne.0) then
								diff_percentage_avgdomain_3d_modellevel(it,var_id,k)=\
												diff_avgdomain_3d_modellevel(it,var_id,k)/abs(data_2_avgdomain_3d_modellevel(it,var_id,k))*100
							else
								diff_percentage_avgdomain_3d_modellevel(it,var_id,k)=0.
							end if
						end do
					end if

					;interpolate to height level
					do k=0,nheight-1
						data_1_avgdomain_3d(it,var_id,k)=data_1_avgdomain_3d_modellevel(it,var_id,model_vertical_index(k))	
						data_2_avgdomain_3d(it,var_id,k)=data_2_avgdomain_3d_modellevel(it,var_id,model_vertical_index(k))	
						if have_diff then	
							diff_avgdomain_3d(it,var_id,k)=diff_avgdomain_3d_modellevel(it,var_id,model_vertical_index(k))					
							diff_percentage_avgdomain_3d(it,var_id,k)=diff_percentage_avgdomain_3d_modellevel(it,var_id,model_vertical_index(k))		
						end if
					end do

				end if

			end if


		end if
			;end of average

		;------------------------
		; get  station aod
		;--------------------
		if output_station then

			do station_id=0,num_stations-1

				loc=wrf_user_ll_to_ij(a,station_lon(station_id),station_lat(station_id),True)
				i=loc(0)
				j=loc(1)
				station_data1(it,var_id,station_id)=data_1(j,i)
				station_data2(it,var_id,station_id)=data_2(j,i)
			
			end do

		end if

		;---------
		; delete variable
		;----------
		delete(opts) 
		if have_diff then
			if(.not.average_domain .and. .not.average_around_center)
				delete(opts_diff)
			end if
		end if

		if(var_name(var_id) .eq. "wind_vector" .or. var_name(var_id) .eq. "wind_vector_2d" .or.var_name(var_id) .eq."shear_vector")then
			delete(data_1_uu)	;delete 2D variable
			delete(data_1_vv)
			delete(data_2_uu)
			delete(data_2_vv)
			if have_diff then
				delete(diff_uu)
				delete(diff_vv)
			end if

		  	if(if_2d_var(var_id) .eq. "False")then  ;delete 3D variable
				if(.not.average_domain .and. .not.average_around_center)
					delete(data_1_uu_plane)
					delete(data_1_vv_plane)
					delete(data_2_uu_plane)
					delete(data_2_vv_plane)
					if have_diff then
						delete(diff_uu_plane)
						delete(diff_vv_plane)
					end if
				end if
		 	 end if

		else   ;delete non-vector variable
			delete(data_1)	;delete 2D variable
			delete(data_2)
			if have_diff then
				delete(diff)
			end if


		    if(if_2d_var(var_id) .eq. "False")then ;delete 3D variable
				if(.not.average_domain .and. .not.average_around_center)
					delete(data_1_plane)
					delete(data_2_plane)
					if have_diff then
						delete(diff_plane)
					end if
				end if
		    end if
		end if

		if(if_2d_var(var_id) .eq. "False")then
			if(.not.average_domain .and. .not.average_around_center)
				if(level_type .eq.3 )then
					delete(z_plane)
				end if

				if(level_type .eq.2 )then
					delete(p_plane)
				end if
			end if
		end if


	end do 				; 3000			

	;END OF VARIABLE LOOP

	;----------------------
	; begin the panel plot
	;----------------------
	if plot_figure then
												
		resP            = True                        
		resP@gsnPanelLabelBar    = False ;???##  
		resP@gsnMaximize=True 
		;resP@lbOrientation="vertical"
		;resP@gsnFrame         = False
		resP@gsnPanelMainString = time_name(it)
		print("outout plots")
	    checkfile="echo outout plots  >>"+wks_name+".txt"
		system(checkfile)

		if plot_3d then  	; (1) 3D variable

			do var_id=0,var_numbers-1,1

				if(	.not. isoverlay(var_id).or.(isoverlay(var_id).and.var_id.eq.last_overlay_id) )then
					if(.not.if_2d_var(var_id) )then	
		
							do k=0,nlevels-1,5		;???###
								gsn_panel(wks,(/plot_1_3d(var_id,k),plot_2_3d(var_id,k),plot_diff_3d(var_id,k),\
								plot_1_3d(var_id,k+1),plot_2_3d(var_id,k+1),plot_diff_3d(var_id,k+1),\
								plot_1_3d(var_id,k+2),plot_2_3d(var_id,k+2),plot_diff_3d(var_id,k+2),\
								plot_1_3d(var_id,k+3),plot_2_3d(var_id,k+3),plot_diff_3d(var_id,k+3),\
								plot_1_3d(var_id,k+4),plot_2_3d(var_id,k+4),plot_diff_3d(var_id,k+4)/),(/5,3/),resP)
							end do
					end if
				end if

			end do
			

		else 	; (2) 2D
	 
	   		do var_id=0,var_numbers-1,1		
				if(	.not. isoverlay(var_id).or.(isoverlay(var_id).and.var_id.eq.last_overlay_id) )then
					if(if_2d_var(var_id) )then	
						if have_diff then	
							gsn_panel(wks,(/plot_1_2d(var_id),plot_2_2d(var_id),plot_diff_2d(var_id)/),(/1,3/),resP)
						else
							gsn_panel(wks,(/plot_1_2d(var_id),plot_2_2d(var_id)/),(/1,2/),resP)
						end if
					end if
				end if
	   		end do
			
		end if
	end if

end do 
;---------------
;end of time loop   2000
;-----------------




;-------------------
;output average and correlation
;------------------

if  average_domain .or. average_around_center then	
	resP            = True                        
	resP@gsnMaximize=True 
	;resP@lbOrientation="vertical"
	;resP@gsnFrame         = False

	;-----------------
	; resources for XY plot
	;-------------

	
	ntimes2=time_end-start_time+1
	comma_array=new((/ntimes2/),"string")
	do i=0,ntimes2-1,1
		comma_array(i)=","
	end do
    comma=","
	name1="rm  "+"domain-average.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt"
	name2="rm  "+"domain-average-diff-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt"
	name3="rm  "+"domain-average-data1-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt"
	name4="rm  "+"domain-average-data2-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt"
	system(name1)
	system(name2)
	system(name3)
	system(name4)

	;-----------output data------------
	write_table("domain-average.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","w",[/"time",comma,"level",comma,"variable name",comma,"data1",comma,\
		"data2",comma,"difference",comma,"different(percentage)"/], "%s   %s   %s  %s    %s  %s   %s     %s   %s      %s    %s   %s   %s")

	do var_id=0,var_numbers-1,1
		if if_2d_var(var_id) then ;2D variable
			tem1=time_name(start_time:time_end)
			tem2=data_1_avgdomain_2d(start_time:time_end,var_id)
			tem3=data_2_avgdomain_2d(start_time:time_end,var_id)
			tem4=diff_avgdomain_2d(start_time:time_end,var_id)
			tem5=diff_percentage_avgdomain_2d(start_time:time_end,var_id) 

			surface_array=new((/ntimes2/),"string")
			var_name_array=new((/ntimes2/),"string")
			do i=0,ntimes2-1,1
				surface_array(i)="surface"
				var_name_array(i)=var_name(var_id)
			end do

			write_table("domain-average.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a", [/tem1,comma_array,surface_array,comma_array,var_name_array, comma_array,tem2,comma_array,tem3,\
						comma_array,tem4,comma_array,tem5/], "%s    %s     %s    %s      %s              %s  %9.4f %s %9.4f  %s %9.4f %s  %9.4f")  
			  
		else
			do lev=0,nheight-1	;3D variable
				tem1=time_name(start_time:time_end)
				temp2=data_1_avgdomain_3d(start_time:time_end,var_id,lev)
				temp3=data_2_avgdomain_3d(start_time:time_end,var_id,lev)
				temp4=diff_avgdomain_3d(start_time:time_end,var_id,lev)
				temp5=diff_percentage_avgdomain_3d(start_time:time_end,var_id,lev) 

				level_info2_array=new((/ntimes2/),"string")
				var_name_array=new((/ntimes2/),"string")

				do i=0,ntimes2-1,1
					level_info2_array(i)=level_info2(lev)
					var_name_array(i)=var_name(var_id)
				end do

				write_table("domain-average.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a", [/tem1,comma_array,level_info2_array,comma_array,var_name_array,comma_array,temp2,comma_array,temp3,\
					comma_array,temp4,comma_array,temp5/], "%s    %s      %s          %s    %s     %s   %9.4f %s %9.4f  %s %9.4f    %s  %9.4f")  			
			end do
		end if
	end do 

	;----------------compute  correlation---------------
	lag=0				;???###
	significant=0.05	;???###	
	sample_size=time_end-start_time+1

	;common resources
	resL                        = True 						
	resL@tiMainFontHeightF  = 0.015
	resL@tmXBMode = "Explicit" 	
	xstride=4										;???##  ;  only label those values
	time=ispan(start_time,time_end,1) 				 ;don't change , x axis value
	resL@tmXBMinorValues=ispan(start_time,time_end,1);don't change , tick every x axis value
	resL@tmXBValues = ispan(start_time,time_end,xstride) 
	newtimelength=tointeger((time_end-start_time)/xstride)
	tickmarklablestring=new((/newtimelength+1/),"string")
	do i=0,newtimelength
		tickmarklablestring(i)=time_name2(start_time+i*xstride)
	end do
	resL@tmXBLabels =tickmarklablestring
	resL@tmXBLabelStride		=1
	;resL@tmXBMajorLengthF = 0.021
  	;resL@tmXBMinorLengthF = 0.008

	resL@xyLineThicknesses      = 2.                  ; thicker line
	resL@xyMarkLineMode = "MarkLines"    ; Markers *and* lines	
	resL@xyMarkers      = (/1/)    		; 3 different markers
	resL@xyMarkerSizeF=0.05
	resR                        = True                      
	resR@xyDashPatterns         = 1                   ; dashed line for 2nd
	resR@xyLineThicknesses      = 2                   ; thicker line
	resR@xyMarkLineMode = "MarkLines"    ; Markers *and* lines	
	resR@xyMarkers      = (/7/)    		; 3 different markers
	resR@xyMarkerSizeF=0.02


	do i=0,var_numbers-1,1		;loop over variable 
		do j=i+1,var_numbers-1,1	;???### NCL is slow, so I set j=i, if you want to correlate the variable itself, make j=i

 ;(1) 2D correlate 2D
			if if_2d_var(i) .and. if_2d_var(j)  
				if(i.ne.j)then
					correlation_1=esccr(data_1_avgdomain_2d(start_time:time_end,i),data_1_avgdomain_2d(start_time:time_end,j),lag)
					correlation_2=esccr(data_2_avgdomain_2d(start_time:time_end,i),data_2_avgdomain_2d(start_time:time_end,j),lag)
					correlation_diff=esccr(diff_avgdomain_2d(start_time:time_end,i),diff_avgdomain_2d(start_time:time_end,j),lag)

					
			;output data1
					;plot the data											
			

					if(rtest(correlation_1,sample_size,0).lt.significant)then
						write_table("domain-average-data1-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",\
						[/"significant correlation",comma,"surface",comma,var_name(i),comma,"  and  ",comma,"surface",\
						comma,var_name(j),comma," is ",comma,correlation_1/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")

						

					else
						write_table("domain-average-data1-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",\
										[/"insignificant correlation",comma,"surface",comma,var_name(i),comma,"  and  ",comma,"surface"\
										,comma,var_name(j),comma," is ",comma,correlation_1/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")
					end if

					;plot the  data											
					resL@tiMainString      ="2D/2D data1 "+var_name(i)+" / "+var_name(j)+"  at  surface,"+" correlation "+correlation_1
					resL@tiYAxisString = var_name(i) +"  "+"[solid]"  ; axis string						
					resR@tiYAxisString = var_name(j) +"  "+"[dash]"   ; axis string

					plot_time_series_2d_2d = gsn_csm_xy2(wks,time,data_1_avgdomain_2d(start_time:time_end,i),\
																	  data_1_avgdomain_2d(start_time:time_end,j),resL,resR)


			;output data2

					;plot the data											
					

					if(rtest(correlation_2,sample_size,0).lt.significant)then
						write_table("domain-average-data2-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"significant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
							,comma,"surface",comma,var_name(j),comma," is ",comma,correlation_2/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")

						

					else
						write_table("domain-average-data2-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"insignificant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
							,comma,"surface",comma,var_name(j),comma," is ",comma,correlation_2/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")
					end if

					;plot the significant data												
					resL@tiMainString  ="2D/2D data2 "+var_name(i)+" / "+var_name(j)+"  at  surface,"+" correlation "+correlation_2		         
					resL@tiYAxisString = var_name(i) +"  "+"[solid]"  ; axis string						
					resR@tiYAxisString = var_name(j) +"  "+"[dash]"   ; axis string
				
					plot_time_series_2d_2d = gsn_csm_xy2(wks,time,data_2_avgdomain_2d(start_time:time_end,i),\
																	  data_2_avgdomain_2d(start_time:time_end,j),resL,resR)



			;output diff

					;plot the data											
				

					if(rtest(correlation_diff,sample_size,0).lt.significant)then						
						write_table("domain-average-diff-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"significant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
							,comma,"surface",comma,var_name(j),comma," is ",comma,correlation_diff/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")

						
					else
						write_table("domain-average-diff-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"insignificant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
							,comma,"surface",comma,var_name(j),comma," is ",comma,correlation_diff/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")
					end if

					;plot the significant data

					resL@tiMainString  ="2D/2D  diff "+var_name(i)+" / "+var_name(j)+"  at  surface,"+" correlation "+correlation_diff			              
					resL@tiYAxisString = var_name(i) +"  "+"[solid]"  ; axis string						                
					resR@tiYAxisString = var_name(j) +"  "+"[dash]"   ; axis string
				
					plot_time_series_2d_2d_diff = gsn_csm_xy2(wks,time,diff_avgdomain_2d(start_time:time_end,i),\
																	  diff_avgdomain_2d(start_time:time_end,j),resL,resR)



				end if

			end if

 ;(2) 2D correlate 3D
			if ((if_2d_var(i).eq."True") .and. (if_2d_var(j).eq."False")) then 
				do lev2=0,nheight-1	;loop over 3D variable
					correlation_1=esccr(data_1_avgdomain_2d(start_time:time_end,i),data_1_avgdomain_3d(start_time:time_end,j,lev2),lag)
					correlation_2=esccr(data_2_avgdomain_2d(start_time:time_end,i),data_2_avgdomain_3d(start_time:time_end,j,lev2),lag)
					correlation_diff=esccr(diff_avgdomain_2d(start_time:time_end,i),diff_avgdomain_3d(start_time:time_end,j,lev2),lag)
					

			;output data1

					;plot the data											
				


					if(rtest(correlation_1,sample_size,0).lt.significant)then
						write_table("domain-average-data1-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",\
						[/"significant correlation",comma,"surface",comma,var_name(i),comma,"  and  ",comma,level_info2(lev2),\
							comma,var_name(j),comma," is ",comma,correlation_1/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")

						


					else
						write_table("domain-average-data1-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"insignificant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
							,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_1/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")
					end if

					;plot the significant data
									
					resL@tiMainString      ="2D/3D data1  "+var_name(i)+" / "+var_name(j)+"  at  "+level_info2(lev2)+" level,"\
																+" correlation "+correlation_1					                
					resL@tiYAxisString = var_name(i) +"  "+"[solid]"  ; axis string					
					resR@tiYAxisString = var_name(j) +"  "+"[dash]"   ; axis string
					 
					plot_time_series_2d_3d = gsn_csm_xy2(wks,time,data_1_avgdomain_2d(start_time:time_end,i),\
																	  data_1_avgdomain_3d(start_time:time_end,j,lev2),resL,resR)


			;output data2

					

					if(rtest(correlation_2,sample_size,0).lt.significant)then
						write_table("domain-average-data2-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"significant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
							,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_2/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")

					

					else
						write_table("domain-average-data2-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"insignificant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
							,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_2/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")
					end if

					;plot the significant data
									
					resL@tiMainString      ="2D/3D data2  "+var_name(i)+" / "+var_name(j)+"  at  "+level_info2(lev2)+" level,"\
																+" correlation "+correlation_2					                
					resL@tiYAxisString = var_name(i) +"  "+"[solid]"  ; axis string					
					resR@tiYAxisString = var_name(j) +"  "+"[dash]"   ; axis string
					 
					plot_time_series_2d_3d = gsn_csm_xy2(wks,time,data_2_avgdomain_2d(start_time:time_end,i),\
																	  data_2_avgdomain_3d(start_time:time_end,j,lev2),resL,resR)

			;output diff

					;plot the data											
					

					if(rtest(correlation_diff,sample_size,0).lt.significant)then
						write_table("domain-average-diff-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"significant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
						,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_diff/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")		

						


					else
						write_table("domain-average-diff-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"insignificant correlation",comma,"surface",comma,var_name(i),comma,"  and  "\
							,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_diff/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")	
					end if

					;plot the significant data
								
					resL@tiMainString      ="2D/3D diff  "+var_name(i)+" / "+var_name(j)+"  at  "+level_info2(lev2)+" level,"\
																			+" correlation "+correlation_diff
					resL@tiYAxisString = var_name(i) +"  "+"[solid]"  ; axis string					
					resR@tiYAxisString = var_name(j) +"  "+"[dash]"   ; axis string
				
					plot_time_series_2d_3d_diff = gsn_csm_xy2(wks,time,diff_avgdomain_2d(start_time:time_end,i),\
																	  diff_avgdomain_3d(start_time:time_end,j,lev2),resL,resR)

				end do
			end if

 ;(3) 3D correlate 3D
			if ((if_2d_var(i).eq."False") .and. (if_2d_var(j).eq."False")) then 
				do lev1=0,nheight-1		;loop on the first variable
					if(i.eq.j)then
						index=lev1+1		;avoid double count for the same variable
					else
						index=0
					end if
					do lev2=index,nheight-1  ;loop on the second variable
						if((i.ne.j).or.(lev1.ne.lev2))then
							correlation_1=esccr(data_1_avgdomain_3d(start_time:time_end,i,lev1),data_1_avgdomain_3d(start_time:time_end,j,lev2),lag)
							correlation_2=esccr(data_2_avgdomain_3d(start_time:time_end,i,lev1),data_2_avgdomain_3d(start_time:time_end,j,lev2),lag)
							correlation_diff=esccr(diff_avgdomain_3d(start_time:time_end,i,lev1),diff_avgdomain_3d(start_time:time_end,j,lev2),lag)
							
							;output data1
							if(rtest(correlation_1,sample_size,0).lt.significant)then
					write_table("domain-average-data1-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"significant correlation",comma,level_info2(lev1),comma,var_name(i),comma,"  and  "\
						,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_1/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")		
							else
					write_table("domain-average-data1-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"insignificant correlation",comma,level_info2(lev1),comma,var_name(i),comma,"  and  "\
						,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_1/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")	
							end if

							;output data2
							if(rtest(correlation_2,sample_size,0).lt.significant)then
					write_table("domain-average-data2-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt"+".txt","a",[/"significant correlation",comma,level_info2(lev1),comma,var_name(i),comma,"  and  "\
						,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_2/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")	
							else
					write_table("domain-average-data2-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt"+".txt","a",[/"insignificant correlation",comma,level_info2(lev1),comma,var_name(i),comma,"  and  "\
						,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_2/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")	
							end if

							;output diff
							if(rtest(correlation_diff,sample_size,0).lt.significant)then
					write_table("domain-average-diff-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"significant correlation",comma,level_info2(lev1),comma,var_name(i),comma,"  and  "\
						,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_diff/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")	
							else
					write_table("domain-average-diff-correlation.txt"+"-"+var_name(0)+"-"+var_name(1)+".txt","a",[/"insignificant correlation",comma,level_info2(lev1),comma,var_name(i),comma,"  and  "\
						,comma,level_info2(lev2),comma,var_name(j),comma," is ",comma,correlation_diff/], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %9.4f")	

							end if
						end if
					end do
				end do
			end if

		end do
	end do


end if


;----------------
; AOD
;------------------
if output_station then


	system("rm station.txt")
	ntimes2=time_end-start_time+1
	comma = ","
	write_table("station.txt","w",[/"variable name",comma, "station name",comma,"time", comma, " data1",	comma, "data2"/],\
																	 "%s %s %s %s  %s %s %s %s %s ") 

	do var_id=0,var_numbers-1

		do station_id=0,num_stations-1

			station_nanme_array=new((/ntimes2/),"string")
			var_name_array2=new((/ntimes2/),"string")
			comma_array=new((/ntimes2/),"string")
			do i=0,ntimes2-1,1
				station_nanme_array(i)=station_name(station_id)
				var_name_array2(i)=var_name(var_id)
				comma_array(i)=","
			end do

			
		
			temm1=time_name(start_time:time_end)
			temm2=station_data1(start_time:time_end,var_id,station_id)
			temm3=station_data2(start_time:time_end,var_id,station_id)
			write_table("station.txt","a",[/var_name_array2,comma_array,station_nanme_array,comma_array,temm1, comma_array, temm2,	comma_array, temm3/],\
												 "%s %s %s %s  %s %s %9.4f %s %9.4f ") 

		end do

	end do
	delete(var_name_array2)
	;output_station_map 

	res             = True                              ; plot mods desired
	;res@gsnFrame    = False                             ; don't advance yet
	res@gsnMaximize = True

	res@mpMinLatF = 5
	res@mpMaxLatF = 35
	res@mpMinLonF = -30
	res@mpMaxLonF = 20
	res@tiMainString = "Locations of stations"

	map = gsn_csm_map(wks,res)                ; Create the map plot, don't draw

	mkres               = True
	mkres@gsMarkerIndex = 12
	mkres@gsMarkerColor = "Red"
	mkres@gsMarkerSizeF = 15.        ; Increase marker sizes.
	dum = gsn_add_polymarker(wks,map,station_lon,station_lat,mkres)

	txres               = True
	txres@txFontHeightF = 0.007
	txres@txFont        = "helvetica-bold"
	txres@txFontColor="Blue"

	dum2 = gsn_add_text(wks,map,station_name,station_lon,station_lat,txres)
	draw(map)


end if





end	
