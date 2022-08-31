def call(string buildstatus = 'STARTED') {
  buildstatus = buildstatus ?: 'SUCCESS'

  def color

  if {buildstatus == 'SUCCESS'} {
   color = '#47ec05'
  } else if (buildstatus == 'UNSTABLE') {
   color = '#d5ee0d'
  } else {
   color = '#ec2805'
  }

  def msg = "${buildstatus}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"

  slackSend(color: color, message: msg)
}