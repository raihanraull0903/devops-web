pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['DEPLOY', 'ROLLBACK'],
            description: 'Pilih aksi deployment'
        )

        string(
            name: 'ROLLBACK_TAG',
            defaultValue: '0a38c38',
            description: 'Docker image tag untuk rollback'
        )
    }

    environment {
        DOCKER_IMAGE = 'raihan999/devops-web'
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Version') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                script {
                    env.IMAGE_TAG = sh(
                        script: "git rev-parse --short=7 HEAD",
                        returnStdout: true
                    ).trim()

                    echo "Image version: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Test') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

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
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                sh '''
                    echo "================================"
                    echo "Building Docker Image"
                    echo "================================"

                    docker build \
                        -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                        .
                '''
            }
        }

        stage('Docker Push') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                sh '''
                    echo "================================"
                    echo "Pushing Docker Image"
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
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                sh '''
                    echo "================================"
                    echo "Deploying ${DOCKER_IMAGE}:${IMAGE_TAG}"
                    echo "================================"

                    ansible-playbook \
                        -i /home/ubuntu/devops-project/ansible/inventory.ini \
                        /home/ubuntu/devops-project/ansible/deploy-web.yml \
                        -e "docker_image=${DOCKER_IMAGE}:${IMAGE_TAG}"
                '''
            }
        }

        stage('Rollback') {
            when {
                expression {
                    params.ACTION == 'ROLLBACK'
                }
            }

            steps {
                sh '''
                    echo "================================"
                    echo "ROLLBACK"
                    echo "================================"

                    echo "Rolling back to:"
                    echo "${DOCKER_IMAGE}:${ROLLBACK_TAG}"

                    ansible-playbook \
                        -i /home/ubuntu/devops-project/ansible/inventory.ini \
                        /home/ubuntu/devops-project/ansible/rollback-web.yml \
                        -e "docker_image=${DOCKER_IMAGE}:${ROLLBACK_TAG}"

                    echo "================================"
                    echo "Rollback completed!"
                    echo "================================"
                '''
            }
        }
    }

    post {
        success {
            echo '================================'
            echo 'PIPELINE SUCCESS'
            echo '================================'
        }

        failure {
            echo '================================'
            echo 'PIPELINE FAILED'
            echo '================================'
        }
    }
}
