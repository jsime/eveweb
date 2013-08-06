package EVEWeb::Controller::Admin::Jobs;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Admin::Jobs - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub auto :Private {
    my ($self, $c) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Jobs', link => $c->uri_for('/admin/jobs') });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $json = JSON->new;

    my $res = $c->model('DB')->do(q{
        select j.job_id, j.job_type, j.job_key, j.stash, j.run_host, j.run_pid,
            to_char(j.run_at      at time zone ?, ?) as run_at,
            to_char(j.started_at  at time zone ?, ?) as started_at,
            to_char(j.finished_at at time zone ?, ?) as finished_at,
            to_char(j.created_at  at time zone ?, ?) as created_at
        from public.jobs j
        where j.started_at is not null
            and j.finished_at is null
        order by j.started_at asc
        limit 25
    }, ($c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}) x 4);

    if ($res) {
        $c->stash->{'current_jobs'} = [];

        while ($res->next) {
            push(@{$c->stash->{'current_jobs'}}, { map { $_ => $res->{$_} } $res->columns });

            $c->stash->{'current_jobs'}[-1]->{'stash'} =
                $json->pretty->encode($json->decode($c->stash->{'current_jobs'}[-1]->{'stash'}));
        }
    }
    
    $res = $c->model('DB')->do(q{
        select j.job_id, j.job_type, j.job_key, j.stash, j.run_host, j.run_pid,
            to_char(j.run_at      at time zone ?, ?) as run_at,
            to_char(j.started_at  at time zone ?, ?) as started_at,
            to_char(j.finished_at at time zone ?, ?) as finished_at,
            to_char(j.created_at  at time zone ?, ?) as created_at
        from public.jobs j
        where j.started_at is null
        order by j.run_at asc
        limit 10
    }, ($c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}) x 4);

    if ($res) {
        $c->stash->{'open_jobs'} = [];

        while ($res->next) {
            push(@{$c->stash->{'open_jobs'}}, { map { $_ => $res->{$_} } $res->columns });

            $c->stash->{'open_jobs'}[-1]->{'stash'} =
                $json->pretty->encode($json->decode($c->stash->{'open_jobs'}[-1]->{'stash'}));
        }
    }
    
    $res = $c->model('DB')->do(q{
        select j.job_id, j.job_type, j.job_key, j.stash, j.run_host, j.run_pid,
            to_char(j.run_at      at time zone ?, ?) as run_at,
            to_char(j.started_at  at time zone ?, ?) as started_at,
            to_char(j.finished_at at time zone ?, ?) as finished_at,
            to_char(j.created_at  at time zone ?, ?) as created_at
        from public.jobs j
        where j.finished_at is not null
        order by j.finished_at desc
        limit 10
    }, ($c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}) x 4);

    if ($res) {
        $c->stash->{'finished_jobs'} = [];

        while ($res->next) {
            push(@{$c->stash->{'finished_jobs'}}, { map { $_ => $res->{$_} } $res->columns });

            $c->stash->{'finished_jobs'}[-1]->{'stash'} =
                $json->pretty->encode($json->decode($c->stash->{'finished_jobs'}[-1]->{'stash'}));
        }
    }
    
    $c->stash->{'template'} = 'admin/jobs/index.tt2';
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
