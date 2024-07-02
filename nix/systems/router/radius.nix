{
  config,
  lib,
  pkgs,
  self,
  ...
}:

with lib;
let
  vlanCfg = config.dhm.networking.vlans;
  pkg = pkgs.freeradius;

  port = 1812;

  usersFile = pkgs.writeText "users" ''
    ${concatStringsSep "\n" (
      map (user: ''
        ${user}
                Tunnel-Private-Group-Id = ${toString vlanCfg.${user}.vlanId},
                Fall-Through            = Yes
      '') ([ "organisers" ] ++ (map (id: "team-${toString id}") (range 1 14)))
    )}

    DEFAULT
            Tunnel-Type        = VLAN,
            Tunnel-Medium-Type = IEEE-802
  '';

  configText = ''
    prefix = /dev/null

    checkrad = ${pkg}/bin/checkrad
    localstatedir = "/var/lib/freeradius"
    sbindir = "${pkg}/sbin"
    logdir = "/var/log/freeradius"
    run_dir = "/run/radiusd"
    libdir = "${pkg}/lib"
    radacctdir = "''${logdir}/radacct"
    pidfile = "/dev/null/var/run/radiusd/radiusd.pid"
    modconfdir = ''${confdir}/mods-config

    max_requests = ${toString (256 * 50)}

    policy {
      $INCLUDE policy.d/
    }

    client localhost {
      ipaddr = 127.0.0.1
      secret = testing
    }

    thread pool {
      start_servers = 2
      max_servers = 4

      min_spare_servers = 1
      max_spare_servers = 3
    }

    modules {
      $INCLUDE mods-enabled/

      passwd dhm_passwd {
        filename = ${config.sops.secrets.passwords.path}

        format = "*User-Name:Cleartext-Password"
        delimiter = ":"
        ignore_nislike = no
        allow_multiple_keys = no
      }

      files {
        filename = ${usersFile}
      }

      eap inner-eap {
        default_eap_type = mschapv2

        gtc {
          auth_type = PAP
        }

        mschapv2 { }
      }
    }

    # ... log, client, thread pool, module, policy, and server config...
    server inner-tunnel {
      listen {
        type = auth
        ipaddr = 127.0.0.1
        port = ${toString (port + 1)}
      }

      authorize {
        filter_username

        chap
        mschap

        inner-eap {
          ok = return
        }

        dhm_passwd
        files

        expiration
        logintime

        pap
      }

      authenticate {
        Auth-Type PAP {
          pap
        }

        Auth-Type CHAP {
          chap
        }

        Auth-Type MS-CHAP {
          mschap
        }

        inner-eap
      }

      post-auth {
        Post-Auth-Type REJECT {
          attr_filter.access_reject

          update outer.session-state {
            &Module-Failure-Message := &request:Module-Failure-Message
          }
        }
      }
    }
  '';

  upstreamModules = [
    "always"
    "attr_filter"
    "chap"
    "expiration"
    "logintime"
    "mschap"
    "pap"
  ];

  configDir = pkgs.runCommand "raddb" { } ''
    mkdir $out

    ln -s ${pkg}/etc/raddb/mods-available $out/mods-available
    ln -s ${pkg}/etc/raddb/policy.d $out/policy.d

    mkdir $out/mods-config/
    ln -s ${pkg}/etc/raddb/mods-config/attr_filter $out/mods-config/attr_filter

    mkdir $out/mods-enabled/
    ${concatStringsSep "\n" (
      map (e: "ln -s ../mods-available/${e} $out/mods-enabled/${e}") upstreamModules
    )}

    ln -s ${pkgs.writeText "radiusd.conf" configText} $out/radiusd.conf
  '';
in
{
  sops.secrets = {
    passwords = {
      sopsFile = "${self}/secrets/credentials.sops.yaml";

      mode = "0400";
      owner = "radius";
    };
  };

  users = {
    users.radius.group = "radius";
    groups.radius = { };
  };

  services.freeradius = {
    enable = true;
    debug = true;

    inherit configDir;
  };
}
