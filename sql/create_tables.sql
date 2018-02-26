DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS category_closure;

CREATE TABLE category (
    category_id integer not null primary key,
    category_name text,
    category_level integer,
    category_parent_id integer,
    best_offer_enabled text
);


CREATE TABLE category_closure (
    ancestor_id integer not null,
    descendant_id integer not null
);
