# timelapse-tools
bash-scripts for handling video- and imagefiles for timelapsing - GoPro-Users will deserve it

running on debian linux with ffmpeg, exiv and mediainfo (thanks a lot)

video2img generates jpg-files with exif-stamps (DateTimeOriginal) according to video run time

timelapse generates a video out of jpeg images and enblends a dial bottom-right with the respective date and time, according to the exif-info of the image files
