{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    direnv
    docker_29
    git
    neovim
    openssh
  ];
  virtualisation.docker.enable = true;
}
