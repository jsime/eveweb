use strict;
use warnings;

use Plack::Builder;
use EVEWeb;

builder {
    enable "Plack::Middleware::ReverseProxy";
    EVEWeb->psgi_app;
};

