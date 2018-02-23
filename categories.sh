#!/bin/sh

DB_FILE='pmath.db'
RESP=''

rebuild_func()
{
    echo "Rebuild function called. Please wait..."

    # Remove database file if present
    [[ -f $DB_FILE ]] && rm $DB_FILE

    # Create database and tables
    sqlite3 $DB_FILE < create_tables.sql
    echo "Database and tables created!\nPopulating tables..."

    python builder.py
}

render_func()
{
    echo "Render function called"
    arg=$1
    HTML_FILENAME="$arg.html"
    echo "$HTML_FILENAME"

    # Remove html file if present
    html_file="$HTML_FILENAME"
    [[ -f $html_file ]] && rm $html_file

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

read -d '' HELP_STRING <<- _EOF_
    Usage:
        ./categories.sh <command>

    Commands:
        --rebuild
        --render <category_id>
_EOF_


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
        DATA="${DATA}No category with ID: '$1'"
        echo "No category with ID: '$1'"
    else
        DATA="${DATA}<table>"
        for j in ${RESP[@]}
        do
            DATA="${DATA}<tr><td>$j</td></tr>"
        done
    "${DATA} </table>"
    fi


    HTML="
    <!DOCTYPE HTML>
    <html>
    <head></head>
    <body>
        <p>Yo bruh!</p>
        $DATA
    </body>
    </html>
    "
    echo $HTML >> $HTML_FILENAME

    count=${#RESP[@]}
    echo $count
fi
