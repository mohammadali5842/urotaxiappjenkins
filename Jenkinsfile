pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_SECRET_KEY')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        GIT_CRED = credentials('urotaxi_token')
        UROTAXI_DB_USER = 'root'
        UROTAXI_DB_PSW = credentials('DB_PASSWORD')
        AWS_KEY = credentials('AWS_KEY')
        ANSIBLE_HOST_KEY_CHECKING = "False"
        
    }
    tools {
        git 'git'
        maven '3.9.6'
        terraform '21207'
    }
    stages {
        stage('checkout') {
            steps {
                git(url: "https://${GIT_CRED}@github.com/mohammadali5842/urotaxiappjenkins.git", branch: 'main')
            }
        }
        stage('test') {
            steps {
                sh 'mvn clean test -Dmaven.test.failure.ignore=true'
            }
        }
        stage('package') {
            steps {
                sh 'mvn clean verify --batch-mode'
            }
        }
        stage('infra') {
            steps {
                sh '''
                terraform  -chdir=src/main/config/terraform init
                terraform  -chdir=src/main/config/terraform apply --auto-approve
                terraform  -chdir=src/main/config/terraform output "databaseendpoint" >  dbHosts
                terraform  -chdir=src/main/config/terraform output "ec2publicip" >  Hosts
                '''
            }
            post {
                failure {
                    sh 'terraform  -chdir=src/main/config/terraform destroy --auto-approve'
                }
            }
        }
        
        stage('dB_config') {
            steps {
            sh '''
            sed -i "s|#dbusername#|$UROTAXI_DB_USER|g" src/main/resources/application.yml
            sed -i "s|#dbpassword#|$UROTAXI_DB_PSW|g" src/main/resources/application.yml
            dbHost=$(cat dbHosts)
            sed -i "s|#dbhost#|$dbHost|g" src/main/resources/application.yml
            '''
            }
        }
        
        stage('package') {
            steps {
                sh 'mvn --batch-mode clean package -DskipTests=true'
            }
        }
        
        stage('deploy') {
            steps {
                script {
                    env.DB_HOSTS = sh(returnStdout: true, script: 'cat dbHosts').trim()
                    echo "env.DB_HOST '${DB_HOSTS}'"
                }
                sh '''
                db_HOST=$(echo $DB_HOSTS | sed 's/"//g' | sed 's/:.*//g')
                '''
                withEnv(["DB_HOST=echo ${db_HOST}"]) {
                    ansiblePlaybook(credentialsId: 'AWS_KEY', inventory: 'Hosts', disableHostKeyChecking: true, playbook: 'src/main/config/ansible/urotaxi-playbook.yml')
                }    
            }
        }
    }
    /*post {
        always {
            input (message: "want to destroy aws infra.", ok: "Continue")
            sh 'terraform  -chdir=src/main/config/terraform destroy --auto-approve'
        }
    }*/
}
