pipeline {
  agent {
      label 'azure'
  }
  environment{
        VERSION = "${env.BUILD_ID}"
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
            post {
              always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco,exec'
              }
            }
      }
      stage('Mutation Test - PIT') {
          steps {
              sh 'mvn org.pitest:pitest-maven:mutationCoverage'
          }
          post {
            always {
              pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
            }
          }
      }
      stage('SonarQube -SAST') {
          steps {
                withSonarQubeEnv('sonar-server') {
                     sh 'mvn sonar:sonar'
                }
          }
      }
      stage('checking qualitu gate') {
          steps {
              timeout(time: 2, unit: 'MINUTES') {
                  waitForQualityGate abortPipeline: true

              }
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
      stage('Deploying to kubernetes') {
          steps {
              sh "sed -i 's#replace#/bill3213/numeric-app:${VERSION}#g' k8s_deployment_service.yaml"
              sh 'kubectl apply -f k8s_deployment_service.yaml'
              sh 'kubectl apply -f node-app-deployment.yaml'
              sh 'kubectl apply -f node-service.yaml'
          }
      }
  }

}