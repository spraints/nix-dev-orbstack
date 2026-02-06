{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    curl
    openssh
    git
    direnv
    docker_29
  ];
}
