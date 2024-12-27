sed -i -e 's/^COPY lib\/b_libssl.so/# COPY lib\/b_libssl.so/' \
-e 's/^COPY lib\/b_libcrypto.so/# COPY lib\/b_libcrypto.so/' \
envoy-openssl-env/istio/pilot/docker/Dockerfile.proxyv2

sed -z -i 's/RUN chmod +x ${BSSL_COMPAT_ROOT}\/lib64\/b_libssl.so && \\\n    chmod +x ${BSSL_COMPAT_ROOT}\/lib64\/b_libcrypto.so/# RUN chmod +x ${BSSL_COMPAT_ROOT}\/lib64\/b_libssl.so && \\\n#     chmod +x ${BSSL_COMPAT_ROOT}\/lib64\/b_libcrypto.so/' \
envoy-openssl-env/istio/pilot/docker/Dockerfile.proxyv2