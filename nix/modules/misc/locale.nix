{ lib, ... }:

with lib;
{
  config = mkDefault {
    console.keyMap = "de-latin1";

    i18n = {
      # Default to a locale with sane settings for start of week, formats, etc
      defaultLocale = "en_IE.UTF-8";

      extraLocaleSettings = {
        # Reference:
        # https://lh.2xlibre.net/locale/de_DE/
        # https://lh.2xlibre.net/locale/en_IE/
        # https://lh.2xlibre.net/locale/en_US/

        LC_CTYPE = "de_DE.UTF-8"; # Umlauts
        # LC_COLLATE same for IE and DE, stick to default
        # LC_TIME use english names and %d/%m/%y format
        # LC_NUMERIC stick to (.) as decimal point and (,) as thousands sep.
        # LC_MONETARY IE has more (and sane) definitions than DE
        # LC_PAPER IE and DE have A4
        # LC_MEASUREMENT IE and DE both have metric
        # LC_MESSAGES stick to english yes/no selections
        LC_NAME = "en_US.UTF-8"; # Include salutations
        LC_ADDRESS = "de_DE.UTF-8"; # German address format
        LC_TELEPHONE = "de_DE.UTF-8"; # German phone format and +49 prefix
      };
    };
  };
}
