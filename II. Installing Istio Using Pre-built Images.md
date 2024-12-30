# II. Installing Istio Using Pre-built Images
## 1. Istio Installation

The process of installing Istio using an existing built image

Proceed with the Istio installation with the built image through the following command  
> **Note:** TLS Version and CipherSuite are predefined and can be modified as you needed
```bash
yes | istioctl install \
  --set profile=default \
  --set hub=docker.io/boanlab \
  --set tag=cryptoflex \
  --set meshConfig.accessLogFile=/dev/stdout \
  --set meshConfig.enableTracing=true \
  --set 'meshConfig.meshMTLS.minProtocolVersion=TLSV1_3' \
  --set 'meshConfig.meshMTLS.cipherSuites[0]=TLS_CHACHA20_POLY1305_SHA256'
```

![istio installation process](https://i.imgur.com/uMx6evd.png)

## 2. Verifying Deployment Status

Deploying test workloads to verify Istio's deployment status

The test workloads are configured as follows:
* Istio-Proxy is injected into both the Echo-server and Echo-client Pods, establishing mTLS communication
* mTLS is renewed every 2 seconds, enabling observation of TLS Handshake processes to verify the configurations for each workload

![](https://i.imgur.com/IPOhVRL.png)

Create a `test` namespace for test workload deployment and enable Istio injection
```bash
kubectl create ns test && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test
```

![create test namespace and allow istio injection](https://i.imgur.com/yjdlrWA.png)

Deploy the test workloads to the `test` namespace and wait until they are ready  
> **Note:** This process may take over 100 seconds depending on network condition
```bash
kubectl apply -f cryptoflex-test/deployment/ -n test && \
kubectl wait --for=condition=ready pod -l app=echo-server -n test --timeout=100s
```

![deploy test workload](https://i.imgur.com/EdmMEJf.png)

Verify the workloads' mTLS information using the TLS Inspector container
```bash
kubectl logs -n test deployments/echo-server -c tls-inspector -f
```

![](https://i.imgur.com/ZToEzY7.png)

Verify that the TLS Handshake is conducted using the `CHACHA20_POLY1305_SHA256` CipherSuite as configured earlier  
> **Note:** The first few `TLS_AES_128_GCM_SHA256` logs are initial logs generated during Istio's initialization process and are independent of dynamic Cipher Suite transitions

