<?php
session_start();
if (!isset($_SESSION['id_usuario'])) {
    header("Location: ../index.html");
    exit();
}
if ($_SESSION['rol'] !== 'admin') {
    header("Location: home.php");
    exit();
}
require_once "../Scripts/php/conexion.php";
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = filter_input(INPUT_POST, 'id_usuario', FILTER_VALIDATE_INT);
    $nombre = trim($_POST['nombre'] ?? '');
    $apellido = trim($_POST['apellido'] ?? '');
    $usuarioLogin = trim($_POST['usuario'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $telefono = trim($_POST['telefono'] ?? '');
    $rol = $_POST['rol'] ?? 'usuario';
    $password = $_POST['password'] ?? '';
    if (!$id || $nombre === '' || $apellido === '' || $usuarioLogin === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || !in_array($rol, ['usuario', 'admin'], true)) {
        header('Location: EditarUsuario.php?id=' . (int)$id);
        exit();
    }
    if ($id === (int)$_SESSION['id_usuario'] && $rol !== 'admin') {
        $rol = 'admin';
    }
    if ($password === '') {
        $sql = 'UPDATE usuario SET nombre=?, apellido=?, usuario=?, email=?, telefono=?, rol=? WHERE id_usuario=?';
        $datos = [$nombre, $apellido, $usuarioLogin, $email, $telefono ?: null, $rol, $id];
    } else {
        $sql = 'UPDATE usuario SET nombre=?, apellido=?, usuario=?, email=?, telefono=?, rol=?, contrasenia=? WHERE id_usuario=?';
        $datos = [$nombre, $apellido, $usuarioLogin, $email, $telefono ?: null, $rol, password_hash($password, PASSWORD_DEFAULT), $id];
    }
    try {
        $consulta = $conexion->prepare($sql);
        $consulta->execute($datos);
    } catch (PDOException $error) {
        $tipoError = $error->getCode() === '23000' ? 'duplicado' : 'guardar';
        header('Location: EditarUsuario.php?id=' . $id . '&error=' . $tipoError);
        exit();
    }
    if ($id === (int)$_SESSION['id_usuario']) {
        $_SESSION['nombre'] = trim($nombre . ' ' . $apellido);
        $_SESSION['rol'] = $rol;
    }
    header('Location: admin.php');
    exit();
}
$id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
if (!$id) { header('Location: admin.php'); exit(); }
$sql = "SELECT id_usuario, nombre, apellido, usuario, email, telefono, rol FROM usuario WHERE id_usuario = ?";
$consulta = $conexion->prepare($sql);
$consulta->execute([$id]);
$usuario = $consulta->fetch();
if (!$usuario) { header('Location: admin.php'); exit(); }
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LOGOPARK - Editar usuario</title>
  <link rel="stylesheet" href="../css/admin.css?v=20261109-1">
</head>
<body>
  <header class="encabezado"><a class="encabezadoNombre" href="admin.php">LOGOPARK</a><div class="encabezado-acciones"><span>Administración</span><a href="admin.php">Volver al panel</a></div></header>
  <div class="contenedor-form">
    <h1>Editar usuario</h1>
    <p>Actualizá los datos de la cuenta seleccionada.</p>
    <?php if (($_GET['error'] ?? '') === 'duplicado'): ?>
      <p class="mensaje-error">El usuario o el correo electrónico ya están registrados.</p>
    <?php elseif (($_GET['error'] ?? '') === 'guardar'): ?>
      <p class="mensaje-error">No se pudieron guardar los cambios.</p>
    <?php endif; ?>
    <form action="EditarUsuario.php" method="POST" class="linea-formulario">
      <input type="hidden" name="id_usuario" value="<?php echo $usuario["id_usuario"]; ?>">
      <div class="campo">
        <label>Nombre</label>
        <input type="text" name="nombre" required value="<?php echo htmlspecialchars($usuario["nombre"], ENT_QUOTES, 'UTF-8'); ?>">
      </div>
      <div class="campo">
        <label>Apellido</label>
        <input type="text" name="apellido" required value="<?php echo htmlspecialchars($usuario["apellido"], ENT_QUOTES, 'UTF-8'); ?>">
      </div>
      <div class="campo">
        <label>Usuario</label>
        <input type="text" name="usuario" required value="<?php echo htmlspecialchars($usuario["usuario"], ENT_QUOTES, 'UTF-8'); ?>">
      </div>
      <div class="campo">
        <label>Email</label>
        <input type="email" name="email" required value="<?php echo htmlspecialchars($usuario["email"], ENT_QUOTES, 'UTF-8'); ?>">
      </div>
      <div class="campo">
        <label>Teléfono</label>
        <input type="text" name="telefono" value="<?php echo htmlspecialchars($usuario["telefono"], ENT_QUOTES, 'UTF-8'); ?>">
      </div>
      <div class="campo">
        <label>Rol</label>
        <select name="rol">
          <option value="usuario" <?= $usuario['rol'] === 'usuario' ? 'selected' : '' ?>>Usuario</option>
          <option value="admin" <?= $usuario['rol'] === 'admin' ? 'selected' : '' ?>>Admin</option>
        </select>
      </div>
      <div class="campo">
        <label>Nueva contrase&ntilde;a</label>
        <input type="password" name="password" placeholder="Dejar vacío para no cambiarla">
      </div>
      <div class="col-full fila-botones">
        <a href="admin.php" class="btn-cancelar">Cancelar</a>
        <button type="submit" class="btn-guardar">Guardar cambios</button>
      </div>
    </form>
  </div>
</body>
</html>
