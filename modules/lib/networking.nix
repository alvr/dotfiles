{
  config.flake.lib.mkIpv4 =
    defaultGateway: ipv4:
    if ipv4.address == null then
      { method = "auto"; }
    else
      {
        method = "manual";
        address1 =
          "${ipv4.address}/${toString ipv4.prefixLength},"
          + (if ipv4.gateway != null then ipv4.gateway else defaultGateway);
      };
}
