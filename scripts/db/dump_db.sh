DB_TO_DUMP_DEFAULT=macos_log_collector_development
DEFAULT_DIR_TO_DUMP_TO=/Volumes/images/pg_dump

if [[ -z $DB_TO_DUMP ]]; then
    echo -e "DB_TO_DUMP not defined, using default value..."
    DB_TO_DUMP=$DB_TO_DUMP_DEFAULT
fi

if [[ -z $DIR_TO_DUMP_TO ]]; then
    echo "DIR_TO_DUMP_TO not defined, using default value..."
    DIR_TO_DUMP_TO=$DEFAULT_DIR_TO_DUMP_TO
fi

DUMP_FILE=$DIR_TO_DUMP_TO/pg_dump_$DB_TO_DUMP_$(date "+%Y-%m-%dT%H%M%S%p")
mkdir -p $DIR_TO_DUMP_TO
echo -e "\nOutput file: $DUMP_FILE"
pg_dump $@ -Fc -Z9 -f $DUMP_FILE $DB_TO_DUMP
