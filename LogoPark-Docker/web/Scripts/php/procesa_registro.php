<?php
require_once "conexion.php";
$nombre = trim($_POST["nombre"] ?? '');
$apellido = trim($_POST["apellido"] ?? '');
$usuario = trim($_POST["usuario"] ?? '');
$email = trim($_POST["email"] ?? '');
$telefono = trim($_POST["telefono"] ?? '');
$password = $_POST["password"] ?? '';

if ($nombre === '' || $apellido === '' || $usuario === '' || $password === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    header("Location: ../../htmls/Registrarse.html");
    exit();
}

$contrasenia = password_hash($password, PASSWORD_DEFAULT);
$sql = "INSERT INTO usuario (nombre, apellido, usuario, contrasenia, email, telefono) VALUES (?, ?, ?, ?, ?, ?)";
try {
    $consulta = $conexion->prepare($sql);
    $consulta->execute([$nombre, $apellido, $usuario, $contrasenia, $email, $telefono ?: null]);
} catch (PDOException $error) {
    $tipoError = $error->getCode() === '23000' ? 'duplicado' : 'guardar';
    header("Location: ../../htmls/Registrarse.html?error=" . $tipoError);
    exit();
}
header("Location: ../../index.html");
exit();
?>
