pipeline {
    agent any
    tools {
        maven 'M3_8_6'
        terraform 'Terraform'
    }
    parameters {
        booleanParam(name: 'destroy', defaultValue: false, description: 'Destroy Terraform build?')
        booleanParam(name: 'deploy', defaultValue: false, description: 'Deploy Terraform apply?')
        booleanParam(name: 'database', defaultValue: false, description: 'Create tables?')
        booleanParam(name: 'microservices', defaultValue: false, description: 'Create microservices?')
    }
    environment {
        AWS_ACCESS_KEY_ID       = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY   = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_ACCOUNT_ID          = "262583979852"
        AWS_DEFAULT_REGION      = "us-east-1" 
        TF_VAR_environment      = 'jimena'
    }
    stages {
        stage('Create Infra') {
            when {
                equals expected: true, actual: params.deploy
            }
            steps {
                dir("infra/"){
                    sh "terraform init"
                    sh "terraform apply --auto-approve"
                }
            }
        }
           stage('secrets') {
            when {
                equals expected: true, actual: params.deploy
            }
            steps {
                withAWS(credentials: 'ecr-credentials', region: 'us-east-1') {
                    dir("Deployment/"){
                        sh 'aws eks --region us-east-1 update-kubeconfig --name eks-cluster-${TF_VAR_environment}'
                        sh 'kubectl apply -f ingress-deploy.yaml'
                    }
                }
            }
        }
        stage('Destroy Infra') {
            when {
                equals expected: true, actual: params.destroy
            }
            steps {
                dir("infra/"){
                    sh "terraform destroy --auto-approve"
                }
            }
        }
        stage('Database') {
            when {
                equals expected: true, actual: params.database
            }
            steps {
                dir("liquibase/"){
                    sh '/opt/liquibase/liquibase --changeLogFile="changesets/db.changelog-master.xml" update'
                }
            }
        }
        /*stage("Docker Build") {
            when {
                equals expected: true, actual: params.microservices
            }
            steps {
                dir("payment-service/"){
                    sh "docker build --cache-from payment-service-${TF_VAR_environment}:latest -t payment-service-${TF_VAR_environment}:latest ."
                    //sh "docker pull payment-service:latest"
                    //docker hub publico
                }
                dir("order-service/"){
                    sh "docker build --cache-from order-service-${TF_VAR_environment}:latest -t order-service-${TF_VAR_environment}:latest ."
                }
                dir("kitchen-service/"){
                    sh "docker build --cache-from kitchen-service-${TF_VAR_environment}:latest -t kitchen-service-${TF_VAR_environment}:latest ."
                }
            }
        }*/
        stage("Docker Pull") {
            when {
                equals expected: true, actual: params.microservices
            }
            steps {
                withAWS(credentials: 'ecr-credentials', region: 'us-east-1') {
                    script {
                        sh "docker pull jimenarodriguez/payment-service:latest"
                        sh "docker pull jimenarodriguez/kitchen-service:latest"
                        sh "docker pull jimenarodriguez/order-service:latest"
                        //sh "docker pull payment-service:latest"
                        /*dir("order-service/"){
                            sh "docker build --cache-from order-service-${TF_VAR_environment}:latest -t order-service-${TF_VAR_environment}:latest ."
                        }
                        dir("kitchen-service/"){
                            sh "docker build --cache-from kitchen-service-${TF_VAR_environment}:latest -t kitchen-service-${TF_VAR_environment}:latest ."
                        }*/
                    }
                }
            }
        }
        stage('Logging into AWS ECR') {
            when {
                equals expected: true, actual: params.microservices
            }
            steps {
                withAWS(credentials: 'ecr-credentials', region: 'us-east-1') {
                        script {
                            def login = ecrLogin()
                            sh "${login}"
                            sh '''docker tag jimenarodriguez/payment-service:latest 262583979852.dkr.ecr.us-east-1.amazonaws.com/payment-service-${TF_VAR_environment}'''
                            sh '''docker tag jimenarodriguez/kitchen-service:latest 262583979852.dkr.ecr.us-east-1.amazonaws.com/kitchen-service-${TF_VAR_environment}'''
                            sh '''docker tag jimenarodriguez/order-service:latest 262583979852.dkr.ecr.us-east-1.amazonaws.com/order-service-${TF_VAR_environment}'''
                        }
                }
            }
        }
        stage("Docker Push") {
            when {
                equals expected: true, actual: params.microservices
            }
            steps {
                sh "docker push 262583979852.dkr.ecr.us-east-1.amazonaws.com/payment-service-${TF_VAR_environment}:latest"
                sh "docker push 262583979852.dkr.ecr.us-east-1.amazonaws.com/kitchen-service-${TF_VAR_environment}:latest"
                sh "docker push 262583979852.dkr.ecr.us-east-1.amazonaws.com/order-service-${TF_VAR_environment}:latest"
            }
        }
        stage('Kubectl') {
            when {
                equals expected: true, actual: params.microservices
            }
            steps {
                withAWS(credentials: 'ecr-credentials', region: 'us-east-1') {
                    sh 'aws eks --region us-east-1 update-kubeconfig --name eks-cluster-${TF_VAR_environment}'
                    sh 'kubectl get pods'
                    dir("Deployment/"){
                        sh "sed -i \"s#ACCESS_REPLACE#$AWS_ACCESS_KEY_ID#g\" secrets.yaml"
                        sh "sed -i \"s#SECRET_REPLACE#$AWS_SECRET_ACCESS_KEY#g\" secrets.yaml"
                        sh 'kubectl apply -f secrets.yaml'
                        sh 'kubectl apply -f Payment-deployment.yaml'
                        sh 'kubectl apply -f Kitchen-deployment.yaml'
                        sh 'kubectl apply -f Order-deployment.yaml'
                        sh 'kubectl apply -f nginx_ingress_services.yaml'
                    }
                }
            }
        }
    }
}
