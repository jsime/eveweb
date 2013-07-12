begin;

-- SCHEMA: public
-- General account, authorization, configuration data

create table public.users (
    user_id      serial not null primary key,
    email        text not null,
    username     text not null,
    password     text not null,
    verify_token text not null,
    verified     boolean not null default false,
    created_at   timestamp with time zone not null default now(),
    updated_at   timestamp with time zone,
    deleted_at   timestamp with time zone
);

create unique index users_lower_email_idx on public.users (lower(email));
create unique index users_lower_username_idx on public.users (lower(username));
create index users_verified_idx on public.users (verified);
create index users_created_at_idx on public.users (created_at);
create index users_updated_at_idx on public.users (updated_at);
create index users_deleted_at_idx on public.users (deleted_at);

create table public.password_resets (
    user_id     integer not null,
    reset_token text not null,
    sent_at     timestamp with time zone not null default now(),
    viewed_at   timestamp with time zone,
    reset_at    timestamp with time zone,
    valid_until timestamp with time zone
);

alter table public.password_resets add primary key (user_id, reset_token);
create index password_resets_reset_token_idx on public.password_resets (reset_token);
create index password_resets_sent_at_idx on public.password_resets (sent_at);
create index password_resets_viewed_at_idx on public.password_resets (viewed_at);
create index password_resets_reset_at_idx on public.password_resets (reset_at);
create index password_resets_valid_until_idx on public.password_resets (valid_until);

create table public.roles (
    role_id serial not null primary key,
    role_name text not null
);

create unique index roles_lower_role_name_idx on public.roles (lower(role_name));

create table public.user_roles (
    user_id     integer not null,
    role_id     integer not null,
    granted_by  integer,
    created_at  timestamp with time zone not null default now()
);

alter table public.user_roles add primary key (user_id, role_id);

create index user_roles_role_id_idx on public.user_roles (role_id);
create index user_roles_granted_by_idx on public.user_roles (granted_by);
create index user_roles_created_at_idx on public.user_roles (created_at);

alter table public.user_roles add foreign key (user_id) references public.users (user_id) on update cascade on delete cascade;
alter table public.user_roles add foreign key (role_id) references public.roles (role_id) on update cascade on delete cascade;
alter table public.user_roles add foreign key (granted_by) references public.users (user_id) on update cascade on delete set null;

create table public.sessions (
    session_id   serial not null primary key,
    user_id      integer not null,
    session_key  text not null,
    session_data text not null,
    started_at   timestamp with time zone not null default now(),
    ended_at     timestamp with time zone,
    last_used    timestamp with time zone
);

create index sessions_user_id_idx on public.sessions (user_id);
create unique index sessions_session_key_idx on public.sessions (session_key);
create index sessions_started_at_idx on public.sessions (started_at);
create index sessions_ended_at_idx on public.sessions (ended_at);
create index sessions_last_used_idx on public.sessions (last_used);

alter table public.sessions add foreign key (user_id) references public.users (user_id) on update cascade on delete cascade;

-- SCHEMA: ccp
-- Static data imported from CCP's EVE data exports
create schema ccp;

create table ccp.attributes (
    attribute_id    integer not null primary key,
    name            text not null,
    description     text
);

create index attributes_icon_id_idx on ccp.attributes (icon_id);
create index attributes_name_idx on ccp.attributes (name);

create table ccp.skills (
    skill_id                integer not null primary key,
    name                    text not null,
    description             text not null,
    rank                    integer not null,
    primary_attribute_id    integer not null,
    secondary_attribute_id  integer not null
);

create unique index skills_name_idx on ccp.skills (name);
create index skills_primary_attribute_id_idx on ccp.skills (primary_attribute_id);
create index skills_secondary_attribute_id_idx on ccp.skills (secondary_attribute_id);

alter table ccp.skills add foreign key (primary_attribute_id) references ccp.attributes (attribute_id);
alter table ccp.skills add foreign key (secondary_attribute_id) references ccp.attributes (attribute_id);

create table ccp.skill_requirements (
    skill_id            integer not null,
    required_skill_id   integer not null,
    required_level      integer not null
);

alter table ccp.skill_requirements add primary key (skill_id, required_skill_id);
create index skill_requirements_required_skill_id_idx on ccp.skill_requirements (required_skill_id);

alter table ccp.skill_requirements add foreign key (skill_id) references ccp.skills (skill_id) on update cascade on delete cascade;
alter table ccp.skill_requirements add foreign key (required_skill_id) references ccp.skills (skill_id) on update cascade on delete cascade;

-- SCHEMA: eve
-- Contains data collected through the EVE API provided by CCP
create schema eve;

create table eve.api_keys (
    user_id     integer not null,
    key_id      integer not null,
    v_code      text not null,
    key_type    text not null,
    access_mask integer,
    active      boolean not null default 'f',
    verified    boolean not null default 'f',
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone
);

alter table eve.api_keys add primary key (user_id, key_id, v_code);
create index api_keys_key_id_v_code_idx on eve.api_keys (key_id, v_code);
create index api_keys_key_type_idx on eve.api_keys (key_type);
create index api_keys_active_idx on eve.api_keys (active);
create index api_keys_verified_idx on eve.api_keys (verified);
create index api_keys_created_at_idx on eve.api_keys (created_at);
create index api_keys_updated_at_idx on eve.api_keys (updated_at);

alter table eve.api_keys add foreign key (user_id) references public.users (user_id) on update cascade on delete cascade;

alter table eve.api_keys add constraint valid_key_types check (key_type in ('account','character','corporation'));
alter table eve.api_keys add constraint verified_access_mask check (verified is false or access_mask is not null);

create table eve.pilots (
    pilot_id    integer not null primary key,
    user_id     integer,
    name        text not null,
    race        text not null,
    bloodline   text not null,
    ancestry    text not null,
    gender      text not null,
    birthdate   timestamp with time zone not null,
    sec_status  numeric(6,4) not null
);

create index pilots_user_id_idx on eve.pilots (user_id);
create unique index pilots_name_idx on eve.pilots (name);

alter table eve.pilots add foreign key (user_id) references public.users (user_id) on update cascade;

create table eve.pilot_skills (
    pilot_id        integer not null,
    skill_id        integer not null,
    level           integer not null,
    skill_points    integer not null
);

alter table eve.pilot_skills add primary key (pilot_id, skill_id);
create index pilot_skills_skill_id_idx on eve.pilot_skills (skill_id);
create index pilot_skills_level_idx on eve.pilot_skills (level);

alter table eve.pilot_skills add foreign key (pilot_id) references eve.pilots (pilot_id) on update cascade on delete cascade;
alter table eve.pilot_skills add foreign key (skill_id) references ccp.skills (skill_id) on update cascade on delete cascade;

alter table eve.pilot_skills add constraint valid_skill_level check (level between 0 and 5);

-- SCHEMA: plans
-- Skill queue/plan management
create schema plans;


-- SCHEMA: fits
-- Ship fittings
create schema fits;


-- Wonders will never cease if we got here and the transaction hasn't already failed.
commit;
