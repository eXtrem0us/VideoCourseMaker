#!/bin/bash

# This script prepares user uploaded videos for Faranesh

FirstVid=$(ls | grep -i '\.mp4$\|\.avi$\|\.mov$'|head -1)
LastVid=$(ls | grep -i '\.mp4$\|\.avi$\|\.mov$'|tail -1)
FilesCount=$(ls | grep -i '\.mp4$\|\.avi$\|\.mov$'|wc -l)
IntroVid="stuffs/intro720.mp4"
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
    VidWidth=$(mediainfo $FirstVid | grep Width | tr -d 'a-z,A-Z, '| cut -d: -f2)
    VidHeight=$(mediainfo $FirstVid | grep Height | tr -d 'a-z,A-Z, '| cut -d: -f2)
    ffmpeg -i $IntroVid -s $VidWidth\x$VidHeight $TempDir/intermediate0.mp4
    echo "___Joining Intro to $FirstVid___"
    ffmpeg -i $TempDir/intermediate0.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediate1.ts
    ffmpeg -i $FirstVid -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediate2.ts
    ffmpeg -i "concat:$TempDir/intermediate1.ts|$TempDir/intermediate2.ts" -c copy -bsf:a aac_adtstoasc $OutputDir/$FirstVid
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
    VidWidth=$(mediainfo $LastVid | grep Width | tr -d 'a-z,A-Z, '| cut -d: -f2)
    VidHeight=$(mediainfo $LastVid | grep Height | tr -d 'a-z,A-Z, '| cut -d: -f2)
    echo "___Joining $LastVid to Outro___"
    ffmpeg -i $LastVid -i $WatermarkFile -filter_complex 'overlay=x=0:y=(main_h-overlay_h)' $TempDir/intermediate3.mp4
    ffmpeg -i $TempDir/intermediate3.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediate3.ts
    ffmpeg -i "concat:$TempDir/intermediate3.ts|$TempDir/intermediate1.ts" -c copy -bsf:a aac_adtstoasc $OutputDir/$LastVid
}

CheckRequirements
Cleanup
IntroFirstVideo
WatermarkVideos
OutroLastVideo
Cleanup

# Written by Mehdi Hamidi ( @eXtrem0us )

