{
  config,
  lib,
  pkgs,
  self,
  systemConfigs,
  ...
}:

with lib;
{
  services = {
    k3s = {
      # Override the default from node1
      clusterInit = mkForce false;
      serverAddr = "https://${systemConfigs.node1.networking.fqdn}:6443";
    };
  };
}
