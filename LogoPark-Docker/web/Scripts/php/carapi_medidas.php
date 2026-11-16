<?php
session_start();
header('Content-Type: application/json; charset=utf-8');
if (!isset($_SESSION['id_usuario'])) {
    http_response_code(401);
    echo json_encode(['error' => 'No autorizado']);
    exit();
}
$id = $_GET['id'] ?? '';
if ($id === '' || !ctype_digit((string) $id)) {
    echo json_encode(['error' => 'Versión inválida']);
    exit();
}
$url = 'https://carapi.app/api/trims/v2/' . $id;
$conexionAPI = curl_init($url);
curl_setopt($conexionAPI, CURLOPT_RETURNTRANSFER, true);
$respuesta = curl_exec($conexionAPI);
curl_close($conexionAPI);
$datos = json_decode($respuesta, true);
$largoPulgadas = $datos['bodies'][0]['length'] ?? null;
if ($largoPulgadas === null || !is_numeric($largoPulgadas)) {
    echo json_encode([
        'error' => 'No hay medidas disponibles para esta versión'
    ]);
    exit();
}
$largoMetros = (float) $largoPulgadas / 39.3701;
if ($largoMetros <= 4.20) {
    $tamano = 'Chico';
} elseif ($largoMetros <= 4.70) {
    $tamano = 'Mediano';
} else {
    $tamano = 'Grande';
}
echo json_encode([
    'largo' => round($largoMetros, 2),
    'tamano' => $tamano
]);
?>
