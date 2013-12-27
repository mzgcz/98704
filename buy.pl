#!/usr/bin/env perl

use strict;
use warnings;
use SelfURL;
use SelfConf;
use Self98704;
use LWP::ConnCache;
use LWP::UserAgent;
use POSIX qw(strftime);

my $train_code = $ARGV[0] || TRAIN_CODE;
my $date = $ARGV[1] || DATE;
my $from = $ARGV[2] || FROM;
my $to = $ARGV[3] || TO;
my $from_name = FROM_NAME;
my $to_name = TO_NAME;
my $username = USERNAME;
my $password = PASSWORD;
my $passenger = PASSENGER;
my $ticket = TICKET;

my $ua = LWP::UserAgent->new();
$ua->ssl_opts(verify_hostname => 0);
$ua->cookie_jar({});
$ua->timeout(60);
$ua->env_proxy;
$ua->conn_cache(LWP::ConnCache->new());

my $no = 1;
until (login($ua, $username, $password)) {
  printf "用户登录失败，第%d次重试\n", $no++;
}

my $secret_str = query($ua, $date, $from, $to, $train_code);

$no = 1;
until (login_order($ua, $date, $from_name, $to_name, $secret_str)) {
  printf "订票登录失败，第%d次重试\n", $no++;
  sleep 1;
  $secret_str = query($ua, $date, $from, $to, $train_code);
}

$no = 1;
my ($repeat_submit_token, $key_check_isChange, $leftTicketStr,
    $purpose_codes, $train_location, $from_station_telecode,
    $station_traincode, $to_station_telecode, $train_date, $train_no) = order($ua);
until ($leftTicketStr) {
  printf "获取订票参数失败，第%d次重试\n", $no++;
  sleep 1;
  ($repeat_submit_token, $key_check_isChange, $leftTicketStr,
   $purpose_codes, $train_location, $from_station_telecode,
   $station_traincode, $to_station_telecode, $train_date, $train_no) = order($ua);
}

until (order_check($ua)) {
  sleep 1;
}

my $check_str;
while (1) {
  print "输入验证码[购票]：";
  chomp($check_str = <STDIN>);
  $check_str =~ s/\s//g;
  if ($check_str eq "r") {
    until (order_check($ua)) {
      sleep 1;
    }
  } else {
    last;
  }
}

order_info($ua, $repeat_submit_token, $check_str, $passenger, $ticket);

order_queue($ua, $repeat_submit_token, $from_station_telecode,
            $leftTicketStr, $purpose_codes, 4, $station_traincode,
            $to_station_telecode, $train_no, $train_date);

confirm($ua, $repeat_submit_token, $key_check_isChange,
        $leftTicketStr, $passenger, $ticket,
        $purpose_codes, $check_str, $train_location);
