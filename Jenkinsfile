pipeline {
    agent any

    environment {
        SONAR_HOST_URL = "http://<SONAR_PRIVATE_IP>:9000"
        NEXUS_DOCKER_REGISTRY = "<NEXUS_PRIVATE_IP>:8083"
        IMAGE_NAME = "devops-demo"
        IMAGE_TAG = "latest"
        EC2_HOST = "<EC2_PRIVATE_IP>"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/<your-username>/devops-demo-app.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                    mvn clean verify sonar:sonar \
                    -Dsonar.projectKey=devops-demo \
                    -Dsonar.host.url=${SONAR_HOST_URL} \
                    -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${NEXUS_DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Push Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-docker',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS')]) {

                    sh """
                    docker login ${NEXUS_DOCKER_REGISTRY} -u ${NEXUS_USER} -p ${NEXUS_PASS}
                    docker push ${NEXUS_DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy on EC2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER')]) {

                    sh """
                    ssh -o StrictHostKeyChecking=no -i $SSH_KEY $SSH_USER@${EC2_HOST} '
                    docker pull ${NEXUS_DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker stop devops-demo || true
                    docker rm devops-demo || true
                    docker run -d --name devops-demo ${NEXUS_DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    '
                    """
                }
            }
        }
    }
}

