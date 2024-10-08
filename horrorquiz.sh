#!/bin/bash

# Function to install jq
install_jq() {
    echo "jq is required for this script to run. Attempting to install jq..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            echo "Unable to install jq automatically. Please install it manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install jq
        else
            echo "Homebrew is not installed. Please install Homebrew and then run: brew install jq"
            exit 1
        fi
    else
        echo "Unsupported operating system. Please install jq manually."
        exit 1
    fi
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed."
    read -p "Do you want to attempt to install jq? (y/n): " install_choice
    if [[ $install_choice == "y" || $install_choice == "Y" ]]; then
        install_jq
    else
        echo "jq is required for this script. Please install it manually."
        echo "On Ubuntu or Debian, you can install it with: sudo apt-get install jq"
        echo "On macOS with Homebrew, use: brew install jq"
        echo "For other systems, visit: https://stedolan.github.io/jq/download/"
        exit 1
    fi
fi

# Check again if jq is installed (in case installation failed)
if ! command -v jq &> /dev/null; then
    echo "jq installation failed or was not completed. Please install jq manually and run the script again."
    exit 1
fi

echo "jq is installed. Continuing with the quiz..."

# Array of scary ASCII art
declare -a scary_ascii=(
'
    .     .       .  .   . .   .   . .    +  .
  .     .  :     .    .. :. .___---------___.
       .  .   .    .  :.:. _".^ .^ ^.  '\''. :"-_. .
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
      .  :  .  .  .-:.":.:.:\             ..:/
 .      -.   . . . .: .:::.:.\.           .:/
.   .   .  :      : ....::_:..:\   ___.  :/
   .   .  .   .:. .. .  .: :.:.:\       :/
     +   .   .   : . ::. :.:. .:.|\  .:/|
     .         +   .  .  ...:: ..|  --.:|
.      . . .   .  .  . ... :..:..\(  ..)\
 .   .       .      :  .   .: ::/  .  .::\
'
'
                     .-.
     .-"""""-    |(@ @)
  _/`oOoOoOoOo`\_ \ \-/
 '\''.-=-=-=-=-=-=-.'\'' \/ \
   `-=.=-.-=.=-'\''    \ /\
      ^  ^  ^       _H_ \
'
'
      _____
     /     \
    /__|o|__\
       |||
       |||
       |||
       |||
       |||
       |||
       |||
   ___|||___
  /   |||   \
 /    |||    \
|     |||     |
 \   (|||)   /
  \_________/
'
'
     /\
    /  \
   /    \
  /      \
 /  REST  \
/    IN    \
\  PEACE  /
 \      /
  \    /
   \  /
    \/
'
)

# Array of horror movie questions and answers
declare -a questions=(
    "What is the name of the killer in the 'Halloween' franchise?|Michael Myers|Jason Voorhees|Freddy Krueger|Leatherface"
    "Which horror movie features a group of friends who encounter a family of cannibals in Texas?|The Texas Chain Saw Massacre|Wrong Turn|The Hills Have Eyes|Hostel"
    "In 'The Exorcist', what is the name of the possessed girl?|Regan MacNeil|Carrie White|Samara Morgan|Annabelle"
    "Who directed the 1960 psychological horror film 'Psycho'?|Alfred Hitchcock|Stanley Kubrick|Wes Craven|John Carpenter"
    "What is the name of the cursed videotape in 'The Ring'?|There is no specific name|The Death Tape|Seven Days|Samara's Revenge"
    "Which horror film features a group of researchers in Antarctica who encounter a shape-shifting alien?|The Thing|Alien|The Blob|Predator"
    "In 'A Nightmare on Elm Street', what is the name of the dream-stalking killer?|Freddy Krueger|Jason Voorhees|Michael Myers|Pinhead"
    "What is the name of the demon in 'The Exorcist'?|Pazuzu|Beelzebub|Asmodeus|Baphomet"
    "Which horror movie features a family terrorized by a group of strangers wearing animal masks?|The Strangers|You're Next|Hush|The Purge"
    "In 'The Silence of the Lambs', what is the nickname of the serial killer Buffalo Bill?|Jame Gumb|Norman Bates|Jack Torrance|Patrick Bateman"
    "What is the name of the summer camp in 'Friday the 13th'?|Camp Crystal Lake|Camp Arawak|Camp Blackfoot|Camp Redwood"
    "Which horror film features a group of people trying to survive in a world where making noise attracts deadly creatures?|A Quiet Place|Bird Box|The Silence|Don't Breathe"
    "In 'The Shining', what is the name of the haunted hotel?|The Overlook Hotel|The Stanley Hotel|The Bates Motel|The Dolphin Hotel"
    "What is the name of the demon-possessed doll in the 'Conjuring' universe?|Annabelle|Chucky|Brahms|Billy"
    "Which horror movie features a babysitter being terrorized by a stranger on Halloween night?|Halloween|When a Stranger Calls|Scream|Black Christmas"
    "In 'It', what form does Pennywise usually take?|A clown|A spider|A werewolf|A vampire"
    "What is the name of the fictional town where 'Stranger Things' is set?|Hawkins|Derry|Castle Rock|Haddonfield"
    "Which horror film features a family moving into a house where a mass murder took place?|The Amityville Horror|Poltergeist|Sinister|Insidious"
    "In 'The Blair Witch Project', how many student filmmakers go into the Black Hills Forest?|Three|Two|Four|Five"
    "What is the name of the serial killer in 'Scream' who wears a ghost face mask?|Ghostface (the identity changes)|Billy Loomis|Stu Macher|Roman Bridger"
    "Which horror movie features a group of friends who unknowingly summon a demon while playing a game?|Ouija|Truth or Dare|The Craft|Witchboard"
    "In 'The Conjuring', what is the name of the paranormal investigating couple?|Ed and Lorraine Warren|Ryan and Shane Madej|Ed and Elaine Parker|John and Mary Winchester"
    "What is the name of the fictional Maine town where many Stephen King stories are set?|Castle Rock|Derry|Haven|Bangor"
    "Which horror film features a family trapped in their home during a night of government-sanctioned crime?|The Purge|You're Next|Don't Breathe|Hush"
    "In 'Saw', what is the name of the main antagonist who sets up deadly traps?|Jigsaw|The Collector|Ghostface|Hannibal Lecter"
    "What is the name of the summer camp in 'Sleepaway Camp'?|Camp Arawak|Camp Crystal Lake|Camp Blackfoot|Camp Redwood"
    "Which horror movie features a group of cave explorers who encounter humanoid creatures?|The Descent|As Above, So Below|The Cave|Sanctum"
    "In 'Hellraiser', what is the name of the lead Cenobite?|Pinhead|Chatterer|Butterball|Female Cenobite"
    "What is the name of the haunted ship in 'Ghost Ship'?|Antonia Graza|Mary Celeste|Flying Dutchman|Queen Mary"
    "Which horror film features a cursed videotape that kills viewers seven days after watching it?|The Ring|Sinister|V/H/S|Videodrome"
    "In 'Candyman', how many times must you say his name in front of a mirror to summon him?|Five|Three|Seven|Once"
    "What is the name of the fictional New England university in H.P. Lovecraft's stories?|Miskatonic University|Arkham University|Innsmouth College|Dunwich Institute"
    "Which horror movie features a group of friends who encounter evil forces while staying at a remote cabin?|The Evil Dead|Cabin Fever|The Cabin in the Woods|Wrong Turn"
    "In 'Alien', what is the name of the ship where the crew encounters the Xenomorph?|Nostromo|Sulaco|Prometheus|Covenant"
    "What is the name of the creepy doll in the 'Child's Play' franchise?|Chucky|Annabelle|Billy|Robert"
    "What is the name of the fictional town in 'Silent Hill'?|Silent Hill|Raccoon City|Haddonfield|Woodsboro"
    "In 'The Babadook', what is the name of the pop-up book that introduces the monster?|Mister Babadook|The Boogeyman|The Shadow Man|Nightmares Come Alive"
    "Which horror film features a group of friends who encounter a murderous backwoods family while on a road trip?|The Hills Have Eyes|Wrong Turn|Deliverance|The Texas Chain Saw Massacre"
    "What is the name of the demon nun in 'The Conjuring' universe?|Valak|Bathsheba|Annabelle|Mary"
    "In 'Get Out', what is the name of the procedure used to transplant consciousness?|The Coagula Procedure|The Sunken Place|The Armitage Method|The Host Initiative"
    "Which horror movie features a group of college students who discover a cabin in the woods is actually a front for a ritual sacrifice?|The Cabin in the Woods|Evil Dead|Tucker & Dale vs. Evil|Until Dawn"
    "What is the name of the island where 'Jurassic Park' is located?|Isla Nublar|Isla Sorna|Skull Island|Shutter Island"
    "In 'The Sixth Sense', what is the famous line spoken by Cole Sear?|I see dead people|They're here|It's alive|We all float down here"
    "Which horror film features a family terrorized by their doppelgängers?|Us|Get Out|The Strangers|Funny Games"
    "What is the name of the cursed object in 'Oculus'?|The Lasser Glass|The Dybbuk Box|The Monkey's Paw|The Necronomicon"
    "In 'Hereditary', what is the name of the demon king being worshipped?|Paimon|Asmodeus|Baal|Mammon"
    "Which horror movie features a group of people trapped in a grocery store surrounded by a mysterious mist?|The Mist|The Fog|The Happening|30 Days of Night"
    "What is the name of the fictional serial killer in 'American Psycho'?|Patrick Bateman|Norman Bates|Hannibal Lecter|Dexter Morgan"
    "In 'The Others', what year do the events of the film take place?|1945|1920|1963|1899"
    "Which horror film features a group of friends who unleash a zombie outbreak while vacationing at a cabin?|The Evil Dead|Cabin Fever|Night of the Demons|Dead Snow"
    "What is the name of the demon in 'Insidious'?|Lipstick-Face Demon|The Man Who Can't Breathe|The Bride in Black|The Red-Faced Demon"
    "In 'The Witch', what is the name of the family's goat?|Black Phillip|Baphomet|Lucifer|Damien"
    "Which horror movie features a couple who discover their new house was the site of a brutal murder?|Sinister|Amityville Horror|The Conjuring|Poltergeist"
    "What is the name of the fictional town where 'It' takes place?|Derry|Castle Rock|Haddonfield|Woodsboro"
    "In 'Paranormal Activity', what is the name of the demon haunting Katie?|Toby|Pazuzu|Asmodeus|Zozo"
)

# Function to convert number to ASCII art
number_to_ascii() {
    local num=$1
    local -a ascii_numbers=(
        ' ___  \n/ _ \ \n\/ \/ \n\___/ ' # 0
        '  _   \n / |  \n | |  \n |_|  ' # 1
        ' ___  \n|_  ) \n / /  \n/___| ' # 2
        ' ___  \n|__ \ \n|__) |\n\___/ ' # 3
        ' _ _  \n| | | \n|_  _|\n  |_| ' # 4
        ' ___  \n| __| \n|__ \ \n|___/ ' # 5
        '  __  \n / /  \n/ _ \ \n\___/ ' # 6
        ' ____ \n|__  |\n  / / \n /_/  ' # 7
        ' ___  \n( _ ) \n/ _ \ \n\___/ ' # 8
        ' ___  \n/ _ \ \n\_, / \n /_/  ' # 9
    )
    echo -e "${ascii_numbers[$num]}"
}

# Function to display "20" in ASCII art
display_20() {
    echo " ___   ___  "
    echo "|_  ) / _ \ "
    echo " / / / // / "
    echo "/___| \___/ "
}

# Function to create scary percentage ASCII art
scary_percentage() {
    local percent=$1
    echo "   _____   "
    echo "  /     \  "
    echo " | () () | "
    echo "  \  ^  /  "
    echo "   |||||   "
    echo "   |||||   "
    echo "  -------  "
    printf " /       \\ \n"
    printf "|   %3d%%  |\n" "$percent"
    printf " \\_______/ \n"
}

# Function to shuffle an array
shuffle_array() {
    local -n arr=$1
    local i j temp
    for ((i = ${#arr[@]} - 1; i > 0; i--)); do
        j=$((RANDOM % (i + 1)))
        temp="${arr[i]}"
        arr[i]="${arr[j]}"
        arr[j]="$temp"
    done
}

# Shuffle and select 20 questions
shuffle_array questions
selected_questions=("${questions[@]:0:20}")

# Initialize score
score=0

# Display welcome message
clear
echo "Welcome to the Horror Movie Quiz!"
echo "You'll be asked 20 questions out of a possible 55."
echo "Press Enter to start..."
read

# Main quiz loop
for ((i = 0; i < 20; i++)); do
    clear
    # Display random scary ASCII art
    echo "${scary_ascii[$((RANDOM % ${#scary_ascii[@]}))]}"
    
    IFS='|' read -r question correct_answer wrong1 wrong2 wrong3 <<< "${selected_questions[i]}"
    
    # Create an array of all answers
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
    while true; do
        read -p "Enter your answer (1-4): " user_answer
        if [[ "$user_answer" =~ ^[1-4]$ ]]; then
            break
        else
            echo "Invalid input. Please enter a number between 1 and 4."
        fi
    done

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
percentage=$((score * 100 / 20))
echo "Quiz completed!"
echo "Your score:"
if ((score < 10)); then
    number_to_ascii 0
fi
number_to_ascii $((score / 10))
number_to_ascii $((score % 10))
echo
echo "of"
echo
display_20
echo
scary_percentage $percentage

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

# Ask user if they want to upload their score
read -p "Do you want to upload your score? (y/n): " upload_score
if [[ $upload_score == "y" || $upload_score == "Y" ]]; then
    read -p "Enter your name: " user_name
    # URL encode the user's name
    encoded_name=$(printf '%s' "$user_name" | jq -sRr @uri)
    current_date=$(date +"%Y-%m-%d")
    
    # Upload score to a simple PHP script
    upload_url="http://halloween2024.techlogicals.uk/upload_score.php?name=$encoded_name&score=$score&date=$current_date"
    if curl -s "$upload_url" | grep -q "Success"; then
        echo "Score uploaded successfully!"
        echo "View high scores at: http://halloween2024.techlogicals.uk/highscores.php"
    else
        echo "Failed to upload score. Please try again later."
    fi
fi

echo "Happy Halloween! Thanks for playing the 2024 Tech Logicals Halloween Quiz!"