from flask import Flask, request, jsonify, g
import sqlite3
import random
import string
import datetime
import os
app = Flask(__name__)

# Database setup
def get_db():
    if 'db' not in g:
        g.db = sqlite3.connect('user_database.db')
    return g.db

def get_username_by_access_token(access_token):
    db = sqlite3.connect('user_database.db')
    cursor = db.cursor()

    cursor.execute("SELECT username FROM users WHERE access_token = ?", (access_token,))
    result = cursor.fetchone()

    cursor.close()
    db.close()

    if result:
        return result[0]  # Return the username from the result
    else:
        return None  # Return None if the access token is not found

def write_data_to_database(username, data):
    # Define the database filename
    database_filename = f'user_database_{username}-db.db'
    
    # Create the database if it doesn't exist
    if not os.path.exists(database_filename):
        db = sqlite3.connect(database_filename)
        cursor = db.cursor()
        
        # Create a table to store the data
        cursor.execute('''
            CREATE TABLE data (
                id INTEGER PRIMARY KEY,
                time TEXT,
                humidity REAL,
                temperature REAL,
                pressure REAL,
                location TEXT
            )
        ''')
        
        db.commit()
        cursor.close()
        db.close()

    # Open the database and write the data
    db = sqlite3.connect(database_filename)
    cursor = db.cursor()

    time = data.get('time')
    humidity = data.get('humidity')
    temperature = data.get('temperature')
    pressure = data.get('pressure')
    location = data.get('location')

    cursor.execute("INSERT INTO data (time, humidity, temperature, pressure, location) VALUES (?, ?, ?, ?, ?)", (time, humidity, temperature, pressure, location))
    db.commit()
    cursor.close()
    db.close()

@app.teardown_appcontext
def close_db(error):
    if hasattr(g, 'db'):
        g.db.close()

# Create the users table if it doesn't exist
with app.app_context():
    db = get_db()
    cursor = db.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            email TEXT NOT NULL,
            access_token TEXT
        )
    ''')
    db.commit()
    cursor.close()

# Generate a random access token
def generate_access_token():
    return ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(50))

# Endpoint for user registration
@app.route('/register', methods=['POST'])
def register_user():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    email = data.get('email')
    if not username or not password or not email:
        return jsonify({'message': 'Invalid username or password or email', 'status': 'invalidRegister'}), 400

    db = get_db()
    cursor = db.cursor()

    # Check if the username already exists
    cursor.execute("SELECT id FROM users WHERE username = ?", (username,))
    existing_user = cursor.fetchone()

    if existing_user:
        return jsonify({'message': 'Username already exists', 'status': 'alreadyExists'}), 400

    access_token = generate_access_token()

    cursor.execute("INSERT INTO users (username, password, email, access_token) VALUES (?, ?, ?, ?)", (username, password, email, access_token))
    db.commit()
    cursor.close()

    return jsonify({'access_token': access_token, 'status': 'success'}), 201

# Endpoint for user login
@app.route('/login', methods=['POST'])
def login_user():
    data = request.json
    print(data)
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'message': 'Invalid username or password', 'status': 'invalidLogin'}), 400

    db = get_db()
    cursor = db.cursor()

    cursor.execute("SELECT access_token FROM users WHERE username = ? AND password = ?", (username, password))
    user_data = cursor.fetchone()

    cursor.close()

    if user_data:
        return jsonify({'access_token': user_data[0], 'status': 'success'}), 200
    else:
        return jsonify({'message': 'Invalid username or password', 'status': 'invalidLogin'}), 401
        
@app.route('/getUserData', methods=['POST'])
def get_userdata():
    data = request.json
    print(data)
    access_token = data.get('access_token')
    print(access_token)

    if not access_token:
        return jsonify({'message': 'Invalid accesstoken', 'status': 'invalidLogin'}), 400

    db = get_db()
    cursor = db.cursor()

    cursor.execute("SELECT email FROM users WHERE access_token = ?", (access_token,))
    user_data = cursor.fetchone()

    cursor.close()

    if user_data:
        return jsonify({'email': user_data[0], 'status': 'success'}), 200
    else:
        return jsonify({'message': 'Invalid username or password', 'status': 'invalidLogin'}), 401


@app.route('/postData', methods=['POST'])
def post_data():
    data = request.json
    print(data)
    currentTime = datetime.datetime.now()
    humidity = data.get('humidity')
    temperature = data.get('temperature')
    pressure = data.get('pressure')
    location = data.get('location')
    access_token = data.get('access_token')
    if not all([humidity, temperature, pressure, location, access_token]):
        return jsonify({'message': 'Invalid data', 'status': 'invalidData'}), 400
    
    username = get_username_by_access_token(access_token)
    
    if username != None:
        data = {
            'time': currentTime,
            'humidity': humidity,
            'temperature': temperature,
            'pressure': pressure,
            'location': location
        }

        write_data_to_database(username, data)
        return jsonify({'message': 'Successfully posted data', 'status': 'success'}), 200
    else:
        return jsonify({'message': 'Unauthorized', 'status': 'unauthorized'}), 403
    
@app.route('/latestVersion', methods=['POST'])
def latest_version():
    return jsonify({'latest': "V1.0"}), 201


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

