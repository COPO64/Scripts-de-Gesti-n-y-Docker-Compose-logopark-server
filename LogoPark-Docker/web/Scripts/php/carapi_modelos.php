<?php
session_start();
if (!isset($_SESSION['id_usuario'])) {
    exit();
}
$marca = $_GET['marca'] ?? '';
$anio = $_GET['anio'] ?? '';
if ($marca === '' || $anio === '') {
    exit();
}
$url = "https://carapi.app/api/models/v2?year=" . $anio . "&make_id=" . $marca . "&limit=100";
$conexionAPI = curl_init($url);
curl_setopt($conexionAPI, CURLOPT_RETURNTRANSFER, true);
$respuesta = curl_exec($conexionAPI);
curl_close($conexionAPI);
header("Content-Type: application/json; charset=utf-8");
echo $respuesta;
?>
