package EVEWeb::Job;

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::SetOnce;
use namespace::autoclean;

use DateTime;
use JSON;
use Sys::Hostname;

has 'job_id' => (
    is        => 'rw',
    isa       => 'Num',
    traits    => [qw( SetOnce )],
    predicate => 'has_job_id',
);

has 'type' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'key' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_key',
);

has 'db' => (
    is       => 'ro',
    isa      => 'DBIx::DataStore',
    required => 1,
);

has 'stash' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'run_at' => (
    is      => 'rw',
    isa     => 'DateTime',
    default => sub { DateTime->now },
);

has 'started' => (
    is  => 'rw',
    isa => 'DateTime',
);

has 'finished' => (
    is  => 'rw',
    isa => 'DateTime',
);

has 'host' => (
    is  => 'ro',
    isa => 'Str',
);

has 'pid' => (
    is  => 'ro',
    isa => 'Int',
);

=head1 CLASS METHODS

=cut

sub claim {
    my ($class, $db, $type) = @_;

    my $host = hostname;
    my $pid = $$;

    $db->begin;

    my $res = $db->do(q{
        select *
        from public.jobs
        where job_type = ?
            and run_at <= now()
            and started_at is null
        for update
    }, $type);

    unless ($res && $res->next) {
        $db->rollback;
        return;
    }

    my $job = EVEWeb::Job->new(
        db     => $db,
        job_id => $res->{'job_id'},
        type   => $res->{'job_type'},
        key    => $res->{'job_key'},
        stash  => from_json($res->{'stash'}, { utf8 => 1 }),
    );

    $res = $db->do(q{
        update public.jobs
        set ???
        where job_id = ?
    }, {
        run_host   => $host,
        run_pid    => $pid,
        started_at => 'now',
    }, $job->job_id);

    unless ($res) {
        $db->rollback;
        return;
    }

    $db->commit;

    return $job;
}

=head1 METHODS

=cut

sub start {
    my ($self) = @_;

    die sprintf('Job %d has already finished. It cannot be started again.', $self->job_id)
        if $self->finished;

    $self->started(DateTime->now());
}

sub finish {
    my ($self) = @_;

    die sprintf('Job %d has not yet been started. It cannot be finished yet.', $self->job_id)
        if !$self->started;
    die sprintf('Job %d has already finished. It cannot be finished a second time.', $self->job_id)
        if $self->finished;

    $self->finished(DateTime->now());
}

sub save {
    my ($self) = @_;

    my ($res);

    if (!$self->has_job_id) {
        $self->key($self->make_key) unless $self->has_key;

        $res = $self->db->do(q{
            select job_id
            from public.jobs
            where job_key = ?
                and (started_at is null or finished_at is null)
        }, $self->key);

        # do not save a new job if there is already an unfinished one of the same key
        return if $res && $res->next;

        die "Must specify a time at which to run this job before it can be saved."
            unless $self->run_at;

        $res = $self->db->do(q{
            insert into public.jobs ??? returning job_id
        }, {
            job_type => $self->type,
            job_key  => $self->key,
            stash    => to_json($self->stash, { utf8 => 1, pretty => 0 }),
            run_at   => $self->run_at . '+0000',
        });

        return unless $res && $res->next;

        $self->job_id($res->{'job_id'});
        return 1;
    } else {
        $res = $self->db->do(q{
            update public.jobs
            set ???
            where job_id = ? and finished_at is null
            returning job_id
        }, {
            stash       => to_json($self->stash, { utf8 => 1, pretty => 0 }),
            run_host    => $self->host,
            run_pid     => $self->pid,
            started_at  => $self->started,
            finished_at => $self->finished,
        }, $self->job_id);

        return unless $res && $res->next;
        return 1;
    }
}

=head1 INTERNAL METHODS

=cut

sub make_key {
    my ($self) = @_;

    return sprintf('%s-%d', $self->type, $self->stash->{$self->type . '_id'})
        if $self->type && exists $self->stash->{$self->type . '_id'};

    die "Could not generate a sufficient job key.";
}

__PACKAGE__->meta->make_immutable;

1;
