#!/usr/bin/env perl

use v5.10;
use strict;
use warnings FATAL => 'all';

use Config::Any;
use Data::Dumper;
use DBIx::DataStore ( config => 'yaml' );
use File::Basename;

my ($SCRIPT, $BASEDIR) = fileparse(__FILE__);

my $cfg = Config::Any->load_files({
    files => ["$BASEDIR/../../eveweb.conf"],
    use_ext => 1,
    flatten_to_hash => 1,
});
$cfg = $cfg->{(keys %{$cfg})[0]};

my $sde_db = DBIx::DataStore->new($cfg->{'SDE'}{'datastore'});
my $db = DBIx::DataStore->new($cfg->{'Model::DB'}{'datastore'});

my ($res);

#################
#### SKILL GROUPS

$res = $sde_db->do(q{
    select *
    from "invGroups"
    where "categoryID" = 16
});

die $res->error unless $res;

###########
#### SKILLS
$res = $sde_db->do(q{
    select "typeID", "groupID", "typeName", "basePrice",
        "portionSize", published, "marketGroupID"
    from "invTypes"
    where "groupID" IN (select "groupID" from "invGroups" where "categoryID" = 16)
});

die $res->error unless $res;

while ($res->next) {
    printf("%10d -> %s\n", $res->{'typeID'}, $res->{'typeName'})
}
