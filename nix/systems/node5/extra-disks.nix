_:

{
  fileSystems = {
    # Drive for k3s (config, certs, pod ephemeral storage)
    "/var/lib/storage" = {
      device = "/dev/disk/by-label/Data";
      fsType = "ext4";
    };
  };
}
