{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim
    curl
    openssh
    git
    direnv
    docker_29
  ];
  virtualisation.docker.enable = true;
}
