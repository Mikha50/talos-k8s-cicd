pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    role: devops-cicd-runner
spec:
  containers:
  - name: terraform
    image: hashicorp/terraform:1.9.8
    command:
    - cat
    tty: true
    securityContext:
      runAsUser: 0
    env:
    - name: KUBERNETES_SERVICE_HOST
      value: "192.168.14.210"
    - name: KUBERNETES_SERVICE_PORT
      value: "6443"
  - name: devops
    image: alpine/k8s:1.31.2
    command:
    - cat
    tty: true
    securityContext:
      runAsUser: 0
    env:
    - name: KUBERNETES_SERVICE_HOST
      value: "192.168.14.210"
    - name: KUBERNETES_SERVICE_PORT
      value: "6443"
'''
    }
  }

  stages {
    stage('1. Terraform Infrastructure') {
      steps {
        container('terraform') {
          sh '''
            echo "=========================================================="
            echo "🏗️ [Terraform] Initializing & Provisioning K8s & Longhorn"
            echo "=========================================================="
            cd terraform
            terraform init
            terraform apply -auto-approve
          '''
        }
      }
    }

    stage('2. Ansible Application Deployment') {
      steps {
        container('devops') {
          sh '''
            echo "=========================================================="
            echo "🚀 [Ansible] Installing Ansible & Deploying PostgreSQL + App"
            echo "=========================================================="
            apk add --no-cache ansible-core
            ansible-playbook -i ansible/inventory.ini ansible/deploy-app.yml
          '''
        }
      }
    }

    stage('3. Cluster Verification & Health Check') {
      steps {
        container('devops') {
          sh '''
            echo "=========================================================="
            echo "🔍 [Verification] Checking Pods, PVC, and Services"
            echo "=========================================================="
            kubectl get pods,pvc,svc -n production-app -o wide
          '''
        }
      }
    }
  }

  post {
    success {
      echo "========================================================="
      echo "🎉 CI/CD Pipeline Completed Successfully!"
      echo "🌐 Access Web App at: http://192.168.14.211:30088"
      echo "💾 Storage: Longhorn 3-Way Replicated Storage is Healthy!"
      echo "========================================================="
    }
    failure {
      echo "❌ Pipeline Failed! Please check the logs above."
    }
  }
}
