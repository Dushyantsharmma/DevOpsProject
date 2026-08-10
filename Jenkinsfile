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

        // ==============================
        // SonarQube
        // ==============================
        SONARQUBE_SERVER  = 'sonar'
        SONAR_PROJECT_KEY = 'DevOpsProject'
        SONAR_URL         = 'http://65.0.81.202:9000/dashboard?id=DevOpsProject'

        // ==============================
        // Docker
        // ==============================
        IMAGE_NAME     = 'fistpipeline'
        DOCKERHUB_REPO = 'dushyantsharmma/fistpipeline'

        // ==============================
        // Kubernetes
        // ==============================
        K8S_DEPLOYMENT = 'simple-webapp-deployment'
        K8S_NAMESPACE  = 'default'
        CONTAINER_NAME = 'simple-webapp'

        // ==============================
        // Environment
        // ==============================
        DEPLOY_ENV = 'Production'

        // ==============================
        // Paths
        // ==============================
        DEP_CHECK_DATA  = '/var/lib/jenkins/dependency-check-data'
        TRIVY_TEMP      = '/var/lib/jenkins/trivy-temp'
        KUBECONFIG_PATH = '/var/lib/jenkins/.kube/config'

        // ==============================
        // Failure diagnostics
        // ==============================
        FAILED_STAGE = 'Unknown'
        FAILED_ERROR = 'No detailed error captured.'
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

            post {
                success {
                    echo "✅ Checkout completed successfully"
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
                    archiveArtifacts(
                        artifacts: 'target/*.war',
                        fingerprint: true
                    )
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


        // ==========================================================
        // SONARQUBE
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
                            docker build \
                                -t ${IMAGE_NAME}:${BUILD_NUMBER} .

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
        // TRIVY
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

                            echo "=== Trivy HTML Report ==="

                            TMPDIR=${TRIVY_TEMP} trivy image \
                                --skip-version-check \
                                --severity HIGH,CRITICAL \
                                --format template \
                                --template "@contrib/html.tpl" \
                                --output trivy-report.html \
                                --no-progress \
                                ${IMAGE_NAME}:${BUILD_NUMBER} || \
                            echo "HTML template unavailable. JSON/TXT reports remain available."
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

                        env.TRIVY_CRITICAL = criticalCount.toString()
                        env.TRIVY_HIGH = highCount.toString()

                        if (criticalCount > 0 || highCount > 0) {

                            error """
Trivy Security Gate Failed.

CRITICAL vulnerabilities: ${criticalCount}
HIGH vulnerabilities: ${highCount}

Review:
trivy-report.txt
trivy-report.json
trivy-report.html
"""
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
        // DOCKER HUB
        // ==========================================================

        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    try {

                        withDockerRegistry(
                            credentialsId: 'dockerpassword',
                            url: 'https://index.docker.io/v1/'
                        ) {

                            sh """
                                docker tag \
                                    ${IMAGE_NAME}:${BUILD_NUMBER} \
                                    ${DOCKERHUB_REPO}:${BUILD_NUMBER}

                                docker push \
                                    ${DOCKERHUB_REPO}:${BUILD_NUMBER}
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

                            kubectl set image \
                                deployment/${K8S_DEPLOYMENT} \
                                ${CONTAINER_NAME}=${DOCKERHUB_REPO}:${BUILD_NUMBER} \
                                -n ${K8S_NAMESPACE}

                            echo "======================================"
                            echo " Waiting For Rollout"
                            echo "======================================"

                            kubectl rollout status \
                                deployment/${K8S_DEPLOYMENT} \
                                -n ${K8S_NAMESPACE} \
                                --timeout=180s

                            echo "======================================"
                            echo " Deployment Status"
                            echo "======================================"

                            kubectl get deployments \
                                -n ${K8S_NAMESPACE}

                            echo "======================================"
                            echo " Pods"
                            echo "======================================"

                            kubectl get pods \
                                -o wide \
                                -n ${K8S_NAMESPACE}

                            echo "======================================"
                            echo " Services"
                            echo "======================================"

                            kubectl get svc \
                                -n ${K8S_NAMESPACE}

                            echo "======================================"
                            echo " Rollout History"
                            echo "======================================"

                            kubectl rollout history \
                                deployment/${K8S_DEPLOYMENT} \
                                -n ${K8S_NAMESPACE}
                        """

                    } catch (err) {

                        env.FAILED_STAGE = 'Deploy to Kubernetes'
                        env.FAILED_ERROR = err.getMessage()

                        // Collect Kubernetes diagnostics immediately
                        sh """
                            export KUBECONFIG=${KUBECONFIG_PATH}

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
                            kubectl get deployment \
                                ${K8S_DEPLOYMENT} \
                                -n ${K8S_NAMESPACE} \
                                -o wide || true

                            echo ""
                            echo "=== ReplicaSets ==="
                            kubectl get rs \
                                -n ${K8S_NAMESPACE} || true

                            echo ""
                            echo "=== Pods For Deployment ==="

                            kubectl get pods \
                                -n ${K8S_NAMESPACE} \
                                -l app=${K8S_DEPLOYMENT} \
                                -o wide || true

                            echo ""
                            echo "=== Deployment Description ==="

                            kubectl describe deployment \
                                ${K8S_DEPLOYMENT} \
                                -n ${K8S_NAMESPACE} || true

                            echo ""
                            echo "=== Recent Kubernetes Events ==="

                            kubectl get events \
                                -n ${K8S_NAMESPACE} \
                                --sort-by='.lastTimestamp' || true

                            echo ""
                            echo "=== Pod Descriptions ==="

                            for POD in \$(kubectl get pods \
                                -n ${K8S_NAMESPACE} \
                                -l app=${K8S_DEPLOYMENT} \
                                -o name 2>/dev/null); do

                                echo "----------------------------------------"
                                echo "POD: \$POD"
                                echo "----------------------------------------"

                                kubectl describe \$POD \
                                    -n ${K8S_NAMESPACE} || true

                                echo ""
                                echo "=== Container Logs ==="

                                kubectl logs \$POD \
                                    -n ${K8S_NAMESPACE} \
                                    --all-containers=true \
                                    --tail=100 || true

                            done
                        """ > kubernetes-failure-diagnostics.txt 2>&1 || true

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
        // ZAP
        // ==========================================================

        stage('OWASP ZAP Scan') {
            steps {
                script {

                    try {

                        sh 'rm -f zap-report.html || true'

                        sh "chmod -R 777 ${WORKSPACE}"

                        sh """
                            echo "=== Waiting For Application ==="

                            for i in \$(seq 1 20); do

                                HTTP_CODE=\$(curl \
                                    -s \
                                    -o /dev/null \
                                    -w "%{http_code}" \
                                    ${params.APP_URL} || echo "000")

                                if echo "\$HTTP_CODE" | grep -qE "200|301|302"; then

                                    echo "Application is UP!"
                                    echo "HTTP Status: \$HTTP_CODE"

                                    break

                                fi

                                echo "Application not ready."
                                echo "HTTP Status: \$HTTP_CODE"
                                echo "Retry \$i/20"

                                sleep 5

                            done
                        """

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

        // ==========================================================
        // SUCCESS
        // ==========================================================

        success {

            emailext(
                subject: "✅ PIPELINE SUCCESS #${env.BUILD_NUMBER} - ${env.JOB_NAME}",
                mimeType: 'text/html',
                attachLog: false,

                attachmentsPattern:
                    'trivy-report.txt,' +
                    'trivy-report.html,' +
                    'trivy-report.json,' +
                    'dependency-check-report.html,' +
                    'dependency-check-report.xml,' +
                    'zap-report.html',

                to: '227dushyantsharma@gmail.com',

                body: """
<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<style>

body {
    font-family: Arial, sans-serif;
    background: #f4f6f9;
    padding: 20px;
}

.container {
    max-width: 850px;
    margin: auto;
    background: white;
    border-radius: 12px;
    overflow: hidden;
}

.header {
    background: linear-gradient(135deg,#198754,#20c997);
    color: white;
    padding: 30px;
    text-align: center;
}

.content {
    padding: 30px;
}

.status {
    color: white;
    background: #198754;
    padding: 8px 18px;
    border-radius: 20px;
    font-weight: bold;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
}

th, td {
    padding: 12px;
    border-bottom: 1px solid #eee;
    text-align: left;
}

th {
    width: 35%;
    background: #f8f9fa;
}

.success-box {
    background: #e9f7ef;
    border-left: 5px solid #198754;
    padding: 15px;
    margin-top: 20px;
}

.footer {
    padding: 20px;
    text-align: center;
    color: #777;
}

a {
    color: #0d6efd;
}

</style>

</head>

<body>

<div class="container">

<div class="header">

<h1>✅ PIPELINE SUCCESSFUL</h1>

<h2>${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>

</div>

<div class="content">

<p>
<strong>Status:</strong>
<span class="status">SUCCESS</span>
</p>

<table>

<tr>
<th>Project</th>
<td>${env.JOB_NAME}</td>
</tr>

<tr>
<th>Build</th>
<td>#${env.BUILD_NUMBER}</td>
</tr>

<tr>
<th>Build Date</th>
<td>${new Date()}</td>
</tr>

<tr>
<th>Duration</th>
<td>${currentBuild.durationString}</td>
</tr>

<tr>
<th>Git Commit</th>
<td>${env.GIT_COMMIT_SHORT ?: 'N/A'}</td>
</tr>

<tr>
<th>Environment</th>
<td>${DEPLOY_ENV}</td>
</tr>

<tr>
<th>Docker Image</th>
<td>
${DOCKERHUB_REPO}:${BUILD_NUMBER}
</td>
</tr>

<tr>
<th>Kubernetes Deployment</th>
<td>
${K8S_DEPLOYMENT}
</td>
</tr>

<tr>
<th>Kubernetes Namespace</th>
<td>
${K8S_NAMESPACE}
</td>
</tr>

<tr>
<th>Application</th>
<td>
<a href="${params.APP_URL}">
${params.APP_URL}
</a>
</td>
</tr>

<tr>
<th>SonarQube</th>
<td>
<a href="${SONAR_URL}">
View SonarQube
</a>
</td>
</tr>

<tr>
<th>Jenkins Build</th>
<td>
<a href="${env.BUILD_URL}">
Open Build
</a>
</td>
</tr>

</table>


<div class="success-box">

<h3>🎯 Pipeline Verification</h3>

<ul>

<li>✅ Source Checkout</li>

<li>✅ Maven Build</li>

<li>✅ OWASP Dependency Check</li>

<li>✅ SonarQube Analysis</li>

<li>✅ SonarQube Quality Gate</li>

<li>✅ Docker Image Build</li>

<li>✅ Trivy Security Scan</li>

<li>✅ Docker Hub Push</li>

<li>✅ Kubernetes Deployment</li>

<li>✅ Kubernetes Rollout</li>

<li>✅ OWASP ZAP Scan</li>

</ul>

</div>


<h3>📎 Security Reports</h3>

<ul>

<li>Trivy Image Scan</li>

<li>OWASP Dependency Check</li>

<li>OWASP ZAP</li>

</ul>


<h3>🚀 Deployment Result</h3>

<p>

The application passed the CI/CD and security pipeline
and was successfully deployed to Kubernetes.

</p>

</div>

<div class="footer">

<p>
Powered by Jenkins • Docker • Kubernetes • SonarQube • Trivy • OWASP ZAP
</p>

<p>
DevSecOps CI/CD Pipeline
</p>

</div>

</div>

</body>

</html>
"""
            )
        }


        // ==========================================================
        // FAILURE
        // ==========================================================

        failure {

            script {

                // -----------------------------------------------
                // Generate failure explanation
                // -----------------------------------------------

                def cause = "Unknown"

                def fix = "Check the Jenkins Console Output and attached diagnostics."

                switch (env.FAILED_STAGE) {

                    case 'Checkout':

                        cause = "Git repository checkout failed."

                        fix = """
Check:
1. Repository URL
2. Branch name
3. GitHub credentials
4. Network connectivity
"""

                        break


                    case 'Maven Build':

                        cause = "Maven could not compile/package the application."

                        fix = """
Check:
1. Java version
2. pom.xml
3. Maven dependencies
4. Compilation errors
5. Unit test/build configuration
"""

                        break


                    case 'OWASP Dependency Check':

                        cause = "OWASP Dependency-Check failed while scanning project dependencies."

                        fix = """
Check:
1. NVD API key
2. Dependency-Check database
3. Network connectivity
4. dependency-check-report.xml
"""

                        break


                    case 'SonarQube Analysis':

                        cause = "Jenkins could not complete SonarQube analysis."

                        fix = """
Check:
1. SonarQube server availability
2. Jenkins SonarQube configuration
3. SONARQUBE_SERVER name
4. SonarQube token/credentials
5. Network connectivity to SonarQube
"""

                        break


                    case 'SonarQube Quality Gate':

                        cause = "SonarQube Quality Gate rejected the build."

                        fix = """
Open SonarQube and inspect:
- Bugs
- Vulnerabilities
- Code Smells
- Coverage
- Duplications
- Quality Gate conditions
"""

                        break


                    case 'Build Docker Image':

                        cause = "Docker failed while building the container image."

                        fix = """
Check:
1. Dockerfile
2. Base image
3. Build context
4. Docker daemon
5. Disk space
6. Docker build output
"""

                        break


                    case 'Trivy Image Scan':

                        cause = "Trivy security gate detected HIGH or CRITICAL vulnerabilities."

                        fix = """
Review:
trivy-report.txt
trivy-report.json
trivy-report.html

Recommended actions:
1. Update vulnerable dependencies
2. Update base image
3. Rebuild image
4. Run Trivy again
"""

                        break


                    case 'Push Docker Image to Docker Hub':

                        cause = "Docker image could not be pushed to Docker Hub."

                        fix = """
Check:
1. Docker Hub credentials
2. Repository name
3. Docker login
4. Docker Hub permissions
5. Network connectivity
"""

                        break


                    case 'Deploy to Kubernetes':

                        cause = "Kubernetes deployment or rollout failed."

                        fix = """
Check the attached Kubernetes diagnostics.

Important commands:

kubectl get pods -A

kubectl describe pod <pod>

kubectl get events --sort-by='.lastTimestamp'

kubectl logs <pod>

kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE}

Common causes:
- ImagePullBackOff
- ErrImagePull
- CrashLoopBackOff
- insufficient resources
- incorrect image/tag
- failed readiness probe
- Kubernetes configuration error
"""

                        break


                    case 'OWASP ZAP Scan':

                        cause = "OWASP ZAP could not complete the application security scan."

                        fix = """
Check:
1. Application URL
2. Application availability
3. NodePort
4. Kubernetes service
5. ZAP container
6. Network connectivity
"""

                        break
                }


                emailext(

                    subject:
                        "❌ PIPELINE FAILED #${env.BUILD_NUMBER} - ${env.JOB_NAME}",

                    mimeType: 'text/html',

                    attachLog: true,

                    attachmentsPattern:
                        'kubernetes-failure-diagnostics.txt,' +
                        'trivy-report.txt,' +
                        'trivy-report.html,' +
                        'trivy-report.json,' +
                        'dependency-check-report.html,' +
                        'dependency-check-report.xml,' +
                        'zap-report.html',

                    to: '227dushyantsharma@gmail.com',

                    body: """

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<style>

body {
    font-family: Arial, sans-serif;
    background: #f4f6f9;
    padding: 20px;
}

.container {
    max-width: 850px;
    margin: auto;
    background: white;
    border-radius: 12px;
    overflow: hidden;
}

.header {
    background: linear-gradient(135deg,#dc3545,#e4606e);
    color: white;
    padding: 30px;
    text-align: center;
}

.content {
    padding: 30px;
}

.failed {
    color: white;
    background: #dc3545;
    padding: 8px 18px;
    border-radius: 20px;
    font-weight: bold;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
}

th, td {
    padding: 12px;
    border-bottom: 1px solid #eee;
    text-align: left;
    vertical-align: top;
}

th {
    width: 30%;
    background: #f8f9fa;
}

.error-box {
    background: #fff3cd;
    border-left: 5px solid #ffc107;
    padding: 15px;
    margin-top: 20px;
}

.fix-box {
    background: #e9f7ef;
    border-left: 5px solid #198754;
    padding: 15px;
    margin-top: 20px;
}

.debug-box {
    background: #f1f3f5;
    border-left: 5px solid #6c757d;
    padding: 15px;
    margin-top: 20px;
}

code {
    background: #212529;
    color: #fff;
    padding: 3px 6px;
    border-radius: 4px;
}

.footer {
    padding: 20px;
    text-align: center;
    color: #777;
}

a {
    color: #0d6efd;
}

</style>

</head>

<body>

<div class="container">

<div class="header">

<h1>❌ PIPELINE FAILED</h1>

<h2>${env.JOB_NAME} #${env.BUILD_NUMBER}</h2>

</div>


<div class="content">

<p>

<strong>Status:</strong>

<span class="failed">FAILED</span>

</p>


<table>

<tr>
<th>Project</th>
<td>${env.JOB_NAME}</td>
</tr>

<tr>
<th>Build Number</th>
<td>#${env.BUILD_NUMBER}</td>
</tr>

<tr>
<th>Failed Stage</th>
<td><strong>${env.FAILED_STAGE}</strong></td>
</tr>

<tr>
<th>Git Commit</th>
<td>${env.GIT_COMMIT_SHORT ?: 'N/A'}</td>
</tr>

<tr>
<th>Environment</th>
<td>${DEPLOY_ENV}</td>
</tr>

<tr>
<th>Duration</th>
<td>${currentBuild.durationString}</td>
</tr>

<tr>
<th>Jenkins Build</th>
<td>
<a href="${env.BUILD_URL}">
Open Jenkins Build
</a>
</td>
</tr>

</table>


<div class="error-box">

<h3>🔴 What Failed?</h3>

<p>

<strong>Stage:</strong>

${env.FAILED_STAGE}

</p>

<p>

<strong>Exact Error:</strong>

</p>

<pre>${env.FAILED_ERROR}</pre>

</div>


<div class="error-box">

<h3>🧠 Why Did It Probably Fail?</h3>

<p>

${cause}

</p>

</div>


<div class="fix-box">

<h3>🛠️ How To Fix It</h3>

<pre>${fix}</pre>

</div>


<div class="debug-box">

<h3>🔍 Debugging Information</h3>

<p>

The pipeline automatically collected diagnostic information.

</p>

<ul>

<li>Jenkins Console Log attached</li>

<li>Kubernetes diagnostics attached when deployment failed</li>

<li>Trivy reports attached when available</li>

<li>OWASP Dependency Check reports attached when available</li>

<li>OWASP ZAP report attached when available</li>

</ul>

<p>

<a href="${env.BUILD_URL}console">
Open Full Jenkins Console
</a>

</p>

</div>


<h3>🚨 Recommended Debug Flow</h3>

<ol>

<li>Open the Jenkins Console.</li>

<li>Go directly to the failed stage: <strong>${env.FAILED_STAGE}</strong>.</li>

<li>Read the exact error.</li>

<li>Check the attached report.</li>

<li>If Kubernetes failed, inspect <strong>kubernetes-failure-diagnostics.txt</strong>.</li>

<li>Fix the root cause.</li>

<li>Run the pipeline again.</li>

</ol>


</div>


<div class="footer">

<p>

Powered by Jenkins • Docker • Kubernetes • SonarQube • Trivy • OWASP ZAP

</p>

<p>

Automated DevSecOps Failure Analysis

</p>

</div>


</div>

</body>

</html>

"""
                )
            }
        }


        // ==========================================================
        // CLEANUP
        // ==========================================================

        cleanup {

            echo "Cleaning Jenkins workspace..."

            cleanWs()
        }
    }
}
