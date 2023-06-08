<?php
 
 $logfile = isset($_GET['logfile']) ? "logs/".urldecode($_GET['logfile']) : '';
 
 if(file_exists($logfile)) {
  
   if(filesize($logfile) < 8) {
    echo(json_encode(array("percent"=>htmlentities(utf8_encode("0"))))); // Import wurde zuvor erfolgreich abgeschlossen und logfile geleert...
    die();
   }
   
   # Import laeuft
    
   $percent = trim(exec("grep -o '.................$' ".$logfile." | grep -o '^...'"));
    
   echo( json_encode(array( "percent"=>htmlentities(utf8_encode($percent)))) );
   
 } else {
  echo( json_encode(array( "Error"=>"DB-Import-Log ".htmlentities($log)." existiert nicht!")) );
 }
 
?>