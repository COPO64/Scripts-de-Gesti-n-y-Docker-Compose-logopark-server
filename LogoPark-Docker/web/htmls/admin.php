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
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'eliminar') {
  $id_usuario = filter_input(INPUT_POST, 'id_usuario', FILTER_VALIDATE_INT);
  if ($id_usuario && $id_usuario !== (int)$_SESSION['id_usuario']) {
    try {
      $conexion->beginTransaction();

      $consulta = $conexion->prepare('SELECT matricula FROM usuario_vehiculo WHERE id_usuario = ?');
      $consulta->execute([$id_usuario]);
      $matriculas = $consulta->fetchAll(PDO::FETCH_COLUMN);

      $conexion->prepare('DELETE FROM usuario_vehiculo WHERE id_usuario = ?')->execute([$id_usuario]);
      $conexion->prepare('DELETE FROM usuario WHERE id_usuario = ?')->execute([$id_usuario]);

      $eliminarAuto = $conexion->prepare('DELETE FROM vehiculo WHERE matricula = ? AND NOT EXISTS (SELECT 1 FROM usuario_vehiculo WHERE matricula = ?) AND NOT EXISTS (SELECT 1 FROM ocupacion WHERE matricula = ?)');
      foreach ($matriculas as $matricula) {
        $eliminarAuto->execute([$matricula, $matricula, $matricula]);
      }

      $conexion->commit();
    } catch (PDOException $error) {
      if ($conexion->inTransaction()) {
        $conexion->rollBack();
      }
      header('Location: admin.php?error=eliminar');
      exit();
    }
  }
  header('Location: admin.php');
  exit();
}
$consulta = $conexion->prepare('SELECT id_usuario, nombre, apellido, usuario, email, telefono, rol FROM usuario ORDER BY nombre, apellido');
$consulta->execute();
$usuarios = $consulta->fetchAll(PDO::FETCH_ASSOC);
$totalUsuarios = count($usuarios);
$totalAdmins = count(array_filter($usuarios, fn($usuario) => $usuario['rol'] === 'admin'));

$resumenSistema = $conexion->query("SELECT
  COUNT(*) AS total,
  COALESCE(SUM(e.estado = 'Ocupado'), 0) AS activos,
  COALESCE(SUM(e.estado = 'Finalizado'), 0) AS finalizados,
  COALESCE(SUM(e.estado = 'Cancelado'), 0) AS cancelados,
  COUNT(DISTINCT o.id_usuario) AS usuarios_con_actividad
FROM ocupacion o
INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento")->fetch(PDO::FETCH_ASSOC);

$calleSistema = $conexion->query("SELECT COALESCE(t.nombre, 'Sin tramo identificado') AS calle, COUNT(*) AS cantidad
FROM ocupacion o
INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento
LEFT JOIN tramos_calle t ON t.id_tramo = e.id_tramo
GROUP BY COALESCE(t.nombre, 'Sin tramo identificado')
ORDER BY cantidad DESC, calle ASC
LIMIT 1")->fetch(PDO::FETCH_ASSOC) ?: ['calle' => 'Sin datos', 'cantidad' => 0];

$mesesSistema = [];
$mesActualSistema = new DateTime('first day of this month');
for ($i = 5; $i >= 0; $i--) {
  $fechaMes = (clone $mesActualSistema)->modify('-' . $i . ' months');
  $mesesSistema[$fechaMes->format('Y-m')] = ['etiqueta' => $fechaMes->format('m/Y'), 'cantidad' => 0];
}
$desdeSistema = array_key_first($mesesSistema) . '-01 00:00:00';
$consultaMesesSistema = $conexion->prepare("SELECT DATE_FORMAT(COALESCE(fecha_hora_ingreso, TIMESTAMP(fecha, hora_inicio)), '%Y-%m') AS mes, COUNT(*) AS cantidad
FROM ocupacion
WHERE COALESCE(fecha_hora_ingreso, TIMESTAMP(fecha, hora_inicio)) >= ?
GROUP BY mes ORDER BY mes");
$consultaMesesSistema->execute([$desdeSistema]);
foreach ($consultaMesesSistema->fetchAll(PDO::FETCH_ASSOC) as $fila) {
  if (isset($mesesSistema[$fila['mes']])) $mesesSistema[$fila['mes']]['cantidad'] = (int) $fila['cantidad'];
}

$estadosSistema = ['Finalizado' => 0, 'Cancelado' => 0, 'Ocupado' => 0];
foreach ($conexion->query("SELECT e.estado, COUNT(*) AS cantidad FROM ocupacion o INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento GROUP BY e.estado")->fetchAll(PDO::FETCH_ASSOC) as $fila) {
  if (isset($estadosSistema[$fila['estado']])) $estadosSistema[$fila['estado']] = (int) $fila['cantidad'];
}

$usuariosActividad = $conexion->query("SELECT TRIM(CONCAT_WS(' ', u.nombre, NULLIF(u.apellido, ''))) AS usuario, COUNT(*) AS cantidad
FROM ocupacion o
INNER JOIN usuario u ON u.id_usuario = o.id_usuario
GROUP BY u.id_usuario, u.nombre, u.apellido
ORDER BY cantidad DESC, usuario ASC
LIMIT 5")->fetchAll(PDO::FETCH_ASSOC);
function escapar($valor)
{
  return htmlspecialchars((string)$valor, ENT_QUOTES, 'UTF-8');
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LOGOPARK - Panel de administración</title>
  <link rel="stylesheet" href="../css/admin.css?v=20261111-2">
</head>
<body>
  <header class="encabezado" id="top"><a class="encabezadoNombre">LOGOPARK</a>
    <h2 style="color: white;">Panel de Administración</h2>
    <div class="encabezado-acciones"><a href="#estadisticas-generales">Estadísticas generales</a><a href="../Scripts/php/logout.php">Cerrar sesión</a></div>
  </header>
  <main class="contenedor-admin">
    <?php if (($_GET['error'] ?? '') === 'eliminar'): ?>
      <p class="mensaje-error">No se pudo eliminar el usuario.</p>
    <?php endif; ?>
    <div class="admin-titulo">
      <div>
        <h1>Usuarios registrados</h1>
      </div>
      <div class="admin-titulo-acciones"><div class="resumen"><span><?= $totalUsuarios ?></span> usuarios activos</div><a class="btn-crear" href="CrearUsuario.php">Crear usuario</a></div>
    </div>
    <div class="tabla-contenedor">
      <table class="tabla-usuarios">
        <thead>
          <tr>
            <th>Nombre y apellido</th>
            <th>Usuario</th>
            <th>Email</th>
            <th>Teléfono</th>
            <th>Rol</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($usuarios as $fila): ?>
            <tr>
              <td><?= escapar(trim($fila['nombre'] . ' ' . $fila['apellido'])) ?></td>
              <td><?= escapar($fila['usuario']) ?></td>
              <td><?= escapar($fila['email']) ?></td>
              <td><?= escapar($fila['telefono'] ?: '—') ?></td>
              <td><span class="rol <?= escapar($fila['rol']) ?>"><?= escapar($fila['rol']) ?></span></td>
              <td>
                <div class="acciones-tabla"><a href="EditarUsuario.php?id=<?= (int)$fila['id_usuario'] ?>" class="btn-editar">Editar</a><?php if ((int)$fila['id_usuario'] !== (int)$_SESSION['id_usuario']): ?><form action="admin.php" method="POST" onsubmit="return confirm('¿Eliminar a este usuario? Esta acción no se puede deshacer.');"><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id_usuario" value="<?= (int)$fila['id_usuario'] ?>"><button type="submit" class="btn-eliminar">Eliminar</button></form><?php else: ?><span class="cuenta-propia">Tu cuenta</span><?php endif; ?></div>
              </td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>

    <section class="estadisticas-admin" id="estadisticas-generales">
      <div class="estadisticas-admin-titulo"><div><p>VISIÓN GENERAL</p><h2>Estadísticas de todo LogoPark</h2><span>Información conjunta de todos los usuarios registrados.</span></div><a href="#top">Volver arriba</a></div>
      <div class="resumen-admin-estadisticas">
        <article><span>Total de estacionamientos</span><strong><?= (int) ($resumenSistema['total'] ?? 0) ?></strong><small>Todos los usuarios</small></article>
        <article><span>Estacionamientos activos</span><strong><?= (int) ($resumenSistema['activos'] ?? 0) ?></strong><small>Ocupados en este momento</small></article>
        <article><span>Usuarios con actividad</span><strong><?= (int) ($resumenSistema['usuarios_con_actividad'] ?? 0) ?></strong><small>Usuarios que estacionaron</small></article>
        <article><span>Calle más utilizada</span><strong class="dato-calle-admin"><?= escapar($calleSistema['calle']) ?></strong><small><?= (int) $calleSistema['cantidad'] ?> registros</small></article>
      </div>
      <div class="graficas-admin">
        <article class="grafica-admin grafica-admin-ancha"><h3>Actividad general de los últimos seis meses</h3><div><canvas id="graficaAdminActividad"></canvas></div></article>
        <article class="grafica-admin"><h3>Estados de los estacionamientos</h3><div><canvas id="graficaAdminEstados"></canvas></div></article>
        <article class="grafica-admin"><h3>Usuarios con más registros</h3><div><canvas id="graficaAdminUsuarios"></canvas></div></article>
      </div>
    </section>
  </main>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
  <script>
    const mesesSistema = <?= json_encode(array_values($mesesSistema), JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;
    const estadosSistema = <?= json_encode($estadosSistema, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;
    const usuariosActividad = <?= json_encode($usuariosActividad, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;
    Chart.defaults.font.family = 'Trebuchet MS, Segoe UI, sans-serif';
    Chart.defaults.color = '#586b78';
    new Chart(document.getElementById('graficaAdminActividad'), { type: 'line', data: { labels: mesesSistema.map(dato => dato.etiqueta), datasets: [{ data: mesesSistema.map(dato => dato.cantidad), borderColor: '#0b5d7a', backgroundColor: 'rgba(57,169,162,.18)', fill: true, tension: .32, pointBackgroundColor: '#39a9a2', pointRadius: 4 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { precision: 0 } }, x: { grid: { display: false } } } } });
    new Chart(document.getElementById('graficaAdminEstados'), { type: 'doughnut', data: { labels: Object.keys(estadosSistema), datasets: [{ data: Object.values(estadosSistema), backgroundColor: ['#39a9a2', '#d98d55', '#0b5d7a'], borderWidth: 0 }] }, options: { responsive: true, maintainAspectRatio: false, cutout: '68%', plugins: { legend: { position: 'bottom', labels: { usePointStyle: true, padding: 16 } } } } });
    new Chart(document.getElementById('graficaAdminUsuarios'), { type: 'bar', data: { labels: usuariosActividad.map(dato => dato.usuario), datasets: [{ data: usuariosActividad.map(dato => dato.cantidad), backgroundColor: '#39a9a2', borderRadius: 5 }] }, options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true, ticks: { precision: 0 } }, y: { grid: { display: false } } } } });
  </script>
</body>
</html>
