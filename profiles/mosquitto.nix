{
  ...
}: {
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        users."valetudo".hashedPassword = "$7$1000\$TQYu02875xeztmM9CR2DA14r/Td87F+yzCeDmfg2bFT/WuGPGUYHpvm01Mv7++j6TVbhfbY5bIQUrOYYPefJfg==\$JSi81W7V3zw7giixXIsykfCs6lfiXaAX4+gLhrWHElLZjLOm8HSWPLJde8E98Zq297zNhONSLIFMqtrxScULaw==";
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 1883 ];
}
