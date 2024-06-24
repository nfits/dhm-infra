{ pkgs, ... }:

{
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZPYF6pCjSFVkxJOMw1DuiFaXoDfa2lynxVu+/u5Qu2 daniel@nfits"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcN6c6/8qYVjxWi39CVju6ecKHZZcqYQhgHA+MR4Wg9 felipe@nfits"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALcss3gZalQ+NZej76HdmT01yfgnZUUg2ArydmL+ZQ0 patrick@nfits"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7W3NIGeEGRHu63+dP7s6M5/s0uHODI4QV2Y1yOzDEq lukas2511@redrocket"
    ];

    shell = pkgs.zsh;
  };
}
