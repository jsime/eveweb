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

####################
#### TYPE CATEGORIES

$res = $sde_db->do(q{
    select *
    from "invCategories"
});

die $res->error unless $res;

print "\nType Categories";
print "\n---------------\n";

($created, $updated) = (0,0);
CATEGORY:
while ($res->next) {
    printf("%10d -> %s\n        ", $res->{'categoryID'}, $res->{'categoryName'});

    my $update = $db->do(q{
        update ccp.type_categories
        set ???
        where type_category_id = ?
    }, {
        name        => $res->{'categoryName'},
        description => $res->{'description'},
        published   => ($res->{'published'} ? 1 : 0)
    }, $res->{'categoryID'});

    if ($update->count > 0) {
        $updated++;
        next CATEGORY;
    } else {
        my $insert = $db->do(q{
            insert into ccp.type_categories ???
        }, {
            type_category_id => $res->{'categoryID'},
            name             => $res->{'categoryName'},
            description      => $res->{'description'},
            published        => ($res->{'published'} ? 1 : 0)
        });

        if ($insert->count > 0) {
            $created++;
            next CATEGORY;
        }
    }

    die sprintf("Couldn't update or insert type category %s (%d).\n", $res->{'categoryName'}, $res->{'categoryID'});
}

printf("Created: %d / Updated: %d\n", $created, $updated);

################
#### TYPE GROUPS

$res = $sde_db->do(q{
    select *
    from "invGroups"
});

die $res->error unless $res;

print "\nType Groups";
print "\n-----------\n";

($created, $updated) = (0,0);
GROUP:
while ($res->next) {
    printf("%10d -> %s\n        ", $res->{'groupID'}, $res->{'groupName'});

    my $update = $db->do(q{
        update ccp.type_groups
        set ???
        where type_group_id = ?
    }, {
        name             => $res->{'groupName'},
        description      => $res->{'description'},
        type_category_id => $res->{'categoryID'},
        published        => ($res->{'published'} ? 1 : 0)
    }, $res->{'groupID'});

    if ($update->count > 0) {
        $updated++;
        next GROUP;
    } else {
        my $insert = $db->do(q{
            insert into ccp.type_groups ???
        }, {
            type_group_id    => $res->{'groupID'},
            type_category_id => $res->{'categoryID'},
            name             => $res->{'groupName'},
            description      => $res->{'description'},
            published        => ($res->{'published'} ? 1 : 0)
        });

        if ($insert->count > 0) {
            $created++;
            next GROUP;
        }
    }

    die sprintf("Couldn't update or insert type group %s (%d).\n", $res->{'groupName'}, $res->{'groupID'});
}

printf("Created: %d / Updated: %d\n", $created, $updated);

##########
#### TYPES

$res = $sde_db->do(q{
    select *
    from "invTypes"
});

die $res->error unless $res;

print "\nTypes";
print "\n-----\n";

($created, $updated) = (0,0);
TYPE:
while ($res->next) {
    printf("%10d -> %s\n        ", $res->{'typeID'}, $res->{'typeName'});

    my $update = $db->do(q{
        update ccp.types
        set ???
        where type_id = ?
    }, {
        name          => $res->{'typeName'},
        description   => $res->{'description'},
        type_group_id => $res->{'groupID'},
        published     => ($res->{'published'} ? 1 : 0)
    }, $res->{'typeID'});

    if ($update->count > 0) {
        $updated++;
        next TYPE;
    } else {
        my $insert = $db->do(q{
            insert into ccp.types ???
        }, {
            type_id       => $res->{'typeID'},
            type_group_id => $res->{'groupID'},
            name          => $res->{'typeName'},
            description   => $res->{'description'},
            published     => ($res->{'published'} ? 1 : 0)
        });

        if ($insert->count > 0) {
            $created++;
            next TYPE;
        }
    }

    die sprintf("Couldn't update or insert type %s (%d).\n", $res->{'typeName'}, $res->{'typeID'});
}

printf("Created: %d / Updated: %d\n", $created, $updated);
