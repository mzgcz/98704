package SelfURL;
use parent qw(Exporter);

use strict;
use URI::Escape;

our @EXPORT = qw(compose_url);
our $VERSION = 0.10;

sub compose_url {
  my ($base_url, $parameters, $characters) = @_;

  unless ($characters) {
    $characters = "^A-Za-z0-9\-\._~";
  }
  my $url = $base_url."?";
  for (my $i=0; $i<@$parameters; ) {
    unless ($i == 0) {
      $url .= "&";
    }
    $url .= $parameters->[$i++]."=".uri_escape($parameters->[$i++], $characters);
  }

  return $url;
}

1;

__END__
