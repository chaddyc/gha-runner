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

## Steps to Set Up the GitHub Actions Runner With Docker

You can set up the runner using either `docker run` or `docker-compose`. Choose the method that suits your setup.

1. **Docker Run**
   ```bash
   docker run -d \
    -e GITHUB_URL=https://github.com/<your-org-or-repo> \
    -e RUNNER_TOKEN=<your-runner-token> \
    -e RUNNER_NAME=<your-runner-name> \
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
        - RUNNER_NAME=<your-runner-name>
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
          - RUNNER_NAME=<your-runner-name>
        restart: unless-stopped
   ```

4. **Kubernetes Deployment**

   Create a new kubernetes secret for your Github Actions Runner Token like in the example below:

   ```bash
   kubectl create secret generic gha-runner-secret \
     --from-literal=RUNNER_TOKEN=<your-runner-token>
   ```

   Create a kubernetes deployment `yaml` and call it `gha-runner-deployment.yml` and copy the below yaml file and update where needed such as the `image tag` if using a `specific version` other than `latest`:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
   name: gha-runner-deployment
   labels:
      app: gha-runner
   spec:
   replicas: 1  # Number of runner instances
   selector:
      matchLabels:
         app: gha-runner
   template:
      metadata:
         labels:
         app: gha-runner
      spec:
         containers:
         - name: gha-runner
            image: chaddyc/gha-runner:latest  # Replace Docker image tag if not going to use latest
            imagePullPolicy: IfNotPresent
            env:
               - name: GITHUB_URL
               value:  "https://github.com/<your-org-or-repo>" # Replace with your GitHub URL org or repo
               - name: RUNNER_NAME
               value:  "<your-runner-name>" # Name you want to give your runner
               - name: RUNNER_TOKEN # pull runner token from secret value created
               valueFrom:
                  secretKeyRef:
                     name: gha-runner-secret  # Kubernetes Secret name
                     key: RUNNER_TOKEN      # Key in the secret holding the token
            resources:
               limits:
               cpu: "4"
               memory: "8Gi"
               requests:
               cpu: "2"
               memory: "4Gi"
   ```

   Run the below command to create your deployment - ensure that you are in the correct `namespace` where you want to deploy your runner:
   
   ```bash
   kubectl apply -f gha-runner-deployment.yml
   ```


