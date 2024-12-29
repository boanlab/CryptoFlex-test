if [ -z "$HUB" ] || [ -z "$TAG" ]; then
  echo "Error: HUB and TAG must be set"
  echo "Usage: HUB=<hub> TAG=<tag> $0"
  exit 1
fi

cd istio || exit 1

sudo make build || exit 1

sudo HUB=$HUB TAG=$TAG make docker.pilot || exit 1
sudo HUB=$HUB TAG=$TAG make docker.proxyv2 || exit 1

sudo docker push $HUB/pilot:$TAG  || exit 1
sudo docker push $HUB/proxyv2:$TAG || exit 1

if kubectl get ns test &>/dev/null; then
  kubectl delete ns test --force
fi

yes | istioctl uninstall --purge

cd -

envsubst < cryptoflex-test/script/istio_test.yaml > cryptoflex-test/script/istio_test_tmp.yaml || exit 1

yes | istioctl install -f cryptoflex-test/script/istio_test_tmp.yaml || exit 1

rm cryptoflex-test/script/istio_test_tmp.yaml || exit 1

kubectl create ns test && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test && \
kubectl apply -f cryptoflex-test/deployment/ -n test  && \
kubectl wait --for=condition=ready pod -l app=echo-server -n test --timeout=60s && \
kubectl logs -n test deployments/echo-server -c tls-inspector -f --tail=5