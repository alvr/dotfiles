{
  http.middlewares = {
    secure-headers.headers = {
      sslRedirect = true;
      stsSeconds = 31536000;
      stsIncludeSubdomains = true;
      stsPreload = true;
      forceSTSHeader = true;
      frameDeny = true;
      contentTypeNosniff = true;
      browserXssFilter = true;
    };
  };
}
