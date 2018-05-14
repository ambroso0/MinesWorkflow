#!/bin/bash 
tar -zxvf concessions.tar.gz
vect="concessions"
rast="Hansen_GFC2015_treecover2000_00N_020E"

# Get extent
meta=`gdalinfo $Hansen_GFC2015_treecover2000_00N_020E.tif | grep 'Lower Left' | sed 's/Lower Left  (//g' |  sed 's/) (/,/g'`
w=`echo ${meta}| awk -F ',' '{print $1}'`
s=`echo ${meta}| awk -F ',' '{print $2}'`
meta=`gdalinfo $Hansen_GFC2015_treecover2000_00N_020E.tif | grep 'Upper Right' | sed 's/Upper Right (//g' |  sed 's/) (/,/g'`
e=`echo ${meta}| awk -F ',' '{print $1}'`
n=`echo ${meta}| awk -F ',' '{print $2}'` 

# Get resolution (necessary to use the -tap option to guarantee proper overlay with rast)
meta=`gdalinfo $Hansen_GFC2015_treecover2000_00N_020E.tif | grep 'Pixel Size' | sed 's/Pixel Size = //g' | sed 's/(//g' | sed 's/)//g' | sed 's/ - /, /g'`
rez=`echo ${meta}| awk -F ',' '{print $1}'`

# Rasterize vect as 1 overlaying perfectly rast using information just collected
gdal_rasterize -te $w $s $e $n -tr $rez $rez -tap -burn 1 -init 0 -co COMPRESS=LZW $concessions.shp $concessions.tif

# Mask rast with rasterized vect
# You could use this oppotunity to convert the pixel size into surface
gdal_calc.py -A $Hansen_GFC2015_treecover2000_00N_020E.tif -B $concessions.tif --co COMPRESS=LZW --outfile=masked_$Hansen_GFC2015_treecover2000_00N_020E.tif --calc="A*B"

# Calculate sum by multiplying mean values by the number of pixels and print the result
# in a .txt file
# (this is the reason why I used -init 0 (all pixels are used to compute mean)
# and no -a_nodata 0 (only data picels are used)
stat=`gdalinfo -stats masked_$Hansen_GFC2015_treecover2000_00N_020E.tif | grep 'Size is ' | sed 's/Size is //g' |  sed 's/) (/,/g'`
xpx=`echo ${stat}| awk -F ',' '{print $1}'`
ypx=`echo ${stat}| awk -F ',' '{print $2}'`
cellmean=`gdalinfo -stats masked_$Hansen_GFC2015_treecover2000_00N_020E.tif | grep 'STATISTICS_MEAN=' | sed 's/STATISTICS_MEAN=//g' |  sed 's/) (/,/g'`

#echo "$cellmean*$xpx*$ypx" >> rast_sum.txt
