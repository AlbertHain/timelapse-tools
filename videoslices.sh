#!/bin/bash
# AD 2018-11-07
# copy slices out of a given video and pastes them together
#
slicelength=2000       # length of videoslice in milliseconds
slicegap=30000          # gap between videoslices in milliseconds
#quicker
# slicelength=/1       # length of videoslice in seconds
# slicegap=30          # gap between videoslices in seconds

profile="-preset medium"            # ultrafast,superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo
metadata="-map_metadata 0"
vcodec="-vcodec libx264"
crf="-crf 23"
format="-vf format=yuvj420p"
acodec="-acodec aac -ab 96k"
faststart="-movflags +faststart"
loglevel="-loglevel error"       # quiet, panic, fatal, error, warning, info, verbose, debug
slicedir="slices"
if [ ! -d $slicedir ]; then
	mkdir $slicedir
fi

############################
# gets "$inputfile" duration and returns total number of seconds: secondstotal
############################
getduration () {
    fileinfo=$(mktemp)                      # use tempfile for fileinfo
	ffmpeg -i "$inputfile" 2> $fileinfo        # ffmpeg without parameters throws the videocharacteristics, esp. duration
	info=`cat $fileinfo | grep -Eo "Duration: ([0-9]{2}:[0-9]{2}:[0-9]{2})"`  # Duration in hh:mm:ss format
	rm $fileinfo
    time=${info##*Duration: }
#	seconds=`echo ${time##*:} | bc`
	seconds=${time##*:}
    time=${time%:*}
    minutes=${time##*:}
    time=${time%:*}
    hours=${time##*:}
    secondstotal=`echo "(($hours*60 + $minutes)*60 + $seconds )" | bc`
    millisecondstotal=`echo "1000*(($hours*60 + $minutes)*60 + $seconds )" | bc`
}
############################
# gets "$inputfile" creation date and time of video and returns string with date and time: creationtime
############################
getcreation () {
    fileinfo=$(mktemp)                      # use tempfile for fileinfo
    ffprobe -show_format "$inputfile" > $fileinfo
	creation=`cat $fileinfo | grep "creation_time"`
    creationtime=${creation##*=}
    creationtime=${creationtime%%.*}
	rm $fileinfo
}
############################
# makes at string-timestamp out of a number of seconds
############################
makestamp() {
#    printf '%02d:%02d:%02d' $(($1%86400/3600)) $(($1%3600/60)) $(($1%60))
   millis=`echo "scale=0; (($1*1000/1.0))" | bc`
   millis=$1
#     millis= printf %5d $(echo "$1*1000" | bc -l)
    printf '%02d:%02d:%02d.%03d' $(($millis%86400000/3600000)) $(($millis%3600000/60000)) $(($millis%60000/1000)) $(($millis%1000))
}

while [ $# -gt 0 ]      # loop through commandline patterns
do
    inputfile=$1        # we just need one argument
    getduration
    getcreation
    # creationmetadata="-metadata creation_time=\"$creationtime\""
    creationmetadata="-metadata creation_time=$creationtime"    # needed for target-video of slices

    filetrunc=${inputfile%%.*}                                  # use filename for result
    filetype=${inputfile##*.}                                   # use filetype for result
    filetrunc_nws=`echo $filetrunc | sed 's/\s/_/g'`            # ensure no whitespaces "safe" characters in filename

    position=0
    slicenumber=0
    slicelengthstamp=`makestamp $slicelength`
    echo "slicelengthstamp".$slicelengthstamp."\n"

    segments=segments.txt                                       # segments=$(mktemp) does not work because of security issues of ffmpeg

    while [ $position -lt $(( $millisecondstotal-$slicelength )) ]; do
        slicenummerstring=`printf '%03d' $slicenumber`
        positionstamp=`makestamp $position`
        echo "start:" $positionstamp " length:" $slicelengthstamp " filename:" $filetrunc_nws"_"$slicenummerstring"."$filetype
        ffmpeg -ss $positionstamp -i "$inputfile" -t $slicelengthstamp  $format $profile $vcodec $acodec $loglevel "$filetrunc_nws""_"$slicenummerstring"."$filetype
        echo "file "$filetrunc_nws"_"$slicenummerstring"."$filetype >> $segments
        position=$(( $position + $slicegap))
        slicenumber=$(($slicenumber + 1));
    done
    # ffmpeg -f concat -i $segments -c copy $filetrunc_nws"_"$slicelength"s_after_"$slicegap"s."$filetype
    # ffmpeg -f concat -i $segments $acodec $crf $format $faststart $creationmetadata $loglevel $filetrunc_nws"_"$slicelength"s_after_"$slicegap"s."$filetype

    rm $segments
    position=0
    slicenumber=0
    ######################
    # cleanup slices - if desired
    ######################
    while [ $position -lt $millisecondstotal ]; do
        slicenummerstring=`printf '%03d' $slicenumber`
    #     rm $filetrunc_nws"_"$slicenummerstring"."$filetype
        mv $filetrunc_nws"_"$slicenummerstring"."$filetype $slicedir
        position=$(( $position + $slicegap))
        slicenumber=$(($slicenumber + 1))
    done
    shift
done
