#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Proxy;
use HTTP::Proxy::BodyFilter::simple;
use Imager;
use LWP::Simple qw($ua get);
$ua->agent('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:18.0) Gecko/20100101 Firefox/18.0');

my($type, $port) = @ARGV;
$type ||= "cats";
$port ||= 8080;

my %PLACE_HOLDERS = (
  cats   => 'http://placekitten.com/WIDTH/HEIGHT',
  dogs   => 'http://placedog.com/WIDTH/HEIGHT',
  apes   => 'http://placeape.com/WIDTH/HEIGHT',
  random => 'http://pipsum.com/WIDTHxHEIGHT',
  puppy  => 'http://placepuppy.it/WIDTH/HEIGHT',
  sheen  => 'http://placesheen.com/WIDTH/HEIGHT',
);
$PLACE_HOLDERS{$type} || die "I don't know how to replace that: $type";

# Create proxy
my $proxy  = HTTP::Proxy->new(in => { port => $port });
my $filter = HTTP::Proxy::BodyFilter::simple->new(\&tamper_image);
$proxy->push_filter(mime => 'image/*', response => $filter);
$proxy->max_clients(500);
$proxy->max_keep_alive_requests(40);
$proxy->start;
 
# Modify images
sub tamper_image {
  my ( $self, $dataref, $message, $protocol, $buffer ) = @_; 

  eval {
    # Get original image data
    my $img = Imager->new(data => $$dataref);
    my ($w, $h) = ($img->getwidth(), $img->getheight());

    # Construct url
    my $url = $PLACE_HOLDERS{$type};
    $url =~ s#WIDTH#$w#;
    $url =~ s#HEIGHT#$h#;

    # Get image
    $$dataref = get($url);
  };
  if ($@) {
    $$dataref = '';
  }
}
