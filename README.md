## Snowflake Plymouth

This repo contains a plymouth theme for NixOS that pulses the NixOS logo. Please check out the credits section for all the work that inspired this.

> [!WARNING]
> Using this repo for some reason bloats the `initrd` quite a bit (up to 50 MB). Use it with [boot.loader.systemd-boot.configurationLimit](https://search.nixos.org/options?channel=23.05&show=boot.loader.systemd-boot.configurationLimit&from=0&size=50&sort=relevance&type=packages&query=systemd-boot) or a `/boot` of at least a gigabyte.
> On EFI Systems it's also possible to keep the initrd on the main partition when switching to Grub. Checkout the [nixos wiki](https://wiki.nixos.org/wiki/Bootloader#Keeping_kernels/initrd_on_the_main_partition).

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
            theme = "snowflake";
            themePackages = [ snowflake-plymouth.packages.x86_64-linux.default ];
          };
        }
      ];
    };
  };
}
```

## Building The Theme

Run `nix build` on x86_64-linux. The committed `flake.lock` pins nixpkgs, including
Chromium, Playwright and Inkscape. The build renders 180 PNG animation frames at
30 FPS from `resources/nixos-logo-animated.svg` and converts the icon SVGs in
`resources/` to PNGs. The installed theme is in `result/share/plymouth/themes/snowflake/`;
Edit the SVGs or `src/snowflake.plymouth` to change the
theme and rebuild with `nix build`.

## Testing the changes

Once your host system has been configured:

1. Update your flake
2. Rebuild your system `using nixos-rebuild`
3. Run the following `sudo plymouthd ; sudo plymouth --show-splash ; sleep 10 ; sudo killall plymouthd`

## Credits

* Creating Glows in SVGs - www.youtube.com/watch?v=oe8RB4Y6Vi4
* NixOS-Boot - https://github.com/Melkor333/nixos-boot
