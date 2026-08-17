pipeline {

    agent any

    environment {
        DOCKER_IMAGE = "raihan999/devops-web"
        INVENTORY = "/home/ubuntu/devops-project/ansible/inventory.ini"
        ANSIBLE_DIR = "/home/ubuntu/devops-project/ansible"
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
                    set -e

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

                    env.NEW_IMAGE = "${DOCKER_IMAGE}:${IMAGE_TAG}"

                    echo "======================================"
                    echo "Docker Build"
                    echo "Image: ${NEW_IMAGE}"
                    echo "======================================"

                    sh """
                        set -e
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
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    sh """
                        set -e

                        echo "======================================"
                        echo "Docker Hub Login"
                        echo "======================================"

                        echo "\$DOCKER_PASSWORD" | docker login \
                            -u "\$DOCKER_USERNAME" \
                            --password-stdin

                        echo "Pushing image:"
                        echo "${NEW_IMAGE}"

                        docker push ${NEW_IMAGE}

                        echo "Docker image pushed successfully"
                    """
                }
            }
        }

        stage('Get Current Production Image') {
            steps {
                script {

                    echo "======================================"
                    echo "Getting Current Production Image"
                    echo "======================================"

                    def output = sh(
                        script: """
                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/get-current-image.yml
                        """,
                        returnStdout: true
                    ).trim()

                    echo output

                    /*
                     * Mencari:
                     *
                     * CURRENT_IMAGE=raihan999/devops-web:65bebd9
                     *
                     * dan mengambil seluruh image reference.
                     */

                    def matcher = output =~ /CURRENT_IMAGE=(raihan999\\/devops-web:[A-Za-z0-9._-]+)/

                    if (!matcher.find()) {
                        error("Gagal mendapatkan CURRENT_IMAGE dari Ansible")
                    }

                    env.PREVIOUS_IMAGE = matcher.group(1)

                    echo "======================================"
                    echo "Previous Production Image:"
                    echo "${env.PREVIOUS_IMAGE}"
                    echo "======================================"
                }
            }
        }

        stage('Deploy') {
            steps {
                script {

                    try {

                        echo "======================================"
                        echo "Deploying New Image"
                        echo "Image: ${NEW_IMAGE}"
                        echo "======================================"

                        sh """
                            set -e

                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/deploy-web.yml \
                            -e "image_tag=${IMAGE_TAG}"
                        """

                        echo "Deployment completed."

                    } catch (Exception e) {

                        echo "======================================"
                        echo "DEPLOYMENT FAILED"
                        echo "======================================"
                        echo "Starting automatic rollback..."

                        def rollbackTag = env.PREVIOUS_IMAGE.substring(
                            env.PREVIOUS_IMAGE.lastIndexOf(':') + 1
                        )

                        echo "Rollback image:"
                        echo "${env.PREVIOUS_IMAGE}"

                        echo "Rollback tag:"
                        echo "${rollbackTag}"

                        sh """
                            set -e

                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/rollback-web.yml \
                            -e "rollback_tag=${rollbackTag}"
                        """

                        echo "Automatic rollback completed."

                        error("Deployment failed. Rollback completed.")
                    }
                }
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
                            set -e

                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/health-check.yml
                        """

                        echo "======================================"
                        echo "Health Check PASSED"
                        echo "======================================"

                    } catch (Exception e) {

                        echo "======================================"
                        echo "HEALTH CHECK FAILED"
                        echo "======================================"

                        echo "Starting automatic rollback..."

                        def rollbackTag = env.PREVIOUS_IMAGE.substring(
                            env.PREVIOUS_IMAGE.lastIndexOf(':') + 1
                        )

                        echo "Rollback image:"
                        echo "${env.PREVIOUS_IMAGE}"

                        echo "Rollback tag:"
                        echo "${rollbackTag}"

                        sh """
                            set -e

                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/rollback-web.yml \
                            -e "rollback_tag=${rollbackTag}"
                        """

                        echo "======================================"
                        echo "AUTOMATIC ROLLBACK COMPLETED"
                        echo "======================================"

                        error("Health check failed. Rollback completed.")
                    }
                }
            }
        }
    }

    post {

        always {

            sh '''
                docker logout || true
            '''

            echo """
========================================
          PIPELINE FINISHED
========================================

Previous production image:
${PREVIOUS_IMAGE ?: 'Not available'}

New image:
${NEW_IMAGE ?: 'Not available'}

========================================
"""
        }

        success {

            echo """
========================================
       DEPLOYMENT SUCCESSFUL
========================================

Production image:
${NEW_IMAGE}

Health check:
PASSED

========================================
"""
        }

        failure {

            echo """
========================================
          PIPELINE FAILED
========================================

Previous production image:
${PREVIOUS_IMAGE ?: 'Not available'}

Automatic rollback:
Attempted

========================================
"""
        }
    }
}
