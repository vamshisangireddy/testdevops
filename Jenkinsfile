pipeline {
    agent any
    triggers {
        githubPush()
    }
    environment {
        AWS_REGION = 'us-west-1'
        PATH = "/usr/local/bin:${env.PATH}"
        // The build number is used to tag the Docker images
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    tools {
       terraform 'terraform' // Assumes a Terraform tool configured in Jenkins
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
            withCredentials([
                [$class: 'AmazonWebServicesCredentialsBinding',
                 credentialsId: 'aws-terraform-creds',
                 accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                 secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                string(credentialsId: 'aws-terraform-creds', variable: 'AWS_KEY_NAME')
            ]) {
                dir('terraform') {
                    sh 'terraform init -input=false'

                    // write terraform.tfvars
                    sh """
                    cat > terraform.tfvars <<EOF
                    aws_region   = "us-west-1"
                    aws_key_name = "${AWS_KEY_NAME}"
                    EOF
                    """

                    sh 'terraform apply -auto-approve -var-file=terraform.tfvars'
                }
            }
        }
    }
}



    }
}