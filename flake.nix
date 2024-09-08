{
  description = "Ror2 server anywhere";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };

    inherit (pkgs) lib;
  in
  rec {
    nixosModules.${system}.default =
    { config, ... }:
    let
      cfg = config.services.ror2;
    in
    {
      options = {
        services.ror2 = {
    enable = lib.mkEnableOption "enable";
  };
      };
      
      config = lib.mkIf cfg.enable (lib.mkMerge [
        {
          environment.systemPackages = with pkgs; [ 
      wget 
      gnupg2
            xorg.xauth
            gettext
            winbind
            xvfb
            lib32gcc1
    ];
        }
      ]);
    };

    # test on vm
    # `nix run .#nixosConfigurations.test.config.system.build.vm`
    nixosConfigurations.test =
    nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        nixosModules.${system}.default 
        ({ pkgs, config, modulesPath, ... }: {
          imports = [
      # neccessary for vm
            (modulesPath + "/profiles/qemu-guest.nix")
          ];

          environment.systemPackages = [ ];

          services.getty.autologinUser = "root";

          users.users.root.password = lib.mkForce "zalupa";
          users.users.root.hashedPassword = lib.mkForce null;
          users.users.root.hashedPasswordFile = lib.mkForce null;
          users.users.root.initialPassword = lib.mkForce null;
          users.users.root.passwordFile = lib.mkForce null;

          virtualisation.vmVariant = {
            virtualisation = {
              memorySize = 2056;
        forwardPorts = [
                { from = "host"; host.port = 40500; guest.port = 22; }
                { from = "host"; host.port = 27015; guest.port = 27015; }
                { from = "host"; host.port = 27016; guest.port = 27016; }
              ];
      };
          };

          users.users.root.openssh.authorizedKeys.keys = [
            ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMezFt0OjCXCEjuOch03oTGXxgON+O9YShrU0hC0dJfb''
          ];

          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = true;

            };
          };

          programs.bash.shellAliases = { };

          system.stateVersion = "24.05";
        })
      ];
      pkgs = import nixpkgs {
        inherit system;
      };
    };

    #packages.${system} = {
    #   
    #}
  };
}
