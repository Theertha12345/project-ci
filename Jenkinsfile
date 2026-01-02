pipeline {
    agent any

    environment {
        NEXUS_DOCKER_REGISTRY = "172.31.3.63:8083"
        IMAGE_NAME = "devops-demo"
        IMAGE_TAG = "latest"
        EC2_HOST = "172.31.8.183"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/Theertha12345/project-ci.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh """
                    mvn clean verify \
                    org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                    -Dsonar.projectKey=devops-demo
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
                sh 'mvn package'
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
                withCredentials([usernamePassword(
                        credentialsId: 'nexus-docker',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh """
                    docker login ${NEXUS_DOCKER_REGISTRY} -u ${NEXUS_USER} -p ${NEXUS_PASS}
                    docker push ${NEXUS_DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy on EC2') {
            steps {
                withCredentials([sshUserPrivateKey(
                        credentialsId: 'ec2-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                )]) {
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
