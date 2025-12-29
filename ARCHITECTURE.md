# Architecture Diagram

## System Architecture

```mermaid
graph TB
    subgraph "External Services"
        CF[Cloudflare DNS/API]
        LE[Let's Encrypt]
    end

    subgraph "Management Workstation"
        A[Ansible Playbooks]
        K3SUP[k3sup]
        KC[kubectl]
    end

    subgraph "Raspberry Pi Cluster"
        subgraph "k3s-01a.spahr.dev"
            N1[k3s Server + etcd]
        end

        subgraph "k3s-01b.spahr.dev"
            N2[k3s Server + etcd]
        end

        subgraph "k3s-01c.spahr.dev"
            N3[k3s Server + etcd]
        end

        subgraph "Cluster Components"
            SC[System Upgrade Controller]
            CM[cert-manager]
            ED[external-dns]
            TR[Traefik Ingress]
        end
    end

    A -->|1. Provision Hosts| N1
    A -->|1. Provision Hosts| N2
    A -->|1. Provision Hosts| N3

    K3SUP -->|2. Bootstrap HA Cluster| N1
    K3SUP -->|2. Join Cluster| N2
    K3SUP -->|2. Join Cluster| N3

    KC -->|3. Deploy Components| SC
    KC -->|3. Deploy Components| CM
    KC -->|3. Deploy Components| ED
    KC -->|3. Deploy Components| TR

    N1 -.->|embedded etcd| N2
    N2 -.->|embedded etcd| N3
    N3 -.->|embedded etcd| N1

    CM -->|ACME DNS-01| LE
    CM -->|DNS Challenge| CF
    ED -->|Sync DNS Records| CF

    SC -.->|Upgrades| N1
    SC -.->|Upgrades| N2
    SC -.->|Upgrades| N3

    style N1 fill:#e1f5ff
    style N2 fill:#e1f5ff
    style N3 fill:#e1f5ff
    style CM fill:#ffe1f5
    style ED fill:#ffe1f5
    style TR fill:#ffe1f5
    style SC fill:#ffe1f5
```

## Component Interaction Flow

```mermaid
sequenceDiagram
    participant User
    participant Ingress as Traefik Ingress
    participant App as Application Pod
    participant DNS as external-dns
    participant Cert as cert-manager
    participant CF as Cloudflare
    participant LE as Let's Encrypt

    Note over User,LE: Initial Setup Flow

    User->>App: Deploy application with Ingress
    App->>DNS: Ingress created event
    DNS->>CF: Create/Update DNS record

    App->>Cert: Certificate requested
    Cert->>CF: Create DNS TXT record (ACME challenge)
    Cert->>LE: Request certificate validation
    LE->>CF: Verify DNS TXT record
    LE->>Cert: Issue certificate
    Cert->>Ingress: Store TLS certificate

    Note over User,LE: Runtime Traffic Flow

    User->>CF: DNS query (app.domain.com)
    CF->>User: Returns cluster IP
    User->>Ingress: HTTPS request
    Ingress->>App: Forward request
    App->>Ingress: Response
    Ingress->>User: HTTPS response
```

## Deployment Order

```mermaid
graph LR
    A[system-upgrade-controller] --> B[cert-manager CRDs]
    B --> C[cert-manager]
    C --> D[cert-manager-issuer]
    D --> E[dnsendpoint-crd]
    E --> F[external-dns]
    F --> G[traefik config]
    G --> H[upgrade-plans]

    style A fill:#ffcccc
    style B fill:#ffddcc
    style C fill:#ffeecc
    style D fill:#ffffcc
    style E fill:#eeffcc
    style F fill:#ccffcc
    style G fill:#ccffee
    style H fill:#cceeff
```

## Bootstrap Workflow

```mermaid
flowchart TD
    Start[Flash Ubuntu 24.04 to SD Cards] --> Net[Add Netplan WiFi Config]
    Net --> Boot[First Boot: Auto-join Network]
    Boot --> Ansible1[Ansible: Create User & SSH Keys]
    Ansible1 --> Ansible2[Ansible: Enable cgroups]
    Ansible2 --> K3S1[k3sup: Install First Server]
    K3S1 --> K3S2[k3sup: Join Second Server]
    K3S2 --> K3S3[k3sup: Join Third Server]
    K3S3 --> Verify[Verify 3-node HA Cluster]
    Verify --> Deploy[Deploy Cluster Components]
    Deploy --> Done[Production Ready]

    style Start fill:#e1f5ff
    style Ansible1 fill:#ffe1e1
    style Ansible2 fill:#ffe1e1
    style K3S1 fill:#e1ffe1
    style K3S2 fill:#e1ffe1
    style K3S3 fill:#e1ffe1
    style Done fill:#ffe1ff
```

## Network Architecture

```mermaid
graph TB
    subgraph Internet
        Users[Internet Users]
        CF[Cloudflare DNS]
    end

    subgraph "Home Network / WiFi"
        subgraph "k3s Cluster - 192.168.x.x"
            N1[k3s-01a<br/>Control Plane + Worker]
            N2[k3s-01b<br/>Control Plane + Worker]
            N3[k3s-01c<br/>Control Plane + Worker]

            LB[kube-vip / MetalLB<br/>Load Balancer]

            N1 --- LB
            N2 --- LB
            N3 --- LB
        end
    end

    Users -->|HTTPS| CF
    CF -->|DNS Resolution| LB
    LB -->|Traffic Distribution| N1
    LB -->|Traffic Distribution| N2
    LB -->|Traffic Distribution| N3

    style LB fill:#ffcc00
    style CF fill:#ff9900
```

## Key Design Decisions

### High Availability
- **3 Server Nodes**: All nodes run both control plane and worker roles
- **Embedded etcd**: Distributed consensus across all 3 nodes (quorum-based)
- **No External Dependencies**: Self-contained cluster survives individual node failures

### Automation
- **Ansible**: Idempotent host configuration (cgroups, users, SSH)
- **k3sup**: Simplified k3s deployment with HA support
- **System Upgrade Controller**: Automated k3s and Ubuntu OS upgrades

### Certificate Management
- **cert-manager**: Automated TLS certificate lifecycle
- **Let's Encrypt**: Free, automated certificate authority
- **DNS-01 Challenge**: Works without exposing cluster to internet (via Cloudflare API)

### DNS Management
- **external-dns**: Kubernetes-native DNS synchronization
- **Cloudflare Integration**: Automatic DNS record creation/deletion for Ingresses
- **DNSEndpoint CRD**: Custom DNS records independent of Ingresses

### Resource Constraints
- **ARM64 Only**: All container images must support ARM64 architecture
- **8GB RAM per Node**: Sufficient for small-to-medium workloads
- **SD Card Storage**: Consider using USB SSD for production (I/O intensive workloads)
