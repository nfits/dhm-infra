{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.k3s;

  rrDomain = "api.${config.networking.domain}";

  clusterNodeCidr = "10.248.2.0/24";

  lbSvcCIDR = "10.248.3.0/24";
  podCIDR = "10.250.0.0/16";
  svcCIDR = "10.251.0.0/16";
  dnsIP = "10.251.0.10";

  images = with pkgs.dockerTools; [
    (buildImage rec {
      name = "dhm-ctf.de/nixos-built/longhorn-manager";
      tag = "v1.6.2";

      fromImage = pullImage rec {
        imageName = "longhornio/longhorn-manager";
        imageDigest = "sha256:c849a1f1f9ff33a5412dff58235791b4bc909211d6723b1d27f5fbf35dea3fc6";
        sha256 = "1cfabr4ak5qpzy4spv08kjw03a17jvwxwvf86kn35iak26wapkxi";
        finalImageName = imageName;
        finalImageTag = tag;
      };

      config.Env = [
        "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/run/wrappers/bin:/run/current-system/sw/bin"
      ];
    })
    (buildImage rec {
      name = "dhm-ctf.de/nixos-built/longhorn-instance-manager";
      tag = "v1.6.2";

      fromImage = pullImage rec {
        imageName = "longhornio/longhorn-instance-manager";
        imageDigest = "sha256:957d6a84c83a4627d6b278bd0d36c2f9de26fdd351d2b95c39f3429302898302";
        sha256 = "0pif9xwz65iqzg6f2va39cp28af3rx0581nyhd8gyyqyi6h8131d";
        finalImageName = imageName;
        finalImageTag = tag;
      };

      config.Env = [
        "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/run/wrappers/bin:/run/current-system/sw/bin"
      ];
    })
  ];
in
{
  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        # Required by longhorn
        nfs-utils
        openiscsi
      ] ++ optionals (cfg.role == "server") [
        # Management
        (wrapHelm kubernetes-helm {
          plugins = with kubernetes-helmPlugins; [ helm-secrets ];
        })

        k9s
        kubectl
        kustomize
        kustomize-sops
        sops
      ];

      variables = mkIf (cfg.role == "server") {
        KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      };
    };

    networking.firewall = {
      checkReversePath = false;

      extraInputRules = ''
        ip saddr { ${clusterNodeCidr} } accept comment "Other cluster nodes"
        ip daddr { ${lbSvcCIDR}, ${podCIDR}, ${svcCIDR} } accept comment "Kubernetes Load-Balancer Services"
        ip saddr { ${podCIDR}, ${svcCIDR} } accept comment "Kubernetes Pods / Services"
      '';

      allowedTCPPorts = [
        10250 # kubelet
      ] ++ optionals (cfg.role == "server") [
        6443 # API
        5001 # distributed internal registry
        2379 # etcd clients
        2380 # etcd peers
      ];
    };

    services = {
      # NOTE: The update settings are quite extreme, but due to the nodes being in the same rack this is fine
      k3s.extraFlags = concatStringsSep " " ([
        "--flannel-backend=host-gw"
        "--node-name=${config.networking.hostName}"
        "--node-label=node.longhorn.io/create-default-disk=true"

        "--kubelet-arg=node-status-update-frequency=4s"
      ] ++ optionals (cfg.role == "server") [
        "--disable-helm-controller"
        "--disable local-storage"
        "--disable servicelb"

        "--embedded-registry"

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

    systemd.services.k3s-image-import = mkIf (cfg.role == "server" && cfg.clusterInit) {
      path = with pkgs; [ gzip k3s ];

      script = ''
        echo "Waiting for k3s to become available..."

        while ! k3s kubectl version &>/dev/null; do
          sleep 1
        done

        echo "k3s available."

        ${concatStringsSep "\n" (map
          (v: "zcat ${v} | ctr -n k8s.io image import -")
          images)}
      '';

      requires = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
