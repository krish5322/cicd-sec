@Library('slack') _

pipeline {
  agent {
      label 'azure'
  }
  environment{
        VERSION = "${env.BUILD_ID}"
        deploymentName = "devsecops"
        containerName = "devsecops-container"
        serviceName = "devsecops-svc"
        imageName = "bill3213/numeric-app:${VERSION}"
        applicationURL = "http://devsec.20.204.236.196.nip.io"
        applicationURI = "/increment/99"
  }

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar'
            }
      }
      stage('Unit test') {
            steps {
              sh "mvn test"
            }

      }
      stage('Mutation Test - PIT') {
          steps {
              sh 'mvn org.pitest:pitest-maven:mutationCoverage'
          }

      }
      stage('SonarQube -SAST') {
          steps {
                withSonarQubeEnv('sonar-server2') {
                     sh 'mvn sonar:sonar'
                }
          }
      }
      stage('vulnerability Scan - Docker') {
        steps {
          parallel(
            "Dependency Scan": {
                sh "mvn dependency-check:check"
            },
            "Trivy Scan": {
                sh "docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.31.3  image adoptopenjdk/openjdk8:alpine-slim"
            },
            "OPA Conftest": {
                sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
            }
          )
        }
      }
      stage('Docker Build and Push') {
          steps {
              script{
                        withCredentials([string(credentialsId: 'docker_secret', variable: 'docker_secret')]) {
                             sh '''
                             docker build -t bill3213/numeric-app:${VERSION} .
                             docker login -u bill3213 -p $docker_secret
                             docker push bill3213/numeric-app:${VERSION}
                             docker rmi bill3213/numeric-app:${VERSION}
                             '''
                        }

              }
          }
      }
      stage('vulnerability Scan - kubernetes') {
         steps {
           parallel(
             "OPA Scan": {
                sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy k8s-tests.rego k8s_deployment_service.yaml'
             },
             "Trivy Scan": {
                sh "bash trivy-scan-k8s.sh"
             }
           )
         }
      }
      //stage('Deploying to kubernetes') {
      //     steps {
      //        sh "sed -i 's#replace#bill3213/numeric-app:${VERSION}#g' k8s_deployment_service.yaml"
      //        sh 'kubectl apply -f k8s_deployment_service.yaml'
      //        sh 'kubectl apply -f node-app-deployment.yaml'
      //        sh 'kubectl apply -f node-service.yaml'
      //    }
      //}
      stage('k8s deployment - DEV') {
          steps {
            parallel(
              "Deployment": {
                 sh "bash k8s-script.sh"
                 sh 'kubectl apply -f node-app-deployment.yaml'
                 sh 'kubectl apply -f node-service.yaml'
              },
              "Rollout Status": {
                 sh "bash k8s-deployment-rollout-status.sh"
              }
            )
          }
      }
      stage('Integration Test - DEV') {
          steps {
            sh "bash integration-test.sh"
          }
      }
      stage('Promote to PROD') {
        steps {
          timeout(time: 2, unit: 'DAYS') {
            input 'Do you Want to Approve the Deployment to Production Environment?'
          }
        }
      }
      stage('K8s deployment - PROD') {
        steps {
          parallel(
            "Deployment": {
               sh 'kubectl -n prod apply -f node-app-deployment-prod.yaml'
               sh 'kubectl -n prod apply -f node-service-prod.yaml'
               sh "sed -i 's#replace#${imageName}#g' k8s_prod_deployment_service.yaml"
               sh "kubectl -n prod apply -f k8s_prod_deployment_service.yaml"
            },
            "Rollout Status": {
               sh "bash k8s-prod-deployment-rollout-status.sh"
            }
          )
        }
      }
  }
  post {
      always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco,exec'
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'

          sendNotification currentBuild.result
      }
  }
}

