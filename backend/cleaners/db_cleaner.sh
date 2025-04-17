#!/bin/bash

echo "DB cleanup started" >> /app/backend/cleaners/cron.log

TABLES=(chat file folder)
QUERY="DELETE FROM %s WHERE created_at < unixepoch(datetime('now', '-7 days'));\n"

for TABLE in "${TABLES[@]}"; do
 QUERY_WITH_TABLE=$(printf "$QUERY" "$TABLE")
 sqlite3 /app/backend/data/webui.db "$QUERY_WITH_TABLE"
 if [ $? -ne 0 ]; then
  echo "Error executing query on table $TABLE" >> /app/backend/cleaners/cron.log
 fi
done

echo "DB cleanup finished" >> /app/backend/cleaners/cron.log

echo "DB Vacuum started" >> /app/backend/cleaners/cron.log

# Om vrijgekomen ruimte vrij te maken en de database te optimaliseren
sqlite3 /app/backend/data/webui.db "VACUUM;"

if [ $? -ne 0 ]; then
  echo "DB Vacuum failed" >> /app/backend/cleaners/cron.log
fi

echo "DB Vacuum finished" >> /app/backend/cleaners/cron.log