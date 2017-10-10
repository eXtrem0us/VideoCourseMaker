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

#Watermark All Videos

#Check the number of videos
#  =1 ?
    # Resize intro and outro to video size
    # Create Intermediate files
    # Join all videos together
# >=2 ?
    # Resize intro to first video
    # Resize outro to last video
    # Create Intermediate files
    # Join all videos together

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

function WatermarkVideos
{
	for videofile in $(ls | grep -i '\.mp4$\|\.avi$\|\.mov$')
	do
	    echo "___Watermarking $videofile___"
	    ffmpeg -i $videofile -i $WatermarkFile -filter_complex 'overlay=x=0:y=(main_h-overlay_h)' $TempDir/$videofile
	done
}

function ConvertSingle
{
	# In this case, FirstVid=LastVid=Single file. I choose $Firstvid.
	VidWidth=$(mediainfo $FirstVid | grep Width | tr -d 'a-z,A-Z, '| cut -d: -f2)
	VidHeight=$(mediainfo $FirstVid | grep Height | tr -d 'a-z,A-Z, '| cut -d: -f2)
	
	#Resizing Intro video to match First Video:
	ffmpeg -i $IntroVid -s $VidWidth\x$VidHeight $TempDir/intermediatex.mp4
	
	#Resizing Outro video to match First Video:
	ffmpeg -i $IntroVid -s $VidWidth\x$VidHeight $TempDir/intermediatey.mp4


	echo "___Joining Intro and $Firstvid and Outro___"
	
	##Creating Intermediate Videos
	#For Intro Video:
	ffmpeg -i $TempDir/intermediatex.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediatex.ts
	#For First Video:
	ffmpeg -i $TempDir/$FirstVid         -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediate1.ts
	#For Outro Video:
	ffmpeg -i $TempDir/intermediatey.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediatey.ts

	#Concatenating the intermediate Videos:
	ffmpeg -i "concat:$TempDir/intermediatex.ts|$TempDir/intermediate1.ts|$TempDir/intermediatey.ts" -c:v libx264 -bufsize -8M -c:a aac $OutputDir/$FirstVid
}

function ConvertCouple
{
	# In this case, we should concat Intro to FirstVid and LastVid to Outro
	#For FirstVid:
	VidWidth=$(mediainfo $FirstVid | grep Width | tr -d 'a-z,A-Z, '| cut -d: -f2)
	VidHeight=$(mediainfo $FirstVid | grep Height | tr -d 'a-z,A-Z, '| cut -d: -f2)
	##Resizing Intro video to match First Video:
	ffmpeg -i $IntroVid -s $VidWidth\x$VidHeight $TempDir/intermediatex.mp4

	echo "___Joining Intro and $FirstVid\___"

	##Creating the Intermediate Videos:
	###For Intro Video:
	ffmpeg -i $TempDir/intermediatex.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediatex.ts
	###For First Video:
	ffmpeg -i $TempDir/$FirstVid -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediate1.ts
	##Concatenating the intermediate Videos:
	ffmpeg -i "concat:$TempDir/intermediatex.ts|$TempDir/intermediate1.ts" -c:v libx264 -bufsize -8M -c:a aac $OutputDir/$FirstVid


	#For LastVid:
	VidWidth=$(mediainfo $LastVid | grep Width | tr -d 'a-z,A-Z, '| cut -d: -f2)
	VidHeight=$(mediainfo $LastVid | grep Height | tr -d 'a-z,A-Z, '| cut -d: -f2)
	##Resizing Outro video to match Last Video:
	ffmpeg -i $OutroVid -s $VidWidth\x$VidHeight $TempDir/intermediatey.mp4

	echo "___Joining $LastVid and Outro___"

	##Creating Intermediate Videos:
	###For Outro Video:
	ffmpeg -i $TempDir/intermediatey.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediatey.ts
	###For Last Video:
	ffmpeg -i $TempDir/$LastVid -c copy -bsf:v h264_mp4toannexb -f mpegts $TempDir/intermediate2.ts
	##Concatenating the intermediate Videos:
	ffmpeg -i "concat:$TempDir/intermediate2.ts|$TempDir/intermediatey.ts" -c:v libx264 -bufsize -8M -c:a aac $OutputDir/$LastVid
}

function HouseKeeping
{
	mv $OutputDir/*.mp4 $TempDir
	rm $TempDir/intermediate*.*
	mv $TempDir/*.mp4 $OutputDir
}

CheckRequirements
Cleanup
WatermarkVideos
[ $FilesCount -eq 1 ] && ConvertSingle && exit 0
[ $FilesCount -ge 2 ] && ConvertCouple && exit 0
HouseKeeping


# Written by Mehdi Hamidi ( @eXtrem0us )


