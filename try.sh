#!/bin/bash
tar -zxvf concessions.tar.gz

VECT="concessions_agregees_2015_one.shp"
RAST="Hansen_GFC2015_treecover2000_00N_020E.tif"
OUT="concessions.tif"

# Get extent
meta=`gdalinfo $RAST | grep 'Lower Left' | sed 's/Lower Left  (//g' |  sed 's/) (/,/g'`

w=`echo ${meta}| awk -F ',' '{print $1}'`
s=`echo ${meta}| awk -F ',' '{print $2}'`

meta=`gdalinfo $RAST | grep 'Upper Right' | sed 's/Upper Right (//g' | sed 's/) (/,/g'`

e=`echo ${meta}| awk -F ',' '{print $1}'`
n=`echo ${meta}| awk -F ',' '{print $2}'`

# Get resolution (necessary to use the -tap option to guarantee proper overlay with RAST)

meta=`gdalinfo $RAST | grep 'Pixel Size' | sed 's/Pixel Size = //g' | sed 's/(//g' | sed 's/)//g' | sed 's/ - /, /g'`
rez=`echo ${meta}| awk -F ',' '{print $1}'`

# RASTerize VECT as 1 overlaying perfectly RAST using information just collected
gdal_rasterize -te $w $s $e $n -tr $rez $rez -tap -burn 1 -init 0 -co COMPRESS=LZW $VECT $OUT

gdal_calc.py -A $RAST -B $OUT --co COMPRESS=LZW --outfile=masked_$RAST --calc="A*B"

stat=`gdalinfo -stats masked_$RAST | grep 'Size is ' | sed 's/Size is //g' |  sed 's/) (/,/g'`
xpx=`echo ${stat}| awk -F ',' '{print $1}'`
ypx=`echo ${stat}| awk -F ',' '{print $2}'`

cellmean=`gdalinfo -stats masked_$RAST | grep 'STATISTICS_MEAN=' | sed 's/STATISTICS_MEAN=//g' |  sed 's/) (/,/g'`
echo "$cellmean*$xpx*$ypx" >> rast_sum.txt
