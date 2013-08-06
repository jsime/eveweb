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


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $res = $c->model('DB')->do(q{
        select j.job_id, j.job_type, j.job_key, j.stash, j.run_host, j.run_pid,
            to_char(j.run_at      at time zone ?, ?) as run_at,
            to_char(j.started_at  at time zone ?, ?) as started_at,
            to_char(j.finished_at at time zone ?, ?) as finished_at,
            to_char(j.created_at  at time zone ?, ?) as created_at
        from public.jobs j
        order by j.run_at desc limit 50;
    }, ($c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}) x 4);

    if ($res) {
        $c->stash->{'jobs'} = [];

        while ($res->next) {
            push(@{$c->stash->{'jobs'}}, { map { $_ => $res->{$_} } $res->columns });
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
