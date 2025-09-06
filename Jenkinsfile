pipeline {
    agent any
    triggers {
        // This makes the pipeline responsive to GitHub push events.
        // It relies on a companion configuration in the Jenkins job settings.
        githubPush()
    }
    environment {
        
        PATH = "/usr/local/bin:${env.PATH}"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = 'DOCKERHUB_CREDENTIALS_USR'
        DOCKERHUB_PASSWORD = 'DOCKERHUB_CREDENTIALS_PSW'
        // The build number is used to tag the Docker images
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    //tools {
     //   terraform 'terraform-1.6.5' // Assumes a Terraform tool configured in Jenkins
    //}

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
                dir('terraform') {
                    sh 'terraform init'
                    // You need to pass your AWS key pair name.
                    // It's recommended to manage the terraform.tfvars file securely.
                    // For this example, we create it on the fly.
                    sh 'echo \'aws_key_name = "your-aws-key-pair-name"\' > terraform.tfvars'
                    sh 'terraform apply -auto-approve -var-file=terraform.tfvars'
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

                        sed -e "s/\\${k8s_master_public_ip}/$MASTER_IP/" \\
                            -e "s/\\${k8s_worker_1_public_ip}/$WORKER_1_IP/" \\
                            -e "s/\\${k8s_worker_2_public_ip}/$WORKER_2_IP/" \\
                            inventory.ini > inventory.ini.tmp && mv inventory.ini.tmp inventory.ini
                    '''
                    // You'll need to add your SSH private key to the Jenkins agent
                    // and reference it here, or use the SSH Agent plugin.
                    ansiblePlaybook(
                        playbook: 'playbook.yml',
                        inventory: 'inventory.ini',
                        credentialsId: 'your-ssh-private-key-credential-id'
                    )
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh """
                    sed -i 's|image: .*|image: ${DOCKERHUB_USERNAME}/user-service:${IMAGE_TAG}|' k8s/user-service.yaml
                    sed -i 's|image: .*|image: ${DOCKERHUB_USERNAME}/product-service:${IMAGE_TAG}|' k8s/product-service.yaml
                    sed -i 's|image: .*|image: ${DOCKERHUB_USERNAME}/order-service:${IMAGE_TAG}|' k8s/order-service.yaml
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
    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
        def customImage = docker.build("${imageName}:${IMAGE_TAG}", "-f ${dockerfile} ${context}")
        customImage.push()
        // Also push the 'latest' tag
        customImage.push('latest')
    }
}