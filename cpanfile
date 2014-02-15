requires 'perl', '5.008001';
requires 'Amon2';
requires 'Net::CIDR::Lite';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Plack::Test';
    requires 'HTTP::Request::Common';
};

