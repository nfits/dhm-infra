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
    netdevs = mapAttrs' (n: v: {
      name = "20-${n}";
      value = {
        netdevConfig = {
          Kind = "vlan";
          Name = n;
        };

        vlanConfig.Id = v.vlanId;
      };
    }) (filterAttrs (name: _: elem name [ "cluster" ]) cfg.vlans);

    networks = {
      "30-uplink" = {
        inherit networkConfig;

        matchConfig.PermanentMACAddress = cfg.vlans.cluster.dhcp.staticLeases.node1.mac;
        linkConfig.RequiredForOnline = "carrier";

        vlan = [ "cluster" ];
      };

      "40-cluster" = {
        inherit networkConfig;

        matchConfig.Name = "cluster";
        linkConfig.RequiredForOnline = "routable";

        address = [
          "${
            cfg.vlans.cluster.dhcp.staticLeases.${config.networking.hostName}.ip
          }/${toString cfg.vlans.cluster.ipv4.prefixLength}"
        ];
        gateway = [ cfg.vlans.cluster.ipv4.routerAddress ];
        dns = [ cfg.vlans.cluster.ipv4.routerAddress ];
      };
    };
  };
}
