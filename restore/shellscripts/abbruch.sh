LOGFILE=$1

# FTP-Verbindung unterbrechen
kill `ps -aux | grep "ftp -n ftp.<MeineDomain>" | grep -v grep | awk {'print$2'}`
kill `ps -aux | grep "ftp -n ftp.<MeineDomain>" | grep -v grep | awk {'print$2'}`

# Unzip-Vorgang stoppen
kill `ps -aux | grep "rm -rf" | grep -v grep | awk {'print$2'}`

# Unzip-Vorgang stoppen
kill `ps -aux | grep "rm -f" | grep -v grep | awk {'print$2'}`

# Unzip-Vorgang stoppen
kill `ps -aux | grep "unzip tmpbackups" | grep -v grep | awk {'print$2'}`

# Unzip-Vorgang stoppen
kill `ps -aux | grep "unzip -q tmpbackups" | grep -v grep | awk {'print$2'}`

# Datenbank-Sicherungsdump stoppen ...
kill `ps -aux | grep "mysqldump --comments" | grep -v grep | awk {'print$2'}`

# Datenbankimport stoppen - sollte i.d.R. der einzige Prozess mit diesem String sein ...
kill `ps -aux | grep "mysql --force" | grep -v grep | awk {'print$2'}`

# Datenbankimport stoppen - sollte i.d.R. der einzige Prozess mit diesem String sein ...
kill `ps -aux | grep "mysql --verbose --force" | grep -v grep | awk {'print$2'}`

# Meta-Download-/Import-Skript stoppen
killall downloadAndImportSQLtoSandbox.sh

echo "" > logs/importToDB.log

# Weiteren Importvorgang ermoeglichen
rm sandboximport.lock
rm deletezipfolder.lock
rm deleteSQL.lock
rm restoreProcess.dead

if [ -z "$1" ]
  then
      echo "Warnung: Kein Logfile angegeben!"
      exit 1
fi

# Abbruch in Log-Datei schreiben
NOW=$(date +"%d.%m.%Y %H:%M")
SUBJECT="[$NOW]Abbruch: Manueller Abbruch des Importvorganges!"
echo $SUBJECT >> "logs/"$LOGFILE

echo "Logfile: logs/"$LOGFILE | mail -s "$SUBJECT" "<MeineEmailAdresse>"