#!/bin/bash

# Ask for the server name
read -p "Enter your server name (e.g., example.com): " SERVER_NAME

# Create project directory
mkdir -p snippet_gallery
cd snippet_gallery

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install Flask gunicorn

# Create app.py
cat > app.py << EOL
from flask import Flask, render_template, request, redirect, url_for, jsonify, send_file
from werkzeug.utils import secure_filename
import os
import sqlite3
from datetime import datetime

app = Flask(__name__)

# Configuration
UPLOAD_FOLDER = 'static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Ensure upload folder exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Database setup
def get_db():
    db = sqlite3.connect('snippets.db')
    db.row_factory = sqlite3.Row
    return db

def init_db():
    with app.app_context():
        db = get_db()
        db.execute('''CREATE TABLE IF NOT EXISTS snippets 
                      (id INTEGER PRIMARY KEY, 
                       text TEXT, 
                       image_filename TEXT, 
                       category TEXT, 
                       created_at TIMESTAMP)''')
        db.commit()

init_db()

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        text = request.form['text']
        category = request.form['category']
        file = request.files['file']
        
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
        else:
            filename = None
        
        db = get_db()
        db.execute('INSERT INTO snippets (text, image_filename, category, created_at) VALUES (?, ?, ?, ?)', 
                   (text, filename, category, datetime.now()))
        db.commit()
        
        return redirect(url_for('index'))
    
    db = get_db()
    snippets = db.execute('SELECT * FROM snippets ORDER BY created_at DESC').fetchall()
    categories = db.execute('SELECT DISTINCT category FROM snippets').fetchall()
    return render_template('index.html', snippets=snippets, categories=categories)

@app.route('/load_snippet/<int:id>')
def load_snippet(id):
    db = get_db()
    snippet = db.execute('SELECT * FROM snippets WHERE id = ?', (id,)).fetchone()
    return jsonify({
        'text': snippet['text'],
        'image_filename': snippet['image_filename'],
        'category': snippet['category']
    })

@app.route('/filter_snippets/<category>')
def filter_snippets(category):
    db = get_db()
    snippets = db.execute('SELECT * FROM snippets WHERE category = ? ORDER BY created_at DESC', (category,)).fetchall()
    return render_template('snippet_list.html', snippets=snippets)

@app.route('/delete_snippet/<int:id>', methods=['POST'])
def delete_snippet(id):
    db = get_db()
    snippet = db.execute('SELECT image_filename FROM snippets WHERE id = ?', (id,)).fetchone()
    if snippet['image_filename']:
        os.remove(os.path.join(app.config['UPLOAD_FOLDER'], snippet['image_filename']))
    db.execute('DELETE FROM snippets WHERE id = ?', (id,))
    db.commit()
    return redirect(url_for('index'))

@app.route('/download_snippet/<int:id>')
def download_snippet(id):
    db = get_db()
    snippet = db.execute('SELECT * FROM snippets WHERE id = ?', (id,)).fetchone()
    if snippet['image_filename']:
        return send_file(os.path.join(app.config['UPLOAD_FOLDER'], snippet['image_filename']), as_attachment=True)
    else:
        return snippet['text'], 200, {'Content-Type': 'text/plain', 'Content-Disposition': 'attachment; filename=snippet.txt'}

if __name__ == '__main__':
    app.run(debug=True)
EOL

# Create templates directory
mkdir -p templates

# Create index.html with an elegant design and delete/download functions
cat > templates/index.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Elegant Snippet Gallery</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700&family=Roboto:wght@300;400&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.1.1/css/all.min.css">
    <style>
        body {
            font-family: 'Roboto', sans-serif;
            background-color: #f8f9fa;
            color: #343a40;
            padding-top: 80px;
        }
        h1, h2, h3 {
            font-family: 'Playfair Display', serif;
        }
        .navbar {
            background-color: #343a40;
        }
        .navbar-brand {
            font-family: 'Playfair Display', serif;
            font-size: 1.5rem;
        }
        .card {
            border: none;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
        }
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 15px rgba(0, 0, 0, 0.1);
        }
        .btn-primary {
            background-color: #007bff;
            border-color: #007bff;
        }
        .btn-primary:hover {
            background-color: #0056b3;
            border-color: #0056b3;
        }
        #snippetModal .modal-content {
            border-radius: 15px;
        }
        #snippetModal .modal-header {
            border-bottom: none;
            padding-bottom: 0;
        }
        #snippetModal .modal-body {
            padding-top: 0;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark fixed-top">
        <div class="container">
            <a class="navbar-brand" href="#">Elegant Snippet Gallery</a>
        </div>
    </nav>

    <div class="container">
        <div class="row">
            <div class="col-md-4">
                <h2 class="mb-4">Add New Snippet</h2>
                <form id="snippetForm" method="post" enctype="multipart/form-data" class="mb-5">
                    <div class="mb-3">
                        <textarea class="form-control" id="snippetText" name="text" rows="3" placeholder="Enter your snippet text here"></textarea>
                    </div>
                    <div class="mb-3">
                        <input type="file" class="form-control" id="snippetImage" name="file">
                    </div>
                    <div class="mb-3">
                        <input type="text" class="form-control" id="snippetCategory" name="category" placeholder="Enter category">
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Save Snippet</button>
                </form>
            </div>
            <div class="col-md-8">
                <h2 class="mb-4">Snippet Gallery</h2>
                <div class="mb-4">
                    <select id="categoryFilter" class="form-select">
                        <option value="">All Categories</option>
                        {% for category in categories %}
                            <option value="{{ category['category'] }}">{{ category['category'] }}</option>
                        {% endfor %}
                    </select>
                </div>
                <div id="snippetGallery" class="row g-4">
                    {% for snippet in snippets %}
                        <div class="col-md-6 col-lg-4 snippet">
                            <div class="card h-100">
                                {% if snippet['image_filename'] %}
                                    <img src="{{ url_for('static', filename='uploads/' + snippet['image_filename']) }}" class="card-img-top" alt="Snippet image">
                                {% endif %}
                                <div class="card-body">
                                    <p class="card-text">{{ snippet['text'][:50] }}...</p>
                                    <div class="d-flex justify-content-between align-items-center">
                                        <button class="btn btn-outline-primary btn-sm" onclick="loadSnippet({{ snippet['id'] }})">View</button>
                                        <div>
                                            <a href="{{ url_for('download_snippet', id=snippet['id']) }}" class="btn btn-outline-success btn-sm" title="Download"><i class="fas fa-download"></i></a>
                                            <form action="{{ url_for('delete_snippet', id=snippet['id']) }}" method="post" style="display: inline;">
                                                <button type="submit" class="btn btn-outline-danger btn-sm" onclick="return confirm('Are you sure you want to delete this snippet?')" title="Delete"><i class="fas fa-trash"></i></button>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    {% endfor %}
                </div>
            </div>
        </div>
    </div>

    <!-- Modal -->
    <div class="modal fade" id="snippetModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Snippet Details</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p id="modalSnippetText" class="mb-3"></p>
                    <img id="modalSnippetImage" src="" alt="Snippet image" class="img-fluid mb-3" style="display: none;">
                    <p id="modalSnippetCategory" class="text-muted"></p>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function loadSnippet(id) {
            fetch(\`/load_snippet/\${id}\`)
                .then(response => response.json())
                .then(data => {
                    document.getElementById('modalSnippetText').textContent = data.text;
                    document.getElementById('modalSnippetCategory').textContent = \`Category: \${data.category}\`;
                    let img = document.getElementById('modalSnippetImage');
                    if (data.image_filename) {
                        img.src = \`/static/uploads/\${data.image_filename}\`;
                        img.style.display = 'block';
                    } else {
                        img.style.display = 'none';
                    }
                    new bootstrap.Modal(document.getElementById('snippetModal')).show();
                });
        }

        document.getElementById('categoryFilter').addEventListener('change', function() {
            let category = this.value;
            if (category) {
                fetch(\`/filter_snippets/\${category}\`)
                    .then(response => response.text())
                    .then(html => {
                        document.getElementById('snippetGallery').innerHTML = html;
                    });
            } else {
                location.reload();
            }
        });
    </script>
</body>
</html>
EOL

# Create snippet_list.html
cat > templates/snippet_list.html << EOL
{% for snippet in snippets %}
    <div class="col-md-6 col-lg-4 snippet">
        <div class="card h-100">
            {% if snippet['image_filename'] %}
                <img src="{{ url_for('static', filename='uploads/' + snippet['image_filename']) }}" class="card-img-top" alt="Snippet image">
            {% endif %}
            <div class="card-body">
                <p class="card-text">{{ snippet['text'][:50] }}...</p>
                <div class="d-flex justify-content-between align-items-center">
                    <button class="btn btn-outline-primary btn-sm" onclick="loadSnippet({{ snippet['id'] }})">View</button>
                    <div>
                        <a href="{{ url_for('download_snippet', id=snippet['id']) }}" class="btn btn-outline-success btn-sm" title="Download"><i class="fas fa-download"></i></a>
                        <form action="{{ url_for('delete_snippet', id=snippet['id']) }}" method="post" style="display: inline;">
                            <button type="submit" class="btn btn-outline-danger btn-sm" onclick="return confirm('Are you sure you want to delete this snippet?')" title="Delete"><i class="fas fa-trash"></i></button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
{% endfor %}
EOL

# Create Nginx configuration
sudo tee /etc/nginx/sites-available/snippet_gallery << EOL
server {
    listen 80;
    server_name $SERVER_NAME;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /static {
        alias $(pwd)/static;
    }
}
EOL

# Create symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/snippet_gallery /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Create a systemd service file for Gunicorn
sudo tee /etc/systemd/system/snippet_gallery.service << EOL
[Unit]
Description=Gunicorn instance to serve Snippet Gallery
After=network.target

[Service]
User=$(whoami)
Group=www-data
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 app:app

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable snippet_gallery
sudo systemctl start snippet_gallery

echo "Elegant Snippet Gallery setup complete with delete and download functions!"
echo "Your application is now configured to run on: $SERVER_NAME"
echo "Make sure your DNS is properly configured to point to this server."
echo "You may need to configure your firewall to allow HTTP traffic."