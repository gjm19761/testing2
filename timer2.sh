#!/bin/bash

# Function to display a single digit
display_digit() {
    local n=$1
    case $n in
        0) echo "  █████  ";echo " ██   ██ ";echo "██     ██";echo "██     ██";echo "██     ██";echo " ██   ██ ";echo "  █████  ";;
        1) echo "   ██   ";echo " ███   ";echo "  ██   ";echo "  ██   ";echo "  ██   ";echo "  ██   ";echo "██████ ";;
        2) echo " ██████  ";echo "██    ██ ";echo "     ██  ";echo "   ██    ";echo " ██      ";echo "██       ";echo "████████ ";;
        3) echo " ██████  ";echo "██    ██ ";echo "      ██ ";echo "   ████  ";echo "      ██ ";echo "██    ██ ";echo " ██████  ";;
        4) echo "██   ██ ";echo "██   ██ ";echo "██   ██ ";echo "██████  ";echo "    ██  ";echo "    ██  ";echo "    ██  ";;
        5) echo "███████ ";echo "██      ";echo "██      ";echo "███████ ";echo "     ██ ";echo "██   ██ ";echo " █████  ";;
        6) echo " ██████  ";echo "██       ";echo "██       ";echo "███████  ";echo "██    ██ ";echo "██    ██ ";echo " ██████  ";;
        7) echo "███████ ";echo "     ██ ";echo "    ██  ";echo "   ██   ";echo "  ██    ";echo " ██     ";echo "██      ";;
        8) echo " ██████  ";echo "██    ██ ";echo "██    ██ ";echo " ██████  ";echo "██    ██ ";echo "██    ██ ";echo " ██████  ";;
        9) echo " ██████  ";echo "██    ██ ";echo "██    ██ ";echo " ███████ ";echo "      ██ ";echo "██    ██ ";echo " ██████  ";;
    esac
}

# Function to display the timer
display_timer() {
    local minutes=$1
    local seconds=$2
    local term_width=$(tput cols)
    local term_height=$(tput lines)

    clear

    # Calculate start position
    local start_row=$(( (term_height - 7) / 2 ))
    local start_col=$(( (term_width - 43) / 2 ))  # 43 = 4 digits * 9 width + 7 spaces (including colon)

    # Display timer
    for i in {0..6}; do
        tput cup $((start_row + i)) $start_col
        m1=$(display_digit $((minutes/10)) | sed -n "$((i+1))p")
        m2=$(display_digit $((minutes%10)) | sed -n "$((i+1))p")
        s1=$(display_digit $((seconds/10)) | sed -n "$((i+1))p")
        s2=$(display_digit $((seconds%10)) | sed -n "$((i+1))p")
        colon=""
        if [ $i -eq 2 ] || [ $i -eq 4 ]; then
            colon="███"
        else
            colon="   "
        fi
        echo -n "$m1 $m2 $colon $s1 $s2"
    done

    # Move cursor to bottom of screen
    tput cup $((term_height-1)) 0
}

# Function to display "Time's up!" in big letters
display_times_up() {
    local term_width=$(tput cols)
    local term_height=$(tput lines)
    local start_row=$(( (term_height - 6) / 2 ))
    local start_col=$(( (term_width - 62) / 2 ))

    clear
    tput cup $start_row $start_col
    echo "████████╗██╗███╗   ███╗███████╗███████╗    ██╗   ██╗██████╗ ██╗"
    tput cup $((start_row+1)) $start_col
    echo "╚══██╔══╝██║████╗ ████║██╔════╝██╔════╝    ██║   ██║██╔══██╗██║"
    tput cup $((start_row+2)) $start_col
    echo "   ██║   ██║██╔████╔██║█████╗  ███████╗    ██║   ██║██████╔╝██║"
    tput cup $((start_row+3)) $start_col
    echo "   ██║   ██║██║╚██╔╝██║██╔══╝  ╚════██║    ██║   ██║██╔═══╝ ╚═╝"
    tput cup $((start_row+4)) $start_col
    echo "   ██║   ██║██║ ╚═╝ ██║███████╗███████║    ╚██████╔╝██║     ██╗"
    tput cup $((start_row+5)) $start_col
    echo "   ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝     ╚═╝"

    # Move cursor to bottom of screen
    tput cup $((term_height-1)) 0
}

# Main script
echo "Enter the timer duration in seconds:"
read duration

total_seconds=$duration

while [ $total_seconds -ge 0 ]; do
    minutes=$((total_seconds / 60))
    seconds=$((total_seconds % 60))
    
    display_timer $minutes $seconds
    
    sleep 1
    ((total_seconds--))
done

display_times_up
sleep 5  # Display "Time's up!" for 5 seconds