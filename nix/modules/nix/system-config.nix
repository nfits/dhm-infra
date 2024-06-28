{ self, config, ... }:

{
  system.configurationRevision =
    self.shortRev or self.dirtyShortRev or self.lastModified or "unknown";

  system.extraSystemBuilderCmds = ''
    echo ${config.system.configurationRevision} > $out/config-version
    ln -s ${self} $out/config
  '';
}
