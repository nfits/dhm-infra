DHM Infrastructure
===

## Server Setup

### Router

- 1 blade running the competition router
- connected to all VLANs

### Node1, Node2, Node3

- 3 blades, running the k3s instances
- connected to VLAN 2 and 3

## Network Setup

### Network Zones

The DHM network is `10.248.0.0/14`.
DNS Zones are extended by `dhm-ctf.de`.

| Zone              | VLAN                   | IP Ranges                        | DNS Zone           |
|-------------------|------------------------|----------------------------------|--------------------|
| Cluster Nodes     | 2002                   | 10.248.2.0/24                    | cluster.           |
| Cluster Services  | - (Routed via Cluster) | 10.248.3.0/24                    |                    |
| Management        | 2004                   | 10.248.4.0/24                    | management.        |
| Organisers        | 2005                   | 10.248.5.0/24                    | orga.              |
| Uplink            | 200                    | 31.172.98.0/23                   | -                  |
| Services          | 2007                   | 10.248.7.0/24                    | svc.               |
| AP Management     | 891                    | 10.248.8.0/24                    | wlan.              |
| Team 1-14         | 2011-24                | 10.248.<team-id>.0/24            | team-(1-14).       |
| NVISO Challenge   | 3000                   | 10.248.100.0/24                  | nviso-challenge.   |
| NVISO Participant | 3001                   | 10.248.101.0/24                  | nviso-participant. |
| BWI Challenge     | 3002                   | 10.248.102.0/24                  | bwi-challenge.     |
| Guests            | 4000                   | 10.249.0.0/16                    | guest.             |
| Cluster Pod       | - (Routed via Cluster) | 10.250.0.0/16 (Pod IP Range)     |                    |
| Cluster Svc       | - (Routed via Cluster) | 10.251.0.0/16 (Service IP Range) |                    |

## Access

### Wireguard Config Template

```
[Interface]
Address = 10.247.0.<ip>/32
# Uncomment if you need dns
# DNS = 10.248.5.1
# Uncomment if you use systemd-resolved (test via `resolvectl`), this limits dns requests only to our domain
# PostUp = resolvectl domain %i ~dhm-ctf.de
PrivateKey = <private-key>

[Peer]
PublicKey = gMyOiGbFTPFH4OusZghGWohkPY/SBekMuNckK2nw7xY=
AllowedIPs = 10.248.0.0/14
Endpoint = vpn.dhm-ctf.de:51820
```

### Development Setup

This flake has a devShell with pre-commit hooks for formatting and statix

For direnv support:

```
echo "use flake" >.envrc
direnv allow
```
