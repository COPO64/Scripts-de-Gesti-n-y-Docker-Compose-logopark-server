<?php
session_start();
require_once "conexion.php";
$usuario = $_POST["usuario"];
$contrasenia = $_POST["password"];
$sql = "SELECT id_usuario, nombre, apellido, usuario, contrasenia, rol FROM usuario WHERE usuario = ?";
$consulta = $conexion->prepare($sql);
$consulta->execute([$usuario]);
$fila = $consulta->fetch();
if ($fila) {
    if (password_verify($contrasenia, $fila["contrasenia"])) {
        $_SESSION["id_usuario"] = $fila["id_usuario"];
        $_SESSION["nombre"] = trim($fila["nombre"] . ' ' . $fila["apellido"]);
        $_SESSION["rol"] = $fila["rol"];
        $destino = ($fila['rol'] === 'admin') ? '../../htmls/admin.php' : '../../htmls/home.php';
        header("Location: " . $destino);
        exit();
    } else {
        echo "Contraseña incorrecta";
    }
} else {
    echo "Usuario no encontrado";
}
?>
