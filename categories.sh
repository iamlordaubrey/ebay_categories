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
    sqlite3 $DB_FILE < create_tables.sql
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
    RESP=($(
    sqlite3 $DB_FILE "with recursive nt(cat_id)
    as (
      select descendant_id
      from category_closure
      where ancestor_id = $arg
      union
      select descendant_id
      from category_closure, nt
      where category_closure.ancestor_id = nt.cat_id
    )
    select category_id, category_name, category_level, best_offer_enabled
    from category
    where category_id in nt
    order by category_level;
    "))
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
    DATA=""

    if [ ${#RESP[@]} -eq 0 ]; then
        DATA="${DATA}<table class="table">"
        DATA="${DATA}
        <thead>
            <tr>
                <th scope="col">No category with ID: '$1'</th>
            </tr>
        </thead>
        "
        DATA="${DATA}</table>"

        echo "No category with ID: '$1'"
    else
        DATA="${DATA}<table class="table">"
        DATA="${DATA}
        <thead>
            <tr>
                <th scope="col">#</th>
                <th scope="col">CATEGORY ID</th>
                <th scope="col">CATEGORY NAME</th>
                <th scope="col">CATEGORY LEVEL</th>
                <th scope="col">BEST OFFER ENABLED</th>
            </tr>
        </thead>
        "
        index=1

        for j in ${RESP[@]}
        do
            cat_id="$(cut -d'|' -f1 <<<"$j")"
            cat_name="$(cut -d'|' -f2 <<<"$j")"
            cat_level="$(cut -d'|' -f3 <<<"$j")"
            best_offer_enabled="$(cut -d'|' -f4 <<<"$j")"

            DATA="${DATA}
            <tbody>
                <tr>
                    <th scope="row">$index</th>
                    <td>$cat_id</td>
                    <td>$cat_name</td>
                    <td>$cat_level</td>
                    <td>$best_offer_enabled</td>
                </tr>
            </tbody>
            "
            let index=${index}+1
        done
        DATA="${DATA}</table>"
    fi

    HTML="
    <!DOCTYPE HTML>
    <html>
    <head>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
        <link href="styles/cat.css" rel="stylesheet" type="text/css" />
    </head>
    <body>
        $DATA
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
    </body>
    </html>
    "
    echo $HTML >> $HTML_FILENAME
fi
