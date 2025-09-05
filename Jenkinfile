pipeline {
    agent any

    // Parameters make the pipeline reusable for all your microservices.
    parameters {
        string(name: 'SERVICE_NAME', defaultValue: 'order-service', description: 'The name of the microservice to build and deploy (e.g., order-service, product-service)')
    }

    environment {
        // Use a single credential ID for AWS.
        // Note: It's even better to scope these inside the stages that need them.
        AWS_CREDENTIALS_ID    = 'aws-credentials' // The ID you created in Jenkins
        AWS_REGION            = 'us-east-1'
        ECR_REGISTRY          = "YOUR_AWS_ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com" // Replace with your AWS Account ID
        ECR_REPOSITORY        = "${params.SERVICE_NAME}"
        IMAGE_TAG             = "v${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image from the directory matching the service name
                    docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}", "./${params.SERVICE_NAME}")
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // Login to ECR and push the image
                    // The withRegistry block uses the specified AWS credentials for ECR login
                    docker.withRegistry("https://${ECR_REGISTRY}", "ecr:${AWS_REGION}:${AWS_CREDENTIALS_ID}") {
                        docker.image("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}").push()
                    }
                }
            }
        }

        // It's best practice to separate infrastructure provisioning into its own pipeline.
        // This stage is left here as an example but could be removed from the main CI/CD flow.
        stage('Provision Infrastructure') {
            when { expression { false } } // Disable by default to prevent running on every commit
            steps {
                withCredentials([aws(credentialsId: AWS_CREDENTIALS_ID)]) {
                    // AWS credentials are automatically available as environment variables here
                    sh 'terraform -chdir=terraform init'
                    sh 'terraform -chdir=terraform apply -auto-approve'
                }
            }
        }

        stage('Configure K8s Cluster') {
            when { expression { false } } // Disable by default
            steps { /* ... ansible steps ... */ }
        }

        stage('Deploy to K8s') {
            steps {
                // Use the 'Secret file' credential for kubeconfig. This is the secure way.
                withCredentials([file(credentialsId: 'kubeconfig-file', variable: 'KUBECONFIG_PATH')]) {
                    script {
                        def deploymentFile = "k8s/${params.SERVICE_NAME}-deployment.yml"
                        def serviceFile = "k8s/${params.SERVICE_NAME}-service.yml"

                        // Replace the placeholder image in the correct deployment file
                        // Note the change from IMAGE_PLACEHOLDER to the actual placeholder in your YAMLs
                        sh "sed -i 's|your-repo/${params.SERVICE_NAME}:latest|${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}|g' ${deploymentFile}"

                        // Apply the Kubernetes manifests using the secure kubeconfig file
                        sh "KUBECONFIG=${KUBECONFIG_PATH} kubectl apply -f ${deploymentFile}"
                        sh "KUBECONFIG=${KUBECONFIG_PATH} kubectl apply -f ${serviceFile}"
                    }
                }
            }
        }
    }
}