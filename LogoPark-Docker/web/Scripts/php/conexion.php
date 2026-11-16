<?php
date_default_timezone_set('America/Montevideo');
$hostBase = getenv('LOGOPARK_DB_HOST') ?: 'localhost';
$puertoBase = getenv('LOGOPARK_DB_PORT') ?: '3306';
$nombreBase = getenv('MYSQL_DATABASE') ?: 'logopark';
$usuarioBase = getenv('LOGOPARK_DB_USER') ?: 'root';
$contraseniaBase = getenv('MYSQL_ROOT_PASSWORD') ?: '';

$conexion = new PDO(
    "mysql:host={$hostBase};port={$puertoBase};dbname={$nombreBase};charset=utf8mb4",
    $usuarioBase,
    $contraseniaBase
);
$conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$conexion->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
// PHP y MySQL usan la misma zona horaria para calcular salidas y confirmaciones.
$conexion->exec("SET time_zone = '-03:00'");
