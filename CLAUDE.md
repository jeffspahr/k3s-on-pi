# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository automates the setup and management of a 3-node high-availability k3s Kubernetes cluster on Raspberry Pi 4 (8GB) devices running Ubuntu 24.04 LTS (64-bit). The infrastructure uses a combination of Ansible for host provisioning, k3sup for cluster bootstrapping, and kubectl for deploying cluster components.

## Architecture

### Bootstrap Flow
1. **Image Preparation**: Ubuntu 24.04 LTS 64-bit is flashed to SD cards with network configuration (Netplan) for automatic WiFi/network join on first boot
2. **Ansible Provisioning** (`ansible/roles/common`): Configures hosts with users, SSH keys, and enables required cgroups for k3s
3. **k3s Cluster Bootstrap** (`k3s-bootstrap.sh`): Uses k3sup to create a 3-node HA cluster with embedded etcd
4. **Component Deployment** (`manifests/`): Deploys system components in a specific order (see Deployment Order below)

### Key Components
- **System Upgrade Controller**: Manages automated k3s and Ubuntu upgrades
- **cert-manager**: Handles TLS certificate automation using Let's Encrypt and Cloudflare DNS-01 challenge
- **external-dns**: Synchronizes Kubernetes Ingress/Service resources with Cloudflare DNS records
- **Traefik**: Ingress controller (pre-installed with k3s, optional custom configuration)

### Node Naming Convention
Nodes follow pattern: `k3s-01[a-c].spahr.dev` (3 nodes: 01a, 01b, 01c)

## Common Commands

### Initial Setup

**First-time Ansible run (creates user account):**
```bash
ansible-playbook -bk -i ansible/inventory/k3s -u ubuntu ansible/playbooks/setup.yaml
```

**Subsequent Ansible runs:**
```bash
ansible-playbook -b -i ansible/inventory/k3s ansible/playbooks/setup.yaml
```

**Bootstrap k3s cluster:**
```bash
./k3s-bootstrap.sh
export KUBECONFIG=$(pwd)/kubeconfig
```

**Verify cluster:**
```bash
kubectl get nodes -o wide
```

### Cluster Management

**Apply all manifests (must follow deployment order):**
```bash
kubectl apply -f manifests/system-upgrade-controller.yaml
kubectl apply -f manifests/cert-manager.crds.yml
kubectl wait --for condition=established --timeout=60s crd/certificates.cert-manager.io
kubectl apply -f manifests/cert-manager.yml
kubectl apply -f manifests/dnsendpoint-crd.yml
kubectl apply -f manifests/external-dns.yml
```

**Check cluster component status:**
```bash
kubectl get pods --all-namespaces
kubectl get plans -n system-upgrade
kubectl get certificateissuers --all-namespaces
```

**View component logs:**
```bash
kubectl logs -n cert-manager -l app.kubernetes.io/component=controller
kubectl logs -n external-dns -l app=external-dns
```

### Uninstall

**Complete cluster teardown:**
```bash
ansible-playbook -b -i ansible/inventory/k3s ansible/playbooks/uninstall.yaml
```

### CI/CD Validation

**Local manifest validation (mimics GitHub Actions):**
```bash
# Validate YAML syntax
python3 -c "import yaml; from pathlib import Path; [print(f'✓ {f.name}') if yaml.safe_load_all(open(f)) else None for f in Path('manifests').glob('*.y*ml')]"

# Validate Kubernetes manifests
for manifest in manifests/*.yml manifests/*.yaml; do
  kubectl apply --dry-run=client -f "$manifest"
done

# Check container images
grep -h "image:" manifests/*.yml manifests/*.yaml | sed 's/.*image: *//;s/"//g' | sort -u

# Verify image ARM64 support
docker manifest inspect <image> | grep arm64
```

## Deployment Order (Critical)

Components **must** be deployed in this specific order due to dependencies:

1. **system-upgrade-controller** (provides upgrade Plans CRD)
2. **cert-manager CRDs** → **cert-manager** → **cert-manager-issuer** (requires Cloudflare API token secret)
3. **dnsendpoint-crd** → **external-dns** (requires Cloudflare API token secret)
4. **traefik** (optional, k3s includes Traefik by default)
5. **server-upgrade-plans** (optional, enables automated upgrades)

### Secrets Required

Before deploying cert-manager-issuer and external-dns:
```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=YOUR_TOKEN \
  -n cert-manager

kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=YOUR_TOKEN \
  -n external-dns
```

## Important Implementation Details

### k3s Version Management
- k3s version is hardcoded in `k3s-bootstrap.sh` (currently `v1.23.3+k3s1`)
- Update `K8SVERSION` variable when upgrading

### Ansible Role Structure
- `ansible/roles/common/tasks/main.yml`: Creates user, configures sudo, enables cgroups
- `ansible/roles/uninstall/tasks/main.yml`: Runs k3s uninstall scripts
- Inventory: `ansible/inventory/k3s` (simple INI format with `[k3s_nodes]` group)

### Node Resolution
- `k3s-bootstrap.sh` uses `dig +short` to resolve node IPs from DNS names
- Update `USER` variable to match your username

### ARM64 Specific Configuration
- Boot commandline modifications in `/boot/firmware/cmdline.txt` enable required cgroups
- All container images must support ARM64 architecture
- GitHub Actions validates ARM64 support via `docker manifest inspect`

### Security Scanning
- CI pipeline runs Trivy (image + manifest scanning) and kubesec
- Manifests are scanned for CRITICAL and HIGH severity issues
- Container images are validated for existence and ARM64 support

## File Locations

- **Ansible**: `ansible/` (playbooks, roles, inventory)
- **Kubernetes Manifests**: `manifests/` (all cluster components)
- **Bootstrap Scripts**: `k3s-bootstrap.sh`, `netplan-apply.sh`
- **Network Config Template**: `01-wifis-config.yaml`
- **CI/CD**: `.github/workflows/validate-manifests.yml`
- **Generated kubeconfig**: `kubeconfig` (created by k3sup, git-ignored)
