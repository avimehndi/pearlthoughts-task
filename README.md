# Task 1 -  Strapi Core Setup and CMS Exploration

This repository contains my exploration of the [Strapi open-source CMS](https://github.com/strapi/strapi) source code. The goal of this task was to clone Strapi's monorepo, run it locally, understand the folder structure, start the admin panel, and create a sample content type.

---

## Cloning the Strapi Repository

The official Strapi GitHub repository was cloned using:

```bash
git clone https://github.com/strapi/strapi
cd strapi
```

---

## Project Setup

> The cloned repository is the **Strapi monorepo**, meant for contributing to Strapi, not for creating projects directly.

To explore Strapi as a developer:

1. **Installed dependencies**:
   ```bash
   npm install
   ```

2. **Built the packages**:
   ```bash
   npm run build
   ```

3. **Started the development playground**:
   ```bash
   npm run develop
   ```

> This runs a development instance of Strapi for testing and exploring its admin UI and packages.

---

## Folder Structure Overview

Here’s a quick breakdown of key folders in the cloned monorepo:

| Folder                  | Purpose                                                                 |
|--------------------------|-------------------------------------------------------------------------|
| `packages/core`         | Core packages of Strapi (admin, backend, CLI, etc.)                     |
| `packages/plugins`      | Built-in plugins like `i18n`, `upload`, `users-permissions`, etc.       |
| `packages/utils`        | Shared utilities used across the codebase                               |
| `packages/strapi`       | The CLI tool used for creating new Strapi apps                          |
| `scripts/`              | Dev scripts for maintainers                                             |
| `examples/`             | Example Strapi apps for testing                                         |

---

## Starting the Admin Panel

Once built and started using `npm run develop`, the Strapi admin panel is available at:

```
http://localhost:1337/admin
```

---

## Creating a Sample Content Type

To test the CMS:

1. Logged in to the admin panel
2. Created a collection type named `Test Blog`
3. Added the following fields:
   - `Title` (Text)
   - `Content` (Rich Text)
   - `Slug` (UID)
   - `Published Date` (Date)

---

## Public API Endpoint Test

After creating the blog content type, I verified the API was working by accessing:

```
http://localhost:1337/api/blogs
```

This returned the expected blog entries in JSON format.

---

## GitHub Setup

After running and exploring the project:

- Created a personal branch:
  ```bash
  git checkout -b aviral
  ```

- Committed the work:
  ```bash
  git add .
  git commit -m "Task 1 -  Strapi Core Setup and CMS Exploration"
  git push -u origin aviral
  ```
---
# Task 2 - Strapi Application (Dockerized)

This task instructs us to Dockerize Strapi CMS application using a **multi-stage build** for optimized image size and security. The Strapi backend is located in the `my-strapi-project` directory.

---

## Project Structure

```
.
├── my-strapi-project/
│   ├── Dockerfile               # Multi-stage Dockerfile
│   ├── .dockerignore
│   ├── package.json
│   ├── package-lock.json
│   ├── src/
│   ├── config/
│   ├── ...
│   └── .env.example             # Sample env file
├── README.md
```

---

## Docker: Multi-Stage Build

The Dockerfile inside `my-strapi-project/` uses multi-stage builds to:

- **Install dependencies** without including them in the final image.
- **Build the Strapi application** for production use.
- **Serve with `node` in a clean environment**.

### 🔧 Build Docker Image

Navigate to the project directory:

```bash
cd my-strapi-project
```

Then build the Docker image:

```bash
docker build -t strapi-app .
```

---

### Run Docker Container

```bash
docker run -d -p 1337:1337 --name strapi-app strapi-app
```

Visit [http://localhost:1337](http://localhost:1337) to access your Strapi admin panel.

---

## Common Docker Commands

### Start an existing stopped container:
```bash
docker start strapi-app
```

### Stop the container:
```bash
docker stop strapi-app
```

### View logs:
```bash
docker logs -f strapi-app
```

---

## 🧼 Cleanup

To reduce image size and build context, unnecessary files are excluded using `.dockerignore`. Check that file for optimization settings.

---
# Task 3 - Dockerized Strapi Setup with PostgreSQL and Nginx Reverse Proxy on Localhost

This task sets up a fully Dockerized Strapi application with:

- PostgreSQL database
- Nginx reverse proxy (on port 80)
- Multi-stage Dockerfile for optimized Strapi build
- All services running on the same user-defined Docker network

---

## Project Structure

```
my-strapi-project/
├── Dockerfile
├── docker-compose.yml
├── nginx/
│   └── default.conf
├── src/
│   └── (Strapi project files)
├── package.json
└── yarn.lock
```

---

## Dockerfile (Multi-Stage)

Located at `my-strapi-project/Dockerfile`:

```Dockerfile
FROM node:20

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Expose Strapi default port
EXPOSE 1337

# Run Strapi in development mode
CMD ["npm", "run", "develop"]
```

---

## `nginx/default.conf`

```nginx
server {
    listen 80;

    server_name localhost;

    location / {
        proxy_pass http://strapi:1337;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## `docker-compose.yml`

```yaml
version: '3.8'

services:
  strapi:
    build: .
    container_name: strapi
    env_file:
      - .env
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: ${POSTGRES_DB}
      DATABASE_USERNAME: ${POSTGRES_USER}
      DATABASE_PASSWORD: ${POSTGRES_PASSWORD}
      STRAPI_ADMIN_EMAIL: ${STRAPI_ADMIN_EMAIL}
      STRAPI_ADMIN_PASSWORD: ${STRAPI_ADMIN_PASSWORD}
    ports:
      - "1337:1337"
    networks:
      - strapi-network
    depends_on:
      - postgres
    volumes:
      - .:/app
      - /app/node_modules
      - /app/.cache
      - /app/.tmp

  postgres:
    image: postgres:15
    container_name: postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - strapi-network

  nginx:
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - strapi
    networks:
      - strapi-network

volumes:
  postgres_data:

networks:
  strapi-network:
    driver: bridge
```

---

## Run the Stack

```bash
docker-compose up --build -d
```

---

## Access Strapi

Open [http://localhost](http://localhost) in your browser.

---

## Clean Up

```bash
docker-compose down -v
```

---

## References

- [Strapi Docs](https://docs.strapi.io/)
- [Docker Compose](https://docs.docker.com/compose/)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Nginx Docker](https://hub.docker.com/_/nginx)

---

# Task 4 - Strapi EC2 Deployment via Docker and Terraform

This task demonstrates deploying a Dockerized Strapi application to an AWS EC2 instance using Terraform. It automates infrastructure provisioning, Docker installation, image pulling, and container execution via EC2 User Data.

---

## Project Structure

```
Strapi-Pipeline-Masters/
├── my-strapi-project/        # Strapi application folder (Dockerized)
│   ├── Dockerfile            # Dockerfile for building the Strapi app
│   ├── .env                  # Environment file (not pushed to repo)
│   └── ...                   # Strapi app files
├── terraform/                # Terraform scripts to provision EC2
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── user-data.sh
└── README.md
```

---

## Deployment Steps

### Prerequisites

- AWS account with an IAM user
- SSH key pair created in the AWS region
- Docker Hub account with the Strapi image pushed
- Terraform installed
- `.env` file with necessary Strapi environment variables (local use)

---
### Dockerize Strapi App

In the `my-strapi-project/` folder:

```Dockerfile
FROM node:20

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Expose Strapi default port
EXPOSE 1337

# Run Strapi in development mode
CMD ["npm", "run", "develop"]

```
### Build and Push Image:

```bash
# In the strapi app folder
docker build -t avimehndi/strapi-app:latest .
docker push avimehndi/strapi-app:latest
```

---

### Configure Terraform

Edit the `terraform/terraform.tfvars` file with our values:

```hcl
region     = "us-east-2"
key_name   = "my-key-aviral"
image_name = "avimehndi/strapi-app:latest"
```

Run the following:

```bash
cd terraform
terraform init
terraform apply
```

> This provisions a t3.micro EC2 instance, installs Docker, and runs your Strapi app.

---

### Accessing Strapi

- Once the instance passes the 3/3 status checks, access your app via:

```bash
http://<your-ec2-public-ip>
```

- To SSH into the instance:

```bash
ssh -i ~/.ssh/my-key-aviral.pem ubuntu@<public-ip>
```

---

## Managing the Instance

- **Stop Instance**: Go to AWS Console > EC2 > Instances > Stop
- **Restart**: Start the instance from the AWS Console
- **Terminate**: `terraform destroy`

---

## Notes

- `.env` is excluded via `.gitignore`
- Terraform state files are ignored for safety
- Docker container auto-restarts unless stopped manually
- Strapi app runs on port 80 mapped from 1337 inside the container

---

## Final Output

- EC2 instance provisioned via Terraform
- Docker installed via user-data
- Strapi container running and accessible via public IP

---

# Task 5 - Strapi Deployment on AWS EC2 using Docker, Terraform, and GitHub Actions

This task automates the deployment of a Dockerized Strapi CMS to an AWS EC2 instance using a full CI/CD pipeline powered by GitHub Actions and Terraform.

## Features

- Dockerized Strapi app
- GitHub Actions CI/CD pipeline
- AWS EC2 provisioning with Terraform
- Secrets management with GitHub Secrets
- Auto-deployment of container using EC2 `user-data` script
- Publicly accessible Strapi instance

---

## Project Structure

```
.
├── my-strapi-project             
├── main.tf                    # EC2 instance and security group config
├── variables.tf               # Terraform variables                
│── user-data.sh               # EC2 bootstrap script for deploying Strapi
├── .github/
   └── workflows/
        ├── ci.yml                # CI pipeline: builds and pushes Docker image
        └── terraform.yml         # CD pipeline: provisions EC2 using Terraform

```

---

## CI/CD Overview

### `ci.yml` - CI Workflow

- Triggered on every `push` to the `main` branch.
- Builds the Strapi Docker image.
- Tags the image with the Git short SHA.
- Pushes the image to [Docker Hub](https://hub.docker.com/repository/docker/brohan9/strapi-app).
- Stores the image tag as a GitHub Actions artifact.

### `terraform.yml` - CD Workflow

- Downloads the image tag artifact from the CI pipeline.
- Applies Terraform code to provision or update the EC2 instance.
- Passes secrets and Docker tag into EC2 `user_data` script for container launch.

---

## AWS Infrastructure (Terraform)

### Key Resources:

- **EC2 Instance**: Ubuntu instance with Docker installed
- **Security Group**: Opens port `1337` for public access
- **User Data**: Bootstraps the instance by pulling and running the Strapi Docker container

---

## user-data.sh

This script is automatically run by the EC2 instance when it boots up.

```bash
#!/bin/bash

exec > /var/log/user-data.log 2>&1

echo ">>> Installing Docker"
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

echo ">>> Pulling Docker image"
sudo docker pull brohan9/strapi-app:${docker_tag}

echo ">>> Removing existing container if any"
sudo docker rm -f strapi || true

echo ">>> Running new Strapi container"
sudo docker run -d \
  --name strapi \
  -p 1337:1337 \
  --restart unless-stopped \
  -e APP_KEYS="$APP_KEYS" \
  -e API_TOKEN_SALT="$API_TOKEN_SALT" \
  -e ADMIN_JWT_SECRET="$ADMIN_JWT_SECRET" \
  -e JWT_SECRET="$JWT_SECRET" \
  brohan9/strapi-app:${docker_tag}
echo ">>> Done setting up Strapi"

```
All environment variables are injected manually.

---

## Secrets Used

These are stored securely in GitHub Secrets and injected via the pipeline:

| Secret Name           | Purpose                              |
|-----------------------|--------------------------------------|
| `DOCKER_USERNAME`     |  JWT Secret for admin panel login    |
| `DOCKER_PASSWORD`     | General auth token signing           |
| `AWS_ACCESS_KEY_ID`   | For Terraform access                 |
| `AWS_SECRET_ACCESS_KEY` | For Terraform access               |

---

## Accessing Strapi

Once the EC2 instance is up and running, navigate to:

```
http://<EC2_PUBLIC_IP>:1337
```

It will automatically redirect to `/admin` to set up your admin account.

---

## Deployment Summary

- Docker image built and pushed via CI pipeline  
- EC2 instance provisioned using Terraform  
- Strapi container deployed using EC2 User Data  
- Secrets injected securely at runtime  
- Admin dashboard accessible via browser  

---

## Final Notes

- The pipeline is completely automated — no manual SSH or EC2 configuration.
- This setup is ideal for staging or production use cases.
- DNS and HTTPS setup can be added as a next step using Nginx and Route53.

---

# Task 6 - Deploy Strapi on AWS ECS Fargate using Terraform with full infrastructure automation.

This task deploys a **Strapi CMS** app to **AWS ECS Fargate**, fronted by an **Application Load Balancer (ALB)** using **Terraform**.

---

## Project Structure

```
.
├── my-strapi-project
    ├── Dockerfile
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── outputs.tf
```

---

## Prerequisites

- AWS CLI configured
- Terraform installed
- Docker installed
- AWS IAM roles created:
  - `ecsTaskExecutionRole` (with policies: `AmazonECSTaskExecutionRolePolicy`, `CloudWatchLogsFullAccess`)

---

## Step 1: Build & Push Docker Image

```bash
# 1. Build Docker image
docker build -t strapi-app .

# 2. Tag image
docker tag strapi-app:latest <your_account_id>.dkr.ecr.us-east-2.amazonaws.com/strapi-app:latest

# 3. Authenticate Docker to ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <your_account_id>.dkr.ecr.us-east-2.amazonaws.com

# 4. Push image to ECR
docker push <your_account_id>.dkr.ecr.us-east-2.amazonaws.com/strapi-app:latest
```

---

## Step 2: Configure Terraform

Update `terraform.tfvars`:

```hcl
aws_access_key       = "YOUR_ACCESS_KEY"
aws_secret_key       = "YOUR_SECRET_KEY"
region               = "us-east-2"
container_image      = "<your_account_id>.dkr.ecr.us-east-2.amazonaws.com/strapi-app:latest"
execution_role_arn   = "arn:aws:iam::<account_id>:role/ecs-task-execution-role"
task_role_arn        = "arn:aws:iam::<account_id>:role/ecs-task-execution-role"
app_keys             = "some_app_key"
admin_jwt_secret     = "admin_secret"
jwt_secret           = "jwt_secret"
api_token_salt       = "salt_key"
```

---

## Step 3: Deploy with Terraform

```bash
cd terraform/

terraform init
terraform plan 
terraform apply 
```

Output:  
```
strapi_url = aviral-strapi-alb-xxxxxxxx.us-east-2.elb.amazonaws.com
```

---

## Access Strapi

Open the output ALB DNS URL in your browser:  
```
aviral-strapi-alb-xxxxxxxx.us-east-2.elb.amazonaws.com
```

---

## AWS Resources Created

- ECS Cluster + Service + Task Definition
- Application Load Balancer (ALB)
- Target Group + Listener
- CloudWatch Logs Group
- Security Group (Port 1337 + 80 open)
- IAM Task Roles (provided manually)

---

# Task 7 - Strapi Deployment on AWS ECS using Terraform & GitHub Actions

This task demonstrates how to deploy a Strapi application to AWS ECS Fargate using Terraform for infrastructure provisioning and GitHub Actions for CI/CD automation.

---

## Project Structure

```
.
├── .github
│   └── workflows
│       ├── deploy.yml           
│       └── terraform.yml        
├── Dockerfile                   
├── package.json                 
├── package-lock.json
├── terraform                    
│   ├── main.tf                 
│   ├── outputs.tf             
│   ├── terraform.tfvars         
│   └── variables.tf             
```

---

✅ Features
- Infrastructure as Code with Terraform
- CI/CD pipeline via GitHub Actions
- Container deployment to AWS ECS Fargate
- Uses SQLite (no need for external database)
- ECR image build and deployment
- Environment variables managed via Terraform

---

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/strapi-ecs-pipeline.git
cd strapi-ecs-pipeline
```

### 2. Configure GitHub Secrets
In your GitHub repo:

Go to Settings → Secrets and variables → Actions → New repository secret and add the following:

| Secret Name           | Description                          |
|-----------------------|--------------------------------------|
| `DOCKER_USERNAME`     |  JWT Secret for admin panel login    |
| `DOCKER_PASSWORD`     | General auth token signing           |
| `AWS_ACCESS_KEY_ID`   | For Terraform access                 |
| `AWS_SECRET_ACCESS_KEY` | For Terraform access               |

## GitHub Actions Workflows

| Workflow        | Trigger                                       | Description                                |
| --------------- | -----------------                             | ------------------------------------------ |
| `deploy.yml`    | On push to `main`                             | Builds Docker image & pushes to ECR        |
| `terraform.yml` | Successful completion of previous workflow    | Runs `terraform init`, `plan`, and `apply` |

---

## Verification Steps

After deployment is complete, verify the setup:

1. Check ECS Service

  - Go to AWS Console → ECS → Clusters
  - Open the created cluster
  - Ensure a task is running and healthy under the service

2. Check Load Balancer

  - Go to AWS Console → EC2 → Load Balancers
  - Copy the DNS name of the Application Load Balancer
  - Open it in a browser (http://<ALB-DNS>) to access Strapi

3. Check CloudWatch Logs

  - Go to AWS Console → CloudWatch → Log groups
  - Confirm logs are being collected from the ECS Task

4. Login to Strapi Admin
  
  - If first time: You'll see a registration form to create an admin
  - After setup: Access /admin for CMS dashboard

---

## Notes:

 -  This deployment uses SQLite — no external DB setup needed.
 -  Your ECS Task Definition mounts the SQLite .tmp/data.db file inside the container.
 -  Ideal for quick deployments, PoCs, or minimal infra setups.

---

## Author

**Aviral Mehndiratta**   
Intern @ PearlThoughts DevOps Program  
Location: Jaipur, Rajasthan