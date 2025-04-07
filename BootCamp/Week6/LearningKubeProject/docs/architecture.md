# Kubernetes Architecture Notes
- **Master Node**: Runs control plane components (API server, scheduler, controller manager, etcd).
- **Worker Node**: Runs kubelet, kube-proxy, and container runtime (containerd) to manage pods.
- **Networking**: Uses Flannel CNI for pod-to-pod communication.
- **Key Objects**:
  - Pod: Smallest deployable unit.
  - Deployment: Manages pod replicas.
  - Service: Exposes pods to the network.
