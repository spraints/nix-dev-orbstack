{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    direnv
    docker_29
    fd
    git
    neovim
    openssh
    ripgrep
    xxd
  ];
  virtualisation.docker.enable = true;
}
