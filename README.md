# timelapse-tools
bash-scripts for handling video- and imagefiles for timelapsing - GoPro-Users will deserve it

running on debian linux with ffmpeg, exiv, melt and mediainfo (thanks a lot)  
* video2img generates jpg-files out of videos with exif-stamps (DateTimeOriginal) according to video run time  
* timelapse generates a video out of jpeg images and enblends a dial bottom-right with the respective date and time, according to the exif-info of the image files  
* videoslices.sh cuts automatically slices out of a video  
* videofade.sh combines the slices by fading one in another  

## scenario 1
make timelapse video with speedup >> 10 and enblend a dial with real time and date info

1. video2img generates the images with exif-timestamp out the real videoinfo
2. delete the jpgs you don't want to show
3. let 'timelapse' generate the timelapsed video with the dial in lower right corner of the video

## scenario 2
speedup videoimpression of GoPro-vide

1. videoslices.sh cuts short scenes every n secondes
2. delete the slices you don't want to show
3. videofade.sh fades the scendes together
