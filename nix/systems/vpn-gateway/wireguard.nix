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
        # Tobias (FluxFingers, External Author)
        {
          publicKey = "Ui3RMybcJmUpEZajzWcBdNpENn8JQA++HyDmXozsO3g=";
          allowedIPs = [ "10.247.0.8/32" ];
        }
        # Felix (FluxFingers, External Author)
        {
          publicKey = "uBV+CiQZuMLuIZFIAJOo5i3+4QD7IMvVR8k5AlOun10=";
          allowedIPs = [ "10.247.0.9/32" ];
        }
        # Gina (RedRocket)
        {
          publicKey = "OHjPkg4WVc2WImE2+IbAZsLNzJxwhsD4enmDl6TXDm4=";
          allowedIPs = [ "10.247.0.10/32" ];
        }
        # Tobias (NFITS)
        {
          publicKey = "V+v8EEbHtOeTUFFWY3jVJuJ0GdhsTJFgG1oSDpwZYCk=";
          allowedIPs = [ "10.247.0.11/32" ];
        }
        # Jan-Niklas (RedRocket)
        {
          publicKey = "gK6Mum9zSzaeTUjX9t9f1ojN0jpNzJ+6a2BoHDnLc14=";
          allowedIPs = [ "10.247.0.12/32" ];
        }
        # Lukas (lukas2511) (RedRocket)
        {
          publicKey = "gWW2yaWsgxRwvYilcylS5H2vVOPrRjnUGYgIdpcrPFI=";
          allowedIPs = [ "10.247.0.13/32" ];
        }
        # Lukas (RedRocket)
        {
          publicKey = "zvI/8qN7vzthPk936N3arn2NDB1NuGgTI1Kft6mS70w=";
          allowedIPs = [ "10.247.0.14/32" ];
        }
        # Apfelsaft (Betatester (Tobi (NFITS)))
        {
          publicKey = "QAwrFCZdwGg61OnGlVeK/oLZkUvlWglpSm4k3jR0e0A=";
          allowedIPs = [ "10.247.0.15/32" ];
        }
        # Ruben (RedRocket)
        {
          publicKey = "5Vbd/lkhyKwh6QWavAQ1R142fiL8PMJvLoHUa15p/Dk=";
          allowedIPs = [ "10.247.0.16/32" ];
        }
      ];
    };

    firewall.allowedUDPPorts = [ config.networking.wireguard.interfaces.wg0.listenPort ];
  };
}
