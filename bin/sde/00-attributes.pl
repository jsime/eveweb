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

my ($res, $created, $updated);

###############
#### ATTRIBUTES

$res = $sde_db->do(q{
    select *
    from "chrAttributes"
});

die $res->error unless $res;

print "\nAttributes";
print "\n----------\n";

($created, $updated) = (0,0);
ATTRIBUTE:
while ($res->next) {
    printf("%10d -> %s\n", $res->{'attributeID'}, $res->{'attributeName'});

    my $update = $db->do(q{
        update ccp.attributes
        set ???
        where attribute_id = ?
    }, {
        name        => $res->{'attributeName'},
        description => $res->{'description'},
    }, $res->{'attributeID'});

    if ($update->count > 0) {
        $updated++;
        next ATTRIBUTE;
    } else {
        my $insert = $db->do(q{
            insert into ccp.attributes ???
        }, {
            attribute_id => $res->{'attributeID'},
            name         => $res->{'attributeName'},
            description  => $res->{'description'},
        });

        if ($insert->count > 0) {
            $created++;
            next ATTRIBUTE;
        }
    }

    die sprintf("Couldn't update or insert attribute %s (%d).\n", $res->{'attributeName'}, $res->{'attributeID'});
}

printf("Created: %d / Updated: %d\n", $created, $updated);
