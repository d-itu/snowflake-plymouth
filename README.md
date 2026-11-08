## Snowflake Plymouth

This repo contains a plymouth theme for NixOS that pulses the NixOS logo. Please check out the credits section for all the work that inspired this.

# Install & Configuration

Add the flake package to your NixOS configuration:

```nix
{
  inputs.snowflake-plymouth = {
    url = "github:d-itu/snowflake-plymouth";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, snowflake-plymouth, ... }: {
    nixosConfigurations."<hostname>" = nixpkgs.lib.nixosSystem {
      modules = [
        {
          boot.plymouth = {
            enable = true;
            theme = "snowflake-pulse";
            themePackages = [ snowflake-plymouth.packages.x86_64-linux.default ];
          };
        }
      ];
    };
  };
}
```

## Testing the changes

Once your host system has been configured:

1. Update your flake
2. Rebuild your system `using nixos-rebuild`
3. Run the following `sudo plymouthd ; sudo plymouth --show-splash ; sleep 10 ; sudo killall plymouthd`

## Credits

* Creating Glows in SVGs - www.youtube.com/watch?v=oe8RB4Y6Vi4
* NixOS-Boot - https://github.com/Melkor333/nixos-boot
