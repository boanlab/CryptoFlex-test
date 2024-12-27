if [ -z "$HUB" ] || [ -z "$TAG" ] || [ -z "$TARGET" ]; then
  echo "Error: HUB, TAG and TARGET must be set"
  echo "Usage: HUB=<hub> TAG=<tag> TARGET=<target_directory> $0"
  exit 1
fi

cd $TARGET/istio
sudo make build

sudo HUB=$HUB TAG=$TAG make docker.pilot
sudo HUB=$HUB TAG=$TAG make docker.proxyv2

sudo docker push $HUB/pilot:$TAG 
sudo docker push $HUB/proxyv2:$TAG

if kubectl get ns test &>/dev/null; then
  kubectl delete ns test --force
fi

yes | istioctl uninstall --purge

cd -

envsubst < cryptoflex-test/script/istio_test.yaml > cryptoflex-test/script/istio_test_tmp.yaml

yes | istioctl install -f cryptoflex-test/script/istio_test_tmp.yaml

rm cryptoflex-test/script/istio_test_tmp.yaml

kubectl create ns test && \
./cryptoflex-test/prerequisite/kubernetes/istio/enable-istio-injection.sh test && \
kubectl apply -f cryptoflex-test/deployment/ -n test  && \
kubectl wait --for=condition=ready pod -l app=echo-server -n test --timeout=60s && \
kubectl logs -n test deployments/echo-server -c tls-inspector -f --tail=5