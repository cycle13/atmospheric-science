load "$NCARG_ROOT/lib/ncarg/nclex/gsun/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
; the difference is a-b,plot order is a, b, diff

begin
;=================================================
;plot the profile in every time step and the average profile
;=============================================

dir_a="/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/2010/mosaic/coarse/full/"
dir_b="/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/2010/mosaic/coarse/seas-sulfate-bc-oc/"
 													;???####

namelist2 = "/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/ncl/namelist-cross"  ;?????????
filename     = asciiread(namelist2,-1,"string") 
ntimes   = dimsizes(filename)
print(filename)

set=1
zmax=15   						;???## the heighest level, if your top is 200hpa, write 200., if it is 10km, write 10. 
vertical_type=1					;???### 1 is the height coordinate, 2 is pressure coordinate
zstart_index=1					; model level. plot above that level
add_extra_line=False				;??### ;??### add extra line to the horizontal map , they are copy from the diff-cross-section.ncl						
add_extra_line_maxip=2    		;??### 2 is two cross section at the same time
start_time=0					;???### 0 is the first time, you can specify 
end_time=999						;???### 999 means at the end of time, you can specify
moving_domain=False
nest=False	
average_time=True
;======================
; set up domain		;???### !! be careful, the time here should match  namelist , otherwise, if start_time .ne.0, may cause mismatch
;==========================
lat_s=new((/1000/),"float")
lat_n=new((/1000/),"float")
lon_w=new((/1000/),"float")
lon_e=new((/1000/),"float")

if .not. moving_domain then
	;----------
	; (1) fix domain
	;-------------
	do i=0,200
		;land
		    lat_s(i)=12.0           ;????######set the domain
		    lat_n(i)=25.0
		    lon_w(i)=-10.0
		    lon_e(i)=10.0

		;land ocean
		  ;  lat_s(i)=12.0           ;????######set the domain
		   ; lat_n(i)=25.0
		    ;lon_w(i)=-23.0
		    ;lon_e(i)=-10.0

		;ocean
		 ;   lat_s(i)=10.0           ;????######set the domain
		  ;  lat_n(i)=22.0
		   ; lon_w(i)=-28.0
		    ;lon_e(i)=-18.0

		;for output tc whole column average
		    lat_s(i)=12.0           ;????######set the domain
		    lat_n(i)=25.0
		    lon_w(i)=-15.0
		    lon_e(i)=10.0

	end do

else 
	;------------
	;(2) moving domain
	;--------------
	lat_s(:2)=(/15.0,12.0,15.0/)
	lat_n(:2)=(/25.0,25.0,25.0/)
	lon_w(:2)=(/-12.0,-15.0,-16.0/)
	lon_e(:2)=(/5.0,2.0,0.0/)

end if

;---------------
; add extra line to the horizontal map , they are copy from the diff-cross-section.ncl;  ;???###
;---------------

if add_extra_line then

	lat1_array_a=new((/ntimes,10/),"float")         ; cross sections
	lat2_array_a=new((/ntimes,10/),"float")
	lon1_array_a=new((/ntimes,10/),"float")
	lon2_array_a=new((/ntimes,10/),"float")
	lat1_array_b=new((/ntimes,10/),"float")        
	lat2_array_b=new((/ntimes,10/),"float")
	lon1_array_b=new((/ntimes,10/),"float")
	lon2_array_b=new((/ntimes,10/),"float")


	do ip=0,0
		    lat1_array_a(:2,ip)=10.
		    lat2_array_a(:2,ip)=30.
		    lon1_array_a(:2,ip)=(/-3,-5,-10/)
		    lon2_array_a(:2,ip)=(/-3,-5,-10/)
	end do

	do ip=1,1
		 	lat1_array_a(:2,ip)=10.
		    lat2_array_a(:2,ip)=30.
		    lon1_array_a(:2,ip)=(/-7.5,-9,-15/)
		    lon2_array_a(:2,ip)=(/-7.5,-9,-15/)
	end do

	lat1_array_b=lat1_array_a           			;???#### can give different value for data_2
	lat2_array_b=lat2_array_a
	lon1_array_b=lon1_array_a
	lon2_array_b=lon2_array_a 
 
end if
;---------
; end of extra line
;-------------

;================
; setting	;???####
;===========
if (set.eq.1) then  ;???### edit panel plot if you add or delete variables
	var_name=(/"EXTCOF55","RTHRATSW","RTHRATLW","RTHRATEN","H_DIABATIC","RTHCUTEN","total_moist_tendency","RTHBLTEN","RTHFTEN","total_tendency",\
"th","th_prediction","tc","td","rh","wind_speed","QVAPOR","QCLOUD","QNDROP","wa"/)

	exist_both_file=(/True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True/)
	in_restart_file=(/False,True,True,True,True,True,True,True,True,False,False,False,False,False,False,False,False,False,False,False/)

	;HFX
	;RTHFTEN:description = "TOTAL ADVECTIVE POTENTIAL TEMPERATURE TENDENCY" ; units = "K s-1" ;
	;RTHCUTEN:description = "COUPLED THETA TENDENCY DUE TO CUMULUS SCHEME" ;units = "Pa K s-1" ;
	;RTHRATEN:description = "COUPLED THETA TENDENCY DUE TO RADIATION" ; units = "Pa K s-1" ;
	; RTHBLTEN:description = "COUPLED THETA TENDENCY DUE TO PBL PARAMETERIZATION" ;units = "Pa K s-1" ;
;H_DIABATIC:description = "MICROPHYSICS LATENT HEATING" 
end if

if (set.eq.2) then
	var_name=(/"td","tc","rh","QVAPOR","wind_speed","ua"/)
	exist_both_file=(/True,True,True,True,True,True/)
	in_restart_file=(/False,False,False,False,False,False/)
end if

if (set.eq.3) then
	var_name=(/"tc"/)
	exist_both_file=(/True,True,True,True,True,True/)
	in_restart_file=(/False,False,False,False,False,False/)
end if


if (end_time.eq.999)then
	time_end=ntimes-1
else
	time_end=end_time
end if

; open work station
tmpname1=str_sub_str(filename(start_time),":","_")
tmpname2=str_sub_str(filename(time_end),":","_")
var_numbers=dimsizes(var_name)
	
if (var_numbers.eq.1) then
	wks_name="vertcal-profile-"+var_name(0)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.eq.2) then
	wks_name="vertcal-profile-"+var_name(0)+"-"+var_name(1)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.eq.3) then
	wks_name="vertcal-profile-"+var_name(0)+"-"+var_name(1)+"-"+var_name(2)+"-"+tmpname1+"-"+tmpname2  
end if
if(var_numbers.gt.3) then
	wks_name="vertcal-profile-"+var_name(0)+"-"+var_name(1)+"-"+var_name(2)+"-other-"+tmpname1+"-"+tmpname2  
end if

wks=gsn_open_wks("pdf",wks_name) 

gsn_define_colormap(wks,"cmp_flux")
rmfile="rm "+wks_name+".txt"
system(rmfile)
 

;==============
; define the plot array						;???########
;=======================	
plot=new((/50/),"graphic") 			;store data1(time,variable)
plot_avgtime=new((/50/),"graphic") 			
plot_diff=new((/50/),"graphic") 
plot_diff_avgtime=new((/50/),"graphic") 
plot_diff_percentage=new((/50/),"graphic") 
plot_diff_percentage_avgtime=new((/50/),"graphic") 

 
dum13=new((/10/),"graphic") 
dum14=new((/10/),"graphic") 
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

;----------------
;read restart
;---------------

restart_files=False
do id=0,var_numbers-1
	if(in_restart_file(id))then
		restart_files=True
		break
	end if
end do

res = True
;============
;begin the time loop
;==============  

do it=start_time,time_end,1	
	;  filename_a=dir_a+filename(it)+"_prior"+".nc"		;???######### this is for the diff in the da cycle
	;  filename_b=dir_b+filename(it)+"_prior"+".nc"
	; filename_a=dir_a+filename(it)+"_post"+".nc"		;???######### this is for the diff in the da cycle
	;  filename_b=dir_b+filename(it)+"_post"+".nc"
	filename_a=dir_a+filename(it)+".nc"			
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
   ; res@TimeLabel = times(0)   ; Set Valid time to use on plots

	;===============================
	; set domain
	;=============================

	loc1 = wrf_user_ll_to_ij(a, lon_w(it), lat_n(it), True)
	loc2 = wrf_user_ll_to_ij(a, lon_e(it), lat_s(it), True)
	x_start = loc1(0) - 1
	x_end   = loc2(0) - 1
	y_start = loc2(1) - 1
	y_end   = loc1(1) - 1
	print("x_start"+x_start)
	print("x_end"+x_end)
	print("y_start"+y_start)
	print("y_end"+y_end)


    ;---------
    ;get some useful variable 
    ;-----------   

	z1  = wrf_user_getvar(a, "z",0)        ; grid point height, units:m
	z2  = wrf_user_getvar(b, "z",0)        ; grid point height
	z=z1

	p1  = wrf_user_getvar(a, "pressure",0) ;units:hPa
	p2  = wrf_user_getvar(b, "pressure",0) 
	p=p1

    ;pb1  = wrf_user_getvar(a, "PB",0) 
    ;pb2  = wrf_user_getvar(b, "PB",0) 
	;ter = wrf_user_getvar(a, "HGT",0)
	;mu1= wrf_user_getvar(a, "MU",0)		;dry pressure, convert from couple to uncouple
	;mub1= wrf_user_getvar(a, "MUB",0)
	;mu2= wrf_user_getvar(b, "MU",0)
	;mub2= wrf_user_getvar(b, "MUB",0)

	slp_a = wrf_user_getvar(a, "slp",0)
	slp_b = wrf_user_getvar(b, "slp",0)
	slp_diff=slp_a-slp_b

	;=====================
	;getting maximum height, find the closest index
	;===================
	if (it.eq.start_time)then
		if (vertical_type.eq.1)then	;height 
			zmin=0.0
			zmax=zmax*1000
			z_profile=   dim_avg_n(z, (/1,2/))  ;units:m
			zspan=closest_val(zmax,z_profile) ; find the closest index
		else						;pressure
			p_profile=   dim_avg_n(p, (/1,2/)) 	;units:hPa 
			zmin=max(p_profile)
			zspan=closest_val(zmax,p_profile) 
		end if
		;print("zspan is  "+zspan)
	end if
    zspan=zspan-1				;???### reduce the axis
	;------------
	;creat new array
	;------------
	if(it.eq.start_time)
		dsizes_x = dimsizes(z)
		klev     = dsizes_x(0)
		nlat     = dsizes_x(1)
		mlon     = dsizes_x(2)
		data_1_profile=new((/ntimes,var_numbers,klev/),"float")
		data_2_profile=new((/ntimes,var_numbers,klev/),"float")
		diff_profile=new((/ntimes,var_numbers,klev/),"float")
		diff_percentage_profile=new((/ntimes,var_numbers,klev/),"float")

		;profile average, for output text purpose
		data_1_profile_avg=new((/ntimes,var_numbers/),"float")
		data_2_profile_avg=new((/ntimes,var_numbers/),"float")
		diff_profile_avg=new((/ntimes,var_numbers/),"float")
		diff_percentage_profile_avg=new((/ntimes,var_numbers/),"float")

		;for time average
		data_1_profile_avgtime=new((/var_numbers,klev/),"float")
		data_2_profile_avgtime=new((/var_numbers,klev/),"float")
		diff_profile_avgtime=new((/var_numbers,klev/),"float")
		diff_percentage_profile_avgtime=new((/var_numbers,klev/),"float")

		;for time average, then average  for output text purpose
		data_1_profile_avgtime_avg=new((/var_numbers/),"float")
		data_2_profile_avgtime_avg=new((/var_numbers/),"float")
		diff_profile_avgtime_avg=new((/var_numbers/),"float")
		diff_percentage_profile_avgtime_avg=new((/var_numbers/),"float")

		h_profile=new((/ntimes,klev/),"float")
		;for prediction 
		data_1_th=new((/ntimes,klev,nlat,mlon/),"float")
		data_2_th=new((/ntimes,klev,nlat,mlon/),"float")
		data_1_th_prediction=new((/ntimes,klev,nlat,mlon/),"float")
		data_2_th_prediction=new((/ntimes,klev,nlat,mlon/),"float")
	
		; dry pressure, for calculation convenience
		;dry_p_3d_a=new((/klev,nlat,mlon/),"float")
		;dry_p_3d_b=new((/klev,nlat,mlon/),"float")

		data   = new((/20,ntimes,var_numbers,klev/),float)	; store many profiles
		


	end if  ;end of creating arrays
	

	;do k=0,klev-1				;for wrf version before 3.9.1
	;	dry_p_3d_a(k,:,:)=mub1(:,:)+mu1(:,:)
	;	dry_p_3d_b(k,:,:)=mub2(:,:)+mu2(:,:)
	;end do

	;======================
	; loop over variable
	;=====================

	do  var_id=0,var_numbers-1,1

		print("Working on Variable  "+var_name(var_id))
		checkfile="echo working on time "+time_name(it)+" variable "+var_name(var_id) +">>"+wks_name+".txt"
		system(checkfile)
		;---------------
		; common variables , not wind variables
		;--------------

		if(var_name(var_id) .ne. "wind_speed" .and. var_name(var_id).ne. "total_tendency".and. \
				var_name(var_id).ne."th_prediction".and. var_name(var_id).ne. "total_moist_tendency")then	;these variables are calculated
																											;???### add variable here

			if .not. in_restart_file(var_id) then
		  		data_1 = wrf_user_getvar(a,var_name(var_id),0) 			

		  		if(exist_both_file(var_id) )then
					data_2 = wrf_user_getvar(b,var_name(var_id),0)
				else							
					data_2=0.
				end if
			else
		  		data_1 = wrf_user_getvar(c,var_name(var_id),0) 			

		  		if(exist_both_file(var_id) )then
					data_2 = wrf_user_getvar(d,var_name(var_id),0)
				else							
					data_2=0.
				end if
			end if

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
		; convert couple to uncouple, only for wrf version before 3.9
		;---------------------------
		;if(var_name(var_id).eq."RTHCUTEN".or.var_name(var_id).eq."RTHRATEN".or.var_name(var_id).eq."RTHBLTEN")then
		;	data_1=data_1/dry_p_3d_a		
		;	data_2=data_2/dry_p_3d_b		
		;	data_1=data_1*3600					
		;	data_2=data_2*3600
		;end if

								
		if(var_name(var_id).eq."total_tendency".or.var_name(var_id).eq."th_prediction")then		
			RTHFTEN_c=wrf_user_getvar(c,"RTHFTEN",0)	
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
			RTHFTEN_c=wrf_user_getvar(c,"RTHFTEN",0)
			RTHFTEN_d=wrf_user_getvar(d,"RTHFTEN",0)
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

		if(var_name(var_id).eq."th")then		; store the theta variable, used for prediction
			data_1_th(it,:,:,:)=data_1
			data_2_th(it,:,:,:)=data_2
		end if

		if(var_name(var_id).eq."th_prediction")then	
	
			if(it.eq.start_time)then
					data_1_th_prediction(it,:,:,:)=data_1_th(it,:,:,:)
					data_2_th_prediction(it,:,:,:)=data_2_th(it,:,:,:)
					data_1=data_1_th_prediction(it,:,:,:)
					data_2=data_2_th_prediction(it,:,:,:)
			else
					data_1_th_prediction(it,:,:,:)=data_1_th_prediction(it-1,:,:,:)+data_1_total_tendency
					data_2_th_prediction(it,:,:,:)=data_2_th_prediction(it-1,:,:,:)+data_2_total_tendency
					data_1=data_1_th_prediction(it,:,:,:)
					data_2=data_2_th_prediction(it,:,:,:)
			end if

		end if

		
		if(var_name(var_id) .eq. "wind_speed" )then
				tmp1=wrf_user_getvar(a,"ua",0) 
				tmp2=wrf_user_getvar(a,"va",0)
				data_1 = sqrt(tmp1^2+tmp2^2)
				tmp3=wrf_user_getvar(b,"ua",0)
				tmp4=wrf_user_getvar(b,"va",0) 
				data_2 = sqrt(tmp3^2+tmp4^2)
				data_1@units = "m/s"
		end if



		units(var_id)=data_1@units
	
		;-----------------
		; end of variable caculation
		;----------------

		; difference
   		diff=data_1-data_2	
	
		;===============
		; get the average profile
		;=============
		data_1_profile(it,var_id,:)=dim_avg_n(data_1(:,y_start:y_end,x_start:x_end),(/1,2/))	
		data_2_profile(it,var_id,:)=dim_avg_n(data_2(:,y_start:y_end,x_start:x_end),(/1,2/))		
		diff_profile(it,var_id,:)=dim_avg_n(diff(:,y_start:y_end,x_start:x_end),(/1,2/))
		do k=0,klev-1 ;calculate percentage for the diff
			if(data_2_profile(it,var_id,k).ne.0)then
							diff_percentage_profile(it,var_id,k)=diff_profile(it,var_id,k)/abs(data_2_profile(it,var_id,k))*100
			end if
		end do

		; averae profile, use as text output
		data_1_profile_avg(it,var_id)=dim_avg_n(data_1_profile(it,var_id,:),(/0/))	
		data_2_profile_avg(it,var_id)=dim_avg_n(data_2_profile(it,var_id,:),(/0/))
		diff_profile_avg(it,var_id)=dim_avg_n(diff_profile(it,var_id,:),(/0/))
		diff_percentage_profile_avg(it,var_id)=dim_avg_n(diff_percentage_profile(it,var_id,:),(/0/))
		
		
		if(vertical_type.eq.1)then
			h_profile(it,:)=dim_avg_n(z(:,y_start:y_end,x_start:x_end),(/1,2/))/1000.    ;height convert from m to km
		else	
			h_profile(it,:)=dim_avg_n(p(:,y_start:y_end,x_start:x_end),(/1,2/))			 ;pressure , hPa
		end if

		;store all the profiles into one array for plotting
		data(0,it,var_id,:)=data_1_profile(it,var_id,:)		
		data(1,it,var_id,:)=data_2_profile(it,var_id,:)
		data(2,it,var_id,:)=diff_profile(it,var_id,:)
		data(3,it,var_id,:)=0.0
		data(4,it,var_id,:)=diff_percentage_profile(it,var_id,:)
		data(5,it,var_id,:)=0.0

		;---------------------
		; time average at the end
		;-----------------------------

		if average_time then
			if(it.eq.(time_end))then
				data_1_profile_avgtime(var_id,:)=dim_avg_n(data_1_profile(:,var_id,:),(/0/))
				data_2_profile_avgtime(var_id,:)=dim_avg_n(data_2_profile(:,var_id,:),(/0/))
				diff_profile_avgtime(var_id,:)=dim_avg_n(diff_profile(:,var_id,:),(/0/))
				diff_percentage_profile_avgtime(var_id,:)=dim_avg_n(diff_percentage_profile(:,var_id,:),(/0/))

				; averae profile, use as text output
				data_1_profile_avgtime_avg(var_id)=dim_avg_n(data_1_profile_avgtime(var_id,:),(/0/))
				data_2_profile_avgtime_avg(var_id)=dim_avg_n(data_2_profile_avgtime(var_id,:),(/0/))
				diff_profile_avgtime_avg(var_id)=dim_avg_n(diff_profile_avgtime(var_id,:),(/0/))
				diff_percentage_profile_avgtime_avg(var_id)=dim_avg_n(diff_percentage_profile_avgtime(var_id,:),(/0/))

				;store all the profiles into one array for plotting
				data(6,it,var_id,:)=data_1_profile_avgtime(var_id,:)		
				data(7,it,var_id,:)=data_2_profile_avgtime(var_id,:)
				data(8,it,var_id,:)=diff_profile_avgtime(var_id,:)
				data(9,it,var_id,:)=0.0
				data(10,it,var_id,:)=diff_percentage_profile_avgtime(var_id,:)
				data(11,it,var_id,:)=0.0
			end if
		end if  

		;================
		;resources
		;================

		res                 = True                         ; make plot mods
		res@gsnDraw           = False                   ; don't draw
		res@gsnFrame          = False			 ; don't advance frame
		res@tiMainString    = var_name(var_id) ; title
		res@tmLabelAutoStride=True

		;y axis
		if(vertical_type.eq.1)then
			res@tiYAxisString   = "Height(km)"
			res@trYReverse        = False                      
		else
			res@tiYAxisString   = "Pressure(hPa)" 
			res@trYReverse        = True                  ; reverse Y-axis , when use pressure
		end if
		res@tiYAxisFontHeightF      = 0.03  		;Sets the font height in NDC coordinates to use for the Y-Axis title. 
		res@tmYROn                  = False			;Setting True turns on the right tick marks
		res@tmYLMajorLengthF        = 0.02			;Sets the length of the Y-Axis left major tick marks in NDC coordinates.
		res@tmYLLabelFontHeightF    = 0.025			;Sets the height of the Y-Axis left labels in NDC coordinates.

		;-----------------------------------------------------
		; this doesn't work , why? it seems working in azimuth.ncl
		;------------------------------------------------
		;res@tmYLMode                = "Explicit"   ;need to set @tmYLValues   and @tmYLLabels
 		;nz = floattoint((zmin-zmax)/50+1) 	
        ;res@tmYLValues              = fspan(zstart_index,zspan,zspan-zstart_index+1)    	; Create tick marks, this is the position indice for tickmark.  
		;res@tmYLLabels              = sprintf("%.1f",fspan(zmin,zmax,nz))  ; Create labels  
		;res@tmYLLabels              = sprintf("%.1f",h_profile(it,zstart_index:zspan)) 

		;---------------------------------------
		; this works, but the plot is not nice as the auto
		;-------------------------------------
		;res@tmYLMode                = "Manual"
		;res@tmYLTickStartF	= 0
		;res@tmYLTickSpacingF=1
		;res@tmYLTickEndF=10


		;x axis
		res@tiXAxisString   = var_name(var_id)   	; string is longtitude or latitude
		res@tiXAxisFontHeightF      = 0.025
		res@tmXTOn                  = False			;Setting True turns on top tick marks
		res@tmXBMajorLengthF        = 0.02			;Sets the length of the X-Axis bottom major tick marks in NDC coordinates. 
		res@tmXBLabelFontHeightF    = 0.025			;Sets the font height in NDC coordinates for the bottom X Axis labels. 
		;res@tmXBMode                = "Explicit"	;need to set tmXBValues and tmXBLabels after that

		;markers
		;res@xyMarkLineMode = "MarkLines"    ; Markers *and* lines	;?? set the marker
		;res@xyMarkers      = (/1,4,16/)    ; 3 different markers
		;res@xyMarkerColors = (/"blue","red","purple","black"/)  ; 3 different colors

		res@xyDashPatterns = (/0,1/)               ; Make curves all solid
		res@xyLineThicknesses = (/0.7,0.7/)           
		res@xyLineColors=(/"red","purple"/)  	;(/"blue","red","purple","black"/)  

		 
		;legend
		res@lgAutoManage   = True

	
		;---------------------------------
		; resources for setting the heating  ;???###
		;-------------------------------
		if (var_name(var_id).eq."tc") then		; for heating rate, res_diff is the same as the 'th'
			res@trXMinF = -40.
			res@trXMaxF =55.
			res_diff=res
			res_diff@trXMinF = -0.3	
			res_diff@trXMaxF =0.3
			if(set.gt.1)then		;plot tc individually, not compare with other heating terms
				res_diff@trXMinF = -1.0
				res_diff@trXMaxF =1.0
			end if
		end if

		if (var_name(var_id).eq."td") then
			res@trXMinF = -40.
			res@trXMaxF =55.
			res_diff=res
			res_diff@trXMinF = -1.2
			res_diff@trXMaxF =1.2
		end if


		if (var_name(var_id).eq."th".or.var_name(var_id).eq."th_prediction") then
			res@trXMinF = 300.
			res@trXMaxF =380.
			res_diff=res
			res_diff@trXMinF = -0.3
			res_diff@trXMaxF =0.3
		end if

		if (var_name(var_id).eq."H_DIABATIC".or.var_name(var_id).eq."RTHCUTEN".or.var_name(var_id).eq."RTHRATEN"\
				.or.var_name(var_id).eq."RTHBLTEN".or.var_name(var_id).eq."RTHRATSW".or.var_name(var_id).eq.\
					"RTHRATLW".or.var_name(var_id).eq."total_tendency".or.var_name(var_id).eq."RTHFTEN") then		;???###K/hours
			res@trXMinF = -1.5
			res@trXMaxF =1.5
			res_diff=res
			res_diff@trXMinF = -0.12
			res_diff@trXMaxF =0.12
		end if


		if (var_name(var_id).eq."wa") then		
			res@trXMinF = -1.0
			res@trXMaxF =1.0
			res_diff=res
			res_diff@trXMinF = -1.
			res_diff@trXMaxF =1.
		end if

		if (var_name(var_id).eq."EXTCOF55") then		
			res@trXMinF = 0.0
			res@trXMaxF =0.3
			res_diff=res
			res_diff@trXMinF = -0.3
			res_diff@trXMaxF =0.3
		end if

		if(var_name(var_id).eq."QCLOUD")then
			res@trXMinF = 0.
			res@trXMaxF =4.0e-5
			res_diff=res
			res_diff@trXMinF = -1.8e-5
			res_diff@trXMaxF =1.8e-5
		end if

		if(var_name(var_id).eq."QNDROP")then
			res@trXMinF = 0.
			res@trXMaxF =4.0e7
			res_diff=res
			res_diff@trXMinF = -3e7
			res_diff@trXMaxF =3e7
		end if

		if(var_name(var_id) .eq. "QVAPOR" )then
			res@trXMinF = 0.
			res@trXMaxF =0.03
			res_diff=res
			res_diff@trXMinF = -0.001
			res_diff@trXMaxF =0.001
		end if 

		if (var_name(var_id).eq."rh") then
			res@trXMinF = 0.
			res@trXMaxF =100.
			res_diff=res
			res_diff@trXMinF = -10.0
			res_diff@trXMaxF =10.0
		end if

		if (var_name(var_id).eq."wind_speed") then
			res@trXMinF = 0.
			res@trXMaxF =40.
			res_diff=res
			res_diff@trXMinF = -5.0
			res_diff@trXMaxF =5.0
		end if

		if (var_name(var_id).eq."ua") then
			res@trXMinF = -40.
			res@trXMaxF =40.
			res_diff=res
			res_diff@trXMinF = -5.0
			res_diff@trXMaxF =5.0
		end if

		


		;resources for diff
		res_diff_percentage=res
		res_diff@tiMainString    = var_name(var_id)+"  difference"  
		res_diff@tiXAxisString   = var_name(var_id)+"  difference" 
		res_diff_percentage@tiMainString    = var_name(var_id)+"  percentage change"  
		res_diff_percentage@tiXAxisString   = var_name(var_id)+"  percentage change" 	
		res_diff_percentage@trXMinF = -150		
		res_diff_percentage@trXMaxF =150

		;=============
		;begin plot
		;=============
		plot(var_id) = gsn_xy(wks,data(0:1,it,var_id,zstart_index:zspan),h_profile(it,zstart_index:zspan),res)  	;left column
		plot_diff(var_id)= gsn_xy(wks,data(2:3,it,var_id,zstart_index:zspan),h_profile(it,zstart_index:zspan),res_diff)   ;middle column  
		plot_diff_percentage(var_id)= gsn_xy(wks,data(4:5,it,var_id,zstart_index:zspan),h_profile(it,zstart_index:zspan),res_diff_percentage)     ;right column
		
		
		;-----------
		;plot the time average
		;-------------
		if average_time then
			if(it.eq.time_end)then 
				plot_avgtime(var_id) = gsn_xy(wks,data(6:7,it,var_id,zstart_index:zspan),h_profile(it,zstart_index:zspan),res)  
				plot_diff_avgtime(var_id)= gsn_xy(wks,data(8:9,it,var_id,zstart_index:zspan),h_profile(it,zstart_index:zspan),res_diff)     
				plot_diff_percentage_avgtime(var_id)= gsn_xy(wks,data(10:11,it,var_id,zstart_index:zspan),\
														h_profile(it,zstart_index:zspan),res_diff_percentage)         
			end if
		end if

		;***********************************************
		; legend resources
		;***********************************************
		lgres                    = True
		;lgres@lgLineColors     = (/"blue","red","purple","black"/)
		lgres@lgLineColors     = (/"red","purple"/)
		; lgres@lgLineThicknessF   = res@cnLineThicknessF  ; legend line thickness = contour line thickness
		lgres@lgLineThicknessF = 1.0
		lgres@lgItemType         = "Lines"        			; show lines only (default)
		lgres@lgLabelFontHeightF = .08            			; set the legend label font thickness
		lgres@vpWidthF           = 0.15           			; width of legend (NDC)
		lgres@vpHeightF          = 0.15           			; height of legend (NDC)
		lgres@lgPerimOn         = False
		lgres@lgPerimColor       = "orange"       			; draw the box perimeter in orange
		lgres@lgPerimThicknessF  = 1.0            			; thicken the box perimeter
		lgres@lgDashIndexes      = (/0,1/)              	; dash indexes
		lbid = gsn_create_legend(wks,2,(/" "+var_name(var_id)+" data_1",var_name(var_id)+" data_2"/),lgres)         ; create legend
		lbid_diff = gsn_create_legend(wks,2,(/" "+var_name(var_id)+" difference","0"/),lgres)  
		lbid_diff_percentage = gsn_create_legend(wks,2,(/" "+var_name(var_id)+" percentage change","0"/),lgres)    

		lbid_avgtime = gsn_create_legend(wks,2,(/" "+var_name(var_id)+" data_1",var_name(var_id)+" data_2"/),lgres)         ; create legend
		lbid_diff_avgtime = gsn_create_legend(wks,2,(/" "+var_name(var_id)+" difference","0"/),lgres)  
		lbid_diff_percentage_avgtime = gsn_create_legend(wks,2,(/" "+var_name(var_id)+" percentage change","0"/),lgres)  

		;lbid_avgtime = lbid
		;lbid_diff_avgtime = lbid_diff
		;lbid_diff_percentage_avgtime = lbid_diff_percentage          

		amres = True
		amres@amParallelPosF   = 0.35		      			; move legend to the right
		amres@amOrthogonalPosF = -0.35            			; move the legend vertically, negative is moving up, positive is down
		annoid1 = gsn_add_annotation(plot(var_id),lbid,amres)   ; add legend to plot
		annoid2 = gsn_add_annotation(plot_diff(var_id),lbid_diff,amres)   ; add legend to plot
						;Note when using gsn_add_annotation that gsnDraw and gsnFrame must be set to False. This results 
						;in the need to call draw and frame after the legend is attached to the plot
		annoid3 = gsn_add_annotation(plot_diff_percentage(var_id),lbid_diff_percentage,amres)

		if average_time then
			if(it.eq.time_end)then 
				annoid4 = gsn_add_annotation(plot_avgtime(var_id),lbid_avgtime ,amres)   
				annoid5 = gsn_add_annotation(plot_diff_avgtime(var_id),lbid_diff_avgtime ,amres)   
				annoid6 = gsn_add_annotation(plot_diff_percentage_avgtime(var_id),lbid_diff_percentage_avgtime ,amres)
			end if
		end if

	delete(data_1)
	delete(data_2)
	delete(diff)

	end do
	;-----------------
	;end the variable loop
	;---------------


	;-----------------------------------
	;plotthe terrain or slp and the position of the  plane_a				
	;----------------------------------

	xlat = wrf_user_getvar(a, "XLAT",0)
	xlon = wrf_user_getvar(a, "XLONG",0)

	;-----------------
	; for shading
	;------------------

	opts_sh=True
	opts_sh@cnLinesOn=False 			; turn off contour lines
	opts_sh@cnLineLabelsOn       =  False
	opts_sh@lbLabelBarOn= True   		; only draw it after the panel was created
	opts_sh@cnFillOn=True 
	if .not. nest then
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

	opts_slp = opts_sh
	opts_slp@gsnFrame= False
	opts_slp@gsnDraw = False
	opts_slp@gsnMaximize=False
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

	opts_slp@mpMaxLonF=30			;???### the big domain
	opts_slp@mpMinLonF=-70
	opts_slp@mpMaxLatF=40
	opts_slp@mpMinLatF=0

	opts_slp@cnFillOn = True
	opts_slp@lbTitleOn = False
	opts_slp@tiMainString=time_name(it)
	opts_slp@cnLevelSelectionMode =  "ManualLevels" 
	opts_slp@cnMinLevelValF       = 990.
	opts_slp@cnMaxLevelValF       = 1020.
	opts_slp@cnLevelSpacingF      = 2.5
	opts_slp_diff=opts_slp
	opts_slp_diff@cnMinLevelValF       = -6.0
	opts_slp_diff@cnMaxLevelValF       = 6.0
	opts_slp_diff@cnLevelSpacingF      = 1.
	slp_a@lon2d=xlon
	slp_a@lat2d=xlat
	slp_b@lon2d=xlon
	slp_b@lat2d=xlat
	slp_diff@lon2d=xlon
	slp_diff@lat2d=xlat

	contour_slp_a  = gsn_csm_contour_map(wks,slp_a,opts_slp)
	contour_slp_b  = gsn_csm_contour_map(wks,slp_b,opts_slp)
	contour_slp_diff  = gsn_csm_contour_map(wks,slp_diff,opts_slp_diff)
	plot_slp_1=contour_slp_a
	plot_slp_2=contour_slp_b
	plot_slp_diff=contour_slp_diff

	;------------
	; add the domain line
	;----------------

	lnres = True
	lnres@gsLineThicknessF = 3.0
	lnres@gsLineColor = "Blue"
	lnres@tfPolyDrawOrder = "PostDraw"

	dum1 = gsn_add_polyline(wks, plot_slp_1,(/lon_w(it),lon_e(it)/),(/lat_s(it),lat_s(it)/),lnres)
	dum2=  gsn_add_polyline(wks, plot_slp_1,(/lon_w(it),lon_e(it)/),(/lat_n(it),lat_n(it)/),lnres)
	dum3=  gsn_add_polyline(wks, plot_slp_1,(/lon_w(it),lon_w(it)/),(/lat_s(it),lat_n(it)/),lnres)
	dum4=  gsn_add_polyline(wks, plot_slp_1,(/lon_e(it),lon_e(it)/),(/lat_s(it),lat_n(it)/),lnres)
	dum5 = gsn_add_polyline(wks, plot_slp_2,(/lon_w(it),lon_e(it)/),(/lat_s(it),lat_s(it)/),lnres)
	dum6=  gsn_add_polyline(wks, plot_slp_2,(/lon_w(it),lon_e(it)/),(/lat_n(it),lat_n(it)/),lnres)
	dum7=  gsn_add_polyline(wks, plot_slp_2,(/lon_w(it),lon_w(it)/),(/lat_s(it),lat_n(it)/),lnres)
	dum8=  gsn_add_polyline(wks, plot_slp_2,(/lon_e(it),lon_e(it)/),(/lat_s(it),lat_n(it)/),lnres)
	dum9 = gsn_add_polyline(wks, plot_slp_diff,(/lon_w(it),lon_e(it)/),(/lat_s(it),lat_s(it)/),lnres)
	dum10= gsn_add_polyline(wks, plot_slp_diff,(/lon_w(it),lon_e(it)/),(/lat_n(it),lat_n(it)/),lnres)
	dum11= gsn_add_polyline(wks, plot_slp_diff,(/lon_w(it),lon_w(it)/),(/lat_s(it),lat_n(it)/),lnres)
	dum12= gsn_add_polyline(wks, plot_slp_diff,(/lon_e(it),lon_e(it)/),(/lat_s(it),lat_n(it)/),lnres)

	;------------
	; add extra line
	;---------------
	if add_extra_line then
		
		lnres = True
		lnres@gsLineThicknessF = 3.0
		lnres@gsLineColor = "Black"

		do ip=0,add_extra_line_maxip-1

			lat1_a=lat1_array_a(it,ip)
			lon1_a=lon1_array_a(it,ip)			
			lat2_a=lat2_array_a(it,ip)
			lon2_a=lon2_array_a(it,ip) 

			lat1_b=lat1_array_b(it,ip)
			lon1_b=lon1_array_b(it,ip)			
			lat2_b=lat2_array_b(it,ip)
			lon2_b=lon2_array_b(it,ip) 

			dum13(ip) = gsn_add_polyline(wks, plot_slp_1,(/lon1_a,lon2_a/),(/lat1_a,lat2_a/),lnres)
			dum14(ip) = gsn_add_polyline(wks,plot_slp_2,(/lon1_b,lon2_b/),(/lat1_b,lat2_b/),lnres)

		end do

	end if


	;----------------------
	; begin the panel plot
	;----------------------
												
	resP            = True                        
	;resP@gsnPanelLabelBar    = True  
	resP@gsnMaximize=True 
	;resP@lbOrientation="vertical"

	resP@gsnPanelRowSpec = False    


	;------------
	; (1) heating rate
	;-------------
	if (set.eq.1)then	; some some specific variables, plot several variables at the same page

		resP@gsnPanelMainString = time_name(it) 
		gsn_panel(wks,(/plot(0),plot_diff(0),plot_diff_percentage(0),\
						plot(1),plot_diff(1),plot_diff_percentage(1),\
						plot(2),plot_diff(2),plot_diff_percentage(2),\
						plot(3),plot_diff(3),plot_diff_percentage(3),\
						plot(4),plot_diff(4),plot_diff_percentage(4),\
						plot(5),plot_diff(5),plot_diff_percentage(5),\
						plot(6),plot_diff(6),plot_diff_percentage(6),\
						plot(7),plot_diff(7),plot_diff_percentage(7),\
						plot(8),plot_diff(8),plot_diff_percentage(8),\
						plot(9),plot_diff(9),plot_diff_percentage(9),\
						plot(10),plot_diff(10),plot_diff_percentage(10),\
						plot(11),plot_diff(11),plot_diff_percentage(11),\
						plot(12),plot_diff(12),plot_diff_percentage(12),\
						plot(13),plot_diff(13),plot_diff_percentage(13),\
						plot(14),plot_diff(14),plot_diff_percentage(14),\
						plot(15),plot_diff(15),plot_diff_percentage(15),\
						plot(16),plot_diff(16),plot_diff_percentage(16),\
						plot(17),plot_diff(17),plot_diff_percentage(17),\
						plot(18),plot_diff(18),plot_diff_percentage(18)/),(/19,3/),resP)
		 
		gsn_panel(wks,(/plot_slp_1,plot_slp_2,plot_slp_diff/),(/1,3/),resP)
		
		if average_time then	;plot the average after finish ploting variables at all time
			if(it.eq.end_time)then
				resP@gsnPanelMainString = "average from "+time_name(start_time)+" to "+time_name(time_end) 
				gsn_panel(wks,(/plot_avgtime(0),plot_diff_avgtime(0),plot_diff_percentage_avgtime(0),\
								plot_avgtime(1),plot_diff_avgtime(1),plot_diff_percentage_avgtime(1),\
								plot_avgtime(2),plot_diff_avgtime(2),plot_diff_percentage_avgtime(2),\
								plot_avgtime(3),plot_diff_avgtime(3),plot_diff_percentage_avgtime(3),\
								plot_avgtime(4),plot_diff_avgtime(4),plot_diff_percentage_avgtime(4),\
								plot_avgtime(5),plot_diff_avgtime(5),plot_diff_percentage_avgtime(5),\
								plot_avgtime(6),plot_diff_avgtime(6),plot_diff_percentage_avgtime(6),\
								plot_avgtime(7),plot_diff_avgtime(7),plot_diff_percentage_avgtime(7),\
								plot_avgtime(8),plot_diff_avgtime(8),plot_diff_percentage_avgtime(8),\
								plot_avgtime(9),plot_diff_avgtime(9),plot_diff_percentage_avgtime(9),\
								plot_avgtime(10),plot_diff_avgtime(10),plot_diff_percentage_avgtime(10),\
								plot_avgtime(11),plot_diff_avgtime(11),plot_diff_percentage_avgtime(11),\
								plot_avgtime(12),plot_diff_avgtime(12),plot_diff_percentage_avgtime(12),\
								plot_avgtime(13),plot_diff_avgtime(13),plot_diff_percentage_avgtime(13),\
								plot_avgtime(14),plot_diff_avgtime(14),plot_diff_percentage_avgtime(14),\
								plot_avgtime(15),plot_diff_avgtime(15),plot_diff_percentage_avgtime(15),\
								plot_avgtime(16),plot_diff_avgtime(16),plot_diff_percentage_avgtime(16),\
								plot_avgtime(17),plot_diff_avgtime(17),plot_diff_percentage_avgtime(17),\
								plot_avgtime(18),plot_diff_avgtime(18),plot_diff_percentage_avgtime(18),\
								plot_avgtime(19),plot_diff_avgtime(19),plot_diff_percentage_avgtime(19)/),(/20,3/),resP)
			end if
		end if

	end if

	;---------------------
	;(2) general variables, plot one variabe at one page
	;------------------
	if(set.gt.1)then
		

		resP@gsnPanelMainString = time_name(it) 

		do j=0,var_numbers-1,1
			gsn_panel(wks,(/plot(j),plot_diff(j),plot_diff_percentage(j)/),(/1,3/),resP)
				
		end do

		gsn_panel(wks,(/plot_slp_1,plot_slp_2,plot_slp_diff/),(/1,3/),resP)
		  

		if average_time then		;plot average
			if(it.eq.end_time)then
				resP@gsnPanelMainString = "average from "+time_name(start_time)+" to "+time_name(time_end) 
				do j=0,var_numbers-1,1
					gsn_panel(wks,(/plot_avgtime(j),plot_diff_avgtime(j),plot_diff_percentage_avgtime(j)/),(/1,3/),resP)
		
				end do
			end if
		end if
	
	end if			
	; ---------------end of panel plot


end do
;===========
;end of time loop
;==============	
	


;test the date in excel
;temp1=h_profile(6,zstart_index:zspan)
;temp2=data(0,6,0,zstart_index:zspan)
;temp3=data(2,16,0,zstart_index:zspan)
;dott = " "
;	write_table("test-vertical.txt","w",[/temp1,dott,temp2,dott,temp3/], "%8.3f %s %8.3f %s %8.3f")  

;output average 
system("rm vertical-profile.txt")
do var_id=0,var_numbers-1,1
	write_table("vertical-profile.txt", "a", [/var_name(var_id)/], "%s")
	tem1=time_name(start_time:time_end)
	tem2=data_1_profile_avg(start_time:time_end,var_id)
	tem3=data_2_profile_avg(start_time:time_end,var_id)
	tem4=diff_profile_avg(start_time:time_end,var_id)
	tem5=diff_percentage_profile_avg(start_time:time_end,var_id) 
	dott = " "
	write_table("vertical-profile.txt","a",[/tem1,dott,tem2,dott,tem3,dott,tem4,dott,tem5/], "%s %s  %8.3f %s %8.3f %s %8.3f  %s %8.3f")  

	if average_time then
		write_table("vertical-profile.txt", "a", [/ var_name(var_id)+ (/"  average"/) /], "%s")
		tem6=time_name(time_end:time_end)
		tem7=data_1_profile_avgtime_avg(var_id)
		tem8=data_2_profile_avgtime_avg(var_id)
		tem9=diff_profile_avgtime_avg(var_id)
		tem10=diff_percentage_profile_avgtime_avg(var_id)
		dott = " "
		write_table("vertical-profile.txt","a",[/tem6,dott,tem7,dott,tem8,dott,tem9,dott,tem10/], "%s %s %8.3f %s %8.3f %s %8.3f  %s %8.3f")  
	end if

end do 





end
																			 
