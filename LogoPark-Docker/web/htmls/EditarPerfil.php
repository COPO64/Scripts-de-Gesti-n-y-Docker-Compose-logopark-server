<?php
session_start();
if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../index.html');
    exit();
}
require_once '../Scripts/php/conexion.php';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id_usuario = $_SESSION['id_usuario'];
    $nombre = trim($_POST['nombre'] ?? '');
    $apellido = trim($_POST['apellido'] ?? '');
    $usuarioLogin = trim($_POST['usuario'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $telefono = trim($_POST['telefono'] ?? '');
    $password = $_POST['password'] ?? '';
    if ($nombre === '' || $apellido === '' || $usuarioLogin === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        header('Location: EditarPerfil.php');
        exit();
    }
    try {
        if ($password === '') {
            $sql = 'UPDATE usuario SET nombre = ?, apellido = ?, usuario = ?, email = ?, telefono = ? WHERE id_usuario = ?';
            $consulta = $conexion->prepare($sql);
            $consulta->execute([$nombre, $apellido, $usuarioLogin, $email, $telefono ?: null, $id_usuario]);
        } else {
            $sql = 'UPDATE usuario SET nombre = ?, apellido = ?, usuario = ?, email = ?, telefono = ?, contrasenia = ? WHERE id_usuario = ?';
            $consulta = $conexion->prepare($sql);
            $consulta->execute([$nombre, $apellido, $usuarioLogin, $email, $telefono ?: null, password_hash($password, PASSWORD_DEFAULT), $id_usuario]);
        }
    } catch (PDOException $error) {
        $tipoError = $error->getCode() === '23000' ? 'duplicado' : 'guardar';
        header('Location: EditarPerfil.php?error=' . $tipoError);
        exit();
    }
    $_SESSION['nombre'] = trim($nombre . ' ' . $apellido);
    header('Location: EditarPerfil.php?actualizado=1');
    exit();
}
$consulta = $conexion->prepare('SELECT nombre, apellido, usuario, email, telefono FROM usuario WHERE id_usuario = ?');
$consulta->execute([$_SESSION['id_usuario']]);
$perfil = $consulta->fetch(PDO::FETCH_ASSOC);
if (!$perfil) {
    session_destroy();
    header('Location: ../index.html');
    exit();
}
$nombreCompleto = trim($perfil['nombre'] . ' ' . $perfil['apellido']);
$iniciales = strtoupper(substr($perfil['nombre'], 0, 1) . substr($perfil['apellido'], 0, 1));
function escapar($valor) { return htmlspecialchars((string)$valor, ENT_QUOTES, 'UTF-8'); }
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LOGOPARK - Editar perfil</title>
  <link rel="stylesheet" href="../css/estilos.css?v=20260819-4">
  <link rel="stylesheet" href="../css/usuario.css?v=20261111-4">
</head>
<body class="page-perfil">
  <header class="encabezado">
    <a class="encabezadoNombre" href="home.php">LOGOPARK</a>
    <div class="perfil-acciones">
      <button id="botonPerfil" class="boton-perfil" type="button" aria-expanded="false" aria-controls="menuPerfil"><span class="Iniciales"><?= escapar($iniciales) ?></span><span class="nombre-usuario"><?= escapar($nombreCompleto) ?></span><span aria-hidden="true">⌄</span></button>
      <nav id="menuPerfil" class="Menu">
        <div class="Menu-header"><span class="Iniciales-grande"><?= escapar($iniciales) ?></span><div><strong><?= escapar($nombreCompleto) ?></strong><small><?= escapar($perfil['email']) ?></small></div></div>
        <a class="menu-principal" href="home.php#mapa-estacionamiento">Registrar estacionamiento</a>
        <a href="MiAuto.php">Ingresar un auto</a>
        <a href="Estadisticas.php">Estadísticas</a>
        <a class="activo" href="EditarPerfil.php" aria-current="page">Editar Perfil</a>
        <a class="Menu-salir" href="../Scripts/php/logout.php">Cerrar sesión</a>
      </nav>
    </div>
  </header>
  <main class="perfil-layout">
    <section class="perfil-intro">
      <img src="../Imagenes/logo-logopark-transparente.png" alt="Logo LogoPark">
      <p>MI CUENTA</p>
      <span>Actualizá los datos con los que ingresás a LogoPark.</span>
    </section>
    <section class="perfil-formulario">
      <h1>Editar perfil</h1>
      <p>Los cambios se guardarán en tu cuenta.</p>
      <?php if (($_GET['error'] ?? '') === 'duplicado'): ?>
        <p class="mensaje-error">El usuario o el correo electrónico ya están registrados.</p>
      <?php elseif (($_GET['error'] ?? '') === 'guardar'): ?>
        <p class="mensaje-error">No se pudieron guardar los cambios.</p>
      <?php endif; ?>
      <form action="EditarPerfil.php" method="post">
        <label for="nombre">Nombre</label>
        <input id="nombre" name="nombre" type="text" value="<?= escapar($perfil['nombre']) ?>" required>
        <label for="apellido">Apellido</label>
        <input id="apellido" name="apellido" type="text" value="<?= escapar($perfil['apellido']) ?>" required>
        <label for="usuario">Usuario</label>
        <input id="usuario" name="usuario" type="text" value="<?= escapar($perfil['usuario']) ?>" required>
        <label for="email">Correo electrónico</label>
        <input id="email" name="email" type="email" value="<?= escapar($perfil['email']) ?>" required>
        <label for="telefono">Teléfono</label>
        <input id="telefono" name="telefono" type="tel" value="<?= escapar($perfil['telefono']) ?>" placeholder="099 123 456">
        <label for="password">Nueva contrase&ntilde;a <span>(opcional)</span></label>
        <input id="password" name="password" type="password" placeholder="Dejá vacío para conservar la actual">
        <div class="acciones"><a href="home.php">Cancelar</a><button type="submit">Guardar cambios</button></div>
      </form>
    </section>
  </main>
  <script src="../Scripts/js/menu_perfil.js?v=20261111-1"></script>
</body>
</html>
