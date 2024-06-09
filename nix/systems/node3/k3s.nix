{ config, lib, pkgs, self, systemConfigs, ... }:

with lib;
{
  sops.secrets.clusterToken = {
    sopsFile = "${self}/secrets/cluster.sops.yaml";
    restartUnits = [ "k3s.service" ];
  };

  services = {
    k3s = {
      enable = false;
      role = "server";
      tokenFile = config.sops.secrets.clusterToken.path;
      serverAddr = "https://${systemConfigs.node1.networking.fqdn}:6443";
    };
  };
}
