{ config, ... }:

{
  networking = {
    nat = {
      enable = true;
      externalInterface = "ens18";
      internalInterfaces = [ "wg0" ];
    };

    wireguard.interfaces.wg0 = {
      listenPort = 51820;

      ips = [ "10.247.0.1/24" ];

      privateKeyFile = "/var/lib/wireguard/server-private";

      peers = [
        # Patrick (NFITS)
        {
          publicKey = "cMigFoFfdnIOp1ZBVdJR8mhk819z1Sj1wsNQX8HiSQs=";
          allowedIPs = [ "10.247.0.2/32" ];
        }
        # Daniel (NFITS)
        {
          publicKey = "EeVgH86U0pnjWwgKQJ5kzroddj+jtZUsuCH/kL2k0jw=";
          allowedIPs = [ "10.247.0.3/32" ];
        }
        # Alain (NFITS)
        {
          publicKey = "nEngiH/1RsQZp3ms5zoWhfwYnxsrdxw7B7Wd/ElLuQU=";
          allowedIPs = [ "10.247.0.4/32" ];
        }
        # Felipe (NFITS)
        {
          publicKey = "e/2cazrNY8kdVlGW9qBvne6jLIsi4OUCCGIIMO4EXEQ=";
          allowedIPs = [ "10.247.0.5/32" ];
        }
        # Thomas (NFITS)
        {
          publicKey = "YRJDowQbkOnlcG/8kIo1/zHiMz9JX98fkr//aimVWAY=";
          allowedIPs = [ "10.247.0.6/32" ];
        }
        # Kolja (NFITS)
        {
          publicKey = "sDka5SCnnxNxE95U/qMIqD2UZc0bqqRr8xL8o3tT4Gg=";
          allowedIPs = [ "10.247.0.7/32" ];
        }
      ];
    };

    firewall.allowedUDPPorts = [ config.networking.wireguard.interfaces.wg0.listenPort ];
  };
}
