#!/bin/bash

# Function to display a single digit
display_digit() {
    local n=$1
    case $n in
        0) echo " ███ ";echo "█   █";echo "█   █";echo "█   █";echo " ███ ";;
        1) echo "  █  ";echo " ██  ";echo "  █  ";echo "  █  ";echo " ███ ";;
        2) echo " ███ ";echo "    █";echo " ███ ";echo "█    ";echo " ███ ";;
        3) echo " ███ ";echo "    █";echo " ███ ";echo "    █";echo " ███ ";;
        4) echo "█   █";echo "█   █";echo " ████";echo "    █";echo "    █";;
        5) echo " ███ ";echo "█    ";echo " ███ ";echo "    █";echo " ███ ";;
        6) echo " ███ ";echo "█    ";echo " ███ ";echo "█   █";echo " ███ ";;
        7) echo " ███ ";echo "    █";echo "   █ ";echo "  █  ";echo " █   ";;
        8) echo " ███ ";echo "█   █";echo " ███ ";echo "█   █";echo " ███ ";;
        9) echo " ███ ";echo "█   █";echo " ███ ";echo "    █";echo " ███ ";;
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
    local start_row=$(( (term_height - 5) / 2 ))
    local start_col=$(( (term_width - 29) / 2 ))  # 29 = 4 digits * 6 width + 5 spaces

    # Display timer
    for i in {0..4}; do
        tput cup $((start_row + i)) $start_col
        m1=$(display_digit $((minutes/10)) | sed -n "$((i+1))p")
        m2=$(display_digit $((minutes%10)) | sed -n "$((i+1))p")
        s1=$(display_digit $((seconds/10)) | sed -n "$((i+1))p")
        s2=$(display_digit $((seconds%10)) | sed -n "$((i+1))p")
        echo -n "$m1 $m2  $s1 $s2"
    done

    # Display colon
    tput cup $((start_row + 1)) $((start_col + 11))
    echo "*"
    tput cup $((start_row + 3)) $((start_col + 11))
    echo "*"

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

echo "Time's up!"