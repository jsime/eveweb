-- SCHEMA: public
-- General account, authorization, configuration data

create table public.users (
    user_id     serial not null primary key,
    email       text not null,
    username    text not null,
    password    text not null,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone,
    deleted_at  timestamp with time zone
);

create unique index users_lower_email_idx on public.users (lower(email));
create unique index users_lower_username_idx on public.users (lower(username));
create index users_created_at_idx on public.users (created_at);
create index users_updated_at_idx on public.users (updated_at);
create index users_deleted_at_idx on public.users (deleted_at);

create table public.sessions (
    session_id  serial not null primary key,
    user_id     integer not null,
    started_at  timestamp with time zone not null default now(),
    ended_at    timestamp with time zone,
    last_used   timestamp with time zone
);

create index sessions_user_id_idx on public.sessions (user_id);
create index sessions_started_at_idx on public.sessions (started_at);
create index sessions_ended_at_idx on public.sessions (ended_at);
create index sessions_last_used_idx on public.sessions (last_used);

alter table public.sessions add foreign key (user_id) references public.users (user_id) on update cascade on delete cascade;

-- SCHEMA: ccp
-- Static data imported from CCP's EVE data exports
create schema ccp;

create table ccp.attributes (
    attribute_id
    name
    description
);

create table ccp.skills (
    skill_id
    name
    description
    rank
    primary_attribute_id
    secondary_attribute_id
);

create table ccp.skill_requirements (
    skill_id
    required_skill_id
    required_level
);

-- SCHEMA: eve
-- Contains data collected through the EVE API provided by CCP
create schema eve;

create table eve.accounts (
    account_id
    user_id
    created_at
    updated_at
    deleted_at
);

create table eve.account_api_keys (
    api_key_id
    account_id
    api_key
    verification_code
    created_at
    updated_at
    deleted_at
);

create table eve.pilots (
    pilot_id
    account_id
    name
    race
    bloodline
    gender
    birthdate
    sec_status
);

create table eve.pilot_skills (
    pilot_id
    skill_id
    level
    skill_points
    training
    started_at
    started_points
);

-- SCHEMA: plans
-- Skill queue/plan management
create schema plans;

create table plans.skill_plans (
    skill_plan_id
    pilot_id
    plan_name
    notes
    created_at
    updated_at
    deleted_at
);

create table plans.skill_plan_queue (
    skill_plan_id
    skill_id
    level
    order
    created_at
    updated_at
);

-- SCHEMA: fits
-- Ship fittings
create schema fits;

create table fits.ship_fits (
    ship_fit_id
    account_id
    ship_id
    name
    description
    visibility -- personal, corp, alliance, coalition, public
    created_at
    updated_at
    deleted_at
);

create table fits.ship_fit_subsystems (
    ship_fit_subsystem_id
    ship_fit_id
    subsystem_id
);

create table fits.ship_fit_modules (
    ship_fit_module_id
    ship_fit_id
    module_id
);

create table fits.ship_fit_munitions (
    ship_fit_munition_id
    ship_fit_module_id
    munition_id
);

create table fits.ship_fit_drones (
    ship_fit_drone_id
    ship_fit_id
    drone_id
    quantity
);
