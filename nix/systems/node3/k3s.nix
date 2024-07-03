{ config, lib, ... }:

with lib;
{
  services = {
    k3s = {
      # Override the default from node1
      clusterInit = mkForce false;
      serverAddr = "https://api.${config.networking.domain}:6443";
    };
  };
}
