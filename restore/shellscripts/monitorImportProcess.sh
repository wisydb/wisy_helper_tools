# nur fuer separaten Aufruf (Webpage oder per Hand)

LOGFILE=$1

check_process(){
        
 if [ "$1" = "" ];
  then
    return 0
  fi

 #PROCESS_NUM => get the process number regarding the given thread name
 PROCESS_NUM=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
 
 NOW=$(date +"%d.%m.%Y %H:%M")
 
 if [ $PROCESS_NUM -eq 1 ] ;
  then
   return 1
 elif [ -z "$PROCESS_NUM" ] || [ $PROCESS_NUM -eq 0 ] ; then
   echo "[$NOW] Prozess beendet." >> $LOGFILE 
   exit 0
 else
  # Ggf. Sinnlos
  ps -ef | grep "$1" | grep -v "grep" >> $LOGFILE
  # shellscripts/abbruch.sh
  exit 0
 fi
}

# check wheter the instance of thread exsits
while [ 1 ] ; do

 echo "begin checking... ("$LOGFILE")"

 check_process "downloadAndImportSQLtoSandbox.sh" # the thread name
 
 sleep 30

done