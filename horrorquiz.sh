#!/bin/bash

# ASCII art for horror movie theme
horror_ascii() {
    cat << "EOF"
    .     .       .  .   . .   .   . .    +  .
  .     .  :     .    .. :. .___---------___.
       .  .   .    .  :.:. _".^ .^ ^.  '.. :"-_. .
    .  :       .  .  .:../:            . .^  :.:\.
        .   . :: +. :.:/: .   .    .        . . .:\
 .  :    .     . _ :::/:               .  ^ .  . .:\
  .. . .   . - : :.:./.                        .  .:\
  .      .     . :..|:                    .  .  ^. .:|
    .       . : : ..||        .                . . !:|
  .     . . . ::. ::\(                           . :)/
 .   .     : . : .:.|. ######              .#######::|
  :.. .  :-  : .:  ::|.#######           ..########:|
 .  .  .  ..  .  .. :\ ########          :######## :/
  .        .+ :: : -.:\ ########       . ########.:/
    .  .+   . . . . :.:\. #######       #######..:/
      :: . . . . ::.:..:.\           .   .   ..:/
   .   .   .  .. :  -::::.\.       | |     . .:/
      .  :  .  .  .-:.":.::.\             ..:/
 .      -.   . . . .: .:::.:.\.           .:/
.   .   .  :      : ....::_:..:\   ___.  :/
   .   .  .   .:. .. .  .: :.:.:\       :/
     +   .   .   : . ::. :.:. .:.|\  .:/|
     .         +   .  .  ...:: ..|  --.:|
.      . . .   .  .  . ... :..:.."(  ..)"
 .   .       .      :  .   .: ::/  .  .::\
EOF
}

# Array of horror movie questions and answers
declare -a questions=(
    "What is the name of the killer in the 'Halloween' franchise?:Michael Myers:Jason Voorhees:Freddy Krueger:Leatherface"
    "Which horror movie features a group of friends who encounter a family of cannibals in Texas?:The Texas Chain Saw Massacre:Wrong Turn:The Hills Have Eyes:Hostel"
    "In 'The Exorcist', what is the name of the possessed girl?:Regan MacNeil:Carrie White:Samara Morgan:Annabelle"
    "Who directed the 1960 psychological horror film 'Psycho'?:Alfred Hitchcock:Stanley Kubrick:Wes Craven:John Carpenter"
    "What is the name of the cursed videotape in 'The Ring'?:There is no specific name:The Death Tape:Seven Days:Samara's Revenge"
    "Which horror film features a group of researchers in Antarctica who encounter a shape-shifting alien?:The Thing:Alien:The Blob:Predator"
    "In 'A Nightmare on Elm Street', what is the name of the dream-stalking killer?:Freddy Krueger:Jason Voorhees:Michael Myers:Pinhead"
    "What is the name of the demon in 'The Exorcist'?:Pazuzu:Beelzebub:Asmodeus:Baphomet"
    "Which horror movie features a family terrorized by a group of strangers wearing animal masks?:The Strangers:You're Next:Hush:The Purge"
    "In 'The Silence of the Lambs', what is the nickname of the serial killer Buffalo Bill?:Jame Gumb:Norman Bates:Jack Torrance:Patrick Bateman"
    "What is the name of the summer camp in 'Friday the 13th'?:Camp Crystal Lake:Camp Arawak:Camp Blackfoot:Camp Redwood"
    "Which horror film features a group of people trying to survive in a world where making noise attracts deadly creatures?:A Quiet Place:Bird Box:The Silence:Don't Breathe"
    "In 'The Shining', what is the name of the haunted hotel?:The Overlook Hotel:The Stanley Hotel:The Bates Motel:The Dolphin Hotel"
    "What is the name of the demon-possessed doll in the 'Conjuring' universe?:Annabelle:Chucky:Brahms:Billy"
    "Which horror movie features a babysitter being terrorized by a stranger on Halloween night?:Halloween:When a Stranger Calls:Scream:Black Christmas"
    "In 'It', what form does Pennywise usually take?:A clown:A spider:A werewolf:A vampire"
    "What is the name of the fictional town where 'Stranger Things' is set?:Hawkins:Derry:Castle Rock:Haddonfield"
    "Which horror film features a family moving into a house where a mass murder took place?:The Amityville Horror:Poltergeist:Sinister:Insidious"
    "In 'The Blair Witch Project', how many student filmmakers go into the Black Hills Forest?:Three:Two:Four:Five"
    "What is the name of the serial killer in 'Scream' who wears a ghost face mask?:Ghostface (the identity changes):Billy Loomis:Stu Macher:Roman Bridger"
)

# Function to shuffle the questions array
shuffle_array() {
    local i j temp
    for ((i = ${#questions[@]} - 1; i > 0; i--)); do
        j=$((RANDOM % (i + 1)))
        temp="${questions[i]}"
        questions[i]="${questions[j]}"
        questions[j]="$temp"
    done
}

# Shuffle the questions
shuffle_array

# Initialize score
score=0

# Display ASCII art
clear
horror_ascii
echo "Welcome to the Horror Movie Quiz!"
echo "Press Enter to start..."
read

# Main quiz loop
for ((i = 0; i < 20; i++)); do
    clear
    horror_ascii
    IFS=':' read -r question correct_answer wrong1 wrong2 wrong3 <<< "${questions[i]}"
    
    # Create an array of all answers and shuffle them
    answers=("$correct_answer" "$wrong1" "$wrong2" "$wrong3")
    shuffle_array answers

    # Display question and answers
    echo "Question $((i+1))/20: $question"
    echo
    for ((j = 0; j < 4; j++)); do
        echo "$((j+1)). ${answers[j]}"
    done
    echo

    # Get user's answer
    read -p "Enter your answer (1-4): " user_answer

    # Check if the answer is correct
    if [[ "${answers[$((user_answer-1))]}" == "$correct_answer" ]]; then
        echo "Correct!"
        ((score++))
    else
        echo "Incorrect. The correct answer was: $correct_answer"
    fi
    echo
    echo "Press Enter to continue..."
    read
done

# Calculate and display the final score
clear
horror_ascii
percentage=$((score * 100 / 20))
echo "Quiz completed!"
echo "Your score: $score out of 20"
echo "Percentage: $percentage%"

# Provide feedback based on the score
if ((percentage >= 90)); then
    echo "Excellent! You're a horror movie master!"
elif ((percentage >= 70)); then
    echo "Great job! You really know your horror films!"
elif ((percentage >= 50)); then
    echo "Not bad! You have a good grasp of horror movies."
else
    echo "Looks like you might need to watch more horror movies!"
fi

# Display scary Halloween ASCII art
cat << "EOF"

                     .-.
     .-""`""-.    |(@ @)
  _/`oOoOoOoOo`\_ \ \-/
 '.-=-=-=-=-=-=-.' \/ \
   `-=.=-.-=.=-'    \ /\
      ^  ^  ^       _H_ \

EOF

echo "Happy Halloween! Thanks for playing!"


