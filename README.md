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
