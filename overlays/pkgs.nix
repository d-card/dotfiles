{
  rakeLeaves,
  inputs,
  ...
}: final: prev:
if builtins.pathExists ../pkgs
then
  prev.lib.mapAttrsRecursive
  (_: path: (prev.callPackage path {inherit inputs;}))
  (rakeLeaves ../pkgs)
else {}
