<div align="center"><img src="assets/logo.png" width="300px"></div>

# Overview

This repository contains a complete NixOS system configuration using flakes, designed for running self-hosted services and managing network infrastructure. The configuration is modular and organized for maintainability.

# Hosts

## homelab

### Hardware
- Ryzen 9 4650G
- B550 Aorus Elite V2
- 48GB RAM
- 256GB SSD
- Sipeed NanoKVM PCIe
- Jonsbo N5 Case

### Solutions
- **Nextcloud** - Self-hosted file sync and collaboration platform
- **Vaultwarden** - Bitwarden-compatible password manager
- **Wireguard** - VPN with split tunneling for work/home/censored services
- **singbox** - Hysteria2 proxy for censored domains/ip
- **dnsmasq** - dnsmasq DNS server for custom local domains
- **Adguard Home** - DNS server for ad-blocking / DoH
- **restic** - Automated backup solution
- **nginx** - Reverse proxy

## steam

### Hardware
- Ryzen 5 7500f
- Sapphire NITRO+ B850M WIFI
- 32GB RAM
- 2TB SSD for NixOS / 1TB SSD for Windows 11
- Radeon 9070XT
- Lian Li A3 Case

### Solutions
- **Jovian** - SteamOS-like config for NixOS
- **Wireguard** - VPN for connecting to homelab
- **CachyOS Proton** - custom Proton with FSR4 support
- **CachyOS kernel** - custom kernel with HDMI-DP dongle support
- **LACT** - AMD GPU overclocking
- **ADB/WOL wake up** - for waking up TV from sleep
- **lanzaboote** - secure boot

## Installation

Disk partitioning (example for steam machine):
```bash
sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode zap_create_mount hosts/steam/disko.nix
```

Add personal ssh keys for secrets:
```bash
cp {ssh-key-name} /root/.ssh/{ssh-key-name}
sudo chmod 500 /root/.ssh/{ssh-key-name}
```

Installing the system:
```bash
sudo nixos-install --flake .#steam
```
