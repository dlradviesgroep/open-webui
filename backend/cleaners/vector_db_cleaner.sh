#!/bin/bash

echo "Vector DB cleanup started" >> /app/backend/cleaners/cron.log

# Zet de directory's en de database file
UPLOADS_DIR="/app/backend/data/uploads"
VECTOR_DB_DIR="/app/backend/data/vector_db"
VECTOR_DB_FILE="$VECTOR_DB_DIR/chroma.sqlite3"

# Zet de tabellen en kolommen in de database
SEGMENTS_TABLE="segments"
COLLECTIONS_TABLE="collections"

# echo "UPLOADS_DIR: $UPLOADS_DIR" >> /app/backend/cleaners/cron.log
# echo "VECTOR_DB_DIR: $VECTOR_DB_DIR" >> /app/backend/cleaners/cron.log
# echo "VECTOR_DB_FILE: $VECTOR_DB_FILE" >> /app/backend/cleaners/cron.log
# echo "SEGMENTS_TABLE: $SEGMENTS_TABLE" >> /app/backend/cleaners/cron.log
# echo "COLLECTIONS_TABLE: $COLLECTIONS_TABLE" >> /app/backend/cleaners/cron.log

# Loop door alle mappen in de vector_db directory
for dir in "$VECTOR_DB_DIR"/*; do
  echo "Dir: $dir" >> /app/backend/cleaners/cron.log

  # Check of het een directory is en niet de .sqlite3 file
  if [ -d "$dir" ] && [ "${dir##*/}" != "chroma.sqlite3" ]; then
    # Haal de uuid uit de directory naam
    uuid="${dir##*/}"

    echo "Verwijdering van UUID: $uuid" >> /app/backend/cleaners/cron.log

    # Vraag de naam van het bestand op uit de database
    file_name=$(sqlite3 "$VECTOR_DB_FILE" "SELECT REPLACE(name, 'file-', '') FROM $COLLECTIONS_TABLE WHERE id = (SELECT collection FROM $SEGMENTS_TABLE WHERE id = '$uuid');")
    echo "Verwijdering van file: $file_name" >> /app/backend/cleaners/cron.log

    # Check of het bestand bestaat in de uploads directory
    if [ -f "$UPLOADS_DIR/$file_name"* ]; then
      # Bestand bestaat, doe niets
      echo "File gevonden: $file_name" >> /app/backend/cleaners/cron.log

    else
      echo "File niet gevonden: $file_name" >> /app/backend/cleaners/cron.log

      # Haal de collection id op uit de segments tabel
      collection_id=$(sqlite3 "$VECTOR_DB_FILE" "SELECT collection FROM $SEGMENTS_TABLE WHERE id = '$uuid';")
      echo "Verwijdering van collection: $collection_id" >> /app/backend/cleaners/cron.log

      # Verwijder de rijen uit de database
      sqlite3 "$VECTOR_DB_FILE" "BEGIN TRANSACTION;"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM embedding_fulltext_search_content WHERE id IN (SELECT id FROM embeddings WHERE segment_id IN (SELECT id FROM $SEGMENTS_TABLE WHERE collection = '$collection_id'));"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM embedding_fulltext_search_docsize WHERE id IN (SELECT id FROM embeddings WHERE segment_id IN (SELECT id FROM $SEGMENTS_TABLE WHERE collection = '$collection_id'));"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM embedding_metadata WHERE id IN (SELECT id FROM embeddings WHERE segment_id IN (SELECT id FROM $SEGMENTS_TABLE WHERE collection = '$collection_id'));"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM embedding_fulltext_search_idx WHERE seq_id IN (SELECT id FROM embeddings WHERE segment_id IN (SELECT id FROM $SEGMENTS_TABLE WHERE collection = '$collection_id'));"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM embeddings_queue WHERE seq_id IN (SELECT id FROM embeddings WHERE segment_id IN (SELECT id FROM $SEGMENTS_TABLE WHERE collection = '$collection_id'));"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM max_seq_id WHERE segment_id IN (SELECT id FROM $SEGMENTS_TABLE WHERE collection = '$collection_id');"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM embeddings WHERE segment_id IN (SELECT id FROM $SEGMENTS_TABLE WHERE collection = '$collection_id');"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM segment_metadata WHERE segment_id IN (SELECT id FROM $SEGMENTS_TABLE WHERE collection = '$collection_id');"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM collection_metadata WHERE collection_id = '$collection_id';"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM $COLLECTIONS_TABLE WHERE id = '$collection_id';"
      sqlite3 "$VECTOR_DB_FILE" "DELETE FROM $SEGMENTS_TABLE WHERE collection = '$collection_id';"
      sqlite3 "$VECTOR_DB_FILE" "COMMIT;"

      # Verwijder de directory
      echo "Verwijder directory $dir" >> /app/backend/cleaners/cron.log
      rm -rf "$dir"
    fi
  fi
done

echo "Vector DB cleanup finished" >> /app/backend/cleaners/cron.log

echo "Vector DB Vacuum started" >> /app/backend/cleaners/cron.log

# Om vrijgekomen ruimte vrij te maken en de database te optimaliseren
sqlite3 "$VECTOR_DB_FILE" "VACUUM;"

echo "Vector DB Vacuum finished" >> /app/backend/cleaners/cron.log