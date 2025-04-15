#!/bin/bash

echo "DB cleanup started" >> /app/backend/cleaners/cron.log

TABLES=(chat file folder)
QUERY="DELETE FROM %s WHERE created_at < unixepoch(datetime('now', '-7 days'));"
sqlite3 /app/backend/data/webui.db <<EOF
BEGIN TRANSACTION;
$(for TABLE in "${TABLES[@]}"; do
  printf "$QUERY\n" "$TABLE"
done)
COMMIT;
EOF

echo "DB cleanup finished" >> /app/backend/cleaners/cron.log

echo "DB Vacuum started" >> /app/backend/cleaners/cron.log

# Om vrijgekomen ruimte vrij te maken en de database te optimaliseren
sqlite3 /app/backend/data/webui.db "VACUUM;"

echo "DB Vacuum finished" >> /app/backend/cleaners/cron.log