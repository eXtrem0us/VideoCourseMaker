#!/bin/bash

# This script prepares user uploaded videos for Faranesh

FirstVid=$(ls | grep -i '\.mp4$\|\.avi$\|\.mov$'|head -1)
LastVid=$(ls | grep -i '\.mp4$\|\.avi$\|\.mov$'|tail -1)
FilesCount=$(ls | grep -i '\.mp4$\|\.avi$\|\.mov$'|wc -l)
IntroVid="stuffs/intro.mp4"
OutroVid="stuffs/intro.mp4"
WatermarkFile="stuffs/watermark.png"
OutputDir="output"
TempDir="tmp"

function CheckRequirements
{
    [ -z $(command -v ffmpeg) ] && echo "Please install ffmpeg" && exit 1
    [ -z $(command -v mediainfo) ] && echo "Please install mediainfo" && exit 1
}

function Cleanup
{
    rm -rf $TempDir $OutputDir
    mkdir $TempDir $OutputDir
}


function IntroFirstVideo
{
    echo "___Creating Intermediate Files___"
	
	#Determining First Video Resolution:
    VidWidth=$(mediainfo $FirstVid | grep Width | tr -d 'a-z,A-Z, '| cut -d: -f2)
    VidHeight=$(mediainfo $FirstVid | grep Height | tr -d 'a-z,A-Z, '| cut -d: -f2)
	
	#Resizing Intro video to match First Video:
    ffmpeg -i $IntroVid -s $VidWidth\x$VidHeight $TempDir/intermediatex.mp4
    
	echo "___Joining Intro to $FirstVid___"
    #Warermark First Video:
    ffmpeg -i $FirstVid -i $WatermarkFile -filter_complex 'overlay=x=0:y=(main_h-overlay_h)' $TempDir/intermediate1.mp4
    
	##Creating Intermediate Videos
	#For Intro Video:
	ffmpeg -i $TempDir/intermediatex.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediatex.ts
	#For First Video:
    ffmpeg -i $TempDir/intermediate1.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediate1.ts

	#Concatenating the intermediate Videos:
    ffmpeg -i "concat:$TempDir/intermediatex.ts|$TempDir/intermediate1.ts" -c:v libx264 -bufsize -8M -c:a aac $OutputDir/$FirstVid
}

function WatermarkVideos
{
    for videofile in $(ls | grep -i '\.mp4$\|\.avi$\|\.mov$'|sed -n 2,$(($FilesCount-1))p)
    do
	echo "___Watermarking $videofile___"
	ffmpeg -i $videofile -i $WatermarkFile -filter_complex 'overlay=x=0:y=(main_h-overlay_h)' $OutputDir/$videofile
    done
}

function OutroLastVideo
{
    echo "___Creating Intermediate Files___"

	#Determining Last Video Resolution:
    VidWidth=$(mediainfo $LastVid | grep Width | tr -d 'a-z,A-Z, '| cut -d: -f2)
    VidHeight=$(mediainfo $LastVid | grep Height | tr -d 'a-z,A-Z, '| cut -d: -f2)

	#Resizing Outro video to match Last Video:
    ffmpeg -i $OutroVid -s $VidWidth\x$VidHeight $TempDir/intermediatey.mp4

    echo "___Joining $LastVid to Outro___"

	#Warermark Last Video:
    ffmpeg -i $LastVid -i $WatermarkFile -filter_complex 'overlay=x=0:y=(main_h-overlay_h)' $TempDir/intermediate2.mp4

	##Creating Intermediate Videos
	#For Outro Video:
    ffmpeg -i $TempDir/intermediatey.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediatey.ts
	#For Last Video:
	ffmpeg -i $TempDir/intermediate2.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediate2.ts
	#Concatenating the intermediate Videos:
    ffmpeg -i "concat:$TempDir/intermediate2.ts|$TempDir/intermediatey.ts" -c:v libx264 -bufsize -8M -c:a aac $OutputDir/$LastVid
}

CheckRequirements
Cleanup
#IntroFirstVideo
WatermarkVideos
#OutroLastVideo

# Written by Mehdi Hamidi ( @eXtrem0us )

