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
                    echo "======================================"
                    echo "Testing DevOps Web"
                    echo "======================================"

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

                    echo "======================================"
                    echo "Docker Build"
                    echo "Image: ${NEW_IMAGE}"
                    echo "======================================"

                    sh """
                        docker build \
                        -t ${NEW_IMAGE} \
                        .
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
                        echo "======================================"
                        echo "Docker Hub Login"
                        echo "======================================"

                        echo "$DOCKER_PASSWORD" | docker login \
                            -u "$DOCKER_USER" \
                            --password-stdin

                        echo "Pushing image: $NEW_IMAGE"

                        docker push "$NEW_IMAGE"

                        echo "Docker image pushed successfully"
                    '''
                }
            }
        }

        stage('Get Current Production Image') {
            steps {

                echo "======================================"
                echo "Getting Current Production Image"
                echo "======================================"

                script {

                    def output = sh(
                        script: """
                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/get-current-image.yml
                        """,
                        returnStdout: true
                    ).trim()

                    echo output

                    def match = output =~ /CURRENT_IMAGE=([^\\s"]+)/

                    if (!match.find()) {
                        error("Current production image tidak ditemukan")
                    }

                    env.PREVIOUS_IMAGE = match.group(1).trim()

                    echo "======================================"
                    echo "Previous Production Image:"
                    echo "${PREVIOUS_IMAGE}"
                    echo "======================================"
                }
            }
        }

        stage('Deploy') {
            steps {

                echo "======================================"
                echo "Deploying New Image"
                echo "Image: ${NEW_IMAGE}"
                echo "======================================"

                sh """
                    ansible-playbook \
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

                        echo "======================================"
                        echo "Running Production Health Check"
                        echo "======================================"

                        sh """
                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/health-check.yml
                        """

                        echo "Health check passed."

                        echo "======================================"
                        echo "SIMULATING DEPLOYMENT FAILURE"
                        echo "======================================"

                        error("SIMULATED DEPLOYMENT FAILURE")

                    } catch (Exception e) {

                        echo "======================================"
                        echo "DEPLOYMENT FAILED"
                        echo "======================================"

                        echo "Starting automatic rollback..."

                        def rollbackTag =
                            env.PREVIOUS_IMAGE.tokenize(':')[-1]

                        echo "Rollback target:"
                        echo "${PREVIOUS_IMAGE}"

                        echo "Rollback tag:"
                        echo "${rollbackTag}"

                        sh """
                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/rollback-web.yml \
                            -e "rollback_tag=${rollbackTag}"
                        """

                        echo "======================================"
                        echo "AUTOMATIC ROLLBACK COMPLETED"
                        echo "======================================"

                        echo "Restored image:"
                        echo "${PREVIOUS_IMAGE}"

                        error(
                            "Deployment failed. Automatic rollback completed."
                        )
                    }
                }
            }
        }
    }

    post {

        success {

            echo """
========================================
       DEPLOYMENT SUCCESSFUL
========================================

New image:
${NEW_IMAGE}

Previous image:
${PREVIOUS_IMAGE}

========================================
"""
        }

        failure {

            echo """
========================================
          PIPELINE FAILED
========================================

Automatic rollback was attempted.

Previous production image:
${PREVIOUS_IMAGE}

========================================
"""
        }

        always {

            sh '''
                docker logout || true
            '''
        }
    }
}
