pipeline {
    agent any

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
                sh 'docker build -t devops-web:ci .'
            }
        }
    }
}
