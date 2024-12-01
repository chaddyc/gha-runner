# GitHub Actions Runner Docker

This guide provides detailed instructions for setting up a self-hosted GitHub Actions Runner using Docker. You can choose to run the container with `docker run` or `docker-compose`.

## Prerequisites

Before starting, ensure you have the following:

1. **Docker Installed**  
   Ensure Docker is installed and running on your system. You can follow the [official installation guide](https://docs.docker.com/get-docker/) for help.

2. **Docker Compose (Optional)**  
   If using `docker-compose`, ensure it is installed. You can find installation instructions in the [official Docker Compose guide](https://docs.docker.com/compose/install/).

3. **GitHub Runner Token**  
   - Go to your GitHub repository or organization.  
   - Navigate to **Settings > Actions > Runners**.
   - Click **Add Runner** and copy the registration token provided.

---

## Steps to Set Up the GitHub Actions Runner With Docker

You can set up the runner using either `docker run` or `docker-compose`. Choose the method that suits your setup.

1. **Docker Run**
   ```bash
   docker run -d \
    -e GITHUB_URL=https://github.com/<your-org-or-repo> \
    -e RUNNER_TOKEN=<your-runner-token> \
    --name <container-name> \
    chaddyc/gha-runner:latest
   ```

2. **Docker Compose**
   ```yaml
   services:
    github-runner:
        image: chaddyc/gha-runner:latest
        container_name: <container-name>
        environment:
        - GITHUB_URL=https://github.com/<your-org-or-repo>
        - RUNNER_TOKEN=<your-runner-token>
        restart: unless-stopped
   ```

3. **Docker Compose - Multi Containers**
   ```yaml
   services:
    github-runner:
        image: chaddyc/gha-runner:latest
        #container_name: <container-name>
        #don't use container name when deploying multi replica containers of your gha-runner
        deploy:
          mode: replicated
          replicas: 2
        environment:
          - GITHUB_URL=https://github.com/<your-org-or-repo>
          - RUNNER_TOKEN=<your-runner-token>
        restart: unless-stopped

## License

[MIT](LICENSE)


