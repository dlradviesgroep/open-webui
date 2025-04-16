#!/bin/bash

echo "DB cleanup started" >> /app/backend/cleaners/cron.log

TABLES=(chat file folder)
QUERY="DELETE FROM %s WHERE created_at < strftime('%s', 'now', '-7 days');"
sqlite3 /app/backend/data/webui.db <<EOF
BEGIN TRANSACTION;
$(for TABLE in "${TABLES[@]}"; do
  echo "Deleting $TABLE" >> /app/backend/cleaners/cron.log
  printf "$QUERY\n" "$TABLE"
done)
COMMIT;
EOF

if [ $? -ne 0 ]; then
  echo "DB cleanup failed" >> /app/backend/cleaners/cron.log
  echo "Foutbericht: $?" >> /app/backend/cleaners/cron.log
  sqlite3 /app/backend/data/webui.db "ROLLBACK;"
  exit 1
fi

echo "DB cleanup finished" >> /app/backend/cleaners/cron.log

echo "DB Vacuum started" >> /app/backend/cleaners/cron.log

# Om vrijgekomen ruimte vrij te maken en de database te optimaliseren
sqlite3 /app/backend/data/webui.db <<EOF
BEGIN TRANSACTION;
VACUUM;
COMMIT;
EOF

if [ $? -ne 0 ]; then
  echo "DB Vacuum failed" >> /app/backend/cleaners/cron.log
  exit 1
fi

echo "DB Vacuum finished" >> /app/backend/cleaners/cron.log