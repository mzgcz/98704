package Self98704;
use parent qw(Exporter);

use strict;
use SelfURL;
use Mojo::JSON;
use POSIX qw(strftime);

our @EXPORT = qw(login query login_order order order_check order_info order_queue confirm);
our $VERSION = 0.10;

sub login_check {
  my $ua = shift;

  my $url = compose_url(
                        "https://kyfw.12306.cn/otn/passcodeNew/getPassCodeNew",
                        ['module' => 'login',
                         'rand' => 'sjrand']
                       );
  my $response = $ua->get($url);
  if ($response->is_success) {
    open my $img, "> check.png" or die "$!";
    binmode($img);
    print $img $response->content;
    close $img;
    return 1;
  }

  return 0;
}

sub login {
  my ($ua, $username, $password) = @_;

  my $check_str;
  until (login_check($ua)) {
    sleep 1;
  }

  while (1) {
    print "输入验证码[登录]：";
    chomp($check_str = <>);
    $check_str =~ s/\s//g;
    if ($check_str eq "r") {
      until (login_check($ua)) {
        sleep 1;
      }
    } else {
      last;
    }
  }

  my $response = $ua->post(
                           'https://kyfw.12306.cn/otn/login/loginAysnSuggest',
                           ['loginUserDTO.user_name' => $username,
                            'UserDTO.password' => $password,
                            randCode => $check_str]
                          );
  if ($response->is_success) {
    my $json = Mojo::JSON->new;
    my $response_json = $json->decode($response->decoded_content);
    my $login_check = $response_json->{"data"}->{"loginCheck"};
    if ($login_check && ($login_check eq "Y")) {
      return 1;
    }
  }

  return 0;
}

sub query {
  my ($ua, $date, $from, $to, $code) = @_;

  my $secret_str;
  my $url = compose_url(
                        "https://kyfw.12306.cn/otn/leftTicket/query",
                        ['leftTicketDTO.train_date' => $date,
                         'leftTicketDTO.from_station' => $from,
                         'leftTicketDTO.to_station' => $to,
                         'purpose_codes' => 'ADULT']
                       );
  my $response = $ua->get($url);
  if ($response->is_success) {
    my $json = Mojo::JSON->new;
    my $response_json = $json->decode($response->decoded_content);
    my $datas = $response_json->{"data"};
    foreach my $data (@$datas) {
      if ($data->{"queryLeftNewDTO"}->{"station_train_code"} eq $code) {
        $secret_str = $data->{"secretStr"};
      }
    }
  }

  return $secret_str;
}

sub login_order {
  my ($ua, $date, $from, $to, $secret) = @_;

  my $url = compose_url(
                        "https://kyfw.12306.cn/otn/leftTicket/submitOrderRequest",
                        ['back_train_date' => strftime("%F", localtime()),
                         'purpose_codes' => 'ADULT',
                         'query_from_station_name' => $from,
                         'query_to_station_name' => $to,
                         'secretStr' => $secret,
                         'tour_flag' => 'dc',
                         'train_date' => $date,
                         'undefined' => ''],
                        "^A-Za-z0-9\-\._~%"
                       );
  my $response = $ua->post($url);
  if ($response->is_success) {
    my $json = Mojo::JSON->new;
    my $response_json = $json->decode($response->decoded_content);
    if ($response_json->{"status"}) {
      return 1;
    }
  }

  return 0;
}

sub order {
  my $ua = shift;

  my ($repeat_submit_token, $key_check_ischange, $left_ticket_str,
      $purpose_codes, $train_location, $from_station_telecode,
      $station_traincode, $to_station_telecode, $train_date, $train_no);

  my $url = compose_url(
                        "https://kyfw.12306.cn/otn/confirmPassenger/initDc",
                        ['_json_att' => '']
                       );
  my $response = $ua->post($url);
  if ($response->is_success) {
    open my $fh, "<", \($response->content);
    while (<$fh>) {
      if (/var\s+globalRepeatSubmitToken.*'(.*)'/) {
        $repeat_submit_token = $1;
      } elsif (/var\s+ticketInfoForPassengerForm.*?({.*})/) {
        my $string = $1;
        $string =~ s/\'/\"/g;

        my $json = Mojo::JSON->new;
        my $response_json = $json->decode($string);
        $key_check_ischange = $response_json->{"key_check_isChange"};
        $left_ticket_str = $response_json->{"leftTicketStr"};
        $purpose_codes = $response_json->{"purpose_codes"};
        $train_location = $response_json->{"train_location"};
        $from_station_telecode = $response_json->{"orderRequestDTO"}->{"from_station_telecode"};
        $station_traincode = $response_json->{"orderRequestDTO"}->{"station_train_code"};
        $to_station_telecode = $response_json->{"orderRequestDTO"}->{"to_station_telecode"};
        $train_date = $response_json->{"orderRequestDTO"}->{"train_date"}->{"time"}/1000;
        $train_no = $response_json->{"orderRequestDTO"}->{"train_no"};
      }
    }
    close $fh;
  }

  return ($repeat_submit_token, $key_check_ischange, $left_ticket_str,
          $purpose_codes, $train_location, $from_station_telecode,
          $station_traincode, $to_station_telecode, $train_date, $train_no);
}

sub order_check {
  my $ua = shift;

  my $url = compose_url(
                        "https://kyfw.12306.cn/otn/passcodeNew/getPassCodeNew",
                        ['module' => 'passenger',
                         'rand' => 'randp']
                       );
  my $response = $ua->get($url);
  if ($response->is_success) {
    open my $img, "> check.png" or die "$!";
    binmode($img);
    print $img $response->content;
    close $img;
    return 1;
  }

  return 0;
}

sub order_info {
  my ($ua, $token, $check_str, $passenger, $ticket) = @_;

  my $url = compose_url(
                        "https://kyfw.12306.cn/otn/confirmPassenger/checkOrderInfo",
                        ['REPEAT_SUBMIT_TOKEN' => $token,
                         '_json_att' => '',
                         'bed_level_order_num' => '000000000000000000000000000000',
                         'cancel_flag' => 2,
                         'randCode' => $check_str,
                         'tour_flag' => 'dc',
                         'oldPassengerStr' => $passenger,
                         'passengerTicketStr' => $ticket]
                       );
  my $response = $ua->post($url);
  if ($response->is_success) {
    my $json = Mojo::JSON->new;
    my $response_json = $json->decode($response->decoded_content);
    if ($response_json->{"status"}) {
      return 1;
    }
  }

  return 0;
}

sub order_queue {
  my ($ua, $token, $from_telecode,
      $left_ticket_str, $purpose_codes,
      $seat_type, $station_traincode,
      $to_telecode, $train_no, $train_date) = @_;

  my $url = compose_url(
                        "https://kyfw.12306.cn/otn/confirmPassenger/getQueueCount",
                        ['REPEAT_SUBMIT_TOKEN' => $token,
                         '_json_att' => '',
                         'fromStationTelecode' => $from_telecode,
                         'leftTicket' => $left_ticket_str,
                         'purpose_codes' => $purpose_codes,
                         'seatType' => $seat_type,
                         'stationTrainCode' => $station_traincode,
                         'toStationTelecode' => $to_telecode,
                         'train_no' => $train_no,
                         'train_data' => strftime("%a %b %d %Y %T GMT+0800 (CST)", localtime($train_date))],
                        "^A-Za-z0-9\-\._~()"
                       );
  $ua->post($url);
}

sub confirm {
  my ($ua, $token, $key_check_ischange,
      $left_ticket_str, $passenger, $ticket,
      $purpose_codes, $check_str, $train_location) = @_;

  my $url = compose_url(
                        "https://kyfw.12306.cn/otn/confirmPassenger/confirmSingleForQueue",
                        ['REPEAT_SUBMIT_TOKEN' => $token,
                         '_json_att' => '',
                         'key_check_isChange' => $key_check_ischange,
                         'leftTicketStr' => $left_ticket_str,
                         'oldPassengerStr' => $passenger,
                         'passengerTicketStr' => $ticket,
                         'purpose_codes' => $purpose_codes,
                         'randCode' => $check_str,
                         'train_location' => $train_location]
                       );
  my $response = $ua->post($url);
  if ($response->is_success) {
    my $json = Mojo::JSON->new;
    my $response_json = $json->decode($response->decoded_content);
    if ($response_json->{"data"}
        && $response_json->{"data"}->{"submitStatus"}) {
      print "购票成功，到网站进行支付.\n";
    } else {
      print "出错啦，重新尝试.\n";
    }
  }
}

1;

__END__
