# III. Building and Installing Envoy, Istio-Proxy, and Istio
Building Envoy in virtual environments takes a significant build time (several hours), so building on bare metal is recommended.

## 1. Building Vanilla Envoy

Start a new build container with the working directory mapped to `/work`:
```bash
sudo docker run -d --name vanilla-envoy -it -w /work -v $HOME/istio-test/istio-proxy:/work -v $HOME/istio-test/envoy:/envoy gcr.io/istio-testing/build-tools-proxy:release-1.20-latest bash && \
sudo docker exec -it vanilla-envoy bash
```

![execute vanila envoy build container](https://i.imgur.com/jewWmUw.png)

> **Note:** Once the prompt below is confirmed, the subsequent commands will be executed within the build container

![build container example](https://i.imgur.com/P93k7OT.png)

Add the Ubuntu repository to access the latest GCC/G++ compiler:
```bash
git config --global --add safe.directory /work && \
add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
apt-get update
```

![install depedencies for vanilla envoy (1)](https://i.imgur.com/S56KYg8.png)

Install required build tools and GCC-9 compiler:
```bash
apt-get install -y build-essential gawk vim gcc-9 g++-9 && \
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 900 && \
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 900
```

![install depedencies for vanilla envoy (2)](https://i.imgur.com/sCtK82o.png)

Build Vanilla Envoy
```bash
make build
```

![process of vanilla envoy build](https://i.imgur.com/ZwtbsXx.png)

![example output of vanilla envoy build](https://i.imgur.com/3fPKQbL.png)

After successful build completion, Envoy binaries and BoringSSL libraries are created in specific directories within the build container  
These components are essential for Istio-Proxy to utilize encryption functionalities through Envoy

Copy the Vanilla Envoy binaries and encryption libraries (`libssl.so`, `libcrypto.so`)  
> **Note:** The work directory within the container corresponds to `$HOME/istio-test/istio-proxy`, where the build container was executed
```bash
cp "$(find /home/.cache/bazel/_bazel_root/*/execroot/io_istio_proxy/bazel-out/k8-fastbuild/bin/envoy)" ./envoy
```
```bash
cp "$(find /home/.cache/bazel/_bazel_root/*/execroot/io_istio_proxy/bazel-out/k8-fastbuild/bin/external/boringssl_fips/crypto/libcrypto.so)" ./b_libcrypto.so
```
```bash
cp "$(find /home/.cache/bazel/_bazel_root/*/execroot/io_istio_proxy/bazel-out/k8-fastbuild/bin/external/boringssl_fips/ssl/libssl.so)" ./b_libssl.so
```

![Copy Vanilla Envoy, libcrypto.so, and libssl.so](https://i.imgur.com/pOEo450.png)

## 2. Building Envoy-OpenSSL

This is the build process for Envoy-OpenSSL  
Overall procedure is similar to that of Vanilla Envoy as described earlier

Initialize the Envoy-OpenSSL build environment:
```bash
sudo docker run -d --name envoy-openssl -it -w /work -v $HOME/istio-test/istio-proxy:/work -v $HOME/istio-test/envoy-openssl:/envoy gcr.io/istio-testing/build-tools-proxy:release-1.20-latest bash
sudo docker exec -it envoy-openssl bash
```

![execute build container](https://i.imgur.com/7ZB0c3i.png)

Add the Ubuntu repository for the latest GCC/G++ compiler using the following command
```bash
git config --global --add safe.directory /work && \
add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
apt-get update
```

Install the Envoy OpenSSL build tools and GCC compiler using the following command
```bash
apt-get install -y build-essential gawk vim gcc-9 g++-9 && \
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 900 && \
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 900
```

Install dependencies for OpenSSL compatibility in Envoy-OpenSSL
```bash
./install-openssl.sh
```

Start the Envoy-OpenSSL build process:
```bash
make build
```

![envoy build succeed](https://i.imgur.com/nKKItOE.png)

Once the build is complete, the Envoy binaries and OpenSSL libraries are created in a specific directory within the build container  
Additionally, Envoy-OpenSSL generates libbssl-compat, which is the core layer for using OpenSSL

Copy libbssl-compat.so
```bash
cp "$(find /home/.cache/bazel/_bazel_root/*/execroot/io_istio_proxy/bazel-out/k8-fastbuild/bin/external/envoy/bssl-compat/bssl-compat/lib/libbssl-compat.so)" ./
```

![copy of Envoy-OpenSSL's libbssl-compat.so and envoy binary](https://i.imgur.com/2MMKLY0.png)

## 3. Building Istio

In the consolidated build for dynamic switching, we use Envoy binary with all dependencies removed, along with the BSSL-Compat from Envoy-OpenSSL and the cryptographic libraries from Vanilla Envoy

The commands in sub section 3 are executed outside the build container

![example of execution outside the build container](https://i.imgur.com/qLCx3PK.png)

Copy Vanilla Envoy's libraries, Envoy binaries, and bssl-compat from Envoy-OpenSSL into an unified build environment  
> **Note:** Use the binary from Vanilla Envoy
```bash
mkdir -p istio/out/linux_amd64/dockerx_build/build.docker.proxyv2/lib && \
sudo cp istio-proxy/b_libcrypto.so istio-proxy/b_libssl.so istio-proxy/libbssl-compat.so istio/out/linux_amd64/dockerx_build/build.docker.proxyv2/lib && \
sudo cp istio-proxy/envoy integrated-env/istio/out/linux_amd64/dockerx_build/build.docker.proxyv2
```

Inspect Envoy binary dependencies:
```bash
ldd istio/out/linux_amd64/dockerx_build/build.docker.proxyv2/envoy
```

![checking library dependencies using ldd command](https://i.imgur.com/13gnzdV.png)

As shown, it confirms that there are dependencies for libssl.so and libcrypto.so.

Remove the Vanilla Envoy dependencies from the Envoy binary.
```bash
sudo patchelf --remove-needed libcrypto.so istio/out/linux_amd64/dockerx_build/build.docker.proxyv2/envoy && \
sudo patchelf --remove-needed libssl.so istio/out/linux_amd64/dockerx_build/build.docker.proxyv2/envoy
```

![checking library depedencies after applying patchelf](https://i.imgur.com/Mwkbff8.png)

Build and validate Istio with the following parameters:
> **Note:** During this process, Istio-Proxy is created based on Envoy, and the Pilot images is generated

> **Note:** Replace `<HUB>` and `<TAG>` with your Docker Hub account and the tag you intend to use
```bash
HUB=<HUB> TAG=<TAG> ./cryptoflex-test/script/build_and_test_istio.sh && \
```

![Example of Build Completion Output](https://i.imgur.com/YPGTB9a.png)

Upon successful build, you can confirm the same results as the previous tests, as demonstrated above dependencies on
