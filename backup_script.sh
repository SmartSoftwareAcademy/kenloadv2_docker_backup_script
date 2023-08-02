#!/bin/bash

# Load environment variables from config.json
CONFIG_FILE="/app/config.json"

if [ -f "$CONFIG_FILE" ]; then
    # Read and parse JSON config file
    MYSQL_USER=$(jq -r '.MYSQL_USER' "$CONFIG_FILE")
    MYSQL_PASSWORD=$(jq -r '.MYSQL_PASSWORD' "$CONFIG_FILE")
    MYSQL_HOST=$(jq -r '.MYSQL_HOST' "$CONFIG_FILE")
    MYSQL_PORT=$(jq -r '.MYSQL_PORT' "$CONFIG_FILE")
    DATABASE_NAME=$(jq -r '.DATABASE_NAME' "$CONFIG_FILE")
    BACKUP_DIR=$(jq -r '.BACKUP_DIR' "$CONFIG_FILE")
    HOST_DIR=$(jq -r '.HOST_DIR' "$CONFIG_FILE")
    TZ=$(jq -r '.TZ' "$CONFIG_FILE")
    DESIRED_BACKUP_TIME=$(jq -r '.DESIRED_BACKUP_TIME' "$CONFIG_FILE")
else
    echo "Config file not found."
    exit 1
fi

# Function to perform the backup
perform_backup() {
    #MySQL Connection Details
    mysql_user="$MYSQL_USER"
    mysql_password="$MYSQL_PASSWORD"
    mysql_host="$MYSQL_HOST"
    mysql_port="$MYSQL_PORT"
    database_name="$DATABASE_NAME"

    # Backup Directory
    backup_dir="$BACKUP_DIR"
    host_dir="$HOST_DIR"

    # Timestamp for the backup file
    #$(date +"%Y%m%d%H%M%S")
    timestamp=$(date +"%Y%m")
    # Check if backup directory exists, if not, create it
    if [ ! -d "$backup_dir" ]; then
        mkdir "$backup_dir"
    fi

    # Check if there is a full backup file
    full_backup_file="$backup_dir/full_backup_$timestamp.zip"
    if [ -f "$full_backup_file" ]; then
        # Perform incremental backup since a previous backup exists
        /usr/bin/mysqldump --user="$mysql_user" --password="$mysql_password" --host="$mysql_host" --port="$mysql_port" --databases "$database_name" --single-transaction --flush-logs --source-data=2 --set-gtid-purged=OFF --result-file="$backup_dir/incremental_backup_$timestamp.sql"
        /usr/bin/zip -r "$backup_dir/incremental_backup_$timestamp.zip" "$backup_dir"/*.sql
    else
        # Perform full backup if no previous backup exists
        /usr/bin/mysqldump --user="$mysql_user" --password="$mysql_password" --host="$mysql_host" --port="$mysql_port" --databases "$database_name" --result-file="$backup_dir/full_backup_$timestamp.sql"
        # Compress all the SQL files to a zip archive
        /usr/bin/zip -r "$backup_dir/full_backup_$timestamp.zip" "$backup_dir"/*.sql
    fi

    # Update the previous backup file with the most recent incremental backup
    # mv "$backup_dir/incremental_backup_$timestamp.sql" "$previous_backup_file"

    # Compress all the SQL files to a zip archive
    #/usr/bin/zip -r "$backup_dir/autobackupfiles_$timestamp.zip" "$backup_dir"/*.sql

    # Save the link to the backup zip file in the database
    backup_file="$host_dir/autobackupfiles_$timestamp.zip"
    backup_file="${backup_file//\\/\\\\}"

    /usr/bin/mysql --user="$mysql_user" --password="$mysql_password" --host="$mysql_host" --port="$mysql_port" --database="$database_name" --execute="INSERT INTO backups (backupName,bkPath) VALUES ('autoautobackupfiles_$timestamp.zip','$backup_file');"

    # Delete all .sql files except for incremental_previous_backup.sql
    find "$backup_dir" -maxdepth 1 -type f -name '*.sql' ! -name 'incremental_previous_backup.sql' -exec rm {} \;

    echo "Backup and database update completed successfully!"
}

# Get the desired backup time from an environmental variable (in 24-hour format, e.g., 0200 for 2 AM)
desired_backup_time="${DESIRED_BACKUP_TIME}"

# Run the backup process daily at the desired time
while true; do
    current_time=$(date +"%H%M")
    echo "Now: $current_time HRS - Backup Time: $desired_backup_time HRS"
    if [ "$current_time" == "$desired_backup_time" ]; then
        perform_backup
    else
        # Calculate time left until the next backup
        current_hour=$(date +"%-H")
        current_minute=$(date +"%-M")
        backup_hour=${desired_backup_time:0:2}
        backup_minute=${desired_backup_time:2:2}

        # Remove leading zeros if present
        backup_hour=${backup_hour#0}
        backup_minute=${backup_minute#0}

        # Convert to integer values
        current_hour=$((10#$current_hour))
        current_minute=$((10#$current_minute))
        backup_hour=$((10#$backup_hour))
        backup_minute=$((10#$backup_minute))

        # Calculate time left
        time_left=$(( (backup_hour - current_hour) * 60 + (backup_minute - current_minute) ))

        if [ $time_left -lt 0 ]; then
            time_left=$((time_left + 24 * 60)) # Add 24 hours to handle next day's backup
        fi
        echo "Next backup in $time_left minutes."
    fi
    sleep 30  # Sleep for 30 secs
done
