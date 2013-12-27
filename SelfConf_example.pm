package SelfConf;
use parent qw(Exporter);

use strict;

our @EXPORT = qw(TRAIN_CODE DATE FROM TO FROM_NAME TO_NAME USERNAME PASSWORD PASSENGER TICKET);
our $VERSION = 1.00;

use constant TRAIN_CODE => "G1234";
use constant DATE => "2014-01-02";
use constant FROM => "NJH";
use constant TO => "NCG";
use constant FROM_NAME => "南京";
use constant TO_NAME => "南昌";
use constant USERNAME => 'somebody@secret.com';
use constant PASSWORD => 'secretpassword';
use constant PASSENGER => "杜某某,1,杜某某身份证号,1_蒋某某,1,蒋某某身份证号,1_";
use constant TICKET => "4,0,1,杜某某,1,杜某某身份证号,杜某某电话,N_4,0,1,蒋某某,1,蒋某某身份证号,蒋某某电话,N";

1;

__END__
