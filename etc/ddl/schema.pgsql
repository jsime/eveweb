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

create table public.user_prefs (
    user_id    integer not null,
    pref_name  text not null,
    pref_value text,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone
);

alter table public.user_prefs add primary key (user_id, pref_name);
create index user_prefs_pref_name_idx on public.user_prefs (pref_name);

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
    role_id     serial not null primary key,
    role_name   text not null,
    description text
);

create unique index roles_lower_role_name_idx on public.roles (lower(role_name));

insert into public.roles (role_name, description) values
    ('superadmin','Super Admins are able to create administrators (and other super admins), but otherwise have no privileges.'),
    ('admin','Administrators may view all users, pilots, corporations and alliances. This role should be granted sparingly.'),
    ('moderator','Moderators are granted the ability to manage forums and comments, but only within their corporations.')
;

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

create table public.jobs (
    job_id      bigserial not null primary key,
    job_type    text not null,
    job_key     text not null,
    stash       json not null,
    run_host    text,
    run_pid     integer,
    run_at      timestamp with time zone not null,
    started_at  timestamp with time zone,
    finished_at timestamp with time zone,
    created_at  timestamp with time zone not null default now()
);

create index jobs_type_idx on public.jobs (type);
create index jobs_key_idx on public.jobs (key);
create index jobs_run_at_idx on public.jobs (run_at);
create index jobs_started_at_idx on public.jobs (started_at);
create index jobs_finished_at_idx on public.jobs (finished_at);
create index jobs_created_at_idx on public.jobs (created_at);

-- SCHEMA: ccp
-- Static data imported from CCP's EVE data exports
create schema ccp;

create table ccp.attributes (
    attribute_id    integer not null primary key,
    name            text not null,
    description     text
);

create index attributes_name_idx on ccp.attributes (name);

create table ccp.skill_level_points (
    level   integer not null primary key,
    points  integer not null
);

insert into ccp.skill_level_points values
    (1, 250),
    (2, 1415),
    (3, 8000),
    (4, 45255),
    (5, 256000)
;

create table ccp.skill_groups (
    skill_group_id  integer not null primary key,
    name            text not null,
    published       boolean not null default 't'
);

create unique index skill_groups_name_idx on ccp.skill_groups (name);
create index skill_groups_published_idx on ccp.skill_groups (published);

create table ccp.skills (
    skill_id                integer not null primary key,
    skill_group_id          integer not null,
    name                    text not null,
    description             text not null,
    rank                    integer not null,
    primary_attribute_id    integer not null,
    secondary_attribute_id  integer not null,
    published               boolean not null default 't'
);

create unique index skills_name_idx on ccp.skills (name);
create index skills_skill_group_id_idx on ccp.skills (skill_group_id);
create index skills_primary_attribute_id_idx on ccp.skills (primary_attribute_id);
create index skills_secondary_attribute_id_idx on ccp.skills (secondary_attribute_id);
create index skills_published_idx on ccp.skills (published);

alter table ccp.skills add foreign key (skill_group_id) references ccp.skill_groups (skill_group_id);
alter table ccp.skills add foreign key (primary_attribute_id) references ccp.attributes (attribute_id);
alter table ccp.skills add foreign key (secondary_attribute_id) references ccp.attributes (attribute_id);

create table ccp.skill_requirements (
    skill_id            integer not null,
    required_skill_id   integer not null,
    required_level      integer not null,
    tier                integer not null
);

alter table ccp.skill_requirements add primary key (skill_id, required_skill_id);
create index skill_requirements_required_skill_id_idx on ccp.skill_requirements (required_skill_id);

alter table ccp.skill_requirements add foreign key (skill_id) references ccp.skills (skill_id) on update cascade on delete cascade;
alter table ccp.skill_requirements add foreign key (required_skill_id) references ccp.skills (skill_id) on update cascade on delete cascade;

create view ccp.skill_tree as
    with recursive reqtree (skill_id, required_skill_id, required_level, tier, path, tier_path, cycle) as (
        select skill_id, required_skill_id, required_level, tier, ARRAY[skill_id], ARRAY[tier], false
        from skill_requirements
        union all
        select sr.skill_id, sr.required_skill_id, sr.required_level, sr.tier,
            path || sr.required_skill_id, tier_path || sr.tier,
            ARRAY[sr.skill_id, sr.required_skill_id] <@ path
        from skill_requirements sr,
            reqtree r
        where r.required_skill_id = sr.skill_id
            and not cycle
    )
    select q.path[1] as skill_id, s1.name as skill_name,
        q.skill_id as parent_skill_id, s2.name as parent_skill_name,
        q.required_skill_id, s3.name as required_skill_name,
        q.tier, q.required_level,
        q.tier_path, array_to_string(q.tier_path, '.', '*') as tier_path_str
    from reqtree q
        join ccp.skills s1 on (s1.skill_id = q.path[1])
        join ccp.skills s2 on (s2.skill_id = q.skill_id)
        join ccp.skills s3 on (s3.skill_id = q.required_skill_id)
;

create table ccp.corporation_roles (
    corporation_role_id serial not null primary key,
    role_mask           bigint not null,
    role_name           text not null
);

create index corporation_roles_role_mask_idx on ccp.corporation_roles (role_mask);
create index corporation_roles_role_name_idx on ccp.corporation_roles (role_name);

create table ccp.type_categories (
    type_category_id integer not null primary key,
    name             text not null,
    description      text,
    published        boolean not null default 't'
);

create index type_categories_name_idx on ccp.type_categories (name);
create index type_categories_published_idx on ccp.type_categories (published);

create table ccp.type_groups (
    type_group_id    integer not null primary key,
    type_category_id integer not null,
    name             text not null,
    description      text,
    -- TODO
    published        boolean not null default 't'
);

create index type_groups_type_category_id_idx on ccp.type_groups (type_category_id);
create index type_groups_name_idx on ccp.type_groups (name);
create index type_groups_published_idx on ccp.type_groups (published);

alter table ccp.type_groups add foreign key (type_category_id) references ccp.type_categories (type_category_id) on update cascade on delete cascade;

create table ccp.types (
    type_id       integer not null primary key,
    type_group_id integer not null,
    name          text not null,
    description   text,
    base_price    numeric(20,4),
    -- TODO
    published     boolean not null default 't'
);

create index types_type_group_id_idx on ccp.types (type_group_id);
create index types_name_idx on ccp.types (name);
create index types_published_idx on ccp.types (published);

alter table ccp.types add foreign key (type_group_id) references ccp.type_groups (type_group_id) on update cascade on delete cascade;

-- SCHEMA: eve
-- Contains data collected through the EVE API provided by CCP
create schema eve;

create table eve.api_keys (
    key_id      integer not null primary key,
    v_code      text not null,
    user_id     integer not null,
    key_type    text,
    access_mask integer,
    active      boolean not null default 'f',
    verified    boolean not null default 'f',
    expires_at  timestamp with time zone,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone
);

create index api_keys_key_type_idx on eve.api_keys (key_type);
create index api_keys_active_idx on eve.api_keys (active);
create index api_keys_verified_idx on eve.api_keys (verified);
create index api_keys_expires_at_idx on eve.api_keys (expires_at);
create index api_keys_created_at_idx on eve.api_keys (created_at);
create index api_keys_updated_at_idx on eve.api_keys (updated_at);

alter table eve.api_keys add foreign key (user_id) references public.users (user_id) on update cascade on delete cascade;

alter table eve.api_keys add constraint verified_key_type check (verified is false or key_type is not null);
alter table eve.api_keys add constraint valid_key_types check (key_type is null or key_type in ('account','character','corporation'));
alter table eve.api_keys add constraint verified_access_mask check (verified is false or access_mask is not null);

create table eve.pilots (
    pilot_id     integer not null primary key,
    name         text not null,
    race         text not null,
    bloodline    text not null,
    ancestry     text not null,
    gender       text not null,
    birthdate    timestamp with time zone not null,
    balance      numeric,
    sec_status   numeric(6,4) not null,
    cached_until timestamp with time zone not null,
    active       boolean not null default 't'
);

create unique index pilots_name_idx on eve.pilots (name);
create index pilots_cached_until_idx on eve.pilots (cached_until);
create index pilots_active_idx on eve.pilots (active);

create table eve.pilot_api_keys (
    pilot_id integer not null,
    key_id   integer not null
);

alter table eve.pilot_api_keys add primary key (pilot_id, key_id);
create index pilot_api_keys_key_id_idx on eve.pilot_api_keys (key_id);

alter table eve.pilot_api_keys add foreign key (pilot_id) references eve.pilots (pilot_id) on update cascade on delete cascade;
alter table eve.pilot_api_keys add foreign key (key_id) references eve.api_keys (key_id) on update cascade on delete cascade;

create table eve.pilot_attributes (
    pilot_id     integer not null,
    attribute_id integer not null,
    level        integer not null
);

alter table eve.pilot_attributes add primary key (pilot_id, attribute_id);
create index pilot_attributes_attribute_id_idx on eve.pilot_attributes (attribute_id);

alter table eve.pilot_attributes add foreign key (pilot_id) references eve.pilots (pilot_id) on update cascade on delete cascade;
alter table eve.pilot_attributes add foreign key (attribute_id) references ccp.attributes (attribute_id) on update cascade;

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

create table eve.alliances (
    alliance_id bigint not null primary key,
    name        text not null,
    short_name  text not null,
    executor    bigint,
    founded     timestamp with time zone not null
);

create unique index alliances_name_idx on eve.alliances (name);
create unique index alliances_short_name_idx on eve.alliances (short_name);
create index alliances_executor_idx on eve.alliances (executor);
create index alliances_founded_idx on eve.alliances (founded);

create table eve.corporations (
    corporation_id  bigint not null primary key,
    name            text not null,
    ticker          text not null,
    description     text,
    tax_rate        numeric(6,2) not null,
    members         integer not null,
    shares          bigint not null,
    cached_until    timestamp with time zone not null
);

create unique index corporations_name_idx on eve.corporations (name);
create unique index corporations_ticker_idx on eve.corporations (ticker);
create index corporations_cached_until_idx on eve.corporations (cached_until);

-- add the executor FKEY from alliances now that we have the referenced object
alter table eve.alliances add foreign key (executor) references eve.corporations (corporation_id) on update cascade;

create table eve.alliance_corporations (
    alliance_id    bigint not null,
    corporation_id bigint not null,
    from_datetime  timestamp with time zone not null,
    to_datetime    timestamp with time zone
);

alter table eve.alliance_corporations add primary key (alliance_id, corporation_id, from_datetime);
create index alliance_corporations_corporation_id_idx on eve.alliance_corporations (corporation_id);
create index alliance_corporations_from_datetime_idx on eve.alliance_corporations (from_datetime);
create index alliance_corporations_to_datetime_idx on eve.alliance_corporations (to_datetime);

alter table eve.alliance_corporations add foreign key (alliance_id) references eve.alliances (alliance_id) on update cascade;
alter table eve.alliance_corporations add foreign key (corporation_id) references eve.corporations (corporation_id) on update cascade;

create table eve.corporation_api_keys (
    corporation_id  bigint not null,
    key_id          integer not null
);

alter table eve.corporation_api_keys add primary key (corporation_id, key_id);
create index corporation_api_keys_key_id_idx on eve.corporation_api_keys (key_id);

alter table eve.corporation_api_keys add foreign key (corporation_id) references eve.corporations (corporation_id) on update cascade on delete cascade;
alter table eve.corporation_api_keys add foreign key (key_id) references eve.api_keys (key_id) on update cascade on delete cascade;

create table eve.pilot_corporations (
    pilot_id       integer not null,
    corporation_id integer not null,
    from_datetime  timestamp with time zone not null,
    to_datetime    timestamp with time zone
);

alter table eve.pilot_corporations add primary key (pilot_id, corporation_id, from_datetime);
create index pilot_corporations_corporation_id_idx on eve.pilot_corporations (corporation_id);
create index pilot_corporations_from_datetime_idx on eve.pilot_corporations (from_datetime);
create index pilot_corporations_to_datetime_idx on eve.pilot_corporations (to_datetime);

alter table eve.pilot_corporations add foreign key (pilot_id) references eve.pilots (pilot_id) on update cascade on delete cascade;
alter table eve.pilot_corporations add foreign key (corporation_id) references eve.corporations (corporation_id) on update cascade on delete cascade;

-- SCHEMA: plans
-- Skill queue/plan management
create schema plans;

create view plans.training_times as
    select p.pilot_id, s.skill_id, s.primary_attribute_id, s.secondary_attribute_id,
        coalesce(pa1.level, 20) as primary_level, coalesce(pa2.level, 20) as secondary_level,
        s.rank, slp.level as train_level, s.rank * slp.points as train_points,
        (coalesce(pa1.level, 20) + cast(coalesce(pa2.level, 20) as float) / 2) * 60 as rate,
        (s.rank * slp.points) / ((coalesce(pa1.level, 20) + cast(coalesce(pa2.level, 20) as float) / 2) / 60) as train_seconds
    from eve.pilots p
        cross join ccp.skills s
        cross join ccp.skill_level_points slp
        join ccp.attributes a1 on (a1.attribute_id = s.primary_attribute_id)
        join ccp.attributes a2 on (a2.attribute_id = s.secondary_attribute_id)
        left join eve.pilot_attributes pa1 on (pa1.attribute_id = a1.attribute_id and pa1.pilot_id = p.pilot_id)
        left join eve.pilot_attributes pa2 on (pa2.attribute_id = a2.attribute_id and pa2.pilot_id = p.pilot_id)
;

create table plans.skill_queues (
    pilot_id     integer not null,
    position     integer not null,
    skill_id     integer not null,
    level        integer not null,
    start_points integer not null,
    end_points   integer not null,
    start_time   timestamp with time zone not null,
    end_time     timestamp with time zone not null
);

alter table plans.skill_queues add primary key (pilot_id, position);
create index skill_queues_position_idx on plans.skill_queues (position);
create index skill_queues_skill_id_idx on plans.skill_queues (skill_id);
create index skill_queues_start_time_idx on plans.skill_queues (start_time);

alter table plans.skill_queues add foreign key (pilot_id) references eve.pilots (pilot_id) on update cascade on delete cascade;
alter table plans.skill_queues add foreign key (skill_id) references ccp.skills (skill_id) on update cascade on delete cascade;

create table plans.plans (
    plan_id     serial not null primary key,
    user_id     integer not null,
    pilot_id    integer,
    name        text not null,
    summary     text,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone
);

create index plans_user_id_idx on plans.plans (user_id);
create index plans_pilot_id_idx on plans.plans (pilot_id);
create index plans_name_idx on plans.plans (name);

alter table plans.plans add foreign key (user_id) references public.users (user_id) on update cascade on delete cascade;
alter table plans.plans add foreign key (pilot_id) references eve.pilots (pilot_id) on update cascade on delete cascade;

-- SCHEMA: fits
-- Ship fittings
create schema fits;


-- SCHEMA: forums
-- Discussion forums
create schema forums;

create table forums.forums (
    forum_id        serial not null primary key,
    parent_forum_id integer,
    name            text not null,
    description     text,
    created_at      timestamp with time zone not null default now()
);

create index forums_parent_forum_id_idx on forums.forums (parent_forum_id);

alter table forums.forums add foreign key (parent_forum_id) references forums.forums (forum_id) on update cascade on delete cascade;

create table forums.forum_visibility (
    visibility_id     serial not null primary key,
    forum_id          integer not null,
    global            boolean not null default 'f',
    alliance          integer,
    corporation       integer,
    corporate_role_id integer,
    created_by        integer not null,
    created_at        timestamp with time zone not null default now()
);

create table forums.threads (
    thread_id serial not null primary key,
    forum_id  integer not null,
    locked    boolean not null default 'f',
    sticky    boolean not null default 'f'
);

create table forums.posts (
    post_id     serial not null primary key,
    thread_id   integer not null,
    pilot_id    integer not null,
    in_reply_to integer,
    subject     text not null,
    body        text not null,
    created_at  timestamp with time zone not null default now()
);

create table forums.post_votes (
    post_id     integer not null,
    user_id     integer not null,
    vote        integer not null,
    created_at  timestamp with time zone not null default now()
);

alter table forums.post_votes add primary key (post_id, user_id);

create table forums.thread_reads (
    user_id   integer not null,
    thread_id integer not null,
    read_at   timestamp with time zone not null
);

alter table forums.thread_reads add primary key (user_id, thread_id);

-- Wonders will never cease if we got here and the transaction hasn't already failed.
commit;
