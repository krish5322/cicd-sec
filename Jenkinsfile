pipeline {
  agent any
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
              // sh 'kubectl -n default create deploy node-app --image siddharth67/node-service:v1'
              sh 'kubectl -n default expose deploy node-app --name node-service --port 5000'
          }
      }
  }

}