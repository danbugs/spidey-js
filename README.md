# `spidey-js`

This is an example app. using JS w/ SpiderLightning working in K3Ds.

## How to use

```bash
# --> If you have to, build your image:
# docker buildx build --platform=wasi/wasm --load -t spidey-js:v0.5.0 .
# ^^^ I already did and pushed to dockerhub (docker tag spidey-js:v0.5.0 danstaken/spidey-js:v0.5.0 && docker push danstaken/spidey-js:v0.5.0), so my workload.yaml uses that.

# --> Create a cluster with the shim:
k3d cluster create wasm-cluster --image ghcr.io/deislabs/containerd-wasm-shims/examples/k3d:v0.6.0 -p "8081:80@loadbalancer" --agents 1

# --> If you are using a local image, load it onto the cluster:
# k3d image load -c wasm-cluster spidey-js:v0.5.0
# # ^^^ Again, I'm using an image on dockerhub, so I don't need to do this.

# --> Apply the label to the agent:
kubectl label nodes k3d-wasm-cluster-agent-0 slight-enabled=true

# --> Apply the runtime and workload:
kubectl apply -f k3d

# --> Verify it works:
kubectl get pods

# --> Sample successful output:
# NAME                           READY   STATUS    RESTARTS   AGE
# wasm-slight-5bf74c979d-r77w8   1/1     Running   0          6s

# Test it:
curl -v http://127.0.0.1:8081/get/hello

# --> Sample successful output:
# *   Trying 127.0.0.1:8081...
# * Connected to 127.0.0.1 (127.0.0.1) port 8081 (#0)
# > GET /get/hello HTTP/1.1
# > Host: 127.0.0.1:8081
# > User-Agent: curl/7.87.0
# > Accept: */*
# > 
# * Mark bundle as not supporting multiuse
# < HTTP/1.1 200 OK
# < Access-Control-Allow-Headers: *
# < Access-Control-Allow-Methods: *
# < Access-Control-Allow-Origin: *
# < Access-Control-Expose-Headers: *
# < Content-Length: 15
# < Date: Fri, 05 May 2023 00:00:26 GMT
# < Content-Type: text/plain; charset=utf-8
# < 
# * Connection #0 to host 127.0.0.1 left intact
# Hello, JS Wasm!% 
```

## Running on AKS Before Official Support

AKS is yet trigger a new release officially supporting the latest versions [containerd-wasm-shims](https://github.com/deislabs/containerd-wasm-shims) (v0.6.0 w/ slight v0.5.0), so this is a workaround to get it working on AKS until then.

> Note: Most of this tutorial is taken from [here](https://learn.microsoft.com/en-us/azure/aks/use-wasi-node-pools), as they are normal steps to setting up Wasm/WASI node pools – the workaround steps are marked w/ a `*`.

(1) Create an AKS cluster as normal.
(2) Connect to your AKS cluster.
(3) Register the 'WasmNodePoolPreview' feature flag (https://learn.microsoft.com/en-us/azure/aks/use-wasi-node-pools#register-the-wasmnodepoolpreview-feature-flag).
(4) Add a Wasm/WASI node pool to your cluster (https://learn.microsoft.com/en-us/azure/aks/use-wasi-node-pools#add-a-wasmwasi-node-pool-to-an-existing-aks-cluster).
```bash
az aks nodepool add \
    --resource-group dchiarlone-spidey-js \
    --cluster-name spidey-js-wasm-cluster \
    --name mywasipool \
    --node-count 1 \
    --workload-runtime WasmWasi
```
(5) Verify the node pool is running 
```bash
kubectl get nodes -o wide
# --> Sample successful output:
# ➜  spidey-js git:(main) ✗ kubectl get nodes -o wide
# NAME                                 STATUS   ROLES   AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
# aks-agentpool-26499314-vmss000000    Ready    agent   26m   v1.25.6   10.224.0.4    <none>        Ubuntu 22.04.2 LTS   5.15.0-1036-azure   containerd://1.6.18+azure-1
# aks-agentpool-26499314-vmss000002    Ready    agent   26m   v1.25.6   10.224.0.5    <none>        Ubuntu 22.04.2 LTS   5.15.0-1036-azure   containerd://1.6.18+azure-1
# aks-mywasipool-10429225-vmss000000   Ready    agent   61s   v1.25.6   10.224.0.6    <none>        Ubuntu 22.04.2 LTS   5.15.0-1036-azure   containerd://1.6.18+azure-1
```
(6\*) Somewhere else in your machine, run `git clone https://github.com/trstringer/az-aks-ssh && cd az-aks-ssh` and then `./az-aks-ssh.sh -g dchiarlone-spidey-js -n spidey-js-wasm-cluster -d aks-mywasipool-10429225-vmss000000` to SSH into the Wasm/WASI node pool.
(7\*) Once you've successfully SSH'd, run `ls -la /usr/local/bin/` to verify the slight shim is installed and its' permissions:
```bash
ls -la /usr/local/bin/
# --> Sample successful output:
# azureuser@aks-mywasipool-10429225-vmss000000:~$ ls -la /usr/local/bin/
# total 567460
# drwxr-xr-x  2 root root         4096 May  5 17:16 .
# drwxr-xr-x 10 root root         4096 Apr 20 02:08 ..
# <snip>
# -rwxr-xr-x  1 root root     47622592 May  5 16:59 containerd-shim-slight-v0-3-0-v1
# -rwxr-xr-x  1 root root     52232184 May  5 16:59 containerd-shim-slight-v0-5-1-v1
# <snip>
```
(8\*) `curl` the latest shim binary purposefully misnamed with `v0-5-1` to avoid extra work:
```bash
curl https://spideyjsstorage.blob.core.windows.net/spidey-js/containerd-shim-slight-v0-5-1-v1 --output containerd-shim-slight-v0-5-1-v1
```
(9\*) Set the correct permissions on the shim binary:
```bash
sudo chmod 755 containerd-shim-slight-v0-5-1-v1
sudo chown root:root containerd-shim-slight-v0-5-1-v1
```
(10\*) Move the shim binary to the correct location:
```bash
sudo mv containerd-shim-slight-v0-5-1-v1 /usr/local/bin/containerd-shim-slight-v0-5-1-v1
```
(11\*) Exit off the ssh session with `exit`. 
(12) Apply the runtime and workload:
```bash
kubectl apply -f aks
```
(13) Verify it works:
```bash
kubectl get svc
# --> Sample successful output:
# NAME          TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
# kubernetes    ClusterIP      10.0.0.1       <none>         443/TCP        10m
# wasm-slight   LoadBalancer   10.0.133.247   <EXTERNAL-IP>  80:30725/TCP   2m47s
curl http://EXTERNAL-IP/get/hello
```

