# gha-runner-docker
GitHub Actions Runner Docker Container

docker run -e GITHUB_URL=https://github.com/<your-org-or-repo> \
           -e RUNNER_TOKEN=<your-runner-token> \
           --name <container-name>
           github-runner

# GitHub Actions Runner with Docker

This guide provides instructions for setting up a self-hosted GitHub Actions Runner using Docker. You can run the container with either `docker run` or `docker-compose`.

---

## Prerequisites

1. **Install Docker**  
   Ensure Docker is installed and running on your system. Follow the [official installation guide](https://docs.docker.com/get-docker/) if needed.

2. **Install Docker Compose (Optional)**  
   If using `docker-compose`, ensure it is installed. You can follow the [official guide](https://docs.docker.com/compose/install/) to set it up.

3. **Generate a Runner Token**  
   - Go to your GitHub repository or organization.  
   - Navigate to **Settings > Actions > Runners**.  
   - Click **Add Runner** and copy the registration token provided.

---

## Using `docker run`

1. **Build the Docker Image**
   ```bash
   docker build -t github-runner .
