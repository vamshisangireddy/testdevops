pipeline {
    agent any
    triggers { githubPush() }

    environment {
        AWS_REGION = 'us-west-1'
        PATH = "/opt/homebrew/bin/:/usr/local/bin:${env.PATH}"
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    tools {
        terraform 'terraform'
        ansible 'ansible'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build, Tag, and Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                                      usernameVariable: 'DOCKER_USER',
                                                      passwordVariable: 'DOCKER_PASSWORD')]) {
                        env.DOCKERHUB_USERNAME = DOCKER_USER.toLowerCase()
                        sh 'open -a docker || true'
                        sh "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker compose build --parallel"
                        sh "docker compose push"
                    }
                }
            }
        }

        stage('Provision Infrastructure') {
            steps {
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                         credentialsId: 'aws-terraform-creds',
                                         secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        env.AWS_KEY_NAME = "jenkins-terraform"
                        dir('terraform') {
                            sh 'terraform init -input=false'
                            sh "terraform apply -auto-approve -var aws_key_name=$AWS_KEY_NAME"
                        }
                    }
                }
            }
        }

        stage('Configure K8s Cluster') {
            steps {
                dir('ansible') {
                    sh 'terraform -chdir=../terraform output -json > tf_output.json'
                    sh '''
                        MASTER_IP=$(jq -r .k8s_master_public_ip.value tf_output.json)
                        WORKER_1_IP=$(jq -r .k8s_worker_1_public_ip.value tf_output.json)
                        WORKER_2_IP=$(jq -r .k8s_worker_2_public_ip.value tf_output.json)

                        sed -e "s/\\${k8s_master_public_ip}/$MASTER_IP/" \
                            -e "s/\\${k8s_worker_1_public_ip}/$WORKER_1_IP/" \
                            -e "s/\\${k8s_worker_2_public_ip}/$WORKER_2_IP/" \
                            inventory.ini > inventory.ini.tmp && mv inventory.ini.tmp inventory.ini
                    '''
                    ansiblePlaybook credentialsId: 'jenkins-ssh-key', disableHostKeyChecking: true, installation: 'ansible', inventory: 'inventory.ini', playbook: 'playbook.yml'

                }
            }
        }
        stage('Deploy to K8s') {
            steps {
                script {
                    dir('k8s') {
                        sh "sed -i '' 's|image:.*|image: ${env.DOCKERHUB_USERNAME}/testdevops:user-service-${env.IMAGE_TAG}|' user-service.yaml"
                        sh "sed -i '' 's|image:.*|image: ${env.DOCKERHUB_USERNAME}/testdevops:product-service-${env.IMAGE_TAG}|' product-service.yaml"
                        sh "sed -i '' 's|image:.*|image: ${env.DOCKERHUB_USERNAME}/testdevops:order-service-${env.IMAGE_TAG}|' order-service.yaml"
                        sh 'kubectl apply -f . --validate=false'
                    }
                }
            }
        }
    }
    }

