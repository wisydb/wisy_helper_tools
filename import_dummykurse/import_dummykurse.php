<?php

// Ein WISY-Testsystem mit Dummy-Kurs- und Durchfuehrung-Daten fuellen
// allow_url_fopen muss in php.ini erlaubt sein

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// 1000 Kurse generieren samt Durchfuehrungen. 
// Auf sehr gutem Server: ca. 1000 Aufrufe / min
$dummy_kurs_anz = 1000;

define( 'apikey', '<REST apikey>' );
define( 'client', 'Dummydaten' );
define( 'zugangsdaten', '' );
define( 'domain', '<Testportal-Domain>' );

define( 'anbieter', 0 );                    // DummyAnbieter-ID

define( 'user_created', 0 );                // WISY-User-ID
define( 'user_modified', 0 );               // WISY-User-ID
define( 'user_grp', 0 );                    // WISY-User-Grp
define( 'user_access', 504 );               // lesen fuer dritte ermoeglichen

define( 'strasse', 'Hauptstraße 1' );
define( 'ort', 'Hamburg' );
define( 'plz', 20095 );

// Alle Themen-IDs (nicht Kuerzel) im Test-System
// Koennte man besser auch dynamisch abrufen.
$themen         = array( "1", "2", "3", "5", "6", "7", "8", "9", "10" );
$randomIndex    = rand(0, count($themen)-1);
define( 'thema', $themen[$randomIndex] );

// Alle Stichwoerter-IDs (nicht Kuerzel) im Test-System
// Koennte man besser auch dynamisch abrufen.
$stichwoerter   = array( "1", "2", "3", "5", "6", "7", "8", "9", "10" );

// Beginn-/Ende-Minutenauswahl
$minuten        = array( "10", "20", "30", "40", "50" );

// Terminoptionen-Auswahl
$beginnOptionen = array( 1, 2, 4, 8, 16, 32, 64, 256, 512 );      


echo "Start: ".date("h:i:s d.m.Y")."<hr>";


// Kurs erstellen:

$url_kurs = 'https://'.zugangsdaten.domain.'/api/v1/?scope=kurse&apikey='.apikey.'&client='.client;

for($i = 1; $i < $dummy_kurs_anz; $i++) {

 $randOpt = rand(1, 7);

 $data = array(
  'user_grp'        => user_grp,
  'user_access'     => user_access,
  'user_created'    => user_created, 
  'user_modified'   => user_modified,
  'titel'           => ucfirst(getRandomWord()) . " " . getRandomWord() . " " . getRandomWord(),
  'org_titel'       => $randOpt == 1 ? ucfirst(getRandomWord()) . " " . getRandomWord() . " " . getRandomWord() : '',
  'freigeschaltet'  => rand(0,4),
  'thema'           => thema,
  'stichwoerter'    => $stichwoerter[rand(0, count($stichwoerter)-1)].",".$stichwoerter[rand(0, count($stichwoerter)-1)].",".$stichwoerter[rand(0, count($stichwoerter)-1)],
  'beschreibung'    => getRandomText(),
  'anbieter'        => anbieter,
  'notizen'         => date("d.m.y") . ": " . ucfirst(getRandomWord()) . " " . getRandomWord() . " " . getRandomWord(),
  'notizen_fix'     => "Allgemeiner interner Hinweis.",
  'bu_nummer'       => $randOpt == 2 ? "".rand(1,10000)."" : '',
  'fu_knr'          => $randOpt == 3 ? "FU".rand(1,10000)."" : '',
  'azwv_knr'        => $randOpt == 4 ? "".rand(1,10000)."" : '',
 );	

 
 // use key 'http' even if you send the request to https://...
 $options = array(
    'http' => array(
        'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
        'method'  => 'POST',
        'content' => http_build_query($data)
    )
 );
 $context  = stream_context_create($options);


 $result = file_get_contents($url_kurs, false, $context);

 if ($result === FALSE) { 
  echo "Fehler:<br>";
  echo "URL:".$url_kurs."<br>";
  echo "Context:<br>"; print_r($options);
 } 

 $result = json_decode($result, true);
 

 // Durchfuehrung erstellen, falls Kurs angelegt werden konnte:

 if( isset($result['id']) && $result['id']) {
    $randOpt = rand(1, 7);
     
 	$url_df = 'https://'.zugangsdaten.domain.'/api/v1/?scope=kurse.'.$result['id'].'&apikey='.apikey.'&client='.client;
 
 	$randomIndex = rand(0, count($minuten)-1);
 	
 	$min_beginn = $minuten[rand(0, count($minuten)-1)];
 	$min_ende = $minuten[rand(0, count($minuten)-1)];
 	
 	$protocol = 'https';
 	$domain = generateRandomString(5) . '.com';
 	$path = generateRandomString(10);
 	
 	$url = $protocol . '://' . $domain . '/' . $path;
 	
 	$df_data = array(
   		'user_created'     => user_created,
   		'user_modified'    => user_modified,
   		'user_grp'         => user_grp,
   		'user_access'      => user_access,
 	    'nr'               => rand(1,30000)."-".lcfirst(getRandomWord()),
   		'stunden'          => rand(1,30),
  	 	'teilnehmer'       => rand(1,30),
   		'preis'            => rand(1,300),
 	    'preishinweise'    => ucfirst(getRandomWord()).' '.getRandomWord().' '.getRandomWord().' '.getRandomWord(),
 	    'beginn'           => $randOpt != 5 ? (intval(date('Y'))+1)."-".rand(6,9) ."-". rand(1,30)." ".rand(7,20).":".$min_beginn.":00" : '',
 	    'ende'             => (intval(date('Y'))+1)."-".rand(10,12) ."-". rand(1,30)." ".rand(7,20).":".$min_ende.":00",   		
 	    'zeit_von'         => rand(7,12) .":". $min_beginn,
 	    'zeit_bis'         => rand(13,22) .":". $min_ende,	    
	    'kurstage'         => rand(1,50),	    	    
	    'strasse'          => strasse,	 
 	    'stadtteil'        => ucfirst(getRandomWord()),
	    'plz'              => plz,
	    'ort'              => ort,
 	    'url'              => $url,
   		'bemerkungen'      => "Irgendeine Bemerkung zu Teilnehmerzahl, Preisstruktur o. ä.",
 	    'beginnoptionen'   => $randOpt == 5 ? $beginnOptionen[rand(0, count($beginnOptionen)-1)] : '',
 	    'rollstuhlgerecht' => rand(0,1),
 	    'herkunft'         => rand(0,20),
 	    'herkunftsID'      => rand(1,30000)."-".lcfirst(getRandomWord()),
 	    
 	);	
 
	$df_options = array(
    	'http' => array(
        	'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
	        'method'  => 'POST',
    	    'content' => http_build_query($df_data)
    	)
 	);
 	
	$df_context  = stream_context_create($df_options);
 	$df_result = file_get_contents($url_df, false, $df_context);

 	if ($df_result === FALSE) { 
  		echo "Fehler:<br>";
  		echo "URL:".$url_df."<br>";
		  echo "Context:<br>"; print_r($df_options);
 	}
 	
 	$df_result = json_decode($df_result, true);
 
	if( isset($df_result['id']) && $df_result['id'])
 		echo $result['id']."->".$df_result['id'].", ";  
 	

 } // end: if kurs eingefuegt
 

} // end: for

echo "<br><br><hr>Done: ".date("h:i:s d.m.Y");


// Text aus 20-40 Worten von getRandomWord() generieren + alle 1-15 Woerter zwei Line Feeds
function getRandomText() {
    $length = rand(20, 40);
    $randomText = "";
    
    for($i = 0; $i < $length; $i++) {
        $upperCaseWord = rand(1, 15);
        $randomText .= getRandomWord()." ";
        if( $upperCaseWord == 10 )
            $randomText .= "\n\n";
    }
    
    return $randomText;
}

// Wort generieren, das wie ein echtes Wort wirkt aus 3-10 Buchstaben. Manche mit großem Anfangsbuchstaben.
function getRandomWord() {
    $length         = rand(3, 10);
    $upperCaseWord  = rand(1, 2);
    $consonants     = 'bdfghjklmnprstvwz'; // consonants except hard to speak ones
    $vowels         = 'aeiou'; // vowels
    $word           = ''; // this will hold the generated word
    
    for ($i = 0; $i < $length; $i++) {
        // Konsonanten und Vokale abwechseln, um aussprechbare Woerter zu generieren
        if ($i % 2 == 0) {
            // Gerade Zahl (inkl. 0): beliebigen Konsonanten ergaenzen
            $word .= $consonants[mt_rand(0, strlen($consonants) - 1)];
        } else {
            // Ungerade Zahl: beliebigen Vokal ergaenzen
            $word .= $vowels[mt_rand(0, strlen($vowels) - 1)];
        }
    }
    
    if( $upperCaseWord == 2 )
        return ucfirst($word);
    
    return $word;
}

// Fuer Dummy-URLs
function generateRandomString($length = 10) {
    $characters         = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $charactersLength   = strlen($characters);
    $randomString       = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, $charactersLength - 1)];
    }
    return $randomString;
}
 		
?>