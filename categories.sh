#!/bin/sh

DB_FILE='pmath.db'
RESP=''

read -d '' HELP_STRING <<- _EOF_
    Usage:
        ./categories.sh <command>

    Commands:
        --rebuild
        --render <category_id>
_EOF_


rebuild_func()
{
    echo "Rebuild function called. Please wait..."

    # Remove database file if present
    [[ -f $DB_FILE ]] && rm $DB_FILE

    # Create database and tables
    sqlite3 $DB_FILE < sql/create_tables.sql
    echo "Database and tables created!\nPopulating tables..."

    # Call builder script
    python builder.py
}

render_func()
{
    echo "Render function called"
    arg=$1
    HTML_FILENAME="$arg.html"

    # Remove html file if present
    html_file="$HTML_FILENAME"
    [[ -f $html_file ]] && rm $html_file

    # Make query, saving response in array RESP
    RESP=$(
    sqlite3 $DB_FILE "
    SELECT c.category_parent_id, c.category_id, c.category_name, c.category_level, c.best_offer_enabled
    FROM category c
    INNER JOIN category_closure cc
    ON cc.descendant_id = c.category_id
    WHERE cc.ancestor_id = $arg
    ORDER BY c.category_level;
    ")
}

usage()
{
    echo "$HELP_STRING"

}


case $1 in
    --rebuild )     rebuild_func
                    ;;

    --render )      shift; render=true;
                    ;;

    --help )        usage
                    exit
                    ;;
    * )             echo "Unrecognized command '$1'.";
                    usage
                    exit 1
esac


if [ "$render" == "true" ]
then
    render_func "$@"
    DATA="<table class='table table-striped table-bordered table-hover'>"
    DATA="${DATA}
    <thead class='thead-dark'>
        <tr>
            <th scope='col'>#</th>
            <th scope='col'>CATEGORY PARENT ID</th>
            <th scope='col'>CATEGORY ID</th>
            <th scope='col'>CATEGORY NAME</th>
            <th scope='col'>CATEGORY LEVEL</th>
            <th scope='col'>BEST OFFER ENABLED</th>
        </tr>
    </thead>
    "

    if [ -z "$RESP" ]; then

        DATA="${DATA}
        <tbody>
            <tr>
                <th colspan='6'><strong>No category with ID: '$1'</strong></th>
            </tr>
        </tbody>
        "
        echo "No category with ID: '$1'"
    else

        index=1
        IFS=$'\n'

        for j in ${RESP[@]}
        do
            cat_parent_id="$(cut -d'|' -f1 <<<"$j")"
            cat_id="$(cut -d'|' -f2 <<<"$j")"
            cat_name="$(cut -d'|' -f3 <<<"$j")"
            cat_level="$(cut -d'|' -f4 <<<"$j")"
            best_offer_enabled="$(cut -d'|' -f5 <<<"$j")"

            DATA="${DATA}
            <tbody>
                <tr>
                    <th scope='row'>$index</th>
                    <td>$cat_parent_id</td>
                    <td>$cat_id</td>
                    <td>$cat_name</td>
                    <td>$cat_level</td>
                    <td>$best_offer_enabled</td>
                </tr>
            </tbody>
            "
            let index=${index}+1
        done
    fi
    DATA="${DATA}</table>"

    HTML="<!DOCTYPE HTML>
    <html>
    <head>
    <link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css' integrity='sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm' crossorigin='anonymous'>
    <link href='styles/cat.css' rel='stylesheet' type='text/css' />
    </head>
    <body>
    $DATA
    <script src='https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js' integrity='sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl' crossorigin='anonymous'></script>
    </body>
    </html>
    "

    echo $HTML >> $HTML_FILENAME
fi
