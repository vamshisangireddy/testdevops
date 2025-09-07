pipeline {
    agent any
    triggers {
        githubPush()
    }
    environment {
        AWS_REGION = 'us-west-1'
        PATH = "/opt/homebrew/bin/:/usr/local/bin:${env.PATH}"
        // The build number is used to tag the Docker images
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    tools {
       terraform 'terraform' // Assumes a Terraform tool configured in Jenkins
       //ansible 'ansible-playbook'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build, Tag, and Push') {
            steps {
                script {
                    // Log in to Docker Hub and set DOCKERHUB_USERNAME
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                        // Set the username environment variable, ensuring it's lowercase for Docker Hub
                        env.DOCKERHUB_USERNAME = DOCKER_USER.toLowerCase()
                        sh 'open -a docker'
                        sh "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USER --password-stdin"

                        // Build all images in parallel.
                        // The DOCKERHUB_USERNAME is now available for docker-compose.
                        sh "docker compose build --parallel"

                        // Push all images to Docker Hub.
                        // docker-compose.yml is now responsible for naming the images correctly.
                        sh "docker compose push"
                    }
                }
            }
        }
        stage('Provision Infrastructure') {
    steps {
        script {
             withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-terraform-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')])
             {
                 // Set AWS Key Name
                 env.AWS_KEY_NAME = "jenkins-terraform" // Ensure this key pair exists in your AWS account

                 // Navigate to the terraform directory and run terraform commands
                dir('terraform') {
                    sh 'terraform init -input=false'
                    sh 'terraform plan -out=tfplan -input=false'
                    sh 'terraform apply -auto-approve'

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

                        sed -e "s/\\${k8s_master_public_ip}/$MASTER_IP/" \\
                            -e "s/\\${k8s_worker_1_public_ip}/$WORKER_1_IP/" \\
                            -e "s/\\${k8s_worker_2_public_ip}/$WORKER_2_IP/" \\
                            inventory.ini > inventory.ini.tmp && mv inventory.ini.tmp inventory.ini
                    '''
                    sh "echo 'Inventory file:' && cat inventory.ini"
                    // You'll need to add your SSH private key to the Jenkins agent
                    // and reference it here, or use the SSH Agent plugin.
                    sh'''
                    /opt/homebrew/bin/ansible-playbook \
                    -i inventory.ini playbook.yml \
                    --private-key /Users/vamshisangireddy/.jenkins/workspace/testdev/ansible/ssh13068254442594307973.key \
                    -u ubuntu'''
                }
            }
        }
    }
}
