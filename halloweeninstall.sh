#!/bin/bash

# Check if Nginx is installed
if ! command -v nginx &> /dev/null
then
    echo "Nginx is not installed. Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
else
    echo "Nginx is already installed."
fi

# Install PHP and MySQL
sudo apt install -y php-fpm php-mysql mysql-server

# Start and enable Nginx and MySQL
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start mysql
sudo systemctl enable mysql

# Create a new Nginx server block configuration
sudo tee /etc/nginx/sites-available/horror_quiz <<EOF
server {
    listen 80;
    server_name halloween2024.techlogicals.uk;
    root /var/www/horror_quiz;
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

# Enable the new site and restart Nginx
sudo ln -s /etc/nginx/sites-available/horror_quiz /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Create the web root directory
sudo mkdir -p /var/www/horror_quiz

# Create upload_score.php
sudo tee /var/www/horror_quiz/upload_score.php <<EOF
<?php
\$servername = "localhost";
\$username = "horror_quiz_user";
\$password = "your_password_here";
\$dbname = "horror_quiz_db";

\$conn = new mysqli(\$servername, \$username, \$password, \$dbname);

if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

\$name = \$_GET['name'];
\$score = \$_GET['score'];
\$date = \$_GET['date'];

\$stmt = \$conn->prepare("INSERT INTO scores (name, score, date) VALUES (?, ?, ?)");
\$stmt->bind_param("sis", \$name, \$score, \$date);

if (\$stmt->execute()) {
    echo "Success";
} else {
    echo "Error: " . \$stmt->error;
}

\$stmt->close();
\$conn->close();
?>
EOF

# Create highscores.php
sudo tee /var/www/horror_quiz/highscores.php <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Horror Quiz High Scores</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Horror Quiz High Scores</h1>
    <table>
        <tr>
            <th>Rank</th>
            <th>Name</th>
            <th>Score</th>
            <th>Date</th>
        </tr>
        <?php
        \$servername = "localhost";
        \$username = "horror_quiz_user";
        \$password = "your_password_here";
        \$dbname = "horror_quiz_db";

        \$conn = new mysqli(\$servername, \$username, \$password, \$dbname);

        if (\$conn->connect_error) {
            die("Connection failed: " . \$conn->connect_error);
        }

        \$sql = "SELECT name, score, date FROM scores ORDER BY score DESC, date DESC LIMIT 10";
        \$result = \$conn->query(\$sql);

        if (\$result->num_rows > 0) {
            \$rank = 1;
            while(\$row = \$result->fetch_assoc()) {
                echo "<tr>
                        <td>".\$rank."</td>
                        <td>".\$row["name"]."</td>
                        <td>".\$row["score"]."</td>
                        <td>".\$row["date"]."</td>
                      </tr>";
                \$rank++;
            }
        } else {
            echo "<tr><td colspan='4'>No scores yet</td></tr>";
        }
        \$conn->close();
        ?>
    </table>
</body>
</html>
EOF

# Set proper permissions
sudo chown -R www-data:www-data /var/www/horror_quiz
sudo chmod -R 755 /var/www/horror_quiz

# Create MySQL database and user
sudo mysql <<EOF
CREATE DATABASE horror_quiz_db;
CREATE USER 'horror_quiz_user'@'localhost' IDENTIFIED BY 'your_password_here';
GRANT ALL PRIVILEGES ON horror_quiz_db.* TO 'horror_quiz_user'@'localhost';
FLUSH PRIVILEGES;
USE horror_quiz_db;
CREATE TABLE scores (
    id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    score INT(3) NOT NULL,
    date DATE NOT NULL
);
EOF

echo "Setup complete! Your Nginx server is now configured with PHP and MySQL for the Horror Quiz."
echo "Access the high scores page at: http://halloween2024.techlogicals.uk/highscores.php"