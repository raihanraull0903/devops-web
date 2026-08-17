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

                    def output = sh(
                        script: """
                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/get-current-image.yml
                        """,
                        returnStdout: true
                    ).trim()

                    echo output

                    def lines = output.readLines().findAll {
                        it.contains('Current production image:')
                    }

                    if (lines.isEmpty()) {
                        error("Tidak dapat menemukan current production image")
                    }

                    env.PREVIOUS_IMAGE = lines.last()
                        .replace('Current production image:', '')
                        .trim()

                    echo "Previous production image: ${PREVIOUS_IMAGE}"
                }
            }
        }

        stage('Deploy') {
            steps {

                echo "Deploying ${NEW_IMAGE}"

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

                        echo "Checking application health..."

                        sh """
                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/health-check.yml
                        """

                        echo "Health check passed."

                    } catch (Exception e) {

                        echo "======================================"
                        echo "HEALTH CHECK FAILED"
                        echo "======================================"

                        echo "Starting automatic rollback..."
                        echo "Rollback target: ${PREVIOUS_IMAGE}"

                        def rollbackTag = env.PREVIOUS_IMAGE.tokenize(':')[-1]

                        sh """
                            ansible-playbook \
                            -i ${INVENTORY} \
                            ${ANSIBLE_DIR}/rollback-web.yml \
                            -e "rollback_tag=${rollbackTag}"
                        """

                        echo "======================================"
                        echo "AUTOMATIC ROLLBACK COMPLETED"
                        echo "Rollback image: ${PREVIOUS_IMAGE}"
                        echo "======================================"

                        error("Deployment failed. Automatic rollback completed.")
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
Image deployed : ${NEW_IMAGE}
Previous image : ${PREVIOUS_IMAGE}
========================================
"""
        }

        failure {

            echo """
========================================
          PIPELINE FAILED
========================================
Check the pipeline logs.
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
