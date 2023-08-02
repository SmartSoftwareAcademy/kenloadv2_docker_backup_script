# Kenloadv2 Autobackup Docker Image

This Docker image is designed to automate the backup of a MySQL database using a specified schedule. It runs a backup script inside a Docker container that connects to a MySQL database, performs backups, and stores them in a designated directory. The image is based on Ubuntu 22.04.

## Getting Started

### 1. Create MySQL User and Grant Privileges:

Run the following commands in your MySQL terminal to create a new user with backup privileges:

```sql
CREATE USER 'new_user'@'%' IDENTIFIED BY 'new_password';
GRANT ALL PRIVILEGES ON your_database_name.* TO 'new_user'@'%';
FLUSH PRIVILEGES;
````
### 2. Configure a bind address to enable the docker MySQL instance to connect to the host machine's MySQL instance
   -  Create *my.ini* file at the root of the MySQL installation directory if it does not exist already
   - Add this line or uncomment if already exist
     ```sh
        bind-address=0.0.0.0
    ```

To use this Docker image, follow these steps:

Pull the Docker image from Docker Hub using the following commands:
````sh
docker pull titusdev/kenloadv2_autobackup_script
````
Run the Docker container with the necessary settings:
````sh
docker run -p 5000:5000 -v path/to/host/machine/backup/directory:/app/backups --name kenloadv2_autobackup_script -d titusdev/kenloadv2_autobackup_script
````
Remember to replace "path/to/host/machine/backup/directory" with the path on your host machine where you want to save the backup files. The path should have the necessary access permissions.

Configure the environmental variables from the .[Kenloadv2 Auto backup Image GUI](http://127.0.0.1:5000)

### 3. Replace Environmental Variables

Before running the Docker container, replace the following environmental variables in the docker run command with your own values:

- `MYSQL_USER`: The MySQL user with backup privileges.
- `MYSQL_PASSWORD`: Password for the MySQL user.
- `MYSQL_HOST`: IP address of the MySQL host machine.
- `MYSQL_PORT`: MySQL port (default: 3306).
- `DATABASE_NAME`: The name of the database to be backed up.
- `HOST_DIR`: Directory path on the host machine to map the container's backup directory and store backup files.
- `DESIRED_BACKUP_TIME`: Desired daily backup time in 24 HR clock system (e.g., 0200 for 2 AM).
- `TZ`: Timezone for the Docker container to use. Default is Africa/Nairobi.

### 4. MySQL User Permissions
Ensure that you have created a MySQL user with backup privileges (GRANT ALL) specifically for this script. This user should have the necessary privileges to perform backups on the specified database. It's recommended to avoid using the root user for security reasons.

### 5. Backup Script Overview
The script inside the Docker container connects to the MySQL database using the provided credentials and performs backups. If a previous backup exists, it performs an incremental backup; otherwise, it performs a full backup. Backups are compressed and stored in the designated backup directory. The script then saves the backup path in the MySQL database for reference.

Usage
1.  Make sure you have Docker installed on your system.
2. Replace the necessary environmental variables as described above.
3. Restart the Docker image using the Docker app or via the terminal with
````sh
docker restart titusdev/kenloadv2_autobackup_script
````
4. The script will execute backups based on the set schedule.
***License
## License

This Docker image and script are provided under the MIT License. See [LICENSE](./LICENSE) for details.