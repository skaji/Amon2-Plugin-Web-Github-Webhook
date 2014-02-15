# NAME

Amon2::Plugin::Web::Github::Webhook - Github Webhook!

# SYNOPSIS

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

# DESCRIPTION

Amon2::Plugin::Web::Github::Webhook helps you write github webhook
application.

## CONFIGURATION

You can initialize this plugin with access restrictions:

    Your::App->load_plugin(
        "Web::Github::Webhook", { access => '192.30.252.0/22' }
    );

Default: `192.30.252.0/22`.

You may check the github notification IP addresses for webhooks by:

    curl -i https://api.github.com/meta

## METHOD

This plugin adds `$c->github` method to your application.
If the request is a github notification,
then it returns a hash containing 'event', 'delivery' and 'payload' as in
SYNOPSIS; otherwise returns false.

Here 'the request is a github notification' means that:

    * the request ip address is in the configured ip range.
    * the request has a request header X-GITHUB-EVENT.
    * the request has the body parameter 'payload', and it is a json string.

# SEE ALSO

[Plack::App::GitHub::WebHook](https://metacpan.org/pod/Plack::App::GitHub::WebHook)

[http://developer.github.com/webhooks/](http://developer.github.com/webhooks/)

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
