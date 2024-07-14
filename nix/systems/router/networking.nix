{ config, lib, ... }:

with lib;
let
  vlanConfig = name: cfg: {
    netdev = {
      netdevConfig = {
        Kind = "vlan";
        Name = name;
      };

      vlanConfig.Id = cfg.vlanId;
    };

    network = {
      matchConfig.Name = name;

      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = "no";
        LinkLocalAddressing = "no";
      };

      routingPolicyRules = optionals (cfg.ipv4.exitIPAddress != null) [
        {
          routingPolicyRuleConfig = {
            To = "10.248.0.0/14";
            Priority = 1000;
            Table = "main";
          };
        }
        {
          routingPolicyRuleConfig = {
            IncomingInterface = name;
            Priority = 1001;
            Table = name;
          };
        }
      ];

      address = flatten [
        "${cfg.ipv4.routerAddress}/${toString cfg.ipv4.prefixLength}"
        (optionals cfg.uplinkInterface (
          mapAttrsToList (
            _: cfg: "${cfg.ipv4.exitIPAddress.ip}/${toString cfg.ipv4.exitIPAddress.prefixLength}"
          ) (filterAttrs (_: v: v.ipv4.exitIPAddress != null) config.dhm.networking.vlans)
        ))
      ];

      gateway = optional (cfg.ipv4.gateway != null && !cfg.uplinkInterface) "${cfg.ipv4.gateway}";

      routes = flatten [
        (map (subnet: {
          routeConfig = {
            Destination = subnet;
          };
        }) cfg.ipv4.routedSubnets)
        (optionals cfg.uplinkInterface [
          {
            routeConfig = {
              Table = "main";
              Gateway = "${cfg.ipv4.gateway}";
              GatewayOnLink = true;
              Destination = "0.0.0.0/0";
              PreferredSource = cfg.ipv4.routerAddress;
            };
          }
          (mapAttrsToList (name: cfg: {
            routeConfig = {
              Table = name;
              Gateway = cfg.ipv4.exitIPAddress.gateway;
              GatewayOnLink = true;
              PreferredSource = cfg.ipv4.exitIPAddress.ip;
              Destination = "0.0.0.0/0";
            };
          }) (filterAttrs (_: v: v.ipv4.exitIPAddress != null) config.dhm.networking.vlans))
        ])
      ];

      linkConfig.RequiredForOnline = "routable";
    };
  };

  dhmVlans = mapAttrs vlanConfig config.dhm.networking.vlans;

  vpnIP = config.dhm.networking.vlans.organisers.dhcp.staticLeases.vpn-gateway.ip;
in
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking = {
    nftables = {
      flushRuleset = true;

      ruleset = ''
        table inet mss-clamping {
          chain clamp {
            type filter hook forward priority mangle; policy accept;

            oifname { uplink } tcp flags syn tcp option maxseg size set rt mtu
            iifname { uplink } tcp flags syn tcp option maxseg size set rt mtu
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority srcnat - 1; policy accept;

            ${
              concatStringsSep "\n" (
                mapAttrsToList (
                  _: cfg:
                  "ip saddr ${cfg.ipv4.prefix}/${toString cfg.ipv4.prefixLength} oifname uplink snat to ${cfg.ipv4.exitIPAddress.ip}"
                ) (filterAttrs (_: v: v.ipv4.exitIPAddress != null) config.dhm.networking.vlans)
              )
            }
          }
        }
      '';
    };

    nat = {
      enable = true;

      internalIPs = [ "10.248.0.0/14" ];
      externalIP = config.dhm.networking.vlans.uplink.ipv4.routerAddress;
      externalInterface = "uplink";

      forwardPorts = [
        {
          destination = "${vpnIP}:51820";
          proto = "udp";
          sourcePort = 51820;
        }
      ];
    };

    firewall = {
      filterForward = true;
      trustedInterfaces = [ "organisers" ];

      extraForwardRules = ''
        iifname { organisers } accept comment "organisers have full access"
        iifname { uplink } ip daddr { ${vpnIP} } accept comment "vpn gateway"
        ip daddr 193.56.133.168/29 accept comment "everyone but guests may access the k8s cluster"
        iifname != { guests } oifname { services } accept comment "everyone but guests have access to services"
      '';
    };
  };

  systemd.network = {
    config.routeTables = mapAttrs (_: v: v.vlanId) (
      filterAttrs (_: v: v.ipv4.exitIPAddress != null) config.dhm.networking.vlans
    );

    netdevs = mapAttrs' (n: v: {
      name = "20-${n}";
      value = v.netdev;
    }) dhmVlans;

    networks =
      recursiveUpdate
        (mapAttrs' (n: v: {
          name = "40-${n}";
          value = v.network;
        }) dhmVlans)
        {
          "30-rack" = {
            matchConfig.PermanentMACAddress = "bc:24:11:7b:38:f8";

            networkConfig = {
              DHCP = "no";
              IPv6AcceptRA = "no";
              LinkLocalAddressing = "no";
            };

            linkConfig.RequiredForOnline = "carrier";

            vlan = attrNames dhmVlans;
          };
        };
  };
}
