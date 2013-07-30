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

#################
#### SKILL GROUPS

$res = $sde_db->do(q{
    select *
    from "invGroups"
    where "categoryID" = 16
});

die $res->error unless $res;

print "\nSkill Groups";
print "\n------------\n";

($created, $updated) = (0,0);
GROUP:
while ($res->next) {
    printf("%10d -> %s\n        ", $res->{'groupID'}, $res->{'groupName'});

    my $update = $db->do(q{
        update ccp.skill_groups
        set ???
        where skill_group_id = ?
    }, {
        name      => $res->{'groupName'},
        published => ($res->{'published'} ? 1 : 0)
    }, $res->{'groupID'});

    if ($update->count > 0) {
        $updated++;
        next GROUP;
    } else {
        my $insert = $db->do(q{
            insert into ccp.skill_groups ???
        }, {
            skill_group_id => $res->{'groupID'},
            name           => $res->{'groupName'},
            published      => ($res->{'published'} ? 1 : 0)
        });

        if ($insert->count > 0) {
            $created++;
            next GROUP;
        }
    }

    die sprintf("Couldn't update or insert skill group %s (%d).\n", $res->{'groupName'}, $res->{'groupID'});
}

printf("Created: %d / Updated: %d\n", $created, $updated);

###########
#### SKILLS
$res = $sde_db->do(q{
    select *
    from "invTypes"
    where "groupID" IN (select "groupID" from "invGroups" where "categoryID" = 16)
});

die $res->error unless $res;

print "\nSkills";
print "\n------\n";

($created, $updated) = (0,0);
SKILL:
while ($res->next) {
    printf("%10d -> %s (Group %d)\n", $res->{'typeID'}, $res->{'typeName'}, $res->{'groupID'});

    my $update = $db->do(q{
        update ccp.skills
        set ???
        where skill_id = ?
    }, {
        skill_group_id => $res->{'groupID'},
        name           => $res->{'typeName'},
        description    => $res->{'description'},
        rank           => 1, # TODO get the real rank
        primary_attribute_id   => 1, # TODO
        secondary_attribute_id => 1, # TODO
        published      => ($res->{'published'} ? 1 : 0)
    }, $res->{'typeID'});

    if ($update->count > 0) {
        $updated++;
        next SKILL;
    } else {
        my $insert = $db->do(q{
            insert into ccp.skills ???
        }, {
            skill_id       => $res->{'typeID'},
            skill_group_id => $res->{'groupID'},
            name           => $res->{'typeName'},
            description    => $res->{'description'},
            rank           => 1, # TODO get the real rank
            primary_attribute_id   => 1, # TODO
            secondary_attribute_id => 1, # TODO
            published      => ($res->{'published'} ? 1 : 0)
        });

        if ($insert->count > 0) {
            $created++;
            next SKILL;
        }
    }

    die sprintf("Couldn't update or insert skill %s (%d).\n", $res->{'typeName'}, $res->{'typeID'});
}

printf("Created: %d / Updated: %d\n", $created, $updated);

