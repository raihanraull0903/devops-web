pipeline {

    agent any

    environment {
        DOCKER_USERNAME = 'raihan999'
        IMAGE_NAME = 'raihan999/devops-web'
        ANSIBLE_DIR = '/home/ubuntu/devops-project/ansible'
        INVENTORY = '/home/ubuntu/devops-project/ansible/inventory.ini'
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
                    echo "Testing DevOps Web..."

                    test -f index.html
                    test -f style.css
                    test -f Dockerfile

                    echo "Tests passed"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.NEW_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"

                    echo "New image: ${NEW_IMAGE}"

                    sh """
                        docker build -t ${NEW_IMAGE} .
                    """
                }
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                            -u "$DOCKER_USER" \
                            --password-stdin

                        docker push "$NEW_IMAGE"
                    '''
                }
            }
        }

        stage('Get Current Production Image') {
            steps {
                script {
                    env.PREVIOUS_IMAGE = sh(
                        script: """
                            sudo -u jenkins ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/get-current-image.yml
                        """,
                        returnStdout: true
                    ).readLines()
                    .findAll { it.contains('Current production image:') }
                    .collect { it.replace('Current production image:', '').trim() }
                    .last()

                    echo "Previous production image: ${PREVIOUS_IMAGE}"
                }
            }
        }

        stage('Deploy') {
            steps {
                sh """
                    sudo -u jenkins ansible-playbook \
                    -i ${INVENTORY} \
                    ${ANSIBLE_DIR}/deploy-web.yml \
                    -e "image_tag=${IMAGE_TAG}"
                """
            }
        }

        stage('Health Check') {
            steps {
                script {
                    try {
                        sh """
                            sudo -u jenkins ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/health-check.yml
                        """
                    } catch (Exception e) {
                        echo "Health check FAILED!"
                        echo "Starting automatic rollback..."

                        sh """
                            sudo -u jenkins ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/rollback-web.yml \
                            -e "rollback_tag=${PREVIOUS_IMAGE.split(':')[-1]}"
                        """

                        error("Deployment failed. Automatic rollback completed.")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "======================================"
            echo "DEPLOYMENT SUCCESSFUL"
            echo "Image: ${NEW_IMAGE}"
            echo "======================================"
        }

        failure {
            echo "======================================"
            echo "PIPELINE FAILED"
            echo "Check the logs above."
            echo "======================================"
        }

        always {
            sh '''
                docker logout || true
            '''
        }
    }
}
