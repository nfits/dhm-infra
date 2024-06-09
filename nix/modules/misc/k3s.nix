{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.k3s;

  rrDomain = "api.${config.networking.domain}";

  clusterNodeCidr = "10.248.2.0/24";

  podCIDR = "10.250.0.0/16";
  svcCIDR = "10.251.0.0/16";
  dnsIP = "10.251.0.10";
in
{
  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        nfs-utils # Required by longhorn
      ] ++ optionals (cfg.role == "server") [
        # Management
        k9s
        kubectl
      ];

      variables = mkIf (cfg.role == "server") {
        KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      };
    };

    networking.firewall = {
      checkReversePath = false;

      extraInputRules = ''
        ip saddr { ${clusterNodeCidr} } accept comment "Other cluster nodes"
        ip saddr { ${podCIDR}, ${svcCIDR} } accept comment "Kubernetes Pods / Services"
      '';

      allowedTCPPorts = [
        10250 # kubelet
      ] ++ optionals (cfg.role == "server") [
        6443 # API
        2379 # etcd clients
        2380 # etcd peers
      ];
    };

    services = {
      # NOTE: The update settings are quite extreme, but due to the nodes being in the same rack this is fine
      k3s.extraFlags = concatStringsSep " " ([
        "--flannel-backend=host-gw"
        "--node-name=${config.networking.hostName}"

        "--kubelet-arg=node-status-update-frequency=4s"
      ] ++ optionals (cfg.role == "server") [
        "--disable-helm-controller"
        "--disable local-storage"
        "--disable servicelb"

        "--kube-controller-manager-arg=node-monitor-period=2s"
        "--kube-controller-manager-arg=node-monitor-grace-period=16s"

        "--cluster-cidr=${podCIDR}"
        "--service-cidr=${svcCIDR}"
        "--cluster-dns=${dnsIP}"

        "--tls-san=${rrDomain}"
        "--tls-san=${config.networking.fqdn}"
      ]);

      openiscsi = {
        enable = true;
        name = "${config.networking.hostName}-initiatorhost";
      };
    };
  };
}
