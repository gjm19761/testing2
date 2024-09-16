#!/bin/bash

# Function to display the ASCII art numbers horizontally
display_number() {
    local n=$1
    local lines=()
    case $n in
        0) lines=("  ████████  " "██        ██" "██        ██" "██        ██" "██        ██" "██        ██" "  ████████  ");;
        1) lines=("     ██     " "   ████     " "     ██     " "     ██     " "     ██     " "     ██     " "   ██████   ");;
        2) lines=(" ██████████ " "         ██ " "         ██ " " ██████████ " "██          " "██          " " ██████████ ");;
        3) lines=(" ██████████ " "         ██ " "         ██ " "   ██████   " "         ██ " "         ██ " " ██████████ ");;
        4) lines=("██      ██  " "██      ██  " "██      ██  " " ██████████ " "        ██  " "        ██  " "        ██  ");;
        5) lines=(" ██████████ " "██          " "██          " " ██████████ " "         ██ " "         ██ " " ██████████ ");;
        6) lines=(" ██████████ " "██          " "██          " " ██████████ " "██        ██" "██        ██" " ██████████ ");;
        7) lines=(" ██████████ " "         ██ " "        ██  " "       ██   " "      ██    " "     ██     " "    ██      ");;
        8) lines=(" ██████████ " "██        ██" "██        ██" " ██████████ " "██        ██" "██        ██" " ██████████ ");;
        9) lines=(" ██████████ " "██        ██" "██        ██" " ██████████ " "         ██ " "         ██ " " ██████████ ");;
    esac
    echo "${lines[@]}"
}

# Function to display the timer horizontally
display_timer() {
    local minutes=$1
    local seconds=$2
    local term_width=$(tput cols)
    local term_height=$(tput lines)

    clear

    local timer_width=68  # 4 numbers * 13 width + 4 spaces + 12 for colon
    local start_col=$(( (term_width - timer_width) / 2 ))
    local start_row=$(( (term_height - 7) / 2 ))

    # Move cursor to the starting position
    tput cup $start_row 0

    # Display the timer
    for i in {0..6}; do
        printf "%${start_col}s" ""  # Padding
        IFS=' ' read -ra num1 <<< "$(display_number $((minutes/10)))"
        IFS=' ' read -ra num2 <<< "$(display_number $((minutes%10)))"
        IFS=' ' read -ra num3 <<< "$(display_number $((seconds/10)))"
        IFS=' ' read -ra num4 <<< "$(display_number $((seconds%10)))"
        
        echo -n "${num1[$i]} ${num2[$i]} "
        
        if [ $i -eq 2 ] || [ $i -eq 4 ]; then
            echo -n "██ "
        else
            echo -n "   "
        fi
        
        echo "${num3[$i]} ${num4[$i]}"
    done

    # Move cursor to the bottom of the screen
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