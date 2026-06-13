pipeline {
    agent any
    environment {
        // Pointing to your local port-forwarded registry
        REGISTRY_URI = "host.docker.internal:5001" // Used by Jenkins to push from your Mac
        CLUSTER_REGISTRY_URI = "localhost:5000"     // Used by Minikube internally to pull (by Argocd)
        IMAGE_NAME = "playerservice"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        MANIFEST_REPO_URL = "github.com/mvajith18/playerService-deployment.git"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    // 1. Download official portable Docker CLI binary for Linux inside Jenkins
                    sh 'curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz | tar -xzm'

                    // 2. Execute build and push using the freshly downloaded local CLI tool
                    sh "./docker/docker build -t ${REGISTRY_URI}/${IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "./docker/docker push ${REGISTRY_URI}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Update GitOps Manifest Repository') {
            steps {
                // 'github-token' is the ID of the credential we will save in Jenkins in the next step
                withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                    sh """
                        git config --global user.email "jenkins-automation@local.com"
                        git config --global user.name "Jenkins Local Automation"

                        # FIX: Remove the folder if a previous build left it behind
                        rm -rf playerService-deployment

                        # Clone the manifest repository
                        git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@${MANIFEST_REPO_URL}
                        cd playerService-deployment

                        # Dynamically change the image tag to the new build number inside deployment.yaml
                        sed -i 's|image: .*|image: '${CLUSTER_REGISTRY_URI}'/'${IMAGE_NAME}':'${IMAGE_TAG}'|g' deployment.yaml

                        # Commit the change back to your repository
                        git add deployment.yaml
                        git commit -m "Jenkins CI: Updating deployment image tag to build #${IMAGE_TAG} [skip ci]"
                        git push origin main
                    """
                }
            }
        }
    }
}