{ config, lib, ... }:

with lib;
let
  tld = "dhm-ctf.de";

  zones = {
    cluster = {
      dns = "cluster.${tld}";
      listenAddress = "10.248.2.1";

      dhcpRange = {
        start = "10.248.2.150";
        end = "10.248.2.254";
        ttl = "24h";
      };

      staticLeases = {
        # TODO: Set to actual MACs
        node1 = { mac = "52:54:00:ef:ae:15"; ip = "10.248.2.10"; };
        node2 = { mac = "52:54:00:61:b1:49"; ip = "10.248.2.11"; };
        node3 = { mac = "52:54:00:8d:a3:2f"; ip = "10.248.2.12"; };
      };
    };

    services = {
      dns = "svc.${tld}";
      listenAddress = "10.248.3.1";

      dhcpRange = {
        start = "10.248.2.150";
        end = "10.248.2.254";
        ttl = "24h";
      };
    };
  };
in
{
  services = {
    dnsmasq = {
      enable = true;

      settings = {
        server = [ "1.1.1.1" "1.0.0.1" ];

        auth-server = concatStringsSep "," (flatten [
          "${config.networking.fqdn}"
          (mapAttrsToList (_: v: v.listenAddress) zones)
        ]);
        auth-zone = tld;

        interface = attrNames zones;
        listen-address = concatStringsSep "," ((mapAttrsToList (_: v: v.listenAddress) zones) ++ [ "127.0.0.1" "::1" ]);

        dhcp-range = mapAttrsToList
          (zone: cfg: "set:${zone},${cfg.dhcpRange.start},${cfg.dhcpRange.end},${cfg.dhcpRange.ttl}")
          (filterAttrs (_: v: v.dhcpRange or null != null) zones);

        dhcp-option = flatten (mapAttrsToList
          (zone: cfg: [
            "tag:${zone},option:router,${cfg.listenAddress}"
            "tag:${zone},option:dns-server,${cfg.listenAddress}"
            "tag:${zone},option:domain-name,${cfg.dns}"
            "tag:${zone},option:domain-search,${cfg.dns}"
          ])
          (filterAttrs (_: v: v.dhcpRange or null != null) zones));

        dhcp-host = flatten (mapAttrsToList
          (zone: cfg: mapAttrsToList
            (hostname: hostCfg: "${hostCfg.mac},tag:${zone},${hostCfg.ip},${hostname},infinite")
            (cfg.staticLeases or { }))
          zones);
      };
    };

    resolved.enable = false;
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 67 ];
  };
}
