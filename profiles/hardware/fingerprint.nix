{
  services.fprintd.enable = true;

# https://github.com/NixOS/nixpkgs/issues/517804
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("net.reactivated.fprint.") > -1) {
        return polkit.Result.YES;
      }
    });
  '';
}
