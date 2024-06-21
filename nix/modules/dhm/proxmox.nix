{ config, lib, ... }:

with lib;
let
  cfg = config.dhm;
in
{
  options.dhm = {
    isProxmoxVM = mkOption {
      type = types.bool;
      default = false;
      description = "Whether or not the node is a proxmox vm. Applies common defaults if true";
    };
  };

  config = mkIf cfg.isProxmoxVM {
    boot = {
      initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
      kernelModules = [ "kvm-intel" ];

      # We are on UEFI
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/Root";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
        options = [ "fmask=0022" "dmask=0022" ];
      };
    };

    networking.useDHCP = mkDefault true;
    nixpkgs.hostPlatform = mkDefault "x86_64-linux";

    # All proxmox vms are qemu guests
    services.qemuGuest.enable = mkDefault true;
  };
}
