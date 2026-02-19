<div align="center"><img src="assets/logo.png" width="300px"></div>

# Overview

This repository contains a complete NixOS system configuration using flakes, designed for running self-hosted services and managing network infrastructure. The configuration is modular and organized for maintainability.

# Hosts

## homelab

<div align="center"><img src="assets/jonsbo-n5.png" width="300px"></div>

### Hardware
- Ryzen 9 5950x
- B550 Aorus Elite V2
- 48GB RAM
- 1TB SSD
- Intel Arc A380
- Sipeed NanoKVM PCIe

### Services
- **Nextcloud** - Self-hosted file sync and collaboration platform
- **Vaultwarden** - Bitwarden-compatible password manager
- **VPN** - WireGuard with split tunneling for own domains/censored domains
- **DNS** - dnsmasq DNS server for WireGuard split tunneling
- **Xray** - VLESS proxy for censored domains
- **Restic** - Automated backup solution
- **Nginx** - Reverse proxy
