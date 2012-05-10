create table postcodes (
       id integer primary key,
-- the postcode is not unique.
       postcode text,
       address_id integer references address (id),
       jigyosyo_id integer references jigyosyo (id)
);

create index postcode_idx on postcodes (address_id, jigyosyo_id);

create table jigyosyo (
       id integer primary key,
       kanji text,
       kana text,
       street_number text
);

create index jigyosyo_idx on jigyosyo (kanji, kana);

create table ken (
       id integer primary key,
       kanji text unique,
       kana text unique
);

create index ken_idx on ken (kanji, kana);

create table city (
       id integer primary key,
       ken_id integer references ken (id),
       kanji text,
       kana text
);

create index city_idx on city (kanji, kana);

create table address (
       id integer primary key,
       city_id integer references city (id),
       kanji text,
       kana text,
       other_id integer references other (id)
);

create index address_idx on address (kanji, kana);

create table other (
       id integer primary key,
       kanji text,
       kana text
);
