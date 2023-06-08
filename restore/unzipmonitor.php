<?php
  
 $backup_path   = "tmpbackups/";
 $filename_raw  = isset($_GET['filename']) ? urldecode($_GET['filename']) : '';
 $filename      = $backup_path.$filename_raw;
 $unzipscope    = isset($_GET['unzipscope']) ? $_GET['unzipscope'] : '';
 
 $getTargetFileSize     = isset($_GET['getTargetFileSize']) ? $_GET['getTargetFileSize'] : null;
 $getCurrentFileSize    = isset($_GET['getCurrentFileSize']) ? $_GET['getCurrentFileSize'] : null;
 
 $server = "<MeineDomain>";
 
 if(file_exists($filename)) {
  
  if(   $getTargetFileSize && $unzipscope == "unzipAll"
     || $getTargetFileSize && $unzipscope == "unzipAllAndImportSQL") {
   
   $targetFilesize = exec("unzip -l ".$filename." | sed -e 1b -e '$!d' | grep -v Archive | awk {'print$1'}");
   echo(json_encode(array("targetFilesize"=>htmlentities(utf8_encode($targetFilesize)))));
   
  } else if(   $getCurrentFileSize && $unzipscope == "unzipAll"
            || $getCurrentFileSize && $unzipscope == "unzipAllAndImportSQL") {
   
   // Loeschvorgang dauert noch an...
   if(file_exists("deletezipfolder.lock") || file_exists("deleteSQL.lock"))
    die(json_encode(array("unzipedBytes"=>"0")));
   
   $unzipedKBytes = exec("du -s ".$filename."_unziped | sed -e 1b -e '$!d' | grep -v _unziped/ | awk {'print$1'}");
   $unzipedBytes = $unzipedKBytes*1024; //
   echo(json_encode(array("unzipedBytes"=>htmlentities(utf8_encode($unzipedBytes)))));
   
  } else if(   $getTargetFileSize && $unzipscope == "unzipSQL"
            || $getTargetFileSize && $unzipscope == "unzipSQLAndImportSQL") {
   
   $targetFilesize = exec("unzip -l ".$filename." | grep \"backup2scp-".$server."-live.sql$\" | awk {'print$1'}");
   echo(json_encode(array("targetFilesize"=>htmlentities(utf8_encode($targetFilesize)))));
   
  } else if(   $getCurrentFileSize && $unzipscope == "unzipSQL"
            || $getCurrentFileSize && $unzipscope == "unzipSQLAndImportSQL") {
   
   // Loeschvorgang dauert an
   if(file_exists("deletezipfolder.lock"))
    die(json_encode(array("unzipedBytes"=>"0")));
      
   $unzipedBytes = exec("ls -l ".$backup_path."backup2scp-".$server."-live_FROM_".$filename_raw.".sql | awk {'print$5'}");
   echo(json_encode(array("unzipedBytes"=>htmlentities(utf8_encode($unzipedBytes)))));
   
  } else {
   echo(json_encode(array("Error"=>"Dateityp existiert nicht!")));
  }
  
 } else {
  echo(json_encode(array("Error"=>"Zip-Datei ".htmlentities($filename)." existiert nicht!")));
 }
 
?>