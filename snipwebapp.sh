from flask import Flask, render_template, request, redirect, url_for, jsonify
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

if __name__ == '__main__':
    app.run(debug=True)

# Save this HTML template in a file named 'index.html' in a 'templates' folder
"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snippet Gallery</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { padding-top: 60px; }
        .snippet { margin-bottom: 20px; }
        .snippet img { max-width: 100%; height: auto; }
        #snippetModal .modal-body img { max-width: 100%; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary fixed-top">
        <div class="container">
            <a class="navbar-brand" href="#">Snippet Gallery</a>
        </div>
    </nav>

    <div class="container">
        <div class="row">
            <div class="col-md-4">
                <h2>Add New Snippet</h2>
                <form id="snippetForm" method="post" enctype="multipart/form-data">
                    <div class="mb-3">
                        <textarea class="form-control" id="snippetText" name="text" rows="3" placeholder="Enter your snippet text here"></textarea>
                    </div>
                    <div class="mb-3">
                        <input type="file" class="form-control" id="snippetImage" name="file">
                    </div>
                    <div class="mb-3">
                        <input type="text" class="form-control" id="snippetCategory" name="category" placeholder="Enter category">
                    </div>
                    <button type="submit" class="btn btn-primary">Save Snippet</button>
                </form>
            </div>
            <div class="col-md-8">
                <h2>Snippet Gallery</h2>
                <div class="mb-3">
                    <select id="categoryFilter" class="form-select">
                        <option value="">All Categories</option>
                        {% for category in categories %}
                            <option value="{{ category['category'] }}">{{ category['category'] }}</option>
                        {% endfor %}
                    </select>
                </div>
                <div id="snippetGallery" class="row">
                    {% for snippet in snippets %}
                        <div class="col-md-4 snippet">
                            <div class="card">
                                {% if snippet['image_filename'] %}
                                    <img src="{{ url_for('static', filename='uploads/' + snippet['image_filename']) }}" class="card-img-top" alt="Snippet image">
                                {% endif %}
                                <div class="card-body">
                                    <p class="card-text">{{ snippet['text'][:50] }}...</p>
                                    <button class="btn btn-sm btn-info" onclick="loadSnippet({{ snippet['id'] }})">View</button>
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
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Snippet Details</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p id="modalSnippetText"></p>
                    <img id="modalSnippetImage" src="" alt="Snippet image" style="display: none;">
                    <p id="modalSnippetCategory"></p>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function loadSnippet(id) {
            fetch(`/load_snippet/${id}`)
                .then(response => response.json())
                .then(data => {
                    document.getElementById('modalSnippetText').textContent = data.text;
                    document.getElementById('modalSnippetCategory').textContent = `Category: ${data.category}`;
                    let img = document.getElementById('modalSnippetImage');
                    if (data.image_filename) {
                        img.src = `/static/uploads/${data.image_filename}`;
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
                fetch(`/filter_snippets/${category}`)
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
"""

# Save this HTML template in a file named 'snippet_list.html' in the 'templates' folder
"""
{% for snippet in snippets %}
    <div class="col-md-4 snippet">
        <div class="card">
            {% if snippet['image_filename'] %}
                <img src="{{ url_for('static', filename='uploads/' + snippet['image_filename']) }}" class="card-img-top" alt="Snippet image">
            {% endif %}
            <div class="card-body">
                <p class="card-text">{{ snippet['text'][:50] }}...</p>
                <button class="btn btn-sm btn-info" onclick="loadSnippet({{ snippet['id'] }})">View</button>
            </div>
        </div>
    </div>
{% endfor %}
"""


