{ config, lib, pkgs, self, ... }:

with lib;
{
  sops.secrets.clusterToken = {
    sopsFile = "${self}/secrets/cluster.sops.yaml";
    restartUnits = [ "k3s.service" ];
  };

  services = {
    k3s = {
      enable = true;
      role = "server";
      tokenFile = config.sops.secrets.clusterToken.path;
      clusterInit = true;
    };
  };
}
