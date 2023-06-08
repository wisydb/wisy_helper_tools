<?php

$liveimportpwd  = isset($_GET['liveimportpwd'])     ? trim(urldecode($_GET['liveimportpwd'])) : '';
$ftpFilename    = isset($_GET['ftpFilename'])       ? trim(urldecode($_GET['ftpFilename']), "./") : '';
$email          = isset($_GET['email'])             ? str_replace(" ", "", trim(urldecode($_GET['email']))) : '';
$logfile        = isset($_GET['logfile'])           ? trim(urldecode($_GET['logfile'])) : '';
$logdetailsfile = isset($_GET['logdetailsfile'])    ? trim(urldecode($_GET['logdetailsfile'])) : '';
$unzipscope     = isset($_GET['unzipscope'])        ? trim(urldecode($_GET['unzipscope'])) : '';
$sandbox        = isset($_GET['sandbox'])           ? trim(urldecode($_GET['sandbox'])) : '';
$quicker        = isset($_GET['quicker'])           ? trim(urldecode($_GET['quicker'])) : null;
$html           = isset($_GET['html'])              ? trim(urldecode($_GET['html'])) : '';

// Ueberpruefung der Variablen auf Sinnhaftigkeit erfolgt im Shellscript, somit besser separat nutzbar (cronjobfaehig)...

$command = 'shellscripts/downloadAndImportSQLtoSandbox.sh'
           .' "'.$liveimportpwd.'" "'.$ftpFilename.'" '.$email.' "'.$logfile.'" "'.$logdetailsfile.'" '.$unzipscope.' "'.$sandbox.'" '.$quicker." ".$html;

if(trim($ftpFilename) == "") {
 die("<div class='error'>Error: Es wurde kein g&uuml;ltiger Dateiname angefordert!</div>");
} else {
 
 echo "<br>"; flush(); // timeout verhindern...
 
 if(file_exists("sandboximport.lock"))
  die("<div class='error'>Error: Import-Vorgang bereits im Gang! GGf. \"Abbruch-Button\" verwenden!</div>");
 
 $output = array();
 $return_status = "OK";

 exec($command); //, $output, $return_status
 
 /* Den Ouput von exec aufzuzeichnen sprengt den Speicher (und wird dann erst am Ende des Programms ausgegeben)
  * 
  * $ouput_log = "";
 
 foreach($output AS $line) {
  $ouput_log .= $line."\n";
 }
 
 $ouput_log .= "Befehl beendete mit Status: ".$return_status."\n";
 
 if($return_status > 0)
  $ouput_log .= "<div class='error'>Error: Import-Programm wurde irregul&auml;r beendet!</div>\n";
  
 echo($ouput_log);
 
 // Zusaetzlicher Output, der nicht durch das Shellscript geloggt wird, wie Warnungen..
 file_put_contents("logs/".str_replace(".log", ".details.log", $logfile), $ouput_log);
 
 */
}
        
?>