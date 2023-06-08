<?php

	$sftpServerIP = "<sftp.example.com>";
    $sftpUser = "<user>";
    $sftpCD = "<path>";
    
    $ssh_pubkey     = '[...]/.ssh/id_rsa.pub';
    $ssh_privkey    = '[...]/.ssh/id_rsa';
    
    $logfile           = urlencode("import-".date("Y-m-d-H-i-s").".log");
	$logdetailsfile    = urlencode("import-".date("Y-m-d-H-i-s").".details.log");
	$logDBImportfile   = "importToDB.log";
    
    $server = "<MeineDomain>";
    // ! $server = "<DistServer>";
	
    function sftp_connect($sftpServerIP, $sftpUser, $ssh_pubkey, $ssh_privkey) {
        $connection = ssh2_connect($sftpServerIP, 22, array('hostkey'=>'ssh-rsa'));
        
        // Auf <sftpServer> (und <DistServer>) ist ein entsprechender Key hinterlegt.
        // Eine Anmeldung mit Passwort sollte also nicht nötig sein.
        if ( !ssh2_auth_pubkey_file($connection, $sftpUser, $ssh_pubkey, $ssh_privkey, 'secret') )
            die('Public Key Authentication fehlgeschlagen!');
        
        return ssh2_sftp($connection);
    }
    
?>
<!DOCTYPE html>
<html lang="de">

    <head>
        <title>Backup-SQL -> Sandbox</title>
        <link rel="shortcut icon" type="image/ico" href="/restore/favicon.ico" />
        <script type="text/javascript" src="/admin/lib/jquery/js/jquery-1.10.2.min.js"></script>
        <link rel="stylesheet" href="/restore/css/jquery-ui.css">
        <script src="/restore/js/jquery-ui.js"></script>
        <link rel="stylesheet" href="/restore/css/style.css">
        
        <script type="text/javascript">
            var logfile			= "<?php echo $logfile; ?>";
    		var logdetailsfile	= "<?php echo $logdetailsfile; ?>";
    		var logDBImportfile = "<?php echo $logDBImportfile; ?>"; 
        </script>
        <script src="/restore/js/restore.js"></script>
    </head>

    <body>
        <div id="wrapper">
            <noscript>
                <h1>STOP: Sie m&uuml;ssen Javascript aktivieren!</h1>
            </noscript>
            <div id="head_wrapper">
                <!--  <img src="/files/fernglas.gif" alt="Suche" /> -->
                <div id="kopf_logo"><div id="hamburg">Server</div><div id="aktiv">2</div></div>
                <input type="submit" onclick="abbruch();" value="Abbrechen!" id="abbruch">
            </div>
            <h1><span class="server2">MeineDomain.abc</span>-Live-Backup &rarr; <span id="importTargetText"><span class="server2">MeineDomain.abc</span>-Sandbox</span></h1>
            <hr>    
            <?php
                
                echo "Initialisiere SFTP-Verbindung...<br>";
                
                $sftp_conn = sftp_connect($sftpServerIP, $sftpUser, $ssh_pubkey, $ssh_privkey);
                
                echo "Verbindung erfolgreich hergestellt.<br>";
                
                $path = "ssh2.sftp://".$sftp_conn."/".$sftpCD;
                
                echo "Lese Verzeichnis: ".$path."<br>";
                
                $handle = opendir($path);
                
                if( !$handle )
                    die("Fehler: kann Verzeichnis nicht einlesen!")
                
            ?>
            <small><span style="font-family: 'Courier New', monospace;">Ctrl+l</span> f&uuml;r <a href='#' onclick='$("#liveoption").show();'>LIVE-Option.</a><hr></small>
            E-Mailadresse zur Statusbenachrichtigung:<br>
            <input type="text" id="email" name="email" onkeyup="showElements();" onblur="showElements();" onclick="showElements();" onfocus="showElements();">
            <div id="forms">
                <hr>
        		<?php
                    $relevant_backups = array();
                    while (false != ($filename = readdir($handle))){
                        if(preg_match("/^backup2scp-".$server.".*.zip$/", $filename)) {
                            array_push($relevant_backups, $filename);
                        }
                        
                    }									    
        																					
        			$zipCnt = count($relevant_backups);
        			$displayzips = 10;
        																
        			if(  isset( $_GET['displayzips'] ) && $_GET['displayzips'] > 0 )
        			 $displayzips = $_GET['displayzips'];
        																
        			echo "<input type='checkbox' id='switchAllBackups' onclick='switchAllBackups();'> <span style='font-size: 10px;'>Alle ".$zipCnt." Backups anzeigen!</span>";
        		?>
        		<br>
                <select name="ftpFilename" id="ftpFilename" onchange="evalSelects()">
                    <option value="">Backup w&auml;hlen...</option>
                    <?php
        				$cnt = 0;
        				asort( $relevant_backups );
                        foreach($relevant_backups AS $filename) {
        				    $cnt++;
        																				
        					if(preg_match("/^backup2scp-".$server.".*.zip$/", $filename)) {
        					   // $response =  ftp_raw($ftpConnection, "SIZE $filename"); 
        					    $filestats = ssh2_sftp_stat($sftp_conn, $sftpCD."/".$filename); // floatval(str_replace('213 ', '', $response[0]));  // file size in bytes > 32-bit int max. value of: 2147483647
        					    $filesize =  $filestats['size'];
        		              ?>
        						<?php /* einzeilig belassen: */ ?>                         
        						<option value="<?php echo urlencode($filename); ?>" data-filesize="<?php echo $filesize; ?>" class="<?php if($cnt <= ($zipCnt - $displayzips)) { echo "tooMuch skipBackup"; } ?>" ><?php echo trim($filename, "./")." - ".number_format(($filesize/1000000000), 2, ',', '')."GB"; ?></option>
        					  <?php
        					} /* end: if */
                        } /* end: foreach */
                    ?>
                </select>
                <br><br>
                <select id="unzipscope" name="unzipscope" onchange="evalSelects()">
                    <option value="">Nach dem Download:</option>
                    <option value="unzipSQLAndImportSQL">Nur SQL entpacken und importieren!</option>
                    <option value="unzipAllAndImportSQL">Gesamte Zip-Datei entpacken und Live-SQL importieren!</option>
                    <option value="unzipSQL">Nur SQL entpacken, nichts importieren...</option>
                    <option value="unzipAll">Gesamte Zip-Datei entpacken, nichts imporieren...</option>
                </select>
                
                <div id="sandboxchoicecontainer">
                    <span id="arrow">&rarr;&nbsp;&nbsp;</span>
                    <select id="sandbox" name="sandbox" onchange="evalSelects()">
                      <option value="">Sandbox w&auml;hlen...</option>
                      <option value="<?php echo(urlencode('Sandbox 1')); ?>">Sandbox 1</option>
                      <option value="<?php echo(urlencode('Sandbox 2')); ?>">Sandbox 2</option>
                      <option value="<?php echo(urlencode('Sandbox 3')); ?>">Sandbox 3</option>
                      <option value="<?php echo(urlencode('Sandbox 4')); ?>">Sandbox 4</option>
                      <option value="<?php echo(urlencode('Sandbox 5')); ?>">Sandbox 5</option>
                      <option value="<?php echo(urlencode('Sandbox 6')); ?>">Sandbox 6</option>
                      <option value="<?php echo(urlencode('Sandbox 7')); ?>">Sandbox 7</option>
                      <option value="<?php echo(urlencode('Sandbox 8')); ?>">Sandbox 8</option>
                      <option value="<?php echo(urlencode('Sandbox 9')); ?>">Sandbox 9</option>
                      <option value="<?php echo(urlencode('Sandbox 10')); ?>">Sandbox 10</option>
        			  <option value="<?php echo(urlencode('Sandbox 99')); ?>">Sandbox 99</option>
                      <option value="<?php echo(urlencode('LIVE')); ?>" id="liveoption">LIVE!</option>
                    </select>
                </div>
                
                <br><br>
                
                <select id="quicker" name="quicker">
                    <option value="">Import beschleunigen...</option>
                    <option value="skipFTP">FTP-Download &uuml;berspringen!</option>
                    <option value="skipFTPandUNZIP">FTP-Download und Unzip &uuml;berspringen!</option>
                </select>
                
                <br><br>
                        
                <input id="startImport" type='submit' value='Import starten!' onclick='startImport();' onmouseover="evalSelects()">
                <div id="monitors">
                    <pre><b>Download-Monitor</b><br><div id="download_monitor"></div><br><b>Unzip-Monitor</b><br><div id="unzip_monitor"></div><span id="dbmonitorlabel"><br><b>DB-Import-Monitor</b><br><span style="font-size: 10px">Es ist normal, wenn es zwischendurch mal ca. 15min. "einfriert" / dauern kann. Das sind die Geodaten.<br>Wenn sofort 100% oder am Ende 0% angezeigt werden: alles i.O. Trotzdem warten, bis Blinklicht blau und Protokoll "Fertig" anzeigt.</span></span><br><div id="dbimport_monitor"></div><br><br></pre>
                    <pre><b>Log</b> <span id="log_time"></span><div class="led-red"></div><div class="led-yellow"></div><div class="led-green"></div><div class="led-blue"></div><div id="log_monitor"></div><div id="misc"></div><br><b>Details und sonstiger Output (Warnungen etc.)</b> <br><div id="live_output"></div></pre>
                </div>
            </div>
        </div>
    </body>