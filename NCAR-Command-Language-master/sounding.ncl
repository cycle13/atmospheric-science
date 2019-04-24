;https://www.ncl.ucar.edu/Applications/skewt.shtml
; http://www2.mmm.ucar.edu/wrf/OnLineTutorial/Graphics/NCL/Examples/SKEW_T/wrf_SkewT.htm
;http://www2.mmm.ucar.edu/wrf/OnLineTutorial/Graphics/NCL/Examples/SKEW_T/wrf_SkewT1.ncl
;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Plot SkewT's at a number of locations
;hahhahhahh
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;;;;
begin

dir_a="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/full/"
dir_b="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2112-3.9.1/seas-sulfate-bc-oc/"

namelist2 = "/mnt/parallel_scratch_mp2_wipe_on_december_2017/chen/liangjia/test/ncl/namelist-sounding"  ;????###
filename     = asciiread(namelist2,-1,"string") 
ntimes   = dimsizes(filename)

print(filename)


;----set time----
start_time=0					;???### 0 is the first time, you can specify 
end_time=999						;???### 999 means at the end of time, you can specify
if (end_time.eq.999)then
	time_end=ntimes-1
else
	time_end=end_time
end if


station=False			;???### plot stations for domain average
plot_both_experiments=False	;???### plot the data2 to the same figure.

number_stations=1
if station then			;???######
	ip_locs = (/ "08522 Funchal", "60018 Guimar-Tenerife","60630 in-salah","60656 DAOF Tindouf",\
				"61024 DRZA Agadez","61052 DRRN Niamey-Aero","64870 FKKN Ngaoundere"/)
	ip_lats = (/  32.6333,28.32,27.2333,27.7,16.5800,13.48,7.4/)
	ip_lons = (/ -16.9,-16.38,2.5,-8.17,7.5900,2.16,13.6/)
	number_stations=dimsizes(ip_locs)	
end if


lat_s=new((/100/),"float")
lat_n=new((/100/),"float")
lon_w=new((/100/),"float")
lon_e=new((/100/),"float")

;land
do i=0,99
	lat_s(i)=12.0           ;????######set the domain
    lat_n(i)=25.0
    lon_w(i)=-10.0
    lon_e(i)=10.0
end do

;ocean
do i=0,99
	;lat_s(i)=10.0		
	;lat_n(i)=20.0
	;lon_w(i)=-30.0
	;lon_e(i)=-18.0	
end do
;lat_s(:8)=(/0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0/)
;lat_n(:8)=(/40.0,40.0,40.0,40.0,40.0,40.0,40.0,40.0,40.0/)
;lon_w(:8)=(/-40.0,-40.0,-40.0,-40.0,-40.0,-40.0,-40.0,-40.0,-40.0/)
;lon_e(:8)=(/5.0,5.0,5.0,5.0,5.0,5.0,5.0,5.0,5.0/)


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

; open work station
tmpname1=str_sub_str(filename(start_time),":","_")
tmpname2=str_sub_str(filename(time_end),":","_")

wks_name="sounding-"+"-"+tmpname1+"-"+tmpname2  


wks=gsn_open_wks("pdf",wks_name) 

rmfile="rm "+wks_name+".txt"
system(rmfile)


;==========
; define color map
;============
;gsn_define_colormap(wks,"WhViBlGrYeOrReWh")              
gsn_define_colormap(wks,"cmp_flux")

;==============
; define the plot array						;???###########
;=======================	
plot_1=new((/ntimes,50/),"graphic") 			;store data1(time,variable)
plot_2=new((/ntimes,50/),"graphic")			;store data2
plot_diff=new((/ntimes,50/),"graphic") 
plot_line=new((/ntimes/),"graphic") 
dum1=new((/ntimes/),"graphic") 
dum2=new((/ntimes/),"graphic") 
dum3=new((/ntimes/),"graphic") 
dum4=new((/ntimes/),"graphic") 
dum5=new((/ntimes/),"graphic") 
dum6=new((/ntimes/),"graphic") 
dum7=new((/ntimes/),"graphic") 
dum8=new((/ntimes/),"graphic") 
dum9=new((/ntimes/),"graphic") 
dum10=new((/ntimes/),"graphic") 
dum11=new((/ntimes/),"graphic") 
dum12=new((/ntimes/),"graphic") 
dum13=new((/ntimes,10/),"graphic") 
dum14=new((/ntimes,10/),"graphic") 
dum15=new((/ntimes,10/),"graphic") 
dum16=new((/ntimes/),"graphic") 
dum17=new((/ntimes/),"graphic") 
plot_slp_1=new((/ntimes/),"graphic")
plot_slp_2=new((/ntimes/),"graphic")
plot_slp_diff=new((/ntimes/),"graphic")
plot_dot1_2d=new((/ntimes,10/),"graphic") 			
plot_dot2_2d=new((/ntimes,10/),"graphic") 
plot_dot_diff_2d=new((/ntimes,10/),"graphic") 

;;===================================
; begin the time loop
;========================================

do it=start_time,time_end,1	

	; filename_a=dir_a+filename(it)+"_prior"+".nc"		;???######### this is for the diff in the da cycle
	;filename_b=dir_b+filename(it)+"_prior"+".nc"
	; filename_a=dir_a+filename(it)+"_post"+".nc"		;???######### this is for the diff in the da cycle
	;  filename_b=dir_b+filename(it)+"_post"+".nc"
	filename_a=dir_a+filename(it)+".nc"			;???#########  this is for the forecast stage
	filename_b=dir_b+filename(it)+".nc"
	a=addfile(filename_a, "r") 
	b=addfile(filename_b, "r") 
	print(filename_a)
	print(filename_b)


    ;-----------
    ;print time information
    ;---------------
	res=True
    times = wrf_user_getvar(a,"times",-1)  
    print("Working on time: " + times(0) )
   
	;===============================
	; set domain
	;=============================
	if .not. station then
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
	end if

	;======================
	; get some dimension information
	;======================
	mdims = getfilevardimsizes(a,"P")
	nd = dimsizes(mdims)
	dimX = mdims(nd-1)
	dimY = mdims(nd-2)


	;;;;;;;;;;;;;;
	;  get the variables    
	;;;;;;;;;;;;;;;;;   

    tc_1  = wrf_user_getvar(a,"tc",0)         ; T in C
    td_1  = wrf_user_getvar(a,"td",0)         ; dew point temperature
    p_1   = wrf_user_getvar(a, "pressure",0)  ; grid point pressure
    z_1   = wrf_user_getvar(a, "z",0)         ; grid point height
    uvm_1 = wrf_user_getvar(a,"uvmet",0)      ; umet and vmet averaged to mass points
					     ; This is a 4D array where
					     ; uvm(0,:,:,:) is umet, and
					     ; uvm(1,:,:,:) is vmet, and
					     ; This function rotate winds to earth coord.
 						 ; extract u and v from uvm array, and turn wind into kts
	u_1   = uvm_1(0,:,:,:)*1.94386 
	v_1   = uvm_1(1,:,:,:)*1.94386
;;
	tc_2  = wrf_user_getvar(b,"tc",0)        
	td_2  = wrf_user_getvar(b,"td",0)         
	p_2   = wrf_user_getvar(b, "pressure",0)  
	z_2   = wrf_user_getvar(b, "z",0)        
	uvm_2 = wrf_user_getvar(b,"uvmet",0)     					     
	u_2   = uvm_2(0,:,:,:)*1.94386 
	v_2   = uvm_2(1,:,:,:)*1.94386


	;----------------
	; Define a few skew-T plotting options		;???#########
	;-----------------------
	skewtOpts          = True
	skewtOpts@DrawHeightScale   = True    ; plot height scale on side
	skewtOpts@DrawHeightScaleFt = False   ; plot height scale in km, if True, the unit is feet
	skewtOpts@DrawStandardAtm   = True    ; draw standard atm on plot
	skewtOpts@vpXF              = 0.3    ; controls off-set from left
	skewtOpts@vpYF              = 0.7    ; controls off-set from top
	skewtOpts@vpWidthF          = 0.5    ; controls size of plot
	skewtOpts@vpHeightF         = 0.5    ; controls size of plot
	skewtOpts@DrawFahrenheit    = False   ; use deg C scale
	skewtOpts@tiMainFontHeightF = 0.015   ; change size of main title	;???####
	skewtOpts@DrawColLine       = True   ; True: draw background lines in color, False: in black	;???#####
	skewtOpts@DrawColAreaFill   = True    ; color on background plot	;???######
	;skewtOpts@DrawColAreaColor  = "Green" ; final color may depend on the color table used
	skewtOpts@DrawColAreaColor  = 53      ; Light Green for WhViBlGrYeOrReWh color table	;???####
	skewtOpts@PrintOpts         = False   ; do not print options out
	;skewtOpts@Panel           = True    ;???#### if plot panel, no wind bar, right now, no panel plot
	;skewtOpts@DrawWind        = False   ; not possible with panel	;???#######  cannot draw even is True, stange??


	;-----------------------------------
	;plotthe terrain or slp and the position of the  plane_a				
	;----------------------------------

	xlat = wrf_user_getvar(a, "XLAT",0)
	xlon = wrf_user_getvar(a, "XLONG",0)

	slp_a = wrf_user_getvar(a, "slp",0)
	slp_b = wrf_user_getvar(b, "slp",0)
	slp_diff=slp_a-slp_b

	;-----------------
	; for shading
	;------------------

	opts_sh=True
	opts_sh@cnLinesOn=False 			; turn off contour lines
	opts_sh@cnLineLabelsOn       =  False
	opts_sh@lbLabelBarOn= True   		; only draw it after the panel was created
	opts_sh@cnFillOn=True 
	opts_sh@cnFillMode="AreaFill"   
	opts_sh@cnMissingValFillPattern = -1 
	opts_sh@cnMissingValFillColor=-1
	opts_sh@gsnSpreadColors =True   ; use the entire color spectrum
	opts_sh@gsnSpreadColorStart =  3 ; 2 is default
	opts_sh@gsnSpreadColorEnd = -3   ; -1 is default

	;opts_sh@cnMinLevelValF       = 0
	;opts_sh@cnMaxLevelValF       = 4
	;opts_sh@cnLevelSpacingF      =  0.25
	;opts_sh@lbLabelBarOn        = True           ; turn off individual cb's
	;opts_sh@lbTitleOn           =True
	;opts_sh@lbOrientation        = "Vertical"   ; vertical label bar

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

	opts_slp@mpMaxLonF=30
	opts_slp@mpMinLonF=-85
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
	plot_slp_1(it)=contour_slp_a
	plot_slp_2(it)=contour_slp_b
	plot_slp_diff(it)=contour_slp_diff




	;=======================
	; plot several station or plot several region
	;;====================

	;=========================
	; (1) plot several locations
	;==========================

	if station then
 
		;-------------------------------
		; begin the location loop			
		;------------------------------------

		do ip = 0, number_stations-1   ; LOOP through station locations and plot a skewT if location is inside model domain

			; Get ij point in model domain for location "ip"
			; loc(1) is south-north (y) and loc(0) is west-east (x)
			loc = wrf_user_ll_to_ij(a, ip_lons(ip), ip_lats(ip), True)
			locX = loc(0)
			locY = loc(1)


			if ( locX .lt. 1 .or. locX .gt. dimX .or. locY .lt. 1 .or. locY .gt. dimY )

			   	print("Attempting to plot: " + "Station - " + ip_locs(ip) )
			   	print("                    " + "at location: "+ ip_lats(ip) +" ; "+ ip_lons(ip) )
			   	print("                    " + "SKIP: Sounding outside model domain" )

			else

				; We need array points in NCL space 
				locX = locX - 1
				locY = locY - 1
				print("Working on statino: " +ip_locs(ip))

				checkfile="echo working on time "+time_name(it)+" staton "+ip_locs(ip)+"  >>"+wks_name+".txt"
				system(checkfile)

		  		;      Get the skew-T background
		  		 skewtOpts@tiMainString = ip_locs(ip)  + " at " + times(0)
				 skewt_bkgd             = skewT_BackGround (wks, skewtOpts)

				;----------------------------
				;     (1) Draw the data_1 skew-T plot	;???####
				;--------------------------
				dataOpts           = True
  				dataOpts@Wthin     = 2        ; plot every n-th wind barb		;???#####
  				dataOpts@xpWind    = 45.      ; new location for winds [default 45]
				dataOpts@Parcel    = 1
				dataOpts@colTemperature  = "black"		;???####
				dataOpts@colDewPt        = dataOpts@colTemperature
				dataOpts@colWindP        = dataOpts@colTemperature
				dataOpts@linePatternDewPt = 1
				dataOpts@WspdWdir  = False  ; wind speed and dir [else: u,v]  ; Set to False, if u and v are input.	;???#####
				dataOpts@HspdHdir  = True   ; wind speed and dir [else: u,v]   ; wind speed and dir [else: u,v]  ;???####, what is this? 
				dataOpts@PlotWindH = False  ; plot wind barbs at h lvls [pibal; special], ;need to have more data, see skewt_7.ncl for example
				plot_1(it,ip) = skewT_PlotData(wks, skewt_bkgd, p_1(:,locY,locX), \
								                         tc_1(:,locY,locX), \
								                         td_1(:,locY,locX), \
								                          z_1(:,locY,locX), \
								                          u_1(:,locY,locX), \
								                          v_1(:,locY,locX), \
								                         dataOpts)
				draw (plot_1(it,ip) )
				;----------------------------
				;     (2) Draw the data_2 skew-T plot	;???####
				;--------------------------
				if plot_both_experiments then

					dataOpts@xpWind    = 40.      ; new location for winds [default 45]	;???####
					dataOpts@colTemperature  = "black"	;???####	"magenta"
					dataOpts@colDewPt        = dataOpts@colTemperature
					dataOpts@colWindP        = dataOpts@colTemperature
					plot_2(it,ip) = skewT_PlotData(wks, skewt_bkgd, p_2(:,locY,locX), \
										                     tc_2(:,locY,locX), \
										                     td_2(:,locY,locX), \
										                      z_2(:,locY,locX), \
										                      u_2(:,locY,locX), \
										                      v_2(:,locY,locX), \
										                     dataOpts)
				
					draw(plot_2(it,ip) )		;draw on the same background
				end if

				frame(wks)
				delete(dataOpts)
				delete(skewt_bkgd)

				;------------------------------
				; add the dots on slp map
				;--------------------------
				dotres = True
				dotres@gsMarkerColor = "Black"
				dotres@gsMarkerIndex = 16
				dotres@gsMarkerSizeF = 0.005

				dum13(it,ip)=gsn_add_polymarker(wks,plot_slp_1(it),ip_lons(ip),ip_lats(ip),dotres)
	 			dum14(it,ip)=gsn_add_polymarker(wks,plot_slp_2(it),ip_lons(ip),ip_lats(ip),dotres)
	 			dum15(it,ip)=gsn_add_polymarker(wks,plot_slp_diff(it),ip_lons(ip),ip_lats(ip),dotres)

				resP            = True                        
				;resP@gsnPanelLabelBar    = True  
				resP@gsnMaximize=True 
				;resP@lbOrientation="vertical"
				resP@gsnFrame         = False
				resP@gsnPanelRowSpec = False    

				gsn_panel(wks,(/plot_slp_1(it),plot_slp_2(it),plot_slp_diff(it)/),(/1,3/),resP)
				frame(wks)

			end if

		end do     
		;=================
		; ; END OF LOCATIONS loop
		;=====================



	;;===============
	;; (2) plot area average
	;====================

	else
		print("Working on time" +time_name(it))

		checkfile="echo working on time "+time_name(it)+"  >>"+wks_name+".txt"
		system(checkfile)

		tc_1_ave=dim_avg_n(tc_1(:,y_start:y_end,x_start:x_end),(/1,2/))
		td_1_ave=dim_avg_n(td_1(:,y_start:y_end,x_start:x_end),(/1,2/))
		p_1_ave=dim_avg_n(p_1(:,y_start:y_end,x_start:x_end),(/1,2/))
		z_1_ave=dim_avg_n(z_1(:,y_start:y_end,x_start:x_end),(/1,2/))
		u_1_ave=dim_avg_n(u_1(:,y_start:y_end,x_start:x_end),(/1,2/))
		v_1_ave=dim_avg_n(v_1(:,y_start:y_end,x_start:x_end),(/1,2/))

		tc_2_ave=dim_avg_n(tc_2(:,y_start:y_end,x_start:x_end),(/1,2/))
		td_2_ave=dim_avg_n(td_2(:,y_start:y_end,x_start:x_end),(/1,2/))
		p_2_ave=dim_avg_n(p_2(:,y_start:y_end,x_start:x_end),(/1,2/))
		z_2_ave=dim_avg_n(z_2(:,y_start:y_end,x_start:x_end),(/1,2/))
		u_2_ave=dim_avg_n(u_2(:,y_start:y_end,x_start:x_end),(/1,2/))
		v_2_ave=dim_avg_n(v_2(:,y_start:y_end,x_start:x_end),(/1,2/))


		;      Get the skew-T background
		skewtOpts@tiMainString = "domain average"  + " at " + times(0)
		skewt_bkgd             = skewT_BackGround (wks, skewtOpts)
		;----------------------------
		;     (1) Draw the data_1 skew-T plot		;???####
		;--------------------------
		dataOpts           = True
		dataOpts@Wthin     = 2        ; plot every n-th wind barb	;???####
		dataOpts@xpWind    = 45.      ; new location for winds [default 45]
		dataOpts@Parcel    = 1
		dataOpts@colTemperature  = "black"		;???####
		dataOpts@colDewPt        = dataOpts@colTemperature
		dataOpts@colWindP        = dataOpts@colTemperature
		dataOpts@linePatternDewPt = 1
		dataOpts@WspdWdir  = False  ; wind speed and dir [else: u,v]  ; Set to False, if u and v are input.	;???#####
		dataOpts@HspdHdir  = True   ; wind speed and dir [else: u,v]   ; wind speed and dir [else: u,v]  ;???####, what is this? 
		dataOpts@PlotWindH = False  ; plot wind barbs at h lvls [pibal; special], ;need to have more data, see skewt_7.ncl for example

		plot_1(it,0)= skewT_PlotData(wks, skewt_bkgd, p_1_ave,tc_1_ave,td_1_ave,z_1_ave,u_1_ave,v_1_ave,dataOpts)
		draw (plot_1(it,0) )

		;----------------------------
		;     (2) Draw the data_2 skew-T plot	;???####
		;--------------------------
		if plot_both_experiments then
			;skewt_bkgd             = skewT_BackGround (wks, skewtOpts)	; if it is panel plot, need to draw the background again
			dataOpts@xpWind    = 40.      ; new location for winds [default 45]	;???####
			dataOpts@colTemperature  = "black"	;???####  "magenta"
			dataOpts@colDewPt        = dataOpts@colTemperature
			dataOpts@colWindP        = dataOpts@colTemperature

			plot_2(it,0) = skewT_PlotData(wks, skewt_bkgd, p_2_ave,tc_2_ave,td_2_ave,z_2_ave,u_2_ave,v_2_ave,dataOpts)
			draw (plot_2(it,0) )

		end if
		frame(wks)
		delete(dataOpts)
		delete(skewt_bkgd)
		
		;------------
		; add the domain line
		;----------------
		resP            = True                        
		;resP@gsnPanelLabelBar    = True  
		resP@gsnMaximize=True 
		;resP@lbOrientation="vertical"
		resP@gsnFrame         = False
		resP@gsnPanelRowSpec = False    

		lnres = True
		lnres@gsLineThicknessF = 3.0
		lnres@gsLineColor = "Blue"
		lnres@tfPolyDrawOrder = "PostDraw"

		dum1(it) = gsn_add_polyline(wks, plot_slp_1(it),(/lon_w(it),lon_e(it)/),(/lat_s(it),lat_s(it)/),lnres)
		dum2(it)=  gsn_add_polyline(wks, plot_slp_1(it),(/lon_w(it),lon_e(it)/),(/lat_n(it),lat_n(it)/),lnres)
		dum3(it)=  gsn_add_polyline(wks, plot_slp_1(it),(/lon_w(it),lon_w(it)/),(/lat_s(it),lat_n(it)/),lnres)
		dum4(it)=  gsn_add_polyline(wks, plot_slp_1(it),(/lon_e(it),lon_e(it)/),(/lat_s(it),lat_n(it)/),lnres)
		dum5(it) = gsn_add_polyline(wks, plot_slp_2(it),(/lon_w(it),lon_e(it)/),(/lat_s(it),lat_s(it)/),lnres)
		dum6(it)=  gsn_add_polyline(wks, plot_slp_2(it),(/lon_w(it),lon_e(it)/),(/lat_n(it),lat_n(it)/),lnres)
		dum7(it)=  gsn_add_polyline(wks, plot_slp_2(it),(/lon_w(it),lon_w(it)/),(/lat_s(it),lat_n(it)/),lnres)
		dum8(it)=  gsn_add_polyline(wks, plot_slp_2(it),(/lon_e(it),lon_e(it)/),(/lat_s(it),lat_n(it)/),lnres)
		dum9(it) = gsn_add_polyline(wks, plot_slp_diff(it),(/lon_w(it),lon_e(it)/),(/lat_s(it),lat_s(it)/),lnres)
		dum10(it)=  gsn_add_polyline(wks, plot_slp_diff(it),(/lon_w(it),lon_e(it)/),(/lat_n(it),lat_n(it)/),lnres)
		dum11(it)=  gsn_add_polyline(wks, plot_slp_diff(it),(/lon_w(it),lon_w(it)/),(/lat_s(it),lat_n(it)/),lnres)
		dum12(it)=  gsn_add_polyline(wks, plot_slp_diff(it),(/lon_e(it),lon_e(it)/),(/lat_s(it),lat_n(it)/),lnres)

		gsn_panel(wks,(/plot_slp_1(it),plot_slp_2(it),plot_slp_diff(it)/),(/1,3/),resP)
		frame(wks)
	end if
	;====================
	; end of the plot for several location or the average area
	;========================


end do        
;========================
; end of time loop
;===============

;===============
;begin the panel plot_1 
;========================  
   
;resP            = True                         ; modify the panel plot_1
;resP@gsnMaximize=True
;resP@gsnFrame         = False                  ; don't advance panel plot_1,by default,after call gsn_panel below,it will automatically 
                                               ;advance the frame, now i manually set it stand still if I want to add something on it.
;resP@gsnPanelRowSpec = False   

;if .not. station then
;	number_stations=1
;end if

;do it=0,ntimes-1,1		
;	do j=0,number_stations-1
;	  gsn_panel(wks,(/plot_1(it,j),plot_2(it,j)/),(/1,2/),resP)
;	frame(wks)
;	end do
;end do
 

end


