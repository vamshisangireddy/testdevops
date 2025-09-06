pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        // Correct way to use credentials in Jenkins
        // This makes the DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD environment variables available
        // as strings from the credential item 'dockerhub-credentials'.
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = DOCKERHUB_CREDENTIALS.get('username')
        DOCKERHUB_PASSWORD = DOCKERHUB_CREDENTIALS.get('password')
        
        // The build number is used to tag the Docker images
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Push Images') {
            parallel {
                stage('User Service') {
                    steps {
                        script {
                            def imageName = "${DOCKERHUB_USERNAME}/user-service"
                            def dockerfile = 'user-service/Dockerfile'
                            def context = 'user-service'
                            buildAndPush(imageName, dockerfile, context)
                        }
                    }
                }
                stage('Product Service') {
                    steps {
                        script {
                            def imageName = "${DOCKERHUB_USERNAME}/product-service"
                            def dockerfile = 'product-service/Dockerfile'
                            def context = 'product-service'
                            buildAndPush(imageName, dockerfile, context)
                        }
                    }
                }
                stage('Order Service') {
                    steps {
                        script {
                            def imageName = "${DOCKERHUB_USERNAME}/order-service"
                            def dockerfile = 'order-service/Dockerfile'
                            def context = 'order-service'
                            buildAndPush(imageName, dockerfile, context)
                        }
                    }
                }
            }
        }
        
        stage('Provision Infrastructure') {
            steps {
                script {
                    // Use a try/finally block for cleanup to prevent dangling resources
                    try {
                        dir('terraform') {
                            sh 'terraform init'
                            // Use a more secure way to manage variables, e.g., with credentials or Jenkins secrets
                            // For this example, we'll write it on the fly.
                            sh 'echo \'aws_key_name = "your-aws-key-pair-name"\' > terraform.tfvars'
                            sh 'terraform apply -auto-approve -var-file=terraform.tfvars'
                        }
                    } finally {
                        // This block will run even if terraform apply fails.
                        dir('terraform') {
                            sh 'terraform destroy -auto-approve -var-file=terraform.tfvars'
                        }
                    }
                }
            }
        }

        stage('Configure K8s Cluster') {
            steps {
                dir('ansible') {
                    // Use terraform output to generate ansible inventory
                    sh 'terraform -chdir=../terraform output -json > tf_output.json'
                    sh '''
                        MASTER_IP=$(jq -r .k8s_master_public_ip.value tf_output.json)
                        WORKER_1_IP=$(jq -r .k8s_worker_1_public_ip.value tf_output.json)
                        WORKER_2_IP=$(jq -r .k8s_worker_2_public_ip.value tf_output.json)

                        sed -i.bak -e "s/\\${k8s_master_public_ip}/$MASTER_IP/" \\
                            -e "s/\\${k8s_worker_1_public_ip}/$WORKER_1_IP/" \\
                            -e "s/\\${k8s_worker_2_public_ip}/$WORKER_2_IP/" \\
                            inventory.ini
                    '''
                    // Use the SSH Agent plugin for secure key management
                    sshagent(credentials: ['your-ssh-private-key-credential-id']) {
                        ansiblePlaybook(
                            playbook: 'playbook.yml',
                            inventory: 'inventory.ini',
                            // The credentialsId is now handled by the sshagent block.
                            // Ensure your playbook and ansible.cfg are configured to use agent forwarding.
                            ansibleHostKeyChecking: false, // WARNING: Use with caution in production.
                            vaultCredentialsId: null
                        )
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh """
                    sed -i.bak 's|image: .*|image: ${DOCKERHUB_USERNAME}/user-service:${IMAGE_TAG}|' k8s/user-service.yaml
                    sed -i.bak 's|image: .*|image: ${DOCKERHUB_USERNAME}/product-service:${IMAGE_TAG}|' k8s/product-service.yaml
                    sed -i.bak 's|image: .*|image: ${DOCKERHUB_USERNAME}/order-service:${IMAGE_TAG}|' k8s/order-service.yaml
                    """
                    sh 'kubectl apply -f k8s/user-service.yaml'
                    sh 'kubectl apply -f k8s/product-service.yaml'
                    sh 'kubectl apply -f k8s/order-service.yaml'
                }
            }
        }
    }
}

void buildAndPush(String imageName, String dockerfile, String context) {
    // The credentials are now available as environment variables.
    // The `docker.withRegistry` block will automatically use them.
    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
        def customImage = docker.build("${imageName}:${IMAGE_TAG}", "-f ${dockerfile} ${context}")
        customImage.push()
        // Also push the 'latest' tag
        customImage.push('latest')
    }
}