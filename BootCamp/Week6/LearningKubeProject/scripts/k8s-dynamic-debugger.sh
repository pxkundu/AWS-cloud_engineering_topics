#!/bin/bash

# k8s-dynamic-debugger.sh
# Dynamic script to debug common Kubernetes issues, adaptable to any cluster setup

# Ensure kubectl is installed and accessible
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH. Please install kubectl and try again."
    exit 1
fi

# Set the output file name with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="k8s-debug-report-$TIMESTAMP.txt"

# Temporary file to store grep results
TEMP_GREP_FILE=$(mktemp)

# Function to add a section header to the report
add_section() {
    echo "=============================================================" >> "$OUTPUT_FILE"
    echo "[$TIMESTAMP] $1" >> "$OUTPUT_FILE"
    echo "=============================================================" >> "$OUTPUT_FILE"
}

# Function to grep for issues and append to temp file
grep_for_issues() {
    local section="$1"
    local output="$2"
    local patterns=("error" "failed" "NotReady" "CrashLoopBackOff" "ImagePullBackOff" "ContainerCreating" "MemoryPressure" "DiskPressure" "NetworkUnavailable" "OOMKilled" "Evicted")
    for pattern in "${patterns[@]}"; do
        echo "$output" | grep -i "$pattern" | while read -r line; do
            echo "[$section] $line" >> "$TEMP_GREP_FILE"
        done
    done
}

# Function to validate namespace
validate_namespace() {
    local ns="$1"
    if kubectl get namespace "$ns" &> /dev/null; then
        return 0
    else
        echo "Error: Namespace '$ns' does not exist. Please enter a valid namespace."
        return 1
    fi
}

# Function to validate node
validate_node() {
    local node="$1"
    if kubectl get node "$node" &> /dev/null; then
        return 0
    else
        echo "Error: Node '$node' does not exist. Please enter a valid node name."
        return 1
    fi
}

# Start the report
echo "Kubernetes Dynamic Debug Report" > "$OUTPUT_FILE"
echo "Generated at: $TIMESTAMP" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Prompt for user inputs with defaults
echo "Gathering required information for debugging..."

# Namespace for application pods
read -p "Enter the namespace for your application pods (default: default): " APP_NS
APP_NS=${APP_NS:-default}
until validate_namespace "$APP_NS"; do
    read -p "Enter a valid namespace: " APP_NS
done
echo "Using application namespace: $APP_NS"

# Label for application pods
read -p "Enter a label to identify your application pods (e.g., app=myapp, leave blank to skip): " APP_LABEL
APP_LABEL=${APP_LABEL:-""}
if [ -n "$APP_LABEL" ]; then
    echo "Using application label: $APP_LABEL"
else
    echo "No application label provided. Skipping application-specific checks."
fi

# Node to describe
read -p "Enter a node name to describe (leave blank to use first available node): " NODE_NAME
if [ -z "$NODE_NAME" ]; then
    NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    if [ -z "$NODE_NAME" ]; then
        echo "Error: No nodes found in the cluster. Exiting."
        exit 1
    fi
    echo "Using first available node: $NODE_NAME"
else
    until validate_node "$NODE_NAME"; do
        read -p "Enter a valid node name: " NODE_NAME
    done
    echo "Using node: $NODE_NAME"
fi

# Check for CNI (optional)
read -p "Do you want to check for CNI issues? (e.g., Flannel, Calico) [y/N]: " CHECK_CNI
CHECK_CNI=${CHECK_CNI:-N}
if [[ "$CHECK_CNI" =~ ^[Yy]$ ]]; then
    read -p "Enter the namespace for CNI pods (default: kube-system): " CNI_NS
    CNI_NS=${CNI_NS:-kube-system}
    until validate_namespace "$CNI_NS"; do
        read -p "Enter a valid namespace for CNI pods: " CNI_NS
    done
    read -p "Enter a label to identify CNI pods (e.g., app=flannel, leave blank to skip): " CNI_LABEL
    CNI_LABEL=${CNI_LABEL:-""}
    if [ -n "$CNI_LABEL" ]; then
        echo "Checking CNI in namespace $CNI_NS with label $CNI_LABEL"
    else
        echo "No CNI label provided. Skipping CNI-specific checks."
    fi
fi

echo "Starting debug process..."
echo "" >> "$OUTPUT_FILE"

# 1. Cluster Information
add_section "Cluster Information"
CLUSTER_INFO=$(kubectl cluster-info 2>&1)
if [ $? -ne 0 ]; then
    echo "Error: Failed to run 'kubectl cluster-info'. The API server might be down." >> "$OUTPUT_FILE"
    grep_for_issues "Cluster Information" "$CLUSTER_INFO"
    echo "Recommendation: Check the API server pod logs in kube-system namespace." >> "$OUTPUT_FILE"
else
    echo "$CLUSTER_INFO" >> "$OUTPUT_FILE"
    grep_for_issues "Cluster Information" "$CLUSTER_INFO"
fi
echo "" >> "$OUTPUT_FILE"

# 2. Node Status
add_section "Node Status"
NODE_STATUS=$(kubectl get nodes -o wide 2>&1)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get node status. Check kubectl access and API server health." >> "$OUTPUT_FILE"
else
    echo "$NODE_STATUS" >> "$OUTPUT_FILE"
    grep_for_issues "Node Status" "$NODE_STATUS"
fi
echo "" >> "$OUTPUT_FILE"

# 3. Describe Specific Node
add_section "Node Description ($NODE_NAME)"
NODE_DESC=$(kubectl describe node "$NODE_NAME" 2>&1)
if [ $? -ne 0 ]; then
    echo "Error: Failed to describe node $NODE_NAME." >> "$OUTPUT_FILE"
else
    echo "$NODE_DESC" >> "$OUTPUT_FILE"
    grep_for_issues "Node Description ($NODE_NAME)" "$NODE_DESC"
fi
echo "" >> "$OUTPUT_FILE"

# 4. Control Plane Pods (kube-system)
add_section "Control Plane Pods (kube-system)"
CONTROL_PODS=$(kubectl get pods -n kube-system -o wide 2>&1)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get pods in kube-system. Check API server health." >> "$OUTPUT_FILE"
else
    echo "$CONTROL_PODS" >> "$OUTPUT_FILE"
    grep_for_issues "Control Plane Pods (kube-system)" "$CONTROL_PODS"
fi
echo "" >> "$OUTPUT_FILE"

# 5. CoreDNS Pods (kube-system)
add_section "CoreDNS Pods (kube-system)"
COREDNS_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide 2>&1)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get CoreDNS pods. Check API server health." >> "$OUTPUT_FILE"
else
    echo "$COREDNS_PODS" >> "$OUTPUT_FILE"
    grep_for_issues "CoreDNS Pods (kube-system)" "$COREDNS_PODS"
    if echo "$COREDNS_PODS" | grep -q "ContainerCreating\|CrashLoopBackOff\|ImagePullBackOff"; then
        COREDNS_POD=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$COREDNS_POD" ]; then
            add_section "CoreDNS Pod Description ($COREDNS_POD)"
            COREDNS_DESC=$(kubectl describe pod -n kube-system "$COREDNS_POD" 2>&1)
            echo "$COREDNS_DESC" >> "$OUTPUT_FILE"
            grep_for_issues "CoreDNS Pod Description ($COREDNS_POD)" "$COREDNS_DESC"
        fi
    fi
fi
echo "" >> "$OUTPUT_FILE"

# 6. Application Pods
add_section "Application Pods (Namespace: $APP_NS)"
if [ -n "$APP_LABEL" ]; then
    APP_PODS=$(kubectl get pods -n "$APP_NS" -l "$APP_LABEL" -o wide 2>&1)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get application pods in namespace $APP_NS." >> "$OUTPUT_FILE"
    else
        echo "$APP_PODS" >> "$OUTPUT_FILE"
        grep_for_issues "Application Pods (Namespace: $APP_NS)" "$APP_PODS"
        if echo "$APP_PODS" | grep -q "ContainerCreating\|CrashLoopBackOff\|ImagePullBackOff"; then
            APP_POD=$(kubectl get pods -n "$APP_NS" -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
            if [ -n "$APP_POD" ]; then
                add_section "Application Pod Description ($APP_POD)"
                APP_DESC=$(kubectl describe pod -n "$APP_NS" "$APP_POD" 2>&1)
                echo "$APP_DESC" >> "$OUTPUT_FILE"
                grep_for_issues "Application Pod Description ($APP_POD)" "$APP_DESC"
            fi
        fi
    fi
else
    echo "Skipped: No application label provided." >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# 7. CNI Pods (if requested)
if [[ "$CHECK_CNI" =~ ^[Yy]$ ]] && [ -n "$CNI_LABEL" ]; then
    add_section "CNI Pods (Namespace: $CNI_NS)"
    CNI_PODS=$(kubectl get pods -n "$CNI_NS" -l "$CNI_LABEL" -o wide 2>&1)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get CNI pods in namespace $CNI_NS." >> "$OUTPUT_FILE"
    else
        echo "$CNI_PODS" >> "$OUTPUT_FILE"
        grep_for_issues "CNI Pods (Namespace: $CNI_NS)" "$CNI_PODS"
        if echo "$CNI_PODS" | grep -q "ContainerCreating\|CrashLoopBackOff\|ImagePullBackOff"; then
            CNI_POD=$(kubectl get pods -n "$CNI_NS" -l "$CNI_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
            if [ -n "$CNI_POD" ]; then
                add_section "CNI Pod Description ($CNI_POD)"
                CNI_DESC=$(kubectl describe pod -n "$CNI_NS" "$CNI_POD" 2>&1)
                echo "$CNI_DESC" >> "$OUTPUT_FILE"
                grep_for_issues "CNI Pod Description ($CNI_POD)" "$CNI_DESC"
            fi
        fi
    fi
else
    add_section "CNI Pods"
    echo "Skipped: CNI check not requested or no label provided." >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# 8. Cluster Events
add_section "Cluster Events (Last 50)"
EVENTS=$(kubectl get events -A --sort-by='.metadata.creationTimestamp' | tail -n 50 2>&1)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get cluster events. Check API server health." >> "$OUTPUT_FILE"
else
    echo "$EVENTS" >> "$OUTPUT_FILE"
    grep_for_issues "Cluster Events (Last 50)" "$EVENTS"
fi
echo "" >> "$OUTPUT_FILE"

# 9. Resource Usage
add_section "Node Resource Usage"
NODE_USAGE=$(kubectl top nodes 2>&1)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get node resource usage. Ensure metrics-server is running." >> "$OUTPUT_FILE"
else
    echo "$NODE_USAGE" >> "$OUTPUT_FILE"
    grep_for_issues "Node Resource Usage" "$NODE_USAGE"
fi
echo "" >> "$OUTPUT_FILE"

add_section "Application Pod Resource Usage (Namespace: $APP_NS)"
if [ -n "$APP_LABEL" ]; then
    APP_POD_USAGE=$(kubectl top pods -n "$APP_NS" -l "$APP_LABEL" 2>&1)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get pod resource usage. Ensure metrics-server is running." >> "$OUTPUT_FILE"
    else
        echo "$APP_POD_USAGE" >> "$OUTPUT_FILE"
        grep_for_issues "Application Pod Resource Usage (Namespace: $APP_NS)" "$APP_POD_USAGE"
    fi
else
    echo "Skipped: No application label provided." >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Final Analysis and Recommendations
add_section "Final Analysis and Recommendations"
echo "Based on the debugging output, here are the findings and recommendations:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Analyze grep findings
if [ -s "$TEMP_GREP_FILE" ]; then
    echo "Critical Issues Detected:" >> "$OUTPUT_FILE"
    cat "$TEMP_GREP_FILE" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Recommendations based on specific issues
    if grep -q "NotReady" "$TEMP_GREP_FILE"; then
        echo "- Nodes Not Ready: One or more nodes are in NotReady state. Check node events and kubelet logs on the affected node:" >> "$OUTPUT_FILE"
        echo "  kubectl describe node <node-name>" >> "$OUTPUT_FILE"
        echo "  journalctl -u kubelet -n 50" >> "$OUTPUT_FILE"
    fi

    if grep -q "CrashLoopBackOff\|ImagePullBackOff\|ContainerCreating" "$TEMP_GREP_FILE"; then
        echo "- Pod Failures: Pods are failing to start (CrashLoopBackOff, ImagePullBackOff, ContainerCreating)." >> "$OUTPUT_FILE"
        echo "  - For CrashLoopBackOff: Check pod logs for errors:" >> "$OUTPUT_FILE"
        echo "    kubectl logs -n <namespace> <pod-name>" >> "$OUTPUT_FILE"
        echo "  - For ImagePullBackOff: Verify the image name and registry access:" >> "$OUTPUT_FILE"
        echo "    kubectl describe pod -n <namespace> <pod-name>" >> "$OUTPUT_FILE"
        echo "  - For ContainerCreating: Check for CNI issues or resource constraints:" >> "$OUTPUT_FILE"
        echo "    kubectl describe pod -n <namespace> <pod-name>" >> "$OUTPUT_FILE"
    fi

    if grep -q "CoreDNS.*ContainerCreating\|CoreDNS.*CrashLoopBackOff" "$TEMP_GREP_FILE"; then
        echo "- CoreDNS Issues: CoreDNS pods are failing, which may cause DNS resolution failures." >> "$OUTPUT_FILE"
        echo "  - Check CoreDNS pod events:" >> "$OUTPUT_FILE"
        echo "    kubectl describe pod -n kube-system -l k8s-app=kube-dns" >> "$OUTPUT_FILE"
        echo "  - Check kubelet logs on the node:" >> "$OUTPUT_FILE"
        echo "    journalctl -u kubelet -n 50" >> "$OUTPUT_FILE"
        echo "  - Restart CNI pods if applicable (e.g., Flannel, Calico)." >> "$OUTPUT_FILE"
    fi

    if grep -q "MemoryPressure\|DiskPressure\|OOMKilled\|Evicted" "$TEMP_GREP_FILE"; then
        echo "- Resource Constraints: Nodes or pods are under resource pressure." >> "$OUTPUT_FILE"
        echo "  - Check node resource usage:" >> "$OUTPUT_FILE"
        echo "    kubectl top nodes" >> "$OUTPUT_FILE"
        echo "  - Check pod resource usage and adjust requests/limits:" >> "$OUTPUT_FILE"
        echo "    kubectl top pods -n <namespace>" >> "$OUTPUT_FILE"
        echo "  - Consider scaling up nodes or evicting non-critical pods." >> "$OUTPUT_FILE"
    fi

    if grep -q "NetworkUnavailable" "$TEMP_GREP_FILE"; then
        echo "- Networking Issues: NetworkUnavailable condition detected on a node." >> "$OUTPUT_FILE"
        echo "  - Check CNI pods and logs (e.g., Flannel, Calico):" >> "$OUTPUT_FILE"
        echo "    kubectl get pods -n <cni-namespace> -l <cni-label>" >> "$OUTPUT_FILE"
        echo "    kubectl logs -n <cni-namespace> <cni-pod>" >> "$OUTPUT_FILE"
        echo "  - Restart CNI pods if necessary." >> "$OUTPUT_FILE"
    fi
else
    echo "No critical issues detected based on the grep patterns." >> "$OUTPUT_FILE"
    echo "- The cluster appears healthy, but verify application functionality and monitor for issues." >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Clean up temp file
rm -f "$TEMP_GREP_FILE"

# Notify user
echo "Debug report generated: $OUTPUT_FILE"
echo "Please review the report for detailed findings and recommendations."
