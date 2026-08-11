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
        skipDefaultCheckout(true)
    }

    parameters {
        string(
            name: 'APP_URL',
            defaultValue: 'http://13.233.121.103:30007',
            description: 'Application URL / Kubernetes NodePort'
        )
    }

    environment {
        // ============================================================
        // SONARQUBE
        // ============================================================
        SONARQUBE_SERVER       = 'sonar'
        SONAR_PROJECT_KEY      = 'DevOpsProject'
        SONAR_URL              = 'http://65.0.81.202:9000/dashboard?id=DevOpsProject'
        SONAR_TOKEN_CREDENTIAL = 'sonarqube-token'

        // ============================================================
        // DOCKER
        // ============================================================
        IMAGE_NAME     = 'fistpipeline'
        DOCKERHUB_REPO = 'dushyantsharmma/fistpipeline'

        // ============================================================
        // KUBERNETES
        // ============================================================
        K8S_DEPLOYMENT = 'simple-webapp-deployment'
        K8S_NAMESPACE  = 'default'
        CONTAINER_NAME = 'simple-webapp'

        // ============================================================
        // ENVIRONMENT
        // ============================================================
        DEPLOY_ENV = 'Production'

        // ============================================================
        // PATHS
        // ============================================================
        DEP_CHECK_DATA  = '/var/lib/jenkins/dependency-check-data'
        TRIVY_TEMP      = '/var/lib/jenkins/trivy-temp'
        KUBECONFIG_PATH = '/var/lib/jenkins/.kube/config'
    }

    stages {

        // ============================================================
        // 1. CHECKOUT
        // ============================================================
        stage('Checkout') {
            steps {
                script {
                    try {
                        git(
                            branch: 'main',
                            url: 'https://github.com/Dushyantsharmma/DevOpsProject.git'
                        )
                        env.GIT_COMMIT_SHORT = sh(
                            script: 'git rev-parse --short HEAD',
                            returnStdout: true
                        ).trim()
                        echo "Git Commit: ${env.GIT_COMMIT_SHORT}"
                    } catch (err) {
                        env.FAILED_STAGE = 'Checkout'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ============================================================
        // 2. MAVEN BUILD
        // ============================================================
        stage('Maven Build') {
            steps {
                script {
                    try {
                        sh '''
                            set -eux
                            echo "======================================"
                            echo " Maven Build"
                            echo "======================================"
                            mvn clean package -DskipTests
                        '''
                    } catch (err) {
                        env.FAILED_STAGE = 'Maven Build'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
            post {
                success {
                    archiveArtifacts(
                        artifacts: 'target/*.war',
                        fingerprint: true,
                        allowEmptyArchive: false
                    )
                }
            }
        }

        // ============================================================
        // 3. OWASP DEPENDENCY CHECK
        // ============================================================
        stage('OWASP Dependency Check') {
            steps {
                script {
                    try {
                        withCredentials([
                            string(
                                credentialsId: 'nvd-api-key',
                                variable: 'NVD_API_KEY'
                            )
                        ]) {
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
                            dependencyCheckPublisher(
                                pattern: '**/dependency-check-report.xml'
                            )
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

        // ============================================================
        // 4. SONARQUBE ANALYSIS
        // ============================================================
        stage('SonarQube Analysis') {
            steps {
                script {
                    try {
                        withSonarQubeEnv("${SONARQUBE_SERVER}") {
                            withCredentials([
                                string(
                                    credentialsId: "${SONAR_TOKEN_CREDENTIAL}",
                                    variable: 'SONAR_TOKEN'
                                )
                            ]) {
                                sh '''
                                    set -eux
                                    echo "======================================"
                                    echo " SonarQube Analysis"
                                    echo "======================================"
                                    mvn \
                                      org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                                      -Dsonar.projectKey="${SONAR_PROJECT_KEY}" \
                                      -Dsonar.token="${SONAR_TOKEN}"
                                    echo ""
                                    echo "=== SonarQube Task Metadata ==="
                                    test -f target/sonar/report-task.txt
                                    cat target/sonar/report-task.txt
                                '''
                            }
                        }
                    } catch (err) {
                        env.FAILED_STAGE = 'SonarQube Analysis'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ============================================================
        // 5. SONARQUBE QUALITY GATE (direct polling – no waitForQualityGate)
        // ============================================================
        stage('SonarQube Quality Gate') {
            steps {
                script {
                    try {
                        withSonarQubeEnv("${SONARQUBE_SERVER}") {
                            withCredentials([
                                string(
                                    credentialsId: "${SONAR_TOKEN_CREDENTIAL}",
                                    variable: 'SONAR_TOKEN'
                                )
                            ]) {
                                sh '''
                                    set -eu
                                    echo "======================================"
                                    echo " SonarQube Quality Gate"
                                    echo "======================================"

                                    REPORT_FILE="target/sonar/report-task.txt"
                                    if [ ! -f "$REPORT_FILE" ]; then
                                        echo "ERROR: Sonar report-task.txt not found."
                                        exit 1
                                    fi

                                    CE_TASK_ID=$(awk -F= '$1=="ceTaskId"{print $2}' "$REPORT_FILE")
                                    SONAR_SERVER=$(awk -F= '$1=="serverUrl"{print $2}' "$REPORT_FILE")

                                    if [ -z "$SONAR_SERVER" ]; then
                                        SONAR_SERVER="${SONAR_HOST_URL}"
                                    fi

                                    echo "SonarQube Server: ${SONAR_SERVER}"
                                    echo "CE Task ID: ${CE_TASK_ID}"

                                    if [ -z "$CE_TASK_ID" ]; then
                                        echo "ERROR: SonarQube CE task ID not found."
                                        exit 1
                                    fi

                                    MAX_ATTEMPTS=60
                                    ATTEMPT=1

                                    while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
                                        echo ""
                                        echo "SonarQube check ${ATTEMPT}/${MAX_ATTEMPTS}"

                                        CE_RESPONSE=$(curl -fsS -u "${SONAR_TOKEN}:" "${SONAR_SERVER}/api/ce/task?id=${CE_TASK_ID}")

                                        CE_STATUS=$(printf '%s' "$CE_RESPONSE" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(data["task"]["status"])
')

                                        echo "Compute Engine Status: ${CE_STATUS}"

                                        case "$CE_STATUS" in
                                            SUCCESS)
                                                echo "SonarQube analysis completed."
                                                break
                                                ;;
                                            FAILED)
                                                echo "SonarQube analysis FAILED."
                                                printf '%s\n' "$CE_RESPONSE"
                                                exit 1
                                                ;;
                                            CANCELED)
                                                echo "SonarQube analysis was CANCELED."
                                                exit 1
                                                ;;
                                            PENDING|IN_PROGRESS)
                                                echo "SonarQube is processing analysis..."
                                                sleep 2
                                                ;;
                                            *)
                                                echo "Unknown SonarQube status: ${CE_STATUS}"
                                                exit 1
                                                ;;
                                        esac

                                        ATTEMPT=$((ATTEMPT + 1))
                                    done

                                    if [ "$ATTEMPT" -gt "$MAX_ATTEMPTS" ]; then
                                        echo "ERROR: SonarQube analysis timeout."
                                        exit 1
                                    fi

                                    ANALYSIS_ID=$(printf '%s' "$CE_RESPONSE" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(data["task"].get("analysisId", ""))
')

                                    if [ -z "$ANALYSIS_ID" ]; then
                                        echo "ERROR: analysisId not found."
                                        exit 1
                                    fi

                                    echo "Analysis ID: ${ANALYSIS_ID}"

                                    QG_RESPONSE=$(curl -fsS -u "${SONAR_TOKEN}:" \
                                        "${SONAR_SERVER}/api/qualitygates/project_status?analysisId=${ANALYSIS_ID}")

                                    QG_STATUS=$(printf '%s' "$QG_RESPONSE" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(data["projectStatus"]["status"])
')

                                    echo ""
                                    echo "======================================"
                                    echo " QUALITY GATE RESULT"
                                    echo "======================================"
                                    echo "Status: ${QG_STATUS}"

                                    printf '%s\n' "$QG_RESPONSE" > sonar-quality-gate.json

                                    if [ "$QG_STATUS" != "OK" ]; then
                                        echo ""
                                        echo "======================================"
                                        echo " ❌ QUALITY GATE FAILED"
                                        echo "======================================"
                                        printf '%s\n' "$QG_RESPONSE"
                                        exit 1
                                    fi

                                    echo ""
                                    echo "======================================"
                                    echo " ✅ QUALITY GATE PASSED"
                                    echo "======================================"
                                '''

                                archiveArtifacts(
                                    artifacts: 'sonar-quality-gate.json',
                                    allowEmptyArchive: false,
                                    fingerprint: true
                                )
                            }
                        }
                    } catch (err) {
                        env.FAILED_STAGE = 'SonarQube Quality Gate'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ============================================================
        // 6. BUILD DOCKER IMAGE
        // ============================================================
        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        sh """
                            set -eux
                            echo "======================================"
                            echo " Building Docker Image"
                            echo "======================================"
                            docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                            echo ""
                            echo "Docker Image:"
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

        // ============================================================
        // 7. TRIVY IMAGE SCAN
        // ============================================================
        stage('Trivy Image Scan') {
            steps {
                script {
                    try {
                        sh """
                            set -eu
                            mkdir -p ${TRIVY_TEMP}
                            echo "======================================"
                            echo " Trivy Security Scan"
                            echo "======================================"

                            echo "=== TXT Report ==="
                            TMPDIR=${TRIVY_TEMP} trivy image \
                                --skip-version-check \
                                --severity HIGH,CRITICAL \
                                --format table \
                                --output trivy-report.txt \
                                --no-progress \
                                ${IMAGE_NAME}:${BUILD_NUMBER}

                            echo "=== JSON Report ==="
                            TMPDIR=${TRIVY_TEMP} trivy image \
                                --skip-version-check \
                                --severity HIGH,CRITICAL \
                                --format json \
                                --output trivy-report.json \
                                --no-progress \
                                ${IMAGE_NAME}:${BUILD_NUMBER}

                            echo "=== HTML Report ==="
                            TMPDIR=${TRIVY_TEMP} trivy image \
                                --skip-version-check \
                                --severity HIGH,CRITICAL \
                                --format template \
                                --template "@contrib/html.tpl" \
                                --output trivy-report.html \
                                --no-progress \
                                ${IMAGE_NAME}:${BUILD_NUMBER} || \
                                echo "HTML template unavailable."
                        """

                        archiveArtifacts(
                            artifacts: 'trivy-report.txt,trivy-report.json,trivy-report.html',
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

                        echo "HIGH vulnerabilities: ${highCount}"
                        echo "CRITICAL vulnerabilities: ${criticalCount}"

                        if (criticalCount > 0 || highCount > 0) {
                            error("Trivy Security Gate Failed -> CRITICAL: ${criticalCount}, HIGH: ${highCount}. Check Trivy reports.")
                        }
                    } catch (err) {
                        env.FAILED_STAGE = 'Trivy Image Scan'
                        env.FAILED_ERROR = err.getMessage()
                        throw err
                    }
                }
            }
        }

        // ============================================================
        // 8. PUSH DOCKER IMAGE
        // ============================================================
        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    try {
                        withDockerRegistry(
                            credentialsId: 'dockerpassword',
                            url: 'https://index.docker.io/v1/'
                        ) {
                            sh """
                                set -eux
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

        // ============================================================
        // 9. DEPLOY TO KUBERNETES  (FIXED – no Groovy $ conflict)
        // ============================================================
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    try {
                        withEnv([
                            "K8S_DEPLOYMENT=${env.K8S_DEPLOYMENT}",
                            "K8S_NAMESPACE=${env.K8S_NAMESPACE}",
                            "CONTAINER_NAME=${env.CONTAINER_NAME}",
                            "DOCKERHUB_REPO=${env.DOCKERHUB_REPO}",
                            "BUILD_NUMBER_VALUE=${env.BUILD_NUMBER}",
                            "KUBECONFIG_PATH_VALUE=${env.KUBECONFIG_PATH}"
                        ]) {
                            sh '''
                                set -eu
                                export KUBECONFIG="${KUBECONFIG_PATH_VALUE}"

                                echo "======================================"
                                echo " Kubernetes Context"
                                echo "======================================"
                                kubectl config current-context

                                echo ""
                                echo "======================================"
                                echo " Kubernetes Nodes"
                                echo "======================================"
                                kubectl get nodes -o wide

                                echo ""
                                echo "======================================"
                                echo " Applying Kubernetes Manifest"
                                echo "======================================"
                                kubectl apply -f k8s-deployment.yml

                                echo ""
                                echo "======================================"
                                echo " Updating Deployment Image"
                                echo "======================================"
                                kubectl set image \
                                    deployment/"${K8S_DEPLOYMENT}" \
                                    "${CONTAINER_NAME}"="${DOCKERHUB_REPO}:${BUILD_NUMBER_VALUE}" \
                                    -n "${K8S_NAMESPACE}"

                                echo ""
                                echo "======================================"
                                echo " Waiting For Rollout"
                                echo "======================================"
                                kubectl rollout status \
                                    deployment/"${K8S_DEPLOYMENT}" \
                                    -n "${K8S_NAMESPACE}" \
                                    --timeout=180s

                                echo ""
                                echo "======================================"
                                echo " Deployment"
                                echo "======================================"
                                kubectl get deployment \
                                    "${K8S_DEPLOYMENT}" \
                                    -n "${K8S_NAMESPACE}"

                                echo ""
                                echo "======================================"
                                echo " Pods"
                                echo "======================================"
                                kubectl get pods \
                                    -n "${K8S_NAMESPACE}" \
                                    -o wide

                                echo ""
                                echo "======================================"
                                echo " Services"
                                echo "======================================"
                                kubectl get svc \
                                    -n "${K8S_NAMESPACE}"

                                echo ""
                                echo "======================================"
                                echo " Rollout History"
                                echo "======================================"
                                kubectl rollout history \
                                    deployment/"${K8S_DEPLOYMENT}" \
                                    -n "${K8S_NAMESPACE}"
                            '''
                        }
                    } catch (err) {
                        env.FAILED_STAGE = 'Deploy to Kubernetes'
                        env.FAILED_ERROR = err.getMessage()

                        // Collect rich diagnostics into a file that will be archived + emailed
                        withEnv([
                            "K8S_DEPLOYMENT=${env.K8S_DEPLOYMENT}",
                            "K8S_NAMESPACE=${env.K8S_NAMESPACE}",
                            "KUBECONFIG_PATH_VALUE=${env.KUBECONFIG_PATH}"
                        ]) {
                            sh '''
                                export KUBECONFIG="${KUBECONFIG_PATH_VALUE}"

                                {
                                    echo "================================================"
                                    echo " KUBERNETES FAILURE DIAGNOSTICS"
                                    echo "================================================"
                                    echo "Generated at: $(date)"
                                    echo ""

                                    echo "=== Nodes ==="
                                    kubectl get nodes -o wide || true
                                    echo ""

                                    echo "=== All Pods ==="
                                    kubectl get pods -A -o wide || true
                                    echo ""

                                    echo "=== Deployment ==="
                                    kubectl get deployment "${K8S_DEPLOYMENT}" -n "${K8S_NAMESPACE}" -o wide || true
                                    echo ""

                                    echo "=== ReplicaSets ==="
                                    kubectl get rs -n "${K8S_NAMESPACE}" || true
                                    echo ""

                                    echo "=== Application Pods ==="
                                    kubectl get pods -n "${K8S_NAMESPACE}" -l app=simple-webapp -o wide || true
                                    echo ""

                                    echo "=== Deployment Description ==="
                                    kubectl describe deployment "${K8S_DEPLOYMENT}" -n "${K8S_NAMESPACE}" || true
                                    echo ""

                                    echo "=== Recent Kubernetes Events ==="
                                    kubectl get events -n "${K8S_NAMESPACE}" --sort-by='.lastTimestamp' || true
                                    echo ""

                                    echo "=== Pod Descriptions and Logs ==="
                                    for POD in $(kubectl get pods -n "${K8S_NAMESPACE}" -l app=simple-webapp -o name 2>/dev/null); do
                                        echo ""
                                        echo "----------------------------------------"
                                        echo "POD: ${POD}"
                                        echo "----------------------------------------"

                                        echo ""
                                        echo "=== Pod Description ==="
                                        kubectl describe "${POD}" -n "${K8S_NAMESPACE}" || true

                                        echo ""
                                        echo "=== Pod Logs (last 200 lines) ==="
                                        kubectl logs "${POD}" -n "${K8S_NAMESPACE}" --all-containers=true --tail=200 || true
                                    done
                                } > kubernetes-failure-diagnostics.txt 2>&1 || true
                            '''
                        }

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
    }

    // ================================================================
    // POST ACTIONS
    // ================================================================
    post {

        success {
            emailext(
                subject: "✅ PIPELINE SUCCESS #${env.BUILD_NUMBER} - ${env.JOB_NAME}",
                mimeType: 'text/html',
                attachLog: false,
                attachmentsPattern: 'target/*.war,sonar-quality-gate.json,trivy-report.txt,trivy-report.html,trivy-report.json,dependency-check-report.html,dependency-check-report.xml',
                to: '227dushyantsharma@gmail.com',
                body: """
<!DOCTYPE html>
<html>
<body>
<h1>🟢 PIPELINE SUCCESSFUL</h1>
<h2>${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>
<hr>
<h3>Deployment Summary</h3>
<table border="1" cellpadding="8">
<tr><td><b>Status</b></td><td>SUCCESS</td></tr>
<tr><td><b>Git Commit</b></td><td>${env.GIT_COMMIT_SHORT ?: 'N/A'}</td></tr>
<tr><td><b>Environment</b></td><td>${DEPLOY_ENV}</td></tr>
<tr><td><b>Docker Image</b></td><td>${DOCKERHUB_REPO}:${BUILD_NUMBER}</td></tr>
<tr><td><b>Kubernetes Deployment</b></td><td>${K8S_DEPLOYMENT}</td></tr>
<tr><td><b>Namespace</b></td><td>${K8S_NAMESPACE}</td></tr>
<tr><td><b>Application</b></td><td><a href="${params.APP_URL}">${params.APP_URL}</a></td></tr>
<tr><td><b>SonarQube</b></td><td><a href="${SONAR_URL}">Open SonarQube</a></td></tr>
<tr><td><b>Jenkins Build</b></td><td><a href="${env.BUILD_URL}">Open Jenkins Build</a></td></tr>
</table>

<h3>🎯 Pipeline Stages Passed</h3>
<ul>
<li>✅ Checkout</li>
<li>✅ Maven Build</li>
<li>✅ OWASP Dependency Check</li>
<li>✅ SonarQube Analysis</li>
<li>✅ SonarQube Quality Gate</li>
<li>✅ Docker Image Build</li>
<li>✅ Trivy Security Scan</li>
<li>✅ Docker Hub Push</li>
<li>✅ Kubernetes Deployment</li>
</ul>

<h3>📎 Reports Attached</h3>
<ul>
<li>📦 WAR Artifact</li>
<li>📊 SonarQube Quality Gate JSON</li>
<li>🛡️ Trivy TXT / JSON / HTML</li>
<li>🔍 OWASP Dependency Check HTML / XML</li>
</ul>

<p>Application successfully built, scanned, pushed to Docker Hub and deployed to Kubernetes.</p>
</body>
</html>
"""
            )
        }

        failure {
            script {
                def cause = "Unknown failure."
                def fix   = "Open Jenkins Console Output and inspect the failed stage."

                switch (env.FAILED_STAGE) {
                    case 'Checkout':
                        cause = "Git repository checkout failed."
                        fix = """
1. Check GitHub repository URL.
2. Check branch name.
3. Check GitHub credentials / token.
4. Check network connectivity from Jenkins agent.
"""
                        break
                    case 'Maven Build':
                        cause = "Maven could not compile/package the application."
                        fix = """
1. Check Java version on the agent.
2. Inspect pom.xml for errors.
3. Check Maven dependency resolution.
4. Read the compilation error in the console log.
"""
                        break
                    case 'OWASP Dependency Check':
                        cause = "OWASP Dependency-Check failed."
                        fix = """
1. Verify NVD API key is valid.
2. Check Dependency-Check database path and permissions.
3. Check network connectivity to NVD.
4. Open the dependency-check-report files.
"""
                        break
                    case 'SonarQube Analysis':
                        cause = "SonarQube analysis could not complete."
                        fix = """
1. Confirm SonarQube server is reachable.
2. Check Jenkins SonarQube server configuration.
3. Verify the SonarQube token.
4. Check network connectivity.
"""
                        break
                    case 'SonarQube Quality Gate':
                        cause = "SonarQube Quality Gate rejected the build."
                        fix = """
1. Open the SonarQube dashboard.
2. Review Bugs, Vulnerabilities, Code Smells, Coverage, Duplications.
3. Identify the failed Quality Gate condition.
4. Fix the issues in the code.
5. Commit and re-run the pipeline.
"""
                        break
                    case 'Build Docker Image':
                        cause = "Docker image build failed."
                        fix = """
1. Inspect the Dockerfile.
2. Check base image availability.
3. Verify Docker daemon is running.
4. Check disk space on the agent.
5. Read the Docker build error carefully.
"""
                        break
                    case 'Trivy Image Scan':
                        cause = "Trivy detected HIGH or CRITICAL vulnerabilities."
                        fix = """
1. Open trivy-report.txt / trivy-report.json / trivy-report.html.
2. Identify the vulnerable packages.
3. Update the base image or the vulnerable packages.
4. Rebuild and re-run the pipeline.
"""
                        break
                    case 'Push Docker Image to Docker Hub':
                        cause = "Docker image push failed."
                        fix = """
1. Verify Docker Hub credentials.
2. Check repository name and permissions.
3. Confirm network connectivity to Docker Hub.
"""
                        break
                    case 'Deploy to Kubernetes':
                        cause = "Kubernetes deployment or rollout failed."
                        fix = """
1. Open the attached kubernetes-failure-diagnostics.txt.
2. Check Pod status (ImagePullBackOff, CrashLoopBackOff, etc.).
3. Examine Kubernetes Events.
4. Read Pod logs.
5. Verify the image tag exists on Docker Hub.
6. Check readiness/liveness probes and resource limits.
"""
                        break
                }

                emailext(
                    subject: "❌ PIPELINE FAILED #${env.BUILD_NUMBER} - ${env.JOB_NAME} [${env.FAILED_STAGE ?: 'Unknown'}]",
                    mimeType: 'text/html',
                    attachLog: true,
                    attachmentsPattern: 'target/*.war,sonar-quality-gate.json,kubernetes-failure-diagnostics.txt,trivy-report.txt,trivy-report.html,trivy-report.json,dependency-check-report.html,dependency-check-report.xml',
                    to: '227dushyantsharma@gmail.com',
                    body: """
<!DOCTYPE html>
<html>
<body>
<h1>🔴 PIPELINE FAILED</h1>
<h2>${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>
<hr>

<h2>❌ What Failed?</h2>
<p><b>Failed Stage:</b> ${env.FAILED_STAGE ?: 'Unknown'}</p>

<h3>🔴 Exact Error</h3>
<pre>${env.FAILED_ERROR ?: 'No exception message captured. Check Console Output.'}</pre>

<h3>🧠 Probable Root Cause</h3>
<p>${cause}</p>

<h3>🛠️ How To Fix</h3>
<pre>${fix}</pre>

<h3>🔍 Debug Information</h3>
<ul>
<li>📋 Full Jenkins Console Log is attached</li>
<li>☸️ kubernetes-failure-diagnostics.txt is attached (if Deploy stage failed)</li>
<li>🛡️ Trivy reports are attached (when available)</li>
<li>🔍 Dependency-Check reports are attached (when available)</li>
<li>📊 SonarQube Quality Gate JSON is attached (when available)</li>
</ul>

<h3>🔗 Quick Links</h3>
<ul>
<li><a href="${env.BUILD_URL}">Open Jenkins Build</a></li>
<li><a href="${env.BUILD_URL}console">Open Console Output</a></li>
<li><a href="${SONAR_URL}">Open SonarQube</a></li>
</ul>

<h3>🚨 Next Steps</h3>
<ol>
<li>Open the failed Jenkins stage.</li>
<li>Read the exact error in the console.</li>
<li>Open the relevant attached report / diagnostics file.</li>
<li>Fix the root cause.</li>
<li>Commit the fix.</li>
<li>Re-run the pipeline.</li>
</ol>
</body>
</html>
"""
                )
            }
        }

        always {
            echo "Cleaning Jenkins workspace..."
            cleanWs(deleteDirs: true, notFailBuild: true)
        }
    }
}
