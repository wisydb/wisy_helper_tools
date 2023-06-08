<?php

$logfile = isset($_GET['logfile']) ? $_GET['logfile'] : '';
$logfile = trim(urldecode( $logfile ));

$output = exec("shellscripts/abbruch.sh ".$logfile);

echo( json_encode( array("output"=>$output) ) );
 
?>
