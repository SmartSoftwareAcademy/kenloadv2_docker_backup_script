FROM ubuntu:latest

# Install MySQL Client and zip utility
RUN apt-get update
RUN apt-get install -y mysql-client zip jq python3 python3-pip

# Create the app directory
WORKDIR /app

# Copy the requirements.txt file and install Flask dependencies
COPY requirements.txt /app/requirements.txt
RUN pip3 install -r requirements.txt

# Copy the backup script to the container
COPY backup_script.sh /app/backup_script.sh
# Copy the config file to the container
COPY config.json /app/config.json

# Copy the Flask app and backup script to the container
COPY app.py /app/app.py
COPY templates /app/templates

# Set execute permissions for the script
RUN chmod +x /app/backup_script.sh

# Expose the Flask app port
EXPOSE 5000

# Run the Flask app and the backup script
CMD ["/bin/bash", "-c", "/app/backup_script.sh & python3 /app/app.py"]
