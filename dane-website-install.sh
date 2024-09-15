#!/bin/bash

# Get current user
CURRENT_USER=$(whoami)

# Function to create HTML file
create_html_file() {
    local file_name=$1
    local title=$2
    local content=$3

    cat > "/var/www/nipihlim-great-danes/$file_name" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - Nipihlim Great Danes</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
        }
        header {
            background-color: #333;
            color: #fff;
            text-align: center;
            padding: 1rem;
        }
        nav {
            background-color: #444;
            color: #fff;
            padding: 0.5rem;
        }
        nav ul {
            list-style-type: none;
            padding: 0;
            margin: 0;
            display: flex;
            justify-content: center;
        }
        nav ul li {
            margin: 0 10px;
        }
        nav ul li a {
            color: #fff;
            text-decoration: none;
        }
        main {
            padding: 2rem;
            max-width: 800px;
            margin: 0 auto;
            background-color: #fff;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <header>
        <h1>Nipihlim Great Danes</h1>
    </header>
    <nav>
        <ul>
            <li><a href="index.html">Home</a></li>
            <li><a href="about.html">About</a></li>
            <li><a href="gallery.html">Gallery</a></li>
            <li><a href="care.html">Care</a></li>
            <li><a href="contact.html">Contact</a></li>
        </ul>
    </nav>
    <main>
        $content
    </main>
</body>
</html>
EOL
}

# Create directory for the website with current user
sudo mkdir -p /var/www/nipihlim-great-danes
sudo chown $CURRENT_USER:$CURRENT_USER /var/www/nipihlim-great-danes

# Create index.html
create_html_file "index.html" "Home" "<h2>Welcome to Nipihlim Great Danes</h2>
<p>Discover the majestic world of Great Danes with Nipihlim. Our passion for these gentle giants drives us to provide the best information and resources for Great Dane enthusiasts.</p>"

# Create about.html
create_html_file "about.html" "About" "<h2>About Nipihlim Great Danes</h2>
<p>Nipihlim Great Danes is dedicated to promoting the well-being and appreciation of Great Danes. Learn about our mission and the history of this magnificent breed.</p>"

# Create gallery.html
create_html_file "gallery.html" "Gallery" "<h2>Great Dane Gallery</h2>
<p>Enjoy our collection of beautiful Great Dane photos. From puppies to adults, see the grace and charm of these gentle giants.</p>"

# Create care.html
create_html_file "care.html" "Care" "<h2>Caring for Your Great Dane</h2>
<p>Great Danes require special care and attention. Find tips on nutrition, exercise, health, and training to keep your Great Dane happy and healthy.</p>"

# Create contact.html
create_html_file "contact.html" "Contact" "<h2>Contact Us</h2>
<p>Have questions about Great Danes? Want to learn more about Nipihlim? Get in touch with us for more information.</p>"

# Set permissions
sudo chmod -R 755 /var/www/nipihlim-great-danes

# Create Nginx server block
sudo tee /etc/nginx/sites-available/nipihlim-great-danes << EOL
server {
    listen 80;
    listen [::]:80;

    root /var/www/nipihlim-great-danes;
    index index.html;

    server_name nipihlim-great-danes.com www.nipihlim-great-danes.com;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Enable the Nginx server block
sudo ln -s /etc/nginx/sites-available/nipihlim-great-danes /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

echo "Nipihlim Great Danes website has been set up!"
echo "Please ensure your domain (nipihlim-great-danes.com) is pointed to your server's IP address."
echo "You may also want to set up SSL/HTTPS for secure connections."
echo "The website files are owned by the current user: $CURRENT_USER"

