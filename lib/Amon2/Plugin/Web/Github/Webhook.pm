package Amon2::Plugin::Web::Github::Webhook;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";
use JSON ();
use Amon2::Util ();
use Net::CIDR::Lite;

sub init {
    shift;
    my $c      = shift;
    my $config = shift || +{};

    my $access = $config->{access} || '192.30.252.0/22';
    my @ip     = ref $access ? @$access : ($access);
    my $github_addr = Net::CIDR::Lite->new;
    $github_addr->add_any($_) for @ip;

    my $decoder = JSON->new->utf8(1);
    Amon2::Util::add_method($c, 'github', sub {
        my $c = shift;

        my $req = $c->req;

        return unless $github_addr->find($req->address);

        return unless my $event   = $req->env->{HTTP_X_GITHUB_EVENT};
        return unless my $payload = $req->body_parameters_raw->{payload};
        return unless my $hash    = eval { $decoder->decode($payload) };

        my $delivery = $req->env->{HTTP_X_GITHUB_DELIVERY} || '';

        return { event => $event, delivery => $delivery, payload => $hash };
    });
}


1;
__END__

=encoding utf-8

=for stopwords webhook webhooks

=head1 NAME

Amon2::Plugin::Web::Github::Webhook - Github Webhook!

=head1 SYNOPSIS

    use Amon2::Lite;

    __PACKAGE__->load_plugin(
        'Web::Github::Webhook', { allow => '192.30.252.0/22' }
    );

    post '/hook' => sub {
        my $c = shift;
        return $c->res_403 unless my $github = $c->github;

        # $github = {
        #     evnet    => 'push',
        #     delivery => '19967914-9615-11e3-85b5-...',
        #     payload  => {
        #         after => '6fbadfc1ac7b6a7d32bca086ac95d049e0d8b03c',
        #         before => '4f9585dd9fbd86f20c21e3521e4de48a504f58b0',
        #         commits => [ {...} ],
        #         ...,
        #         pusher => ...,
        #         ref => 'refs/heads/master',
        #         repository => {...},
        #     },
        # };

        if ($github->{event} eq 'push') {
            my $payload = $github->{payload};
            my $ref = $payload->{ref};
            ...
        }
        return $c->create_simple_status_page(200 => "OK");
    };

    __PACKAGE__->to_app;

=head1 DESCRIPTION

Amon2::Plugin::Web::Github::Webhook helps you write github webhook
application.

=head2 CONFIGURATION

You can initialize this plugin with access restrictions:

    Your::App->load_plugin(
        "Web::Github::Webhook", { access => '192.30.252.0/22' }
    );

Default: C<192.30.252.0/22>.

You may check the github notification IP addresses for webhooks by:

    curl -i https://api.github.com/meta

=head2 METHOD

This plugin adds C<< $c->github >> method to your application.
If the request is a github notification,
then it returns a hash containing 'event', 'delivery' and 'payload' as in
SYNOPSIS; otherwise returns false.

Here 'the request is a github notification' means that:

    * the request ip address is in the configured ip range.
    * the request has a request header X-GITHUB-EVENT.
    * the request has the body parameter 'payload', and it is a json string.

=head1 SEE ALSO

L<Plack::App::GitHub::WebHook>

L<http://developer.github.com/webhooks/>

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

