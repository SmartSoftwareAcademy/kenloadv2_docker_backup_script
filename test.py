import docker

# Connect to the Docker daemon
client = docker.from_env()

def restart_container(container_name):
    try:
        container = client.containers.get(container_name)
        container.start()
        print(f"Container '{container_name}' restarted successfully.")
    except docker.errors.NotFound:
        print(f"Container '{container_name}' not found.")
    except docker.errors.APIError as e:
        print(f"Error restarting container '{container_name}': {e}")

if __name__ == "__main__":
    container_name = "kenloadv2_autobackup_script"
    restart_container(container_name)
