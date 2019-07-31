# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.


# rsync with progress
function copy_(){
    rsync -azh --no-i-r --info=progress2 $1 $2
}

# view frames for ROS
function frames(){
    rosrun tf view_frames && evince frames.pdf && rm frames.pdf
}


# ls after cd
function cd() {
    new_directory="$*";
    if [ $# -eq 0 ]; then 
        new_directory=${HOME};
    fi;
    builtin cd "${new_directory}" && ls
    result=${PWD}
}

# bookmark folders and go to them
function go() { eval dir=\$$1; cd "$dir";}
function bm() { eval $1=$(pwd); echo "`set | egrep ^[a-z]+=\/`" > ~/.bookmarks; }
test -f ~/.bookmarks && source ~/.bookmarks 

# combined find + grep
function fgr() {
    NAM=""
    GREPTYPE="-i -H"
    if  [ -n "$1" ]; then
        test -n "$2" && NAM="-name \"$2\""
        test -n "$3" && GREPTYPE=$3
        CMMD="find . $NAM -not -path '*/\.*' -exec egrep --colour=auto $GREPTYPE \"$1\" {} + 2>/dev/null"
        >$2 echo -e "Running: $CMMD\n"
        sh -c "$CMMD"
        echo ""
    else
        echo -e "Expected: fgr <search> [file filter] [grep opt]\n"
    fi
}

# create a python file with shebang
function crpy() {
    if [ $# -eq 0 ]
      then
        echo "No arguments supplied"
        exit
    fi
    touch $1
    echo "#!/usr/bin/env python" >> $1
    chmod +x $1
}

function killnav(){
    killgazebo
    rosnode kill /amcl
    rosnode kill /move_base
    rosnode kill /map_server
    rosnode kill /joint_state_publisher
    rosnode kill /robot_state_publisher
    rosnode kill /controllers/base_spawner
    rosnode kill /controllers/joint_state_pub_spawner
    rosnode kill /gazebo
    rosnode kill /gazebo_gui
    echo "Done"
}
# make dir and cd to it
mcd() { mkdir -p "$1"; cd "$1";}

# cd aliases
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias cd..='cd..'

# git aliases
alias gm="git commit -m"
alias gall="git add ."
alias gs="git status"

#kill gazebo
alias killgazebo="killall -9 gazebo & killall -9 gzserver & killall -9 gzclient"

# Go up a number of directories
# Use: up <number of directories to move>
function up(){
    local d=""
    limit=$1
    for ((i=1 ; i <=limit ; i++))
        do 
            d=$d/..
        done
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd $d
}


# convert video to mp4 (no sanity checks)
# Use to_mp4 <input> 
function to_mp4(){
    ffmpeg -i $1 $2.mp4
}

# stacks 2-4 videos (need to have the same dimensions)
# 2 or three videos will be stacked horizontally
# 4 videos will be stacked in 2x2 configuration
# Use: video_stack 
function video_stack(){ 
    if [ $# -eq 3 ]; then
        ffmpeg -i $1 -i $2 -filter_complex hstack=inputs=$(($#-1)) $3.mp4
        return
    fi
    if [ $# -eq 4 ]; then
        ffmpeg -i $1 -i $2 -i $3 -filter_complex hstack=inputs=$(($#-1)) $3.mp4
        return
    fi
    if [ $# -eq 5 ]; then
        ffmpeg -i $1 -i $2 -i $3 -i $4 -filter_complex \
        "[0:v][1:v]hstack[top]; \
         [2:v][3:v]hstack[bottom]; \
         [top][bottom]vstack" $5.mp4
    fi
    echo "Invalid number of arguments, currently only supports 2,3,4 videos"
}

# Rescale video to desired dimensions
# Use: video_rescale <input> <width> <height> <output>
function video_rescale(){
    if [ $# -eq 4 ]; then
        ffmpeg -i $1 -vf scale=$2:$3 $4
        return
    fi
    echo "Invalid number of arguments"
    echo "Use:  video_rescale <input> <width> <height> <output>"
}

# Decimal to binary conversion
function dec_to_bin(){
    n="$1"
    bit=""
    while [ "$n" -gt 0 ]; do
        bit="$(( n&1 ))$bit";
        : $((n >>=1  ))
    done
    printf "%s\n" "$bit"
}

# Binary to decimal conversion
function bin_to_dec(){
    echo "$((2#$1))"
}

# Hexadecimal to decimal conversion
function hex_to_dec(){
    echo "$((16#$1))"
}

# script to test wether rostests have succedded or failed
function check_rostests(){
    DEBUG=1
    res=0
    if [ "$#" -eq 1 ]; then
        DEBUG=0
    fi
    if [ "$DEBUG" -eq 1 ]; then
        echo "------------ rostests -----------------"
    fi
    res=$(find $1 -name 'rostest-*' | while read line; do
        # echo "Parsing '$line'"
        if grep -Fq "0 errors, 0 failures" "$line"; then
            if [ "$DEBUG" -eq 1 ]; then
                echo "'$line' passed all tests"
            fi
        else
            if [ "$DEBUG" -eq 1 ]; then
                echo "'$line' has failed"
            else
                echo -1
                return
            fi
            
        fi
    done)
    
    if [ "$DEBUG" -ne 1 ]; then
        if [ "$res" -ne 0 ]; then
            echo $res
            return
        fi
    else
        echo "$res"
    fi
    if [ "$DEBUG" -eq 1 ]; then
        echo "------------- rosunit -----------------"
    fi
    res=$(find $1 -name 'rosunit-*' | while read line; do
        # echo "Parsing '$line'"
        if grep -Fq "errors=\"0\" failures=\"0\"" "$line"; then
            if [ "$DEBUG" -eq 1 ]; then
                echo "'$line' passed all tests"
            fi
        else
            # echo "'$line' has failed"
            if [ "$DEBUG" -eq 1 ]; then
                echo "'$line' has failed"
            else
                echo -2
                return 
            fi
        fi
    done)
    if [ "$DEBUG" -ne 1 ]; then
        if [ "$res" -ne 0 ]; then
            echo $res
            return
        fi
    else
        echo "$res"
    fi
}
