#!/bin/bash

echo "Cleanup started" >> /app/backend/cleaners/cron.log

# Directory's waar de bestanden zich bevinden
DIRECTORIES=(
  "/app/backend/data/cache/audio/speech"
  "/app/backend/data/uploads"
)

# Leeftijd in dagen of minuten
DAYS=7
MINUTES=10

# Gebruik leeftijd in dagen of minuten
USE_DAYS=false

# Verwijder bestanden die ouder zijn dan de opgegeven leeftijd
for DIRECTORY in "${DIRECTORIES[@]}"; do
  if [ -d "$DIRECTORY" ]; then
    if $USE_DAYS; then
      find "$DIRECTORY" -type f -mtime +$DAYS -exec rm {} \; >> /app/backend/cleaners/cron.log 2>&1
    else
      find "$DIRECTORY" -type f -mmin +$MINUTES -exec rm {} \; >> /app/backend/cleaners/cron.log 2>&1
    fi
  else
    echo "Directory $DIRECTORY bestaat niet" >> /app/backend/cleaners/cron.log
  fi
done

echo "Cleanup finished" >> /app/backend/cleaners/cron.log