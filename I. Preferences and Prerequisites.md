# I. Preferences and Prerequisites

## 1. Download Tools and Source Code

Create a directory for your work environment.

```bash
mkdir istio-test && cd istio-test
```

Download Envoy repository
```bash
git clone https://github.com/boanlab/envoy.git
```
Download Envoy-OpenSSL repository
```bash
git clone https://github.com/boanlab/envoy-openssl.git
```
Download Istio-Proxy repository
```bash
git clone https://github.com/boanlab/istio-proxy.git
```
Download Istio repository
```bash
git clone https://github.com/boanlab/istio.git
```
Download a toolset for installation scripts and basic requirements for CryptoFlex testing
```bash
git clone https://github.com/boanlab/cryptoflex-test.git
```

## 2. Docker and Build-Related Tools Installation

Install make, patchelf, and docker which are required during the build process  
> **Note:** Dockers are for image build, and can be omitted if using a pre-built image
```bash
sudo apt-get update && \
sudo apt install make patchelf -y && \
./cryptoflex-test/prerequisite/containers/install-docker.sh
```

Run the following command to verify docker installation
```bash
docker ps
```

![check docker installation](https://i.imgur.com/uTxuWRk.png)  

Login to Docker Hub to push the built image later
```bash
sudo docker login
```

![docker login](https://i.imgur.com/Bw6XTqC.png)

## Install Kubernetes and Related Tools

Install CryptoFlex, which is used for dynamic library switching
```bash
sudo cp ./cryptoflex-test/script/cryptoflex /usr/local/bin
```

Install Kubernetes and related dependencies  
> **Note:** This example is based on the single-node Kubernetes cluster
```bash
./cryptoflex-test/prerequisite/containers/install-containerd.sh && \
./cryptoflex-test/prerequisite/kubernetes/install-kubeadm.sh && \
./cryptoflex-test/prerequisite/kubernetes/initialize-kubeadm.sh && \
./cryptoflex-test/prerequisite/kubernetes/deploy-calico.sh && \
kubectl apply -f cryptoflex-test/prerequisite/kubernetes/rbac.yaml
```

The above scripts perform the following:  
* Install Containerd(CRI)
* Install Kubeadm, Kubelet, Kubectl
* Initialize Kubeadm
    * You can check script for multi node cluster initialize
* Calico(CNI) Deployment
* Add ClusterRole (for CipherSuite transition)

Run the following command to verify Kubernetes installation
```bash
kubectl get pod -A
```

![check kubernetes installed](https://i.imgur.com/XwkUFOf.png)

Execute the following command to verify the installation and operation of the istioctl binary  
> **Note:** When using a different version of istioctl, it can cause error because the version with the data plane doesn't match
```bash
sudo cp ./cryptoflex-test/prerequisite/istio-1.20.8/bin/istioctl /usr/local/bin && \
istioctl version
```

![check istioctl can use in local path](https://i.imgur.com/LJ8XtGY.png)

If Taint does not work in a single-node cluster, enter the command below  
> **Note:** The node name can be identified as `kubectl get node -A`
```bash
kubectl taint node <node-name> node-role.kubernetes.io/control-plane:NoSchedule-
```

![troubleshooting: Taint problem](https://i.imgur.com/uTvZ4wu.png)

---
