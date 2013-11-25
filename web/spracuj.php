<?php
if(!empty($_GET["mapa"]) && !empty($_GET["sirka"]) && !empty($_GET["vyska"])){
	$rozdelene = explode(',', $_GET["mapa"]);
	$nazov = md5(rand(0,1000) . time());
	$cesta = '/home/r/rozar1/public_html/rp/mapy/'. $nazov . '.dat';
	$subor = fopen($cesta, "w+");
	fwrite($subor, pack("i", $_GET["vyska"]));
	fwrite($subor, pack("i", $_GET["sirka"]));
	$cas_int = (int) $_GET["cas"];
	if ($_GET["cas"] == $cas_int){
	fwrite($subor, pack("d", $cas_int));
	} else {
	fwrite($subor, pack("d", 0));
	}
	for($i=0;$i<count($rozdelene);$i++){
		fwrite($subor, pack("i", $rozdelene[$i]));
	}
	if(!empty($_GET["npc"])){
		fwrite($subor, pack("i", $_GET["pocet"]));
		$npc = str_replace('|', ',', $_GET["npc"]);
		$npc = explode(',', $npc);
		for($i=0;$i<count($npc);$i++){
			fwrite($subor, pack("i", $npc[$i]));
		}
	} else {die();}
	fclose($subor);
	if(file_exists($cesta)){
		chmod($cesta, 0655);
	}
	header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename=' . $nazov . '.dat');
    header('Content-Transfer-Encoding: binary');
    header('Expires: 0');
    header('Cache-Control: must-revalidate');
    header('Pragma: public');
    header('Content-Length: ' . filesize($cesta));
	ob_clean();
    flush();
	readfile($cesta);
	unlink($cesta);
}
?>