<?php

$logfile = isset($_GET['logfile']) ? $_GET['logfile'] : '';
$logfile = "logs/" . trim(urldecode( $logfile ));
 
 // Nur starten...
 exec("shellscripts/monitorImportProcess.sh ".$logfile." &");
 
?>