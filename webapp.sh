#!/bin/bash

# Create project directory
mkdir -p minimal-webapp
cd minimal-webapp

# Create HTML file
cat > index.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minimal Website</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>Welcome to My Minimal Website</h1>
    </header>
    <main>
        <p>This is a simple, minimal website.</p>
    </main>
    <footer>
        <p>&copy; 2023 My Minimal Website</p>
    </footer>
    <script src="script.js"></script>
</body>
</html>
EOL

# Create CSS file
cat > styles.css << EOL
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    max-width: 800px;
    margin: 0 auto;
}

header, footer {
    background-color: #f4f4f4;
    padding: 10px;
    text-align: center;
}

main {
    padding: 20px 0;
}
EOL

# Create JavaScript file
cat > script.js << EOL
console.log('Minimal website loaded!');
EOL

# Create a simple Python web server script
cat > server.py << EOL
import http.server
import socketserver

PORT = 8000

Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving at http://localhost:{PORT}")
    httpd.serve_forever()
EOL

echo "Minimal web app created. To run the server, use: python3 server.py"
