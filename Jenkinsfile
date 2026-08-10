pipeline {
    agent any

    tools {
        maven 'Maven'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        string(
            name: 'APP_URL',
            defaultValue: 'http://13.233.121.103:30007',
            description: 'Application URL (NodePort of the worker)'
        )
    }

    environment {
        // SonarQube
        SONARQUBE_SERVER   = 'sonar'
        SONAR_PROJECT_KEY  = 'DevOpsProject'
        SONAR_URL          = 'http://65.0.81.202:9000/dashboard?id=DevOpsProject'

        // Docker
        IMAGE_NAME         = 'fistpipeline'
        DOCKERHUB_REPO     = 'dushyantsharmma/fistpipeline'

        // Kubernetes
        K8S_DEPLOYMENT     = 'simple-webapp-deployment'
        K8S_NAMESPACE      = 'default'
        CONTAINER_NAME     = 'simple-webapp'

        // Environment
        DEPLOY_ENV         = 'Production'

        // Paths
        DEP_CHECK_DATA     = '/var/lib/jenkins/dependency-check-data'
        TRIVY_TEMP         = '/var/lib/jenkins/trivy-temp'
        KUBECONFIG_PATH    = '/var/lib/jenkins/.kube/config'
    }

    stages {

        // ==========================================================
        // CHECKOUT
        // ==========================================================
        stage('Checkout') {
            steps {
                script {
                    try {
                        git branch: 'main',
                            url: 'https://github.com/Dushyantsharmma/DevOpsProject.git'

                        env.GIT_COMMIT_SHORT = sh(
                            script: 'git rev-parse --short HEAD',
                            returnStdout: true
                        ).trim()
                    } catch (err) {
                        env.FAILED_STAGE = 'Checkout'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ==========================================================
        // MAVEN BUILD
        // ==========================================================
        stage('Maven Build') {
            steps {
                script {
                    try {
                        sh 'mvn clean package -DskipTests'
                    } catch (err) {
                        env.FAILED_STAGE = 'Maven Build'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                }
            }
        }

        // ==========================================================
        // OWASP DEPENDENCY CHECK
        // ==========================================================
        stage('OWASP Dependency Check') {
            steps {
                script {
                    try {
                        withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                            sh "mkdir -p ${DEP_CHECK_DATA}"

                            dependencyCheck(
                                odcInstallation: 'dp-check',
                                additionalArguments: """
                                    --scan .
                                    --format HTML
                                    --format XML
                                    --out .
                                    --prettyPrint
                                    --data ${DEP_CHECK_DATA}
                                    --noupdate
                                    --nvdApiKey ${NVD_API_KEY}
                                """
                            )

                            dependencyCheckPublisher pattern: '**/dependency-check-report.xml'

                            archiveArtifacts(
                                artifacts: 'dependency-check-report.html,dependency-check-report.xml',
                                fingerprint: true,
                                allowEmptyArchive: true
                            )
                        }
                    } catch (err) {
                        env.FAILED_STAGE = 'OWASP Dependency Check'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ==========================================================
        // SONARQUBE ANALYSIS
        // ==========================================================
        stage('SonarQube Analysis') {
            steps {
                script {
                    try {
                        withSonarQubeEnv("${SONARQUBE_SERVER}") {
                            sh """
                                mvn org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY}
                            """
                        }
                    } catch (err) {
                        env.FAILED_STAGE = 'SonarQube Analysis'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ==========================================================
        // SONAR QUALITY GATE
        // ==========================================================
        stage('SonarQube Quality Gate') {
            steps {
                script {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    } catch (err) {
                        env.FAILED_STAGE = 'SonarQube Quality Gate'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ==========================================================
        // DOCKER BUILD
        // ==========================================================
        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        sh """
                            docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                            echo "=== Built Docker Image ==="
                            docker images | grep ${IMAGE_NAME} || true
                        """
                    } catch (err) {
                        env.FAILED_STAGE = 'Build Docker Image'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ==========================================================
        // TRIVY IMAGE SCAN
        // ==========================================================
        stage('Trivy Image Scan') {
            steps {
                script {
                    try {
                        sh """
                            mkdir -p ${TRIVY_TEMP}

                            echo "=== Trivy Table Report ==="
                            TMPDIR=${TRIVY_TEMP} trivy image \
                                --skip-version-check \
                                --severity HIGH,CRITICAL \
                                --format table \
                                --output trivy-report.txt \
                                --no-progress \
                                ${IMAGE_NAME}:${BUILD_NUMBER}

                            echo "=== Trivy JSON Report ==="
                            TMPDIR=${TRIVY_TEMP} trivy image \
                                --skip-version-check \
                                --severity HIGH,CRITICAL \
                                --format json \
                                --output trivy-report.json \
                                --no-progress \
                                ${IMAGE_NAME}:${BUILD_NUMBER}

                            echo "=== Trivy HTML Report (best effort) ==="
                            TMPDIR=${TRIVY_TEMP} trivy image \
                                --skip-version-check \
                                --severity HIGH,CRITICAL \
                                --format template \
                                --template "@contrib/html.tpl" \
                                --output trivy-report.html \
                                --no-progress \
                                ${IMAGE_NAME}:${BUILD_NUMBER} || \
                            echo "HTML template not available. JSON + TXT reports are still generated."
                        """

                        archiveArtifacts(
                            artifacts: 'trivy-report.txt,trivy-report.html,trivy-report.json',
                            allowEmptyArchive: true,
                            fingerprint: true
                        )

                        def criticalCount = sh(
                            script: "grep -c 'CRITICAL' trivy-report.txt || true",
                            returnStdout: true
                        ).trim().toInteger()

                        def highCount = sh(
                            script: "grep -c 'HIGH' trivy-report.txt || true",
                            returnStdout: true
                        ).trim().toInteger()

                        env.TRIVY_CRITICAL = "${criticalCount}"
                        env.TRIVY_HIGH     = "${highCount}"

                        if (criticalCount > 0 || highCount > 0) {
                            error "Trivy Security Gate Failed → CRITICAL: ${criticalCount}, HIGH: ${highCount}. Check trivy-report.txt / .json / .html"
                        }

                    } catch (err) {
                        env.FAILED_STAGE = 'Trivy Image Scan'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ==========================================================
        // PUSH TO DOCKER HUB
        // ==========================================================
        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    try {
                        withDockerRegistry(credentialsId: 'dockerpassword', url: 'https://index.docker.io/v1/') {
                            sh """
                                docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                                docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                            """
                        }
                    } catch (err) {
                        env.FAILED_STAGE = 'Push Docker Image to Docker Hub'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ==========================================================
        // KUBERNETES DEPLOYMENT
        // ==========================================================
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    try {
                        sh """
                            export KUBECONFIG=${KUBECONFIG_PATH}

                            echo "======================================"
                            echo " Kubernetes Client"
                            echo "======================================"
                            kubectl version --client

                            echo "======================================"
                            echo " Kubernetes Context"
                            echo "======================================"
                            kubectl config current-context

                            echo "======================================"
                            echo " Kubernetes Nodes"
                            echo "======================================"
                            kubectl get nodes -o wide

                            echo "======================================"
                            echo " Applying Kubernetes Manifest"
                            echo "======================================"
                            kubectl apply -f k8s-deployment.yml

                            echo "======================================"
                            echo " Updating Deployment Image"
                            echo "======================================"
                            kubectl set image deployment/${K8S_DEPLOYMENT} \
                                ${CONTAINER_NAME}=${DOCKERHUB_REPO}:${BUILD_NUMBER} \
                                -n ${K8S_NAMESPACE}

                            echo "======================================"
                            echo " Waiting For Rollout"
                            echo "======================================"
                            kubectl rollout status deployment/${K8S_DEPLOYMENT} \
                                -n ${K8S_NAMESPACE} --timeout=180s

                            echo "======================================"
                            echo " Deployment Status"
                            echo "======================================"
                            kubectl get deployments -n ${K8S_NAMESPACE}

                            echo "======================================"
                            echo " Pods"
                            echo "======================================"
                            kubectl get pods -o wide -n ${K8S_NAMESPACE}

                            echo "======================================"
                            echo " Services"
                            echo "======================================"
                            kubectl get svc -n ${K8S_NAMESPACE}

                            echo "======================================"
                            echo " Rollout History"
                            echo "======================================"
                            kubectl rollout history deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE}
                        """
                    } catch (err) {
                        env.FAILED_STAGE = 'Deploy to Kubernetes'
                        env.FAILED_ERROR = err.getMessage()

                        // Collect diagnostics
                        sh """
                            export KUBECONFIG=${KUBECONFIG_PATH}
                            {
                                echo "================================================"
                                echo "KUBERNETES FAILURE DIAGNOSTICS"
                                echo "================================================"
                                echo ""
                                echo "=== Nodes ==="
                                kubectl get nodes -o wide || true
                                echo ""
                                echo "=== All Pods ==="
                                kubectl get pods -A -o wide || true
                                echo ""
                                echo "=== Deployment ==="
                                kubectl get deployment ${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} -o wide || true
                                echo ""
                                echo "=== ReplicaSets ==="
                                kubectl get rs -n ${K8S_NAMESPACE} || true
                                echo ""
                                echo "=== Pods (by label app=simple-webapp) ==="
                                kubectl get pods -n ${K8S_NAMESPACE} -l app=simple-webapp -o wide || true
                                echo ""
                                echo "=== Deployment Description ==="
                                kubectl describe deployment ${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} || true
                                echo ""
                                echo "=== Recent Events ==="
                                kubectl get events -n ${K8S_NAMESPACE} --sort-by='.lastTimestamp' || true
                                echo ""
                                echo "=== Pod Descriptions & Logs ==="
                                for POD in \$(kubectl get pods -n ${K8S_NAMESPACE} -l app=simple-webapp -o name 2>/dev/null); do
                                    echo "----------------------------------------"
                                    echo "POD: \$POD"
                                    echo "----------------------------------------"
                                    kubectl describe \$POD -n ${K8S_NAMESPACE} || true
                                    echo ""
                                    echo "=== Logs ==="
                                    kubectl logs \$POD -n ${K8S_NAMESPACE} --all-containers=true --tail=150 || true
                                    echo ""
                                done
                            } > kubernetes-failure-diagnostics.txt 2>&1 || true
                        """

                        archiveArtifacts(
                            artifacts: 'kubernetes-failure-diagnostics.txt',
                            allowEmptyArchive: true,
                            fingerprint: true
                        )

                        throw err
                    }
                }
            }
        }

        // ==========================================================
        // OWASP ZAP SCAN
        // ==========================================================
        stage('OWASP ZAP Scan') {
            steps {
                script {
                    try {
                        sh 'rm -f zap-report.html || true'
                        sh "chmod -R 777 ${WORKSPACE}"

                        // Wait for application
                        sh """
                            echo "=== Waiting For Application ==="
                            for i in \$(seq 1 20); do
                                HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" ${params.APP_URL} || echo "000")
                                if echo "\$HTTP_CODE" | grep -qE "200|301|302"; then
                                    echo "Application is UP! HTTP Status: \$HTTP_CODE"
                                    break
                                fi
                                echo "Not ready yet (HTTP \$HTTP_CODE). Retry \$i/20"
                                sleep 5
                            done
                        """

                        // Run ZAP
                        sh """
                            docker run --rm \
                                -v ${WORKSPACE}:/zap/wrk:rw \
                                -w /zap/wrk \
                                ghcr.io/zaproxy/zaproxy:stable \
                                zap-baseline.py \
                                -t ${params.APP_URL} \
                                -r zap-report.html \
                                -I
                        """

                        archiveArtifacts(
                            artifacts: 'zap-report.html',
                            fingerprint: true,
                            allowEmptyArchive: true
                        )
                    } catch (err) {
                        env.FAILED_STAGE = 'OWASP ZAP Scan'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }
    }

    // ==============================================================
    // POST ACTIONS
    // ==============================================================
    post {
        success {
            emailext(
                subject: "✅ PIPELINE SUCCESS #${env.BUILD_NUMBER} - ${env.JOB_NAME}",
                mimeType: 'text/html',
                attachLog: false,
                attachmentsPattern: 'trivy-report.txt,trivy-report.html,trivy-report.json,dependency-check-report.html,dependency-check-report.xml,zap-report.html',
                to: '227dushyantsharma@gmail.com',
                body: """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
body { font-family: Arial, sans-serif; background: #f4f6f9; padding: 20px; }
.container { max-width: 850px; margin: auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
.header { background: linear-gradient(135deg,#198754,#20c997); color: white; padding: 30px; text-align: center; }
.content { padding: 30px; }
.status { color: white; background: #198754; padding: 8px 18px; border-radius: 20px; font-weight: bold; }
table { width: 100%; border-collapse: collapse; margin-top: 20px; }
th, td { padding: 12px; border-bottom: 1px solid #eee; text-align: left; }
th { width: 35%; background: #f8f9fa; }
.success-box { background: #e9f7ef; border-left: 5px solid #198754; padding: 15px; margin-top: 20px; border-radius: 0 6px 6px 0; }
.footer { padding: 20px; text-align: center; color: #777; font-size: 13px; }
a { color: #0d6efd; text-decoration: none; }
</style>
</head>
<body>
<div class="container">
<div class="header">
<h1>✅ PIPELINE SUCCESSFUL</h1>
<h2>${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>
</div>
<div class="content">
<p><strong>Status:</strong> <span class="status">SUCCESS</span></p>

<table>
<tr><th>Project</th><td>${env.JOB_NAME}</td></tr>
<tr><th>Build</th><td>#${env.BUILD_NUMBER}</td></tr>
<tr><th>Build Date</th><td>${new Date()}</td></tr>
<tr><th>Duration</th><td>${currentBuild.durationString}</td></tr>
<tr><th>Git Commit</th><td>${env.GIT_COMMIT_SHORT ?: 'N/A'}</td></tr>
<tr><th>Environment</th><td>${DEPLOY_ENV}</td></tr>
<tr><th>Docker Image</th><td>${DOCKERHUB_REPO}:${BUILD_NUMBER}</td></tr>
<tr><th>Kubernetes Deployment</th><td>${K8S_DEPLOYMENT}</td></tr>
<tr><th>Namespace</th><td>${K8S_NAMESPACE}</td></tr>
<tr><th>Application</th><td><a href="${params.APP_URL}">${params.APP_URL}</a></td></tr>
<tr><th>SonarQube</th><td><a href="${SONAR_URL}">View Dashboard</a></td></tr>
<tr><th>Jenkins Build</th><td><a href="${env.BUILD_URL}">Open Build</a></td></tr>
</table>

<div class="success-box">
<h3>🎯 Pipeline Stages Passed</h3>
<ul>
<li>✅ Source Checkout</li>
<li>✅ Maven Build</li>
<li>✅ OWASP Dependency Check</li>
<li>✅ SonarQube Analysis + Quality Gate</li>
<li>✅ Docker Image Build</li>
<li>✅ Trivy Security Scan (no HIGH/CRITICAL)</li>
<li>✅ Docker Hub Push</li>
<li>✅ Kubernetes Deployment + Rollout</li>
<li>✅ OWASP ZAP Baseline Scan</li>
</ul>
</div>

<h3>📎 Security Reports Attached</h3>
<ul>
<li>Trivy (txt / html / json)</li>
<li>OWASP Dependency-Check (html / xml)</li>
<li>OWASP ZAP (html)</li>
</ul>
</div>
<div class="footer">
<p><strong>Powered by Jenkins • Docker • Kubernetes • SonarQube • Trivy • OWASP ZAP</strong></p>
<p>DevSecOps CI/CD Pipeline</p>
</div>
</div>
</body>
</html>
"""
            )
        }

        failure {
            script {
                def cause = "Unknown failure"
                def fix   = "Check the Jenkins Console Output and any attached diagnostics."

                switch (env.FAILED_STAGE) {
                    case 'Checkout':
                        cause = "Git repository checkout failed."
                        fix = """Check:
1. Repository URL
2. Branch name (main)
3. GitHub credentials / access
4. Network connectivity from Jenkins agent"""
                        break
                    case 'Maven Build':
                        cause = "Maven could not compile/package the application."
                        fix = """Check:
1. Java version compatibility
2. pom.xml
3. Maven dependencies
4. Compilation errors in console"""
                        break
                    case 'OWASP Dependency Check':
                        cause = "OWASP Dependency-Check failed."
                        fix = """Check:
1. NVD API key validity
2. Dependency-Check database path
3. Network access to NVD
4. dependency-check-report.xml"""
                        break
                    case 'SonarQube Analysis':
                        cause = "SonarQube analysis could not complete."
                        fix = """Check:
1. SonarQube server is up
2. Jenkins SonarQube configuration (server name = 'sonar')
3. Token / credentials
4. Network connectivity"""
                        break
                    case 'SonarQube Quality Gate':
                        cause = "SonarQube Quality Gate rejected the build."
                        fix = """Open SonarQube dashboard and inspect:
- Bugs, Vulnerabilities, Code Smells
- Coverage, Duplications
- Quality Gate conditions"""
                        break
                    case 'Build Docker Image':
                        cause = "Docker image build failed."
                        fix = """Check:
1. Dockerfile syntax
2. Base image availability
3. Docker daemon status
4. Disk space on agent"""
                        break
                    case 'Trivy Image Scan':
                        cause = "Trivy found HIGH or CRITICAL vulnerabilities."
                        fix = """Review attached reports:
trivy-report.txt / .json / .html

Recommended actions:
1. Update vulnerable packages / base image
2. Rebuild image
3. Re-run pipeline"""
                        break
                    case 'Push Docker Image to Docker Hub':
                        cause = "Failed to push image to Docker Hub."
                        fix = """Check:
1. Docker Hub credentials (credentialsId: dockerpassword)
2. Repository name & permissions
3. Network connectivity"""
                        break
                    case 'Deploy to Kubernetes':
                        cause = "Kubernetes deployment or rollout failed."
                        fix = """Check the attached file: kubernetes-failure-diagnostics.txt

Common causes:
- ImagePullBackOff / ErrImagePull
- CrashLoopBackOff
- Insufficient resources
- Wrong image tag
- Readiness/Liveness probe failure
- Incorrect labels or selectors"""
                        break
                    case 'OWASP ZAP Scan':
                        cause = "OWASP ZAP scan failed."
                        fix = """Check:
1. Application URL is reachable
2. Kubernetes Service / NodePort
3. Application is fully up
4. ZAP container can reach the app"""
                        break
                    default:
                        cause = "An unexpected error occurred."
                        fix = "Open the Jenkins console log for the full stack trace."
                }

                emailext(
                    subject: "❌ PIPELINE FAILED #${env.BUILD_NUMBER} - ${env.JOB_NAME} [${env.FAILED_STAGE ?: 'Unknown'}]",
                    mimeType: 'text/html',
                    attachLog: true,
                    attachmentsPattern: 'kubernetes-failure-diagnostics.txt,trivy-report.txt,trivy-report.html,trivy-report.json,dependency-check-report.html,dependency-check-report.xml,zap-report.html',
                    to: '227dushyantsharma@gmail.com',
                    body: """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
body { font-family: Arial, sans-serif; background: #f4f6f9; padding: 20px; }
.container { max-width: 850px; margin: auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
.header { background: linear-gradient(135deg,#dc3545,#e4606e); color: white; padding: 30px; text-align: center; }
.content { padding: 30px; }
.failed { color: white; background: #dc3545; padding: 8px 18px; border-radius: 20px; font-weight: bold; }
table { width: 100%; border-collapse: collapse; margin-top: 20px; }
th, td { padding: 12px; border-bottom: 1px solid #eee; text-align: left; vertical-align: top; }
th { width: 30%; background: #f8f9fa; }
.error-box { background: #fff3cd; border-left: 5px solid #ffc107; padding: 15px; margin-top: 20px; border-radius: 0 6px 6px 0; }
.fix-box { background: #e9f7ef; border-left: 5px solid #198754; padding: 15px; margin-top: 20px; border-radius: 0 6px 6px 0; }
.debug-box { background: #f1f3f5; border-left: 5px solid #6c757d; padding: 15px; margin-top: 20px; border-radius: 0 6px 6px 0; }
pre { background: #212529; color: #f8f9fa; padding: 12px; border-radius: 6px; overflow-x: auto; white-space: pre-wrap; }
.footer { padding: 20px; text-align: center; color: #777; font-size: 13px; }
a { color: #0d6efd; }
</style>
</head>
<body>
<div class="container">
<div class="header">
<h1>❌ PIPELINE FAILED</h1>
<h2>${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>
</div>
<div class="content">
<p><strong>Status:</strong> <span class="failed">FAILED</span></p>

<table>
<tr><th>Project</th><td>${env.JOB_NAME}</td></tr>
<tr><th>Build Number</th><td>#${env.BUILD_NUMBER}</td></tr>
<tr><th>Failed Stage</th><td><strong>${env.FAILED_STAGE ?: 'Unknown'}</strong></td></tr>
<tr><th>Git Commit</th><td>${env.GIT_COMMIT_SHORT ?: 'N/A'}</td></tr>
<tr><th>Environment</th><td>${DEPLOY_ENV}</td></tr>
<tr><th>Duration</th><td>${currentBuild.durationString}</td></tr>
<tr><th>Jenkins Build</th><td><a href="${env.BUILD_URL}">Open Build</a></td></tr>
</table>

<div class="error-box">
<h3>🔴 What Failed?</h3>
<p><strong>Stage:</strong> ${env.FAILED_STAGE ?: 'Unknown'}</p>
<p><strong>Exact Error:</strong></p>
<pre>${env.FAILED_ERROR ?: 'No detailed error message captured'}</pre>
</div>

<div class="error-box">
<h3>🧠 Probable Root Cause</h3>
<p>${cause}</p>
</div>

<div class="fix-box">
<h3>🛠️ How To Fix It</h3>
<pre>${fix}</pre>
</div>

<div class="debug-box">
<h3>🔍 Debugging Information</h3>
<ul>
<li>Full Jenkins Console Log is attached</li>
<li>Kubernetes diagnostics attached (if deployment failed)</li>
<li>Trivy / Dependency-Check / ZAP reports attached (when available)</li>
</ul>
<p><a href="${env.BUILD_URL}console">Open Full Console Output</a></p>
</div>

<h3>🚨 Recommended Next Steps</h3>
<ol>
<li>Open the Jenkins Console and go to the failed stage.</li>
<li>Read the exact error message.</li>
<li>Check the attached reports / diagnostics file.</li>
<li>Fix the root cause.</li>
<li>Re-run the pipeline.</li>
</ol>
</div>
<div class="footer">
<p><strong>Powered by Jenkins • Docker • Kubernetes • SonarQube • Trivy • OWASP ZAP</strong></p>
<p>Automated DevSecOps Failure Analysis</p>
</div>
</div>
</body>
</html>
"""
                )
            }
        }

        always {
            // Clean workspace only after emails and artifacts are handled
            echo "Cleaning workspace..."
            cleanWs(deleteDirs: true, notFailBuild: true)
        }
    }
}
