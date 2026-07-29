pipeline {
    agent any
    tools {
        maven 'Maven'
    }
    environment {
        // SonarQube
        SONARQUBE_SERVER = 'sonar'
        SONAR_PROJECT_KEY = 'DevOpsProject'
        SONAR_URL = 'http://65.0.81.202:9000/dashboard?id=DevOpsProject'
       
        // Docker
        IMAGE_NAME = 'fistpipeline'
        DOCKERHUB_REPO = 'dushyantsharmma/fistpipeline'
       
        // Kubernetes
        K8S_DEPLOYMENT = 'simple-webapp-deployment'
        K8S_NAMESPACE = 'default'
        CONTAINER_NAME = 'simple-webapp'
       
        // Replace with your actual Worker Public IP
        APP_URL = 'http://43.204.22.117:30007'
       
        // Environment
        DEPLOY_ENV = 'Production'
    }
   
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Dushyantsharmma/DevOpsProject.git'
               
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }
       
        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                }
            }
        }
       
        stage('OWASP Dependency Check') {
            steps {
                echo "Running OWASP Dependency Check..."
                dependencyCheck additionalArguments: '''
                    --scan ./
                    --format HTML
                    --format XML
                    --out .
                    --prettyPrint
                ''', odcInstallation: 'dp-check'
               
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
               
                archiveArtifacts artifacts: 'dependency-check-report.html,dependency-check-report.xml', fingerprint: true
            }
        }
       
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh "mvn sonar:sonar -Dsonar.projectKey=${SONAR_PROJECT_KEY}"
                }
            }
        }
       
        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                    echo "=== Built Docker Images ==="
                    docker images | grep ${IMAGE_NAME}
                """
            }
        }
       
        stage('Trivy Image Scan') {
            steps {
                sh """
                mkdir -p /var/lib/jenkins/trivy-temp
               
                # Generate Table (TXT) report
                TMPDIR=/var/lib/jenkins/trivy-temp \
                trivy image --skip-version-check --severity HIGH,CRITICAL \
                    --format table --output trivy-report.txt --no-progress \
                    ${IMAGE_NAME}:${BUILD_NUMBER}
               
                # Generate HTML report (professional)
                TMPDIR=/var/lib/jenkins/trivy-temp \
                trivy image --skip-version-check --severity HIGH,CRITICAL \
                    --format template --template "@contrib/html.tpl" \
                    --output trivy-report.html --no-progress \
                    ${IMAGE_NAME}:${BUILD_NUMBER} || \
                trivy image --skip-version-check --severity HIGH,CRITICAL \
                    --format json --output trivy-report.json --no-progress \
                    ${IMAGE_NAME}:${BUILD_NUMBER}
                """
               
                archiveArtifacts artifacts: 'trivy-report.txt,trivy-report.html,trivy-report.json', allowEmptyArchive: true, fingerprint: true
            }
        }
       
        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerpassword', url: 'https://index.docker.io/v1/') {
                        sh """
                            docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                            docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }
       
        stage('Deploy to Kubernetes') {
            steps {
                sh """
                echo "=== Kubernetes Client Info ==="
                kubectl version --client
                kubectl config current-context
               
                echo "=== Applying Base Manifest ==="
                kubectl apply -f k8s-deployment.yml
               
                echo "=== Updating Deployment Image ==="
                kubectl set image deployment/${K8S_DEPLOYMENT} ${CONTAINER_NAME}=${DOCKERHUB_REPO}:${BUILD_NUMBER} -n ${K8S_NAMESPACE}
               
                echo "=== Waiting for Rollout ==="
                kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} --timeout=180s
               
                echo "=== Deployment Status ==="
                kubectl get deployments -n ${K8S_NAMESPACE}
                echo "=== Pods ==="
                kubectl get pods -o wide -n ${K8S_NAMESPACE}
                echo "=== Services ==="
                kubectl get svc -n ${K8S_NAMESPACE}
                echo "=== Rollout History ==="
                kubectl rollout history deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE}
                """
            }
        }
    }
   
    post {
        success {
            emailext (
                subject: "✅ Deployment Successful #${env.BUILD_NUMBER} - ${env.JOB_NAME}",
                mimeType: 'text/html',
                attachLog: false,
                attachmentsPattern: 'trivy-report.txt,trivy-report.html,trivy-report.json,dependency-check-report.html,dependency-check-report.xml',
                to: '227dushyantsharma@gmail.com',
                body: '''
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: Arial, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; }
                        .container { max-width: 800px; margin: auto; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
                        .header { background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 25px; text-align: center; }
                        .content { padding: 30px; }
                        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                        th, td { padding: 14px; text-align: left; border-bottom: 1px solid #eee; }
                        th { background-color: #f8f9fa; width: 35%; }
                        .status { display: inline-block; padding: 8px 18px; border-radius: 50px; font-weight: bold; color: white; }
                        .success { background-color: #28a745; }
                        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; border-top: 1px solid #eee; }
                        a { color: #007bff; text-decoration: none; }
                        .report-box { background: #f8f9fa; border-left: 4px solid #28a745; padding: 15px 20px; margin: 20px 0; border-radius: 0 6px 6px 0; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>🎉 Deployment Completed Successfully</h1>
                            <h2>${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>
                        </div>
                        <div class="content">
                            <p><strong>Status:</strong> <span class="status success">SUCCESS</span></p>
                           
                            <table>
                                <tr><th>Project</th><td>${env.JOB_NAME}</td></tr>
                                <tr><th>Build Number</th><td>#${env.BUILD_NUMBER}</td></tr>
                                <tr><th>Build Date</th><td>${new Date()}</td></tr>
                                <tr><th>Build Duration</th><td>${currentBuild.durationString}</td></tr>
                                <tr><th>Git Branch</th><td>${env.BRANCH_NAME ?: 'main'}</td></tr>
                                <tr><th>Git Commit</th><td>${env.GIT_COMMIT_SHORT}</td></tr>
                                <tr><th>Environment</th><td>${DEPLOY_ENV}</td></tr>
                                <tr>
                                    <th>Docker Image</th>
                                    <td>
                                        <a href="https://hub.docker.com/r/dushyantsharmma/fistpipeline" target="_blank">
                                            ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                                        </a>
                                    </td>
                                </tr>
                                <tr><th>Kubernetes Deployment</th><td>${K8S_DEPLOYMENT} (${K8S_NAMESPACE})</td></tr>
                                <tr><th>Deployment Status</th><td>Rolling Update Completed Successfully</td></tr>
                                <tr><th>Application URL</th><td><a href="${APP_URL}" target="_blank">${APP_URL}</a></td></tr>
                                <tr><th>SonarQube Report</th><td><a href="${SONAR_URL}" target="_blank">View SonarQube Dashboard</a></td></tr>
                                <tr><th>Build URL</th><td><a href="${env.BUILD_URL}" target="_blank">View Build Details in Jenkins</a></td></tr>
                            </table>
                           
                            <h3>Pipeline Stages</h3>
                            <ul>
                                <li>✅ Source Code Checkout</li>
                                <li>✅ Maven Build & Packaging</li>
                                <li>✅ OWASP Dependency Check</li>
                                <li>✅ SonarQube Code Quality Analysis</li>
                                <li>✅ Docker Image Build</li>
                                <li>✅ Trivy Security Scan</li>
                                <li>✅ Push to Docker Hub</li>
                                <li>✅ Deploy to Kubernetes</li>
                                <li>✅ Rollout Verification</li>
                            </ul>
                           
                            <div class="report-box">
                                <h3 style="margin-top:0;">📎 Security Reports Attached</h3>
                                <ul style="margin-bottom:0;">
                                    <li><strong>Trivy Image Scan</strong> → trivy-report.html + trivy-report.txt</li>
                                    <li><strong>OWASP Dependency-Check</strong> → dependency-check-report.html + dependency-check-report.xml</li>
                                </ul>
                            </div>
                           
                            <p style="color:#555; font-size:14px;">
                                Please review the attached HTML reports for detailed vulnerability findings.
                            </p>
                        </div>
                        <div class="footer">
                            <p><strong>Powered by Jenkins • Docker • Kubernetes • SonarQube • Trivy • OWASP</strong></p>
                            <p>DevSecOps CI/CD Pipeline • Automated Notification</p>
                        </div>
                    </div>
                </body>
                </html>
                '''
            )
        }
       
        failure {
            emailext (
                subject: "❌ BUILD FAILED #${env.BUILD_NUMBER} - ${env.JOB_NAME}",
                mimeType: 'text/html',
                attachLog: true,
                attachmentsPattern: 'trivy-report.txt,trivy-report.html,trivy-report.json,dependency-check-report.html,dependency-check-report.xml',
                to: '227dushyantsharma@gmail.com',
                body: '''
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: Arial, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; }
                        .container { max-width: 800px; margin: auto; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
                        .header { background: linear-gradient(135deg, #dc3545, #e4606e); color: white; padding: 25px; text-align: center; }
                        .content { padding: 30px; }
                        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                        th, td { padding: 14px; text-align: left; border-bottom: 1px solid #eee; }
                        th { background-color: #f8f9fa; width: 35%; }
                        .status { display: inline-block; padding: 8px 18px; border-radius: 50px; font-weight: bold; color: white; background-color: #dc3545; }
                        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; border-top: 1px solid #eee; }
                        a { color: #007bff; text-decoration: none; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>❌ Pipeline Execution Failed</h1>
                            <h2>${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>
                        </div>
                        <div class="content">
                            <p><strong>Status:</strong> <span class="status">FAILED</span></p>
                           
                            <table>
                                <tr><th>Project</th><td>${env.JOB_NAME}</td></tr>
                                <tr><th>Build Number</th><td>#${env.BUILD_NUMBER}</td></tr>
                                <tr><th>Build Date</th><td>${new Date()}</td></tr>
                                <tr><th>Build Duration</th><td>${currentBuild.durationString}</td></tr>
                                <tr><th>Git Branch</th><td>${env.BRANCH_NAME ?: 'main'}</td></tr>
                                <tr><th>Git Commit</th><td>${env.GIT_COMMIT_SHORT ?: 'N/A'}</td></tr>
                                <tr><th>Environment</th><td>${DEPLOY_ENV}</td></tr>
                                <tr><th>Build URL</th><td><a href="${env.BUILD_URL}" target="_blank">${env.BUILD_URL}</a></td></tr>
                            </table>
                           
                            <p><strong>Build has failed.</strong> Please check the attached build log and any available security reports for details.</p>
                        </div>
                        <div class="footer">
                            <p><strong>Powered by Jenkins • Docker • Kubernetes • SonarQube • Trivy • OWASP</strong></p>
                            <p>DevSecOps CI/CD Pipeline • Automated Notification</p>
                        </div>
                    </div>
                </body>
                </html>
                '''
            )
        }
    }
}
