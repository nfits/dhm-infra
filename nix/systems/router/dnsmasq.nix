{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.dhm.networking;

  hostsFile = pkgs.writeText "dnsmasq-hosts" (
    concatStringsSep "\n" (
      flatten (
        mapAttrsToList (_: cfg: [
          (mapAttrsToList (
            name: entry: "${entry.ip} ${name}.${cfg.dns.subdomain}.${config.dhm.networking.tld}"
          ) cfg.dhcp.staticLeases)
          (mapAttrsToList (
            slug: map (ip: "${ip} ${slug}.${cfg.dns.subdomain}.${config.dhm.networking.tld}")
          ) cfg.dns.extraHosts)
          "${cfg.ipv4.routerAddress} ${config.networking.hostName}.${cfg.dns.subdomain}.${config.dhm.networking.tld}"
        ]) config.dhm.networking.vlans
      )
    )
  );
in
{
  services = {
    dnsmasq = {
      enable = true;

      settings = {
        no-resolv = true;
        no-hosts = true;
        addn-hosts = "${hostsFile}";

        server = [
          "1.1.1.1"
          "1.0.0.1"
        ];

        interface = attrNames cfg.vlans;
        listen-address = concatStringsSep "," (
          (mapAttrsToList (_: v: v.ipv4.routerAddress) cfg.vlans)
          ++ [
            "127.0.0.1"
            "::1"
          ]
        );

        dhcp-range = mapAttrsToList (
          zone: cfg: "set:${zone},${cfg.dhcp.firstIP},${cfg.dhcp.lastIP},${cfg.dhcp.ttl}"
        ) (filterAttrs (_: v: v.dhcp.enable) cfg.vlans);

        local = mapAttrsToList (_: cfg: "/${cfg.dns.subdomain}.${config.dhm.networking.tld}/") (
          filterAttrs (_: e: !e.dns.honorUpstream) cfg.vlans
        );

        dhcp-option = flatten (
          mapAttrsToList (zone: cfg: [
            "tag:${zone},option:router,${cfg.ipv4.routerAddress}"
            "tag:${zone},option:dns-server,${cfg.ipv4.routerAddress}"
            "tag:${zone},option:domain-name,${cfg.dns.subdomain}.${config.dhm.networking.tld}"
            "tag:${zone},option:domain-search,${cfg.dns.subdomain}.${config.dhm.networking.tld}"
          ]) (filterAttrs (_: v: v.dhcp.enable) cfg.vlans)
        );

        dhcp-host = flatten (
          mapAttrsToList (
            zone: cfg:
            mapAttrsToList (
              hostname: hostCfg: "${hostCfg.mac},tag:${zone},${hostCfg.ip},${hostname},infinite"
            ) cfg.dhcp.staticLeases
          ) cfg.vlans
        );
      };
    };

    resolved.enable = false;
  };

  networking.firewall = {
    allowedTCPPorts = [
      53 # DNS
    ];

    allowedUDPPorts = [
      53 # DNS
      67 # DHCP
    ];
  };
}
