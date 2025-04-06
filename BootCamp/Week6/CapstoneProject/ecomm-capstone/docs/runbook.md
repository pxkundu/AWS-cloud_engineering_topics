# E-commerce Platform Runbook

## Overview
This runbook documents recovery procedures for the Secure, Scalable Microservices-Based E-commerce Platform on AWS EKS. It addresses chaos scenarios tested in Phase 4, ensuring operational readiness.

## Chaos Scenarios

### 1. Pod Failure (50% Outage)
- **Description**: 50% of frontend or backend pods are terminated (e.g., hardware failure, human error).
- **Symptoms**:
  - 503 Service Unavailable errors on ALB URL.
  - CloudWatch shows reduced pod count and CPU spikes.
  - X-Ray traces indicate increased latency.
- **Recovery Steps**:
  1. Check pod status: `kubectl get pods -n prod`
  2. View logs: `kubectl logs -l app=frontend -n prod` (or backend)
  3. Verify HPA scaling: `kubectl get hpa -n prod` (expect 5 → 10 pods)
  4. Confirm Karpenter added nodes: `kubectl get nodes`
  5. Monitor CloudWatch dashboard for recovery (<5 min).
- **Expected Outcome**: Pods reschedule across AZs, service restores in <5 min.

### 2. Traffic Spike (DDoS-like Load)
- **Description**: 10,000 requests with 100 concurrent users hit the ALB (e.g., Black Friday surge).
- **Symptoms**:
  - Increased latency on ALB URL.
  - CloudWatch CPU > 80%, pod count rises.
  - X-Ray shows backend bottlenecks.
- **Recovery Steps**:
  1. Simulate spike: `ab -n 10000 -c 100 <alb-url>`
  2. Monitor scaling: `kubectl get hpa -n prod` (pods → 10)
  3. Check nodes: `kubectl get nodes` (expect 2 → 4)
  4. Review CloudWatch metrics and X-Ray traces for latency/errors.
  5. Verify service stability post-spike (latency <1s).
- **Expected Outcome**: System scales up, stabilizes, then scales down.

## General Troubleshooting
- **Logs**: `kubectl logs <pod-name> -n prod`
- **Events**: `kubectl get events -n prod`
- **Dashboard**: Check CloudWatch for CPU, memory, orders/min.
- **Manual Scaling (if needed)**: `kubectl scale deployment frontend --replicas=10 -n prod`

## Verification
- Service uptime >99.9% during chaos.
- Recovery time <5 min per scenario.
