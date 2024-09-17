#!/bin/bash

# Check if Nginx is installed
if ! command -v nginx &> /dev/null
then
    echo "Nginx is not installed. Please install Nginx first."
    exit 1
else
    echo "Nginx is installed. Proceeding with configuration."
fi

# Define variables
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
WEB_ROOT="/var/www/live_stream_chat"
CONFIG_NAME="live_stream_chat"

# Prompt user for domain name
read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME

# Prompt user for API credentials
read -p "Enter your Twitch Client ID: " TWITCH_CLIENT_ID
read -p "Enter your Twitch Client Secret: " TWITCH_CLIENT_SECRET
read -p "Enter your YouTube API Key: " YOUTUBE_API_KEY

# Create Nginx server block configuration
sudo tee $NGINX_AVAILABLE/$CONFIG_NAME <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    root $WEB_ROOT;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}
EOF

# Create web root directory
sudo mkdir -p $WEB_ROOT

# Install Composer
if ! command -v composer &> /dev/null
then
    echo "Installing Composer..."
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
fi

# Install dependencies
cd $WEB_ROOT
sudo composer require google/apiclient
sudo composer require nicklaw5/php-twitch-api

# Create PHP file
sudo tee $WEB_ROOT/index.php <<EOF
<?php
require_once __DIR__ . '/vendor/autoload.php';
use Google_Client;
use Google_Service_YouTube;
use TwitchApi\TwitchApi;

// Function to fetch Twitch chat messages
function getTwitchMessages(\$channel) {
    \$clientId = '$TWITCH_CLIENT_ID';
    \$clientSecret = '$TWITCH_CLIENT_SECRET';
    \$twitchApi = new TwitchApi([
        'client_id' => \$clientId,
        'client_secret' => \$clientSecret
    ]);

    // Get channel ID
    \$channelInfo = \$twitchApi->getUsers(['login' => \$channel]);
    \$channelId = \$channelInfo['data'][0]['id'];

    // Get recent chat messages
    \$messages = \$twitchApi->getChatMessages(\$channelId);
    
    return \$messages;
}

// Function to fetch YouTube chat messages
function getYouTubeMessages(\$videoId) {
    \$client = new Google_Client();
    \$client->setApplicationName("Live Stream Chat Combiner");
    \$client->setDeveloperKey("$YOUTUBE_API_KEY");

    \$youtube = new Google_Service_YouTube(\$client);

    \$liveChatId = \$youtube->videos->listVideos('liveStreamingDetails', ['id' => \$videoId])->items[0]->liveStreamingDetails->activeLiveChatId;

    \$messages = \$youtube->liveChatMessages->listLiveChatMessages(\$liveChatId, 'snippet');
    
    return \$messages->items;
}

// Combine messages from both platforms
function combineMessages(\$twitchChannel, \$youtubeVideoId) {
    \$twitchMessages = getTwitchMessages(\$twitchChannel);
    \$youtubeMessages = getYouTubeMessages(\$youtubeVideoId);
    
    \$combinedMessages = array_merge(\$twitchMessages, \$youtubeMessages);
    
    // Sort messages by timestamp
    usort(\$combinedMessages, function(\$a, \$b) {
        return \$a['timestamp'] <=> \$b['timestamp'];
    });
    
    return \$combinedMessages;
}

// Check if form is submitted
if (\$_SERVER["REQUEST_METHOD"] == "POST") {
    \$twitchChannel = \$_POST['twitch_channel'];
    \$youtubeVideoId = \$_POST['youtube_video_id'];
    
    \$combinedMessages = combineMessages(\$twitchChannel, \$youtubeVideoId);
    
    // Output as JSON for live updates
    header('Content-Type: application/json');
    echo json_encode(\$combinedMessages);
    exit;
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Live Stream Chat Combiner</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
    <h1>Live Stream Chat Combiner</h1>
    
    <form id="chatForm">
        <label for="twitch_channel">Twitch Channel:</label>
        <input type="text" id="twitch_channel" name="twitch_channel" required><br><br>
        
        <label for="youtube_video_id">YouTube Video ID:</label>
        <input type="text" id="youtube_video_id" name="youtube_video_id" required><br><br>
        
        <input type="submit" value="Start Combining Chats">
    </form>

    <div id="chatMessages"></div>

    <script>
    \$(document).ready(function() {
        \$('#chatForm').submit(function(e) {
            e.preventDefault();
            updateChat();
        });

        function updateChat() {
            \$.ajax({
                url: '',
                type: 'POST',
                data: \$('#chatForm').serialize(),
                success: function(response) {
                    \$('#chatMessages').empty();
                    \$.each(response, function(index, message) {
                        \$('#chatMessages').append('<p>' + message + '</p>');
                    });
                    // Update chat every 5 seconds
                    setTimeout(updateChat, 5000);
                }
            });
        }
    });
    </script>
</body>
</html>
EOF

# Set permissions
sudo chown -R www-data:www-data $WEB_ROOT
sudo chmod -R 755 $WEB_ROOT

# Enable the new site
sudo ln -s $NGINX_AVAILABLE/$CONFIG_NAME $NGINX_ENABLED/

# Test Nginx configuration
sudo nginx -t

# If the test is successful, reload Nginx
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "Nginx configuration has been updated and reloaded."
else
    echo "Nginx configuration test failed. Please check your configuration."
fi

echo "Setup complete. PHP file with API integration has been created. Please ensure you have the necessary PHP extensions installed for your application."
echo "Remember to set up proper error handling and respect API rate limits in a production environment."