import numpy as ny
from numpy import log, sqrt,exp,pi
from scipy import special
import matplotlib.pyplot as ply
from netCDF4 import Dataset
import os

#===================================================
# Part 1: calculate the conversion factors, end in 2000
#====================================================
printaxis=False     #?? show the axis for bin redistribution

##########
# diameter of dust and sea salt in MACCII
#########
ec_D_dust=ny.array([0.03, 0.55, 0.9, 20.0])
ec_logD_dust=ny.log(ec_D_dust)
ec_D_salt=ny.array([0.03, 0.5, 5.0, 20.0])
ec_logD_salt=ny.log(ec_D_salt)

########
#diameter of mosaic bin sizes
##########
mos_D=ny.array([0.039,0.078,0.156 ,0.312 , 0.625 , 1.25 ,2.5 ,5.0 ,10.0])
mos_logD=ny.log(mos_D)

######## 
#print  the axis
#######
if printaxis :
    ec_axis_dust=ny.linspace(1,1,4)
    mos_axis_dust=ny.linspace(1,1,9)
    ec_axis_salt=ny.linspace(3,3,4)
    mos_axis_salt=ny.linspace(3,3,9)
    ply.scatter(ec_logD_dust,ec_axis_dust,color = 'red', s=100, label='MACC_DUST')
    ply.scatter(mos_logD,mos_axis_dust,color = 'orange',s=120, marker='x',label='MOSAIC')
    ply.scatter(ec_logD_salt,ec_axis_salt,color = 'blue', s=100, label='MACC_salt')
    ply.scatter(mos_logD,mos_axis_salt,color = 'purple',s=120, marker='x',label='MOSAIC')
    ply.ylim(0,10)
    ply.xticks([mos_logD[0],mos_logD[1],mos_logD[2],mos_logD[3],mos_logD[4],mos_logD[5],mos_logD[6],mos_logD[7],mos_logD[8]],[mos_D[0],mos_D[1],mos_D[2],mos_D[3],mos_D[4],mos_D[5],mos_D[6],mos_D[7],mos_D[8]])
    ply.xlabel('diameter(um)')
 #   ply.legend()
    ply.show()

#######
## generate the random dust, salt for test
#######
ec_dust=ny.random.normal(10,2,3)
ec_dust_sum=ny.sum(ec_dust)
print('sum of ec dust is = ' +str(ec_dust_sum))
ec_salt=ny.random.normal(10,3,3)
ec_salt_sum=ny.sum(ec_salt)
print('sum of ec salt is = ' +str(ec_salt_sum))

#####
# mosiac bins array 
#####
mos_dust=ny.empty((8,1))
mos_salt=ny.empty((8,1))
P_Na=23./(23.+35.5)     #percentage of Na
P_Cl=1-P_Na             # percentage of Cl

######
#convert
#########
# bin1
fac0_dust=(mos_logD[1]-ec_logD_dust[0])/(ec_logD_dust[1]-ec_logD_dust[0])
mos_dust[0]=fac0_dust*ec_dust[0]

fac0_salt=(mos_logD[1]-mos_logD[0])/(ec_logD_salt[1]-ec_logD_salt[0])
mos_salt[0]=fac0_salt*ec_salt[0]

# bin2
fac1_dust=(mos_logD[2]-mos_logD[1])/(ec_logD_dust[1]-ec_logD_dust[0])
mos_dust[1]=fac1_dust*ec_dust[0]

fac1_salt=(mos_logD[2]-mos_logD[1])/(ec_logD_salt[1]-ec_logD_salt[0])
mos_salt[1]=fac1_salt*ec_salt[0]

# bin3
fac2_dust=fac1_dust
mos_dust[2]=fac2_dust*ec_dust[0]

fac2_salt=(mos_logD[3]-mos_logD[2])/(ec_logD_salt[1]-ec_logD_salt[0])
mos_salt[2]=fac2_salt*ec_salt[0]

# bin4
fac3_1_dust=(ec_logD_dust[1]-mos_logD[3])/(ec_logD_dust[1]-ec_logD_dust[0])
fac3_2_dust=(mos_logD[4]-ec_logD_dust[1])/(ec_logD_dust[2]-ec_logD_dust[1])
mos_dust[3]=fac3_1_dust*ec_dust[0]+fac3_2_dust*ec_dust[1]

fac3_1_salt=(ec_logD_salt[1]-mos_logD[3])/(ec_logD_salt[1]-ec_logD_salt[0])
fac3_2_salt=(mos_logD[4]-ec_logD_salt[1])/(ec_logD_salt[2]-ec_logD_salt[1])
mos_salt[3]=fac3_1_salt*ec_salt[0]+fac3_2_salt*ec_salt[1]

# bin5
fac4_1_dust=(ec_logD_dust[2]-mos_logD[4])/(ec_logD_dust[2]-ec_logD_dust[1])
fac4_2_dust=(mos_logD[5]-ec_logD_dust[2])/(ec_logD_dust[3]-ec_logD_dust[2])
mos_dust[4]=fac4_1_dust*ec_dust[1]+fac4_2_dust*ec_dust[2]

fac4_salt=(mos_logD[5]-mos_logD[4])/(ec_logD_salt[2]-ec_logD_salt[1])
mos_salt[4]=fac4_salt*ec_salt[1]

# bin6
fac5_dust=(mos_logD[6]-mos_logD[5])/(ec_logD_dust[3]-ec_logD_dust[2])
mos_dust[5]=fac5_dust*ec_dust[2]

fac5_salt=(mos_logD[6]-mos_logD[5])/(ec_logD_salt[2]-ec_logD_salt[1])
mos_salt[5]=fac5_salt*ec_salt[1]

#bin7
fac6_dust=fac5_dust
mos_dust[6]=fac6_dust*ec_dust[2]

fac6_salt=(mos_logD[7]-mos_logD[6])/(ec_logD_salt[2]-ec_logD_salt[1])
mos_salt[6]=fac6_salt*ec_salt[1]

#bin8
fac7_dust=(ec_logD_dust[3]-mos_logD[7])/(ec_logD_dust[3]-ec_logD_dust[2])
mos_dust[7]=fac7_dust*ec_dust[2]

fac7_salt=(mos_logD[8]-mos_logD[7])/(ec_logD_salt[3]-ec_logD_salt[2])
mos_salt[7]=fac7_salt*ec_salt[2]

###############
## check if the mass is conserved
###############
mos_dust_sum=ny.sum(mos_dust)
print('sum of mos dust=  '+ str(mos_dust_sum))
mos_salt_sum=ny.sum(mos_salt)
print('sum of mos salt =  '+ str(mos_salt_sum))

print("percentage of dust bin1 is " + str(fac0_dust) + " of bin1")
print("percentage of dust bin2 is " + str(fac1_dust)+ " of bin1")
print("percentage of dust bin3 is " + str(fac2_dust)+ " of bin1")
print("percentage of dust bin4 is " + str(fac3_1_dust)+ " of bin1  "+str(fac3_2_dust)+ " of bin2")
print("percentage of dust bin5 is " + str(fac4_1_dust)+ " of bin2  "+str(fac4_2_dust)+ " of bin3")
print("percentage of dust bin6 is " + str(fac5_dust)+ " of bin3")
print("percentage of dust bin7 is " + str(fac6_dust)+ " of bin3")
print("percentage of dust bin8 is " + str(fac7_dust)+ " of bin3")


#########
# cumulative function for lognormal distribution
###########
def fcum(log_Dpg,Og,Dp):	#log_Dpg is log of  median diameter , Og is geometric standard deviation, Dp is diameter
    fcum=0.5+0.5*special.erf((log(Dp)-log_Dpg)/sqrt(2.0)/log(Og))	 #log() is natural log
    return fcum         # return fcum, other wise, error!

############
# mosaic diameter in wrfchem
#########
Dd1=ny.array([0.039,0.078,0.156,0.312,0.625,1.25,2.5,5.0])   # min of each size bin, units: um
Dd2=ny.array([0.078,0.156,0.312,0.625,1.25,2.5,5.0,10.0])	# max of each size bin
mos_D=ny.array([0.039,0.078,0.156 ,0.312 , 0.625 , 1.25 ,2.5 ,5.0 ,10.0])
mos_logD=ny.log(mos_D)

#########
#lognormal distribution parameter in MOZART in MACCII
########
Dp_BC=0.0118*2	#number mean diameter of black carbon , um
Og_BC=2.0	#geometric standard deviation, um
Dp_OC=0.0212*2
Og_OC=2.2
Dp_SO4=0.0695*2
Og_SO4=2.03

######## 
#convert the number lognormal distribution in MOZART to mass(volumn) lognormal distribution
##########
Dpg_BC=Dp_BC/exp(log(Og_BC)**2/2)		#Dpg_BC is number median diameter, DP_BC is mean diameter
log_Dpgm_BC=log(Dpg_BC)+3*log(Og_BC)**2	#log_Dpgm_BC is log of mass(volumn) median diameter  
P_BC=ny.empty(8)

Dpg_OC=Dp_OC/exp(log(Og_OC)**2/2)
log_Dpgm_OC=log(Dpg_OC)+3*log(Og_OC)**2
P_OC=ny.empty(8)

Dpg_SO4=Dp_SO4/exp(log(Og_SO4)**2/2)
log_Dpgm_SO4=log(Dpg_SO4)+3*log(Og_SO4)**2
P_SO4=ny.empty(8)

#######
# redistribute MOZART MACCII to  MOSAIC
#######
for i in range(8):
    P_BC[i]=fcum(log_Dpgm_BC,Og_BC,Dd2[i])-fcum(log_Dpgm_BC,Og_BC,Dd1[i])
    P_OC[i]=fcum(log_Dpgm_OC,Og_OC,Dd2[i])-fcum(log_Dpgm_OC,Og_OC,Dd1[i])
    P_SO4[i]=fcum(log_Dpgm_SO4,Og_SO4,Dd2[i])-fcum(log_Dpgm_SO4,Og_SO4,Dd1[i])

#########
## recalculate the percentage, because the sum is less than 1. recalculate to conserve the mass
########
print("sum of the area of all bins for BC is {0:.3f} ".format(ny.sum(P_BC)))
P_BC=P_BC/ny.sum(P_BC)
print("percentage of each bin for BC is " + str(P_BC))

print("sum of the area of all bins for OC is {0:.3f} ".format(ny.sum(P_OC)))
P_OC=P_OC/ny.sum(P_OC)
print("percentage of each bin for OC is " + str(P_OC))

print("sum of the area of all bins for SO4 is {0:.3f} ".format(ny.sum(P_SO4)))
P_SO4=P_SO4/ny.sum(P_SO4)
print("percentage of each bin for SO4 is " + str(P_SO4))
# 2000

#==============================================================================
# Part 2: read the output from NCL, redistribute MACCII to mosaic bins, calculate bdy, output wrfinput and wrfbdy
#=================================================================================
REPLACE_WRFINPUT=True   #???
BDY=True               #???
DUST=True		#???
SEAS=False
BC=True
OC=True
SO4=True
dt=6*3600               #?? 6hrs for bdy interval
bins8=True 		#???
wrfinputf=Dataset("/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/2010/2200/mosaic/coarse/wrfinput_d01","r+",format='NETCDF3_64BIT_OFFSET')  #??
wrfbdyf=Dataset("/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/2010/2200/mosaic/coarse/wrfbdy_d01","r+",format='NETCDF3_64BIT_OFFSET')       #??
nclf=Dataset("/mnt/parallel_scratch_mp2_wipe_on_december_2018/chen/liangjia/test/data/ecmwf/interpolation_out-2010082112.nc","r",format='NETCDF3_64BIT_OFFSET')     #??

# get the dimension name
lat=wrfbdyf.dimensions['south_north']
lon=wrfbdyf.dimensions['west_east']
lev=wrfbdyf.dimensions['bottom_top']
time=wrfbdyf.dimensions['Time']
nlat=len(lat)
mlon=len(lon)
klev=len(lev)
ntime=len(time)
bdywidth=len(wrfbdyf.dimensions['bdy_width'])
if BDY:
    end_time=ntime
else:
    end_time=1
start_time=2			#??? change the start time here if the beginning time in interpolation_output.nc is different from wrfinput
						#? this is the start_time in interpolation_output.nc  according to the time of your wrfinput_d01, 
						#?start_time=0 is if the wrfinput_d01 time is equal to the first time in interpolation_output.nc, start_time=1 is the 2nd time in .nc

for it in range(0,end_time):		
    print("it= "+str(it))
    #======================
    # define variable, mos_dust only have 2 times
    #===================
    mos_dust=ny.empty((8,2,klev,nlat,mlon))
    mos_na=ny.empty((8,2,klev,nlat,mlon))
    mos_cl=ny.empty((8,2,klev,nlat,mlon))
    mos_bc=ny.empty((8,2,klev,nlat,mlon))
    mos_oc=ny.empty((8,2,klev,nlat,mlon))
    mos_so4=ny.empty((8,2,klev,nlat,mlon))

    #============================
    # read variable from the NCL output, read only 2 times from NCL ouput
    #===============================
    if DUST:
        dust1=nclf.variables['dust1'][it+start_time:it+start_time+2,:,:,:]	
											#plus 2 means from it+start_time to it+start_time+1, in python, the last index is not count
        dust2=nclf.variables['dust2'][it+start_time:it+start_time+2,:,:,:]
        dust3=nclf.variables['dust3'][it+start_time:it+start_time+2,:,:,:]

    if SEAS:
        salt1=nclf.variables['salt1'][it+start_time:it+start_time+2,:,:,:]
        salt2=nclf.variables['salt2'][it+start_time:it+start_time+2,:,:,:]
        salt3=nclf.variables['salt3'][it+start_time:it+start_time+2,:,:,:]
    if BC:
        bc1=nclf.variables['bc1'][it+start_time:it+start_time+2,:,:,:]
        bc2=nclf.variables['bc2'][it+start_time:it+start_time+2,:,:,:]
    if OC:
        oc1=nclf.variables['oc1'][it+start_time:it+start_time+2,:,:,:]
        oc2=nclf.variables['oc2'][it+start_time:it+start_time+2,:,:,:]
    if SO4:
        so4=nclf.variables['so4'][it+start_time:it+start_time+2,:,:,:]

    #=======================
    # begin to redistribute
    #==========================
    print("begin to redistribute")
    os.system("date")
    if DUST:
        print("redistribute dust")
        mos_dust[0,:,:,:,:]=fac0_dust*dust1[:,:,:,:]
        mos_dust[1,:,:,:,:]=fac1_dust*dust1[:,:,:,:]
        mos_dust[2,:,:,:,:]=fac2_dust*dust1[:,:,:,:]
        mos_dust[3,:,:,:,:]=fac3_1_dust*dust1[:,:,:,:]+fac3_2_dust*dust2[:,:,:,:]
        mos_dust[4,:,:,:,:]=fac4_1_dust*dust2[:,:,:,:]+fac4_2_dust*dust3[:,:,:,:]
        mos_dust[5,:,:,:,:]=fac5_dust*dust3[:,:,:,:]
        mos_dust[6,:,:,:,:]=fac6_dust*dust3[:,:,:,:]
        mos_dust[7,:,:,:,:]=fac7_dust*dust3[:,:,:,:]

        if not bins8:
               for id in range(4):
                   print("convert dust to 4bins")
                   mos_dust[id,:,:,:,:]= mos_dust[2*id,:,:,:,:]+ mos_dust[2*id+1,:,:,:,:]

    if SEAS:
        print("redistribute sea-salt")
        mos_na[0,:,:,:,:]=P_Na*(fac0_salt*salt1[:,:,:,:])
        mos_na[1,:,:,:,:]=P_Na*(fac1_salt*salt1[:,:,:,:])
        mos_na[2,:,:,:,:]=P_Na*(fac2_salt*salt1[:,:,:,:])
        mos_na[3,:,:,:,:]=P_Na*(fac3_1_salt*salt1[:,:,:,:]+fac3_2_salt*salt2[:,:,:,:])
        mos_na[4,:,:,:,:]=P_Na*(fac4_salt*salt2[:,:,:,:])
        mos_na[5,:,:,:,:]=P_Na*(fac5_salt*salt2[:,:,:,:])
        mos_na[6,:,:,:,:]=P_Na*(fac6_salt*salt2[:,:,:,:])
        mos_na[7,:,:,:,:]=P_Na*(fac7_salt*salt3[:,:,:,:])

        mos_cl[0,:,:,:,:]=P_Cl*(fac0_salt*salt1[:,:,:,:])
        mos_cl[1,:,:,:,:]=P_Cl*(fac1_salt*salt1[:,:,:,:])
        mos_cl[2,:,:,:,:]=P_Cl*(fac2_salt*salt1[:,:,:,:])
        mos_cl[3,:,:,:,:]=P_Cl*(fac3_1_salt*salt1[:,:,:,:]+fac3_2_salt*salt2[:,:,:,:])
        mos_cl[4,:,:,:,:]=P_Cl*(fac4_salt*salt2[:,:,:,:])
        mos_cl[5,:,:,:,:]=P_Cl*(fac5_salt*salt2[:,:,:,:])
        mos_cl[6,:,:,:,:]=P_Cl*(fac6_salt*salt2[:,:,:,:])
        mos_cl[7,:,:,:,:]=P_Cl*(fac7_salt*salt3[:,:,:,:])

        if not bins8:
               for id in range(4):
                   print("convert sea-salt to 4bins")
                   mos_na[id,:,:,:,:]= mos_na[2*id,:,:,:,:]+ mos_na[2*id+1,:,:,:,:]
                   mos_cl[id,:,:,:,:]= mos_cl[2*id,:,:,:,:]+ mos_cl[2*id+1,:,:,:,:]

    if BC:
            print("redistribute BC")
            for id in range(8):
                mos_bc[id,:,:,:,:]=P_BC[id]*(bc1[:,:,:,:]+bc2[:,:,:,:])
        
            if not bins8:
                   for id in range(4):
                        print("convert to 4bins")
                        mos_bc[id,:,:,:,:]= mos_bc[2*id,:,:,:,:]+ mos_bc[2*id+1,:,:,:,:]

    if OC:
            print("redistribute OC")
            for id in range(8):
                mos_oc[id,:,:,:,:]=P_OC[id]*(oc1[:,:,:,:]+oc2[:,:,:,:])
        
            if not bins8:
                for id in range(4):
                    print("convert to 4bins")
                    mos_oc[id,:,:,:,:]= mos_oc[2*id,:,:,:,:]+ mos_oc[2*id+1,:,:,:,:]
                    
    if SO4:
            print("redistribute SO4")
            for id in range(8):
                mos_so4[id,:,:,:,:]=P_SO4[id]*so4[:,:,:,:]
        
            if not bins8:
                   for id in range(4):
                        print("convert to 4bins")
                        mos_so4[id,:,:,:,:]= mos_so4[2*id,:,:,:,:]+ mos_so4[2*id+1,:,:,:,:]
                                                                      
    print("Finish redistribution")
    os.system("date")

    #######
    ## check the distribution randomly, and clean the memory after that
    #######
    print("check the distribution randomly")
    i=int(ny.random.uniform(0,mlon-1))
    j=int(ny.random.uniform(0,nlat-1))
    k=int(ny.random.uniform(0,klev-1))
    t=int(ny.random.uniform(0,1.1))
    if DUST:
        ec_dust_sum=dust1[t,k,j,i]+dust2[t,k,j,i]+dust3[t,k,j,i]
        if  bins8:
            mos_dust_sum=ny.sum(mos_dust[:,t,k,j,i])
        else:
            mos_dust_sum=ny.sum(mos_dust[0:4,t,k,j,i])

        print('sum of ec dust is = ' +str(ec_dust_sum))
        print('sum of mos dust is = ' +str(mos_dust_sum))

        dust1=None  #clean the memory
        dust2=None
        dust3=None

    if SEAS:
        ec_salt_sum=salt1[t,k,j,i]+salt2[t,k,j,i]+salt3[t,k,j,i]
        if  bins8:
            mos_salt_sum=ny.sum(mos_na[:,t,k,j,i])+ny.sum(mos_cl[:,t,k,j,i])
        else:
            mos_salt_sum=ny.sum(mos_na[0:4,t,k,j,i])+ny.sum(mos_cl[0:4,t,k,j,i])

        print('sum of ec salt is = ' +str(ec_salt_sum))
        print('sum of mos salt is = ' +str(mos_salt_sum))
        salt1=None
        salt2=None
        salt3=None

    if BC:
        print('sum of ec BC is = ' +str(bc1[t,k,j,i]+bc2[t,k,j,i]))
        if bins8:
            print('sum of mos BC is = ' +str(ny.sum(mos_bc[:,t,k,j,i])))
        else:
            print('sum of mos BC is = ' +str(ny.sum(mos_bc[0:4,t,k,j,i])))
        bc1=None
        bc2=None

    if OC:
        print('sum of ec OC is = ' +str(oc1[t,k,j,i]+oc2[t,k,j,i]))
        if bins8:
            print('sum of mos OC is = ' +str(ny.sum(mos_oc[:,t,k,j,i])))
        else:
            print('sum of mos OC is = ' +str(ny.sum(mos_oc[0:4,t,k,j,i])))

        oc1=None
        oc2=None

    if SO4:
        print('sum of ec SO4 is = ' +str(so4[t,k,j,i]))
        if bins8:
            print('sum of mos SO4 is = ' +str(ny.sum(mos_so4[:,t,k,j,i])))
        else:
            print('sum of mos SO4 is = ' +str(ny.sum(mos_so4[0:4,t,k,j,i])))

        so4=None
  

   
    #==============================
    #finish redistribution
    #=======================
    print("finish to redistribute")
    os.system("date")    

    #===================
    #replace wrfinput
    #=====================
    if REPLACE_WRFINPUT:
        if it==0:
            print("replace wrfinput")
            os.system("date")
            if DUST:
                print("replace dust in wrfinput")
                wrfinputf.variables['oin_a01'][0,:,:,:]=mos_dust[0,0,:,:,:]
                wrfinputf.variables['oin_a02'][0,:,:,:]=mos_dust[1,0,:,:,:]
                wrfinputf.variables['oin_a03'][0,:,:,:]=mos_dust[2,0,:,:,:]
                wrfinputf.variables['oin_a04'][0,:,:,:]=mos_dust[3,0,:,:,:]
                if bins8:
                    wrfinputf.variables['oin_a05'][0,:,:,:]=mos_dust[4,0,:,:,:]
                    wrfinputf.variables['oin_a06'][0,:,:,:]=mos_dust[5,0,:,:,:]
                    wrfinputf.variables['oin_a07'][0,:,:,:]=mos_dust[6,0,:,:,:]
                    wrfinputf.variables['oin_a08'][0,:,:,:]=mos_dust[7,0,:,:,:]
            if SEAS:
                print("replace Na,Cl in wrfinput")
                wrfinputf.variables['na_a01'][0,:,:,:]=mos_na[0,0,:,:,:]
                wrfinputf.variables['na_a02'][0,:,:,:]=mos_na[1,0,:,:,:]
                wrfinputf.variables['na_a03'][0,:,:,:]=mos_na[2,0,:,:,:]
                wrfinputf.variables['na_a04'][0,:,:,:]=mos_na[3,0,:,:,:]
                if bins8:
                    wrfinputf.variables['na_a05'][0,:,:,:]=mos_na[4,0,:,:,:]
                    wrfinputf.variables['na_a06'][0,:,:,:]=mos_na[5,0,:,:,:]
                    wrfinputf.variables['na_a07'][0,:,:,:]=mos_na[6,0,:,:,:]
                    wrfinputf.variables['na_a08'][0,:,:,:]=mos_na[7,0,:,:,:]

                wrfinputf.variables['cl_a01'][0,:,:,:]=mos_cl[0,0,:,:,:]
                wrfinputf.variables['cl_a02'][0,:,:,:]=mos_cl[1,0,:,:,:]
                wrfinputf.variables['cl_a03'][0,:,:,:]=mos_cl[2,0,:,:,:]
                wrfinputf.variables['cl_a04'][0,:,:,:]=mos_cl[3,0,:,:,:]
                if bins8:
                    wrfinputf.variables['cl_a05'][0,:,:,:]=mos_cl[4,0,:,:,:]
                    wrfinputf.variables['cl_a06'][0,:,:,:]=mos_cl[5,0,:,:,:]
                    wrfinputf.variables['cl_a07'][0,:,:,:]=mos_cl[6,0,:,:,:]
                    wrfinputf.variables['cl_a08'][0,:,:,:]=mos_cl[7,0,:,:,:]
            if BC:
                print("replace BC in wrfinput")
                wrfinputf.variables['bc_a01'][0,:,:,:]=mos_bc[0,0,:,:,:]
                wrfinputf.variables['bc_a02'][0,:,:,:]=mos_bc[1,0,:,:,:]
                wrfinputf.variables['bc_a03'][0,:,:,:]=mos_bc[2,0,:,:,:]
                wrfinputf.variables['bc_a04'][0,:,:,:]=mos_bc[3,0,:,:,:]
                if bins8:
                    wrfinputf.variables['bc_a05'][0,:,:,:]=mos_bc[4,0,:,:,:]
                    wrfinputf.variables['bc_a06'][0,:,:,:]=mos_bc[5,0,:,:,:]
                    wrfinputf.variables['bc_a07'][0,:,:,:]=mos_bc[6,0,:,:,:]
                    wrfinputf.variables['bc_a08'][0,:,:,:]=mos_bc[7,0,:,:,:]
            if OC:
                print("replace OC in wrfinput")
                wrfinputf.variables['oc_a01'][0,:,:,:]=mos_oc[0,0,:,:,:]
                wrfinputf.variables['oc_a02'][0,:,:,:]=mos_oc[1,0,:,:,:]
                wrfinputf.variables['oc_a03'][0,:,:,:]=mos_oc[2,0,:,:,:]
                wrfinputf.variables['oc_a04'][0,:,:,:]=mos_oc[3,0,:,:,:]
                if bins8:
                    wrfinputf.variables['oc_a05'][0,:,:,:]=mos_oc[4,0,:,:,:]
                    wrfinputf.variables['oc_a06'][0,:,:,:]=mos_oc[5,0,:,:,:]
                    wrfinputf.variables['oc_a07'][0,:,:,:]=mos_oc[6,0,:,:,:]
                    wrfinputf.variables['oc_a08'][0,:,:,:]=mos_oc[7,0,:,:,:]
            if SO4:
                print("replace SO4 in wrfinput")
                wrfinputf.variables['so4_a01'][0,:,:,:]=mos_so4[0,0,:,:,:]
                wrfinputf.variables['so4_a02'][0,:,:,:]=mos_so4[1,0,:,:,:]
                wrfinputf.variables['so4_a03'][0,:,:,:]=mos_so4[2,0,:,:,:]
                wrfinputf.variables['so4_a04'][0,:,:,:]=mos_so4[3,0,:,:,:]
                if bins8:
                    wrfinputf.variables['so4_a05'][0,:,:,:]=mos_so4[4,0,:,:,:]
                    wrfinputf.variables['so4_a06'][0,:,:,:]=mos_so4[5,0,:,:,:]
                    wrfinputf.variables['so4_a07'][0,:,:,:]=mos_so4[6,0,:,:,:]
                    wrfinputf.variables['so4_a08'][0,:,:,:]=mos_so4[7,0,:,:,:]

            print("finish replace wrfinput")
            os.system("date")

    if BDY:         #tendency has only one time
        if DUST:
            oin_a01_tend=ny.empty((klev,nlat,mlon))
            oin_a02_tend=ny.empty((klev,nlat,mlon))
            oin_a03_tend=ny.empty((klev,nlat,mlon))
            oin_a04_tend=ny.empty((klev,nlat,mlon))
            if bins8:
                oin_a05_tend=ny.empty((klev,nlat,mlon))
                oin_a06_tend=ny.empty((klev,nlat,mlon))
                oin_a07_tend=ny.empty((klev,nlat,mlon))
                oin_a08_tend=ny.empty((klev,nlat,mlon))

        if SEAS:
            na_a01_tend=ny.empty((klev,nlat,mlon))
            na_a02_tend=ny.empty((klev,nlat,mlon))
            na_a03_tend=ny.empty((klev,nlat,mlon))
            na_a04_tend=ny.empty((klev,nlat,mlon))
            if bins8:
                na_a05_tend=ny.empty((klev,nlat,mlon))
                na_a06_tend=ny.empty((klev,nlat,mlon))
                na_a07_tend=ny.empty((klev,nlat,mlon))
                na_a08_tend=ny.empty((klev,nlat,mlon))
        
            cl_a01_tend=ny.empty((klev,nlat,mlon))
            cl_a02_tend=ny.empty((klev,nlat,mlon))
            cl_a03_tend=ny.empty((klev,nlat,mlon))
            cl_a04_tend=ny.empty((klev,nlat,mlon))
            if bins8:
                cl_a05_tend=ny.empty((klev,nlat,mlon))
                cl_a06_tend=ny.empty((klev,nlat,mlon))
                cl_a07_tend=ny.empty((klev,nlat,mlon))
                cl_a08_tend=ny.empty((klev,nlat,mlon))
        if BC:
            bc_a01_tend=ny.empty((klev,nlat,mlon))
            bc_a02_tend=ny.empty((klev,nlat,mlon))
            bc_a03_tend=ny.empty((klev,nlat,mlon))
            bc_a04_tend=ny.empty((klev,nlat,mlon))
            if bins8:
                bc_a05_tend=ny.empty((klev,nlat,mlon))
                bc_a06_tend=ny.empty((klev,nlat,mlon))
                bc_a07_tend=ny.empty((klev,nlat,mlon))
                bc_a08_tend=ny.empty((klev,nlat,mlon))
        if OC:
            oc_a01_tend=ny.empty((klev,nlat,mlon))
            oc_a02_tend=ny.empty((klev,nlat,mlon))
            oc_a03_tend=ny.empty((klev,nlat,mlon))
            oc_a04_tend=ny.empty((klev,nlat,mlon))
            if bins8:
                oc_a05_tend=ny.empty((klev,nlat,mlon))
                oc_a06_tend=ny.empty((klev,nlat,mlon))
                oc_a07_tend=ny.empty((klev,nlat,mlon))
                oc_a08_tend=ny.empty((klev,nlat,mlon))
        if SO4:
            so4_a01_tend=ny.empty((klev,nlat,mlon))
            so4_a02_tend=ny.empty((klev,nlat,mlon))
            so4_a03_tend=ny.empty((klev,nlat,mlon))
            so4_a04_tend=ny.empty((klev,nlat,mlon))
            if bins8:
                so4_a05_tend=ny.empty((klev,nlat,mlon))
                so4_a06_tend=ny.empty((klev,nlat,mlon))
                so4_a07_tend=ny.empty((klev,nlat,mlon))
                so4_a08_tend=ny.empty((klev,nlat,mlon))

        if DUST:
         #bdy has only one time
            oin_a01_bxs=ny.empty((bdywidth,klev,nlat))
            oin_a01_btxs=ny.empty((bdywidth,klev,nlat))
            oin_a01_bxe=ny.empty((bdywidth,klev,nlat))
            oin_a01_btxe=ny.empty((bdywidth,klev,nlat))
            oin_a01_bys=ny.empty((bdywidth,klev,mlon))
            oin_a01_btys=ny.empty((bdywidth,klev,mlon))
            oin_a01_bye=ny.empty((bdywidth,klev,mlon))
            oin_a01_btye=ny.empty((bdywidth,klev,mlon))
            oin_a02_bxs=ny.empty((bdywidth,klev,nlat))
            oin_a02_btxs=ny.empty((bdywidth,klev,nlat))
            oin_a02_bxe=ny.empty((bdywidth,klev,nlat))
            oin_a02_btxe=ny.empty((bdywidth,klev,nlat))
            oin_a02_bys=ny.empty((bdywidth,klev,mlon))
            oin_a02_btys=ny.empty((bdywidth,klev,mlon))
            oin_a02_bye=ny.empty((bdywidth,klev,mlon))
            oin_a02_btye=ny.empty((bdywidth,klev,mlon))
            oin_a03_bxs=ny.empty((bdywidth,klev,nlat))
            oin_a03_btxs=ny.empty((bdywidth,klev,nlat))
            oin_a03_bxe=ny.empty((bdywidth,klev,nlat))
            oin_a03_btxe=ny.empty((bdywidth,klev,nlat))
            oin_a03_bys=ny.empty((bdywidth,klev,mlon))
            oin_a03_btys=ny.empty((bdywidth,klev,mlon))
            oin_a03_bye=ny.empty((bdywidth,klev,mlon))
            oin_a03_btye=ny.empty((bdywidth,klev,mlon))
            oin_a04_bxs=ny.empty((bdywidth,klev,nlat))
            oin_a04_btxs=ny.empty((bdywidth,klev,nlat))
            oin_a04_bxe=ny.empty((bdywidth,klev,nlat))
            oin_a04_btxe=ny.empty((bdywidth,klev,nlat))
            oin_a04_bys=ny.empty((bdywidth,klev,mlon))
            oin_a04_btys=ny.empty((bdywidth,klev,mlon))
            oin_a04_bye=ny.empty((bdywidth,klev,mlon))
            oin_a04_btye=ny.empty((bdywidth,klev,mlon))
            if bins8:
                oin_a05_bxs=ny.empty((bdywidth,klev,nlat))
                oin_a05_btxs=ny.empty((bdywidth,klev,nlat))
                oin_a05_bxe=ny.empty((bdywidth,klev,nlat))
                oin_a05_btxe=ny.empty((bdywidth,klev,nlat))
                oin_a05_bys=ny.empty((bdywidth,klev,mlon))
                oin_a05_btys=ny.empty((bdywidth,klev,mlon))
                oin_a05_bye=ny.empty((bdywidth,klev,mlon))
                oin_a05_btye=ny.empty((bdywidth,klev,mlon))
                oin_a06_bxs=ny.empty((bdywidth,klev,nlat))
                oin_a06_btxs=ny.empty((bdywidth,klev,nlat))
                oin_a06_bxe=ny.empty((bdywidth,klev,nlat))
                oin_a06_btxe=ny.empty((bdywidth,klev,nlat))
                oin_a06_bys=ny.empty((bdywidth,klev,mlon))
                oin_a06_btys=ny.empty((bdywidth,klev,mlon))
                oin_a06_bye=ny.empty((bdywidth,klev,mlon))
                oin_a06_btye=ny.empty((bdywidth,klev,mlon))
                oin_a07_bxs=ny.empty((bdywidth,klev,nlat))
                oin_a07_btxs=ny.empty((bdywidth,klev,nlat))
                oin_a07_bxe=ny.empty((bdywidth,klev,nlat))
                oin_a07_btxe=ny.empty((bdywidth,klev,nlat))
                oin_a07_bys=ny.empty((bdywidth,klev,mlon))
                oin_a07_btys=ny.empty((bdywidth,klev,mlon))
                oin_a07_bye=ny.empty((bdywidth,klev,mlon))
                oin_a07_btye=ny.empty((bdywidth,klev,mlon))
                oin_a08_bxs=ny.empty((bdywidth,klev,nlat))
                oin_a08_btxs=ny.empty((bdywidth,klev,nlat))
                oin_a08_bxe=ny.empty((bdywidth,klev,nlat))
                oin_a08_btxe=ny.empty((bdywidth,klev,nlat))
                oin_a08_bys=ny.empty((bdywidth,klev,mlon))
                oin_a08_btys=ny.empty((bdywidth,klev,mlon))
                oin_a08_bye=ny.empty((bdywidth,klev,mlon))
                oin_a08_btye=ny.empty((bdywidth,klev,mlon))

        if SEAS:
            na_a01_bxs=ny.empty((bdywidth,klev,nlat))
            na_a01_btxs=ny.empty((bdywidth,klev,nlat))
            na_a01_bxe=ny.empty((bdywidth,klev,nlat))
            na_a01_btxe=ny.empty((bdywidth,klev,nlat))
            na_a01_bys=ny.empty((bdywidth,klev,mlon))
            na_a01_btys=ny.empty((bdywidth,klev,mlon))
            na_a01_bye=ny.empty((bdywidth,klev,mlon))
            na_a01_btye=ny.empty((bdywidth,klev,mlon))
            na_a02_bxs=ny.empty((bdywidth,klev,nlat))
            na_a02_btxs=ny.empty((bdywidth,klev,nlat))
            na_a02_bxe=ny.empty((bdywidth,klev,nlat))
            na_a02_btxe=ny.empty((bdywidth,klev,nlat))
            na_a02_bys=ny.empty((bdywidth,klev,mlon))
            na_a02_btys=ny.empty((bdywidth,klev,mlon))
            na_a02_bye=ny.empty((bdywidth,klev,mlon))
            na_a02_btye=ny.empty((bdywidth,klev,mlon))
            na_a03_bxs=ny.empty((bdywidth,klev,nlat))
            na_a03_btxs=ny.empty((bdywidth,klev,nlat))
            na_a03_bxe=ny.empty((bdywidth,klev,nlat))
            na_a03_btxe=ny.empty((bdywidth,klev,nlat))
            na_a03_bys=ny.empty((bdywidth,klev,mlon))
            na_a03_btys=ny.empty((bdywidth,klev,mlon))
            na_a03_bye=ny.empty((bdywidth,klev,mlon))
            na_a03_btye=ny.empty((bdywidth,klev,mlon))
            na_a04_bxs=ny.empty((bdywidth,klev,nlat))
            na_a04_btxs=ny.empty((bdywidth,klev,nlat))
            na_a04_bxe=ny.empty((bdywidth,klev,nlat))
            na_a04_btxe=ny.empty((bdywidth,klev,nlat))
            na_a04_bys=ny.empty((bdywidth,klev,mlon))
            na_a04_btys=ny.empty((bdywidth,klev,mlon))
            na_a04_bye=ny.empty((bdywidth,klev,mlon))
            na_a04_btye=ny.empty((bdywidth,klev,mlon))
            if bins8:
                na_a05_bxs=ny.empty((bdywidth,klev,nlat))
                na_a05_btxs=ny.empty((bdywidth,klev,nlat))
                na_a05_bxe=ny.empty((bdywidth,klev,nlat))
                na_a05_btxe=ny.empty((bdywidth,klev,nlat))
                na_a05_bys=ny.empty((bdywidth,klev,mlon))
                na_a05_btys=ny.empty((bdywidth,klev,mlon))
                na_a05_bye=ny.empty((bdywidth,klev,mlon))
                na_a05_btye=ny.empty((bdywidth,klev,mlon))
                na_a06_bxs=ny.empty((bdywidth,klev,nlat))
                na_a06_btxs=ny.empty((bdywidth,klev,nlat))
                na_a06_bxe=ny.empty((bdywidth,klev,nlat))
                na_a06_btxe=ny.empty((bdywidth,klev,nlat))
                na_a06_bys=ny.empty((bdywidth,klev,mlon))
                na_a06_btys=ny.empty((bdywidth,klev,mlon))
                na_a06_bye=ny.empty((bdywidth,klev,mlon))
                na_a06_btye=ny.empty((bdywidth,klev,mlon))
                na_a07_bxs=ny.empty((bdywidth,klev,nlat))
                na_a07_btxs=ny.empty((bdywidth,klev,nlat))
                na_a07_bxe=ny.empty((bdywidth,klev,nlat))
                na_a07_btxe=ny.empty((bdywidth,klev,nlat))
                na_a07_bys=ny.empty((bdywidth,klev,mlon))
                na_a07_btys=ny.empty((bdywidth,klev,mlon))
                na_a07_bye=ny.empty((bdywidth,klev,mlon))
                na_a07_btye=ny.empty((bdywidth,klev,mlon))
                na_a08_bxs=ny.empty((bdywidth,klev,nlat))
                na_a08_btxs=ny.empty((bdywidth,klev,nlat))
                na_a08_bxe=ny.empty((bdywidth,klev,nlat))
                na_a08_btxe=ny.empty((bdywidth,klev,nlat))
                na_a08_bys=ny.empty((bdywidth,klev,mlon))
                na_a08_btys=ny.empty((bdywidth,klev,mlon))
                na_a08_bye=ny.empty((bdywidth,klev,mlon))
                na_a08_btye=ny.empty((bdywidth,klev,mlon))

            cl_a01_bxs=ny.empty((bdywidth,klev,nlat))
            cl_a01_btxs=ny.empty((bdywidth,klev,nlat))
            cl_a01_bxe=ny.empty((bdywidth,klev,nlat))
            cl_a01_btxe=ny.empty((bdywidth,klev,nlat))
            cl_a01_bys=ny.empty((bdywidth,klev,mlon))
            cl_a01_btys=ny.empty((bdywidth,klev,mlon))
            cl_a01_bye=ny.empty((bdywidth,klev,mlon))
            cl_a01_btye=ny.empty((bdywidth,klev,mlon))
            cl_a02_bxs=ny.empty((bdywidth,klev,nlat))
            cl_a02_btxs=ny.empty((bdywidth,klev,nlat))
            cl_a02_bxe=ny.empty((bdywidth,klev,nlat))
            cl_a02_btxe=ny.empty((bdywidth,klev,nlat))
            cl_a02_bys=ny.empty((bdywidth,klev,mlon))
            cl_a02_btys=ny.empty((bdywidth,klev,mlon))
            cl_a02_bye=ny.empty((bdywidth,klev,mlon))
            cl_a02_btye=ny.empty((bdywidth,klev,mlon))
            cl_a03_bxs=ny.empty((bdywidth,klev,nlat))
            cl_a03_btxs=ny.empty((bdywidth,klev,nlat))
            cl_a03_bxe=ny.empty((bdywidth,klev,nlat))
            cl_a03_btxe=ny.empty((bdywidth,klev,nlat))
            cl_a03_bys=ny.empty((bdywidth,klev,mlon))
            cl_a03_btys=ny.empty((bdywidth,klev,mlon))
            cl_a03_bye=ny.empty((bdywidth,klev,mlon))
            cl_a03_btye=ny.empty((bdywidth,klev,mlon))
            cl_a04_bxs=ny.empty((bdywidth,klev,nlat))
            cl_a04_btxs=ny.empty((bdywidth,klev,nlat))
            cl_a04_bxe=ny.empty((bdywidth,klev,nlat))
            cl_a04_btxe=ny.empty((bdywidth,klev,nlat))
            cl_a04_bys=ny.empty((bdywidth,klev,mlon))
            cl_a04_btys=ny.empty((bdywidth,klev,mlon))
            cl_a04_bye=ny.empty((bdywidth,klev,mlon))
            cl_a04_btye=ny.empty((bdywidth,klev,mlon))
            if bins8:
                cl_a05_bxs=ny.empty((bdywidth,klev,nlat))
                cl_a05_btxs=ny.empty((bdywidth,klev,nlat))
                cl_a05_bxe=ny.empty((bdywidth,klev,nlat))
                cl_a05_btxe=ny.empty((bdywidth,klev,nlat))
                cl_a05_bys=ny.empty((bdywidth,klev,mlon))
                cl_a05_btys=ny.empty((bdywidth,klev,mlon))
                cl_a05_bye=ny.empty((bdywidth,klev,mlon))
                cl_a05_btye=ny.empty((bdywidth,klev,mlon))
                cl_a06_bxs=ny.empty((bdywidth,klev,nlat))
                cl_a06_btxs=ny.empty((bdywidth,klev,nlat))
                cl_a06_bxe=ny.empty((bdywidth,klev,nlat))
                cl_a06_btxe=ny.empty((bdywidth,klev,nlat))
                cl_a06_bys=ny.empty((bdywidth,klev,mlon))
                cl_a06_btys=ny.empty((bdywidth,klev,mlon))
                cl_a06_bye=ny.empty((bdywidth,klev,mlon))
                cl_a06_btye=ny.empty((bdywidth,klev,mlon))
                cl_a07_bxs=ny.empty((bdywidth,klev,nlat))
                cl_a07_btxs=ny.empty((bdywidth,klev,nlat))
                cl_a07_bxe=ny.empty((bdywidth,klev,nlat))
                cl_a07_btxe=ny.empty((bdywidth,klev,nlat))
                cl_a07_bys=ny.empty((bdywidth,klev,mlon))
                cl_a07_btys=ny.empty((bdywidth,klev,mlon))
                cl_a07_bye=ny.empty((bdywidth,klev,mlon))
                cl_a07_btye=ny.empty((bdywidth,klev,mlon))
                cl_a08_bxs=ny.empty((bdywidth,klev,nlat))
                cl_a08_btxs=ny.empty((bdywidth,klev,nlat))
                cl_a08_bxe=ny.empty((bdywidth,klev,nlat))
                cl_a08_btxe=ny.empty((bdywidth,klev,nlat))
                cl_a08_bys=ny.empty((bdywidth,klev,mlon))
                cl_a08_btys=ny.empty((bdywidth,klev,mlon))
                cl_a08_bye=ny.empty((bdywidth,klev,mlon))
                cl_a08_btye=ny.empty((bdywidth,klev,mlon))
        if BC:
            bc_a01_bxs=ny.empty((bdywidth,klev,nlat))
            bc_a01_btxs=ny.empty((bdywidth,klev,nlat))
            bc_a01_bxe=ny.empty((bdywidth,klev,nlat))
            bc_a01_btxe=ny.empty((bdywidth,klev,nlat))
            bc_a01_bys=ny.empty((bdywidth,klev,mlon))
            bc_a01_btys=ny.empty((bdywidth,klev,mlon))
            bc_a01_bye=ny.empty((bdywidth,klev,mlon))
            bc_a01_btye=ny.empty((bdywidth,klev,mlon))
            bc_a02_bxs=ny.empty((bdywidth,klev,nlat))
            bc_a02_btxs=ny.empty((bdywidth,klev,nlat))
            bc_a02_bxe=ny.empty((bdywidth,klev,nlat))
            bc_a02_btxe=ny.empty((bdywidth,klev,nlat))
            bc_a02_bys=ny.empty((bdywidth,klev,mlon))
            bc_a02_btys=ny.empty((bdywidth,klev,mlon))
            bc_a02_bye=ny.empty((bdywidth,klev,mlon))
            bc_a02_btye=ny.empty((bdywidth,klev,mlon))
            bc_a03_bxs=ny.empty((bdywidth,klev,nlat))
            bc_a03_btxs=ny.empty((bdywidth,klev,nlat))
            bc_a03_bxe=ny.empty((bdywidth,klev,nlat))
            bc_a03_btxe=ny.empty((bdywidth,klev,nlat))
            bc_a03_bys=ny.empty((bdywidth,klev,mlon))
            bc_a03_btys=ny.empty((bdywidth,klev,mlon))
            bc_a03_bye=ny.empty((bdywidth,klev,mlon))
            bc_a03_btye=ny.empty((bdywidth,klev,mlon))
            bc_a04_bxs=ny.empty((bdywidth,klev,nlat))
            bc_a04_btxs=ny.empty((bdywidth,klev,nlat))
            bc_a04_bxe=ny.empty((bdywidth,klev,nlat))
            bc_a04_btxe=ny.empty((bdywidth,klev,nlat))
            bc_a04_bys=ny.empty((bdywidth,klev,mlon))
            bc_a04_btys=ny.empty((bdywidth,klev,mlon))
            bc_a04_bye=ny.empty((bdywidth,klev,mlon))
            bc_a04_btye=ny.empty((bdywidth,klev,mlon))
            if bins8:
                bc_a05_bxs=ny.empty((bdywidth,klev,nlat))
                bc_a05_btxs=ny.empty((bdywidth,klev,nlat))
                bc_a05_bxe=ny.empty((bdywidth,klev,nlat))
                bc_a05_btxe=ny.empty((bdywidth,klev,nlat))
                bc_a05_bys=ny.empty((bdywidth,klev,mlon))
                bc_a05_btys=ny.empty((bdywidth,klev,mlon))
                bc_a05_bye=ny.empty((bdywidth,klev,mlon))
                bc_a05_btye=ny.empty((bdywidth,klev,mlon))
                bc_a06_bxs=ny.empty((bdywidth,klev,nlat))
                bc_a06_btxs=ny.empty((bdywidth,klev,nlat))
                bc_a06_bxe=ny.empty((bdywidth,klev,nlat))
                bc_a06_btxe=ny.empty((bdywidth,klev,nlat))
                bc_a06_bys=ny.empty((bdywidth,klev,mlon))
                bc_a06_btys=ny.empty((bdywidth,klev,mlon))
                bc_a06_bye=ny.empty((bdywidth,klev,mlon))
                bc_a06_btye=ny.empty((bdywidth,klev,mlon))
                bc_a07_bxs=ny.empty((bdywidth,klev,nlat))
                bc_a07_btxs=ny.empty((bdywidth,klev,nlat))
                bc_a07_bxe=ny.empty((bdywidth,klev,nlat))
                bc_a07_btxe=ny.empty((bdywidth,klev,nlat))
                bc_a07_bys=ny.empty((bdywidth,klev,mlon))
                bc_a07_btys=ny.empty((bdywidth,klev,mlon))
                bc_a07_bye=ny.empty((bdywidth,klev,mlon))
                bc_a07_btye=ny.empty((bdywidth,klev,mlon))
                bc_a08_bxs=ny.empty((bdywidth,klev,nlat))
                bc_a08_btxs=ny.empty((bdywidth,klev,nlat))
                bc_a08_bxe=ny.empty((bdywidth,klev,nlat))
                bc_a08_btxe=ny.empty((bdywidth,klev,nlat))
                bc_a08_bys=ny.empty((bdywidth,klev,mlon))
                bc_a08_btys=ny.empty((bdywidth,klev,mlon))
                bc_a08_bye=ny.empty((bdywidth,klev,mlon))
                bc_a08_btye=ny.empty((bdywidth,klev,mlon))
        if OC:
            oc_a01_bxs=ny.empty((bdywidth,klev,nlat))
            oc_a01_btxs=ny.empty((bdywidth,klev,nlat))
            oc_a01_bxe=ny.empty((bdywidth,klev,nlat))
            oc_a01_btxe=ny.empty((bdywidth,klev,nlat))
            oc_a01_bys=ny.empty((bdywidth,klev,mlon))
            oc_a01_btys=ny.empty((bdywidth,klev,mlon))
            oc_a01_bye=ny.empty((bdywidth,klev,mlon))
            oc_a01_btye=ny.empty((bdywidth,klev,mlon))
            oc_a02_bxs=ny.empty((bdywidth,klev,nlat))
            oc_a02_btxs=ny.empty((bdywidth,klev,nlat))
            oc_a02_bxe=ny.empty((bdywidth,klev,nlat))
            oc_a02_btxe=ny.empty((bdywidth,klev,nlat))
            oc_a02_bys=ny.empty((bdywidth,klev,mlon))
            oc_a02_btys=ny.empty((bdywidth,klev,mlon))
            oc_a02_bye=ny.empty((bdywidth,klev,mlon))
            oc_a02_btye=ny.empty((bdywidth,klev,mlon))
            oc_a03_bxs=ny.empty((bdywidth,klev,nlat))
            oc_a03_btxs=ny.empty((bdywidth,klev,nlat))
            oc_a03_bxe=ny.empty((bdywidth,klev,nlat))
            oc_a03_btxe=ny.empty((bdywidth,klev,nlat))
            oc_a03_bys=ny.empty((bdywidth,klev,mlon))
            oc_a03_btys=ny.empty((bdywidth,klev,mlon))
            oc_a03_bye=ny.empty((bdywidth,klev,mlon))
            oc_a03_btye=ny.empty((bdywidth,klev,mlon))
            oc_a04_bxs=ny.empty((bdywidth,klev,nlat))
            oc_a04_btxs=ny.empty((bdywidth,klev,nlat))
            oc_a04_bxe=ny.empty((bdywidth,klev,nlat))
            oc_a04_btxe=ny.empty((bdywidth,klev,nlat))
            oc_a04_bys=ny.empty((bdywidth,klev,mlon))
            oc_a04_btys=ny.empty((bdywidth,klev,mlon))
            oc_a04_bye=ny.empty((bdywidth,klev,mlon))
            oc_a04_btye=ny.empty((bdywidth,klev,mlon))
            if bins8:
                oc_a05_bxs=ny.empty((bdywidth,klev,nlat))
                oc_a05_btxs=ny.empty((bdywidth,klev,nlat))
                oc_a05_bxe=ny.empty((bdywidth,klev,nlat))
                oc_a05_btxe=ny.empty((bdywidth,klev,nlat))
                oc_a05_bys=ny.empty((bdywidth,klev,mlon))
                oc_a05_btys=ny.empty((bdywidth,klev,mlon))
                oc_a05_bye=ny.empty((bdywidth,klev,mlon))
                oc_a05_btye=ny.empty((bdywidth,klev,mlon))
                oc_a06_bxs=ny.empty((bdywidth,klev,nlat))
                oc_a06_btxs=ny.empty((bdywidth,klev,nlat))
                oc_a06_bxe=ny.empty((bdywidth,klev,nlat))
                oc_a06_btxe=ny.empty((bdywidth,klev,nlat))
                oc_a06_bys=ny.empty((bdywidth,klev,mlon))
                oc_a06_btys=ny.empty((bdywidth,klev,mlon))
                oc_a06_bye=ny.empty((bdywidth,klev,mlon))
                oc_a06_btye=ny.empty((bdywidth,klev,mlon))
                oc_a07_bxs=ny.empty((bdywidth,klev,nlat))
                oc_a07_btxs=ny.empty((bdywidth,klev,nlat))
                oc_a07_bxe=ny.empty((bdywidth,klev,nlat))
                oc_a07_btxe=ny.empty((bdywidth,klev,nlat))
                oc_a07_bys=ny.empty((bdywidth,klev,mlon))
                oc_a07_btys=ny.empty((bdywidth,klev,mlon))
                oc_a07_bye=ny.empty((bdywidth,klev,mlon))
                oc_a07_btye=ny.empty((bdywidth,klev,mlon))
                oc_a08_bxs=ny.empty((bdywidth,klev,nlat))
                oc_a08_btxs=ny.empty((bdywidth,klev,nlat))
                oc_a08_bxe=ny.empty((bdywidth,klev,nlat))
                oc_a08_btxe=ny.empty((bdywidth,klev,nlat))
                oc_a08_bys=ny.empty((bdywidth,klev,mlon))
                oc_a08_btys=ny.empty((bdywidth,klev,mlon))
                oc_a08_bye=ny.empty((bdywidth,klev,mlon))
                oc_a08_btye=ny.empty((bdywidth,klev,mlon))
        if SO4:
            so4_a01_bxs=ny.empty((bdywidth,klev,nlat))
            so4_a01_btxs=ny.empty((bdywidth,klev,nlat))
            so4_a01_bxe=ny.empty((bdywidth,klev,nlat))
            so4_a01_btxe=ny.empty((bdywidth,klev,nlat))
            so4_a01_bys=ny.empty((bdywidth,klev,mlon))
            so4_a01_btys=ny.empty((bdywidth,klev,mlon))
            so4_a01_bye=ny.empty((bdywidth,klev,mlon))
            so4_a01_btye=ny.empty((bdywidth,klev,mlon))
            so4_a02_bxs=ny.empty((bdywidth,klev,nlat))
            so4_a02_btxs=ny.empty((bdywidth,klev,nlat))
            so4_a02_bxe=ny.empty((bdywidth,klev,nlat))
            so4_a02_btxe=ny.empty((bdywidth,klev,nlat))
            so4_a02_bys=ny.empty((bdywidth,klev,mlon))
            so4_a02_btys=ny.empty((bdywidth,klev,mlon))
            so4_a02_bye=ny.empty((bdywidth,klev,mlon))
            so4_a02_btye=ny.empty((bdywidth,klev,mlon))
            so4_a03_bxs=ny.empty((bdywidth,klev,nlat))
            so4_a03_btxs=ny.empty((bdywidth,klev,nlat))
            so4_a03_bxe=ny.empty((bdywidth,klev,nlat))
            so4_a03_btxe=ny.empty((bdywidth,klev,nlat))
            so4_a03_bys=ny.empty((bdywidth,klev,mlon))
            so4_a03_btys=ny.empty((bdywidth,klev,mlon))
            so4_a03_bye=ny.empty((bdywidth,klev,mlon))
            so4_a03_btye=ny.empty((bdywidth,klev,mlon))
            so4_a04_bxs=ny.empty((bdywidth,klev,nlat))
            so4_a04_btxs=ny.empty((bdywidth,klev,nlat))
            so4_a04_bxe=ny.empty((bdywidth,klev,nlat))
            so4_a04_btxe=ny.empty((bdywidth,klev,nlat))
            so4_a04_bys=ny.empty((bdywidth,klev,mlon))
            so4_a04_btys=ny.empty((bdywidth,klev,mlon))
            so4_a04_bye=ny.empty((bdywidth,klev,mlon))
            so4_a04_btye=ny.empty((bdywidth,klev,mlon))
            if bins8:
                so4_a05_bxs=ny.empty((bdywidth,klev,nlat))
                so4_a05_btxs=ny.empty((bdywidth,klev,nlat))
                so4_a05_bxe=ny.empty((bdywidth,klev,nlat))
                so4_a05_btxe=ny.empty((bdywidth,klev,nlat))
                so4_a05_bys=ny.empty((bdywidth,klev,mlon))
                so4_a05_btys=ny.empty((bdywidth,klev,mlon))
                so4_a05_bye=ny.empty((bdywidth,klev,mlon))
                so4_a05_btye=ny.empty((bdywidth,klev,mlon))
                so4_a06_bxs=ny.empty((bdywidth,klev,nlat))
                so4_a06_btxs=ny.empty((bdywidth,klev,nlat))
                so4_a06_bxe=ny.empty((bdywidth,klev,nlat))
                so4_a06_btxe=ny.empty((bdywidth,klev,nlat))
                so4_a06_bys=ny.empty((bdywidth,klev,mlon))
                so4_a06_btys=ny.empty((bdywidth,klev,mlon))
                so4_a06_bye=ny.empty((bdywidth,klev,mlon))
                so4_a06_btye=ny.empty((bdywidth,klev,mlon))
                so4_a07_bxs=ny.empty((bdywidth,klev,nlat))
                so4_a07_btxs=ny.empty((bdywidth,klev,nlat))
                so4_a07_bxe=ny.empty((bdywidth,klev,nlat))
                so4_a07_btxe=ny.empty((bdywidth,klev,nlat))
                so4_a07_bys=ny.empty((bdywidth,klev,mlon))
                so4_a07_btys=ny.empty((bdywidth,klev,mlon))
                so4_a07_bye=ny.empty((bdywidth,klev,mlon))
                so4_a07_btye=ny.empty((bdywidth,klev,mlon))
                so4_a08_bxs=ny.empty((bdywidth,klev,nlat))
                so4_a08_btxs=ny.empty((bdywidth,klev,nlat))
                so4_a08_bxe=ny.empty((bdywidth,klev,nlat))
                so4_a08_btxe=ny.empty((bdywidth,klev,nlat))
                so4_a08_bys=ny.empty((bdywidth,klev,mlon))
                so4_a08_btys=ny.empty((bdywidth,klev,mlon))
                so4_a08_bye=ny.empty((bdywidth,klev,mlon))
                so4_a08_btye=ny.empty((bdywidth,klev,mlon))

    #=========================
    # calcuate tendency
    #===========================   
        print("calcuate tendency")
        os.system("date")
        
        if DUST:
            oin_a01_tend=(mos_dust[0,1,:,:,:]-mos_dust[0,0,:,:,:])/dt
            oin_a02_tend=(mos_dust[1,1,:,:,:]-mos_dust[1,0,:,:,:])/dt
            oin_a03_tend=(mos_dust[2,1,:,:,:]-mos_dust[2,0,:,:,:])/dt
            oin_a04_tend=(mos_dust[3,1,:,:,:]-mos_dust[3,0,:,:,:])/dt
            if bins8:
                oin_a05_tend=(mos_dust[4,1,:,:,:]-mos_dust[4,0,:,:,:])/dt
                oin_a06_tend=(mos_dust[5,1,:,:,:]-mos_dust[5,0,:,:,:])/dt
                oin_a07_tend=(mos_dust[6,1,:,:,:]-mos_dust[6,0,:,:,:])/dt
                oin_a08_tend=(mos_dust[7,1,:,:,:]-mos_dust[7,0,:,:,:])/dt

        if SEAS:
            na_a01_tend=(mos_na[0,1,:,:,:]-mos_na[0,0,:,:,:])/dt
            na_a02_tend=(mos_na[1,1,:,:,:]-mos_na[1,0,:,:,:])/dt
            na_a03_tend=(mos_na[2,1,:,:,:]-mos_na[2,0,:,:,:])/dt
            na_a04_tend=(mos_na[3,1,:,:,:]-mos_na[3,0,:,:,:])/dt
            if bins8:
                na_a05_tend=(mos_na[4,1,:,:,:]-mos_na[4,0,:,:,:])/dt
                na_a06_tend=(mos_na[5,1,:,:,:]-mos_na[5,0,:,:,:])/dt
                na_a07_tend=(mos_na[6,1,:,:,:]-mos_na[6,0,:,:,:])/dt
                na_a08_tend=(mos_na[7,1,:,:,:]-mos_na[7,0,:,:,:])/dt

            cl_a01_tend=(mos_cl[0,1,:,:,:]-mos_cl[0,0,:,:,:])/dt
            cl_a02_tend=(mos_cl[1,1,:,:,:]-mos_cl[1,0,:,:,:])/dt
            cl_a03_tend=(mos_cl[2,1,:,:,:]-mos_cl[2,0,:,:,:])/dt
            cl_a04_tend=(mos_cl[3,1,:,:,:]-mos_cl[3,0,:,:,:])/dt
            if bins8:
                cl_a05_tend=(mos_cl[4,1,:,:,:]-mos_cl[4,0,:,:,:])/dt
                cl_a06_tend=(mos_cl[5,1,:,:,:]-mos_cl[5,0,:,:,:])/dt
                cl_a07_tend=(mos_cl[6,1,:,:,:]-mos_cl[6,0,:,:,:])/dt
                cl_a08_tend=(mos_cl[7,1,:,:,:]-mos_cl[7,0,:,:,:])/dt
        if BC:
            bc_a01_tend=(mos_bc[0,1,:,:,:]-mos_bc[0,0,:,:,:])/dt
            bc_a02_tend=(mos_bc[1,1,:,:,:]-mos_bc[1,0,:,:,:])/dt
            bc_a03_tend=(mos_bc[2,1,:,:,:]-mos_bc[2,0,:,:,:])/dt
            bc_a04_tend=(mos_bc[3,1,:,:,:]-mos_bc[3,0,:,:,:])/dt
            if bins8:
                bc_a05_tend=(mos_bc[4,1,:,:,:]-mos_bc[4,0,:,:,:])/dt
                bc_a06_tend=(mos_bc[5,1,:,:,:]-mos_bc[5,0,:,:,:])/dt
                bc_a07_tend=(mos_bc[6,1,:,:,:]-mos_bc[6,0,:,:,:])/dt
                bc_a08_tend=(mos_bc[7,1,:,:,:]-mos_bc[7,0,:,:,:])/dt
        if OC:
            oc_a01_tend=(mos_oc[0,1,:,:,:]-mos_oc[0,0,:,:,:])/dt
            oc_a02_tend=(mos_oc[1,1,:,:,:]-mos_oc[1,0,:,:,:])/dt
            oc_a03_tend=(mos_oc[2,1,:,:,:]-mos_oc[2,0,:,:,:])/dt
            oc_a04_tend=(mos_oc[3,1,:,:,:]-mos_oc[3,0,:,:,:])/dt
            if bins8:
                oc_a05_tend=(mos_oc[4,1,:,:,:]-mos_oc[4,0,:,:,:])/dt
                oc_a06_tend=(mos_oc[5,1,:,:,:]-mos_oc[5,0,:,:,:])/dt
                oc_a07_tend=(mos_oc[6,1,:,:,:]-mos_oc[6,0,:,:,:])/dt
                oc_a08_tend=(mos_oc[7,1,:,:,:]-mos_oc[7,0,:,:,:])/dt
        if SO4:
            so4_a01_tend=(mos_so4[0,1,:,:,:]-mos_so4[0,0,:,:,:])/dt
            so4_a02_tend=(mos_so4[1,1,:,:,:]-mos_so4[1,0,:,:,:])/dt
            so4_a03_tend=(mos_so4[2,1,:,:,:]-mos_so4[2,0,:,:,:])/dt
            so4_a04_tend=(mos_so4[3,1,:,:,:]-mos_so4[3,0,:,:,:])/dt
            if bins8:
                so4_a05_tend=(mos_so4[4,1,:,:,:]-mos_so4[4,0,:,:,:])/dt
                so4_a06_tend=(mos_so4[5,1,:,:,:]-mos_so4[5,0,:,:,:])/dt
                so4_a07_tend=(mos_so4[6,1,:,:,:]-mos_so4[6,0,:,:,:])/dt
                so4_a08_tend=(mos_so4[7,1,:,:,:]-mos_so4[7,0,:,:,:])/dt

     #===================
     # calculate bdy
     #==================
        print("calculate bdy")
        os.system("date")
        
        # west boundary
        for l in range(bdywidth):
            for k in range(klev):
                for j in range(nlat):
                    if DUST:
                        oin_a01_bxs[l,k,j]=mos_dust[0,0,k,j,l]
                        oin_a01_btxs[l,k,j]=oin_a01_tend[k,j,l]
                        oin_a02_bxs[l,k,j]=mos_dust[1,0,k,j,l]
                        oin_a02_btxs[l,k,j]=oin_a02_tend[k,j,l]
                        oin_a03_bxs[l,k,j]=mos_dust[2,0,k,j,l]
                        oin_a03_btxs[l,k,j]=oin_a03_tend[k,j,l]
                        oin_a04_bxs[l,k,j]=mos_dust[3,0,k,j,l]
                        oin_a04_btxs[l,k,j]=oin_a04_tend[k,j,l]
                        if bins8:
                            oin_a05_bxs[l,k,j]=mos_dust[4,0,k,j,l]
                            oin_a05_btxs[l,k,j]=oin_a05_tend[k,j,l]
                            oin_a06_bxs[l,k,j]=mos_dust[5,0,k,j,l]
                            oin_a06_btxs[l,k,j]=oin_a06_tend[k,j,l]
                            oin_a07_bxs[l,k,j]=mos_dust[6,0,k,j,l]
                            oin_a07_btxs[l,k,j]=oin_a07_tend[k,j,l]
                            oin_a08_bxs[l,k,j]=mos_dust[7,0,k,j,l]
                            oin_a08_btxs[l,k,j]=oin_a08_tend[k,j,l]

                    if SEAS:
                        na_a01_bxs[l,k,j]=mos_na[0,0,k,j,l]
                        na_a01_btxs[l,k,j]=na_a01_tend[k,j,l]
                        na_a02_bxs[l,k,j]=mos_na[1,0,k,j,l]
                        na_a02_btxs[l,k,j]=na_a02_tend[k,j,l]
                        na_a03_bxs[l,k,j]=mos_na[2,0,k,j,l]
                        na_a03_btxs[l,k,j]=na_a03_tend[k,j,l]
                        na_a04_bxs[l,k,j]=mos_na[3,0,k,j,l]
                        na_a04_btxs[l,k,j]=na_a04_tend[k,j,l]
                        if bins8:
                            na_a05_bxs[l,k,j]=mos_na[4,0,k,j,l]
                            na_a05_btxs[l,k,j]=na_a05_tend[k,j,l]
                            na_a06_bxs[l,k,j]=mos_na[5,0,k,j,l]
                            na_a06_btxs[l,k,j]=na_a06_tend[k,j,l]
                            na_a07_bxs[l,k,j]=mos_na[6,0,k,j,l]
                            na_a07_btxs[l,k,j]=na_a07_tend[k,j,l]
                            na_a08_bxs[l,k,j]=mos_na[7,0,k,j,l]
                            na_a08_btxs[l,k,j]=na_a08_tend[k,j,l]

                        cl_a01_bxs[l,k,j]=mos_cl[0,0,k,j,l]
                        cl_a01_btxs[l,k,j]=cl_a01_tend[k,j,l]
                        cl_a02_bxs[l,k,j]=mos_cl[1,0,k,j,l]
                        cl_a02_btxs[l,k,j]=cl_a02_tend[k,j,l]
                        cl_a03_bxs[l,k,j]=mos_cl[2,0,k,j,l]
                        cl_a03_btxs[l,k,j]=cl_a03_tend[k,j,l]
                        cl_a04_bxs[l,k,j]=mos_cl[3,0,k,j,l]
                        cl_a04_btxs[l,k,j]=cl_a04_tend[k,j,l]
                        if bins8:
                            cl_a05_bxs[l,k,j]=mos_cl[4,0,k,j,l]
                            cl_a05_btxs[l,k,j]=cl_a05_tend[k,j,l]
                            cl_a06_bxs[l,k,j]=mos_cl[5,0,k,j,l]
                            cl_a06_btxs[l,k,j]=cl_a06_tend[k,j,l]
                            cl_a07_bxs[l,k,j]=mos_cl[6,0,k,j,l]
                            cl_a07_btxs[l,k,j]=cl_a07_tend[k,j,l]
                            cl_a08_bxs[l,k,j]=mos_cl[7,0,k,j,l]
                            cl_a08_btxs[l,k,j]=cl_a08_tend[k,j,l]
                    if BC:
                        bc_a01_bxs[l,k,j]=mos_bc[0,0,k,j,l]
                        bc_a01_btxs[l,k,j]=bc_a01_tend[k,j,l]
                        bc_a02_bxs[l,k,j]=mos_bc[1,0,k,j,l]
                        bc_a02_btxs[l,k,j]=bc_a02_tend[k,j,l]
                        bc_a03_bxs[l,k,j]=mos_bc[2,0,k,j,l]
                        bc_a03_btxs[l,k,j]=bc_a03_tend[k,j,l]
                        bc_a04_bxs[l,k,j]=mos_bc[3,0,k,j,l]
                        bc_a04_btxs[l,k,j]=bc_a04_tend[k,j,l]
                        if bins8:
                            bc_a05_bxs[l,k,j]=mos_bc[4,0,k,j,l]
                            bc_a05_btxs[l,k,j]=bc_a05_tend[k,j,l]
                            bc_a06_bxs[l,k,j]=mos_bc[5,0,k,j,l]
                            bc_a06_btxs[l,k,j]=bc_a06_tend[k,j,l]
                            bc_a07_bxs[l,k,j]=mos_bc[6,0,k,j,l]
                            bc_a07_btxs[l,k,j]=bc_a07_tend[k,j,l]
                            bc_a08_bxs[l,k,j]=mos_bc[7,0,k,j,l]
                            bc_a08_btxs[l,k,j]=bc_a08_tend[k,j,l]
                    if OC:
                        oc_a01_bxs[l,k,j]=mos_oc[0,0,k,j,l]
                        oc_a01_btxs[l,k,j]=oc_a01_tend[k,j,l]
                        oc_a02_bxs[l,k,j]=mos_oc[1,0,k,j,l]
                        oc_a02_btxs[l,k,j]=oc_a02_tend[k,j,l]
                        oc_a03_bxs[l,k,j]=mos_oc[2,0,k,j,l]
                        oc_a03_btxs[l,k,j]=oc_a03_tend[k,j,l]
                        oc_a04_bxs[l,k,j]=mos_oc[3,0,k,j,l]
                        oc_a04_btxs[l,k,j]=oc_a04_tend[k,j,l]
                        if bins8:
                            oc_a05_bxs[l,k,j]=mos_oc[4,0,k,j,l]
                            oc_a05_btxs[l,k,j]=oc_a05_tend[k,j,l]
                            oc_a06_bxs[l,k,j]=mos_oc[5,0,k,j,l]
                            oc_a06_btxs[l,k,j]=oc_a06_tend[k,j,l]
                            oc_a07_bxs[l,k,j]=mos_oc[6,0,k,j,l]
                            oc_a07_btxs[l,k,j]=oc_a07_tend[k,j,l]
                            oc_a08_bxs[l,k,j]=mos_oc[7,0,k,j,l]
                            oc_a08_btxs[l,k,j]=oc_a08_tend[k,j,l]
                    if SO4:
                        so4_a01_bxs[l,k,j]=mos_so4[0,0,k,j,l]
                        so4_a01_btxs[l,k,j]=so4_a01_tend[k,j,l]
                        so4_a02_bxs[l,k,j]=mos_so4[1,0,k,j,l]
                        so4_a02_btxs[l,k,j]=so4_a02_tend[k,j,l]
                        so4_a03_bxs[l,k,j]=mos_so4[2,0,k,j,l]
                        so4_a03_btxs[l,k,j]=so4_a03_tend[k,j,l]
                        so4_a04_bxs[l,k,j]=mos_so4[3,0,k,j,l]
                        so4_a04_btxs[l,k,j]=so4_a04_tend[k,j,l]
                        if bins8:
                            so4_a05_bxs[l,k,j]=mos_so4[4,0,k,j,l]
                            so4_a05_btxs[l,k,j]=so4_a05_tend[k,j,l]
                            so4_a06_bxs[l,k,j]=mos_so4[5,0,k,j,l]
                            so4_a06_btxs[l,k,j]=so4_a06_tend[k,j,l]
                            so4_a07_bxs[l,k,j]=mos_so4[6,0,k,j,l]
                            so4_a07_btxs[l,k,j]=so4_a07_tend[k,j,l]
                            so4_a08_bxs[l,k,j]=mos_so4[7,0,k,j,l]
                            so4_a08_btxs[l,k,j]=so4_a08_tend[k,j,l]

        #east boundary
        for l in range(bdywidth):
            for k in range(klev):
                for j in range(nlat):
                    if DUST:
                        oin_a01_bxe[l,k,j]=mos_dust[0,0,k,j,mlon-1-l]
                        oin_a01_btxe[l,k,j]=oin_a01_tend[k,j,mlon-1-l]
                        oin_a02_bxe[l,k,j]=mos_dust[1,0,k,j,mlon-1-l]
                        oin_a02_btxe[l,k,j]=oin_a02_tend[k,j,mlon-1-l]
                        oin_a03_bxe[l,k,j]=mos_dust[2,0,k,j,mlon-1-l]
                        oin_a03_btxe[l,k,j]=oin_a03_tend[k,j,mlon-1-l]
                        oin_a04_bxe[l,k,j]=mos_dust[3,0,k,j,mlon-1-l]
                        oin_a04_btxe[l,k,j]=oin_a04_tend[k,j,mlon-1-l]
                        if bins8:
                            oin_a05_bxe[l,k,j]=mos_dust[4,0,k,j,mlon-1-l]
                            oin_a05_btxe[l,k,j]=oin_a05_tend[k,j,mlon-1-l]
                            oin_a06_bxe[l,k,j]=mos_dust[5,0,k,j,mlon-1-l]
                            oin_a06_btxe[l,k,j]=oin_a06_tend[k,j,mlon-1-l]
                            oin_a07_bxe[l,k,j]=mos_dust[6,0,k,j,mlon-1-l]
                            oin_a07_btxe[l,k,j]=oin_a07_tend[k,j,mlon-1-l]
                            oin_a08_bxe[l,k,j]=mos_dust[7,0,k,j,mlon-1-l]
                            oin_a08_btxe[l,k,j]=oin_a08_tend[k,j,mlon-1-l]

                    if SEAS:
                        na_a01_bxe[l,k,j]=mos_na[0,0,k,j,mlon-1-l]
                        na_a01_btxe[l,k,j]=na_a01_tend[k,j,mlon-1-l]
                        na_a02_bxe[l,k,j]=mos_na[1,0,k,j,mlon-1-l]
                        na_a02_btxe[l,k,j]=na_a02_tend[k,j,mlon-1-l]
                        na_a03_bxe[l,k,j]=mos_na[2,0,k,j,mlon-1-l]
                        na_a03_btxe[l,k,j]=na_a03_tend[k,j,mlon-1-l]
                        na_a04_bxe[l,k,j]=mos_na[3,0,k,j,mlon-1-l]
                        na_a04_btxe[l,k,j]=na_a04_tend[k,j,mlon-1-l]
                        if bins8:
                            na_a05_bxe[l,k,j]=mos_na[4,0,k,j,mlon-1-l]
                            na_a05_btxe[l,k,j]=na_a05_tend[k,j,mlon-1-l]
                            na_a06_bxe[l,k,j]=mos_na[5,0,k,j,mlon-1-l]
                            na_a06_btxe[l,k,j]=na_a06_tend[k,j,mlon-1-l]
                            na_a07_bxe[l,k,j]=mos_na[6,0,k,j,mlon-1-l]
                            na_a07_btxe[l,k,j]=na_a07_tend[k,j,mlon-1-l]
                            na_a08_bxe[l,k,j]=mos_na[7,0,k,j,mlon-1-l]
                            na_a08_btxe[l,k,j]=na_a08_tend[k,j,mlon-1-l]

                        cl_a01_bxe[l,k,j]=mos_cl[0,0,k,j,mlon-1-l]
                        cl_a01_btxe[l,k,j]=cl_a01_tend[k,j,mlon-1-l]
                        cl_a02_bxe[l,k,j]=mos_cl[1,0,k,j,mlon-1-l]
                        cl_a02_btxe[l,k,j]=cl_a02_tend[k,j,mlon-1-l]
                        cl_a03_bxe[l,k,j]=mos_cl[2,0,k,j,mlon-1-l]
                        cl_a03_btxe[l,k,j]=cl_a03_tend[k,j,mlon-1-l]
                        cl_a04_bxe[l,k,j]=mos_cl[3,0,k,j,mlon-1-l]
                        cl_a04_btxe[l,k,j]=cl_a04_tend[k,j,mlon-1-l]
                        if bins8:
                            cl_a05_bxe[l,k,j]=mos_cl[4,0,k,j,mlon-1-l]
                            cl_a05_btxe[l,k,j]=cl_a05_tend[k,j,mlon-1-l]
                            cl_a06_bxe[l,k,j]=mos_cl[5,0,k,j,mlon-1-l]
                            cl_a06_btxe[l,k,j]=cl_a06_tend[k,j,mlon-1-l]
                            cl_a07_bxe[l,k,j]=mos_cl[6,0,k,j,mlon-1-l]
                            cl_a07_btxe[l,k,j]=cl_a07_tend[k,j,mlon-1-l]
                            cl_a08_bxe[l,k,j]=mos_cl[7,0,k,j,mlon-1-l]
                            cl_a08_btxe[l,k,j]=cl_a08_tend[k,j,mlon-1-l]
                    if BC:
                        bc_a01_bxe[l,k,j]=mos_bc[0,0,k,j,mlon-1-l]
                        bc_a01_btxe[l,k,j]=bc_a01_tend[k,j,mlon-1-l]
                        bc_a02_bxe[l,k,j]=mos_bc[1,0,k,j,mlon-1-l]
                        bc_a02_btxe[l,k,j]=bc_a02_tend[k,j,mlon-1-l]
                        bc_a03_bxe[l,k,j]=mos_bc[2,0,k,j,mlon-1-l]
                        bc_a03_btxe[l,k,j]=bc_a03_tend[k,j,mlon-1-l]
                        bc_a04_bxe[l,k,j]=mos_bc[3,0,k,j,mlon-1-l]
                        bc_a04_btxe[l,k,j]=bc_a04_tend[k,j,mlon-1-l]
                        if bins8:
                            bc_a05_bxe[l,k,j]=mos_bc[4,0,k,j,mlon-1-l]
                            bc_a05_btxe[l,k,j]=bc_a05_tend[k,j,mlon-1-l]
                            bc_a06_bxe[l,k,j]=mos_bc[5,0,k,j,mlon-1-l]
                            bc_a06_btxe[l,k,j]=bc_a06_tend[k,j,mlon-1-l]
                            bc_a07_bxe[l,k,j]=mos_bc[6,0,k,j,mlon-1-l]
                            bc_a07_btxe[l,k,j]=bc_a07_tend[k,j,mlon-1-l]
                            bc_a08_bxe[l,k,j]=mos_bc[7,0,k,j,mlon-1-l]
                            bc_a08_btxe[l,k,j]=bc_a08_tend[k,j,mlon-1-l]
                    if OC:
                        oc_a01_bxe[l,k,j]=mos_oc[0,0,k,j,mlon-1-l]
                        oc_a01_btxe[l,k,j]=oc_a01_tend[k,j,mlon-1-l]
                        oc_a02_bxe[l,k,j]=mos_oc[1,0,k,j,mlon-1-l]
                        oc_a02_btxe[l,k,j]=oc_a02_tend[k,j,mlon-1-l]
                        oc_a03_bxe[l,k,j]=mos_oc[2,0,k,j,mlon-1-l]
                        oc_a03_btxe[l,k,j]=oc_a03_tend[k,j,mlon-1-l]
                        oc_a04_bxe[l,k,j]=mos_oc[3,0,k,j,mlon-1-l]
                        oc_a04_btxe[l,k,j]=oc_a04_tend[k,j,mlon-1-l]
                        if bins8:
                            oc_a05_bxe[l,k,j]=mos_oc[4,0,k,j,mlon-1-l]
                            oc_a05_btxe[l,k,j]=oc_a05_tend[k,j,mlon-1-l]
                            oc_a06_bxe[l,k,j]=mos_oc[5,0,k,j,mlon-1-l]
                            oc_a06_btxe[l,k,j]=oc_a06_tend[k,j,mlon-1-l]
                            oc_a07_bxe[l,k,j]=mos_oc[6,0,k,j,mlon-1-l]
                            oc_a07_btxe[l,k,j]=oc_a07_tend[k,j,mlon-1-l]
                            oc_a08_bxe[l,k,j]=mos_oc[7,0,k,j,mlon-1-l]
                            oc_a08_btxe[l,k,j]=oc_a08_tend[k,j,mlon-1-l]
                    if SO4:
                        so4_a01_bxe[l,k,j]=mos_so4[0,0,k,j,mlon-1-l]
                        so4_a01_btxe[l,k,j]=so4_a01_tend[k,j,mlon-1-l]
                        so4_a02_bxe[l,k,j]=mos_so4[1,0,k,j,mlon-1-l]
                        so4_a02_btxe[l,k,j]=so4_a02_tend[k,j,mlon-1-l]
                        so4_a03_bxe[l,k,j]=mos_so4[2,0,k,j,mlon-1-l]
                        so4_a03_btxe[l,k,j]=so4_a03_tend[k,j,mlon-1-l]
                        so4_a04_bxe[l,k,j]=mos_so4[3,0,k,j,mlon-1-l]
                        so4_a04_btxe[l,k,j]=so4_a04_tend[k,j,mlon-1-l]
                        if bins8:
                            so4_a05_bxe[l,k,j]=mos_so4[4,0,k,j,mlon-1-l]
                            so4_a05_btxe[l,k,j]=so4_a05_tend[k,j,mlon-1-l]
                            so4_a06_bxe[l,k,j]=mos_so4[5,0,k,j,mlon-1-l]
                            so4_a06_btxe[l,k,j]=so4_a06_tend[k,j,mlon-1-l]
                            so4_a07_bxe[l,k,j]=mos_so4[6,0,k,j,mlon-1-l]
                            so4_a07_btxe[l,k,j]=so4_a07_tend[k,j,mlon-1-l]
                            so4_a08_bxe[l,k,j]=mos_so4[7,0,k,j,mlon-1-l]
                            so4_a08_btxe[l,k,j]=so4_a08_tend[k,j,mlon-1-l]

        #south boundary
        for l in range(bdywidth):
            for k in range(klev):
                for i in range(mlon):
                    if DUST:
                        oin_a01_bys[l,k,i]=mos_dust[0,0,k,l,i]
                        oin_a01_btys[l,k,i]=oin_a01_tend[k,l,i]
                        oin_a02_bys[l,k,i]=mos_dust[1,0,k,l,i]
                        oin_a02_btys[l,k,i]=oin_a02_tend[k,l,i]
                        oin_a03_bys[l,k,i]=mos_dust[2,0,k,l,i]
                        oin_a03_btys[l,k,i]=oin_a03_tend[k,l,i]
                        oin_a04_bys[l,k,i]=mos_dust[3,0,k,l,i]
                        oin_a04_btys[l,k,i]=oin_a04_tend[k,l,i]
                        if bins8:
                            oin_a05_bys[l,k,i]=mos_dust[4,0,k,l,i]
                            oin_a05_btys[l,k,i]=oin_a05_tend[k,l,i]
                            oin_a06_bys[l,k,i]=mos_dust[5,0,k,l,i]
                            oin_a06_btys[l,k,i]=oin_a06_tend[k,l,i]
                            oin_a07_bys[l,k,i]=mos_dust[6,0,k,l,i]
                            oin_a07_btys[l,k,i]=oin_a07_tend[k,l,i]
                            oin_a08_bys[l,k,i]=mos_dust[7,0,k,l,i]
                            oin_a08_btys[l,k,i]=oin_a08_tend[k,l,i]

                    if SEAS:
                        na_a01_bys[l,k,i]=mos_na[0,0,k,l,i]
                        na_a01_btys[l,k,i]=na_a01_tend[k,l,i]
                        na_a02_bys[l,k,i]=mos_na[1,0,k,l,i]
                        na_a02_btys[l,k,i]=na_a02_tend[k,l,i]
                        na_a03_bys[l,k,i]=mos_na[2,0,k,l,i]
                        na_a03_btys[l,k,i]=na_a03_tend[k,l,i]
                        na_a04_bys[l,k,i]=mos_na[3,0,k,l,i]
                        na_a04_btys[l,k,i]=na_a04_tend[k,l,i]
                        if bins8:
                            na_a05_bys[l,k,i]=mos_na[4,0,k,l,i]
                            na_a05_btys[l,k,i]=na_a05_tend[k,l,i]
                            na_a06_bys[l,k,i]=mos_na[5,0,k,l,i]
                            na_a06_btys[l,k,i]=na_a06_tend[k,l,i]
                            na_a07_bys[l,k,i]=mos_na[6,0,k,l,i]
                            na_a07_btys[l,k,i]=na_a07_tend[k,l,i]
                            na_a08_bys[l,k,i]=mos_na[7,0,k,l,i]
                            na_a08_btys[l,k,i]=na_a08_tend[k,l,i]

                        cl_a01_bys[l,k,i]=mos_cl[0,0,k,l,i]
                        cl_a01_btys[l,k,i]=cl_a01_tend[k,l,i]
                        cl_a02_bys[l,k,i]=mos_cl[1,0,k,l,i]
                        cl_a02_btys[l,k,i]=cl_a02_tend[k,l,i]
                        cl_a03_bys[l,k,i]=mos_cl[2,0,k,l,i]
                        cl_a03_btys[l,k,i]=cl_a03_tend[k,l,i]
                        cl_a04_bys[l,k,i]=mos_cl[3,0,k,l,i]
                        cl_a04_btys[l,k,i]=cl_a04_tend[k,l,i]
                        if bins8:
                            cl_a05_bys[l,k,i]=mos_cl[4,0,k,l,i]
                            cl_a05_btys[l,k,i]=cl_a05_tend[k,l,i]
                            cl_a06_bys[l,k,i]=mos_cl[5,0,k,l,i]
                            cl_a06_btys[l,k,i]=cl_a06_tend[k,l,i]
                            cl_a07_bys[l,k,i]=mos_cl[6,0,k,l,i]
                            cl_a07_btys[l,k,i]=cl_a07_tend[k,l,i]
                            cl_a08_bys[l,k,i]=mos_cl[7,0,k,l,i]
                            cl_a08_btys[l,k,i]=cl_a08_tend[k,l,i]
                    if BC:
                        bc_a01_bys[l,k,i]=mos_bc[0,0,k,l,i]
                        bc_a01_btys[l,k,i]=bc_a01_tend[k,l,i]
                        bc_a02_bys[l,k,i]=mos_bc[1,0,k,l,i]
                        bc_a02_btys[l,k,i]=bc_a02_tend[k,l,i]
                        bc_a03_bys[l,k,i]=mos_bc[2,0,k,l,i]
                        bc_a03_btys[l,k,i]=bc_a03_tend[k,l,i]
                        bc_a04_bys[l,k,i]=mos_bc[3,0,k,l,i]
                        bc_a04_btys[l,k,i]=bc_a04_tend[k,l,i]
                        if bins8:
                            bc_a05_bys[l,k,i]=mos_bc[4,0,k,l,i]
                            bc_a05_btys[l,k,i]=bc_a05_tend[k,l,i]
                            bc_a06_bys[l,k,i]=mos_bc[5,0,k,l,i]
                            bc_a06_btys[l,k,i]=bc_a06_tend[k,l,i]
                            bc_a07_bys[l,k,i]=mos_bc[6,0,k,l,i]
                            bc_a07_btys[l,k,i]=bc_a07_tend[k,l,i]
                            bc_a08_bys[l,k,i]=mos_bc[7,0,k,l,i]
                            bc_a08_btys[l,k,i]=bc_a08_tend[k,l,i]
                    if OC:
                        oc_a01_bys[l,k,i]=mos_oc[0,0,k,l,i]
                        oc_a01_btys[l,k,i]=oc_a01_tend[k,l,i]
                        oc_a02_bys[l,k,i]=mos_oc[1,0,k,l,i]
                        oc_a02_btys[l,k,i]=oc_a02_tend[k,l,i]
                        oc_a03_bys[l,k,i]=mos_oc[2,0,k,l,i]
                        oc_a03_btys[l,k,i]=oc_a03_tend[k,l,i]
                        oc_a04_bys[l,k,i]=mos_oc[3,0,k,l,i]
                        oc_a04_btys[l,k,i]=oc_a04_tend[k,l,i]
                        if bins8:
                            oc_a05_bys[l,k,i]=mos_oc[4,0,k,l,i]
                            oc_a05_btys[l,k,i]=oc_a05_tend[k,l,i]
                            oc_a06_bys[l,k,i]=mos_oc[5,0,k,l,i]
                            oc_a06_btys[l,k,i]=oc_a06_tend[k,l,i]
                            oc_a07_bys[l,k,i]=mos_oc[6,0,k,l,i]
                            oc_a07_btys[l,k,i]=oc_a07_tend[k,l,i]
                            oc_a08_bys[l,k,i]=mos_oc[7,0,k,l,i]
                            oc_a08_btys[l,k,i]=oc_a08_tend[k,l,i]
                    if SO4:
                        so4_a01_bys[l,k,i]=mos_so4[0,0,k,l,i]
                        so4_a01_btys[l,k,i]=so4_a01_tend[k,l,i]
                        so4_a02_bys[l,k,i]=mos_so4[1,0,k,l,i]
                        so4_a02_btys[l,k,i]=so4_a02_tend[k,l,i]
                        so4_a03_bys[l,k,i]=mos_so4[2,0,k,l,i]
                        so4_a03_btys[l,k,i]=so4_a03_tend[k,l,i]
                        so4_a04_bys[l,k,i]=mos_so4[3,0,k,l,i]
                        so4_a04_btys[l,k,i]=so4_a04_tend[k,l,i]
                        if bins8:
                            so4_a05_bys[l,k,i]=mos_so4[4,0,k,l,i]
                            so4_a05_btys[l,k,i]=so4_a05_tend[k,l,i]
                            so4_a06_bys[l,k,i]=mos_so4[5,0,k,l,i]
                            so4_a06_btys[l,k,i]=so4_a06_tend[k,l,i]
                            so4_a07_bys[l,k,i]=mos_so4[6,0,k,l,i]
                            so4_a07_btys[l,k,i]=so4_a07_tend[k,l,i]
                            so4_a08_bys[l,k,i]=mos_so4[7,0,k,l,i]
                            so4_a08_btys[l,k,i]=so4_a08_tend[k,l,i]

        #north boundary
        for l in range(bdywidth):
            for k in range(klev):
                for i in range(mlon):
                    if DUST:
                        oin_a01_bye[l,k,i]=mos_dust[0,0,k,nlat-1-l,i]
                        oin_a01_btye[l,k,i]=oin_a01_tend[k,nlat-1-l,i]
                        oin_a02_bye[l,k,i]=mos_dust[1,0,k,nlat-1-l,i]
                        oin_a02_btye[l,k,i]=oin_a02_tend[k,nlat-1-l,i]
                        oin_a03_bye[l,k,i]=mos_dust[2,0,k,nlat-1-l,i]
                        oin_a03_btye[l,k,i]=oin_a03_tend[k,nlat-1-l,i]
                        oin_a04_bye[l,k,i]=mos_dust[3,0,k,nlat-1-l,i]
                        oin_a04_btye[l,k,i]=oin_a04_tend[k,nlat-1-l,i]
                        if bins8:
                            oin_a05_bye[l,k,i]=mos_dust[4,0,k,nlat-1-l,i]
                            oin_a05_btye[l,k,i]=oin_a05_tend[k,nlat-1-l,i]
                            oin_a06_bye[l,k,i]=mos_dust[5,0,k,nlat-1-l,i]
                            oin_a06_btye[l,k,i]=oin_a06_tend[k,nlat-1-l,i]
                            oin_a07_bye[l,k,i]=mos_dust[6,0,k,nlat-1-l,i]
                            oin_a07_btye[l,k,i]=oin_a07_tend[k,nlat-1-l,i]
                            oin_a08_bye[l,k,i]=mos_dust[7,0,k,nlat-1-l,i]
                            oin_a08_btye[l,k,i]=oin_a08_tend[k,nlat-1-l,i]

                    if SEAS:
                        na_a01_bye[l,k,i]=mos_na[0,0,k,nlat-1-l,i]
                        na_a01_btye[l,k,i]=na_a01_tend[k,nlat-1-l,i]
                        na_a02_bye[l,k,i]=mos_na[1,0,k,nlat-1-l,i]
                        na_a02_btye[l,k,i]=na_a02_tend[k,nlat-1-l,i]
                        na_a03_bye[l,k,i]=mos_na[2,0,k,nlat-1-l,i]
                        na_a03_btye[l,k,i]=na_a03_tend[k,nlat-1-l,i]
                        na_a04_bye[l,k,i]=mos_na[3,0,k,nlat-1-l,i]
                        na_a04_btye[l,k,i]=na_a04_tend[k,nlat-1-l,i]
                        if bins8:
                            na_a05_bye[l,k,i]=mos_na[4,0,k,nlat-1-l,i]
                            na_a05_btye[l,k,i]=na_a05_tend[k,nlat-1-l,i]
                            na_a06_bye[l,k,i]=mos_na[5,0,k,nlat-1-l,i]
                            na_a06_btye[l,k,i]=na_a06_tend[k,nlat-1-l,i]
                            na_a07_bye[l,k,i]=mos_na[6,0,k,nlat-1-l,i]
                            na_a07_btye[l,k,i]=na_a07_tend[k,nlat-1-l,i]
                            na_a08_bye[l,k,i]=mos_na[7,0,k,nlat-1-l,i]
                            na_a08_btye[l,k,i]=na_a08_tend[k,nlat-1-l,i]

                        cl_a01_bye[l,k,i]=mos_cl[0,0,k,nlat-1-l,i]
                        cl_a01_btye[l,k,i]=cl_a01_tend[k,nlat-1-l,i]
                        cl_a02_bye[l,k,i]=mos_cl[1,0,k,nlat-1-l,i]
                        cl_a02_btye[l,k,i]=cl_a02_tend[k,nlat-1-l,i]
                        cl_a03_bye[l,k,i]=mos_cl[2,0,k,nlat-1-l,i]
                        cl_a03_btye[l,k,i]=cl_a03_tend[k,nlat-1-l,i]
                        cl_a04_bye[l,k,i]=mos_cl[3,0,k,nlat-1-l,i]
                        cl_a04_btye[l,k,i]=cl_a04_tend[k,nlat-1-l,i]
                        if bins8:
                            cl_a05_bye[l,k,i]=mos_cl[4,0,k,nlat-1-l,i]
                            cl_a05_btye[l,k,i]=cl_a05_tend[k,nlat-1-l,i]
                            cl_a06_bye[l,k,i]=mos_cl[5,0,k,nlat-1-l,i]
                            cl_a06_btye[l,k,i]=cl_a06_tend[k,nlat-1-l,i]
                            cl_a07_bye[l,k,i]=mos_cl[6,0,k,nlat-1-l,i]
                            cl_a07_btye[l,k,i]=cl_a07_tend[k,nlat-1-l,i]
                            cl_a08_bye[l,k,i]=mos_cl[7,0,k,nlat-1-l,i]
                            cl_a08_btye[l,k,i]=cl_a08_tend[k,nlat-1-l,i]
                    if BC:
                        bc_a01_bye[l,k,i]=mos_bc[0,0,k,nlat-1-l,i]
                        bc_a01_btye[l,k,i]=bc_a01_tend[k,nlat-1-l,i]
                        bc_a02_bye[l,k,i]=mos_bc[1,0,k,nlat-1-l,i]
                        bc_a02_btye[l,k,i]=bc_a02_tend[k,nlat-1-l,i]
                        bc_a03_bye[l,k,i]=mos_bc[2,0,k,nlat-1-l,i]
                        bc_a03_btye[l,k,i]=bc_a03_tend[k,nlat-1-l,i]
                        bc_a04_bye[l,k,i]=mos_bc[3,0,k,nlat-1-l,i]
                        bc_a04_btye[l,k,i]=bc_a04_tend[k,nlat-1-l,i]
                        if bins8:
                            bc_a05_bye[l,k,i]=mos_bc[4,0,k,nlat-1-l,i]
                            bc_a05_btye[l,k,i]=bc_a05_tend[k,nlat-1-l,i]
                            bc_a06_bye[l,k,i]=mos_bc[5,0,k,nlat-1-l,i]
                            bc_a06_btye[l,k,i]=bc_a06_tend[k,nlat-1-l,i]
                            bc_a07_bye[l,k,i]=mos_bc[6,0,k,nlat-1-l,i]
                            bc_a07_btye[l,k,i]=bc_a07_tend[k,nlat-1-l,i]
                            bc_a08_bye[l,k,i]=mos_bc[7,0,k,nlat-1-l,i]
                            bc_a08_btye[l,k,i]=bc_a08_tend[k,nlat-1-l,i]
                    if OC:
                        oc_a01_bye[l,k,i]=mos_oc[0,0,k,nlat-1-l,i]
                        oc_a01_btye[l,k,i]=oc_a01_tend[k,nlat-1-l,i]
                        oc_a02_bye[l,k,i]=mos_oc[1,0,k,nlat-1-l,i]
                        oc_a02_btye[l,k,i]=oc_a02_tend[k,nlat-1-l,i]
                        oc_a03_bye[l,k,i]=mos_oc[2,0,k,nlat-1-l,i]
                        oc_a03_btye[l,k,i]=oc_a03_tend[k,nlat-1-l,i]
                        oc_a04_bye[l,k,i]=mos_oc[3,0,k,nlat-1-l,i]
                        oc_a04_btye[l,k,i]=oc_a04_tend[k,nlat-1-l,i]
                        if bins8:
                            oc_a05_bye[l,k,i]=mos_oc[4,0,k,nlat-1-l,i]
                            oc_a05_btye[l,k,i]=oc_a05_tend[k,nlat-1-l,i]
                            oc_a06_bye[l,k,i]=mos_oc[5,0,k,nlat-1-l,i]
                            oc_a06_btye[l,k,i]=oc_a06_tend[k,nlat-1-l,i]
                            oc_a07_bye[l,k,i]=mos_oc[6,0,k,nlat-1-l,i]
                            oc_a07_btye[l,k,i]=oc_a07_tend[k,nlat-1-l,i]
                            oc_a08_bye[l,k,i]=mos_oc[7,0,k,nlat-1-l,i]
                            oc_a08_btye[l,k,i]=oc_a08_tend[k,nlat-1-l,i]
                    if SO4:
                        so4_a01_bye[l,k,i]=mos_so4[0,0,k,nlat-1-l,i]
                        so4_a01_btye[l,k,i]=so4_a01_tend[k,nlat-1-l,i]
                        so4_a02_bye[l,k,i]=mos_so4[1,0,k,nlat-1-l,i]
                        so4_a02_btye[l,k,i]=so4_a02_tend[k,nlat-1-l,i]
                        so4_a03_bye[l,k,i]=mos_so4[2,0,k,nlat-1-l,i]
                        so4_a03_btye[l,k,i]=so4_a03_tend[k,nlat-1-l,i]
                        so4_a04_bye[l,k,i]=mos_so4[3,0,k,nlat-1-l,i]
                        so4_a04_btye[l,k,i]=so4_a04_tend[k,nlat-1-l,i]
                        if bins8:
                            so4_a05_bye[l,k,i]=mos_so4[4,0,k,nlat-1-l,i]
                            so4_a05_btye[l,k,i]=so4_a05_tend[k,nlat-1-l,i]
                            so4_a06_bye[l,k,i]=mos_so4[5,0,k,nlat-1-l,i]
                            so4_a06_btye[l,k,i]=so4_a06_tend[k,nlat-1-l,i]
                            so4_a07_bye[l,k,i]=mos_so4[6,0,k,nlat-1-l,i]
                            so4_a07_btye[l,k,i]=so4_a07_tend[k,nlat-1-l,i]
                            so4_a08_bye[l,k,i]=mos_so4[7,0,k,nlat-1-l,i]
                            so4_a08_btye[l,k,i]=so4_a08_tend[k,nlat-1-l,i]

    #====================
    # replace bdy
    #========================
        print("replace bdy it="+str(it))
        os.system("date")
        if DUST:
            print("replace dust in bdy")
            wrfbdyf.variables['oin_a01_BXS'][it,:,:,:]=oin_a01_bxs[:,:,:]
            wrfbdyf.variables['oin_a01_BTXS'][it,:,:,:]=oin_a01_btxs[:,:,:]
            wrfbdyf.variables['oin_a01_BXE'][it,:,:,:]=oin_a01_bxe[:,:,:]
            wrfbdyf.variables['oin_a01_BTXE'][it,:,:,:]=oin_a01_btxe[:,:,:]
            wrfbdyf.variables['oin_a01_BYS'][it,:,:,:]=oin_a01_bys[:,:,:]
            wrfbdyf.variables['oin_a01_BTYS'][it,:,:,:]=oin_a01_btys[:,:,:]
            wrfbdyf.variables['oin_a01_BYE'][it,:,:,:]=oin_a01_bye[:,:,:]
            wrfbdyf.variables['oin_a01_BTYE'][it,:,:,:]=oin_a01_btye[:,:,:]
            wrfbdyf.variables['oin_a02_BXS'][it,:,:,:]=oin_a02_bxs[:,:,:]
            wrfbdyf.variables['oin_a02_BTXS'][it,:,:,:]=oin_a02_btxs[:,:,:]
            wrfbdyf.variables['oin_a02_BXE'][it,:,:,:]=oin_a02_bxe[:,:,:]
            wrfbdyf.variables['oin_a02_BTXE'][it,:,:,:]=oin_a02_btxe[:,:,:]
            wrfbdyf.variables['oin_a02_BYS'][it,:,:,:]=oin_a02_bys[:,:,:]
            wrfbdyf.variables['oin_a02_BTYS'][it,:,:,:]=oin_a02_btys[:,:,:]
            wrfbdyf.variables['oin_a02_BYE'][it,:,:,:]=oin_a02_bye[:,:,:]
            wrfbdyf.variables['oin_a02_BTYE'][it,:,:,:]=oin_a02_btye[:,:,:]
            wrfbdyf.variables['oin_a03_BXS'][it,:,:,:]=oin_a03_bxs[:,:,:]
            wrfbdyf.variables['oin_a03_BTXS'][it,:,:,:]=oin_a03_btxs[:,:,:]
            wrfbdyf.variables['oin_a03_BXE'][it,:,:,:]=oin_a03_bxe[:,:,:]
            wrfbdyf.variables['oin_a03_BTXE'][it,:,:,:]=oin_a03_btxe[:,:,:]
            wrfbdyf.variables['oin_a03_BYS'][it,:,:,:]=oin_a03_bys[:,:,:]
            wrfbdyf.variables['oin_a03_BTYS'][it,:,:,:]=oin_a03_btys[:,:,:]
            wrfbdyf.variables['oin_a03_BYE'][it,:,:,:]=oin_a03_bye[:,:,:]
            wrfbdyf.variables['oin_a03_BTYE'][it,:,:,:]=oin_a03_btye[:,:,:]
            wrfbdyf.variables['oin_a04_BXS'][it,:,:,:]=oin_a04_bxs[:,:,:]
            wrfbdyf.variables['oin_a04_BTXS'][it,:,:,:]=oin_a04_btxs[:,:,:]
            wrfbdyf.variables['oin_a04_BXE'][it,:,:,:]=oin_a04_bxe[:,:,:]
            wrfbdyf.variables['oin_a04_BTXE'][it,:,:,:]=oin_a04_btxe[:,:,:]
            wrfbdyf.variables['oin_a04_BYS'][it,:,:,:]=oin_a04_bys[:,:,:]
            wrfbdyf.variables['oin_a04_BTYS'][it,:,:,:]=oin_a04_btys[:,:,:]
            wrfbdyf.variables['oin_a04_BYE'][it,:,:,:]=oin_a04_bye[:,:,:]
            wrfbdyf.variables['oin_a04_BTYE'][it,:,:,:]=oin_a04_btye[:,:,:]
            if bins8:
                wrfbdyf.variables['oin_a05_BXS'][it,:,:,:]=oin_a05_bxs[:,:,:]
                wrfbdyf.variables['oin_a05_BTXS'][it,:,:,:]=oin_a05_btxs[:,:,:]
                wrfbdyf.variables['oin_a05_BXE'][it,:,:,:]=oin_a05_bxe[:,:,:]
                wrfbdyf.variables['oin_a05_BTXE'][it,:,:,:]=oin_a05_btxe[:,:,:]
                wrfbdyf.variables['oin_a05_BYS'][it,:,:,:]=oin_a05_bys[:,:,:]
                wrfbdyf.variables['oin_a05_BTYS'][it,:,:,:]=oin_a05_btys[:,:,:]
                wrfbdyf.variables['oin_a05_BYE'][it,:,:,:]=oin_a05_bye[:,:,:]
                wrfbdyf.variables['oin_a05_BTYE'][it,:,:,:]=oin_a05_btye[:,:,:]
                wrfbdyf.variables['oin_a06_BXS'][it,:,:,:]=oin_a06_bxs[:,:,:]
                wrfbdyf.variables['oin_a06_BTXS'][it,:,:,:]=oin_a06_btxs[:,:,:]
                wrfbdyf.variables['oin_a06_BXE'][it,:,:,:]=oin_a06_bxe[:,:,:]
                wrfbdyf.variables['oin_a06_BTXE'][it,:,:,:]=oin_a06_btxe[:,:,:]
                wrfbdyf.variables['oin_a06_BYS'][it,:,:,:]=oin_a06_bys[:,:,:]
                wrfbdyf.variables['oin_a06_BTYS'][it,:,:,:]=oin_a06_btys[:,:,:]
                wrfbdyf.variables['oin_a06_BYE'][it,:,:,:]=oin_a06_bye[:,:,:]
                wrfbdyf.variables['oin_a06_BTYE'][it,:,:,:]=oin_a06_btye[:,:,:]
                wrfbdyf.variables['oin_a07_BXS'][it,:,:,:]=oin_a07_bxs[:,:,:]
                wrfbdyf.variables['oin_a07_BTXS'][it,:,:,:]=oin_a07_btxs[:,:,:]
                wrfbdyf.variables['oin_a07_BXE'][it,:,:,:]=oin_a07_bxe[:,:,:]
                wrfbdyf.variables['oin_a07_BTXE'][it,:,:,:]=oin_a07_btxe[:,:,:]
                wrfbdyf.variables['oin_a07_BYS'][it,:,:,:]=oin_a07_bys[:,:,:]
                wrfbdyf.variables['oin_a07_BTYS'][it,:,:,:]=oin_a07_btys[:,:,:]
                wrfbdyf.variables['oin_a07_BYE'][it,:,:,:]=oin_a07_bye[:,:,:]
                wrfbdyf.variables['oin_a07_BTYE'][it,:,:,:]=oin_a07_btye[:,:,:]
                wrfbdyf.variables['oin_a08_BXS'][it,:,:,:]=oin_a08_bxs[:,:,:]
                wrfbdyf.variables['oin_a08_BTXS'][it,:,:,:]=oin_a08_btxs[:,:,:]
                wrfbdyf.variables['oin_a08_BXE'][it,:,:,:]=oin_a08_bxe[:,:,:]
                wrfbdyf.variables['oin_a08_BTXE'][it,:,:,:]=oin_a08_btxe[:,:,:]
                wrfbdyf.variables['oin_a08_BYS'][it,:,:,:]=oin_a08_bys[:,:,:]
                wrfbdyf.variables['oin_a08_BTYS'][it,:,:,:]=oin_a08_btys[:,:,:]
                wrfbdyf.variables['oin_a08_BYE'][it,:,:,:]=oin_a08_bye[:,:,:]
                wrfbdyf.variables['oin_a08_BTYE'][it,:,:,:]=oin_a08_btye[:,:,:]

        if SEAS:
            print("replace Na,Cl in bdy")
            wrfbdyf.variables['na_a01_BXS'][it,:,:,:]=na_a01_bxs[:,:,:]
            wrfbdyf.variables['na_a01_BTXS'][it,:,:,:]=na_a01_btxs[:,:,:]
            wrfbdyf.variables['na_a01_BXE'][it,:,:,:]=na_a01_bxe[:,:,:]
            wrfbdyf.variables['na_a01_BTXE'][it,:,:,:]=na_a01_btxe[:,:,:]
            wrfbdyf.variables['na_a01_BYS'][it,:,:,:]=na_a01_bys[:,:,:]
            wrfbdyf.variables['na_a01_BTYS'][it,:,:,:]=na_a01_btys[:,:,:]
            wrfbdyf.variables['na_a01_BYE'][it,:,:,:]=na_a01_bye[:,:,:]
            wrfbdyf.variables['na_a01_BTYE'][it,:,:,:]=na_a01_btye[:,:,:]
            wrfbdyf.variables['na_a02_BXS'][it,:,:,:]=na_a02_bxs[:,:,:]
            wrfbdyf.variables['na_a02_BTXS'][it,:,:,:]=na_a02_btxs[:,:,:]
            wrfbdyf.variables['na_a02_BXE'][it,:,:,:]=na_a02_bxe[:,:,:]
            wrfbdyf.variables['na_a02_BTXE'][it,:,:,:]=na_a02_btxe[:,:,:]
            wrfbdyf.variables['na_a02_BYS'][it,:,:,:]=na_a02_bys[:,:,:]
            wrfbdyf.variables['na_a02_BTYS'][it,:,:,:]=na_a02_btys[:,:,:]
            wrfbdyf.variables['na_a02_BYE'][it,:,:,:]=na_a02_bye[:,:,:]
            wrfbdyf.variables['na_a02_BTYE'][it,:,:,:]=na_a02_btye[:,:,:]
            wrfbdyf.variables['na_a03_BXS'][it,:,:,:]=na_a03_bxs[:,:,:]
            wrfbdyf.variables['na_a03_BTXS'][it,:,:,:]=na_a03_btxs[:,:,:]
            wrfbdyf.variables['na_a03_BXE'][it,:,:,:]=na_a03_bxe[:,:,:]
            wrfbdyf.variables['na_a03_BTXE'][it,:,:,:]=na_a03_btxe[:,:,:]
            wrfbdyf.variables['na_a03_BYS'][it,:,:,:]=na_a03_bys[:,:,:]
            wrfbdyf.variables['na_a03_BTYS'][it,:,:,:]=na_a03_btys[:,:,:]
            wrfbdyf.variables['na_a03_BYE'][it,:,:,:]=na_a03_bye[:,:,:]
            wrfbdyf.variables['na_a03_BTYE'][it,:,:,:]=na_a03_btye[:,:,:]
            wrfbdyf.variables['na_a04_BXS'][it,:,:,:]=na_a04_bxs[:,:,:]
            wrfbdyf.variables['na_a04_BTXS'][it,:,:,:]=na_a04_btxs[:,:,:]
            wrfbdyf.variables['na_a04_BXE'][it,:,:,:]=na_a04_bxe[:,:,:]
            wrfbdyf.variables['na_a04_BTXE'][it,:,:,:]=na_a04_btxe[:,:,:]
            wrfbdyf.variables['na_a04_BYS'][it,:,:,:]=na_a04_bys[:,:,:]
            wrfbdyf.variables['na_a04_BTYS'][it,:,:,:]=na_a04_btys[:,:,:]
            wrfbdyf.variables['na_a04_BYE'][it,:,:,:]=na_a04_bye[:,:,:]
            wrfbdyf.variables['na_a04_BTYE'][it,:,:,:]=na_a04_btye[:,:,:]
            if bins8:
                wrfbdyf.variables['na_a05_BXS'][it,:,:,:]=na_a05_bxs[:,:,:]
                wrfbdyf.variables['na_a05_BTXS'][it,:,:,:]=na_a05_btxs[:,:,:]
                wrfbdyf.variables['na_a05_BXE'][it,:,:,:]=na_a05_bxe[:,:,:]
                wrfbdyf.variables['na_a05_BTXE'][it,:,:,:]=na_a05_btxe[:,:,:]
                wrfbdyf.variables['na_a05_BYS'][it,:,:,:]=na_a05_bys[:,:,:]
                wrfbdyf.variables['na_a05_BTYS'][it,:,:,:]=na_a05_btys[:,:,:]
                wrfbdyf.variables['na_a05_BYE'][it,:,:,:]=na_a05_bye[:,:,:]
                wrfbdyf.variables['na_a05_BTYE'][it,:,:,:]=na_a05_btye[:,:,:]
                wrfbdyf.variables['na_a06_BXS'][it,:,:,:]=na_a06_bxs[:,:,:]
                wrfbdyf.variables['na_a06_BTXS'][it,:,:,:]=na_a06_btxs[:,:,:]
                wrfbdyf.variables['na_a06_BXE'][it,:,:,:]=na_a06_bxe[:,:,:]
                wrfbdyf.variables['na_a06_BTXE'][it,:,:,:]=na_a06_btxe[:,:,:]
                wrfbdyf.variables['na_a06_BYS'][it,:,:,:]=na_a06_bys[:,:,:]
                wrfbdyf.variables['na_a06_BTYS'][it,:,:,:]=na_a06_btys[:,:,:]
                wrfbdyf.variables['na_a06_BYE'][it,:,:,:]=na_a06_bye[:,:,:]
                wrfbdyf.variables['na_a06_BTYE'][it,:,:,:]=na_a06_btye[:,:,:]
                wrfbdyf.variables['na_a07_BXS'][it,:,:,:]=na_a07_bxs[:,:,:]
                wrfbdyf.variables['na_a07_BTXS'][it,:,:,:]=na_a07_btxs[:,:,:]
                wrfbdyf.variables['na_a07_BXE'][it,:,:,:]=na_a07_bxe[:,:,:]
                wrfbdyf.variables['na_a07_BTXE'][it,:,:,:]=na_a07_btxe[:,:,:]
                wrfbdyf.variables['na_a07_BYS'][it,:,:,:]=na_a07_bys[:,:,:]
                wrfbdyf.variables['na_a07_BTYS'][it,:,:,:]=na_a07_btys[:,:,:]
                wrfbdyf.variables['na_a07_BYE'][it,:,:,:]=na_a07_bye[:,:,:]
                wrfbdyf.variables['na_a07_BTYE'][it,:,:,:]=na_a07_btye[:,:,:]
                wrfbdyf.variables['na_a08_BXS'][it,:,:,:]=na_a08_bxs[:,:,:]
                wrfbdyf.variables['na_a08_BTXS'][it,:,:,:]=na_a08_btxs[:,:,:]
                wrfbdyf.variables['na_a08_BXE'][it,:,:,:]=na_a08_bxe[:,:,:]
                wrfbdyf.variables['na_a08_BTXE'][it,:,:,:]=na_a08_btxe[:,:,:]
                wrfbdyf.variables['na_a08_BYS'][it,:,:,:]=na_a08_bys[:,:,:]
                wrfbdyf.variables['na_a08_BTYS'][it,:,:,:]=na_a08_btys[:,:,:]
                wrfbdyf.variables['na_a08_BYE'][it,:,:,:]=na_a08_bye[:,:,:]
                wrfbdyf.variables['na_a08_BTYE'][it,:,:,:]=na_a08_btye[:,:,:]
       
            wrfbdyf.variables['cl_a01_BXS'][it,:,:,:]=cl_a01_bxs[:,:,:]
            wrfbdyf.variables['cl_a01_BTXS'][it,:,:,:]=cl_a01_btxs[:,:,:]
            wrfbdyf.variables['cl_a01_BXE'][it,:,:,:]=cl_a01_bxe[:,:,:]
            wrfbdyf.variables['cl_a01_BTXE'][it,:,:,:]=cl_a01_btxe[:,:,:]
            wrfbdyf.variables['cl_a01_BYS'][it,:,:,:]=cl_a01_bys[:,:,:]
            wrfbdyf.variables['cl_a01_BTYS'][it,:,:,:]=cl_a01_btys[:,:,:]
            wrfbdyf.variables['cl_a01_BYE'][it,:,:,:]=cl_a01_bye[:,:,:]
            wrfbdyf.variables['cl_a01_BTYE'][it,:,:,:]=cl_a01_btye[:,:,:]
            wrfbdyf.variables['cl_a02_BXS'][it,:,:,:]=cl_a02_bxs[:,:,:]
            wrfbdyf.variables['cl_a02_BTXS'][it,:,:,:]=cl_a02_btxs[:,:,:]
            wrfbdyf.variables['cl_a02_BXE'][it,:,:,:]=cl_a02_bxe[:,:,:]
            wrfbdyf.variables['cl_a02_BTXE'][it,:,:,:]=cl_a02_btxe[:,:,:]
            wrfbdyf.variables['cl_a02_BYS'][it,:,:,:]=cl_a02_bys[:,:,:]
            wrfbdyf.variables['cl_a02_BTYS'][it,:,:,:]=cl_a02_btys[:,:,:]
            wrfbdyf.variables['cl_a02_BYE'][it,:,:,:]=cl_a02_bye[:,:,:]
            wrfbdyf.variables['cl_a02_BTYE'][it,:,:,:]=cl_a02_btye[:,:,:]
            wrfbdyf.variables['cl_a03_BXS'][it,:,:,:]=cl_a03_bxs[:,:,:]
            wrfbdyf.variables['cl_a03_BTXS'][it,:,:,:]=cl_a03_btxs[:,:,:]
            wrfbdyf.variables['cl_a03_BXE'][it,:,:,:]=cl_a03_bxe[:,:,:]
            wrfbdyf.variables['cl_a03_BTXE'][it,:,:,:]=cl_a03_btxe[:,:,:]
            wrfbdyf.variables['cl_a03_BYS'][it,:,:,:]=cl_a03_bys[:,:,:]
            wrfbdyf.variables['cl_a03_BTYS'][it,:,:,:]=cl_a03_btys[:,:,:]
            wrfbdyf.variables['cl_a03_BYE'][it,:,:,:]=cl_a03_bye[:,:,:]
            wrfbdyf.variables['cl_a03_BTYE'][it,:,:,:]=cl_a03_btye[:,:,:]
            wrfbdyf.variables['cl_a04_BXS'][it,:,:,:]=cl_a04_bxs[:,:,:]
            wrfbdyf.variables['cl_a04_BTXS'][it,:,:,:]=cl_a04_btxs[:,:,:]
            wrfbdyf.variables['cl_a04_BXE'][it,:,:,:]=cl_a04_bxe[:,:,:]
            wrfbdyf.variables['cl_a04_BTXE'][it,:,:,:]=cl_a04_btxe[:,:,:]
            wrfbdyf.variables['cl_a04_BYS'][it,:,:,:]=cl_a04_bys[:,:,:]
            wrfbdyf.variables['cl_a04_BTYS'][it,:,:,:]=cl_a04_btys[:,:,:]
            wrfbdyf.variables['cl_a04_BYE'][it,:,:,:]=cl_a04_bye[:,:,:]
            wrfbdyf.variables['cl_a04_BTYE'][it,:,:,:]=cl_a04_btye[:,:,:]
            if bins8:
                wrfbdyf.variables['cl_a05_BXS'][it,:,:,:]=cl_a05_bxs[:,:,:]
                wrfbdyf.variables['cl_a05_BTXS'][it,:,:,:]=cl_a05_btxs[:,:,:]
                wrfbdyf.variables['cl_a05_BXE'][it,:,:,:]=cl_a05_bxe[:,:,:]
                wrfbdyf.variables['cl_a05_BTXE'][it,:,:,:]=cl_a05_btxe[:,:,:]
                wrfbdyf.variables['cl_a05_BYS'][it,:,:,:]=cl_a05_bys[:,:,:]
                wrfbdyf.variables['cl_a05_BTYS'][it,:,:,:]=cl_a05_btys[:,:,:]
                wrfbdyf.variables['cl_a05_BYE'][it,:,:,:]=cl_a05_bye[:,:,:]
                wrfbdyf.variables['cl_a05_BTYE'][it,:,:,:]=cl_a05_btye[:,:,:]
                wrfbdyf.variables['cl_a06_BXS'][it,:,:,:]=cl_a06_bxs[:,:,:]
                wrfbdyf.variables['cl_a06_BTXS'][it,:,:,:]=cl_a06_btxs[:,:,:]
                wrfbdyf.variables['cl_a06_BXE'][it,:,:,:]=cl_a06_bxe[:,:,:]
                wrfbdyf.variables['cl_a06_BTXE'][it,:,:,:]=cl_a06_btxe[:,:,:]
                wrfbdyf.variables['cl_a06_BYS'][it,:,:,:]=cl_a06_bys[:,:,:]
                wrfbdyf.variables['cl_a06_BTYS'][it,:,:,:]=cl_a06_btys[:,:,:]
                wrfbdyf.variables['cl_a06_BYE'][it,:,:,:]=cl_a06_bye[:,:,:]
                wrfbdyf.variables['cl_a06_BTYE'][it,:,:,:]=cl_a06_btye[:,:,:]
                wrfbdyf.variables['cl_a07_BXS'][it,:,:,:]=cl_a07_bxs[:,:,:]
                wrfbdyf.variables['cl_a07_BTXS'][it,:,:,:]=cl_a07_btxs[:,:,:]
                wrfbdyf.variables['cl_a07_BXE'][it,:,:,:]=cl_a07_bxe[:,:,:]
                wrfbdyf.variables['cl_a07_BTXE'][it,:,:,:]=cl_a07_btxe[:,:,:]
                wrfbdyf.variables['cl_a07_BYS'][it,:,:,:]=cl_a07_bys[:,:,:]
                wrfbdyf.variables['cl_a07_BTYS'][it,:,:,:]=cl_a07_btys[:,:,:]
                wrfbdyf.variables['cl_a07_BYE'][it,:,:,:]=cl_a07_bye[:,:,:]
                wrfbdyf.variables['cl_a07_BTYE'][it,:,:,:]=cl_a07_btye[:,:,:]
                wrfbdyf.variables['cl_a08_BXS'][it,:,:,:]=cl_a08_bxs[:,:,:]
                wrfbdyf.variables['cl_a08_BTXS'][it,:,:,:]=cl_a08_btxs[:,:,:]
                wrfbdyf.variables['cl_a08_BXE'][it,:,:,:]=cl_a08_bxe[:,:,:]
                wrfbdyf.variables['cl_a08_BTXE'][it,:,:,:]=cl_a08_btxe[:,:,:]
                wrfbdyf.variables['cl_a08_BYS'][it,:,:,:]=cl_a08_bys[:,:,:]
                wrfbdyf.variables['cl_a08_BTYS'][it,:,:,:]=cl_a08_btys[:,:,:]
                wrfbdyf.variables['cl_a08_BYE'][it,:,:,:]=cl_a08_bye[:,:,:]
                wrfbdyf.variables['cl_a08_BTYE'][it,:,:,:]=cl_a08_btye[:,:,:]
        if BC:
            wrfbdyf.variables['bc_a01_BXS'][it,:,:,:]=bc_a01_bxs[:,:,:]
            wrfbdyf.variables['bc_a01_BTXS'][it,:,:,:]=bc_a01_btxs[:,:,:]
            wrfbdyf.variables['bc_a01_BXE'][it,:,:,:]=bc_a01_bxe[:,:,:]
            wrfbdyf.variables['bc_a01_BTXE'][it,:,:,:]=bc_a01_btxe[:,:,:]
            wrfbdyf.variables['bc_a01_BYS'][it,:,:,:]=bc_a01_bys[:,:,:]
            wrfbdyf.variables['bc_a01_BTYS'][it,:,:,:]=bc_a01_btys[:,:,:]
            wrfbdyf.variables['bc_a01_BYE'][it,:,:,:]=bc_a01_bye[:,:,:]
            wrfbdyf.variables['bc_a01_BTYE'][it,:,:,:]=bc_a01_btye[:,:,:]
            wrfbdyf.variables['bc_a02_BXS'][it,:,:,:]=bc_a02_bxs[:,:,:]
            wrfbdyf.variables['bc_a02_BTXS'][it,:,:,:]=bc_a02_btxs[:,:,:]
            wrfbdyf.variables['bc_a02_BXE'][it,:,:,:]=bc_a02_bxe[:,:,:]
            wrfbdyf.variables['bc_a02_BTXE'][it,:,:,:]=bc_a02_btxe[:,:,:]
            wrfbdyf.variables['bc_a02_BYS'][it,:,:,:]=bc_a02_bys[:,:,:]
            wrfbdyf.variables['bc_a02_BTYS'][it,:,:,:]=bc_a02_btys[:,:,:]
            wrfbdyf.variables['bc_a02_BYE'][it,:,:,:]=bc_a02_bye[:,:,:]
            wrfbdyf.variables['bc_a02_BTYE'][it,:,:,:]=bc_a02_btye[:,:,:]
            wrfbdyf.variables['bc_a03_BXS'][it,:,:,:]=bc_a03_bxs[:,:,:]
            wrfbdyf.variables['bc_a03_BTXS'][it,:,:,:]=bc_a03_btxs[:,:,:]
            wrfbdyf.variables['bc_a03_BXE'][it,:,:,:]=bc_a03_bxe[:,:,:]
            wrfbdyf.variables['bc_a03_BTXE'][it,:,:,:]=bc_a03_btxe[:,:,:]
            wrfbdyf.variables['bc_a03_BYS'][it,:,:,:]=bc_a03_bys[:,:,:]
            wrfbdyf.variables['bc_a03_BTYS'][it,:,:,:]=bc_a03_btys[:,:,:]
            wrfbdyf.variables['bc_a03_BYE'][it,:,:,:]=bc_a03_bye[:,:,:]
            wrfbdyf.variables['bc_a03_BTYE'][it,:,:,:]=bc_a03_btye[:,:,:]
            wrfbdyf.variables['bc_a04_BXS'][it,:,:,:]=bc_a04_bxs[:,:,:]
            wrfbdyf.variables['bc_a04_BTXS'][it,:,:,:]=bc_a04_btxs[:,:,:]
            wrfbdyf.variables['bc_a04_BXE'][it,:,:,:]=bc_a04_bxe[:,:,:]
            wrfbdyf.variables['bc_a04_BTXE'][it,:,:,:]=bc_a04_btxe[:,:,:]
            wrfbdyf.variables['bc_a04_BYS'][it,:,:,:]=bc_a04_bys[:,:,:]
            wrfbdyf.variables['bc_a04_BTYS'][it,:,:,:]=bc_a04_btys[:,:,:]
            wrfbdyf.variables['bc_a04_BYE'][it,:,:,:]=bc_a04_bye[:,:,:]
            wrfbdyf.variables['bc_a04_BTYE'][it,:,:,:]=bc_a04_btye[:,:,:]
            if bins8:
                wrfbdyf.variables['bc_a05_BXS'][it,:,:,:]=bc_a05_bxs[:,:,:]
                wrfbdyf.variables['bc_a05_BTXS'][it,:,:,:]=bc_a05_btxs[:,:,:]
                wrfbdyf.variables['bc_a05_BXE'][it,:,:,:]=bc_a05_bxe[:,:,:]
                wrfbdyf.variables['bc_a05_BTXE'][it,:,:,:]=bc_a05_btxe[:,:,:]
                wrfbdyf.variables['bc_a05_BYS'][it,:,:,:]=bc_a05_bys[:,:,:]
                wrfbdyf.variables['bc_a05_BTYS'][it,:,:,:]=bc_a05_btys[:,:,:]
                wrfbdyf.variables['bc_a05_BYE'][it,:,:,:]=bc_a05_bye[:,:,:]
                wrfbdyf.variables['bc_a05_BTYE'][it,:,:,:]=bc_a05_btye[:,:,:]
                wrfbdyf.variables['bc_a06_BXS'][it,:,:,:]=bc_a06_bxs[:,:,:]
                wrfbdyf.variables['bc_a06_BTXS'][it,:,:,:]=bc_a06_btxs[:,:,:]
                wrfbdyf.variables['bc_a06_BXE'][it,:,:,:]=bc_a06_bxe[:,:,:]
                wrfbdyf.variables['bc_a06_BTXE'][it,:,:,:]=bc_a06_btxe[:,:,:]
                wrfbdyf.variables['bc_a06_BYS'][it,:,:,:]=bc_a06_bys[:,:,:]
                wrfbdyf.variables['bc_a06_BTYS'][it,:,:,:]=bc_a06_btys[:,:,:]
                wrfbdyf.variables['bc_a06_BYE'][it,:,:,:]=bc_a06_bye[:,:,:]
                wrfbdyf.variables['bc_a06_BTYE'][it,:,:,:]=bc_a06_btye[:,:,:]
                wrfbdyf.variables['bc_a07_BXS'][it,:,:,:]=bc_a07_bxs[:,:,:]
                wrfbdyf.variables['bc_a07_BTXS'][it,:,:,:]=bc_a07_btxs[:,:,:]
                wrfbdyf.variables['bc_a07_BXE'][it,:,:,:]=bc_a07_bxe[:,:,:]
                wrfbdyf.variables['bc_a07_BTXE'][it,:,:,:]=bc_a07_btxe[:,:,:]
                wrfbdyf.variables['bc_a07_BYS'][it,:,:,:]=bc_a07_bys[:,:,:]
                wrfbdyf.variables['bc_a07_BTYS'][it,:,:,:]=bc_a07_btys[:,:,:]
                wrfbdyf.variables['bc_a07_BYE'][it,:,:,:]=bc_a07_bye[:,:,:]
                wrfbdyf.variables['bc_a07_BTYE'][it,:,:,:]=bc_a07_btye[:,:,:]
                wrfbdyf.variables['bc_a08_BXS'][it,:,:,:]=bc_a08_bxs[:,:,:]
                wrfbdyf.variables['bc_a08_BTXS'][it,:,:,:]=bc_a08_btxs[:,:,:]
                wrfbdyf.variables['bc_a08_BXE'][it,:,:,:]=bc_a08_bxe[:,:,:]
                wrfbdyf.variables['bc_a08_BTXE'][it,:,:,:]=bc_a08_btxe[:,:,:]
                wrfbdyf.variables['bc_a08_BYS'][it,:,:,:]=bc_a08_bys[:,:,:]
                wrfbdyf.variables['bc_a08_BTYS'][it,:,:,:]=bc_a08_btys[:,:,:]
                wrfbdyf.variables['bc_a08_BYE'][it,:,:,:]=bc_a08_bye[:,:,:]
                wrfbdyf.variables['bc_a08_BTYE'][it,:,:,:]=bc_a08_btye[:,:,:]
        if OC:
            wrfbdyf.variables['oc_a01_BXS'][it,:,:,:]=oc_a01_bxs[:,:,:]
            wrfbdyf.variables['oc_a01_BTXS'][it,:,:,:]=oc_a01_btxs[:,:,:]
            wrfbdyf.variables['oc_a01_BXE'][it,:,:,:]=oc_a01_bxe[:,:,:]
            wrfbdyf.variables['oc_a01_BTXE'][it,:,:,:]=oc_a01_btxe[:,:,:]
            wrfbdyf.variables['oc_a01_BYS'][it,:,:,:]=oc_a01_bys[:,:,:]
            wrfbdyf.variables['oc_a01_BTYS'][it,:,:,:]=oc_a01_btys[:,:,:]
            wrfbdyf.variables['oc_a01_BYE'][it,:,:,:]=oc_a01_bye[:,:,:]
            wrfbdyf.variables['oc_a01_BTYE'][it,:,:,:]=oc_a01_btye[:,:,:]
            wrfbdyf.variables['oc_a02_BXS'][it,:,:,:]=oc_a02_bxs[:,:,:]
            wrfbdyf.variables['oc_a02_BTXS'][it,:,:,:]=oc_a02_btxs[:,:,:]
            wrfbdyf.variables['oc_a02_BXE'][it,:,:,:]=oc_a02_bxe[:,:,:]
            wrfbdyf.variables['oc_a02_BTXE'][it,:,:,:]=oc_a02_btxe[:,:,:]
            wrfbdyf.variables['oc_a02_BYS'][it,:,:,:]=oc_a02_bys[:,:,:]
            wrfbdyf.variables['oc_a02_BTYS'][it,:,:,:]=oc_a02_btys[:,:,:]
            wrfbdyf.variables['oc_a02_BYE'][it,:,:,:]=oc_a02_bye[:,:,:]
            wrfbdyf.variables['oc_a02_BTYE'][it,:,:,:]=oc_a02_btye[:,:,:]
            wrfbdyf.variables['oc_a03_BXS'][it,:,:,:]=oc_a03_bxs[:,:,:]
            wrfbdyf.variables['oc_a03_BTXS'][it,:,:,:]=oc_a03_btxs[:,:,:]
            wrfbdyf.variables['oc_a03_BXE'][it,:,:,:]=oc_a03_bxe[:,:,:]
            wrfbdyf.variables['oc_a03_BTXE'][it,:,:,:]=oc_a03_btxe[:,:,:]
            wrfbdyf.variables['oc_a03_BYS'][it,:,:,:]=oc_a03_bys[:,:,:]
            wrfbdyf.variables['oc_a03_BTYS'][it,:,:,:]=oc_a03_btys[:,:,:]
            wrfbdyf.variables['oc_a03_BYE'][it,:,:,:]=oc_a03_bye[:,:,:]
            wrfbdyf.variables['oc_a03_BTYE'][it,:,:,:]=oc_a03_btye[:,:,:]
            wrfbdyf.variables['oc_a04_BXS'][it,:,:,:]=oc_a04_bxs[:,:,:]
            wrfbdyf.variables['oc_a04_BTXS'][it,:,:,:]=oc_a04_btxs[:,:,:]
            wrfbdyf.variables['oc_a04_BXE'][it,:,:,:]=oc_a04_bxe[:,:,:]
            wrfbdyf.variables['oc_a04_BTXE'][it,:,:,:]=oc_a04_btxe[:,:,:]
            wrfbdyf.variables['oc_a04_BYS'][it,:,:,:]=oc_a04_bys[:,:,:]
            wrfbdyf.variables['oc_a04_BTYS'][it,:,:,:]=oc_a04_btys[:,:,:]
            wrfbdyf.variables['oc_a04_BYE'][it,:,:,:]=oc_a04_bye[:,:,:]
            wrfbdyf.variables['oc_a04_BTYE'][it,:,:,:]=oc_a04_btye[:,:,:]
            if bins8:
                wrfbdyf.variables['oc_a05_BXS'][it,:,:,:]=oc_a05_bxs[:,:,:]
                wrfbdyf.variables['oc_a05_BTXS'][it,:,:,:]=oc_a05_btxs[:,:,:]
                wrfbdyf.variables['oc_a05_BXE'][it,:,:,:]=oc_a05_bxe[:,:,:]
                wrfbdyf.variables['oc_a05_BTXE'][it,:,:,:]=oc_a05_btxe[:,:,:]
                wrfbdyf.variables['oc_a05_BYS'][it,:,:,:]=oc_a05_bys[:,:,:]
                wrfbdyf.variables['oc_a05_BTYS'][it,:,:,:]=oc_a05_btys[:,:,:]
                wrfbdyf.variables['oc_a05_BYE'][it,:,:,:]=oc_a05_bye[:,:,:]
                wrfbdyf.variables['oc_a05_BTYE'][it,:,:,:]=oc_a05_btye[:,:,:]
                wrfbdyf.variables['oc_a06_BXS'][it,:,:,:]=oc_a06_bxs[:,:,:]
                wrfbdyf.variables['oc_a06_BTXS'][it,:,:,:]=oc_a06_btxs[:,:,:]
                wrfbdyf.variables['oc_a06_BXE'][it,:,:,:]=oc_a06_bxe[:,:,:]
                wrfbdyf.variables['oc_a06_BTXE'][it,:,:,:]=oc_a06_btxe[:,:,:]
                wrfbdyf.variables['oc_a06_BYS'][it,:,:,:]=oc_a06_bys[:,:,:]
                wrfbdyf.variables['oc_a06_BTYS'][it,:,:,:]=oc_a06_btys[:,:,:]
                wrfbdyf.variables['oc_a06_BYE'][it,:,:,:]=oc_a06_bye[:,:,:]
                wrfbdyf.variables['oc_a06_BTYE'][it,:,:,:]=oc_a06_btye[:,:,:]
                wrfbdyf.variables['oc_a07_BXS'][it,:,:,:]=oc_a07_bxs[:,:,:]
                wrfbdyf.variables['oc_a07_BTXS'][it,:,:,:]=oc_a07_btxs[:,:,:]
                wrfbdyf.variables['oc_a07_BXE'][it,:,:,:]=oc_a07_bxe[:,:,:]
                wrfbdyf.variables['oc_a07_BTXE'][it,:,:,:]=oc_a07_btxe[:,:,:]
                wrfbdyf.variables['oc_a07_BYS'][it,:,:,:]=oc_a07_bys[:,:,:]
                wrfbdyf.variables['oc_a07_BTYS'][it,:,:,:]=oc_a07_btys[:,:,:]
                wrfbdyf.variables['oc_a07_BYE'][it,:,:,:]=oc_a07_bye[:,:,:]
                wrfbdyf.variables['oc_a07_BTYE'][it,:,:,:]=oc_a07_btye[:,:,:]
                wrfbdyf.variables['oc_a08_BXS'][it,:,:,:]=oc_a08_bxs[:,:,:]
                wrfbdyf.variables['oc_a08_BTXS'][it,:,:,:]=oc_a08_btxs[:,:,:]
                wrfbdyf.variables['oc_a08_BXE'][it,:,:,:]=oc_a08_bxe[:,:,:]
                wrfbdyf.variables['oc_a08_BTXE'][it,:,:,:]=oc_a08_btxe[:,:,:]
                wrfbdyf.variables['oc_a08_BYS'][it,:,:,:]=oc_a08_bys[:,:,:]
                wrfbdyf.variables['oc_a08_BTYS'][it,:,:,:]=oc_a08_btys[:,:,:]
                wrfbdyf.variables['oc_a08_BYE'][it,:,:,:]=oc_a08_bye[:,:,:]
                wrfbdyf.variables['oc_a08_BTYE'][it,:,:,:]=oc_a08_btye[:,:,:]
        if SO4:
            wrfbdyf.variables['so4_a01_BXS'][it,:,:,:]=so4_a01_bxs[:,:,:]
            wrfbdyf.variables['so4_a01_BTXS'][it,:,:,:]=so4_a01_btxs[:,:,:]
            wrfbdyf.variables['so4_a01_BXE'][it,:,:,:]=so4_a01_bxe[:,:,:]
            wrfbdyf.variables['so4_a01_BTXE'][it,:,:,:]=so4_a01_btxe[:,:,:]
            wrfbdyf.variables['so4_a01_BYS'][it,:,:,:]=so4_a01_bys[:,:,:]
            wrfbdyf.variables['so4_a01_BTYS'][it,:,:,:]=so4_a01_btys[:,:,:]
            wrfbdyf.variables['so4_a01_BYE'][it,:,:,:]=so4_a01_bye[:,:,:]
            wrfbdyf.variables['so4_a01_BTYE'][it,:,:,:]=so4_a01_btye[:,:,:]
            wrfbdyf.variables['so4_a02_BXS'][it,:,:,:]=so4_a02_bxs[:,:,:]
            wrfbdyf.variables['so4_a02_BTXS'][it,:,:,:]=so4_a02_btxs[:,:,:]
            wrfbdyf.variables['so4_a02_BXE'][it,:,:,:]=so4_a02_bxe[:,:,:]
            wrfbdyf.variables['so4_a02_BTXE'][it,:,:,:]=so4_a02_btxe[:,:,:]
            wrfbdyf.variables['so4_a02_BYS'][it,:,:,:]=so4_a02_bys[:,:,:]
            wrfbdyf.variables['so4_a02_BTYS'][it,:,:,:]=so4_a02_btys[:,:,:]
            wrfbdyf.variables['so4_a02_BYE'][it,:,:,:]=so4_a02_bye[:,:,:]
            wrfbdyf.variables['so4_a02_BTYE'][it,:,:,:]=so4_a02_btye[:,:,:]
            wrfbdyf.variables['so4_a03_BXS'][it,:,:,:]=so4_a03_bxs[:,:,:]
            wrfbdyf.variables['so4_a03_BTXS'][it,:,:,:]=so4_a03_btxs[:,:,:]
            wrfbdyf.variables['so4_a03_BXE'][it,:,:,:]=so4_a03_bxe[:,:,:]
            wrfbdyf.variables['so4_a03_BTXE'][it,:,:,:]=so4_a03_btxe[:,:,:]
            wrfbdyf.variables['so4_a03_BYS'][it,:,:,:]=so4_a03_bys[:,:,:]
            wrfbdyf.variables['so4_a03_BTYS'][it,:,:,:]=so4_a03_btys[:,:,:]
            wrfbdyf.variables['so4_a03_BYE'][it,:,:,:]=so4_a03_bye[:,:,:]
            wrfbdyf.variables['so4_a03_BTYE'][it,:,:,:]=so4_a03_btye[:,:,:]
            wrfbdyf.variables['so4_a04_BXS'][it,:,:,:]=so4_a04_bxs[:,:,:]
            wrfbdyf.variables['so4_a04_BTXS'][it,:,:,:]=so4_a04_btxs[:,:,:]
            wrfbdyf.variables['so4_a04_BXE'][it,:,:,:]=so4_a04_bxe[:,:,:]
            wrfbdyf.variables['so4_a04_BTXE'][it,:,:,:]=so4_a04_btxe[:,:,:]
            wrfbdyf.variables['so4_a04_BYS'][it,:,:,:]=so4_a04_bys[:,:,:]
            wrfbdyf.variables['so4_a04_BTYS'][it,:,:,:]=so4_a04_btys[:,:,:]
            wrfbdyf.variables['so4_a04_BYE'][it,:,:,:]=so4_a04_bye[:,:,:]
            wrfbdyf.variables['so4_a04_BTYE'][it,:,:,:]=so4_a04_btye[:,:,:]
            if bins8:
                wrfbdyf.variables['so4_a05_BXS'][it,:,:,:]=so4_a05_bxs[:,:,:]
                wrfbdyf.variables['so4_a05_BTXS'][it,:,:,:]=so4_a05_btxs[:,:,:]
                wrfbdyf.variables['so4_a05_BXE'][it,:,:,:]=so4_a05_bxe[:,:,:]
                wrfbdyf.variables['so4_a05_BTXE'][it,:,:,:]=so4_a05_btxe[:,:,:]
                wrfbdyf.variables['so4_a05_BYS'][it,:,:,:]=so4_a05_bys[:,:,:]
                wrfbdyf.variables['so4_a05_BTYS'][it,:,:,:]=so4_a05_btys[:,:,:]
                wrfbdyf.variables['so4_a05_BYE'][it,:,:,:]=so4_a05_bye[:,:,:]
                wrfbdyf.variables['so4_a05_BTYE'][it,:,:,:]=so4_a05_btye[:,:,:]
                wrfbdyf.variables['so4_a06_BXS'][it,:,:,:]=so4_a06_bxs[:,:,:]
                wrfbdyf.variables['so4_a06_BTXS'][it,:,:,:]=so4_a06_btxs[:,:,:]
                wrfbdyf.variables['so4_a06_BXE'][it,:,:,:]=so4_a06_bxe[:,:,:]
                wrfbdyf.variables['so4_a06_BTXE'][it,:,:,:]=so4_a06_btxe[:,:,:]
                wrfbdyf.variables['so4_a06_BYS'][it,:,:,:]=so4_a06_bys[:,:,:]
                wrfbdyf.variables['so4_a06_BTYS'][it,:,:,:]=so4_a06_btys[:,:,:]
                wrfbdyf.variables['so4_a06_BYE'][it,:,:,:]=so4_a06_bye[:,:,:]
                wrfbdyf.variables['so4_a06_BTYE'][it,:,:,:]=so4_a06_btye[:,:,:]
                wrfbdyf.variables['so4_a07_BXS'][it,:,:,:]=so4_a07_bxs[:,:,:]
                wrfbdyf.variables['so4_a07_BTXS'][it,:,:,:]=so4_a07_btxs[:,:,:]
                wrfbdyf.variables['so4_a07_BXE'][it,:,:,:]=so4_a07_bxe[:,:,:]
                wrfbdyf.variables['so4_a07_BTXE'][it,:,:,:]=so4_a07_btxe[:,:,:]
                wrfbdyf.variables['so4_a07_BYS'][it,:,:,:]=so4_a07_bys[:,:,:]
                wrfbdyf.variables['so4_a07_BTYS'][it,:,:,:]=so4_a07_btys[:,:,:]
                wrfbdyf.variables['so4_a07_BYE'][it,:,:,:]=so4_a07_bye[:,:,:]
                wrfbdyf.variables['so4_a07_BTYE'][it,:,:,:]=so4_a07_btye[:,:,:]
                wrfbdyf.variables['so4_a08_BXS'][it,:,:,:]=so4_a08_bxs[:,:,:]
                wrfbdyf.variables['so4_a08_BTXS'][it,:,:,:]=so4_a08_btxs[:,:,:]
                wrfbdyf.variables['so4_a08_BXE'][it,:,:,:]=so4_a08_bxe[:,:,:]
                wrfbdyf.variables['so4_a08_BTXE'][it,:,:,:]=so4_a08_btxe[:,:,:]
                wrfbdyf.variables['so4_a08_BYS'][it,:,:,:]=so4_a08_bys[:,:,:]
                wrfbdyf.variables['so4_a08_BTYS'][it,:,:,:]=so4_a08_btys[:,:,:]
                wrfbdyf.variables['so4_a08_BYE'][it,:,:,:]=so4_a08_bye[:,:,:]
                wrfbdyf.variables['so4_a08_BTYE'][it,:,:,:]=so4_a08_btye[:,:,:]
        print("finish replace bdy")
        os.system("date")
