# Initial database

# --- !Ups

create extension pgcrypto;

grant select on play_evolutions to public;
revoke create on schema public from public;

create table currencies (
    currency varchar(8) not null primary key,
    position int not null -- used for displaying
);

create table users (
    id bigint primary key,
    created timestamp(3) default current_timestamp not null,
    email varchar(256) not null,
    on_mailing_list bool default false not null,
    tfa_enabled bool default false not null,
    verification int default 0 not null,
    pgp text,
    active bool default true not null
);
create unique index unique_lower_email on users (lower(email));

create table users_name_info (
    user_id bigint not null,
    name varchar(256) not null,
    surname varchar(256) not null,
    middle_name varchar(256),
    prefix varchar(16),
    foreign key (user_id) references users(id),
    primary key (user_id)
);

create table users_address_info (
    user_id bigint not null,
    country varchar(256) not null,
    address varchar(256) not null,
    city varchar(256) not null,
    state varchar(256) not null,
    zip varchar(8) not null,
    type varchar(16) not null,
    foreign key (user_id) references users(id),
    primary key (user_id)
);

create table users_passwords (
    user_id bigint not null,
    password varchar(256) not null, -- salt is a part of the password field
    created timestamp(3) default current_timestamp not null,
    foreign key (user_id) references users(id),
    primary key (user_id, created)
);

create table users_tfa_secrets (
    user_id bigint not null,
    tfa_secret varchar(256),
    created timestamp(3) default current_timestamp not null,
    foreign key (user_id) references users(id),
    primary key (user_id, created)
);

create table users_backup_otps (
    user_id bigint not null,
    otp int not null,
    created timestamp(3) default current_timestamp not null,
    foreign key (user_id) references users(id),
    primary key (user_id, otp)
);

create table trusted_action_requests (
    email varchar(256),
    is_signup boolean not null,
    primary key (email, is_signup)
);

create table totp_tokens_blacklist (
    user_id bigint not null,
    token int not null,
    expiration timestamp(3) not null,
    foreign key (user_id) references users(id)
);
create index totp_tokens_blacklist_expiration_idx on totp_tokens_blacklist(expiration desc);

create sequence event_log_id_seq;
create table event_log (
    id bigint default nextval('event_log_id_seq') primary key,
    created timestamp(3) default current_timestamp not null,
    email varchar(256),
    user_id bigint,
    ip inet,
    browser_headers text, -- these can be parsed later to produce country info
    browser_id text, -- result of deanonymization
    ssl_info text, -- what ciphers were offered, what cipher was accepted, etc.
    type text, -- one of: login_partial_success, login_success, login_failure, logout, session_expired
    foreign key (user_id) references users(id)
);
create index login_log_idx on event_log(user_id, created desc, id desc) where type in ('login_success', 'login_failure', 'logout', 'session_expired');

create table tokens (
    token varchar(256) not null primary key,
    email varchar(256) not null,
    creation timestamp(3) not null,
    expiration timestamp(3) not null,
    is_signup bool not null
);
create index tokens_expiration_idx on tokens(expiration desc);

create table balances (
    user_id bigint not null,
    currency varchar(8) not null,
    balance numeric(23,8) default 0 not null,
    hold numeric(23,8) default 0 not null,
    constraint positive_balance check(balance >= 0),
    constraint positive_hold check(hold >= 0),
    constraint no_hold_above_balance check(balance >= hold),
    foreign key (user_id) references users(id),
    foreign key (currency) references currencies(currency),
    primary key (user_id, currency)
);

create table orders (
    order_id bigint not null,
    user_id bigint not null,
    country_id int not null,
    user_email varchar(256) not null,
    type varchar(4) not null,
    creation int not null, -- timestamp(3) not null,
    primary key (order_id)
);


# --- !Downs
drop table if exists balances cascade;
drop table if exists currencies cascade;
drop table if exists tokens cascade;
drop table if exists orders cascade;
drop table if exists users cascade;
drop table if exists users_name_info cascade;
drop table if exists users_address_info cascade;
drop table if exists users_passwords cascade;
drop table if exists users_api_keys cascade;
drop table if exists users_backup_otps cascade;
drop table if exists users_tfa_secrets cascade;
drop table if exists totp_tokens_blacklist cascade;
drop table if exists event_log cascade;
drop table if exists withdrawal_limits cascade;
drop table if exists trusted_action_requests cascade;
drop sequence if exists event_log_id_seq cascade;
drop extension pgcrypto;
