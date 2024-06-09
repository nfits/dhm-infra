{ lib, ... }:

with lib;
let
  # TODO: Set to value of real hardware
  nodeMac = "52:54:00:61:b1:49";
  nodeIP = "10.248.2.11/24";

  networkConfig = {
    DHCP = "no";
    IPv6AcceptRA = "no";
    LinkLocalAddressing = "no";
  };
in
{
  systemd.network = {
    netdevs = mapAttrs'
      (n: v: {
        name = "20-${n}";
        value = {
          netdevConfig = {
            Kind = "vlan";
            Name = n;
          };

          vlanConfig.Id = v;
        };
      })
      {
        cluster = 2;
        services = 3;
      };

    networks = {
      "30-uplink" = {
        inherit networkConfig;

        matchConfig.PermanentMACAddress = nodeMac;
        linkConfig.RequiredForOnline = "carrier";

        vlan = [ "cluster" "services" ];
      };

      "40-cluster" = {
        inherit networkConfig;

        matchConfig.Name = "cluster";
        linkConfig.RequiredForOnline = "routable";

        address = [ nodeIP ];
        gateway = [ "10.248.2.1" ];
        # dns = [ "10.248.2.1" ]; TODO: Enable
      };

      "40-services" = {
        inherit networkConfig;

        matchConfig.Name = "services";
        linkConfig.RequiredForOnline = "carrier";
      };
    };
  };
}
