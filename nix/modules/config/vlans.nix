{ lib, ... }:

with lib;
let
  vlanOffset = 2000;

  subnet24Ip = subnet: ip: "10.248.${toString subnet}.${toString ip}";

  ipv4Default = subnet: {
    prefix = subnet24Ip subnet 0;
    routerAddress = subnet24Ip subnet 1;

    prefixLength = 24;
  };

  dhcpDefault = subnet: {
    enable = true;

    firstIP = subnet24Ip subnet 50;
    lastIP = subnet24Ip subnet 254;
  };
in
{
  dhm.networking = {
    tld = "dhm-ctf.de";

    vlans =
      {
        cluster = rec {
          dhcp = (dhcpDefault 2) // {
            staticLeases = {
              node1 = {
                ip = subnet24Ip 2 11;
                mac = "bc:24:11:40:47:ec";
              };
            };
          };

          dns.extraHosts = {
            api = [ dhcp.staticLeases.node1.ip ];
          };

          ipv4 = ipv4Default 2 // {
            routedSubnets = [ "10.248.3.0/24" ];
          };
          vlanId = vlanOffset + 2;
        };

        management = {
          dhcp = (dhcpDefault 4) // {
            staticLeases = {
              node1 = {
                ip = subnet24Ip 4 11;
                mac = "42:66:b5:cc:90:11";
              };
              node2 = {
                ip = subnet24Ip 4 12;
                mac = "52:34:f0:6e:06:02";
              };
              node3 = {
                ip = subnet24Ip 4 13;
                mac = "3e:14:ac:bc:43:61";
              };
              node4 = {
                ip = subnet24Ip 4 14;
                mac = "06:0f:c7:53:17:be";
              };
            };
          };

          ipv4 = ipv4Default 4;
          vlanId = vlanOffset + 4;
        };

        organisers = {
          dns.subdomain = "orga";

          dhcp = (dhcpDefault 5) // {
            staticLeases = {
              vpn-gateway = {
                ip = subnet24Ip 5 2;
                mac = "bc:24:11:1a:bf:7a";
              };
            };
          };

          ipv4 = ipv4Default 5;
          vlanId = vlanOffset + 5;
        };

        uplink = {
          ipv4 = {
            prefix = "10.248.6.0";
            prefixLength = 24;

            routerAddress = "10.248.6.2";
            gateway = "10.248.6.1";
          };

          vlanId = vlanOffset + 6;
        };

        services = {
          dns.subdomain = "svc";

          dhcp = dhcpDefault 7;

          ipv4 = ipv4Default 7;
          vlanId = vlanOffset + 7;
        };

        guests = {
          dns.subdomain = "guest";

          dhcp = {
            enable = true;

            firstIP = "10.249.0.50";
            lastIP = "10.249.255.254";
          };

          ipv4 = {
            prefix = "10.249.0.0";
            prefixLength = 16;

            routerAddress = "10.249.0.1";
          };

          vlanId = vlanOffset + 256;
        };
      }
      // (listToAttrs (
        map (id: {
          name = "team-${toString id}";
          value = {
            dns.subdomain = "team-${toString id}";

            dhcp = dhcpDefault (10 + id);

            ipv4 = ipv4Default (10 + id);
            vlanId = vlanOffset + (10 + id);
          };
        }) (range 1 14)
      ));
  };
}
