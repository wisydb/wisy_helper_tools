var downloadMonitor = null;
var logMonitor = null;
var logFailure = 0;
var live = false;
 
$(document).keypress("l",function(e) {
  if(e.ctrlKey) {
   alert("LIVE-Import-Option aktiviert.");
   $("#liveoption").show();
  }
});
 
function startImport() {
 
 $("#abbruch").show();
 blinkGreen = setInterval(green, 1200);
 
 var filename = $("#ftpFilename option:selected").val();
 var email = $("#email").val();
 var unzipscope = $("#unzipscope option:selected").val();
 var sandbox = $("#sandbox option:selected").val();
 var quicker = $("#quicker option:selected").val();
 var liveimportpwd = "Passwort";
 
 if (live) {
  var startliveimport = confirm("Soll "+filename+" wirklich jetzt ins LIVE-System importiert werden?!");
  
  if(!startliveimport)
   return false;
  
  liveimportpwd = prompt("Wie lautet Ihre vollstaendige Telefonnummer (ohne Leer- und Sonderzeichen)?", "");
  
  if (liveimportpwd == null || liveimportpwd == "") {
   alert("Passwortfehler. Abbruch.");
   return false;
  }
 }
 
 $("#live_output").load("/restore/startDownloadImport.php?liveimportpwd="+liveimportpwd+"&ftpFilename="+filename+"&email="+email+"&logfile="+logfile+"&logdetailsfile="+logdetailsfile
                        +"&unzipscope="+unzipscope+"&sandbox="+sandbox+"&quicker="+quicker+"&html=1");
 
 $.get( "/restore/processmonitor.php?logfile="+logfile, function( data ) {
   ; // egal
 });
 
 downloadMonitor = setInterval(monitorDownload, 3000);
 logMonitor = setInterval(monitorLog, 3000);
 
 return false;
}

function testForErrors(interval) {
 if(    $("#download_monitor").text().match(/Error:/i)
     || $("#download_monitor").text().match(/Abbruch:/i)
     || $("#unzip_monitor").text().match(/Error:/i)
     || $("#dbimport_monitor").text().match(/Error:/i)
     || $("#live_output").text().match(/Error:/i)
     || $("#log_monitor").text().match(/Error:/i)
     || $("#misc").text().match(/Abbruch:/i)
   ) {
  if(typeof console != "undefined") { console.log("Fehler oder manueller Abbruch!"); }
  clearInterval(downloadMonitor);
  clearInterval(logMonitor);
  clearInterval(unzipMonitor);
  clearInterval(dbimportMonitor)
  red();
  return true;
 } else if( $("#log_monitor").text().match(/Prozess beendet/i) && !$("#log_monitor").text().match(/Import-Ende/i) ) {
  if(typeof console != "undefined") { console.log("Prozess wurde extern beendet!"); }
  clearInterval(downloadMonitor);
  clearInterval(logMonitor);
  clearInterval(unzipMonitor);
  clearInterval(dbimportMonitor)
  red();
  return true;
 }
 else {
  return false;
 }
}

function monitorDownload() {
 
 if(testForErrors(downloadMonitor)) 
  return false;
 
 var filename = $("#ftpFilename option:selected").attr("value");
 var filenameDisplay = $("#ftpFilename option:selected").text();
 var filesize = $("#ftpFilename option:selected").attr("data-filesize");
 var downloadedBytes = null;
 var percent = null;
            
 $.getJSON("/restore/downloadmonitor.php?filename="+filename, function(data) {
  downloadedBytes = data["bytes"];
  percent = (downloadedBytes*100/filesize);
                 
  $("#download_monitor").html("Datei \""+filenameDisplay+"\" angefordert...\n\nFortschritt: <span id='downloadedbytes'>"+downloadedBytes+"</span> von "+filesize+" Bytes (<span id='percent'>"+parseFloat(Math.round(percent * 100) / 100).toFixed(2)+"</span>%) <div id='download_progressbar'></div>");
  $("#download_progressbar").progressbar({ value: percent });
  $("#startImport").attr("type", "text");
  $("#email, #ftpFilename, #unzipscope, #startImport, #quicker").attr("disabled", "true");
             
  if (percent>=100) {
   clearInterval(downloadMonitor);
   $("#download_monitor").append("Download erfolgreich beendet.");
   if(typeof console != "undefined") { console.log("Download-Monitor beendet."); }
   monitorUnzip();
  }
  
  if (downloadedBytes == null || data["bytes"] == "") {
   /* $("#download_monitor").append("<br>Abgebrochen!");
   abbruch();
   if(typeof console != "undefined") { console.log("Download-Monitor beendet. Mit Fehlern!"); } */
  }
 });
}

var filename = null;
var filenameDisplay = null;
var targetFilesize = null;
var unzipMonitor = null;
var unzipUpdateRate = null;
var dbimportMonitor = null;

function monitorDBImport() {
 
 if(testForErrors(dbimportMonitor))
  return false;

 if( !$("#log_monitor").text().match(/Schreibe in die Datenbank/i) )
  return false;
 
 var percent = 0;
 
 $.getJSON("/restore/DBimportmonitor.php?logfile="+logDBImportfile, function(data) {   
   percent = data["percent"];
    
   $("#dbimport_monitor").html("<span id='percent'>"+percent+"</span>%\n<div id='dbimport_progressbar'></div>");
   $("#dbimport_progressbar").progressbar({ value: parseInt(percent) });
   
   if (percent>=100) {
    clearInterval(dbimportMonitor);
    if(typeof console != "undefined") { console.log("Clear DB-Import-Monitor, weil >= 100% importiert."); }
    
    $("#dbimport_monitor").append("DB-Import erfolgreich beendet.");
   }
   
   if (percent == null || data["percent"] == "") {
      clearInterval(dbimportMonitor);

      $("#dbimport_monitor").append("<br>Error: Abgebrochen!");
      $("#dbimport_monitor").append("<br>"+data["error"]);
    
      if(typeof console != "undefined") { console.log("DB-Monitor beendet. Mit Fehlern!"); }
   }
 });
}

function monitorUnzip() {
 
 filename = $("#ftpFilename option:selected").attr("value");
 filenameDisplay = $("#ftpFilename option:selected").text();
 var unzipscope = $("#unzipscope option:selected").val();
 
 if(unzipscope == "unzipAll" || unzipscope == "unzipAllAndImportSQL") {
    unzipUpdateRate = 20;
 } else {
    unzipUpdateRate = 3;
 }
 
 var percent = null;
 
 if(targetFilesize == null) {
   if(typeof console != "undefined") { console.log("Starte Unzip-Monitor ..."); }
  $.getJSON("/restore/unzipmonitor.php?filename="+filename+"&unzipscope="+unzipscope+"&getTargetFileSize=1", function(data) {
   targetFilesize = data["targetFilesize"];
   monitorUnzipped();
   unzipMonitor = setInterval(monitorUnzipped, unzipUpdateRate*1000);
  });
 }
}

function monitorUnzipped() {
 
 if(testForErrors(unzipMonitor))
  return false;
 
 var unzipedBytes = null;
 var unzipscope = $("#unzipscope option:selected").val();
 
 $.getJSON("/restore/unzipmonitor.php?filename="+filename+"&unzipscope="+unzipscope+"&getCurrentFileSize=1", function(data) {
   unzipedBytes = data["unzipedBytes"];
   
   percent = (unzipedBytes*100/targetFilesize);
   ungenau = "";
   
   if(unzipscope == "unzipAll" || unzipscope == "unzipAllAndImportSQL")
    ungenau = " (Ungef&auml;hrer Wert! Update nur alle "+unzipUpdateRate+" Sek.)";
    
   $("#unzip_monitor").html("von \""+filenameDisplay+"\".\n\nFortschritt<small>"+ungenau+"</small>: <span id='downloadedbytes'>"+unzipedBytes
                            +"</span> von "+targetFilesize+" Bytes (<span id='percent'>"+parseFloat(Math.round(percent * 100) / 100).toFixed(2)+"</span>%)\n"
                            +"<div id='unzip_progressbar'></div>");
   $("#unzip_progressbar").progressbar({ value: percent });
   
   if (percent>=100) {
    clearInterval(unzipMonitor);
    if(typeof console != "undefined") { console.log("Clear Unzipmonitor, weil >= 100% heruntergeladen"); }
    
    $("#unzip_monitor").append("Unzip erfolgreich beendet.");
    if(typeof console != "undefined") { console.log("Unzip-Monitor beendet."); }
    
    dbimportMonitor = setInterval(monitorDBImport, 8000);
   }
   
   if (unzipedBytes == null || data["targetFilesize"] == "") {
    clearInterval(unzipMonitor);
    $("#unzip_monitor").append("<br>Abgebrochen!");
    $("#unzip_monitor").append("<br>"+data["error"]);
    if(typeof console != "undefined") { console.log("Unzip-Monitor beendet. Mit Fehlern!"); }
   }
   
   if($("#log_monitor").text().match(/Ende Unzip/i)) {
    if(typeof console != "undefined") { console.log("Unzip-Monitor: Ende bei: "+percent+"%!"); }
    setTimeout(clearInterval(unzipMonitor), 20000);
   }  
  });
}

function monitorLog() {
 
 var today = new Date();
 var h = today.getHours();
 var m = today.getMinutes();
 var s = today.getSeconds();
 if (h < 10) { h = "0"+h; }
 if (m < 10) { m = "0"+m; }
 if (s < 10) { s = "0"+s; }   
 $("#log_time").html("("+h+":"+m+":"+s+")");
 
 if(testForErrors(logMonitor))
  return false;

 var log = null;
            
 $.getJSON("/restore/logmonitor.php?logfile="+logfile+"&logdetailsfile="+logdetailsfile, function(data) {
  log = data["log"].replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#39;/g, "'");
  logdetails = data["logdetails"].replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#39;/g, "'");
                   
  $("#log_monitor").html(log);
  $("#live_output").html(logdetails);
             
  if(log == null || data["log"] == "" || log.match(/Import beendet/) || log.match(/Error:/i)) {
   logFailure++;
    
   if (logFailure == 3) {
    clearInterval(logMonitor);
    if(typeof console != "undefined") { console.log("Log-Monitor beendet!"); if(log == null || data["log"] == "") { console.log("Mit Fehlern!"); } }
    red();
   }
  }
 });

 if($("#log_monitor").text().match(/Import-Ende/i)) {
  clearInterval(logMonitor);
  blue();
  $("#abbruch").hide();
 }
 
}

function abbruch() {
 $("#abbruch, #email, #ftpFilename, #unzipscope, #startImport, #quicker").attr("disabled", "true");
 
 $("#abbruch").attr("value", "abgebrochen!");
 $("#abbruch").css("color", "darkred"); $("#abbruch").css("background-color", "white");
 
 var neuladen = "<input id=\"neuladen\" type=\"submit\" value=\"Seite neu laden!\" onclick=\"window.location.href='/restore/';\">";
 $("#abbruch").after(neuladen);
 
 $.getJSON("/restore/abbruch.php?logfile="+logfile, function(data) {
  output = data["output"];
  $("#misc").html("<div class='error'>Abbruch: Laufende Prozesse werden beendet und Lock-Datei gel&ouml;scht.</div>");
  $("#misc").html($("#misc").html()+output);
  red();
  $("#neuladen").show();
  clearInterval(downloadMonitor);
  clearInterval(logMonitor);
 });
 
 yellow();
}

function evalSelects() {
 var doImport = false;
 var unzipscope = $("#unzipscope option:selected").val();
 var ftpFilename = $("#ftpFilename option:selected").val();
 var sandbox = $("#sandbox option:selected").val();

 if(unzipscope == "unzipAll" || unzipscope == "unzipSQL") {
  // Kein Import
  $("#importTargetText").html("Server-Festplatte"); // Ueberschrift
  $("#sandboxchoicecontainer, #arrow, #dbimport_monitor, #dbmonitorlabel").hide(); // Sanboxwahl aus
 } else if(unzipscope == "unzipAllAndImportSQL" || unzipscope == "unzipSQLAndImportSQL") {
  doImport = true;
  if ($("#sandbox option:selected").val() == "LIVE") {
   $("#importTargetText").html("<Meine-Domain>-LIVE!!!"); // Ueberschrift
  } else {
   $("#importTargetText").html("<Meine-Domain>-Sandbox"); // Ueberschrift
  }
  $("#sandboxchoicecontainer, #arrow, #dbimport_monitor, #dbmonitorlabel").show(); // Sanboxwahl an
 }
 
 if(!doImport && (unzipscope == "" || ftpFilename == "")) {
  $("#startImport, #monitors").hide();
 } else if(doImport && (unzipscope == "" || ftpFilename == "" || sandbox == "")) {
  $("#startImport, #monitors").hide();
 } else {
  $("#startImport, #monitors").show();          
 }
 
 if(sandbox == "LIVE") {
  liveModus();
 } else {
  sandboxModus();
 }
}

function switchAllBackups() {
 if(document.getElementById('switchAllBackups').checked) {
  $("#ftpFilename option.tooMuch").removeClass("skipBackup");
 } else {
  $("#ftpFilename option.tooMuch").addClass("skipBackup");
 }
}

function showElements() {
 if($("#email").val().match(/@/)) {
  $('#forms').show();
 }
}

function red() {
 if(typeof blinkGreen != "undefined") { clearInterval(blinkGreen); }
 $(".led-yellow, .led-green, .led-blue").hide();
 $(".led-red").show();
}

function green() {
 $(".led-yellow, .led-red, .led-blue").hide();
 
 if($(".led-green").is(":visible")) {
  $(".led-green").fadeOut(500);
 } else {
  $(".led-green").fadeIn(500);
 }
}

function yellow() {
 if(typeof blinkGreen != "undefined") { clearInterval(blinkGreen); }
 $(".led-red, .led-green, .led-blue").hide();
 $(".led-yellow").show();
}

function blue() {
 if(typeof blinkGreen != "undefined") { clearInterval(blinkGreen); }
 $(".led-yellow, .led-green, .led-red").hide();
 $(".led-blue").show();
}

function liveModus() {
 $("body").css("background-color", "darkred");
 live = true;
}

function sandboxModus() {
 $("body").css("background-color", "#eee");
 live = false;
}

$(document).ready( function() {
 showElements();
});