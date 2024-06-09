{ lib, ... }:

with lib;
let
  vlanConfig = name: id: {
    netdev = {
      netdevConfig = {
        Kind = "vlan";
        Name = name;
      };

      vlanConfig.Id = id;
    };

    network = {
      matchConfig.Name = name;

      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = "no";
        LinkLocalAddressing = "no";
      };

      address = flatten [
        (optional (id < 255) "10.248.${toString id}.1/24")
        (optional (id > 255) "10.${toString (id - 1000)}.0.1/16")
      ];

      linkConfig.RequiredForOnline = "routable";
    };
  };

  infraVlans = mapAttrs vlanConfig {
    cluster = 2;
    services = 3;
    management = 4;
    organisers = 5;
    # uplink = vlanConfig 6;

    guests = 1249;
  };
in
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking = {
    nat = {
      enable = true;

      internalIPs = [ "10.248.0.0/14" ];
      externalInterface = "enp1s0"; # TODO: Change to uplink
    };

    firewall = {
      filterForward = true;

      # TODO: Remove debug enp1s0
      extraForwardRules = ''
        iifname { enp1s0, organisers } accept comment "organisers have full access"
        iifname != { guests } oifname { services } accept comment "everyone but guests have access to services"
      '';
    };
  };

  systemd.network = {
    netdevs = mapAttrs' (n: v: { name = "20-${n}"; value = v.netdev; }) infraVlans;

    networks = recursiveUpdate
      (mapAttrs' (n: v: { name = "40-${n}"; value = v.network; }) infraVlans)
      {
        "30-rack" = {
          # TODO: Set to value of real hardware
          matchConfig.PermanentMACAddress = "52:54:00:50:26:b6";

          networkConfig = {
            DHCP = "no";
            IPv6AcceptRA = "no";
            LinkLocalAddressing = "no";
          };

          linkConfig.RequiredForOnline = "carrier";

          vlan = attrNames infraVlans;
        };

        "30-uplink" = {
          # TODO: Delete and enable VLAN after verifying this is the actual setup
          matchConfig.PermanentMACAddress = "52:54:00:2b:8a:57";

          networkConfig = {
            DHCP = "no";
            IPv6AcceptRA = "no";
            LinkLocalAddressing = "no";
          };

          address = [ "10.248.6.2/24" ];
          gateway = [ "10.248.6.1" ];

          linkConfig.RequiredForOnline = "routable";
        };
      };
  };
}
