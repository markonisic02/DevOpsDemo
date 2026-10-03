# DevOps .NET Deployment Demo

A DevOps-focused project demonstrating containerization, service orchestration, reverse proxying, CI concepts, and Kubernetes deployment of a .NET 8 REST API backed by Microsoft SQL Server.

The project started as a simple ASP.NET Core API and was extended to demonstrate a complete local deployment workflow using Docker, Nginx, Docker Compose, Azure DevOps Pipelines, and Kubernetes.

## Tech Stack

- ASP.NET Core / .NET 8
- Microsoft SQL Server
- Entity Framework Core
- Docker
- Docker Compose
- Nginx
- Kubernetes
- Minikube
- Azure DevOps Pipelines
- Git

## Architecture

### Docker Compose

```text
Client
  |
  v
Nginx :80
  |
  v
.NET API :8080
  |
  v
SQL Server :1433
  |
  v
Docker Volume
```

Nginx acts as the public entry point while the API and database remain on the internal Docker network.

The SQL Server data is stored in a named Docker volume so that application data persists even when containers are recreated.

### Kubernetes

```text
                API Service
               /           \
              v             v
         API Pod 1      API Pod 2
              \             /
               \           /
                v         v
                 DB Service
                     |
                     v
              SQL Server Pod
                     |
                     v
           PersistentVolumeClaim
```

The Kubernetes deployment includes:

- Two API replicas
- Internal ClusterIP services
- Kubernetes DNS-based service discovery
- Persistent SQL Server storage
- ConfigMap-based application configuration
- Kubernetes Secrets for sensitive values
- Readiness probes
- Liveness probes
- Automatic Pod replacement through Deployments

## Docker

The API uses a multi-stage Docker build.

The first stage uses the .NET SDK to restore and publish the application, while the final image contains only the ASP.NET runtime and published application.

This keeps the runtime image smaller and avoids including unnecessary build tooling.

Build the API image:

```bash
docker build -t devopsdemo-api .
```

Start the complete Docker Compose environment:

```bash
docker compose up --build
```

The application is available through Nginx at:

```text
http://localhost:8081/swagger
```

## Environment Configuration

Create a local `.env` file:

```env
DB_PASSWORD=your_strong_password
```

The `.env` file is excluded from Git.

An `.env.example` file is included to document the required environment variable without exposing credentials.

## Nginx

Nginx is used as a reverse proxy in front of the API.

External traffic reaches Nginx first and is forwarded to the API through Docker's internal network.

This architecture provides a central point where features such as TLS termination, routing, load balancing, rate limiting, or security headers could later be implemented.

## Kubernetes

The Kubernetes manifests are located in the `k8s/` directory.

### Local Cluster

This project was tested using Minikube with the Docker driver.

```bash
minikube start --driver=docker
```

Create the namespace:

```bash
kubectl apply -f k8s/namespace.yaml
```

Load the local API image into Minikube:

```bash
minikube image load devopsdemo-api:latest
```

### Secrets

Database credentials are intentionally not stored in the repository.

Create the SQL Server secret locally:

```bash
kubectl create secret generic mssql-secret \
  --namespace devopsdemo \
  --from-literal=SA_PASSWORD='your_strong_password'
```

Create the API database connection secret:

```bash
kubectl create secret generic api-secret \
  --namespace devopsdemo \
  --from-literal='ConnectionStrings__DefaultConnection=Server=db,1433;Database=DevOpsDemoDB;User Id=sa;Password=your_strong_password;TrustServerCertificate=True'
```

### Deploy

Apply the Kubernetes manifests:

```bash
kubectl apply -f k8s/
```

Check the deployed resources:

```bash
kubectl get pods -n devopsdemo
kubectl get services -n devopsdemo
kubectl get pvc -n devopsdemo
```

For local access:

```bash
kubectl port-forward -n devopsdemo service/api 8082:8080
```

Swagger:

```text
http://localhost:8082/swagger
```

Health endpoint:

```text
http://localhost:8082/health
```

## Kubernetes Reliability

The API Deployment runs two replicas.

If an API Pod is deleted or fails, Kubernetes automatically creates a replacement to restore the desired replica count.

The SQL Server database uses a PersistentVolumeClaim, allowing database data to survive Pod recreation.

The project also uses:

### Readiness Probe

Determines whether an API Pod is ready to receive traffic.

### Liveness Probe

Determines whether the application is healthy or whether Kubernetes should restart the container.

Both probes currently use:

```text
/health
```

## CI Pipeline

The Azure DevOps pipeline runs on Ubuntu and performs:

1. Repository checkout
2. .NET 8 SDK setup
3. Dependency restore
4. Application build
5. Application publish
6. Docker image build
7. Docker image validation
8. Docker Compose configuration validation
9. Build artifact publication

The pipeline automatically validates both the application build and container configuration.

## API

The demo API provides basic product management endpoints.

Example product:

```json
{
  "name": "Mechanical Keyboard",
  "price": 99.99,
  "quantity": 5
}
```

Available operations include:

```text
GET  /api/Products
POST /api/Products
```

## What I Learned

Through this project I practiced:

- Building multi-stage Docker images
- Managing multi-container environments with Docker Compose
- Configuring container networking and service discovery
- Using environment variables for application configuration
- Persisting database data outside the container lifecycle
- Configuring Nginx as a reverse proxy
- Deploying applications to Kubernetes
- Working with Deployments, Services, ConfigMaps and Secrets
- Using PersistentVolumeClaims
- Scaling API workloads horizontally
- Understanding Kubernetes self-healing behavior
- Configuring readiness and liveness probes
- Troubleshooting containers and Kubernetes resources using logs and inspection tools

## Project Structure

```text
DevOpsDemo/
|
|-- DevOpsDemo/              # ASP.NET Core application
|-- k8s/                     # Kubernetes manifests
|-- nginx/
|   `-- default.conf         # Nginx reverse proxy configuration
|
|-- Dockerfile
|-- docker-compose.yml
|-- .dockerignore
|-- .env.example
|-- azure-pipelines-1.yml
`-- README.md
```
