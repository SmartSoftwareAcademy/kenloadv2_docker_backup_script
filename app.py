from flask import Flask, render_template, request, jsonify
import json
import subprocess
import os
import json
import requests


CONFIG_FILE = "/app/config.json"

# Define the Docker Remote API endpoint
DOCKER_API_URL = "http://host.docker.internal:2375"
app = Flask(__name__)

CONFIG_FILE = "/app/config.json"

@app.route('/')
def index():
    config_data = {}
    if subprocess.call(["test", "-f", CONFIG_FILE]) == 0:
        with open(CONFIG_FILE, 'r') as f:
            config_data = json.load(f)
    return render_template('index.html', config=config_data)

@app.route('/readme')
def readme():
    return render_template('readme.html')

@app.route('/update', methods=['POST'])
def update_config():
    try:
        new_config = {
            'MYSQL_USER': request.form['MYSQL_USER'],
            'MYSQL_PASSWORD': request.form['MYSQL_PASSWORD'],
            'MYSQL_HOST': request.form['MYSQL_HOST'],
            'MYSQL_PORT': request.form['MYSQL_PORT'],
            'DATABASE_NAME': request.form['DATABASE_NAME'],
            'BACKUP_DIR': request.form['BACKUP_DIR'],
            'HOST_DIR': request.form['HOST_DIR'],
            'TZ': request.form['TZ'],
            'DESIRED_BACKUP_TIME': request.form['DESIRED_BACKUP_TIME'],
        }
        with open(CONFIG_FILE, 'w') as f:
            json.dump(new_config, f, indent=4)

        # Restart the container
        #subprocess.run(f'docker restart {request.form["CONTAINER_NAME"]}', shell=True)

        message = 'Environment variables updated successfully. Restart Container to effect changes.'
        return render_template('index.html', message=message)
    except Exception as e:
        error_message = f'An error occurred: {str(e)}'
        return render_template('index.html', error_message=error_message)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
