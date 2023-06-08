<?php

 $filename = isset($_GET['filename']) ? $_GET['filename'] : '';
 
 if(trim($filename) != "" && file_exists("tmpbackups/".$filename)) {
  clearstatcache();
  $bytes = exec('stat --printf="%s" tmpbackups/'.$filename);
  
  echo(json_encode(array("bytes"=>$bytes)));
  
 } else {
  die(json_encode(array("error"=>"Datei exisitert nicht.")));
 }
 
?>