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

my @skill_ids; # used later to limit dgmTypeAttributes query to just skills

($created, $updated) = (0,0);
SKILL:
while ($res->next) {
    printf("%10d -> %s (Group %d)\n", $res->{'typeID'}, $res->{'typeName'}, $res->{'groupID'});

    push(@skill_ids, $res->{'typeID'});

    my $update = $db->do(q{
        update ccp.skills
        set ???
        where skill_id = ?
    }, {
        skill_group_id => $res->{'groupID'},
        name           => $res->{'typeName'},
        description    => $res->{'description'} || '',
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
            description    => $res->{'description'} || '',
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

#######################
#### SKILL REQUIREMENTS

# Need to collect the appropriate required levels for each skill,
# depending on whether it is a primary/secondary/tertiary dependency.
$res = $sde_db->do(q{
    select "typeID" as skill_id,
        case
            when "attributeID" = 277 then 1
            when "attributeID" = 278 then 2
            when "attributeID" = 279 then 3
        end as tier,
        coalesce("valueInt","valueFloat") as required_level
    from "dgmTypeAttributes"
    where "attributeID" in (277,278,279)
        and "typeID" in ???
}, \@skill_ids);

die $res->error unless $res;

my %levels;

while ($res->next) {
    $levels{$res->{'skill_id'}} = [1,1,1,1] unless exists $levels{$res->{'skill_id'}};
    $levels{$res->{'skill_id'}}[$res->{'tier'}] = $res->{'required_level'};
}

# Now we get the skill tree itself
$res = $sde_db->do(q{
    select "typeID" as skill_id,
        case
            when "attributeID" = 182 then 1
            when "attributeID" = 183 then 2
            when "attributeID" = 184 then 3
        end as tier,
        coalesce("valueInt","valueFloat") as required_skill_id,
        1 as required_level
    from "dgmTypeAttributes"
    where "attributeID" in (182,183,184)
        and "typeID" in ???
}, \@skill_ids);

die $res->error unless $res;

print "\nSkills Requirements";
print "\n-------------------\n";

($created, $updated) = (0,0);
PREREQ:
while ($res->next) {
    # Grab the required level for this tier from earlier query
    $res->{'required_level'} = $levels{$res->{'skill_id'}}[$res->{'tier'}];

    printf("%8d -> %8d (Tier %d, Level: %d)\n",
        $res->{'skill_id'},
        $res->{'required_skill_id'},
        $res->{'tier'},
        $res->{'required_level'},
    );

    my $update = $db->do(q{
        update ccp.skill_requirements
        set ???
        where skill_id = ? and required_skill_id = ?
    }, {
        required_level => $res->{'required_level'},
        tier           => $res->{'tier'},
    }, $res->{'skill_id'}, $res->{'required_skill_id'});

    if ($update->count > 0) {
        $updated++;
        next PREREQ;
    } else {
        my $insert = $db->do(q{
            insert into ccp.skill_requirements ???
        }, {
            skill_id          => $res->{'skill_id'},
            required_skill_id => $res->{'required_skill_id'},
            required_level    => $res->{'required_level'},
            tier              => $res->{'tier'},
        });

        if ($insert->count > 0) {
            $created++;
            next PREREQ;
        }
    }

    die sprintf("Couldn't update or insert skill requirement of %d for %d.\n", $res->{'skill_id'}, $res->{'required_skill_id'});
}

printf("Created: %d / Updated: %d\n", $created, $updated);
