# gitJenkinTerraform
This project demonstrates a Jenkins pipeline using Docker, Kubernetes (MicroK8s), and Terraform, including unit testing, build, security checks, and deployment.

Pipeline Flow: Unit Test → Build → Terraform Validate → Security → Deploy

## Prerequisites
Docker installed locally
MicroK8s installed and running
MicroK8s registry enabled (microk8s enable registry)
kubectl configured via MicroK8s
Jenkins installed via Kubernetes manifests (see below)
## 1. Build the Docker Image
For MicroK8s, push images to the local registry at localhost:32000:

docker build -t localhost:32000/gitjenkinterraform:latest .
## 2. Push Docker Image to MicroK8s Registry
docker push localhost:32000/gitjenkinterraform:latest
No credentials are required. The MicroK8s registry is local and accessible to all pods in the cluster.

## 3. Make the Docker Image Accessible in Kubernetes Jenkins (MicroK8s)
microk8s kubectl run test-pod --image=localhost:32000/gitjenkinterraform:latest --restart=Never --rm -it -- bash
If the pod starts successfully, Kubernetes can access the image.

Note: If you installed MicroK8s on a VM or remote host, replace localhost with the host IP accessible by the cluster.

## 4. Apply Kubernetes Manifests (Correct Order)
microk8s kubectl apply -f jenkins-ca-configmap.yaml
microk8s kubectl apply -f jenkins-rbac.yaml
microk8s kubectl apply -f jenkins-sa.yaml
microk8s kubectl apply -f jenkins-pvc.yaml
microk8s kubectl apply -f jenkins-deployment.yaml
microk8s kubectl apply -f jenkins-service.yaml
Order is important to ensure RBAC, service accounts, and storage are ready before the Jenkins deployment.

## 5. Login to Jenkins
microk8s kubectl get pods -n default
microk8s kubectl exec --namespace default -it <jenkins-pod> -- cat /var/jenkins_home/secrets/initialAdminPassword
Open: http://<host>:32043
Use the password above to log in
Install suggested plugins

## 6. Configure Jenkins Cloud & Pod Templates
Manage Jenkins → Manage Nodes and Clouds → Configure Clouds
Add Kubernetes cloud:
Kubernetes URL: https://kubernetes.default.svc
Namespace: default

Add Pod Templates matching jenkins/pod-templates/: python, terraform, security-tools, etc.
Containers use images from localhost:32000.

## 7. Run the Jenkins Pipeline
Stages:

Debug
Unit Tests → pytest
Build
Terraform Validate
Terraform Security → Checkov
Deploy → python -m src.app 3 5
Expected:

All stages green
Unit tests pass
Terraform validation succeeds
Checkov failure ≤ 10%
Deploy runs the application
Note for MicroK8s Users
Registry at localhost:32000 is available to all pods.
No credentials required.
If using a VM, ensure pods can reach the host IP.
### Cleaning / Resetting
kubectl delete -f jenkins-deployment.yaml
kubectl delete pvc jenkins-pvc
docker rmi localhost:32000/gitjenkinterraform:latest
### Troubleshooting
Image pull fails → check localhost:32000
Pipeline fails → check pod logs
PVC not mounting → verify permissions or storage class

kubectl logs -c <container> <pod>
kubectl get pods
kubectl get svc jenkins
Also check Jenkins Console Output.