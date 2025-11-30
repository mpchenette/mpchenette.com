# mpchenette.com

## Hello World Docker App

A simple web application that displays "Hello World" and runs in a Docker container.

### Prerequisites

- Docker installed on your system ([Get Docker](https://docs.docker.com/get-docker/))

### Quick Start

1. **Build the Docker image:**
   ```bash
   docker build -t hello-world-app .
   ```

2. **Run the container:**
   ```bash
   docker run -p 3000:3000 hello-world-app
   ```

3. **View the app:**
   Open your browser and navigate to [http://localhost:3000](http://localhost:3000)

### Stop the Container

Press `Ctrl+C` in the terminal, or run:
```bash
docker ps  # Find the container ID
docker stop <container-id>
```

### Run in Detached Mode

To run the container in the background:
```bash
docker run -d -p 3000:3000 --name hello-app hello-world-app
```

Stop it with:
```bash
docker stop hello-app
docker rm hello-app
```

### Files

- [server.js](server.js) - Express.js web server
- [package.json](package.json) - Node.js dependencies
- [Dockerfile](Dockerfile) - Docker configuration
- [.dockerignore](.dockerignore) - Files to exclude from Docker image