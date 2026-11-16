<?php
session_start();
if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../index.html');
    exit();
}
if (($_SESSION['rol'] ?? '') !== 'admin') {
    header('Location: home.php');
    exit();
}
require_once '../Scripts/php/conexion.php';

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nombre = trim($_POST['nombre'] ?? '');
    $apellido = trim($_POST['apellido'] ?? '');
    $usuario = trim($_POST['usuario'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $telefono = trim($_POST['telefono'] ?? '');
    $rol = $_POST['rol'] ?? 'usuario';
    $password = $_POST['password'] ?? '';

    if ($nombre === '' || $apellido === '' || $usuario === '' || $password === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || !in_array($rol, ['usuario', 'admin'], true)) {
        $error = 'Completá correctamente todos los campos obligatorios.';
    } else {
        try {
            $consulta = $conexion->prepare('INSERT INTO usuario (nombre, apellido, usuario, email, telefono, rol, contrasenia) VALUES (?, ?, ?, ?, ?, ?, ?)');
            $consulta->execute([$nombre, $apellido, $usuario, $email, $telefono ?: null, $rol, password_hash($password, PASSWORD_DEFAULT)]);
            header('Location: admin.php?creado=1');
            exit();
        } catch (PDOException $excepcion) {
            $error = $excepcion->getCode() === '23000' ? 'El usuario o el correo electrónico ya están registrados.' : 'No se pudo crear el usuario.';
        }
    }
}
function escaparCrear($valor) { return htmlspecialchars((string)$valor, ENT_QUOTES, 'UTF-8'); }
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LOGOPARK - Crear usuario</title>
  <link rel="stylesheet" href="../css/admin.css?v=20261109-1">
</head>
<body>
  <header class="encabezado"><a class="encabezadoNombre" href="admin.php">LOGOPARK</a><div class="encabezado-acciones"><span>Administración</span><a href="admin.php">Volver al panel</a></div></header>
  <div class="contenedor-form">
    <h1>Crear usuario</h1>
    <p>Agregá una cuenta nueva y definí su rol dentro de LogoPark.</p>
    <?php if ($error !== ''): ?><p class="mensaje-error"><?= escaparCrear($error) ?></p><?php endif; ?>
    <form action="CrearUsuario.php" method="POST" class="linea-formulario">
      <div class="campo"><label>Nombre</label><input type="text" name="nombre" required value="<?= escaparCrear($_POST['nombre'] ?? '') ?>"></div>
      <div class="campo"><label>Apellido</label><input type="text" name="apellido" required value="<?= escaparCrear($_POST['apellido'] ?? '') ?>"></div>
      <div class="campo"><label>Usuario</label><input type="text" name="usuario" required value="<?= escaparCrear($_POST['usuario'] ?? '') ?>"></div>
      <div class="campo"><label>Email</label><input type="email" name="email" required value="<?= escaparCrear($_POST['email'] ?? '') ?>"></div>
      <div class="campo"><label>Teléfono</label><input type="text" name="telefono" value="<?= escaparCrear($_POST['telefono'] ?? '') ?>"></div>
      <div class="campo"><label>Rol</label><select name="rol"><option value="usuario">Usuario</option><option value="admin" <?= ($_POST['rol'] ?? '') === 'admin' ? 'selected' : '' ?>>Admin</option></select></div>
      <div class="campo col-full"><label>Contrase&ntilde;a</label><input type="password" name="password" required></div>
      <div class="col-full fila-botones"><a href="admin.php" class="btn-cancelar">Cancelar</a><button type="submit" class="btn-guardar">Crear usuario</button></div>
    </form>
  </div>
</body>
</html>
