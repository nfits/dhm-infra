{ pkgs, ... }:
{
  environment.etc."cdi/nfits.json".source = (pkgs.formats.json { }).generate "nfits-cdi.json" {
    cdiVersion = "0.5.0";
    containerEdits = {
      deviceNodes = [ ];
      hooks = [ ];
      mounts = [ ];
    };
    devices = [
      {
        containerEdits = {
          deviceNodes = [ { path = "/dev/kvm"; } ];
          hooks = [ ];
        };
        name = "kvm";
      }
    ];
    kind = "nfits.de/devices";
  };
}
