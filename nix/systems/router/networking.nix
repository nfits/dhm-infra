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

      linkConfig.RequiredForOnline = "routable";
    };
  };

  dhmVlans = mapAttrs vlanConfig config.dhm.networking.vlans;
in
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking = {
    nat = {
      enable = true;

      internalIPs = [ "10.248.0.0/14" ];
      externalInterface = "uplink";
    };

    firewall = {
      filterForward = true;

      # TODO: Remove management access to everything, used for testing
      extraForwardRules = ''
        iifname { organisers, management } accept comment "organisers have full access"
        iifname != { guests } oifname { services } accept comment "everyone but guests have access to services"
      '';
    };
  };

  systemd.network = {
    netdevs = mapAttrs' (n: v: { name = "20-${n}"; value = v.netdev; }) dhmVlans;

    networks = recursiveUpdate
      (mapAttrs' (n: v: { name = "40-${n}"; value = v.network; }) dhmVlans)
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
