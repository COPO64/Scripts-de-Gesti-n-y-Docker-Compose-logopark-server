<?php
session_start();
header('Content-Type: application/json; charset=utf-8');
if (!isset($_SESSION['id_usuario'])) {
    http_response_code(401);
    echo json_encode(['error' => 'No autorizado']);
    exit();
}
$anio = $_GET['anio'] ?? '';
$marca = $_GET['marca'] ?? '';
$modelo = $_GET['modelo'] ?? '';
if ($anio === '' || $marca === '' || $modelo === '') {
    echo json_encode(['data' => []]);
    exit();
}
$url = 'https://carapi.app/api/trims/v2?' . http_build_query([
    'year' => $anio,
    'make' => $marca,
    'model' => $modelo,
    'limit' => 100
]);
$conexionAPI = curl_init($url);
curl_setopt($conexionAPI, CURLOPT_RETURNTRANSFER, true);
$respuesta = curl_exec($conexionAPI);
curl_close($conexionAPI);
$datos = json_decode($respuesta, true);
echo json_encode([
    'data' => $datos['data'] ?? []
]);
?>
