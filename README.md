
# pearlthoughts-task
=======
# 🚀 Deploying Strapi on AWS EC2 using Terraform & Docker

This project automates the deployment of a Dockerized Strapi CMS instance on an AWS EC2 instance using Terraform.

---

## 📁 Directory Structure
 <pre>  strapi-terraform-deploy/
├── Dockerfile # Dockerfile for Strapi app
├── main.tf # Terraform config: VPC, SG, EC2, etc.
├── variables.tf # Terraform input variables
├── outputs.tf # Terraform outputs (e.g., public IP)
├── userdata.sh # User data script to install Docker and run container
├── .gitignore # Git ignored files
└── README.md # This file

---

## 🧱 Technologies Used

- **Terraform** – Infrastructure as Code
- **Docker** – Containerizing Strapi
- **AWS EC2** – Compute resource
- **AWS VPC & Security Groups** – Networking and security

---

## 🔧 What Does This Setup Do?

1. **Dockerize Strapi App**
   - Dockerfile builds your Strapi app into a container.

2. **Push Docker Image**
   - Push the image to Docker Hub or Amazon ECR.

3. **Terraform Deployment**
   - Creates a VPC
   - Launches EC2 instance
   - Creates security group (port 22 + 80 open)
   - Bootstraps instance with `userdata.sh` to:
     - Install Docker
     - Pull Strapi image
     - Run it on port 80

---

## 📝 Instructions to Run

### 1️⃣ Set up your Terraform variables
Edit `terraform.tfvars` (or use CLI input):

	key_name     = "your-ec2-keypair-name"
	docker_image = "your-dockerhub-username/strapi-image"

### 2️⃣ Initialize Terraform
	terraform init
	
### 3️⃣ Validate
	terraform validate

### 4️⃣ Apply to deploy
	terraform apply

🔐 Access the Strapi App
Once terraform apply completes successfully, access the Strapi Admin Panel using:

	http://<EC2-Public-IP>

*📦 Docker Image
Make sure your image is public or the EC2 instance has access to your private registry credentials.

🙌 Acknowledgement
This task was done as part of the PearlThoughts DevOps Internship assignment.
Task 4 - done by Aviral Mehndiratta.
