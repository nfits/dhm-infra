{ config, lib, ... }:

with lib;
let
  cfg = config.dhm.networking;

  networkConfig = {
    DHCP = "no";
    IPv6AcceptRA = "no";
    LinkLocalAddressing = "no";
  };
in
{
  systemd.network = {
    config = {
      routeTables = {
        services = 1000;
      };
    };

    netdevs = mapAttrs'
      (n: v: {
        name = "20-${n}";
        value = {
          netdevConfig = {
            Kind = "vlan";
            Name = n;
          };

          vlanConfig.Id = v.vlanId;
        };
      })
      (filterAttrs (name: _: elem name [ "cluster" "services" ]) cfg.vlans);

    networks = {
      "30-uplink" = {
        inherit networkConfig;

        matchConfig.PermanentMACAddress = cfg.vlans.cluster.dhcp.staticLeases.node1.mac;
        linkConfig.RequiredForOnline = "carrier";

        vlan = [ "cluster" "services" ];
      };

      "40-cluster" = {
        inherit networkConfig;

        matchConfig.Name = "cluster";
        linkConfig.RequiredForOnline = "routable";

        address = [
          "${cfg.vlans.cluster.dhcp.staticLeases.${config.networking.hostName}.ip}/${toString cfg.vlans.cluster.ipv4.prefixLength}"
        ];
        gateway = [ cfg.vlans.cluster.ipv4.routerAddress ];
        dns = [ cfg.vlans.cluster.ipv4.routerAddress ];
      };

      "40-services" =
        let
          serviceCidr = "${cfg.vlans.services.ipv4.prefix}/${toString cfg.vlans.services.ipv4.prefixLength}";
        in
        {
          inherit networkConfig;

          matchConfig.Name = "services";
          linkConfig.RequiredForOnline = "carrier";

          routingPolicyRules = [
            {
              routingPolicyRuleConfig = {
                From = serviceCidr;
                To = "10.250.0.0/15";
                Table = "main";
                Priority = 2000;
              };
            }
            {
              routingPolicyRuleConfig = {
                From = serviceCidr;
                Table = "services";
                Priority = 2001;
              };
            }
          ];

          routes = [
            {
              routeConfig = {
                Destination = serviceCidr;
                Scope = "link";
                Table = "services";
              };
            }
            {
              routeConfig = {
                Gateway = cfg.vlans.services.ipv4.routerAddress;
                GatewayOnLink = true;
                Table = "services";
              };
            }
          ];
        };
    };
  };
}
