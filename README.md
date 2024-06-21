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
| Services      | 3                      | 10.248.3.0/24                    | svc.         |
| Management    | 4                      | 10.248.4.0/24                    | management.  |
| Organisers    | 5                      | 10.248.5.0/24                    | orga.        |
| Uplink        | 6                      | 10.248.6.0/24 (If needed at all) | uplink.      |
| Team 1-14     | 11-24                  | 10.248.<team-id>.0/24            | team-(1-14). |
| Guests        | 256                    | 10.249.0.0/16                    | guest.       |
| Cluster Pod   | - (Routed via Cluster) | 10.250.0.0/16 (Pod IP Range)     |              |
| Cluster Svc   | - (Routed via Cluster) | 10.251.0.0/16 (Service IP Range) |              |
