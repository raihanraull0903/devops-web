pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'raihan999/devops-web'
        IMAGE_TAG = "${env.GIT_COMMIT.substring(0, 7)}"
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh '''
                    echo "================================"
                    echo "Testing DevOps Web..."
                    echo "================================"

                    test -f index.html
                    test -f style.css
                    test -f Dockerfile

                    echo "Test passed!"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    echo "================================"
                    echo "Building Docker Image..."
                    echo "================================"

                    docker build \
                        -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                        .
                '''
            }
        }

        stage('Docker Push') {
            steps {
                sh '''
                    echo "================================"
                    echo "Pushing Docker Image..."
                    echo "================================"

                    echo "$DOCKER_CREDENTIALS_PSW" | docker login \
                        -u "$DOCKER_CREDENTIALS_USR" \
                        --password-stdin

                    docker push ${DOCKER_IMAGE}:${IMAGE_TAG}

                    docker tag \
                        ${DOCKER_IMAGE}:${IMAGE_TAG} \
                        ${DOCKER_IMAGE}:latest

                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    echo "================================"
                    echo "Deploying with Ansible..."
                    echo "================================"

                    ansible-playbook \
                        -i /home/ubuntu/devops-project/ansible/inventory.ini \
                        /home/ubuntu/devops-project/ansible/deploy-web.yml \
                        -e "docker_image=${DOCKER_IMAGE}:${IMAGE_TAG}"

                    echo "================================"
                    echo "Deployment completed!"
                    echo "================================"
                '''
            }
        }
    }

    post {
        success {
            echo '================================'
            echo 'CI/CD PIPELINE SUCCESS!'
            echo '================================'
            echo "Docker Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
        }

        failure {
            echo '================================'
            echo 'CI/CD PIPELINE FAILED!'
            echo '================================'
        }
    }
}
