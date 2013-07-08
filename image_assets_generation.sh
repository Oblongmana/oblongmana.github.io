#!/bin/bash
 
# Favicon and Apple Touch Icon Generator
#
# This bash script takes an image as a parameter, and uses ImageMagick to convert it to several
# other formats used on modern websites. The following copies are generated:
# 
# * apple-touch-icon-144x144-precomposed.png
# * apple-touch-icon-114x114-precomposed.png
# * apple-touch-icon-57x57-precomposed.png
# * apple-touch-icon-72x72-precomposed.png
# * apple-touch-icon-precomposed.png
# * apple-touch-icon.png
# * favicon.ico
#
# Concept from http://bergamini.org/computers/creating-favicon.ico-icon-files-with-imagemagick-convert.html
 
CONVERT_CMD=`which convert`
LOGO_SVG=$1
FAV_SVG=$2
PWD=`pwd`
 
if [ -z $CONVERT_CMD ] || [ ! -f $CONVERT_CMD ] || [ ! -x $CONVERT_CMD ];
then
    echo "ImageMagick needs to be installed to run this script"
    exit;
fi
 
if [ -z $FAV_SVG ];
then
    echo "You must supply a favicon image as the 2nd argument to this command."
    exit;
fi
 
if [ ! -f $FAV_SVG ];
then
    echo "Source image \"$FAV_SVG\" does not exist."
    exit;
fi

if [ -z $LOGO_SVG ];
then
    echo "You must supply a logo image as the 1st argument to this command."
    exit;
fi
 
if [ ! -f $LOGO_SVG ];
then
    echo "Source image \"$LOGO_SVG\" does not exist."
    exit;
fi
 
echo "Generating 400w site-logo"
$CONVERT_CMD $LOGO_SVG -resize 400x247! -background none $PWD/images/site-logo.png

echo "Generating square base image"
$CONVERT_CMD $FAV_SVG -resize 256x256! -transparent white $PWD/favicon-256.png
 
echo "Generating various sizes for ico"
$CONVERT_CMD $PWD/favicon-256.png -antialias -resize 16x16 $PWD/favicon-16.png
$CONVERT_CMD $PWD/favicon-256.png -antialias -resize 32x32 $PWD/favicon-32.png
$CONVERT_CMD $PWD/favicon-256.png -antialias -resize 64x64 $PWD/favicon-64.png
$CONVERT_CMD $PWD/favicon-256.png -antialias -resize 128x128 $PWD/favicon-128.png

echo "Generating png alternative"
cp $PWD/favicon-32.png $PWD/favicon.png

echo "Generating media items"
cp $PWD/favicon-64.png $PWD/twitter-default-img.png
 
echo "Generating ico"
#OLD OPTS that seem to mangle everything horribly :) -antialias -colors 256 -transparent white 
$CONVERT_CMD $PWD/favicon-16.png $PWD/favicon-32.png $PWD/favicon-64.png $PWD/favicon-128.png $PWD/favicon-256.png $PWD/favicon.ico
 
echo "Generating touch icons"
$CONVERT_CMD $PWD/favicon-256.png -antialias -resize 57x57 $PWD/images/apple-touch-icon.png
cp $PWD/images/apple-touch-icon.png $PWD/images/apple-touch-icon-precomposed.png
cp $PWD/images/apple-touch-icon.png $PWD/images/apple-touch-icon-57x57-precomposed.png
$CONVERT_CMD $PWD/favicon-256.png -antialias -resize 72x72 $PWD/images/apple-touch-icon-72x72-precomposed.png
$CONVERT_CMD $PWD/favicon-256.png -antialias -resize 114x114 $PWD/images/apple-touch-icon-114x114-precomposed.png
$CONVERT_CMD $PWD/favicon-256.png -antialias -resize 144x144 $PWD/images/apple-touch-icon-144x144-precomposed.png
 
echo "Removing temp files"
rm -rf $PWD/favicon-16.png
rm -rf $PWD/favicon-32.png
rm -rf $PWD/favicon-64.png
rm -rf $PWD/favicon-128.png
rm -rf $PWD/favicon-256.png