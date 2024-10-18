import os
import subprocess
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Set the directory where your Terraform files are located
terraform_directory = ""
# os.chdir(terraform_directory)

# Google Cloud project and credentials
PROJECT_ID = "smart-nomad-433514-k5"
CREDENTIALS_FILE = "../terraform-sa.json"

# Get the list of available zones in the region
def get_gcp_zones(project_id, credentials_file):
    credentials = service_account.Credentials.from_service_account_file(credentials_file)
    service = build('compute', 'v1', credentials=credentials)

    request = service.zones().list(project=project_id)
    zones = []

    while request is not None:
        response = request.execute()
        for zone in response['items']:
            zones.append(zone['name'])
        request = service.zones().list_next(previous_request=request, previous_response=response)

    return zones

# Create a Terraform configuration file for the current zone
def create_terraform_file_for_zone(zone, ssh_username):
    with open("server.tf", 'w') as file:
        with open("server_tf_template", 'r') as template:
            data = template.read()
            data = data.replace('__ZONE_PLACEHOLDER__', zone)
            data = data.replace('__SSH_USERNAME__', ssh_username)
            file.write(data)

# Run a Terraform command using subprocess
def run_terraform_command(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()
    if process.returncode != 0:
        print(f"Error: {stderr.decode('utf-8')}")
        return False
    print(stdout.decode('utf-8'))
    return True

# Try to apply the Terraform plan in each zone
def apply_terraform_in_zones(zones, ssh_username):
    for zone in zones:
        print(f"Trying to create the VM in zone: {zone}")

        # Create a unique Terraform configuration file for the current zone
        create_terraform_file_for_zone(zone, ssh_username)

        # Run terraform commands
        print("Initializing Terraform...")
        if not run_terraform_command("terraform init"):
            print("Terraform initialization failed. Skipping to next zone.")
            continue

        print(f"Planning Terraform deployment in zone {zone}...")
        if not run_terraform_command("terraform plan"):
            print("Terraform plan failed. Skipping to next zone.")
            continue

        print(f"Applying Terraform deployment in zone {zone}...")
        if run_terraform_command("terraform apply -auto-approve"):
            print(f"Successfully created the VM in zone: {zone} with SSH username: {ssh_username}")
            break
        else:
            print(f"Failed to create the VM in zone: {zone}, trying next zone.")
    else:
        print("Could not create the VM in any of the zones.")

if __name__ == "__main__":
    # Prompt for the SSH username, no default value, keep asking until valid input is provided
    ssh_username = ""
    while not ssh_username:
        ssh_username = input("Enter the SSH username (required): ").strip()
        if not ssh_username:
            print("SSH username cannot be empty. Please enter a valid username.")

    # Get available zones from GCP
    zones = get_gcp_zones(PROJECT_ID, CREDENTIALS_FILE)
    print(f"Available zones: {zones}")

    # Apply Terraform configuration for each zone
    apply_terraform_in_zones(zones, ssh_username)

