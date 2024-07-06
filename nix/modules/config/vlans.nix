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
              node2 = {
                ip = subnet24Ip 2 12;
                mac = "bc:24:11:1b:c0:de";
              };
              node3 = {
                ip = subnet24Ip 2 13;
                mac = "bc:24:11:8e:e4:c4";
              };
              node4 = {
                ip = subnet24Ip 2 14;
                mac = "bc:24:11:b3:6c:31";
              };
              node5 = {
                ip = subnet24Ip 2 15;
                mac = "bc:24:11:3f:ac:75";
              };
            };
          };

          dns.extraHosts = {
            api = with dhcp.staticLeases; [
              node1.ip
              node2.ip
              node3.ip
              node4.ip
              node5.ip
            ];
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
                mac = "5a:99:bb:a2:16:82";
              };
              node2 = {
                ip = subnet24Ip 4 12;
                mac = "b2:f1:59:bb:28:eb";
              };
              node3 = {
                ip = subnet24Ip 4 13;
                mac = "3e:14:ac:bc:43:61";
              };
              node4 = {
                ip = subnet24Ip 4 14;
                mac = "06:0f:c7:53:17:be";
              };
              node5 = {
                ip = subnet24Ip 4 15;
                mac = "42:a3:3f:f4:1c:86";
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
              schreihals = {
                ip = subnet24Ip 5 3;
                mac = "7c:d3:0a:31:87:62";
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

          vlanId = vlanOffset + 2000;
        };

        wlan = {
          dns.subdomain = "wlan";

          dhcp = dhcpDefault 8;

          ipv4 = ipv4Default 8;
          vlanId = 891;
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
