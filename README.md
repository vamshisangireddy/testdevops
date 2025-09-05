# testdevops Project

This project contains the necessary configurations for a CI/CD pipeline using Jenkins to build, test, and deploy an application to Kubernetes.

## Prerequisites

Before you begin, ensure you have the following tools installed on your local machine:

- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- A local Kubernetes cluster, such as:
  - [Minikube](https://minikube.sigs.k8s.io/docs/start/)
  - [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)

## Getting Started

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/vamshisangireddy/testdevops.git
    cd testdevops
    ```

2.  **Start your local Kubernetes cluster:**

    For Minikube:
    ```sh
    minikube start
    ```

3.  **Run the application:**

    *(Add steps here on how to apply the Kubernetes manifests and run the application. For example:)*
    ```sh
    # Apply all Kubernetes configurations
    kubectl apply -f k8s/
    ```

## Jenkins Pipeline

This repository contains a `Jenkinsfile` that defines the CI/CD pipeline. To test it, you can set up a new pipeline job in your Jenkins instance and point it to this repository.