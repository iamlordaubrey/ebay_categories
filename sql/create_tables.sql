DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS category_closure;

CREATE TABLE category (
    category_id integer not null primary key,
    category_name varchar(255),
    category_level integer,
    best_offer_enabled varchar,
    category_parent_id integer,
    leaf_category varchar
);


CREATE TABLE category_closure (
    ancestor_id INTEGER NOT NULL,
    descendant_id integer not null,
    depth integer not null
);
