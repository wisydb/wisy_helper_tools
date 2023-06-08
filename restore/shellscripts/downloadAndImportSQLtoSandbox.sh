#!/bin/bash

# script tracing:
# set -x

START=$(date +%s)

###################
##### CONFIG ######

# PFLICHT
LIVEIMPORT_PWDCHK=$1
FILENAME=$2
EMAIL=$3
LOGFILE=$4
LOGDETAILSFILE=$5

UNZIPSCOPE=$6

# GGF. OPTIONAL
SANDBOX=$7
VALIDSANDBOXES="^[S|s]andbox [1|2|3|4|5|6|7|8|9|10|99]$"

# OPTIONAL
QUICKER=$8

if [ -z "$QUICKER" ] ; then
 HTML=$8
else
 HTML=$9
fi

BACKUPFOLDER="tmpbackups"
LOGFOLDER="logs"

SERVER="<MeineDomain>"

# ! SERVER="<DistServer>"
# ! IMPORTSQLFILE="backup2scp-$SERVER-live.sql"
IMPORTSQLFILE="backup2scp-<MeineDomain>-live.sql"


ZIPFILE="$BACKUPFOLDER/$FILENAME"
UNZIPFOLDER=$ZIPFILE"_unziped"

MAILTEXT=$FILENAME
NOW=$(date +"%d.%m.%Y %H:%M")

DUMPSFOLDER="localdumps"
TIMESTAMP=`date +%Y-%m-%d-%H-%M-%S`

DBHOST="localhost"

USER_LIVE="<LiveDB>"
PWD_LIVE="<LivePasswort>"
DB_LIVE="<LiveDB>"

USER_SANDBOX1="<LiveDB>_1"
PWD_SANDBOX1="<LivePasswort>"
DB_SANDBOX1="<LiveDB>_1"

USER_SANDBOX2="<LiveDB>_5"
PWD_SANDBOX2="<LivePasswort>"
DB_SANDBOX2="<LiveDB>_5"

USER_SANDBOX3="<LiveDB>_6"
PWD_SANDBOX3="<LivePasswort>"
DB_SANDBOX3="<LiveDB>_6"

USER_SANDBOX99="<LiveDB>_8"
PWD_SANDBOX99="<LivePasswort>"
DB_SANDBOX99="<LiveDB>_8"

USER_SANDBOX4="<LiveDB>_9"
PWD_SANDBOX4="<LivePasswort>"
DB_SANDBOX4="<LiveDB>_9"

USER_SANDBOX5="<LiveDB>_10"
PWD_SANDBOX5="<LivePasswort>"
DB_SANDBOX5="<LiveDB>_10"

USER_SANDBOX6="<LiveDB>_11"
PWD_SANDBOX6="<LivePasswort>"
DB_SANDBOX6="<LiveDB>_11"

USER_SANDBOX7="<LiveDB>_12"
PWD_SANDBOX7="<LivePasswort>"
DB_SANDBOX7="<LiveDB>_12"

USER_SANDBOX8="<LiveDB>_13"
PWD_SANDBOX8="<LivePasswort>"
DB_SANDBOX8="<LiveDB>_13"

USER_SANDBOX9="<LiveDB>_14"
PWD_SANDBOX9="<LivePasswort>"
DB_SANDBOX9="<LiveDB>_14"

USER_SANDBOX10="<LiveDB>_15"
PWD_SANDBOX10="<LivePasswort>"
DB_SANDBOX10="<LiveDB>_15"

######################
##### FUNCTIONS ######

function error_nomail {
 ERRORTEXT=$1
 
 # Konsolenaufruf
 if [ -z "$HTML" ] ; then
  HTML1=""
  HTML2=""
 else
  HTML1="<span class='error'>"
  HTML2="</span>"
 fi
 
 log_details "$HTML1""$ERRORTEXT""$HTML2"
 
 explainsyntax
 
 shellscripts/abbruch.sh
 
 exit 3
}

function error {

 NOW=$(date +"%d.%m.%Y %H:%M")
 ERRORTEXT="[$NOW] Error: $1"
 
 if [ -z "$2" ] ; then
  echo $ERRORTEXT >> $LOGFILE
 fi
  
 echo "Logfile: "$PWD"/"$LOGFILE | mail -s "$ERRORTEXT" "$EMAIL"
 
 error_nomail "$ERRORTEXT"
}

function log_details {
 NOW=$(date +"%d.%m.%Y %H:%M")
 TEXT="[$NOW] $1"
 echo $TEXT >> $LOGDETAILSFILE
}

function log_nomail {
 NOW=$(date +"%d.%m.%Y %H:%M")
 TEXT="[$NOW] $1"
 echo $TEXT >> $LOGFILE
}
  
function log {
 NOW=$(date +"%d.%m.%Y %H:%M")
 
 SUBJECT="[$NOW] $1"
 
 echo $SUBJECT >> $LOGFILE
 
 if [[ $1 =~ Import-Ende.* ]]
 then
  # $LOGDETAILSFILE
  cat $LOGFILE | mail -s "$SUBJECT | Protokoll:" "$EMAIL"
 else
  echo "Logfile: "$PWD"/"$LOGFILE | mail -s "$SUBJECT" "$EMAIL"
 fi
}

function writeSQL {
 USER_TARGET=$1
 PWD_TARGET=$2
 DB_TARGET=$3
 SQLFILE=$4
 
 log "Schreibe in die Datenbank ..."
 
 # --force noetig, da probl. Trigger nicht immer entfernt!
 # --verbose fuer Debug ...
 # | tee -a $LOGDETAILSFILE
 # log_details "--force --default-character-set=utf8 --host=$DBHOST --user=$USER_TARGET --password=$PWD_TARGET $DB_TARGET < $SQLFILE"
 log_details "/usr/bin/pv -f -N Datenbankimport $SQLFILE 2> logs/importToDB.log | mysql --force --default-character-set=utf8 --host=$DBHOST --user=$USER_TARGET --password=[...] $DB_TARGET"
 
/usr/bin/pv -f -N Datenbankimport $SQLFILE 2> logs/importToDB.log | mysql --force --default-character-set=utf8 --host=$DBHOST --user=$USER_TARGET --password=$PWD_TARGET $DB_TARGET
 
 if [ $? -ne 0 ];
  then
    error "Der Befehl: --default-character-set=utf8 --host=$DBHOST --user=$USER_TARGET --password=$PWD_TARGET $DB_TARGET < $SQLFILE endete mit einem Fehler!";
  else
    echo "" > logs/importToDB.log
 fi;
 
 log "Fertig geschrieben ..."
}

function cleanSQL {
 SQLFILE=$1
 DB_TARGET=$2
 
 log_nomail "Entferne 'DEFINER'-Statements und setze aktuell gewaehlte Target-DB ein..."
 log_details "perl -p -i.bak -e \"s/50017 DEFINER=/99999 DEFINER=/g\" $SQLFILE"
 perl -p -i.bak -e "s/50017 DEFINER=/99999 DEFINER=/g" $SQLFILE
 if [ $? -ne 0 ]; then
   error "Der Befehl: -p -i.bak -e \"s/50017 DEFINER=/99999 DEFINER=/g\" $SQLFILE endete mit einem Fehler!";
 fi; 
 
 log_details "perl -p -i.bak2 -e \"s/\`"$DB_LIVE"\`/\`"$DB_TARGET"\`/g\" $SQLFILE"
 perl -p -i.bak2 -e "s/\`"$DB_LIVE"\`/\`"$DB_TARGET"\`/g" $SQLFILE
 if [ $? -ne 0 ]; then
   error "Der Befehl: perl -p -i.bak2 -e \"s/\`"$DB_LIVE"\`/\`"$DB_TARGET"\`/g\" $SQLFILE endete mit einem Fehler!";
 fi; 
}

function importIntoDatabase {
 SQLFILE=$1

 case $SANDBOX in
    "LIVE" )
      if [[ $LIVEIMPORT_PWD =~ $LIVEIMPORT_PWDCHK ]] ;
       then
        # Kein clean noetig
        writeSQL $USER_LIVE $PWD_LIVE $DB_LIVE $SQLFILE
       else
        error "Das Passwort fuer den LIVE-Import stimmt nicht ueberein!"
      fi
      ;;
    "Sandbox 1" )
     cleanSQL $SQLFILE $DB_SANDBOX1
     writeSQL $USER_SANDBOX1 $PWD_SANDBOX1 $DB_SANDBOX1 $SQLFILE
     ;;
    "Sandbox 2" )     
     cleanSQL $SQLFILE $DB_SANDBOX2
     writeSQL $USER_SANDBOX2 $PWD_SANDBOX2 $DB_SANDBOX2 $SQLFILE
     ;;
    "Sandbox 3" )     
     cleanSQL $SQLFILE $DB_SANDBOX3
     writeSQL $USER_SANDBOX3 $PWD_SANDBOX3 $DB_SANDBOX3 $SQLFILE
     ;;
     "Sandbox 4" )     
     cleanSQL $SQLFILE $DB_SANDBOX4
     writeSQL $USER_SANDBOX4 $PWD_SANDBOX4 $DB_SANDBOX4 $SQLFILE
     ;;
     "Sandbox 5" )     
     cleanSQL $SQLFILE $DB_SANDBOX5
     writeSQL $USER_SANDBOX5 $PWD_SANDBOX5 $DB_SANDBOX5 $SQLFILE
     ;;
     "Sandbox 6" )     
     cleanSQL $SQLFILE $DB_SANDBOX6
     writeSQL $USER_SANDBOX6 $PWD_SANDBOX6 $DB_SANDBOX6 $SQLFILE
     ;;
     "Sandbox 7" )     
     cleanSQL $SQLFILE $DB_SANDBOX7
     writeSQL $USER_SANDBOX7 $PWD_SANDBOX7 $DB_SANDBOX7 $SQLFILE
     ;;
     "Sandbox 8" )     
     cleanSQL $SQLFILE $DB_SANDBOX8
     writeSQL $USER_SANDBOX8 $PWD_SANDBOX8 $DB_SANDBOX8 $SQLFILE
     ;;
     "SANDBOX 99" )     
     CLEANSQL $SQLFILE $DB_SANDBOX99
     WRITESQL $USER_SANDBOX99 $PWD_SANDBOX99 $DB_SANDBOX99 $SQLFILE
     ;;
     "Sandbox 9" )     
     cleanSQL $SQLFILE $DB_SANDBOX9
     writeSQL $USER_SANDBOX9 $PWD_SANDBOX9 $DB_SANDBOX9 $SQLFILE
     ;;
     "Sandbox 10" )     
     cleanSQL $SQLFILE $DB_SANDBOX10
     writeSQL $USER_SANDBOX10 $PWD_SANDBOX10 $DB_SANDBOX10 $SQLFILE
     ;;
     
    * )
     log "Keine gueltige Import-Datenbank definiert."
 esac

}

function dumpDatabases {
 
 log "Erstelle vollstaendige Datenbank-Sicherung ..."
 
 log_nomail "LIVE-DB ..."
 # --verbose
 mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_LIVE --password=$PWD_LIVE $DB_LIVE > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-live-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
  if [ $? -ne 0 ]; then
     error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --host=$DBHOST --max_allowed_packet=500M --user=$USER_LIVE --password=[...] $DB_LIVE > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-live-$TIMESTAMP.sql endete mit einem Fehler!";
  fi;
  if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-live-$TIMESTAMP.sql ] ; then
   error "Dump konnte nicht erstellt/geschrieben werden!"
  fi
 
 
 
 log_nomail "Sandbox 1 ..."
 # --verbose
  mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX1 --password=$PWD_SANDBOX1 $DB_SANDBOX1 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox1-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
  if [ $? -ne 0 ]; then
    error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX1 --password=[...] $DB_SANDBOX1 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox1-$TIMESTAMP.sql endete mit einem Fehler!";
  fi;
  if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox1-$TIMESTAMP.sql ] ; then
   error "Dump konnte nicht erstellt/geschrieben werden!"
  fi

 log_nomail "Sandbox 2 ..."
 # --verbose 
  mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX2 --password=$PWD_SANDBOX2 $DB_SANDBOX2 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox2-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
  if [ $? -ne 0 ]; then
    error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M  --host=$DBHOST --user=$USER_SANDBOX2 --password=[...] $DB_SANDBOX2 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox2-$TIMESTAMP.sql endete mit einem Fehler!";
  fi; 
  if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox2-$TIMESTAMP.sql ] ; then
   error "Dump konnte nicht erstellt/geschrieben werden!"
  fi
 
 log_nomail "Sandbox 3 ..."
 # --verbose 
  mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX3 --password=$PWD_SANDBOX3 $DB_SANDBOX3 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
  if [ $? -ne 0 ]; then
    error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX3 --password=[...] $DB_SANDBOX3 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql endete mit einem Fehler!";
  fi; 
  if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
   error "Dump konnte nicht erstellt/geschrieben werden!"
  fi
 
 log_nomail "Ueberspringe Backup: Sandbox 99 ..."
 # --verbose 
 # ! mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX99 --password=$PWD_SANDBOX99 $DB_SANDBOX99 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox99-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
 # ! if [ $? -ne 0 ]; then
 # !   error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX99 --password=[...] $DB_SANDBOX99 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox99-$TIMESTAMP.sql endete mit einem Fehler!";
 # ! fi; 
 # ! if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
 # !  error "Dump konnte nicht erstellt/geschrieben werden!"
 # ! fi
 
 log_nomail "Ueberspringe Backup: Sandbox 4 ..."
 # --verbose 
 # ! mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX4 --password=$PWD_SANDBOX4 $DB_SANDBOX4 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox4-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
 # ! if [ $? -ne 0 ]; then
 # !   error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX4 --password=[...] $DB_SANDBOX4 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox4-$TIMESTAMP.sql endete mit einem Fehler!";
 # ! fi; 
 # ! if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
 # !  error "Dump konnte nicht erstellt/geschrieben werden!"
 # ! fi
 
 log_nomail "Ueberspringe Backup: Sandbox 5 ..."
 # --verbose 
 # ! mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX5 --password=$PWD_SANDBOX5 $DB_SANDBOX5 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox5-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
 # ! if [ $? -ne 0 ]; then
 # !   error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX5 --password=[...] $DB_SANDBOX5 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox5-$TIMESTAMP.sql endete mit einem Fehler!";
 # ! fi; 
 # ! if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
 # !  error "Dump konnte nicht erstellt/geschrieben werden!"
 # ! fi
 
 log_nomail "Ueberspringe Backup: Sandbox 6 ..."
 # --verbose 
 # ! mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX6 --password=$PWD_SANDBOX6 $DB_SANDBOX6 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox6-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
 # ! if [ $? -ne 0 ]; then
 # !   error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX6 --password=[...] $DB_SANDBOX6 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox6-$TIMESTAMP.sql endete mit einem Fehler!";
 # ! fi; 
 # ! if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
 # !  error "Dump konnte nicht erstellt/geschrieben werden!"
 # ! fi
 
 log_nomail "Ueberspringe Backup: Sandbox 7 ..."
 # --verbose 
 # ! mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX7 --password=$PWD_SANDBOX7 $DB_SANDBOX7 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox7-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
 # ! if [ $? -ne 0 ]; then
 # !   error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX7 --password=[...] $DB_SANDBOX7 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox7-$TIMESTAMP.sql endete mit einem Fehler!";
 # ! fi; 
 # ! if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
 # !  error "Dump konnte nicht erstellt/geschrieben werden!"
 # ! fi
 
 log_nomail "Ueberspringe Backup: Sandbox 8 ..."
 # --verbose 
 # ! mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX8 --password=$PWD_SANDBOX8 $DB_SANDBOX8 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox8-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
 # ! if [ $? -ne 0 ]; then
 # !   error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX8 --password=[...] $DB_SANDBOX8 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox8-$TIMESTAMP.sql endete mit einem Fehler!";
 # ! fi; 
 # ! if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
 # !  error "Dump konnte nicht erstellt/geschrieben werden!"
 # ! fi
 
 log_nomail "Ueberspringe Backup: Sandbox 9 ..."
 # --verbose 
 # ! mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX9 --password=$PWD_SANDBOX9 $DB_SANDBOX9 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox9-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
 # ! if [ $? -ne 0 ]; then
 # !   error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX9 --password=[...] $DB_SANDBOX9 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox9-$TIMESTAMP.sql endete mit einem Fehler!";
 # ! fi; 
 # ! if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
 # !  error "Dump konnte nicht erstellt/geschrieben werden!"
 # ! fi
 
 log_nomail "Ueberspringe Backup: Sandbox 10 ..."
 # --verbose 
 # ! mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX10 --password=$PWD_SANDBOX10 $DB_SANDBOX10 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox10-$TIMESTAMP.sql 2>> $LOGDETAILSFILE
 # ! if [ $? -ne 0 ]; then
 # !   error "Der Befehl: mysqldump --single-transaction --skip-lock-tables --comments --max_allowed_packet=500M --host=$DBHOST --user=$USER_SANDBOX10 --password=[...] $DB_SANDBOX10 > $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox10-$TIMESTAMP.sql endete mit einem Fehler!";
 # ! fi; 
 # ! if [ ! -f $BACKUPFOLDER"/"$DUMPSFOLDER"/"backup2scp-$SERVER-sandbox3-$TIMESTAMP.sql ] ; then
 # !  error "Dump konnte nicht erstellt/geschrieben werden!"
 # ! fi
 
}

function explainsyntax
{
 # <<- sollte tabs ignorieren
 cat <<- _OUTPUT_
 
  Syntax:
  shellscripts/downloadAndImportSQLtoSandbox.sh BACKUPFILENAME EMAIL LOGFILE LOGDETAILSFILE UNZIPSCOPE [[SANDBOX] QUICKER]
  
_OUTPUT_
}

if [ ! -f "shellscripts/downloadAndImportSQLtoSandbox.sh" ] ; then 
 ERROR="Error: Dieses Skript wurde aus dem falschen Verzeichnis aus aufgerufen!"
 printf "\n  $ERROR\n"
 explainsyntax
 exit 3
fi

# Timeout verhindern:
echo " "
echo "" > logs/importToDB.log

#################################################################
##### CHECK for missing variables & writability of folders ######

if ! [[ $EMAIL =~ .*@.*\..* ]] ; then 
 error_nomail "Keine gueltige E-Mailadresse angegeben!" "dontlog"
 echo "Restore..." | mail -s "Keine gueltige E-Mailadresse angegeben!" "<MeineEMailAdresse>"
fi

if ! [[ $LOGFILE =~ .log ]] ; then
 error "Kein gueltiges Logfile angegeben!" "dontlog"
fi

if ! [[ $LOGDETAILSFILE =~ .log ]] ; then
 error "Kein gueltiges LogDetailsfile angegeben!" "dontlog"
fi

LOGFILE=$LOGFOLDER"/"$LOGFILE
LOGDETAILSFILE=$LOGFOLDER"/"$LOGDETAILSFILE

echo "[$NOW] Log Start ..." > $LOGFILE
echo "[$NOW] Log Details Start ..." > $LOGDETAILSFILE

if [ ! -f "$LOGFILE" ] ; then
 error "Log nicht schreibbar!" "dontlog"
fi

if [ ! -f "$LOGDETAILSFILE" ] ; then
 error "Log-Details nicht schreibbar!" "dontlog"
fi

if ! [[ $FILENAME =~ ^backup2scp-.*.zip ]] ; then
 error "Keine gueltige Datei zum Download angegeben!"
fi

if ! [[ $UNZIPSCOPE =~ ^unzip ]] ; then
 error "Keinen gueltigen Import-Umfang angegeben!"
fi

if ! [[ $SANDBOX =~ $VALIDSANDBOXES ]] && ! [[ $SANDBOX =~ ^LIVE$ ]]; then
 if [ "$UNZIPSCOPE" = "unzipAllAndImportSQL" ] || [ "$UNZIPSCOPE" = "unzipSQLAndImportSQL" ] ; then
  error "Keine gueltige Sandbox fuer den Import angegeben!"
 fi
fi

if [ -f sandboximport.lock ] ; then
 error "Import laeuft bereits! Oder vergangener Import abgebrochen! Erst \"Abbrechen\" oder Lock-File loeschen!"
fi

# Locks frueh etablieren, um Monitore zuvorzukommen
touch sandboximport.lock

if [ ! -f sandboximport.lock ] ; then
 error "Restore-Verzechnis nicht schreibbar!"
fi

if [ -d $UNZIPFOLDER ] && [[ $UNZIPSCOPE =~ ^unzipAll* ]] && ! [ "$QUICKER" = "skipFTPandUNZIP" ] ; then
  touch deletezipfolder.lock
fi

# ! $server
if [ -f $BACKUPFOLDER"/backup2scp-<MeineDomain>-live_FROM_"$FILENAME".sql" ] && [[ $UNZIPSCOPE =~ ^unzipSQL* ]] && ! [ "$QUICKER" = "skipFTPandUNZIP" ] ; then
  touch deleteSQL.lock
fi

touch "$BACKUPFOLDER/writetest"

if [ ! -f "$BACKUPFOLDER/writetest" ] ; then
 error "Backup-Verzeichnis nicht schreibbar!"
else
 rm "$BACKUPFOLDER/writetest"
fi



#########################
##### SCP-DOWNLOAD ######

if [ "$QUICKER" = "skipFTP" ] && [ -f "$BACKUPFOLDER/$FILENAME" ] || [ "$QUICKER" = "skipFTPandUNZIP" ] && [ -f "$BACKUPFOLDER/$FILENAME" ] ; then
  log_details "OK: $BACKUPFOLDER/$FILENAME existiert."
  log_nomail "Ueberspringe SCP-Download."
else
 
 if [ "$QUICKER" = "skipFTP" ] || [ "$QUICKER" = "skipFTPandUNZIP" ] ; then
  log "Ueberspringe SCP-Download NICHT! Datei fehlt noch!"
  QUICKER=""
 fi
 
 if [ ! -f ../../scp.conf ] ; then
  error "SCP-Konfigurationsdatei scp.conf fehlt!"
 fi

 . ../../scp.conf
 
 if [ -z "$SERVER_STRATO" ] || [ -z "$USER_STRATO" ] || [ -z "$PATH_STRATO" ] ; then
  error "SCP-Zugangsdaten unvollstaendig in scp.conf!"
 fi
 
 log "Starte SCP-Download von $FILENAME..."

/usr/bin/scp $USER_STRATO@$SERVER_STRATO:"$PATH_STRATO$FILENAME" "$BACKUPFOLDER/$FILENAME"

 if [ ! -f "$BACKUPFOLDER/$FILENAME" ] ; then
  error "ZIP-Datei konnte nicht heruntergeladen/geschrieben werden!"
 fi

 log_nomail "Ende des SCP-Downloads."

fi

#################################
##### UNZIP backup archive ######


if [ "$QUICKER" = "skipFTPandUNZIP" ] && [[ $UNZIPSCOPE =~ ^unzipAll* ]] && [ -d $UNZIPFOLDER ] ; then
 
 log_details "OK: $UNZIPFOLDER exisitert bereits."
 log_nomail "Ueberspringe Unzip."
 
# ! $server 
elif [ "$QUICKER" = "skipFTPandUNZIP" ] && [[ $UNZIPSCOPE =~ ^unzipSQL* ]] && [ -f $BACKUPFOLDER"/backup2scp-<MeineDomain>-live_FROM_"$FILENAME".sql" ] ; then

 log_details "OK: "$BACKUPFOLDER"/backup2scp-$SERVER-live_FROM_"$FILENAME".sql existiert bereits."
 log_nomail "Ueberspringe Unzip."

else # DON'T SKIP UNZIP 
 
 if [ "$QUICKER" = "skipFTPandUNZIP" ] ; then
  log "Ueberspringe Unzip NICHT! Ordner bzw. Datei fehlt noch!"
  QUICKER=""
 fi
 
 log "Start Unzip $FILENAME ..."

 # Integritaet testen - dauert zu lange...
 # zip -T $ZIPFILE 

 if [ -d $UNZIPFOLDER ] && [[ $UNZIPSCOPE =~ ^unzipAll* ]] ; then
  log_nomail "Loesche bereits bestehenes Zip-Verzeichnis ..."
  chmod -R 777 $UNZIPFOLDER
  rm -rf $UNZIPFOLDER
  rm deletezipfolder.lock
 fi

 if [ -f $BACKUPFOLDER"/backup2scp-$SERVER-live_FROM_"$FILENAME".sql" ] && [[ $UNZIPSCOPE =~ ^unzipSQL* ]] ; then
  log_nomail "Loesche bereits bestehende SQL-Datei ..."
  chmod 777 $UNZIPFOLDER"/"$IMPORTSQLFILE
  rm -f $UNZIPFOLDER"/"$IMPORTSQLFILE
  rm -f deleteSQL.lock
 fi
 
 if [ "$UNZIPSCOPE" = "unzipAll" ] ; then
 
  log_details "Erstelle Verzeinis: $UNZIPFOLDER"
  mkdir $UNZIPFOLDER
  
  log_nomail "Entpacke alle Dateien im Zip-Archiv ..."
 
  # uncomment -q for more info
  unzip -q $ZIPFILE -d $UNZIPFOLDER 2>> $LOGDETAILSFILE
  
  if [ $? -ne 0 ]; then
   error "Der Befehl: unzip -q $ZIPFILE -d $UNZIPFOLDER endete mit einem Fehler!";
  fi;
 
  if [ ! -d $UNZIPFOLDER"/<wwwFolder>" ] ; then
   error "ZIP-Datei konnte nicht entpackt werden oder falsche ZIP-Datei gewaehlt!"
   rmdir $UNZIPFOLDER
  fi

 elif [ "$UNZIPSCOPE" = "unzipAllAndImportSQL" ] ; then

  log_details "Erstelle Verzeinis: $UNZIPFOLDER"
  mkdir $UNZIPFOLDER
  
  log_nomail "Entpacke alle Dateien im Zip-Archiv ..."
  
  # uncomment -q for more info
  unzip -q $ZIPFILE -d $UNZIPFOLDER 2>> $LOGDETAILSFILE
  
  if [ $? -ne 0 ]; then
   error "Der Befehl: unzip -q $ZIPFILE -d $UNZIPFOLDER endete mit einem Fehler!";
  fi;
 
  if [ ! -d $UNZIPFOLDER"/<wwwFolder>" ] ; then
   error "ZIP-Datei konnte nicht entpackt werden oder falsche ZIP-Datei gewaehlt!"
   rmdir $UNZIPFOLDER
  fi
 
  if [ ! -f $UNZIPFOLDER"/"$IMPORTSQLFILE ] ; then
   error "SQL-Datei $UNZIPFOLDER"/"$IMPORTSQLFILE nicht in Zip-Archiv enthalten bzw. falsche ZIP-Datei gewaehlt!"
   rmdir $UNZIPFOLDER
  fi
 
 elif [ "$UNZIPSCOPE" = "unzipSQL" ] || [ "$UNZIPSCOPE" = "unzipSQLAndImportSQL" ] ; then

  log_nomail "Entpacke nur die SQL-Datei ..."
  # ! $SERVER
  unzip -p $ZIPFILE $IMPORTSQLFILE > $BACKUPFOLDER"/backup2scp-<MeineDomain>-live_FROM_"$FILENAME".sql" 2>> $LOGDETAILSFILE
  
  if [ $? -ne 0 ]; then
  # ! $SERVER
   error "Der Befehl: unzip -p $ZIPFILE $IMPORTSQLFILE > $BACKUPFOLDER"/backup2scp-<MeineDomain>-live_FROM_"$FILENAME".sql" endete mit einem Fehler!";
  fi;
 
  # ! $SERVER
  if [ ! -f $BACKUPFOLDER"/backup2scp-<MeineDomain>-live_FROM_"$FILENAME".sql" ] ; then
   error "SQL-Datei konnte nicht aus ZIP-Archiv extrahiert werden oder falsche ZIP-Datei gewaehlt!"
   rmdir $UNZIPFOLDER
  fi
 
 else
 
  error "Unzip-Error: Ungueltiger Importumfang angegeben ..."
 
fi

 log_nomail "Ende Unzip $FILENAME ..."
 
fi # Ende: IF skipFTPandUnzip



#############################
##### IMPORT SQL to DB ######

# Dieser Block muss separat bleiben, falls Unzip uebersprungen wurde
if [ "$UNZIPSCOPE" = "unzipAllAndImportSQL" ] || [ "$UNZIPSCOPE" = "unzipSQLAndImportSQL" ] ; then
 
 log "Starte Import von '$IMPORTSQLFILE' in die $SANDBOX ..."
 
 dumpDatabases
 
 if [ "$UNZIPSCOPE" = "unzipAllAndImportSQL" ] ; then
  importIntoDatabase $UNZIPFOLDER"/"$IMPORTSQLFILE
 elif [ "$UNZIPSCOPE" = "unzipSQLAndImportSQL" ] ; then
  # ! $SERVER
  importIntoDatabase $BACKUPFOLDER"/backup2scp-<MeineDomain>-live_FROM_"$FILENAME".sql"
 fi
 
 log_nomail "Import in die $SANDBOX abgeschlossen!"

fi

##### Ende: IMPORT SQL to DB ######
###################################

if [ -f sandboximport.lock ] ; then
 rm sandboximport.lock
fi

END=$(date +%s)
DIFF=$(( $END - $START ))

if [ $DIFF -lt 120 ] ; then
  DIFF="$DIFF Sekunden."
else
 DIFF=$(( $DIFF / 60 ))
 DIFF="$DIFF Minuten."
fi

log "Import-Ende. // Dauer des Vorgangs: $DIFF"
# log_nomail "--------------------------------------------------------"

# scheint sicherer auch zu resetten:
echo "" > logs/importToDB.log

echo "Done."