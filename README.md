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
kubectl apply -f runtime.yaml
kubectl apply -f workload.yaml

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