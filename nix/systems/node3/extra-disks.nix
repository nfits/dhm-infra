_:

{
  fileSystems = {
    # Drive for k3s (config, certs, pod ephemeral storage)
    "/var/lib/storage" = {
      device = "/dev/disk/by-label/Data";
      fsType = "ext4";
    };

    # External etcd drive
    "/var/lib/storage/rancher/k3s/server/db" = {
      device = "/dev/disk/by-label/etcd";
      fsType = "ext4";
    };

    # Longhorn
    "/var/lib/storage/longhorn" = {
      device = "/dev/disk/by-label/longhorn";
      fsType = "ext4";
    };
  };
}
