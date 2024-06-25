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

Due to constraints al VLANs are offset by +2000.

| Zone          | VLAN                   | IP Ranges                        | DNS Zone     |
|---------------|------------------------|----------------------------------|--------------|
| Cluster Nodes | 2                      | 10.248.2.0/24                    | cluster.     |
| Services      | - (Routed via Cluster) | 10.248.3.0/24                    | svc.         |
| Management    | 4                      | 10.248.4.0/24                    | management.  |
| Organisers    | 5                      | 10.248.5.0/24                    | orga.        |
| Uplink        | 6                      | 10.248.6.0/24 (If needed at all) | uplink.      |
| Team 1-14     | 11-24                  | 10.248.<team-id>.0/24            | team-(1-14). |
| Guests        | 256                    | 10.249.0.0/16                    | guest.       |
| Cluster Pod   | - (Routed via Cluster) | 10.250.0.0/16 (Pod IP Range)     |              |
| Cluster Svc   | - (Routed via Cluster) | 10.251.0.0/16 (Service IP Range) |              |

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
Endpoint = 194.95.66.251:51820
```

### Development Setup

This flake has a devShell with pre-commit hooks for formatting and statix

For direnv support:
```
echo "use flake" >.envrc
direnv allow
```
