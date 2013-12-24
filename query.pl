#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Mojo::JSON;
require LWP::UserAgent;

binmode(STDOUT, ':encoding(utf8)');

my $query_date = "2013-12-27";
my $from_station = "NJH";
my $to_station = "NCG";

if (@ARGV > 0) {
  $query_date = $ARGV[0];
}

if (@ARGV > 1) {
  $from_station = $ARGV[1];
}

if (@ARGV > 2) {
  $to_station = $ARGV[2];
}

my $ua = LWP::UserAgent->new();
$ua->ssl_opts( verify_hostname => 0 );
$ua->timeout(60);
$ua->env_proxy;

my $base_url = "https://kyfw.12306.cn/otn/lcxxcx/query?purpose_codes=ADULT";
my $request_url = $base_url."&queryDate=".$query_date."&from_station=".$from_station."&to_station=".$to_station;

printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n", "车次", "出发", "抵达", "软卧", "硬卧", "硬座";

my $response = $ua->get($request_url);
if ($response->is_success) {
  my $json = Mojo::JSON->new;
  my $request_json = $json->decode($response->decoded_content);
  my $datas = $request_json->{"data"}->{"datas"};
  foreach my $data (@$datas) {
    if ($data->{"canWebBuy"} eq "Y") {
      my $train_code = $data->{"station_train_code"}; # 车次
      my $start_time = $data->{"start_time"};         # 出发时间
      my $arrive_time = $data->{"arrive_time"};       # 抵达时间
      my $rw_num = $data->{"rw_num"};                 # 软卧
      my $yw_num = $data->{"yw_num"};                 # 硬卧
      my $gr_num = $data->{"gr_num"};                 # 高级软卧
      my $rz_num = $data->{"rz_num"};                 # 软座
      my $yz_num = $data->{"yz_num"};                 # 硬座
      my $swz_num = $data->{"swz_num"};               # 商务座
      my $tz_num = $data->{"tz_num"};                 # 特等座
      my $zy_num = $data->{"zy_num"};                 # 一等座
      my $ze_num = $data->{"ze_num"};                 # 二等座
      my $wz_num = $data->{"wz_num"};                 # 无座
      printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n", $train_code, $start_time, $arrive_time, $rw_num, $yw_num, $yz_num;
    }
  }
}
