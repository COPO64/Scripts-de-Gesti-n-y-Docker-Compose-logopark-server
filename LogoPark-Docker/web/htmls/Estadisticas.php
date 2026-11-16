<?php
session_start();
if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../index.html');
    exit();
}
require_once '../Scripts/php/conexion.php';
date_default_timezone_set('America/Montevideo');
$idUsuario = (int) $_SESSION['id_usuario'];

function escaparEstadistica($valor)
{
    return htmlspecialchars((string) $valor, ENT_QUOTES, 'UTF-8');
}

$consultaPerfil = $conexion->prepare("SELECT nombre, apellido, email FROM usuario WHERE id_usuario = ?");
$consultaPerfil->execute([$idUsuario]);
$perfil = $consultaPerfil->fetch(PDO::FETCH_ASSOC);
if (!$perfil) {
    session_destroy();
    header('Location: ../index.html');
    exit();
}
$nombreCompleto = trim($perfil['nombre'] . ' ' . $perfil['apellido']);
$iniciales = strtoupper(substr($perfil['nombre'], 0, 1) . substr($perfil['apellido'], 0, 1));

$consultaResumen = $conexion->prepare("SELECT
    COUNT(*) AS total,
    COALESCE(SUM(e.estado = 'Finalizado'), 0) AS finalizados,
    COALESCE(SUM(e.estado = 'Cancelado'), 0) AS cancelados,
    COALESCE(SUM(GREATEST(0, TIMESTAMPDIFF(MINUTE,
        COALESCE(o.fecha_hora_ingreso, TIMESTAMP(o.fecha, o.hora_inicio)),
        COALESCE(o.salida_real, o.fecha_cancelacion, NOW())
    ))), 0) AS minutos
FROM ocupacion o
INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento
WHERE o.id_usuario = ?");
$consultaResumen->execute([$idUsuario]);
$resumen = $consultaResumen->fetch(PDO::FETCH_ASSOC) ?: ['total' => 0, 'finalizados' => 0, 'cancelados' => 0, 'minutos' => 0];

$consultaFavorita = $conexion->prepare("SELECT COALESCE(t.nombre, 'Sin tramo identificado') AS calle, COUNT(*) AS cantidad
FROM ocupacion o
INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento
LEFT JOIN tramos_calle t ON t.id_tramo = e.id_tramo
WHERE o.id_usuario = ?
GROUP BY COALESCE(t.nombre, 'Sin tramo identificado')
ORDER BY cantidad DESC, calle ASC
LIMIT 1");
$consultaFavorita->execute([$idUsuario]);
$favorita = $consultaFavorita->fetch(PDO::FETCH_ASSOC) ?: ['calle' => 'Sin datos', 'cantidad' => 0];

$meses = [];
$mesActual = new DateTime('first day of this month');
for ($i = 5; $i >= 0; $i--) {
    $fechaMes = (clone $mesActual)->modify('-' . $i . ' months');
    $meses[$fechaMes->format('Y-m')] = ['etiqueta' => $fechaMes->format('m/Y'), 'cantidad' => 0];
}
$desde = array_key_first($meses) . '-01 00:00:00';
$consultaMeses = $conexion->prepare("SELECT DATE_FORMAT(COALESCE(o.fecha_hora_ingreso, TIMESTAMP(o.fecha, o.hora_inicio)), '%Y-%m') AS mes, COUNT(*) AS cantidad
FROM ocupacion o
WHERE o.id_usuario = ?
  AND COALESCE(o.fecha_hora_ingreso, TIMESTAMP(o.fecha, o.hora_inicio)) >= ?
GROUP BY mes
ORDER BY mes");
$consultaMeses->execute([$idUsuario, $desde]);
foreach ($consultaMeses->fetchAll(PDO::FETCH_ASSOC) as $fila) {
    if (isset($meses[$fila['mes']])) $meses[$fila['mes']]['cantidad'] = (int) $fila['cantidad'];
}

$estados = ['Finalizado' => 0, 'Cancelado' => 0, 'Ocupado' => 0];
$consultaEstados = $conexion->prepare("SELECT e.estado, COUNT(*) AS cantidad
FROM ocupacion o
INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento
WHERE o.id_usuario = ?
GROUP BY e.estado");
$consultaEstados->execute([$idUsuario]);
foreach ($consultaEstados->fetchAll(PDO::FETCH_ASSOC) as $fila) {
    if (isset($estados[$fila['estado']])) $estados[$fila['estado']] = (int) $fila['cantidad'];
}

$consultaCalles = $conexion->prepare("SELECT COALESCE(t.nombre, 'Sin tramo identificado') AS calle, COUNT(*) AS cantidad
FROM ocupacion o
INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento
LEFT JOIN tramos_calle t ON t.id_tramo = e.id_tramo
WHERE o.id_usuario = ?
GROUP BY COALESCE(t.nombre, 'Sin tramo identificado')
ORDER BY cantidad DESC, calle ASC
LIMIT 5");
$consultaCalles->execute([$idUsuario]);
$calles = $consultaCalles->fetchAll(PDO::FETCH_ASSOC);

$consultaHistorial = $conexion->prepare("SELECT
    o.fecha,
    COALESCE(o.fecha_hora_ingreso, TIMESTAMP(o.fecha, o.hora_inicio)) AS ingreso,
    o.matricula,
    v.marca,
    v.modelo,
    e.estado,
    e.latitud,
    e.longitud,
    COALESCE(t.nombre, 'Sin tramo identificado') AS calle
FROM ocupacion o
INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento
INNER JOIN vehiculo v ON v.matricula = o.matricula
LEFT JOIN tramos_calle t ON t.id_tramo = e.id_tramo
WHERE o.id_usuario = ?
ORDER BY COALESCE(o.fecha_hora_ingreso, TIMESTAMP(o.fecha, o.hora_inicio)) DESC
LIMIT 10");
$consultaHistorial->execute([$idUsuario]);
$historial = $consultaHistorial->fetchAll(PDO::FETCH_ASSOC);
$horas = round(((int) $resumen['minutos']) / 60, 1);
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LOGOPARK - Estadísticas</title>
  <link rel="stylesheet" href="../css/estilos.css?v=20260819-4">
  <link rel="stylesheet" href="../css/usuario.css?v=20261111-4">
</head>
<body class="page-estadisticas">
  <header class="encabezado">
    <a class="encabezadoNombre" href="home.php">LOGOPARK</a>
    <div class="perfil-acciones">
      <button id="botonPerfil" class="boton-perfil" type="button" aria-expanded="false" aria-controls="menuPerfil"><span class="Iniciales"><?= escaparEstadistica($iniciales) ?></span><span class="nombre-usuario"><?= escaparEstadistica($nombreCompleto) ?></span><span aria-hidden="true">⌄</span></button>
      <nav id="menuPerfil" class="Menu">
        <div class="Menu-header"><span class="Iniciales-grande"><?= escaparEstadistica($iniciales) ?></span><div><strong><?= escaparEstadistica($nombreCompleto) ?></strong><small><?= escaparEstadistica($perfil['email']) ?></small></div></div>
        <a class="menu-principal" href="home.php#mapa-estacionamiento">Registrar estacionamiento</a>
        <a href="MiAuto.php">Ingresar un auto</a>
        <a class="activo" href="Estadisticas.php" aria-current="page">Estadísticas</a>
        <a href="EditarPerfil.php">Editar Perfil</a>
        <a class="Menu-salir" href="../Scripts/php/logout.php">Cerrar sesión</a>
      </nav>
    </div>
  </header>

  <main class="estadisticas-contenedor">
    <section class="estadisticas-encabezado">
      <div><p>MI ACTIVIDAD PERSONAL</p><h1>Mis estadísticas de estacionamiento</h1><span>Estos datos pertenecen únicamente a <?= escaparEstadistica($nombreCompleto) ?>.</span></div>
      <a href="home.php#mapa-estacionamiento">Volver al mapa</a>
    </section>

    <section class="resumen-estadisticas" aria-label="Resumen de actividad">
      <article><span>Total de registros</span><strong><?= (int) $resumen['total'] ?></strong><small>Estacionamientos guardados</small></article>
      <article><span>Salidas confirmadas</span><strong><?= (int) $resumen['finalizados'] ?></strong><small>Registros finalizados</small></article>
      <article><span>Tiempo registrado</span><strong><?= escaparEstadistica($horas) ?> h</strong><small>Tiempo acumulado aproximado</small></article>
      <article><span>Calle más usada</span><strong class="dato-calle"><?= escaparEstadistica($favorita['calle']) ?></strong><small><?= (int) $favorita['cantidad'] ?> registros</small></article>
    </section>

    <?php if ((int) $resumen['total'] === 0): ?>
      <section class="estadisticas-vacias"><h2>Todavía no hay datos</h2><p>Cuando registres tu primer estacionamiento, tus gráficos aparecerán en esta sección.</p><a href="home.php#mapa-estacionamiento">Registrar estacionamiento</a></section>
    <?php else: ?>
      <section class="graficas-estadisticas">
        <article class="panel-grafica grafica-ancha"><div><p>EVOLUCIÓN</p><h2>Actividad de los últimos seis meses</h2></div><div class="grafica-lienzo"><canvas id="graficaActividad"></canvas></div></article>
        <article class="panel-grafica"><div><p>ESTADOS</p><h2>Resultado de los registros</h2></div><div class="grafica-lienzo grafica-circular"><canvas id="graficaEstados"></canvas></div></article>
        <article class="panel-grafica"><div><p>UBICACIONES</p><h2>Calles más utilizadas</h2></div><div class="grafica-lienzo"><canvas id="graficaCalles"></canvas></div></article>
      </section>

      <section class="historial-estadisticas">
        <div class="historial-titulo"><div><p>HISTORIAL</p><h2>Estacionamientos recientes</h2></div><span>Últimos <?= count($historial) ?> registros</span></div>
        <div class="historial-tabla-contenedor">
          <table>
            <thead><tr><th>Fecha</th><th>Vehículo</th><th>Calle</th><th>Estado</th><th>Ruta</th></tr></thead>
            <tbody>
              <?php foreach ($historial as $registro): ?>
                <?php $ruta = 'https://www.google.com/maps/dir/?api=1&destination=' . rawurlencode($registro['latitud'] . ',' . $registro['longitud']) . '&travelmode=driving'; ?>
                <tr>
                  <td><strong><?= escaparEstadistica(date('d/m/Y', strtotime($registro['ingreso']))) ?></strong><small><?= escaparEstadistica(date('H:i', strtotime($registro['ingreso']))) ?></small></td>
                  <td><strong><?= escaparEstadistica(strtoupper($registro['matricula'])) ?></strong><small><?= escaparEstadistica($registro['marca'] . ' ' . $registro['modelo']) ?></small></td>
                  <td><?= escaparEstadistica($registro['calle']) ?></td>
                  <td><span class="estado-registro <?= strtolower(escaparEstadistica($registro['estado'])) ?>"><?= escaparEstadistica($registro['estado']) ?></span></td>
                  <td><a class="ruta-historial" href="<?= escaparEstadistica($ruta) ?>" data-destino="<?= escaparEstadistica($registro['latitud'] . ',' . $registro['longitud']) ?>" target="_blank" rel="noopener noreferrer">Cómo llegar</a></td>
                </tr>
              <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      </section>
    <?php endif; ?>
  </main>

  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
  <script src="../Scripts/js/menu_perfil.js?v=20261111-1"></script>
  <script>
    document.addEventListener('click', evento => {
      const enlaceRuta = evento.target.closest('.ruta-historial');
      if (!enlaceRuta) return;
      evento.preventDefault();
      const destino = enlaceRuta.dataset.destino;
      const rutaSinOrigen = 'https://www.google.com/maps/dir/?api=1&destination=' + encodeURIComponent(destino) + '&travelmode=driving&dir_action=navigate';
      const abrirRuta = url => {
        const nuevaVentana = window.open(url, '_blank');
        if (nuevaVentana) nuevaVentana.opener = null;
        else window.location.assign(url);
      };
      enlaceRuta.textContent = 'Obteniendo ubicación...';
      if (!navigator.geolocation) {
        abrirRuta(rutaSinOrigen);
        enlaceRuta.textContent = 'Cómo llegar';
        return;
      }
      navigator.geolocation.getCurrentPosition(
        posicion => {
          const origen = posicion.coords.latitude + ',' + posicion.coords.longitude;
          abrirRuta('https://www.google.com/maps/dir/?api=1&origin=' + encodeURIComponent(origen) + '&destination=' + encodeURIComponent(destino) + '&travelmode=driving&dir_action=navigate');
          enlaceRuta.textContent = 'Cómo llegar';
        },
        () => {
          abrirRuta(rutaSinOrigen);
          enlaceRuta.textContent = 'Cómo llegar';
        },
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      );
    });

    <?php if ((int) $resumen['total'] > 0): ?>
    const datosActividad = <?= json_encode(array_values($meses), JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;
    const datosEstados = <?= json_encode($estados, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;
    const datosCalles = <?= json_encode($calles, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;
    Chart.defaults.font.family = 'Trebuchet MS, Segoe UI, sans-serif';
    Chart.defaults.color = '#586b78';
    new Chart(document.getElementById('graficaActividad'), { type: 'line', data: { labels: datosActividad.map(dato => dato.etiqueta), datasets: [{ label: 'Estacionamientos', data: datosActividad.map(dato => dato.cantidad), borderColor: '#0b5d7a', backgroundColor: 'rgba(57,169,162,.18)', fill: true, tension: .32, pointBackgroundColor: '#39a9a2', pointRadius: 4 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: '#e7ece9' } }, x: { grid: { display: false } } } } });
    new Chart(document.getElementById('graficaEstados'), { type: 'doughnut', data: { labels: Object.keys(datosEstados), datasets: [{ data: Object.values(datosEstados), backgroundColor: ['#39a9a2', '#d98d55', '#0b5d7a'], borderWidth: 0 }] }, options: { responsive: true, maintainAspectRatio: false, cutout: '68%', plugins: { legend: { position: 'bottom', labels: { usePointStyle: true, padding: 18 } } } } });
    new Chart(document.getElementById('graficaCalles'), { type: 'bar', data: { labels: datosCalles.map(dato => dato.calle), datasets: [{ data: datosCalles.map(dato => dato.cantidad), backgroundColor: '#39a9a2', borderRadius: 5 }] }, options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: '#e7ece9' } }, y: { grid: { display: false } } } } });
    <?php endif; ?>
  </script>
</body>
</html>
