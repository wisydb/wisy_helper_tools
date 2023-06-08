<?php 

// Dieses Skript in PHP <= 7.4 aufrufen
// $erlaubteDomains setzen!

error_reporting(E_ALL);
ini_set('display_errors', '1');
ini_set('display_startup_errors', 1);

require_once("admin/sql_curr.inc.php");
require_once("admin/config/config.inc.php");
require_once("admin/lib/g/bin.inc.php");   // Klasse des serialisierten Objekts

$erlaubteDomains = array( '...info', 'sandbox....info' ); 

if( !in_array($_SERVER[ 'SERVER_NAME' ], $erlaubteDomains ) )
    die("Falsche Domain.");
else
    echo "Domain OK: " . $_SERVER[ 'SERVER_NAME' ] .  "<br><br>";

echo "<h1>PHP-Version: " . phpversion() . "</h1><br>";

global $remembered;
$remembered = array();

$db_read = new DB_Admin;
$sql = "SELECT id, remembered FROM user";

echo "<b>SQL:<br>" . $sql . "</b><hr>";

$db_write = new DB_Admin;

$db_read->query( $sql );

if( intval($phpversion) < 8 ) {

    while( $db_read->next_record() ) {
        
        echo "<h2>" . $sql . " WHERE id = " . $db_read->f('id') . "</h2>"; 
        
        $remembered = $db_read->fs('remembered');
        // echo $remembered . "<br><br>";     
      
        echo "<br><hr><br>";
      
        $remembered = unserialize( $remembered );
      
        if( isset($remembered->db) )
            unset($remembered->db);
        else 
            echo "DB not set.<br>";
        
        // echo "<pre>"; print_r( $remembered ); echo "</pre><br><br><hr>"; 
            
        $updateSql = "UPDATE user SET remembered = '" . serialize( $remembered ) . " ' WHERE id = " . $db_read->f('id');
        $db_write->query( $updateSql ) ;
                
    } // end: while
    
} else {
    die( "<b>PHP-Version >= 8. Keine Operation ausgef&uuml;hrt!</b>" );
}
    
echo "<b>Done.</b>";

?>