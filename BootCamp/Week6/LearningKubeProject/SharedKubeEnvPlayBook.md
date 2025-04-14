Shared Kubernetes Cluster for Team
Overview
This Kubernetes cluster is shared among 4 engineers to optimize costs while allowing independent development. Each engineer has their own namespace for isolation, with shared resources for common usage. This setup ensures efficient resource usage, security, and collaboration.
What’s Implemented
Individual Namespaces

Namespaces Created:
engineer1, engineer2, engineer3, engineer4
Each namespace is labeled with owner=<engineer-name> for tracking.


Access Control:
RBAC Role and RoleBinding grant each engineer full access to their namespace but restrict cluster-wide operations.


Resource Quotas:
CPU: 2 cores (requests), 4 cores (limits)
Memory: 4Gi (requests), 8Gi (limits)
Pods: Maximum 10 per namespace


Default Limits:
Pods default to 200m CPU/256Mi memory (requests) and 500m CPU/512Mi memory (limits) to prevent overuse.



Shared Resources

Ingress Controller:
Deployed in ingress-nginx namespace using NGINX Ingress Controller.
Use for routing traffic to your applications.


Storage Class:
standard StorageClass (AWS EBS gp3) for persistent storage.


Monitoring:
Metrics Server for resource usage (kubectl top).
Prometheus in monitoring namespace, scraping metrics from engineer namespaces.



Cluster-Wide Policies

Network Policies:
Cross-namespace communication is blocked except for same-namespace traffic and DNS (to kube-system).


Pod Disruption Budget:
Ensures availability of shared components like the Ingress controller.



What Engineers Can Do to Follow Along
1. Work in Your Namespace

Your namespace is engineer<1-4> (e.g., engineer1 for Engineer 1).
Deploy resources (pods, services, etc.) in your namespace:kubectl apply -f your-resource.yaml -n engineer1


Check your resources:kubectl get pods -n engineer1



2. Set Resource Requests and Limits

Always specify CPU and memory requests/limits in your pod specs to stay within quotas:resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"


Monitor usage to avoid hitting quotas:kubectl top pods -n engineer1



3. Use the Shared Ingress Controller

Create Ingress resources in your namespace to route traffic to your services:apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: engineer1
spec:
  ingressClassName: nginx
  rules:
  - host: engineer1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80

Apply:kubectl apply -f ingress.yaml -n engineer1


Test your Ingress locally before applying to avoid misconfigurations.

4. Use Shared Storage

Create PersistentVolumeClaims (PVCs) using the standard StorageClass:apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: engineer1
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

Apply:kubectl apply -f pvc.yaml -n engineer1



5. Monitor Resource Usage

Use kubectl top to check your namespace’s resource usage:kubectl top pods -n engineer1


Prometheus is available in the monitoring namespace for detailed metrics.

Best Practices

Stay Within Quotas: Monitor your resource usage to avoid hitting limits, which can cause pod evictions.
Test Incrementally: Deploy and test small changes to avoid cluster-wide issues (e.g., DNS or networking failures).
Collaborate: Report issues (e.g., resource contention) to the team via Slack/email so we can adjust quotas or policies.
Schedule Wisely: Use CronJobs for non-critical workloads to run during off-peak hours, reducing contention.

Troubleshooting

Use the k8s-dynamic-debugger.sh script to debug issues in your namespace:./k8s-dynamic-debugger.sh


Input your namespace (e.g., engineer1) and application labels when prompted.


Common issues to watch for:
Pods stuck in ContainerCreating: Check CNI and DNS (CoreDNS) health.
Resource limits exceeded: Adjust your pod specs or request a quota increase.



Contact
For questions or adjustments (e.g., quota increases, shared resource issues), reach out to the team via Slack or email.

Last Updated: April 14, 2025

