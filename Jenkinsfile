pipeline {

    agent any

    environment {
        DOCKER_IMAGE = "raihan999/devops-web"
        INVENTORY = "/home/ubuntu/devops-project/ansible/inventory.ini"
        ANSIBLE_DIR = "/home/ubuntu/devops-project/ansible"
        // Inisialisasi awal agar bagian 'post' tidak crash saat pipeline gagal di awal
        PREVIOUS_IMAGE = "none"
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
                            ${ANSIBLE_DIR}/get-current-image.yml || true
                        """,
                        returnStdout: true
                    ).trim()

                    echo output

                    def matcher = output =~ /CURRENT_IMAGE=(raihan999\\/devops-web:[A-Za-z0-9._-]+)/

                    if (matcher.find()) {
                        env.PREVIOUS_IMAGE = matcher.group(1)
                    } else {
                        echo "Kontainer belum ada di server target, menggunakan fallback PREVIOUS_IMAGE = 'none'"
                        env.PREVIOUS_IMAGE = "none"
                    }

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

                        if (env.PREVIOUS_IMAGE == "none") {
                            error("Deployment gagal dan tidak ada PREVIOUS_IMAGE untuk melakukan rollback.")
                        }

                        echo "Starting automatic rollback..."

                        def rollbackTag = env.PREVIOUS_IMAGE.substring(
                            env.PREVIOUS_IMAGE.lastIndexOf(':') + 1
                        )

                        echo "Rollback image: ${env.PREVIOUS_IMAGE}"
                        echo "Rollback tag: ${rollbackTag}"

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

                        echo "Verifying rollback..."

                        try {

                            sh """
                                set -e

                                ansible-playbook \
                                -i ${INVENTORY} \
                                ${ANSIBLE_DIR}/health-check.yml
                            """

                            echo "======================================"
                            echo "ROLLBACK VERIFIED SUCCESSFULLY"
                            echo "======================================"

                        } catch (Exception rollbackCheckError) {

                            echo "======================================"
                            echo "ROLLBACK VERIFICATION FAILED"
                            echo "======================================"

                            error(
                                "Deployment failed AND rollback verification failed."
                            )
                        }

                        error(
                            "Deployment failed. Rollback completed and verified successfully."
                        )
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
                        echo "HEALTH CHECK PASSED"
                        echo "======================================"

                    } catch (Exception e) {

                        echo "======================================"
                        echo "HEALTH CHECK FAILED"
                        echo "======================================"

                        if (env.PREVIOUS_IMAGE == "none") {
                            error("Health check gagal dan tidak ada PREVIOUS_IMAGE untuk rollback.")
                        }

                        echo "Starting automatic rollback..."

                        def rollbackTag = env.PREVIOUS_IMAGE.substring(
                            env.PREVIOUS_IMAGE.lastIndexOf(':') + 1
                        )

                        echo "Rollback image: ${env.PREVIOUS_IMAGE}"
                        echo "Rollback tag: ${rollbackTag}"

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

                        try {

                            sh """
                                set -e

                                ansible-playbook \
                                -i ${INVENTORY} \
                                ${ANSIBLE_DIR}/health-check.yml
                            """

                            echo "======================================"
                            echo "ROLLBACK VERIFIED SUCCESSFULLY"
                            echo "======================================"

                        } catch (Exception rollbackCheckError) {

                            error(
                                "Deployment failed AND rollback verification failed."
                            )
                        }

                        error(
                            "Deployment failed. Rollback completed and verified successfully."
                        )
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
${env.PREVIOUS_IMAGE}

New image:
${env.NEW_IMAGE ?: 'Not available'}

========================================
"""
        }

        success {

            echo """
========================================
       DEPLOYMENT SUCCESSFUL
========================================

Production image:
${env.NEW_IMAGE}

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
${env.PREVIOUS_IMAGE}

Automatic rollback:
Attempted

========================================
"""
        }
    }
}
