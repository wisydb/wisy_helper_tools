<?php

 $logfile = isset($_GET['logfile']) ? $_GET['logfile'] : '';
 $logfile = "logs/".urldecode($logfile);
 
 $logdetailsfile = isset($_GET['logdetailsfile']) ? $_GET['logdetailsfile'] : '';
 $logdetailsfile = "logs/".urldecode($logdetailsfile);
 
 
 if(file_exists($logfile) && file_exists($logdetailsfile)) {
  $log = file_get_contents($logfile);
  $logdetails = file_get_contents($logdetailsfile);
  
  echo(json_encode(array("log"=>htmlentities(utf8_encode($log)),
                         "logdetails"=>htmlentities(utf8_encode($logdetails))
                        )));
 } else {
  echo(json_encode(array("Error"=>"Log-Datei oder Log-Details-Datei ".htmlentities($filename)." existiert nicht!")));
 }
 
?>