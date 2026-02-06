# Based on https://gist.github.com/hicksca/7bc67e44e40e62b314e5a8f9b88f3bd8
# ssh nix-dev@orb

require "json"
require "shellwords"

VM_NAME = "nix-dev"
NIX_RELEASE = "25.11"
ARCH = "arm64"

def main
  really = ARGV.delete("--doit") || ARGV.delete("--force") || ARGV.delete("-f")
  noop = !really
  recreate = ARGV.delete("--recreate")
  if recreate && exists?
    r "orbctl", "delete", "-f", VM_NAME,
      noop: noop
  end

  # Create the VM
  r "orbctl", "create", "-a", ARCH, "nixos:#{NIX_RELEASE}", VM_NAME,
    noop: noop, continue: true

  r "orbctl", "run", "-m", VM_NAME, "cp",
    "/etc/nixos/configuration.nix",
    "./configuration.nix",
    noop: noop

  add_my_config("./configuration.nix", noop: noop)

  r "orbctl", "run", "-m", VM_NAME, "sudo", "cp",
    "./configuration.nix",
    "/etc/nixos/configuration.nix",
    noop: noop

  r "orbctl", "run", "-m", VM_NAME, "sudo", "cp",
    "./spraints.nix",
    "/etc/nixos/spraints.nix",
    noop: noop

  r "orbctl", "run", "-m", VM_NAME, "sudo", "nixos-rebuild", "switch",
    noop: noop

  r "rm", "./configuration.nix", noop: noop

  r "orbctl", "run", "-m", VM_NAME, "cp",
    "./profile", "/mnt/linux/home/spraints/.profile",
    noop: noop

  r "orbctl", "run", "-m", VM_NAME, "mkdir", "-p",
    "/mnt/linux/home/spraints/.config/direnv/lib",
    noop: noop

  # This comes from https://raw.githubusercontent.com/nix-community/nix-direnv/refs/tags/3.1.0/direnvrc
  r "orbctl", "run", "-m", VM_NAME, "cp",
    "./nix-direnv.sh",
    "/mnt/linux/home/spraints/.config/direnv/lib/nix-direnv.sh",
    noop: noop

  if noop
    puts "*** pass --doit to actually create a vm"
  end
end

def add_my_config(nixcfg, noop:)
  if noop
    puts "(noop) add spraints.nix to nixos configuration"
    return
  end

  orig = nixcfg + ".orig"
  r "cp", nixcfg, orig, noop: noop

  cfg = File.read(nixcfg).lines

  if cfg.none? { |l| l =~ /spraints.nix/ }
    i = cfg.index { |l| l =~ /orbstack/ }
    raise "orbstack import not found in config!" if i.nil?
    cfg.insert i+1, "      ./spraints.nix\n"
  end

  i = cfg.index { |l| l =~ /extraGroups/ }
  cfg[i] = %Q{    extraGroups = [ "wheel" "orbstack" "docker" ];\n}

  File.write(nixcfg, cfg.join)

  r "diff", "-u", orig, nixcfg, noop: noop, continue: true
  r "rm", orig, noop: noop
end

def exists?
  machines = j("orbctl", "list", "-f", "json")
  machines.any? { |m| m.fetch("name") == VM_NAME }
end

def r(*cmd, noop:, continue: false)
  cmd = cmd.flatten
  if noop
    puts "(noop) #{Shellwords.join(cmd)}"
    return
  end
  puts "+ #{Shellwords.join(cmd)}"
  ok = system(*cmd)
  exit(1) unless ok || continue
  ok
end

def j(*cmd)
  JSON.parse(`#{Shellwords.join(cmd)}`)
end

main
