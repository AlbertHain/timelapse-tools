#!/bin/bash
# AD 2017-05-19
# crossfade videos
#
fadeframes=15       # num of frames for fading
#quicker
#fadeframes=7
x=""
first=1
if [ $# -gt 0 ]; then
    while [ $# -gt 0 ]; do
        if [ $first -eq 1 ]; then
            x="$1"
            first=0
        else
            x="$x $1 -mix $fadeframes -mixer luma"
        fi
        shift
    done
    echo "$x"

    x="melt $x -consumer avformat:fade_$(date +%y-%m-%d_%H%M%S).avi vcodec=libx264 vb=8000K an=1" # ab=96k"         # an=1 disable audio
    eval $x
else
    echo "generates a crossfaded video out of several single videos (AD 2017-08-05), needs 'melt'"
    echo "syntax: videofade *.mp4"
fi
