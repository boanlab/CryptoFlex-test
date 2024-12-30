# IV. Test
## 1. Testing CipherSuite Configuration at Different Granularity Levels

Before testing, remove existing configurations and namespaces
```bash
yes | istioctl uninstall --purge && \
kubectl delete ns test test1 test2 2>/dev/null; while kubectl get ns test test1 test2 >/dev/null 2>&1; do sleep 1; done
```

![cleanup test workload](https://i.imgur.com/LbhHT8Z.png)

Test scenarios cover the following configurations:  
&nbsp;&nbsp;&nbsp;&nbsp;a. Deploy and verify the operation of cluster-level settings  
&nbsp;&nbsp;&nbsp;&nbsp;b. Deploy and verify the operation of namespace-level settings  
&nbsp;&nbsp;&nbsp;&nbsp;c. Deploy and verify the operation of settings based on labels  

### a. Deploy and verify the operation of cluster-level settings

Configure cluster-wide settings through `meshconfig`
```bash
yes | istioctl install \
  --set profile=default \
  --set hub=docker.io/boanlab \
  --set tag=cryptoflex \
  --set meshConfig.accessLogFile=/dev/stdout \
  --set meshConfig.enableTracing=true \
  --set meshConfig.meshMTLS.cipherSuites[0]=TLS_AES_256_GCM_SHA384
```

Deploy a workload to verify the cluster-level settings  
As with the previous tests, create a dedicated test namespace, enable Istio injection, and deploy the test workload
```bash
kubectl create ns test && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test && \
kubectl apply -f cryptoflex-test/deployment/ -n test
```

Inspect the logs of the TLS Inspector in the test workload
```bash
kubectl logs -n test deployments/echo-server -c tls-inspector
```

![example of logs after applying cluster-level settings](https://i.imgur.com/UjtIa0I.png)

It can be confirmed that `AES_256_GCM_SHA384` is specified as set

### b. Deploy and verify the operation of namespace-level settings

Similarly, create a test namespace and enable Istio injection
```bash
kubectl create ns test1 && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test1
```

Set annotations on the namespace using the `kubectl annotate` command  
Next, deploy the test workload
```bash
kubectl annotate --overwrite namespace test1 cipherSuites=TLS_AES_128_GCM_SHA256 && \
kubectl apply -f cryptoflex-test/deployment/ -n test1
```

Inspect the logs of the TLS Inspector in the test workload
```bash
kubectl logs -n test1 deployments/echo-server -c tls-inspector
```

![example of logs after applying namespace-level settings](https://i.imgur.com/EXcov9j.png)

This confirms `AES_128_GCM_SHA256` is specified as set

### c. Deploy and verify the operation of settings based on labels

As in the previous examples, proceed with creating a test namespace, activating Istio injection, and deploying the test workload
```bash
kubectl create ns test2 && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test2 && \
kubectl apply -f cryptoflex-test/deployment/ -n test2
```

Modify the annotation of the Pod using the kubectl annotate command to specify settings based on labels
```bash
kubectl annotate pods -n test2 -l app=echo-server --overwrite cipherSuites="TLS_CHACHA20_POLY1305_SHA256"
```

Inspect the logs of the TLS Inspector for the test workload
```bash
kubectl logs -n test2 deployments/echo-server -c tls-inspector
```

![example log after applying label unit settings](https://i.imgur.com/6OqvQEF.png)

Similarly, the specified `CHACHA20_POLY1305_SHA256` is successfully applied to the label unit as well

Use the command below to check the CipherSuites of the entire test workload with the applied granular settings
```bash
for ns in test test1 test2; do echo "=== $ns ==="; kubectl logs -n $ns deployment/echo-server -c tls-inspector --tail=3; done
```
![example log output of granular encryption settings for each workload](https://i.imgur.com/1obxM5x.png)

As it appears, it verifies the settings specified at the cluster level, namespace level, and label level

## 2. Verify Configuration Priority

Before testing, remove existing configurations and namespaces
```bash
yes | istioctl uninstall --purge && \
kubectl delete ns test test1 test2 2>/dev/null; while kubectl get ns test test1 test2  >/dev/null 2>&1; do sleep 1; done
```
Specify cluster-level settings through `meshconfig`
```bash
yes | istioctl install \
  --set profile=default \
  --set hub=docker.io/boanlab \
  --set tag=cryptoflex \
  --set meshConfig.accessLogFile=/dev/stdout \
  --set meshConfig.enableTracing=true \
  --set meshConfig.meshMTLS.cipherSuites[0]=TLS_AES_256_GCM_SHA384
```

Deploy a workload to verify the cluster-level settings  
As with the previous tests, create a namespace, enable Istio injection, and deploy the test workload
```bash
kubectl create ns test && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test && \
kubectl apply -f cryptoflex-test/deployment/ -n test
```

Create a new namespace (test1) and deploy a test workload consisting of a pair of echo-server and echo-client
```bash
kubectl create ns test1 && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test1 && \
kubectl apply -f cryptoflex-test/deployment/ -n test1
```

Check the CipherSuite logs for each workload
```bash
kubectl logs -n test deployments/echo-server -c tls-inspector --tail=5
kubectl logs -n test deployments/echo-server2 -c tls-inspector --tail=5
kubectl logs -n test1 deployments/echo-server -c tls-inspector --tail=5
```

With cluster-level configuration in place, all workloads have the same CipherSuite configuration

![log confirming to cluster-level setting applied for entire workload](https://i.imgur.com/bi3DXvg.png)

Set the CipherSuite by specifying annotations in the namespace and verify it
```bash
kubectl annotate --overwrite namespace test1 cipherSuites=TLS_AES_128_GCM_SHA256 && \
kubectl rollout restart -n test1 deployment echo-server echo-client
```

Check the CipherSuite settings for each workload again
```bash
kubectl logs -n test deployments/echo-server -c tls-inspector --tail=5
kubectl logs -n test deployments/echo-server2 -c tls-inspector --tail=5
kubectl logs -n test1 deployments/echo-server -c tls-inspector --tail=5
```

![log comparing the priority of namespace annotations and cluster-level settings](https://i.imgur.com/NFyYpp5.png)

As configured, the CipherSuite setting for the test1 namespace is updated
```bash
kubectl annotate pods -n test -l app=echo-server --overwrite cipherSuites="TLS_CHACHA20_POLY1305_SHA256"
```

Check the CipherSuite settings for each workload again
```bash
kubectl logs -n test deployments/echo-server -c tls-inspector --tail=5
kubectl logs -n test deployments/echo-server2 -c tls-inspector --tail=5
kubectl logs -n test1 deployments/echo-server -c tls-inspector --tail=5
```

![log comparing the priority of label annotations and cluster-level setting](https://i.imgur.com/pGXmumo.png)

The namespace settings have been redefined over the cluster settings, and the label settings have also been redefined, confirming that each setting has its own priority

## 3. Testing Supported CipherSuite

In Istio based on Vanilla Envoy, only the TLS_AES_128_GCM_SHA256 CipherSuite is available.  
Additionally, if a different TLSv1.3 CipherSuite is specified, an error will occur

This section, we will directly verify this and test the method for specifying the CipherSuite

Before testing, remove existing configurations and namespaces
```bash
yes | istioctl uninstall --purge && \
kubectl delete ns test test1 test2 2>/dev/null; while kubectl get ns test test1 test2 >/dev/null 2>&1; do sleep 1; done
```

Specify the `meshconfig` without a CipherSuite and install Istio
```bash
yes | istioctl install \
  --set profile=default \
  --set hub=docker.io/boanlab \
  --set tag=cryptoflex \
  --set meshConfig.accessLogFile=/dev/stdout \
  --set meshConfig.enableTracing=true
```

Create a test namespace (test) and enable Istio injection, then deploy workloads to test the CipherSuite specification  
Set the encryption library of the test workload to BoringSSL
```bash
kubectl create ns test && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test && \
kubectl apply -f cryptoflex-test/deployment/ -n test && \
kubectl wait --for=condition=ready pod -l app=echo-server -n test --timeout=100s && \
cryptoflex -n test deployments/echo-server bssl
```

![create workload based on Vanilla Envoy](https://i.imgur.com/7wAgmti.png)

Since the CipherSuite is not specified at the cluster level, it is fixed to `AES_128_GCM_SHA256`

Now, test by specifying the TLSv1.3 CipherSuite as `CHACHA20_POLY1305_SHA256`
```bash
HUB=<HUB> TAG=<TAG> ./cryptoflex-test/script/build_and_test_istio.sh
```

![testing specification of TLSv1.3 ciphersuite](https://i.imgur.com/i2QTJO2.png)

Create another namespace (test1) and add the test workload
```bash
kubectl create ns test1 && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test1 && \
kubectl apply -f cryptoflex-test/deployment/ -n test1
```

Check the Istiod log
```bash
kubectl logs -n istio-system deployments/istiod
```

![error logs from istid when specifying TLSv1.3 ciphersuite on vanilla envoy](https://i.imgur.com/kxO9DHw.png)

Check the Istio-Proxy log
```bash
kubectl logs -n test1 deployments/echo-server -c istio-proxy
```

![error logs from Istio-Proxy when specifying TLSv1.3 ciphersuite on vanilla envoy](https://i.imgur.com/aGOsSiw.png)

As demonstrated, this confirms specifying a CipherSuite for TLSv1.3 is not possible in Vanilla Envoy

## 4. Dynamic Transition of CipherSuites
Applying a new CipherSuite to a active workload allows for dynamic changes without interrupting the session

Before testing, remove existing configurations and namespaces
```bash
yes | istioctl uninstall --purge && \
kubectl delete ns test test1 test2 2>/dev/null; while kubectl get ns test test1 test2 >/dev/null 2>&1; do sleep 1; done
```
Specify cluster-level settings through `meshconfig`
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

Create a test namespace (test) and enable Istio injection, then deploy workloads to test the Dynamic transition
```bash
kubectl create ns test && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test && \
kubectl apply -f cryptoflex-test/deployment/ -n test
```

![workload for dynamic transition of ciphersuites](https://i.imgur.com/ksczvHr.png)

Existing session of the workload uses the `TLS_CHACHA20_POLY1305_SHA256` CipherSuite
```bash
kubectl logs -n test deployments/echo-server -c tls-inspector -f
```

![check original ciphersuite](https://i.imgur.com/Rp3bSGr.png)

Specify a different CipherSuite from the existing one for the test workload through annotations
```bash
kubectl annotate --overwrite namespace test chiperSuites=TLS_AES_128_GCM_SHA256
```

![apply namespace level annotation](https://i.imgur.com/1hDIbat.png)

This confirms the transition to `TLS_AES_128_GCM_SHA256` occurs as specified
```bash
kubectl annotate --overwrite namespace test chiperSuites=TLS_AES_128_GCM_SHA256
```

![check changed ciphersuite](https://i.imgur.com/rxqzmIl.png)

<!-- not done yet in below -->

## 5. Cryptography Library Dynamic Transition
Section 5 discusses the method for dynamic switching of encryption libraries  
The encryption library is switched without interrupting the active workload through the previously installed Cryptoflex

Before testing, remove existing configurations and namespaces
```bash
yes | istioctl uninstall --purge && \
kubectl delete ns test test1 test2 2>/dev/null; while kubectl get ns test test1 test2 >/dev/null 2>&1; do sleep 1; done
```

Perform the Istio build as done in Section 3.3, and deploy the test workload
```bash
HUB=<HUB> TAG=<TAG> ./cryptoflex-test/script/build_and_test_istio.sh && \
```

Check the CipherSuite currently in use by the test workload
```bash
kubectl logs -n test deployments/echo-server -c tls-inspector
```

> [스크린샷] 테스트 워크로드의 CipherSuite 재확인 (아직 없음)

This confirms no further communication occurs after the switch

Check the istio-proxy logs of the test workload to identify the reason for the communication interruption
```bash
kubectl logs -n test deployments/echo-server -c istio-proxy
```

> [스크린샷] 테스트 워크로드의 istio-proxy 컨테이너 확인 (아직 없음)

This confirms an error occurred due to the unsupported CipherSuite, as mentioned above  
BoringSSL does not support the specification of CipherSuites other than `AES_128_GCM_SHA256` for TLS 1.3, so the currently specified CipherSuite cannot be applied in BoringSSL

Use the cryptoflex command to switch the encryption library of the current workload back to OpenSSL
```bash
cryptoflex -n test deployments/echo-server ossl
```

Check the CipherSuite of the test workload again
```bash
kubectl logs -n test deployments/echo-server -c tls-inspector
```

> [스크린샷] 테스트 워크로드의 CipherSuite 재확인 (아직 없음)

This confirms communication is functioning normally

Due to the unsupported CipherSuite error caused by the library switch, communication was not possible.  
However, after switching back, it has been confirmed that normal communication is occurring.
