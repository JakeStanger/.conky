#!/usr/bin/env bash

# while true; do
#     read -rsn1 input
#     echo "$input"
#     if [ "$input" = "a" ]; then
#         echo "hello world"
#     fi
# done

# Constants
move_file=/tmp/conky/platformer/move
x_file=/tmp/conky/platformer/x
y_file=/tmp/conky/platformer/y

screen_width=2560
screen_height=1440

# Setup
mkdir -p /tmp/conky/platformer

if [ ! -f $x_file ]; then
    echo 0 > $x_file
fi

if [ ! -f $y_file ]; then
    echo 0 > $y_file
fi

# Keypress listener
while true
do
    dir=""
    read -r -sn1 -t 0.05 t
    case $t in
        A) dir="up" ;;
        B) dir="down" ;;
        C) dir="right" ;;
        D) dir="left" ;;
    esac
    
    echo $dir > $move_file
    
    if [ "$dir" = "right" ]; then
        old_pos="$(cat $x_file)"
        if [ $old_pos != $screen_width ]; then
            echo $(( $old_pos+5 )) > $x_file
        fi
    fi
    
    if [ "$dir" = "left" ]; then
        old_pos="$(cat $x_file)"
        if [ $old_pos != 0 ]; then
            echo $(( $old_pos-5 )) > $x_file
        fi
    fi
    
    if [ "$dir" = "up" ]; then
        old_pos="$(cat $y_file)"
        if [ $old_pos != $screen_height ]; then
            echo $(( $old_pos-5 )) > $y_file
        fi
    fi
    
    if [ "$dir" = "down" ]; then
        old_pos="$(cat $y_file)"
        if [ $old_pos != 0 ]; then
            echo $(( $old_pos+5 )) > $y_file
        fi
    fi
done