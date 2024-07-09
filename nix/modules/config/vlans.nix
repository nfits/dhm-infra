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

  lightMacs = {
    team-1 = "fc:e8:c0:7e:51:7b";
    team-2 = "fc:e8:c0:7e:39:17";
    team-3 = "fc:e8:c0:7e:01:cb";
    team-4 = "fc:e8:c0:7e:80:f7";
    team-5 = "fc:e8:c0:7d:1f:9f";
    team-6 = "fc:e8:c0:7e:a4:ef";
    team-7 = "fc:e8:c0:7d:26:57";
    team-8 = "fc:e8:c0:7e:95:cb";
    team-9 = "fc:e8:c0:7e:2a:bf";
    team-10 = "fc:e8:c0:7e:79:33";
    team-11 = "fc:e8:c0:7e:95:a3";
    team-12 = "fc:e8:c0:7e:95:a3";
    team-13 = "fc:e8:c0:7d:3c:33";
    team-14 = "fc:e8:c0:7d:eb:db";

    orga-1 = "";
    orga-2 = "";
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
                mac = "48:2a:e3:39:a8:76";
              };
            };
          };

          ipv4 = ipv4Default 5;
          vlanId = vlanOffset + 5;
        };

        uplink = {
          ipv4 = {
            prefix = "31.172.98.0";
            prefixLength = 23;

            routerAddress = "31.172.98.42";
            gateway = "31.172.99.254";
          };

          vlanId = 200;
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

        nviso-chal = {
          dns.subdomain = "nviso-challenge";

          dhcp = dhcpDefault 100;

          ipv4 = ipv4Default 100;
          vlanId = vlanOffset + 1000;
        };

        nviso-team = {
          dns.subdomain = "nviso-participant";

          dhcp = dhcpDefault 101;

          ipv4 = ipv4Default 101;
          vlanId = vlanOffset + 1001;
        };
      }
      // (listToAttrs (
        map (id: {
          name = "team-${toString id}";
          value = {
            dns.subdomain = "team-${toString id}";

            dhcp = dhcpDefault (10 + id) // {
              staticLeases = {
                lichtstab = {
                  ip = subnet24Ip (10 + id) 2;
                  mac = lightMacs."team-${toString id}";
                };
              };
            };

            ipv4 = ipv4Default (10 + id);
            vlanId = vlanOffset + (10 + id);
          };
        }) (range 1 14)
      ));
  };
}
