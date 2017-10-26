#!/bin/bash
# create dial with moving big and little hands to mix in videofiles

function secure_filename (){
    filename=$1
    if [ -f "$filename" ]; then          # file exists, don't overwrite
        filetype=${filename##*.}
        datetime=$(date +'%Y%m%d%H%M%S')				# 20161223184533
        filename=${filename%.*}"_"$datetime"."$filetype
    fi
    echo "$filename"
}
####################################################
# Note: Encoded_Date is often marked as 'UTC'
# but some cameras (for examples GoPro, Nikon DSLR, Videocams) dont respect timezones - mobile phones usually do!
# So better check, if the timestamp is UTC or "cameratime"
################################################
timezone="TZ=CEST"             # recalculate real UTC to Central European Summer Time
timezone="TZ=CET"              # recalculate real UTC to Central European Time
# comment out, what's not needed
#ignoretimezone="no"            # mobile phones
ignoretimezone="yes"           # gopro, cameras

fontcolor="'#dddddd'"
dialbackground="'#888888'"            # this is the dialbackground of the grey background of the dial
bighandcolor="'#000000'"
littlehandcolor="'#000000'"
opacity="0.7"                       # opacity of the final dial
font="/usr/share/fonts/truetype/dejavu/DejaVuSansMono_Bold.ttf"

processdir="dial"
if [ ! -d $processdir ]; then
    mkdir $processdir
fi
prefix="clocked"
destinationtype="png";
dialplate=$processdir"/dialplate.png"
dialalpha=$processdir"/dialalpha.png"
hourplate=$processdir"/hourplate.png"
homiplate=$processdir"/homiplate.png"
bighand=$processdir"/bighand.png"
littlehand=$processdir"/littlehand.png"
hour_r=$processdir"/hour_r.png"
minute_r=$processdir"/minute_r.png"
dial=$processdir"/dial.png"
date=$processdir"/date.png"

if [ $# -gt 0 ]; then

    filepath=${1%/*};
    filename=${1##*/};
    if [ "$filepath" != "$filename" ]; then
        cd $filepath;
    fi
    while [ $# -gt 0 ]; do
        filename=${1##*/}
        sourcename=${filename%%.*}
        sourcetype=${filename##*.}
        lowersourcetype=${sourcetype,,}

        if [ -f "$filename" ]; then             # if exists
            if  [ $lowersourcetype == "mp4" ] ||
                [ $lowersourcetype == "mov" ] ||
                [ $lowersourcetype == "mts" ] ||
                [ $lowersourcetype == "avi" ] ||
                [ $lowersourcetype == "mpg" ]
            then
                datetime=$(mediainfo --Inform="Video;%Encoded_Date%" "$filename")  # starttime
                if [ "$datetime" == "UTC 1904-01-01 00:00:00" ] ||
                   [ "$datetime" == "" ]            # there's no Encoded_Date given,
                then                                # look for filename 2017-08-23 145110, no colons allowed in filenames
                    filedatetime=$(echo $filename | grep -Eo "([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}[0-9]{2}[0-9]{2})")
                    if [ "$filedatetime" != "" ]
                    then
                        datetime=$(echo "$filename" | cut -c 1-10)
                        datetime=$datetime" "$(echo "$filedatetime"|cut -c 12-13);
                        datetime=$datetime":"$(echo "$filedatetime"|cut -c 14-15);
                        datetime=$datetime":"$(echo "$filedatetime"|cut -c 16-17);
                        echo "no Encoded_Date given, using filename-date $datetime"
                    else
                        datetime=$(exiftool -b -FileModifyDate "$filename")
                        filedatetime=$(echo $datetime | grep -Eo "([0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})") # filter out 'Timezone-marker, usualy UTC
                        datetime=$(echo "$filedatetime" | cut -c 1-4)
                        datetime=$datetime"-"$(echo "$filedatetime"|cut -c 6-7);
                        datetime=$datetime"-"$(echo "$filedatetime"|cut -c 9-19);
                        echo "no info in filename, using filesystem date $datetime"
                    fi
                fi
                if [ $ignoretimezone == "yes" ]
                then
                    datetime=$(echo $datetime | grep -Eo "([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})") # filter out 'Timezone-marker, usualy UTC
                    timezone=""
                fi
                # request some info about the video
                framerate=$(mediainfo --Inform="Video;%FrameRate%" "$filename")    # average framerate per second
                framestotal=$(mediainfo --Inform="Video;%FrameCount%" "$filename")   # frames in video, same number of frames needed for dial
                duration=$(mediainfo --Inform="Video;%Duration%" "$filename")      # milliseconds
                imgheight=$(mediainfo --Inform="Video;%Height%" "$filename")          # height of video will determine size of dial
                frametime=`echo "scale=4; 1/$framerate" | bc`

                # initialize dimensions of dial, size, length of hands etc
                dialsize=`echo "scale=0; $imgheight/5" | bc`
                textsize=`echo "scale=0; $dialsize*0.7/1" | bc`   # text will be centered in the dial, with 70% of the diameter
                radius=`echo "scale=0; $dialsize/2" | bc`
                mhandlength=`echo "scale=0; $dialsize*0.45/1" | bc`
                hhandlength=`echo "scale=0; $dialsize*0.3/1" | bc`
                mhandwidth=`echo "scale=0; $dialsize/60" | bc`
                hhandwidth=`echo "scale=0; $dialsize/40" | bc`

                # draw the raw elements of the dial
                # black circle
#                s_dialplate="convert -size "$dialsize"x"$dialsize" xc:white -fill $dialbackground -stroke black "                        # white background
                s_dialplate="convert -size "$dialsize"x"$dialsize" xc:transparent -fill $dialbackground -stroke black "                   # transparent background
                s_dialplate+="-strokewidth "$mhandwidth" -draw 'circle "$radius","$radius" "$radius","$mhandwidth"' "$dialplate
                eval ${s_dialplate}

                # dial with alphachannel, probably not neccessary
                # s_dialalpha="convert -size "$dialsize"x"$dialsize" xc:transparent -fill '#444444' alpha set"
                s_dialalpha="convert -size "$dialsize"x"$dialsize" xc:transparent -fill $dialbackground"
                s_dialalpha+=" -draw 'circle "$radius","$radius" "$radius","$mhandwidth"' "$dialalpha
                eval ${s_dialalpha}
                # convert $dialalpha alpha on

                # bighand drawn at 6:00 clock, rectangle-coordinates lower left to upper right
                s_bighand="convert -size "$dialsize"x"$dialsize" xc:transparent -fill $bighandcolor -stroke black "
                s_bighand+="-draw 'roundrectangle "$[$radius-$hhandwidth]","$[$radius-$hhandlength]" "
                s_bighand+=$[$radius+$hhandwidth]","$[$radius+$hhandwidth]" $hhandwidth,$hhandwidth' "$bighand
                eval ${s_bighand}

                # littlehand drawn 6:00 clock, rectangle-coordinates lower left to upper right
                s_littlehand="convert -size "$dialsize"x"$dialsize" xc:transparent -fill $littlehandcolor -stroke black "
                s_littlehand+="-draw 'roundrectangle "$[$radius-$mhandwidth]","$[$radius-$mhandlength]" "
                s_littlehand+=$[$radius+$mhandwidth]","$[$radius+$mhandwidth]" $mhandwidth,$mhandwidth' "$littlehand
                eval ${s_littlehand}

                echo "generating clockvideo $dialsize"x"$dialsize pixels with $framestotal frames at "$framerate"fps ";
                echo "video starts at:"$datetime
                echo "now generating $framestotal images with dials"
                startsecs=$(eval "$timezone date -d '$datetime' +%s")
                oldtimesecs=0
                oldday=0
                for((i=0; i<$framestotal; i++))
                do
                    timesecs=`echo "scale=0; $startsecs+$i*$frametime/1" | bc`
                    if (( timesecs != oldtimesecs )); then             # just calculate frames which differ from each other
                        oldtimesecs=$timesecs

                        year=$(  date -d @$timesecs +%Y)
                        month=$( date -d @$timesecs +%m)
                        day=$(   date -d @$timesecs +%d)
                        hour=$(  date -d @$timesecs +%H)
                        minute=$(date -d @$timesecs +%M)
                        second=$(date -d @$timesecs +%S)
#                         echo $hour

                        # date changes are seldom needed, so we do not update this regularly
                        if [ $day -ne $oldday ]; then
                            oldday=$day
                            text=$day"."$month"."$year
                            stext="convert -background transparent -size $textsize""x""$textsize  -font $font -fill $fontcolor "
                            stext+=" -gravity center label:'\n\n$text' "
                            stext+=" $date "
                            eval ${stext}
                        fi
                        ############ create analogue time-hands ################
#                        hourangle=`echo "scale=2; (($hour+($minute/60))*360/12)/1" | bc`;
                        hourangle=`echo "scale=2; (($hour+($minute/60))*30)/1" | bc`;
                        minuteangle=`echo "scale=2; ($minute*6 + $second/10)/1" | bc`;
                        convert $bighand -distort SRT $hourangle $hour_r            # rotate hands in degrees around center
                        convert $littlehand -distort SRT $minuteangle $minute_r

                        composite -gravity center            $hour_r   $dialplate $hourplate      # add hour
                        composite -alpha set -gravity center $minute_r $hourplate $homiplate      # add minute
                        composite -alpha set -gravity center $date     $homiplate $dial     # add Date
                        echo -ne "generated "$processedname"\r"
                    fi
                    counterstring="$(printf "%06d" $i)";
                    processedname=$processdir"/"$prefix$counterstring"."$destinationtype
                    cp $dial "$processedname"                                   # existing frames with identical secs need just to be copied
                done
                echo

                dialvideo=$(secure_filename "$sourcename""_dial.mov")
                echo "ok, images completed, now generating dialvideo $dialvideo"

                ##### create the video out of the images
                verbosity="-v quiet -stats -hide_banner"     # quiet, just stats
#                verbosity=""

                ffmpeg $verbosity -framerate $framerate -i $processdir/$prefix%06d.png -codec:v copy "$dialvideo"       # video with alphachannel, don't forget the framerate!
                videoname=$(secure_filename "$sourcename""_withdial.mp4")
                echo "ok, dialvideo completed, now mixing $dialvideo over $filename as $videoname"

                quality="29"          # stanard is 23, 29 gives vids aprox. half the size
                filter_complex="[0:v]setpts=PTS-STARTPTS[video];[1:v]setpts=PTS-STARTPTS,colorchannelmixer=aa="$opacity"[dial];[video][dial]overlay=main_w-overlay_w-10:main_h-overlay_h-10:shortest=1"
                command_line=( ffmpeg -i "$filename" -i "$dialvideo" -filter_complex $filter_complex -vcodec libx264 -crf $quality $verbosity "$videoname" )
#                 echo "--------- for debugging --------------"
#                 echo "${command_line[@]}"
#                 echo "--------------------------------------"
                "${command_line[@]}"

                # you probably want to cleanup automatically
                echo "cleaning up tempfiles"
                rm $dialplate
                rm $hourplate
                rm $homiplate
                rm $dialalpha
                rm $bighand
                rm $littlehand
                rm $hour_r
                rm $minute_r
                rm $dial
                rm $date
                rm $processdir/$prefix*.png
                rm "$dialvideo"
            fi
        fi
        shift
    done
    rmdir $processdir
else
    echo "videodial4vids creates dial with moving big and little hands over existing videofiles"
    echo "at least one videofilename is needed as input"
fi
