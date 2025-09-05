# Microservices Project with AWS, EC2, PostgreSQL, and Docker

This project is a sample microservices architecture consisting of three services: User Service, Product Service, and Order Service.

The services are built with Python (Flask), containerized with Docker, and designed to be deployed on AWS. The database is PostgreSQL, configured to run in a Docker container on an EC2 instance.

## Project Structure

```
/
├── docker-compose.yml      # For local orchestration
├── user-service/           # User microservice
├── product-service/        # Product microservice
└── order-service/          # Order microservice
```

Each service directory contains its own `Dockerfile` and source code.

## Local Development

### Prerequisites

- Docker
- Docker Compose

### Running the Services

1.  Clone the repository.
2.  Navigate to the project root directory.
3.  Run the following command to build and start all services:

    ```bash
    docker-compose up --build
    ```

### Endpoints

Once running, the services will be available at:

- **User Service**: `http://localhost:5001/users`
- **Product Service**: `http://localhost:5002/products`
- **Order Service**: `http://localhost:5003/orders`

The local PostgreSQL database is exposed on `localhost:5432`.

## AWS Deployment

A high-level guide for deploying to AWS is as follows:

1.  **Database**: Launch an EC2 instance, install Docker, and run a PostgreSQL container. Ensure the security group allows traffic on port 5432 from your services.
2.  **Container Registry**: Build Docker images for each service and push them to Amazon ECR.
3.  **Orchestration**: Use Amazon ECS to deploy the containers.
    - Create an ECS Cluster.
    - Create a Task Definition for each service, pointing to the ECR image and providing the database connection details as environment variables.
    - Create a Service for each Task Definition to manage the running containers.
4.  **Networking**: Use an Application Load Balancer to route external traffic to the correct service based on path or subdomain.