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

  certDir = config.security.acme.certs."dhm-ctf.de".directory;

  port = 1812;

  usersFile = pkgs.writeText "users" ''
    ${concatStringsSep "\n" (
      map (user: ''
        ${user}
                Tunnel-Private-Group-Id := ${toString vlanCfg.${user}.vlanId},
                Fall-Through            = Yes
      '') ([ "organisers" ] ++ (map (id: "team-${toString id}") (range 1 14)))
    )}

    DEFAULT
            Tunnel-Type        := VLAN,
            Tunnel-Medium-Type := IEEE-802
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

    client wifiAP {
      ipaddr = 10.248.8.0/24
      $INCLUDE ${config.sops.secrets.radiusClientSecret.path}
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

      eap {
        max_sessions = ''${max_requests}
        default_eap_type = mschapv2

        gtc {
          auth_type = PAP
        }

        mschapv2 { }

        tls-config tls-common {
          private_key_file = "${certDir}/key.pem"
          certificate_file = "${certDir}/cert.pem"

          cache {
            enable = no
            persist_dir = "/var/lib/radius"

            store {
              Tunnel-Private-Group-Id
            }
          }

          cipher_list = "DEFAULT"

          tls_min_version = "1.2"
          tls_max_version = "1.2"
        }

        tls {
          tls = tls-common
        }

        ttls {
          tls = tls-common
          default_eap_type = pap
          virtual_server = "inner-tunnel"

          use_tunneled_reply = yes
        }

        peap {
          tls = tls-common
          default_eap_type = mschapv2
          virtual_server = "inner-tunnel"

          use_tunneled_reply = yes
        }
      }
    }

    server default {
      listen {
        type = auth
        ipaddr = *
        port = ${toString port}
      }

      limits {
        max_connections = 16
        lifetime = 0
        idle_timeout = 30
      }

      authorize {
        filter_username

        chap
        mschap

        eap {
          ok = return
          updated = return
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

        eap
      }

      post-auth {
        update reply {
          User-Name !* ANY
          Message-Authenticator !* ANY
          EAP-Message !* ANY
          Proxy-State !* ANY
          MS-MPPE-Encryption-Types !* ANY
          MS-MPPE-Encryption-Policy !* ANY
          MS-MPPE-Send-Key !* ANY
          MS-MPPE-Recv-Key !* ANY
        }

        Post-Auth-Type REJECT {
          attr_filter.access_reject
        }
      }
    }

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

        eap {
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

        eap
      }

      post-auth {
        update reply {
          User-Name !* ANY
          Message-Authenticator !* ANY
          EAP-Message !* ANY
          Proxy-State !* ANY
          MS-MPPE-Encryption-Types !* ANY
          MS-MPPE-Encryption-Policy !* ANY
          MS-MPPE-Send-Key !* ANY
          MS-MPPE-Recv-Key !* ANY
        }

        Post-Auth-Type REJECT {
          attr_filter.access_reject

          update reply {
            Module-Failure-Message := &request:Module-Failure-Message
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
  environment.systemPackages = [
    (pkgs.wpa_supplicant.overrideAttrs (old: {
      name = "eapol_test-${old.version}";

      buildPhase = ''
        runHook preBuild
        echo CONFIG_EAPOL_TEST=y >> .config
        make eapol_test
        runHook postBuild
      '';

      installPhase = ''
        install -D eapol_test $out/bin/eapol_test
      '';

      NIX_CFLAGS_COMPILE = [ "-Wno-error" ];
    }))
  ];

  sops.secrets = {
    passwords = {
      sopsFile = "${self}/secrets/credentials.sops.yaml";

      mode = "0400";
      owner = "radius";
    };

    radiusClientSecret = {
      sopsFile = "${self}/secrets/credentials.sops.yaml";

      mode = "0400";
      owner = "radius";
    };

    cloudflareCredentials.sopsFile = "${self}/secrets/misc.sops.yaml";
  };

  users = {
    users.radius.group = "radius";
    groups.radius = { };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "infrastructure@nfits.de";

    certs."dhm-ctf.de" = {
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1";
      environmentFile = config.sops.secrets.cloudflareCredentials.path;

      group = "radius";
    };
  };

  services.freeradius = {
    enable = true;
    debug = false;

    inherit configDir;
  };

  networking.firewall.interfaces.wlan.allowedTCPPorts = [ port ];

  systemd.services.freeradius.serviceConfig.StateDirectory = [ "radius" ];
}
