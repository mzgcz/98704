#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Mojo::JSON;
use Mojo::Parameters;
require LWP::UserAgent;

binmode(STDOUT, ':encoding(utf8)');

my $query_date = $ARGV[0] || "2014-01-01";
my $from_station = $ARGV[1] || "NJH";
my $to_station = $ARGV[2] || "NCG";
my $echo_type = $ARGV[3] || 1;

my $ua = LWP::UserAgent->new();
$ua->ssl_opts( verify_hostname => 0 );
$ua->timeout(60);
$ua->env_proxy;

my $query_base_url = "https://kyfw.12306.cn/otn/lcxxcx/query";
my $query_params = Mojo::Parameters->new(
                                         'purpose_codes' => 'ADULT',
                                         'queryDate' => $query_date,
                                         'from_station' => $from_station,
                                         'to_station' => $to_station
                                        );
my $query_url = $query_base_url."?".$query_params;

if ($echo_type == 1) {
  printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n",
    "车次", "出发", "抵达", "软卧", "硬卧", "硬座";
} elsif ($echo_type == 2) {
  printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\n",
    "车次", "出发", "抵达", "一等", "二等";
} else {
  printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n",
    "车次", "出发", "抵达", "软卧", "硬卧", "软座", "硬座", "一等", "二等";
}

my $response = $ua->get($query_url);
if ($response->is_success) {
  my $json = Mojo::JSON->new;
  my $request_json = $json->decode($response->decoded_content);
  my $datas = $request_json->{"data"}->{"datas"};
  foreach my $data (@$datas) {
    if ($data->{"canWebBuy"} eq "Y") {
      my $train_code = $data->{"station_train_code"}; # 车次
      my $start_time = $data->{"start_time"};         # 出发
      my $arrive_time = $data->{"arrive_time"};       # 抵达
      my $rw_num = $data->{"rw_num"};                 # 软卧
      my $yw_num = $data->{"yw_num"};                 # 硬卧
      my $gr_num = $data->{"gr_num"};                 # 高软
      my $rz_num = $data->{"rz_num"};                 # 软座
      my $yz_num = $data->{"yz_num"};                 # 硬座
      my $swz_num = $data->{"swz_num"};               # 商务
      my $tz_num = $data->{"tz_num"};                 # 特等
      my $zy_num = $data->{"zy_num"};                 # 一等
      my $ze_num = $data->{"ze_num"};                 # 二等
      my $wz_num = $data->{"wz_num"};                 # 无座

      if ($echo_type == 1) {
        printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n",
          $train_code, $start_time, $arrive_time, $rw_num, $yw_num, $yz_num;
      } elsif ($echo_type == 2) {
        printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\n",
          $train_code, $start_time, $arrive_time, $zy_num, $ze_num;
      } else {
        printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n",
          $train_code, $start_time, $arrive_time, $rw_num, $yw_num, $rz_num, $yz_num, $zy_num, $ze_num;
      }
    }
  }
}
