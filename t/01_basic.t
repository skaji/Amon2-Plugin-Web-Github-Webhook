use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use JSON;
use Plack::Test;
use Test::More;

{
    package MyApp;
    use parent qw/Amon2/;
}
{
    package MyApp::Web1;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    __PACKAGE__->load_plugin('Web::Github::Webhook', { access => '0.0.0.0/0'});
    sub dispatch { MyApp::Web::Dispather->dispatch(shift) }
}
{
    package MyApp::Web2;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    __PACKAGE__->load_plugin('Web::Github::Webhook', { access => '203.0.113.0'});
    sub dispatch { MyApp::Web::Dispather->dispatch(shift) }
}
{
    package MyApp::Web::Dispather;
    use Amon2::Web::Dispatcher::RouterBoom;
    post "/event" => sub {
        my $c = shift;
        my $github = $c->github || +{};
        my $res = $c->create_response(200);
        $res->content_type('text/plain');
        $res->body($github->{event} || "");
        $res;
    };
    post "/delivery" => sub {
        my $c = shift;
        my $github = $c->github || +{};
        my $res = $c->create_response(200);
        $res->content_type('text/plain');
        $res->body($github->{delivery} || "");
        $res;
    };
    post "/payload-ref" => sub {
        my $c = shift;
        my $github  = $c->github || +{};
        my $payload = $github->{payload} || +{};
        my $res = $c->create_response(200);
        $res->content_type('text/plain');
        $res->body($payload->{ref} || "");
        $res;
    };
}

my $app1 = MyApp::Web1->to_app;
my $app2 = MyApp::Web2->to_app;

my @post_data = (
    [ payload => encode_json({ref => "master", after => "あいうえお"}) ],
    'x-github-event' => 'push',
    'x-github-delivery' => 'xyz',
);

test_psgi $app1, sub {
    my $cb  = shift;
    my $res;
    $res = $cb->( POST "/event", @post_data );
    is $res->content, "push";
    $res = $cb->( POST "/delivery", @post_data );
    is $res->content, "xyz";
    $res = $cb->( POST "/payload-ref", @post_data );
    is $res->content, "master";
};
test_psgi $app2, sub {
    my $cb  = shift;
    my $res;
    $res = $cb->( POST "/event", @post_data );
    is $res->content, "";
    $res = $cb->( POST "/delivery", @post_data );
    is $res->content, "";
    $res = $cb->( POST "/payload-ref", @post_data );
    is $res->content, "";
};


done_testing;

