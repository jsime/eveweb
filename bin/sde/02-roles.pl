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

##########
#### ROLES

my @roles = (
    { mask => 1,                 name => 'Director' },
    { mask => 128,               name => 'Personnel Manager' },
    { mask => 256,               name => 'Accountant' },
    { mask => 512,               name => 'Security Officer' },
    { mask => 1024,              name => 'Factory Manager' },
    { mask => 2048,              name => 'Station Manager' },
    { mask => 4096,              name => 'Auditor' },
    { mask => 8192,              name => 'Hangar Can Take Division 1' },
    { mask => 16384,             name => 'Hangar Can Take Division 2' },
    { mask => 32768,             name => 'Hangar Can Take Division 3' },
    { mask => 65536,             name => 'Hangar Can Take Division 4' },
    { mask => 131072,            name => 'Hangar Can Take Division 5' },
    { mask => 262144,            name => 'Hangar Can Take Division 6' },
    { mask => 524288,            name => 'Hangar Can Take Division 7' },
    { mask => 1048576,           name => 'Hangar Can Query Division 1' },
    { mask => 2097152,           name => 'Hangar Can Query Division 2' },
    { mask => 4194304,           name => 'Hangar Can Query Division 3' },
    { mask => 8388608,           name => 'Hangar Can Query Division 4' },
    { mask => 16777216,          name => 'Hangar Can Query Division 5' },
    { mask => 33554432,          name => 'Hangar Can Query Division 6' },
    { mask => 67108864,          name => 'Hangar Can Query Division 7' },
    { mask => 134217728,         name => 'Account Can Take Division 1' },
    { mask => 268435456,         name => 'Account Can Take Division 2' },
    { mask => 536870912,         name => 'Account Can Take Division 3' },
    { mask => 1073741824,        name => 'Account Can Take Division 4' },
    { mask => 2147483648,        name => 'Account Can Take Division 5' },
    { mask => 4294967296,        name => 'Account Can Take Division 6' },
    { mask => 8589934592,        name => 'Account Can Take Division 7' },
    { mask => 17179869184,       name => 'Account Can Query Division 1' },
    { mask => 34359738368,       name => 'Account Can Query Division 2' },
    { mask => 68719476736,       name => 'Account Can Query Division 3' },
    { mask => 137438953472,      name => 'Account Can Query Division 4' },
    { mask => 274877906944,      name => 'Account Can Query Division 5' },
    { mask => 549755813888,      name => 'Account Can Query Division 6' },
    { mask => 1099511627776,     name => 'Account Can Query Division 7' },
    { mask => 2199023255552,     name => 'Equipment Config' },
    { mask => 4398046511104,     name => 'ContainerCan Take Division 1' },
    { mask => 8796093022208,     name => 'ContainerCan Take Division 2' },
    { mask => 17592186044416,    name => 'ContainerCan Take Division 3' },
    { mask => 35184372088832,    name => 'ContainerCan Take Division 4' },
    { mask => 70368744177664,    name => 'ContainerCan Take Division 5' },
    { mask => 140737488355328,   name => 'ContainerCan Take Division 6' },
    { mask => 281474976710656,   name => 'ContainerCan Take Division 7' },
    { mask => 562949953421312,   name => 'Can Rent Office' },
    { mask => 1125899906842624,  name => 'Can Rent FactorySlot' },
    { mask => 2251799813685248,  name => 'Can Rent ResearchSlot' },
    { mask => 4503599627370496,  name => 'Junior Accountant' },
    { mask => 9007199254740992,  name => 'Starbase Config' },
    { mask => 18014398509481984, name => 'Trader' },
);

print "\nCorporation Roles";
print "\n-----------------\n";

($created, $updated) = (0,0);
ROLE:
foreach my $role (@roles) {
    printf("%-20s -> %s\n", $role->{'mask'}, $role->{'name'});

    my $update = $db->do(q{
        update ccp.corporation_roles
        set ???
        where role_mask = ?
    }, {
        role_name => $role->{'name'},
    }, $role->{'mask'});

    if ($update->count > 0) {
        $updated++;
        next ROLE;
    } else {
        my $insert = $db->do(q{
            insert into ccp.corporation_roles ???
        }, {
            role_mask => $role->{'mask'},
            role_name => $role->{'name'},
        });

        if ($insert->count > 0) {
            $created++;
            next ROLE;
        }
    }

    die sprintf("Couldn't update or insert role %s (%s).\n", $role->{'name'}, $role->{'mask'});
}

printf("Created: %d / Updated: %d\n", $created, $updated);
