pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'raihan999/devops-web'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Version') {
            steps {
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Docker Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                }
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

                    echo ""
                    echo "Website content:"
                    grep "<h1>" index.html

                    echo ""
                    echo "All tests passed!"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    echo "================================"
                    echo "Building Docker Image..."
                    echo "================================"

                    docker build --no-cache \
                        -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                        -t ${DOCKER_IMAGE}:latest .

                    echo ""
                    echo "Built images:"
                    docker images ${DOCKER_IMAGE}
                '''
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "================================"
                        echo "Pushing Image to Docker Hub..."
                        echo "================================"

                        echo "$DOCKER_PASSWORD" | docker login \
                            -u "$DOCKER_USERNAME" \
                            --password-stdin

                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest

                        docker logout

                        echo ""
                        echo "Pushed:"
                        echo "${DOCKER_IMAGE}:${IMAGE_TAG}"
                        echo "${DOCKER_IMAGE}:latest"
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    echo "================================"
                    echo "Deploying with Ansible..."
                    echo "================================"

                    ansible-playbook \
                        -i /opt/devops-ansible/inventory.ini \
                        /opt/devops-ansible/deploy-web.yml \
                        -e "docker_image=${DOCKER_IMAGE}:${IMAGE_TAG}"

                    echo ""
                    echo "Deployment completed!"
                '''
            }
        }
    }

    post {
        success {
            echo '================================'
            echo 'CI/CD PIPELINE SUCCESS!'
            echo '================================'
            echo "Deployed version: ${IMAGE_TAG}"
        }

        failure {
            echo '================================'
            echo 'CI/CD PIPELINE FAILED!'
            echo '================================'
        }
    }
}
