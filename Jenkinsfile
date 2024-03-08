groovy
pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '183671436292'
        ECR_REPOSITORY = 'code-app-ecr-repo'
        ECS_CLUSTER = 'code-app-cluster'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Push Docker Images') {
            steps {
                script {
                    def dockerBackendImage = docker.build("backend-image:${env.BUILD_NUMBER}")
                    def dockerFrontendImage = docker.build("frontend-image:${env.BUILD_NUMBER}")
                    
                    dockerBackendImage.push("${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_DEFAULT_REGION}.amazonaws.com/${env.ECR_REPOSITORY}")
                    dockerFrontendImage.push("${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_DEFAULT_REGION}.amazonaws.com/${env.ECR_REPOSITORY}")
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                script {
                    def dockerBackendImage = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_DEFAULT_REGION}.amazonaws.com/${env.ECR_REPOSITORY}:backend-image-${env.BUILD_NUMBER}"
                    def dockerFrontendImage = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_DEFAULT_REGION}.amazonaws.com/${env.ECR_REPOSITORY}:frontend-image-${env.BUILD_NUMBER}"
                    
                    ecsDeploy(service: 'backend-service', image: dockerBackendImage, cluster: env.ECS_CLUSTER)
                    ecsDeploy(service: 'frontend-service', image: dockerFrontendImage, cluster: env.ECS_CLUSTER)
                }
            }
        }
    }
    
    post {
        success {
            echo 'Build and deployment successful'
        }
        failure {
            echo 'Build and deployment failed'
        }
    }
}

def ecsDeploy(def params) {
    sh "ecs deploy -svc ${params.service} -img ${params.image} -clust ${params.cluster}"
}