opne-webui cleaner cron

- docker cp <local_file_path> 									 <container_id>:/<path_inside_container>
- docker cp C:\Users\DahmanDidi\Documents\ai\open-webui\cleaners open-webui:/app/backend/
 
- sqlite3 apt install (via container of via docker file uiteindelijk)

- script bestand
	- navigeer naar directory (/app/backend/cleaners/)
	- nano cleaner.sh
- bestand uitvoerbaar maken
	- chmod +x /app/backend/cleaners/cleaner.sh
	- om te testen: 
		- docker exec open-webui /app/backend/cleaner.sh
- start de crons op de host (lokaal in wsl omgeving crontab -e)
	- * * * * * docker exec open-webui /app/backend/cleaners/cleaner.sh
	- * * * * * docker exec open-webui /app/backend/cleaners/db_cleaner.sh

	
	
dirs om schoon te maken:
- /app/backend/data/cache/audio/speech/*
- /app/backend/data/uploads/*

db om op te schonen:
	- /app/backend/data/webui.db
		- chat (!)
		- chatidtag (?)
		- document (?)
		- file (!)
		- folder (!)
		- memory (?)
		- message (?)
		- message_reaction (?)