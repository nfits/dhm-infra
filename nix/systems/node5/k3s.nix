{ config, lib, ... }:

with lib;
{
  services = {
    # NOTE: Manual changes in k8s:
    #   - Tainted with node-role.kubernetes.io/control-plane:NoSchedule
    #   - Removed label node.longhorn.io/create-default-disk=true
    k3s = {
      # Override the default from node1
      clusterInit = mkForce false;
      serverAddr = "https://api.${config.networking.domain}:6443";
    };
  };
}
