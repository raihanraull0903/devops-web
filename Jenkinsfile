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
                        -t ${DOCKER_IMAGE}:latest .

                    echo ""
                    echo "Docker build completed!"
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

                        docker push ${DOCKER_IMAGE}:latest

                        docker logout

                        echo ""
                        echo "Docker push completed!"
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
                        /opt/devops-ansible/deploy-web.yml

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
            echo 'Website successfully deployed.'
        }

        failure {
            echo '================================'
            echo 'CI/CD PIPELINE FAILED!'
            echo '================================'
            echo 'Please check the Jenkins console output.'
        }
    }
}
