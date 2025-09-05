pipeline {
    agent any

    environment {
        // Use Jenkins Credentials plugin to store your AWS credentials
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_REGION            = 'us-east-1' // Change to your preferred region
        ECR_REGISTRY          = "YOUR_AWS_ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPOSITORY        = 'order-service'
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
                    // Build the Docker image from the order-service directory
                    docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}", "./order-service")
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // Login to ECR and push the image
                    // The withRegistry block handles Docker login and logout
                    docker.withRegistry("https://${ECR_REGISTRY}", 'ecr:aws-us-east-1:aws-credentials') {
                        docker.image("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}").push()
                    }
                }
            }
        }

        stage('Provision Infrastructure') {
            steps {
                // This stage is often run manually or less frequently.
                // For a full end-to-end demo, we include it here.
                sh 'terraform -chdir=terraform init'
                sh 'terraform -chdir=terraform apply -auto-approve'
            }
        }

        stage('Configure K8s Cluster') {
            steps {
                // Wait for SSH to be available on new instances
                sh 'sleep 60'
                // Run Ansible to setup K8s
                sh 'ansible-playbook -i terraform/inventory.ini ansible/playbook.yml'
            }
        }

        stage('Deploy to K8s') {
            steps {
                script {
                    // We need to get the kubeconfig from the master node
                    // This is a simplified approach. A better way is to store the kubeconfig securely.
                    sh 'scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa_k8s ubuntu@$(terraform -chdir=terraform output -raw k8s_master_public_ip):~/.kube/config ./kubeconfig'
                    
                    // Replace placeholder in K8s manifest and apply
                    sh "sed -i 's|IMAGE_PLACEHOLDER|${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}|g' k8s/order-service-deployment.yml"
                    sh "KUBECONFIG=./kubeconfig kubectl apply -f k8s/order-service-deployment.yml"
                    sh "KUBECONFIG=./kubeconfig kubectl apply -f k8s/order-service-service.yml"
                    sh "KUBECONFIG=./kubeconfig kubectl apply -f k8s/postgres-deployment.yml"
                }
            }
        }
    }
}