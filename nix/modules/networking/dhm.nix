{ lib, ... }:

with lib;
{
  options.dhm.networking = with types; {
    tld = mkOption { type = str; };

    vlans = mkOption {
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          dns = {
            subdomain = mkOption {
              type = str;
              default = name;
              description = "The subdomain of the network zone.";
            };

            extraHosts = mkOption {
              type = attrsOf str;
              default = { };
              description = "Extra hosts.";
            };

            honorUpstream = mkOption {
              type = bool;
              default = false;
              description = "Whether or not to honor the upstream for the domain when resolving.";
            };
          };

          dhcp = {
            enable = mkEnableOption "dhcp";

            firstIP = mkOption {
              type = str;
              description = "First ip of the DHCP range.";
            };

            lastIP = mkOption {
              type = str;
              description = "First ip of the DHCP range.";
            };

            ttl = mkOption {
              type = str;
              default = "24h";
              description = "TTL of the leases.";
            };

            staticLeases = mkOption {
              type = attrsOf (submodule {
                options = {
                  ip = mkOption { type = str; };
                  mac = mkOption { type = str; };
                };
              });
              default = { };
              description = "Static dhcp leases.";
            };
          };

          ipv4 = {
            prefix = mkOption { type = str; };
            prefixLength = mkOption { type = int; };

            routerAddress = mkOption { type = str; };
            gateway = mkOption { type = nullOr str; default = null; };
          };

          vlanId = mkOption { type = int; };
        };
      }));

      default = { };
      description = "VLANs deployed across the DHM infrastructure.";
    };
  };
}
