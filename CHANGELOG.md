# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub issue templates
  - Bug report template with environment and component tracking
  - Feature request template with problem/solution format
  - Template configuration linking to discussions
- Pull request template
  - Type of change selection
  - Component tracking checklist
  - Testing requirements (local, validation, security, ARM64)
  - Documentation and CHANGELOG update reminders

## [1.3.0] - 2025-12-13

### Added
- Security scanning to GitHub Actions workflow
  - Trivy for Kubernetes manifest security analysis
  - Trivy for container image vulnerability scanning (CRITICAL and HIGH severity)
  - kubesec for Kubernetes security best practices validation
  - Automated security checks on every push and pull request

## [1.2.0] - 2025-12-13

### Added
- Comprehensive deployment guide in README
  - Step-by-step deployment instructions for all components
  - Verification commands for each component
  - Post-deployment configuration steps
  - Troubleshooting section for common issues
  - Cloudflare API token setup instructions

## [1.1.0] - 2025-12-13

### Added
- GitHub Actions workflow for automated manifest validation
- YAML syntax validation in CI/CD pipeline
- Container image verification in CI/CD pipeline
- ARM64 architecture support verification in CI/CD pipeline
- Workflow status badge in README
- CHANGELOG.md file following Keep a Changelog format

## [1.0.0] - 2025-12-13

### Changed
- **k3s**: Updated from v1.23.3+k3s1 to v1.34.2+k3s1 (Kubernetes v1.34.2)
- **cert-manager**: Updated from v1.6.1 to v1.19.2
  - Includes security fixes for CVE-2025-61727 and CVE-2025-61729
  - Go version upgraded to v1.25.5
  - Base images updated to Debian 12 distroless
- **external-dns**: Updated from v0.15.1 to v0.20.0
  - Migrated image registry from k8s.gcr.io to registry.k8s.io
- **system-upgrade-controller**: Updated from v0.15.0 to v0.18.0
- **kubectl**: Updated from v1.18.20 to v1.34.2 (in system-upgrade-controller config)
- **Ubuntu**: Updated base OS version from 20.04 LTS to 24.04 LTS

### Fixed
- Updated deprecated k8s.gcr.io registry references to registry.k8s.io

### Security
- Applied security patches in cert-manager (CVE-2025-61727, CVE-2025-61729)
- Updated all components to latest stable versions with security fixes

## [Initial] - Before v1.0.0

### Added
- Initial k3s cluster setup for Raspberry Pi
- Ansible playbooks for cluster provisioning
- cert-manager for certificate management
- external-dns for DNS automation with Cloudflare
- Traefik ingress controller configuration
- System upgrade controller for automated k3s and OS updates
- Dependabot configuration for automated dependency updates

[Unreleased]: https://github.com/jeffspahr/k3s-on-pi/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/jeffspahr/k3s-on-pi/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/jeffspahr/k3s-on-pi/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/jeffspahr/k3s-on-pi/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/jeffspahr/k3s-on-pi/releases/tag/v1.0.0
