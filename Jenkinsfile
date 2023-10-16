pipeline {
    agent any
    options {
        timestamps()
        ansiColor('xterm')
    }
    environment {
        // S3_BUCKET_NAME = '<bucket-name>'
        // TF_VAR_AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
        // TF_VAR_AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
        AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')        
    }
//   triggers {
//        pollSCM '*/5 * * * *'
/*    } 
  options {
    skipDefaultCheckout(true)
  }
  stages{
    stage('clean workspace') {
      steps {
        cleanWs()
      }
    }
    stage('checkout') {
      steps {
        checkout scm
      }
    }
  }
}
