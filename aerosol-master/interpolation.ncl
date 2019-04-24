load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
;======================================
; procedure
;(1) Read MACC, 
	;ec_dust1~3,ec_salt1~3, ec_bc, ec_oc, ec_so4 from MACC 
	;vertical and latitude are read in reverse order,convert units to ug/kg
;(2) horizontal interpolation using ESMF_regrid function , 
	;get ec_dust1~3_h_wrf_p_ec ,ec_salt1~3_h_wrf_p_ec ,ec_bc_h_wrf_p_ec, ec_oc_h_wrf_p_ec ,ec_so4_h_wrf_p_ec, 
;(3) vertical interpolation using int2p_n
	;get ec_in_wrf_dust, ec_in_wrf_salt, ec_in_wrf_bc, ec_in_wrf_oc,  ec_in_wrf_so4

ec_file=addfile("/mnt/parallel_scratch_mp2_wipe_on_december_2017/chen/liangjia/test/data/ecmwf/macc-aerosol-20100819-20100915.nc","r")   ;??###
wrfpath="/mnt/parallel_scratch_mp2_wipe_on_april_2017/chen/liangjia/test/2400/"			;??###
wrfinput_file="wrfinput_d01"	
wrfoutput_file="interpolation_output"	;??### output name you want	

begin_time_ec=20;??### is the corresponding MACC to the wrfinput time and the first time in wrfbdy, use check-ecfile-time.ncl to check the time	, =10 is 2112UTC, =20 is 2400UTC
ntime_wrf=28	;??### number of times in wrfbdy, every 6hr, for example: if your forecast time is 12hr, then num_time is 2
IFPLOT=False	;??### if you want to plot to compare the interpolation
OUTPUT=True	;??### output wrfinput for python to read 
wks= gsn_open_wks("pdf","redistribut-from-macc-to-mosaic")
gsn_define_colormap(wks,"BlAqGrYeOrReVi200") 

;==================================
; get the dimension information of the wrfinput_d01 you want to replace
; mlon_wrf,nlat_wrf,klev_wrf
;====================================

a=addfile(wrfpath+wrfinput_file+".nc","r")
tem2=wrf_user_getvar(a,"oin_a01",0)		;??####	
dsizes_x = dimsizes(tem2)
klev_wrf     = dsizes_x(0)
nlat_wrf     = dsizes_x(1)
mlon_wrf     = dsizes_x(2)

pp=wrf_user_getvar(a,"P",0)
pb=wrf_user_getvar(a,"PB",0)
p=pp+pb		;pressure 
p=p/100.	;convert to hPa,match hpa in EC

lat2d = a->XLAT(0,:,:)              
lon2d = a->XLONG(0,:,:)
lon2d = where(lon2d.lt.0,360+lon2d,lon2d)

;==========================================
; EC dimensions 
;==========================================

lat_ec=ec_file->latitude(::-1)
tmp1=dimsizes(lat_ec)
nlat_ec     = tmp1(0)

lon_ec=ec_file->longitude(:)
tmp2=dimsizes(lon_ec)
mlon_ec     = tmp2(0)

time_ec=ec_file->time
tmp3=dimsizes(time_ec)
ntimes_ec=tmp3(0)


;=========================
; pressure in EC
;======================					
pressure_ec_t   = asciiread("pressure-level.txt",(/61,5/),"float") 		;??### copy the file to current script DIR	
pressure_ec=pressure_ec_t(1:,3)		;ncdump -h level , the model level begin from 1, 
;print(pressure_ec)
dsizes = dimsizes(pressure_ec)
klev_ec     = dsizes(0)
pressure_ec(:)=pressure_ec(::-1)  ; reversed the level
;print(pressure_ec)

h_wrf_p_ec=new((/klev_ec,nlat_wrf,mlon_wrf/),"float")
do lev=0,klev_ec-1
      h_wrf_p_ec(lev,:,:)=pressure_ec(lev)
end do

;======================================
; define the new netcdf properties
;=====================================

system("/bin/rm " +wrfpath+wrfoutput_file+".nc")   ; remove any pre-existing file	
outputf=addfile(wrfpath+wrfoutput_file+".nc","c")	
setfileoption(outputf,"DefineMode",True)  ; explicitly declare file definition mode. Improve efficiency.
;========================================
; create global attributes of the file
;========================================
fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Efficient Approach to netCDF Creation"  
fAtt@source_file   =  "MACC and wrfinput"
fAtt@Conventions   = "None"   
fAtt@creation_date = systemfunc ("date")        
fileattdef( outputf, fAtt )            ; copy file attributes   

;===================================================================
; predefine the coordinate variables and their dimensionality
; Note: to get an UNLIMITED record dimension, we set the dimensionality
; to -1 (or the actual size) and set the dimension name to True.
;===================================================================
dimNames = (/"Time", "south_north", "west_east", "bottom_top"/)  
dimSizes = (/ -1   ,  nlat_wrf,  mlon_wrf, klev_wrf  /) 
dimUnlim = (/ True , False, False, False/)   
filedimdef(outputf,dimNames,dimSizes,dimUnlim)

 ;===================================================================
 ; predefine the the dimensionality of the variables to be written out
 ;===================================================================  ; variable name on the file 
filevardef(outputf, "dust1","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "dust2","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "dust3","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "salt1","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "salt2","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "salt3","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "bc1","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "bc2","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "oc1","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "oc2","float",(/"Time","bottom_top","south_north","west_east"/)) 
filevardef(outputf, "so4","float",(/"Time","bottom_top","south_north","west_east"/)) 

ec_dust1=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  
ec_dust2=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  
ec_dust3=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  
ec_salt1=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  
ec_salt2=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  
ec_salt3=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  
ec_bc1=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  
ec_bc2=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  
ec_oc1=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float") 
ec_oc2=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")   
ec_so4=new((/ntime_wrf+1,klev_ec,nlat_ec,mlon_ec/),"float")  

ec_dust1_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")   
ec_dust2_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")   
ec_dust3_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float") 
ec_salt1_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")   
ec_salt2_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")   
ec_salt3_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")  
ec_bc1_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")   
ec_bc2_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")   
ec_oc1_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")   
ec_oc2_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")   
ec_so4_h_wrf_p_ec=new((/ntime_wrf+1,klev_ec,nlat_wrf,mlon_wrf/),"float")  
 
ec_in_wrf_dust1=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")   
ec_in_wrf_dust2=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")   
ec_in_wrf_dust3=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")   
ec_in_wrf_salt1=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")   
ec_in_wrf_salt2=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")   
ec_in_wrf_salt3=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")   
ec_in_wrf_bc1=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")   
ec_in_wrf_bc2=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")   
ec_in_wrf_oc1=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float") 
ec_in_wrf_oc2=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")     
ec_in_wrf_so4=new((/ntime_wrf+1,klev_wrf,nlat_wrf,mlon_wrf/),"float")  


do it=0,ntime_wrf	;go to 2000, number of it is ntime_wrf+1, one more than the times in wrfbdy
	it_ec=begin_time_ec+it
	print("it "+it)

	print("begin to read variables") 	; read EC file, double  precision, get ec_dust1~3,ec_salt1~3,ec_oc,ec_bc,ec_so4
	
	ec_dust1_t1=ec_file->aermr04(it_ec,::-1,::-1,:)			
	ec_dust1_t2=(ec_dust1_t1*ec_dust1_t1@scale_factor+ec_dust1_t1@add_offset)*10^9 
	ec_dust1(it,:,:,:)=doubletofloat(ec_dust1_t2)

	ec_dust2_t1=ec_file->aermr05(it_ec,::-1,::-1,:)
	ec_dust2_t2=(ec_dust2_t1*ec_dust2_t1@scale_factor+ec_dust2_t1@add_offset )*10^9	
	ec_dust2(it,:,:,:)=doubletofloat(ec_dust2_t2)

	ec_dust3_t1=ec_file->aermr06(it_ec,::-1,::-1,:)	
	ec_dust3_t2=(ec_dust3_t1*ec_dust3_t1@scale_factor+ec_dust3_t1@add_offset)*10^9 	
	ec_dust3(it,:,:,:)=doubletofloat(ec_dust3_t2)

	ec_dust1      = where( ec_dust1.lt.0.0, 0.,  ec_dust1 )
	ec_dust2      = where( ec_dust2.lt.0.0, 0.,  ec_dust2 )
	ec_dust3      = where( ec_dust3.lt.0.0, 0.,  ec_dust3 )

	ec_salt1_t1=ec_file->aermr01(it_ec,::-1,::-1,:)			
	ec_salt1_t2=(ec_salt1_t1*ec_salt1_t1@scale_factor+ec_salt1_t1@add_offset )*10^9   ;convert units  kg to ug
	ec_salt1(it,:,:,:)=doubletofloat(ec_salt1_t2)

	ec_salt2_t1=ec_file->aermr02(it_ec,::-1,::-1,:)
	ec_salt2_t2=(ec_salt2_t1*ec_salt2_t1@scale_factor+ec_salt2_t1@add_offset)*10^9  	
	ec_salt2(it,:,:,:)=doubletofloat(ec_salt2_t2)

	ec_salt3_t1=ec_file->aermr03(it_ec,::-1,::-1,:)	
	ec_salt3_t2=(ec_salt3_t1*ec_salt3_t1@scale_factor+ec_salt3_t1@add_offset)*10^9  	
	ec_salt3(it,:,:,:)=doubletofloat(ec_salt3_t2)

	ec_salt1      = where( ec_salt1.lt.0.0,0., ec_salt1 )
	ec_salt2      = where( ec_salt2.lt.0.0, 0., ec_salt2 )
	ec_salt3      = where( ec_salt3.lt.0.0, 0., ec_salt3 )

	ec_bc1_t1=ec_file->aermr09(it_ec,::-1,::-1,:)		;Hydrophobic Black Carbon	
	ec_bc1_t2=(ec_bc1_t1*ec_bc1_t1@scale_factor+ec_bc1_t1@add_offset )*10^9 
	ec_bc1(it,:,:,:)=doubletofloat(ec_bc1_t2)
	ec_bc1      = where( ec_bc1.lt.0.0, 0., ec_bc1 )

	ec_bc2_t1=ec_file->aermr10(it_ec,::-1,::-1,:)	;Hydrophilic Black Carbon 		
	ec_bc2_t2=(ec_bc2_t1*ec_bc2_t1@scale_factor+ec_bc2_t1@add_offset)*10^9  
	ec_bc2(it,:,:,:)=doubletofloat(ec_bc2_t2)
	ec_bc2      = where( ec_bc2.lt.0.0, 0., ec_bc2 )


	ec_oc1_t1=ec_file->aermr07(it_ec,::-1,::-1,:)	;Hydrophobic Organic Matter	
	ec_oc1_t2=(ec_oc1_t1*ec_oc1_t1@scale_factor+ec_oc1_t1@add_offset)*10^9  
	ec_oc1(it,:,:,:)=doubletofloat(ec_oc1_t2)
	ec_oc1      = where( ec_oc1.lt.0.0, 0., ec_oc1 )

	ec_oc2_t1=ec_file->aermr08(it_ec,::-1,::-1,:)	;Hydrophilic Organic Matter	
	ec_oc2_t2=(ec_oc2_t1*ec_oc2_t1@scale_factor+ec_oc2_t1@add_offset)*10^9  
	ec_oc2(it,:,:,:)=doubletofloat(ec_oc2_t2)
	ec_oc2      = where( ec_oc2.lt.0.0, 0., ec_oc2 )


	ec_so4_t1=ec_file->aermr11(it_ec,::-1,::-1,:)	;Sulphate Aerosol 		
	ec_so4_t2=(ec_so4_t1*ec_so4_t1@scale_factor+ec_so4_t1@add_offset )*10^9 
	ec_so4(it,:,:,:)=doubletofloat(ec_so4_t2)
	ec_so4      = where( ec_so4.lt.0.0, 0., ec_so4 )


	;==========================
	; Horizontal  interpolation   to wrf,  but vertical is still in ec , (klev_ec,nlat_wrf,mlon_wrf)
	;ec_dust1~3_h_wrf_p_ec,  ec_salt1~3_h_wrf_p_ec, ec_bc_h_wrf_p_ec, ec_oc_h_wrf_p_ec, ec_so4_h_wrf_p_ec
	;===========================
	print("begin the horizontal interpolation")

	;---For the source
	Opt                = True
	Opt@WgtFileName    = "MACC_to_WRF.nc"  ;The name to use for the NetCDF weights file that is generated under the hood.
	Opt@InterpMethod   = "bilinear"
	Opt@ForceOverwrite = True ;If set to True, then if the corresponding the description NetCDF file already exists, 
			;then it will be overwritten no matter what.
	;opts@ReturnDouble=True ;If set to True, then the return value from this function will be double, regardless of the type of the input data.
	Opt@Check =True
	Opt@SrcFileName  = "MACC.nc"   ; The name to use for the NetCDF file that will contain the needed grid description of the source grid.
				; Do NOT set this to the original file 
	Opt@SrcTitle     = "MACC"   ; An optional title to include in the description NetCDF file as a global attribute called "title".
	Opt@SrcRegional  =False    ;??## if set to True,then the wrf will missing value at 0 longitude ;This means that it connects 
				;the ends of the first dimension to form a sphere and allows extrapolation over the pole.
	Opt@SrcGridType   = "rectilinear"  ; important
	Opt@SrcGridLat      = lat_ec ;These are the arrays that define the source lat/lon grid.
	Opt@SrcGridLon      = lon_ec

	ec_dust1@lon=lon_ec
	ec_dust1@lat=lat_ec 
	ec_dust2@lon=lon_ec
	ec_dust2@lat=lat_ec 
	ec_dust3@lon=lon_ec
	ec_dust3@lat=lat_ec 

	ec_salt1@lon=lon_ec
	ec_salt1@lat=lat_ec 
	ec_salt2@lon=lon_ec
	ec_salt2@lat=lat_ec 
	ec_salt3@lon=lon_ec
	ec_salt3@lat=lat_ec
	 
	ec_bc1@lon=lon_ec
	ec_bc1@lat=lat_ec
	ec_bc2@lon=lon_ec
	ec_bc2@lat=lat_ec

	ec_oc1@lon=lon_ec
	ec_oc1@lat=lat_ec
	ec_oc2@lon=lon_ec
	ec_oc2@lat=lat_ec

	ec_so4@lon=lon_ec
	ec_so4@lat=lat_ec

	;--- for the destination

	Opt@DstFileName     = "WRF.nc"  ;The name to use for the NetCDF file that will contain the needed grid description of the destination grid.  
	Opt@DstTitle        = "WRF"
	Opt@DstRegional     = True
	Opt@DstGridType     = "curvilinear"
	Opt@DstGridLat      = lat2d ;These are the arrays that define the destination lat/lon grid.Since this function has no way to automatically 
				     ;determine what the output grid is, you must set these two attributes or you will get an error.
	Opt@DstGridLon      = lon2d

	;Opt@SrcGridMask    = where(.not.ismissing(ec_dust1(:,:,:)),1,0)  ;A mask array of the same size as the desired lat/lon grid, that indicates
	 							;which areas to mask out. Set the desired masked areas to 0, and all the rest to 1. 
								;This is an important option to set if your data contains missing values.
	; right now,if I set this one, it said 'fatal:Eq: Dimension size, for dimension number 0, of operands does not match, can't continue'

	;You can use the same weights file to regrid across other levels and timesteps of the same variable, or across other variables, as long as the lat/lon grid that you are regridding from and to are exactly the same, and, if you use the special GridMask (or Mask2D prior to NCL V6.3.0) option, that your masks are exactly the same. The masks are arrays filled with 0's and 1's that indicate where your data values and/or lat/lon values are missing. Here's a description
	;right now, masking needs to be done before weight calculation so the regridding knows what it should ignore, so if the mask changes then you need to regenerate weights. 
	if (it.eq.0)then
		ec_dust1_h_wrf_p_ec(it,:,:,:)  = ESMF_regrid(ec_dust1(it,:,:,:),Opt)     ; Do the regridding 

	else
		ec_dust1_h_wrf_p_ec(it,:,:,:) = ESMF_regrid_with_weights(ec_dust1(it,:,:,:),"MACC_to_WRF.nc",False)  
	end if 
	ec_dust1_h_wrf_p_ec  = where( ec_dust1_h_wrf_p_ec .lt.0.0, 0., ec_dust1_h_wrf_p_ec )
	
	; The source and destination grid description files and weight file will be the same for the next call to ESMF_grid, so no need to regenerate them.
	Opt@SkipSrcGrid   = True ;If this is set to True, then it assumes the source description file has already been generated.
	Opt@SkipDstGrid   = True
	Opt@SkipWgtGen    = True
	 
	;The same weights file can only be used if the source and destination lat/lon grids are the same, and if the mask for the new variable is the same as the mask for the "temp" variable.

	ec_dust2_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_dust2(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_dust2_h_wrf_p_ec           = where( ec_dust2_h_wrf_p_ec .lt.0.0, 0., ec_dust2_h_wrf_p_ec )
	ec_dust3_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_dust3(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_dust3_h_wrf_p_ec           = where( ec_dust3_h_wrf_p_ec .lt.0.0, 0.,  ec_dust3_h_wrf_p_ec )
	ec_dust_total_h_wrf_p_ec= ec_dust1_h_wrf_p_ec + ec_dust2_h_wrf_p_ec + ec_dust3_h_wrf_p_ec 

	ec_salt1_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_salt1(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_salt1_h_wrf_p_ec           = where( ec_salt1_h_wrf_p_ec .lt.0.0, 0.,ec_salt1_h_wrf_p_ec )
	ec_salt2_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_salt2(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_salt2_h_wrf_p_ec           = where( ec_salt2_h_wrf_p_ec .lt.0.0, 0., ec_salt2_h_wrf_p_ec )
	ec_salt3_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_salt3(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_salt3_h_wrf_p_ec           = where( ec_salt3_h_wrf_p_ec .lt.0.0, 0., ec_salt3_h_wrf_p_ec )

	ec_salt_total_h_wrf_p_ec= ec_salt1_h_wrf_p_ec + ec_salt2_h_wrf_p_ec + ec_salt3_h_wrf_p_ec 

	ec_bc1_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_bc1(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_bc1_h_wrf_p_ec           = where( ec_bc1_h_wrf_p_ec .lt.0.0, 0.,  ec_bc1_h_wrf_p_ec )
	ec_bc2_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_bc2(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_bc2_h_wrf_p_ec           = where( ec_bc2_h_wrf_p_ec .lt.0.0, 0.,  ec_bc2_h_wrf_p_ec )

	ec_oc1_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_oc1(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_oc1_h_wrf_p_ec           = where( ec_oc1_h_wrf_p_ec .lt.0.0, 0.,ec_oc1_h_wrf_p_ec )
	ec_oc2_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_oc2(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_oc2_h_wrf_p_ec           = where( ec_oc2_h_wrf_p_ec .lt.0.0, 0.,ec_oc2_h_wrf_p_ec )

	ec_so4_h_wrf_p_ec(it,:,:,:)        = ESMF_regrid_with_weights(ec_so4(it,:,:,:),"MACC_to_WRF.nc",False)   
	ec_so4_h_wrf_p_ec           = where( ec_so4_h_wrf_p_ec .lt.0.0, 0.,ec_so4_h_wrf_p_ec )

	;=====================
	;Vertical interpolation to WRF;(klev_wrf,nlat_wrf,mlon_wrf) ec_in_wrf_dust,ec_in_wrf_salt, ec_in_wrf_bc, ec_in_wrf_oc, ec_in_wrf_so4
	;======================
	print("Vertical interpolation")


	print("vertical interpolate dust")
	ec_in_wrf_dust1(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_dust1_h_wrf_p_ec(it,:,:,:),p,-1,0);-1 use extrapolation,othwise, no dust in the lower ground
	ec_in_wrf_dust2(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_dust2_h_wrf_p_ec(it,:,:,:),p,-1,0)
	ec_in_wrf_dust3(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_dust3_h_wrf_p_ec(it,:,:,:),p,-1,0)

	ec_in_wrf_dust1(it,:,:,:)= where( ec_in_wrf_dust1(it,:,:,:) .lt.0.0,0., ec_in_wrf_dust1(it,:,:,:) )
	ec_in_wrf_dust2(it,:,:,:)= where( ec_in_wrf_dust2(it,:,:,:) .lt.0.0, 0., ec_in_wrf_dust2(it,:,:,:) )
	ec_in_wrf_dust3(it,:,:,:)= where( ec_in_wrf_dust3(it,:,:,:) .lt.0.0,0., ec_in_wrf_dust3(it,:,:,:) )

	print("vertical interpolate salt")
	ec_in_wrf_salt1(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_salt1_h_wrf_p_ec(it,:,:,:),p,-1,0)
	ec_in_wrf_salt2(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_salt2_h_wrf_p_ec(it,:,:,:),p,-1,0)
	ec_in_wrf_salt3(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_salt3_h_wrf_p_ec(it,:,:,:),p,-1,0)

	ec_in_wrf_salt1(it,:,:,:)= where( ec_in_wrf_salt1(it,:,:,:) .lt.0.0, 0., ec_in_wrf_salt1(it,:,:,:) )
	ec_in_wrf_salt2(it,:,:,:)= where( ec_in_wrf_salt2(it,:,:,:) .lt.0.0, 0., ec_in_wrf_salt2(it,:,:,:) )
	ec_in_wrf_salt3(it,:,:,:)= where( ec_in_wrf_salt3(it,:,:,:) .lt.0.0, 0., ec_in_wrf_salt3(it,:,:,:) )

	print("vertical interpolate bc")
	ec_in_wrf_bc1(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_bc1_h_wrf_p_ec(it,:,:,:),p,-1,0)	
	ec_in_wrf_bc1(it,:,:,:)= where( ec_in_wrf_bc1(it,:,:,:) .lt.0.0, 0., ec_in_wrf_bc1(it,:,:,:) )
	ec_in_wrf_bc2(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_bc2_h_wrf_p_ec(it,:,:,:),p,-1,0)	
	ec_in_wrf_bc2(it,:,:,:)= where( ec_in_wrf_bc2(it,:,:,:) .lt.0.0, 0., ec_in_wrf_bc2(it,:,:,:) )

	print("vertical interpolate oc")
	ec_in_wrf_oc1(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_oc1_h_wrf_p_ec(it,:,:,:),p,-1,0)	
	ec_in_wrf_oc1(it,:,:,:)= where( ec_in_wrf_oc1(it,:,:,:) .lt.0.0, 0., ec_in_wrf_oc1(it,:,:,:) )
	ec_in_wrf_oc2(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_oc2_h_wrf_p_ec(it,:,:,:),p,-1,0)	
	ec_in_wrf_oc2(it,:,:,:)= where( ec_in_wrf_oc2(it,:,:,:) .lt.0.0, 0., ec_in_wrf_oc2(it,:,:,:) )

	print("vertical interpolate so4")	
	ec_in_wrf_so4(it,:,:,:)= int2p_n(h_wrf_p_ec, ec_so4_h_wrf_p_ec(it,:,:,:),p,-1,0)
	ec_in_wrf_so4(it,:,:,:)= where( ec_in_wrf_so4(it,:,:,:) .lt.0.0, 0., ec_in_wrf_so4(it,:,:,:) )

		
end do 
;2000 end of time loop


;====================
; plot 
;======================
if IFPLOT then	; go to 3000
	plot=new((/ntime_wrf+1,100,25,5/),"graphic")
	; interpolation to pressure levels
	;pressure_levels = (/ 1012.049,1009.056,1004.644,998.385,989.944,979.063,965.567,949.349,930.37,908.651,884.266,857.342,828.047,796.588,\
	;763.205,728.163,691.752,654.273,616.042,577.375,538.591,500,461.9,424.571,388.27,353.226,319.631,287.638,257.356,228.839,\
	;202.086,177.118,153.995,132.758,113.421,95.978,80.397,66.623,54.624,44.335,35.784,28.882,23.311,18.815,15.186,12.257,\
	;9.892,7.984,6.444,5.201,4.193,3.362,2.666,2.077,1.575,1.151,0.796,0.51,0.292,0.1/)   ; this is the full list
	pressure_levels = (/1012.049,1009.056/)					;???###

	nlevels         = dimsizes(pressure_levels) 

	ec_in_wrf_dust1_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_dust2_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_dust3_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_dust_total_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 

	ec_in_wrf_salt1_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_salt2_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_salt3_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_salt_total_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 

	ec_in_wrf_bc1_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_bc2_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_oc1_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_oc2_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 
	ec_in_wrf_so4_plane =new((/ntime_wrf+1,nlevels,nlat_wrf,mlon_wrf/),"float") 

	do it=0,ntime_wrf
		do lev =0,nlevels -1
			opts=True		
			opts@PlotLevelID = pressure_levels(lev) + " hPa"
			print("working on"+pressure_levels(lev) + " hPa")
			pressure = pressure_levels(lev)	
	
			ec_in_wrf_dust1_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_dust1(it,:,:,:)  ,p,"h",pressure,0.,False)
			ec_in_wrf_dust2_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_dust2(it,:,:,:)  ,p,"h",pressure,0.,False)
			ec_in_wrf_dust3_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_dust3(it,:,:,:)  ,p,"h",pressure,0.,False)


			ec_in_wrf_salt1_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_salt1(it,:,:,:) ,p,"h",pressure,0.,False)
			ec_in_wrf_salt2_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_salt2(it,:,:,:) ,p,"h",pressure,0.,False)
			ec_in_wrf_salt3_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_salt3(it,:,:,:) ,p,"h",pressure,0.,False)


			ec_in_wrf_bc1_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_bc1(it,:,:,:)  ,p,"h",pressure,0.,False)
			ec_in_wrf_bc2_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_bc2(it,:,:,:)  ,p,"h",pressure,0.,False)
			ec_in_wrf_oc1_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_oc1(it,:,:,:)  ,p,"h",pressure,0.,False)
			ec_in_wrf_oc2_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_oc2(it,:,:,:)  ,p,"h",pressure,0.,False)
			ec_in_wrf_so4_plane(it,lev,:,:)  = wrf_user_intrp3d( ec_in_wrf_so4(it,:,:,:)  ,p,"h",pressure,0.,False)


			;************************************************
			; Rectilinear plot
			;************************************************
			lat_ec!0      = "lat"
			lat_ec@units  = "degrees_north"

			lon_ec!0      = "lon"
			lon_ec@units  = "degrees_east"

			ec_dust1!1   = "bottom_top"
			ec_dust1!2   = "lat"
			ec_dust1!3   = "lon"
			ec_dust1&lat =  lat_ec
			ec_dust1&lon =  lon_ec

			ec_dust2!1   = "bottom_top"
			ec_dust2!2   = "lat"
			ec_dust2!3   = "lon"
			ec_dust2&lat =  lat_ec
			ec_dust2&lon =  lon_ec

			ec_dust3!1   = "bottom_top"
			ec_dust3!2   = "lat"
			ec_dust3!3   = "lon"
			ec_dust3&lat =  lat_ec
			ec_dust3&lon =  lon_ec

		
			ec_salt1!1   = "bottom_top"
			ec_salt1!2   = "lat"
			ec_salt1!3   = "lon"
			ec_salt1&lat =  lat_ec
			ec_salt1&lon =  lon_ec

			ec_salt2!1   = "bottom_top"
			ec_salt2!2   = "lat"
			ec_salt2!3   = "lon"
			ec_salt2&lat =  lat_ec
			ec_salt2&lon =  lon_ec

			ec_salt3!1   = "bottom_top"
			ec_salt3!2   = "lat"
			ec_salt3!3   = "lon"
			ec_salt3&lat =  lat_ec
			ec_salt3&lon =  lon_ec

			ec_bc1!1   = "bottom_top"
			ec_bc1!2   = "lat"
			ec_bc1!3   = "lon"
			ec_bc1&lat =  lat_ec
			ec_bc1&lon =  lon_ec
			ec_bc2!1   = "bottom_top"
			ec_bc2!2   = "lat"
			ec_bc2!3   = "lon"
			ec_bc2&lat =  lat_ec
			ec_bc2&lon =  lon_ec

			ec_oc1!1   = "bottom_top"
			ec_oc1!2   = "lat"
			ec_oc1!3   = "lon"
			ec_oc1&lat =  lat_ec
			ec_oc1&lon =  lon_ec

			ec_oc2!1   = "bottom_top"
			ec_oc2!2   = "lat"
			ec_oc2!3   = "lon"
			ec_oc2&lat =  lat_ec
			ec_oc2&lon =  lon_ec

			ec_so4!1   = "bottom_top"
			ec_so4!2   = "lat"
			ec_so4!3   = "lon"
			ec_so4&lat =  lat_ec
			ec_so4&lon =  lon_ec

			res                      = True
			res@gsnDraw              = False           ; don't draw
			res@gsnFrame             = False           ; don't advance frame
			res@gsnAddCyclic         = False           ; regional data  
			res@cnInfoLabelOn        = False           ; turn off cn info label
			res@cnFillOn             = True            ; turn on color
			;res@cnFillMode           = "RasterFill"
			res@cnLinesOn            = False
			res@cnLineLabelsOn       = False
			res@lbLabelBarOn         = False           ; turn off individual cb's
			res@cnLinesOn=False
			res@cnLineLabelsOn       =  False
			res@cnFillOn=True
			res@cnFillMode="AreaFill"
			res@cnMissingValFillPattern = -1
			res@cnMissingValFillColor=-1
			res@gsnSpreadColors =True   ; use the entire color spectrum
			res@gsnSpreadColorStart =  3 ; 2 is default
			res@gsnSpreadColorEnd = -3   ; -1 is default
			res@cnLevelSelectionMode =  "ManualLevels"
			res@cnMinLevelValF       = 0
			res@cnMaxLevelValF       = 10.		;??###
			res@cnLevelSpacingF      =  0.5
			res@mpMinLatF            = min(lat2d)      ; range to zoom in on
			res@mpMaxLatF            = max(lat2d)
			res@mpMinLonF            = min(lon2d)
			res@mpMaxLonF            = max(lon2d)
			res@mpCenterLonF=0.
			res@gsnLeftString = ""
			res@gsnRightString= ""

			plot(it,lev,1,1) = gsn_csm_contour_map_ce(wks,ec_dust1(it,lev,:,:) ,res) 
			plot(it,lev,2,1) = gsn_csm_contour_map_ce(wks,ec_dust2(it,lev,:,:) ,res) 
			plot(it,lev,3,1) = gsn_csm_contour_map_ce(wks,ec_dust3(it,lev,:,:) ,res) 
			plot(it,lev,4,1) = gsn_csm_contour_map_ce(wks,ec_salt1(it,lev,:,:) ,res) 
			plot(it,lev,5,1) = gsn_csm_contour_map_ce(wks,ec_salt2(it,lev,:,:) ,res) 
			plot(it,lev,6,1) = gsn_csm_contour_map_ce(wks,ec_salt3(it,lev,:,:) ,res) 
			plot(it,lev,7,1) = gsn_csm_contour_map_ce(wks,ec_bc1(it,lev,:,:) ,res) 
			plot(it,lev,8,1) = gsn_csm_contour_map_ce(wks,ec_bc2(it,lev,:,:) ,res) 
			plot(it,lev,9,1) = gsn_csm_contour_map_ce(wks,ec_oc1(it,lev,:,:) ,res) 
			plot(it,lev,10,1) = gsn_csm_contour_map_ce(wks,ec_oc2(it,lev,:,:) ,res) 
			plot(it,lev,11,1) = gsn_csm_contour_map_ce(wks,ec_so4(it,lev,:,:) ,res) 

			;===========
			;plot wrf
			;===========
			pltres=True
			mpres=True
			pltres@PanelPlot=True									
			pltres@NoTitles=False  
			pltres@NoHeaderFooter=False
			pltres@CommonTitle=True   
			;pltres@PlotTitle=     
			pltres@FramePlot = False 								
			pltres@gsnDraw = False
			mpres@mpGeophysicalLineColor = "Black"
			mpres@mpNationalLineColor    = "Black"
			mpres@mpGridLineColor        = "Black"
			mpres@mpGridLineDashPattern=2
			mpres@mpLimbLineColor        = "Black"
			mpres@mpPerimLineColor       = "Black"
			mpres@mpGeophysicalLineThicknessF = 2.0
			mpres@mpGridLineThicknessF        = 0.4
			mpres@mpLimbLineThicknessF        = 2.0
			mpres@mpNationalLineThicknessF    = 3.0
			mpres@mpUSStateLineThicknessF     = 0.6
			mpres@mpUSStateLineColor="Black"
			mpres@mpDataBaseVersion="MediumRes"
			mpres@mpDataSetName="Earth..4"

			opts_sh=True
			opts_sh@Footer=False 
			opts_sh@NoHeaderFooter=False       
			opts_sh@InitTime= False        
			opts_sh@ValidTime= True
			opts_sh@cnLinesOn=False 
			opts_sh@cnLineLabelsOn       =  False
			opts_sh@cnFillOn=True 
			opts_sh@cnFillMode="AreaFill"   
			opts_sh@cnMissingValFillPattern = -1 
			opts_sh@cnMissingValFillColor=-1
			opts_sh@gsnSpreadColors =True   ; use the entire color spectrum
			opts_sh@gsnSpreadColorStart =  3 ; 2 is default
			opts_sh@gsnSpreadColorEnd = -3   ; -1 is default
			opts_sh@cnLevelSelectionMode =  "ManualLevels"   
			opts_sh@cnMinLevelValF       = 0.
			opts_sh@cnMaxLevelValF       = 10.		;??####
			opts_sh@cnLevelSpacingF      =  0.5

			print("plotting level   "+lev)
			contour_ec  = wrf_contour(a,wks, ec_dust1_h_wrf_p_ec(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,1,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_dust2_h_wrf_p_ec(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,2,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_dust3_h_wrf_p_ec(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,3,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)

			contour_ec  = wrf_contour(a,wks, ec_salt1_h_wrf_p_ec(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,4,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_salt2_h_wrf_p_ec(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,5,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_salt3_h_wrf_p_ec(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,6,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)

			contour_ec  = wrf_contour(a,wks, ec_bc1_h_wrf_p_ec(it,lev,:,:) ,opts_sh) 
			plot(it,lev,7,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_bc2_h_wrf_p_ec(it,lev,:,:) ,opts_sh) 
			plot(it,lev,8,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_oc1_h_wrf_p_ec(it,lev,:,:) ,opts_sh)
			plot(it,lev,9,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_oc2_h_wrf_p_ec(it,lev,:,:) ,opts_sh)
			plot(it,lev,10,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_so4_h_wrf_p_ec(it,lev,:,:) ,opts_sh) 
			plot(it,lev,11,2) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)

			contour_ec  = wrf_contour(a,wks, ec_in_wrf_dust1_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,1,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_in_wrf_dust2_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,2,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_in_wrf_dust3_plane(it,lev,:,:)  ,opts_sh)
			plot(it,lev,3,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)

			contour_ec  = wrf_contour(a,wks, ec_in_wrf_salt1_plane(it,lev,:,:)  ,opts_sh)
			plot(it,lev,4,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_in_wrf_salt2_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,5,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_in_wrf_salt3_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,6,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)

			contour_ec  = wrf_contour(a,wks, ec_in_wrf_bc1_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,7,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_in_wrf_bc2_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,8,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_in_wrf_oc1_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,9,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_in_wrf_oc2_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,10,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
			contour_ec  = wrf_contour(a,wks, ec_in_wrf_so4_plane(it,lev,:,:)  ,opts_sh) 
			plot(it,lev,11,3) = wrf_map_overlays(a,wks,contour_ec,pltres,mpres)
		end do	;end level loop
	end do	;end time loop

	;===========
	; panel  plot
	;=============
	resP            = True                        
	resP@gsnPanelLabelBar    = True  
	resP@gsnMaximize=True 
	;resP@lbOrientation="vertical"
	resP@gsnFrame         = False

	do it=0,ntime_wrf
		do lev=0,nlevels-1
			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  dust1"
			gsn_panel(wks,(/plot(it,lev,1,1),plot(it,lev,1,2),plot(it,lev,1,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  dust2"
			gsn_panel(wks,(/plot(it,lev,2,1),plot(it,lev,2,2),plot(it,lev,2,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  dust3"
			gsn_panel(wks,(/plot(it,lev,3,1),plot(it,lev,3,2),plot(it,lev,3,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  salt1"
			gsn_panel(wks,(/plot(it,lev,4,1),plot(it,lev,4,2),plot(it,lev,4,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  salt2"
			gsn_panel(wks,(/plot(it,lev,5,1),plot(it,lev,5,2),plot(it,lev,5,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  salt3"
			gsn_panel(wks,(/plot(it,lev,6,1),plot(it,lev,6,2),plot(it,lev,6,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  bc1"
			gsn_panel(wks,(/plot(it,lev,7,1),plot(it,lev,7,2),plot(it,lev,7,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  bc2"
			gsn_panel(wks,(/plot(it,lev,8,1),plot(it,lev,8,2),plot(it,lev,8,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  oc1"
			gsn_panel(wks,(/plot(it,lev,9,1),plot(it,lev,9,2),plot(it,lev,9,3)/),(/1,3/),resP)
			frame(wks)


			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  oc2"
			gsn_panel(wks,(/plot(it,lev,10,1),plot(it,lev,10,2),plot(it,lev,10,3)/),(/1,3/),resP)
			frame(wks)

			resP@txString="time ID in wrf  "+it+"  level "+lev+"  pressure:  "+pressure_levels(lev)+"  so4"
			gsn_panel(wks,(/plot(it,lev,11,1),plot(it,lev,11,2),plot(it,lev,11,3)/),(/1,3/),resP)
			frame(wks)

			; plot(level, the species id, different grid(1:ec, 2: after horizontal interpolation, 3: after horizontal and 
			;vertical interpolation, and then interplate back to MACC pressure level)
		end do
	end do


end if
; end of plot  3000


if OUTPUT then
	print("begin  ouput"+systemfunc("date"))
	outputf->dust1=(/ec_in_wrf_dust1/)
	outputf->dust2=(/ec_in_wrf_dust2/)
	outputf->dust3=(/ec_in_wrf_dust3/)
	outputf->salt1=(/ec_in_wrf_salt1/)
	outputf->salt2=(/ec_in_wrf_salt2/)
	outputf->salt3=(/ec_in_wrf_salt3/)
	outputf->bc1=(/ec_in_wrf_bc1/)
	outputf->bc2=(/ec_in_wrf_bc2/)
	outputf->oc1=(/ec_in_wrf_oc1/)
	outputf->oc2=(/ec_in_wrf_oc2/)
	outputf->so4=(/ec_in_wrf_so4/)
	print("end ouput"+systemfunc("date"))
end if

end

