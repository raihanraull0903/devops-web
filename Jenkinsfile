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
                sh 'echo "Testing DevOps Web..."'
                sh 'test -f index.html'
                sh 'test -f style.css'
                sh 'test -f Dockerfile'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:latest .'
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
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    ansible-playbook \
                    -i /opt/devops-ansible/inventory.ini \
                    /opt/devops-ansible/deploy-web.yml
                '''
            }
        }
    }
}
