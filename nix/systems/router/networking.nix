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

      address = [ "${cfg.ipv4.routerAddress}/${toString cfg.ipv4.prefixLength}" ];
      gateway = optional (cfg.ipv4.gateway != null) "${cfg.ipv4.gateway}";

      routes = map (subnet: {
        routeConfig = {
          Destination = subnet;
        };
      }) cfg.ipv4.routedSubnets;

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
      '';
    };

    nat = {
      enable = true;

      internalIPs = [ "10.248.0.0/14" ];
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
        iifname != { guests } ip daddr 10.248.3.0/24 accept comment "everyone but guests may access the k8s cluster"
        iifname != { guests } oifname { services } accept comment "everyone but guests have access to services"
      '';
    };
  };

  systemd.network = {
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
