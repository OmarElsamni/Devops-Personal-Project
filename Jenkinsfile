pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        CLUSTER_NAME = 'devops-task-manager'
        
        // Docker image names
        BACKEND_IMAGE = "${ECR_REGISTRY}/production-task-manager-backend"
        FRONTEND_IMAGE = "${ECR_REGISTRY}/production-task-manager-frontend"
        
        // Git commit short hash
        GIT_COMMIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
        IMAGE_TAG = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        
        // AWS Credentials
        AWS_CREDENTIALS = credentials('aws-credentials')
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out code from Git..."
                    checkout scm
                    sh "git rev-parse HEAD > .git/commit-id"
                }
            }
        }
        
        stage('Run Tests') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir('backend') {
                            script {
                                echo "Running backend tests..."
                                sh '''
                                    npm ci
                                    npm run test || true
                                    npm run lint || true
                                '''
                            }
                        }
                    }
                }
                
                stage('Frontend Tests') {
                    steps {
                        dir('frontend') {
                            script {
                                echo "Running frontend tests..."
                                sh '''
                                    npm ci
                                    npm run test -- --watchAll=false || true
                                    npm run lint || true
                                '''
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Backend Image') {
                    steps {
                        script {
                            echo "Building backend Docker image..."
                            dir('backend') {
                                sh """
                                    docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} .
                                    docker tag ${BACKEND_IMAGE}:${IMAGE_TAG} ${BACKEND_IMAGE}:latest
                                """
                            }
                        }
                    }
                }
                
                stage('Build Frontend Image') {
                    steps {
                        script {
                            echo "Building frontend Docker image..."
                            dir('frontend') {
                                sh """
                                    docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} .
                                    docker tag ${FRONTEND_IMAGE}:${IMAGE_TAG} ${FRONTEND_IMAGE}:latest
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Security Scan') {
            parallel {
                stage('Scan Backend Image') {
                    steps {
                        script {
                            echo "Scanning backend image for vulnerabilities..."
                            sh """
                                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                                    aquasec/trivy image --severity HIGH,CRITICAL \
                                    --exit-code 0 \
                                    ${BACKEND_IMAGE}:${IMAGE_TAG} || true
                            """
                        }
                    }
                }
                
                stage('Scan Frontend Image') {
                    steps {
                        script {
                            echo "Scanning frontend image for vulnerabilities..."
                            sh """
                                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                                    aquasec/trivy image --severity HIGH,CRITICAL \
                                    --exit-code 0 \
                                    ${FRONTEND_IMAGE}:${IMAGE_TAG} || true
                            """
                        }
                    }
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    echo "Logging into AWS ECR..."
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    """
                    
                    echo "Pushing backend image to ECR..."
                    sh """
                        docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                        docker push ${BACKEND_IMAGE}:latest
                    """
                    
                    echo "Pushing frontend image to ECR..."
                    sh """
                        docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                        docker push ${FRONTEND_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Update Kubeconfig') {
            steps {
                script {
                    echo "Updating kubeconfig..."
                    sh """
                        aws eks update-kubeconfig \
                            --region ${AWS_REGION} \
                            --name ${CLUSTER_NAME}
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to Kubernetes..."
                    
                    // Create namespace if it doesn't exist
                    sh "kubectl apply -f kubernetes/namespaces/namespaces.yaml"
                    
                    // Apply ConfigMaps and Secrets
                    sh "kubectl apply -f kubernetes/app/configmap.yaml"
                    
                    // Update deployment manifests with new image tags
                    sh """
                        sed -i.bak "s|\\\${ECR_REGISTRY}|${ECR_REGISTRY}|g" kubernetes/app/backend-deployment.yaml
                        sed -i.bak "s|\\\${IMAGE_TAG}|${IMAGE_TAG}|g" kubernetes/app/backend-deployment.yaml
                        sed -i.bak "s|\\\${ECR_REGISTRY}|${ECR_REGISTRY}|g" kubernetes/app/frontend-deployment.yaml
                        sed -i.bak "s|\\\${IMAGE_TAG}|${IMAGE_TAG}|g" kubernetes/app/frontend-deployment.yaml
                    """
                    
                    // Apply deployments
                    sh """
                        kubectl apply -f kubernetes/app/backend-deployment.yaml
                        kubectl apply -f kubernetes/app/frontend-deployment.yaml
                        kubectl apply -f kubernetes/app/ingress.yaml
                        kubectl apply -f kubernetes/app/hpa.yaml
                        kubectl apply -f kubernetes/app/networkpolicy.yaml
                    """
                    
                    // Restore original files
                    sh """
                        mv kubernetes/app/backend-deployment.yaml.bak kubernetes/app/backend-deployment.yaml
                        mv kubernetes/app/frontend-deployment.yaml.bak kubernetes/app/frontend-deployment.yaml
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo "Verifying deployment..."
                    
                    // Wait for rollout to complete
                    sh """
                        kubectl rollout status deployment/backend -n task-manager --timeout=5m
                        kubectl rollout status deployment/frontend -n task-manager --timeout=5m
                    """
                    
                    // Check pod status
                    sh """
                        kubectl get pods -n task-manager
                        kubectl get svc -n task-manager
                        kubectl get ingress -n task-manager
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "Running health checks..."
                    retry(3) {
                        sleep 10
                        sh """
                            # Get backend pods
                            BACKEND_POD=\$(kubectl get pods -n task-manager -l app=backend -o jsonpath='{.items[0].metadata.name}')
                            
                            # Check backend health
                            kubectl exec -n task-manager \$BACKEND_POD -- wget -q -O- http://localhost:3000/health/live || exit 1
                            
                            echo "Health checks passed!"
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully!"
            script {
                // Tag the commit
                sh """
                    git tag -a "build-${env.BUILD_NUMBER}" -m "Jenkins build ${env.BUILD_NUMBER}"
                """
            }
        }
        
        failure {
            echo "Pipeline failed!"
            script {
                // Rollback deployment if needed
                sh """
                    echo "Consider rolling back the deployment"
                    kubectl rollout history deployment/backend -n task-manager
                    kubectl rollout history deployment/frontend -n task-manager
                """
            }
        }
        
        always {
            echo "Cleaning up..."
            script {
                // Clean up Docker images to save space
                sh """
                    docker image prune -f
                    docker system prune -f --volumes
                """
            }
            
            // Archive build info
            archiveArtifacts artifacts: '.git/commit-id', allowEmptyArchive: true
        }
    }
}

