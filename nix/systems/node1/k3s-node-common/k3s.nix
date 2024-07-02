{ config, self, ... }:

{
  sops.secrets.clusterToken = {
    sopsFile = "${self}/secrets/cluster.sops.yaml";
    restartUnits = [ "k3s.service" ];
  };

  # We have a separate data drives
  fileSystems = {
    "/var/lib/storage" = {
      device = "/dev/disk/by-label/Data";
      fsType = "ext4";
    };
  };

  services = {
    k3s = {
      enable = true;
      role = "server";
      tokenFile = config.sops.secrets.clusterToken.path;
      clusterInit = true;
    };
  };

  systemd.services = {
    crio.serviceConfig.StateDirectory = [ "storage/containers:containers" ];

    k3s.serviceConfig.StateDirectory = [
      "storage/kubelet:kubelet"
      "storage/rancher:rancher"
      "storage/longhorn:longhorn"
    ];
  };
}
