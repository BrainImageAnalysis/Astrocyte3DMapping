#!/bin/bash

MOVING=$1
FIX=$2
OUT=$3

ANTSREG=antsRegistration


echo "#############################"
echo Moving image is $MOVING
echo Fix image is $FIX
echo Output image is $OUT
echo "#############################"


ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=30 $ANTSREG -d 3 -v 1 --float 1 --winsorize-image-intensities [0.005,0.995] --write-composite-transform 1 \
 --initial-moving-transform [${FIX},${MOVING},1] \
 -o [${OUT}] \
  --transform affine[ 0.05 ] -m Mattes[${FIX},${MOVING},1,32,Random,0.125] -c [250, 1.e-8, 20] -s 2vox -f 4 \
 --transform affine[ 0.05 ] -m Mattes[${FIX},${MOVING},1,32,Random,0.0125] -c [200, 1.e-8, 20] -s 1vox -f 2 \
 --transform affine[ 0.05 ] -m Mattes[${FIX},${MOVING},1,32,Random,0.063] -c [50, 1.e-8, 20] -s 1vox -f 1 \
 --transform SyN[ 0.05,3,0 ] -m Mattes[${FIX},${MOVING},1,32,Random,0.125] -c [1000x500x100x50, 1.e-10, 20] -s 4x2x1x1vox -f 8x4x2x1


 
