<?php
session_start();
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
if (!isset($_SESSION['id_usuario'])) {
  header("Location: ../index.html");
  exit();
}
require_once '../Scripts/php/conexion.php';
date_default_timezone_set('America/Montevideo');
$idUsuario = (int) $_SESSION['id_usuario'];

// ETAPA 2: disponibilidad de los tramos guardados en MySQL.
if (isset($_GET['probabilidades'])) {
  header('Content-Type: application/json; charset=utf-8');
  try {
    $datos = $conexion->query("SELECT v.id_tramo, v.nombre, v.geometria, v.permite_estacionar, v.porcentaje_disponibilidad, v.lugares_libres, v.capacidad_estimada, r.color_hex FROM vista_disponibilidad_tramos v LEFT JOIN rangos_disponibilidad r ON v.porcentaje_disponibilidad BETWEEN r.porcentaje_minimo AND r.porcentaje_maximo")->fetchAll(PDO::FETCH_ASSOC);
    $features = [];
    foreach ($datos as $fila) {
      $geo = json_decode($fila['geometria'], true);
      if (!$geo || ($geo['type'] ?? '') !== 'LineString') continue;
      $features[] = ['type'=>'Feature', 'geometry'=>$geo, 'properties'=>[
        'id_tramo'=>(int)$fila['id_tramo'], 'nombre'=>$fila['nombre'],
        'permite_estacionar'=>(bool)$fila['permite_estacionar'],
        'porcentaje'=>$fila['porcentaje_disponibilidad'] === null ? null : (int)$fila['porcentaje_disponibilidad'],
        'libres'=>$fila['lugares_libres'] === null ? null : (int)$fila['lugares_libres'],
        'capacidad'=>(int)$fila['capacidad_estimada'],
        'color'=>(int)$fila['permite_estacionar'] === 0 ? '#888888' : ($fila['color_hex'] ?: '#888888')]];
    }
    echo json_encode(['type'=>'FeatureCollection','features'=>$features], JSON_UNESCAPED_UNICODE);
  } catch (Exception $error) {
    http_response_code(500);
    echo json_encode(['error'=>'No se pudieron consultar las calles']);
  }
  exit;
}

// Determina el tramo que está más cerca del punto marcado por el usuario.
function buscarTramo($conexion, $latitud, $longitud) {
  $calles = $conexion->query('SELECT id_tramo, geometria, permite_estacionar FROM tramos_calle WHERE activo = 1');
  $cercano = null;
  $distanciaMenor = 20; // metros
  $factorX = 111000 * cos(deg2rad((float)$latitud));
  foreach ($calles as $calle) {
    $geo = json_decode($calle['geometria'], true);
    $puntos = $geo['coordinates'] ?? [];
    for ($i = 0; $i < count($puntos)-1; $i++) {
      $a = $puntos[$i]; $b = $puntos[$i+1];
      $x1 = ($a[0]-$longitud)*$factorX; $y1 = ($a[1]-$latitud)*111000;
      $x2 = ($b[0]-$longitud)*$factorX; $y2 = ($b[1]-$latitud)*111000;
      $dx = $x2-$x1; $dy = $y2-$y1;
      $largo = $dx*$dx+$dy*$dy;
      $t = $largo > 0 ? max(0, min(1, -($x1*$dx+$y1*$dy)/$largo)) : 0;
      $distancia = sqrt(($x1+$t*$dx)**2 + ($y1+$t*$dy)**2);
      if ($distancia < $distanciaMenor) {
        $distanciaMenor = $distancia;
        $cercano = [
          'id_tramo' => (int)$calle['id_tramo'],
          'permite_estacionar' => (bool)$calle['permite_estacionar']
        ];
      }
    }
  }
  return $cercano;
}

// ETAPA 1: fechas completas y salidas confirmadas visibles por cinco minutos.
function obtenerEstacionamientos($conexion) {
  $zonaHoraria = new DateTimeZone('America/Montevideo');
  $sql = "SELECT e.id_estacionamiento, o.id_usuario, o.matricula,
      COALESCE(o.salida_estimada,
        CASE WHEN o.hora_fin <= o.hora_inicio
          THEN DATE_ADD(TIMESTAMP(o.fecha, o.hora_fin), INTERVAL 1 DAY)
          ELSE TIMESTAMP(o.fecha, o.hora_fin) END) AS salida_estimada_completa,
      o.salida_real,
      e.estado, e.latitud, e.longitud,
      TRIM(CONCAT_WS(' ', u.nombre, NULLIF(u.apellido, ''))) AS nombre,
      v.marca, v.modelo, v.anio
    FROM ocupacion o
    INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento
    LEFT JOIN usuario u ON u.id_usuario = o.id_usuario
    INNER JOIN vehiculo v ON v.matricula = o.matricula
    WHERE e.estado = 'Ocupado'
    ORDER BY salida_estimada_completa";
  $consulta = $conexion->prepare($sql);
  $consulta->execute();
  $filas = $consulta->fetchAll(PDO::FETCH_ASSOC);
  foreach ($filas as &$fila) {
    $salidaEstimada = $fila['salida_estimada_completa'];
    $salidaReal = $fila['salida_real'];
    $fila['hora_fin'] = $salidaEstimada ? substr($salidaEstimada, 11, 8) : null;
    $fila['salida'] = $salidaEstimada
      ? (new DateTime($salidaEstimada, $zonaHoraria))->getTimestamp() * 1000
      : null;
    $fila['salida_confirmada'] = $salidaReal
      ? (new DateTime($salidaReal, $zonaHoraria))->getTimestamp() * 1000
      : null;
    unset($fila['salida_estimada_completa'], $fila['salida_real']);
  }
  unset($fila);
  return $filas;
}

// Esta respuesta JSON es consultada por todos los mapas cada cinco segundos.
if (isset($_GET['estacionamientos'])) {
  header('Content-Type: application/json; charset=utf-8');
  try {
    echo json_encode(['ok' => true, 'estacionamientos' => obtenerEstacionamientos($conexion)], JSON_UNESCAPED_UNICODE);
  } catch (PDOException $error) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'mensaje' => 'No se pudieron consultar los estacionamientos']);
  }
  exit();
}


if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'eliminar_estacionamiento') {
  header('Content-Type: application/json; charset=utf-8');
  try {
    $consulta = $conexion->prepare("UPDATE estacionamiento e INNER JOIN ocupacion o ON o.id_estacionamiento = e.id_estacionamiento SET e.estado = 'Cancelado', o.fecha_cancelacion = NOW() WHERE o.id_usuario = ? AND e.estado = 'Ocupado'");
    $consulta->execute([$idUsuario]);
    $guardado = $consulta->rowCount() >= 1;
    if (!$guardado) http_response_code(409);
    echo json_encode(['ok' => $guardado]);
  } catch (PDOException $error) {
    http_response_code(500);
    echo json_encode(['ok' => false]);
  }
  exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'confirmar_salida') {
  header('Content-Type: application/json; charset=utf-8');
  try {
    $consulta = $conexion->prepare("UPDATE estacionamiento e INNER JOIN ocupacion o ON o.id_estacionamiento = e.id_estacionamiento SET e.estado = 'Finalizado', o.salida_real = NOW() WHERE o.id_usuario = ? AND e.estado = 'Ocupado' AND o.salida_real IS NULL");
    $consulta->execute([$idUsuario]);
    $guardado = $consulta->rowCount() >= 1;
    if (!$guardado) http_response_code(409);
    echo json_encode(['ok' => $guardado]);
  } catch (PDOException $error) {
    http_response_code(500);
    echo json_encode(['ok' => false]);
  }
  exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'estacionar') {
  header('Content-Type: application/json; charset=utf-8');
  $matricula = strtoupper(trim($_POST['matricula'] ?? ''));
  $latitud = $_POST['latitud'] ?? '';
  $longitud = $_POST['longitud'] ?? '';
  $horaSalida = $_POST['hora_salida'] ?? '';
  $idEstacionamientoEdicion = trim($_POST['id_estacionamiento'] ?? '');

  $consultaAuto = $conexion->prepare('SELECT COUNT(*) FROM usuario_vehiculo WHERE id_usuario = ? AND matricula = ?');
  $consultaAuto->execute([$idUsuario, $matricula]);
  if (!$consultaAuto->fetchColumn() || !is_numeric($latitud) || !is_numeric($longitud) || !preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', $horaSalida)) {
    http_response_code(422);
    echo json_encode(['ok' => false]);
    exit();
  }

  $zonaHoraria = new DateTimeZone('America/Montevideo');
  $ahora = new DateTime('now', $zonaHoraria);
  $salida = new DateTime($ahora->format('Y-m-d') . ' ' . $horaSalida, $zonaHoraria);
  if ($salida <= $ahora) $salida->modify('+1 day');
  $minutos = (int) ceil(($salida->getTimestamp() - $ahora->getTimestamp()) / 60);

  try {
    $conexion->beginTransaction();
    $bloqueoUsuario = $conexion->prepare('SELECT id_usuario FROM usuario WHERE id_usuario = ? FOR UPDATE');
    $bloqueoUsuario->execute([$idUsuario]);
    $consultaAnterior = $conexion->prepare("SELECT o.id_ocupacion, o.id_estacionamiento FROM ocupacion o INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento WHERE o.id_usuario = ? AND e.estado = 'Ocupado' FOR UPDATE");
    $consultaAnterior->execute([$idUsuario]);
    $anterior = $consultaAnterior->fetch();
    $esEdicion = $idEstacionamientoEdicion !== '';
    if (($anterior && (!$esEdicion || (int)$idEstacionamientoEdicion !== (int)$anterior['id_estacionamiento'])) || (!$anterior && $esEdicion)) {
      $conexion->rollBack();
      http_response_code(409);
      echo json_encode(['ok' => false, 'mensaje' => 'El estacionamiento ya cambió. Actualizá la página.']);
      exit();
    }
    $tramo = buscarTramo($conexion, (float)$latitud, (float)$longitud);
    if (!$tramo) {
      $conexion->rollBack();
      http_response_code(422);
      echo json_encode(['ok' => false, 'mensaje' => 'Seleccioná un lugar sobre uno de los tramos del mapa.']);
      exit();
    }
    if (!$tramo['permite_estacionar']) {
      $conexion->rollBack();
      http_response_code(409);
      echo json_encode(['ok' => false, 'mensaje' => 'Prohibido estacionar en ese tramo.']);
      exit();
    }
    $idTramo = $tramo['id_tramo'];
    if ($anterior) {
      $conexion->prepare('UPDATE estacionamiento SET latitud = ?, longitud = ?, id_tramo = ? WHERE id_estacionamiento = ? AND estado = \'Ocupado\'')
        ->execute([$latitud, $longitud, $idTramo, $anterior['id_estacionamiento']]);
      $conexion->prepare('UPDATE ocupacion SET matricula = ?, salida_estimada = ?, hora_fin = ?, tiempo_estimado = ? WHERE id_ocupacion = ?')
        ->execute([$matricula, $salida->format('Y-m-d H:i:s'), $salida->format('H:i:s'), $minutos, $anterior['id_ocupacion']]);
    } else {
      $conexion->prepare("INSERT INTO estacionamiento (estado, latitud, longitud, id_tramo) VALUES ('Ocupado', ?, ?, ?)")->execute([$latitud, $longitud, $idTramo]);
      $idEstacionamiento = $conexion->lastInsertId();
      $conexion->prepare('INSERT INTO ocupacion (id_usuario, matricula, id_estacionamiento, fecha, hora_inicio, hora_fin, tiempo_estimado, fecha_hora_ingreso, salida_estimada) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)')
        ->execute([$idUsuario, $matricula, $idEstacionamiento, $ahora->format('Y-m-d'), $ahora->format('H:i:s'), $salida->format('H:i:s'), $minutos, $ahora->format('Y-m-d H:i:s'), $salida->format('Y-m-d H:i:s')]);
    }
    $conexion->commit();
  } catch (PDOException $error) {
    if ($conexion->inTransaction()) $conexion->rollBack();
    http_response_code(500);
    echo json_encode(['ok' => false]);
    exit();
  }

  echo json_encode(['ok' => true]);
  exit();
}

$consultaPerfil = $conexion->prepare("SELECT TRIM(CONCAT_WS(' ', nombre, NULLIF(apellido, ''))) AS nombre_completo, email FROM usuario WHERE id_usuario = ?");
$consultaPerfil->execute([$idUsuario]);
$perfilUsuario = $consultaPerfil->fetch(PDO::FETCH_ASSOC) ?: [];
$nombreUsuario = $perfilUsuario['nombre_completo'] ?? ($_SESSION['nombre'] ?? 'Mi perfil');
$emailUsuario = $perfilUsuario['email'] ?? '';
$_SESSION['nombre'] = $nombreUsuario;
$consultaAutos = $conexion->prepare('SELECT v.matricula, v.marca, v.modelo FROM vehiculo v INNER JOIN usuario_vehiculo uv ON uv.matricula = v.matricula WHERE uv.id_usuario = ? ORDER BY v.matricula');
$consultaAutos->execute([$idUsuario]);
$autosUsuario = $consultaAutos->fetchAll(PDO::FETCH_ASSOC);
$autoSolicitado = $_GET['auto'] ?? '';
$autoSeleccionado = count($autosUsuario) === 1 ? $autosUsuario[0]['matricula'] : $autoSolicitado;
$estacionados = obtenerEstacionamientos($conexion);
$estacionamientoPropio = null;
foreach ($estacionados as $estacionado) {
  if ((int) $estacionado['id_usuario'] === $idUsuario && $estacionado['estado'] === 'Ocupado') {
    $estacionamientoPropio = $estacionado;
    $autoSeleccionado = $estacionado['matricula'];
  }
}
$iniciales = strtoupper(substr($nombreUsuario, 0, 2));
function escaparHome($valor)
{
  return htmlspecialchars((string)$valor, ENT_QUOTES, 'UTF-8');
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LOGOPARK</title>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
  <link rel="stylesheet" href="../css/estilos.css?v=20260819-3">
  <link rel="stylesheet" href="../css/usuario.css?v=20261111-4">
</head>
<body class="page-home">
  <div class="encabezado">
    <div class="encabezadoNombre">LOGOPARK</div>
    <div class="perfil-acciones">
      <button class="boton-perfil" id="botonPerfil" type="button" aria-expanded="false" aria-controls="menuPerfil"><span class="Iniciales"><?= escaparHome($iniciales) ?></span><span class="nombre-usuario"><?= escaparHome($nombreUsuario) ?></span><span aria-hidden="true">⌄</span></button>
      <div class="Menu" id="menuPerfil">
        <div class="Menu-header">
          <div class="Iniciales-grande"><?= escaparHome($iniciales) ?></div>
          <div>
            <div class="Menu-nombre"><?= escaparHome($nombreUsuario) ?></div>
            <div class="Menu-email"><?= escaparHome($emailUsuario) ?></div>
          </div>
        </div>
        <a href="home.php#mapa-estacionamiento" class="Menu-item menu-principal activo" aria-current="page">Registrar estacionamiento</a>
        <a href="MiAuto.php" class="Menu-item">Ingresar un auto</a>
        <a href="Estadisticas.php" class="Menu-item">Estadísticas</a>
        <a href="EditarPerfil.php" class="Menu-item">
          Editar Perfil
        </a>
        <a href="../Scripts/php/logout.php" class="Menu-item Menu-salir">
          Cerrar sesión
        </a>
      </div>
    </div>
  </div>
  <div class="aviso-instrucciones">
    <span>Leé nuestras instrucciones de uso.</span>
    <a href="Instrucciones.php">Ver instrucciones</a>
  </div>
  <section class="mapa-estacionamiento" id="mapa-estacionamiento" aria-label="Mapa de estacionamiento">
    <div class="mapa-acciones">
      <select id="vehiculoEstacionamiento" aria-label="Auto para estacionar" <?= empty($autosUsuario) ? 'disabled' : '' ?>>
        <option value=""><?= empty($autosUsuario) ? 'Primero ingresá un auto' : 'Seleccioná tu auto' ?></option>
        <?php foreach ($autosUsuario as $auto): ?>
          <option value="<?= escaparHome($auto['matricula']) ?>" <?= $autoSeleccionado === $auto['matricula'] ? 'selected' : '' ?>><?= escaparHome($auto['matricula'] . ' · ' . $auto['marca'] . ' ' . $auto['modelo']) ?></option>
        <?php endforeach; ?>
      </select>
      <button type="button" id="marcarUbicacion" <?= empty($autosUsuario) ? 'disabled' : '' ?>><?= $estacionamientoPropio ? 'Editar estacionamiento' : 'Marcar mi estacionamiento' ?></button>
      <?php if ($estacionamientoPropio && $estacionamientoPropio['estado'] === 'Ocupado'): ?><button type="button" id="confirmarSalida" class="boton-confirmar-salida">Confirmar salida</button><?php endif; ?>
      <?php if ($estacionamientoPropio): ?><button type="button" id="eliminarEstacionamiento" class="boton-eliminar-estacionamiento">Cancelar estacionamiento</button><?php endif; ?>
      <span id="estadoMapa" aria-live="polite"><?= empty($autosUsuario) ? 'Ingresá un auto antes de estacionar.' : ($estacionamientoPropio ? 'Ya estacionaste. Cuando te vayas, confirmá tu salida.' : 'Elegí tu auto y marcá dónde estacionaste.') ?></span>
    </div>
    <div style="padding:8px 12px;display:flex;gap:12px;flex-wrap:wrap;align-items:center;font-size:13px">
      <span>🟢 75–100% libre</span><span>🟡 25–74% libre</span><span>🔴 0–24% libre</span><span>⚪ Gris: prohibido estacionar</span>
      <span>Disponibilidad simulada + estacionamientos reales</span>
    </div>
    <div class="contenedor-mapa-probabilidades">
      <div id="map"></div>
      <aside class="panel-probabilidades" aria-live="polite">
        <h2>Disponibilidad del tramo</h2>
        <div id="detalleTramo"><span>Seleccioná una línea de color en el mapa.</span></div>
      </aside>
    </div>
  </section>
  <div id="ventanaSalida" class="ventana-salida" hidden>
    <form id="formularioSalida">
      <button type="button" id="cerrarSalida" class="cerrar-salida" aria-label="Cerrar">×</button>
      <h2>¿A qué hora dejás libre el estacionamiento?</h2>
      <label for="horaSalida">Hora estimada de salida</label>
      <input type="time" id="horaSalida" required>
      <button type="submit">Guardar estacionamiento</button>
    </form>
  </div>
  <script src="../Scripts/js/menu_perfil.js?v=20261111-1"></script>
  <script src="../Scripts/js/imagenes_autos.js?v=20261111-1"></script>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <!-- Vector tiles: mantiene Leaflet y permite ocultar POI, comercios y numeración. -->
  <link href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css" rel="stylesheet">
  <script src="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js"></script>
  <script src="https://unpkg.com/@maplibre/maplibre-gl-leaflet@0.1.2/leaflet-maplibre-gl.js"></script>
  <script>
    const ubicacionLiceo = [-34.8906295, -56.1596752];
    const map = L.map('map', { scrollWheelZoom: false }).setView(ubicacionLiceo, 17);
    // ETAPA 2: MapLibre mantiene el fondo vectorial y Leaflet dibuja encima
    // los tramos reales que llegan desde MySQL mediante ?probabilidades.
    async function cargarMapaLimpio() {
      try {
        if (typeof maplibregl === 'undefined' || typeof L.maplibreGL !== 'function') {
          throw new Error('No cargaron las bibliotecas del mapa vectorial');
        }
        const respuesta = await fetch('https://tiles.openfreemap.org/styles/positron');
        if (!respuesta.ok) throw new Error('No se pudo descargar el estilo del mapa');
        const estilo = await respuesta.json();
        estilo.layers = estilo.layers.filter(capa => {
          if (capa.type !== 'symbol') return true;
          return capa['source-layer'] === 'transportation_name' ||
            /(?:road|street|highway|motorway|path)[-_ ]?(?:name|label)|(?:road|street|highway)[-_ ]?label/i.test(capa.id);
        });
        L.maplibreGL({ style: estilo, interactive: false }).addTo(map);
      } catch (error) {
        console.warn('No se pudo cargar el mapa limpio; se usa un fondo de respaldo.', error);
        // Respaldo para que LogoPark siga funcionando sin conexión al estilo vectorial.
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
          maxZoom: 19,
          attribution: '&copy; OpenStreetMap contributors'
        }).addTo(map);
      }
    }
    cargarMapaLimpio();

    const detalleTramo = document.getElementById('detalleTramo');
    const anchoTramo = () => map.getZoom() >= 18 ? 8 : map.getZoom() >= 17 ? 6 : map.getZoom() >= 16 ? 4 : 3;
    const capaTramos = L.geoJSON(null, {
      style: feature => ({
        color: feature.properties.color,
        weight: anchoTramo(),
        opacity: 0.85,
        lineCap: 'round',
        lineJoin: 'round'
      }),
      onEachFeature: (feature, layer) => {
        layer.on('click', () => {
          const nombre = textoSeguroMapa(feature.properties.nombre);
          if (!feature.properties.permite_estacionar) {
            detalleTramo.innerHTML = `<strong>${nombre}</strong><span>Prohibido estacionar</span>`;
            if (modoManual) {
              modoManual = false;
              botonUbicacion.textContent = textoBoton;
              map.getContainer().classList.remove('modo-manual');
              estadoMapa.textContent = 'Prohibido estacionar en ese tramo.';
            }
            return;
          }
          if (feature.properties.porcentaje === null) {
            detalleTramo.innerHTML = `<strong>${nombre}</strong><span>Sin datos de disponibilidad</span>`;
            return;
          }
          detalleTramo.innerHTML = `<strong>${nombre}</strong><span>${feature.properties.porcentaje}% disponible · ${feature.properties.libres} de ${feature.properties.capacidad} lugares libres</span>`;
        });
      }
    }).addTo(map);
    map.on('zoomend', () => capaTramos.setStyle(feature => ({
      color: feature.properties.color,
      weight: anchoTramo(),
      opacity: 0.85,
      lineCap: 'round',
      lineJoin: 'round'
    })));

    function textoSeguroMapa(valor) {
      return String(valor ?? '').replace(/[&<>"']/g, caracter => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' })[caracter]);
    }

    async function consultarProbabilidades() {
      try {
        const respuesta = await fetch('home.php?probabilidades=1&_=' + Date.now(), { cache: 'no-store' });
        if (!respuesta.ok) throw new Error();
        const datos = await respuesta.json();
        if (datos.type !== 'FeatureCollection' || !Array.isArray(datos.features)) throw new Error();
        capaTramos.clearLayers();
        capaTramos.addData(datos);
      } catch (error) {
        detalleTramo.textContent = 'No se pudieron actualizar las probabilidades.';
      }
    }
    consultarProbabilidades();
    setInterval(consultarProbabilidades, 5000);

    L.circleMarker(ubicacionLiceo, {
      radius: 10,
      color: '#08233f',
      weight: 4,
      fillColor: '#20aee5',
      fillOpacity: 1
    }).addTo(map)
      .bindTooltip('Liceo Logosófico', { permanent: true, direction: 'top', className: 'etiqueta-liceo' })
      .bindPopup('<strong>Liceo Logosófico</strong><br>Dr. Manuel Albo 2707');
    const iconos = {
      verde: L.icon({ iconUrl: '../Imagenes/auto-verde.png', iconSize: [48, 48], iconAnchor: [24, 24], popupAnchor: [0, -18], className: 'icono-auto' }),
      amarillo: L.icon({ iconUrl: '../Imagenes/auto-amarillo.png', iconSize: [48, 48], iconAnchor: [24, 24], popupAnchor: [0, -18], className: 'icono-auto' }),
      rojo: L.icon({ iconUrl: '../Imagenes/auto-rojo.png', iconSize: [48, 48], iconAnchor: [24, 24], popupAnchor: [0, -18], className: 'icono-auto' })
    };
    // ETAPA 1: rojo > 30 min; amarillo > 5 y <= 30; verde <= 5 o confirmada.
    function colorPorTiempo(salidaEstimada) {
      const salida = Number(salidaEstimada);
      if (!Number.isFinite(salida) || salida <= 0) return 'rojo';
      const minutos = (salida - Date.now()) / 60000;
      if (minutos <= 5) return 'verde';
      if (minutos <= 30) return 'amarillo';
      return 'rojo';
    }
    const marcadores = new Map();
    const usuarioActual = <?= $idUsuario ?>;
    let esperandoLiberacionPropia = false;

    function crearContenido(docente) {
      const matricula = docente.matricula.replace(/[^A-Z0-9]/gi, '').toUpperCase();
      const matriculaOculta = matricula.slice(0, 3) + ' ' + matricula.slice(3, 5) + '*'.repeat(Math.max(0, matricula.length - 5));
      const textoSeguro = valor => String(valor ?? '').replace(/[&<>"']/g, caracter => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' })[caracter]);
      const nombre = textoSeguro(docente.nombre);
      const marca = textoSeguro(docente.marca);
      const modelo = textoSeguro(docente.modelo);
      const anio = textoSeguro(docente.anio);
      const destino = Number(docente.latitud) + ',' + Number(docente.longitud);
      const rutaGoogleMaps = 'https://www.google.com/maps/dir/?api=1&destination=' + encodeURIComponent(destino) + '&travelmode=driving';
      const contenido = document.createElement('div');
      const salidaConfirmada = docente.estado === 'Finalizado';
      contenido.innerHTML = `<article class="tarjeta-docente tarjeta-mapa">
          <div class="nombre-docente">${nombre}</div>
          <div class="matricula-mapa"><span>Matrícula</span><strong>${matriculaOculta}</strong></div>
          <div class="imagen-auto-mapa"><img data-auto-marca="${marca}" data-auto-modelo="${modelo}" data-auto-anio="${anio}" data-auto-ancho="400" alt="Imagen de ${marca} ${modelo}"></div>
          <div class="dato-docente dato-mapa dato-hora"><span class="etiqueta">${salidaConfirmada ? 'Estado' : 'Hora estimada de salida'}</span><strong class="estado-salida">${salidaConfirmada ? 'Salida confirmada hace 0 min' : docente.hora_fin.slice(0, 5)}</strong></div>
          <a class="boton-como-ir" href="${rutaGoogleMaps}" data-destino="${destino}" target="_blank" rel="noopener noreferrer">Cómo llegar</a>
        </article>`;
      if (salidaConfirmada) {
        const minutosDesdeSalida = Math.max(0, Math.floor((Date.now() - Number(docente.salida_confirmada)) / 60000));
        contenido.querySelector('.estado-salida').textContent = 'Salida confirmada hace ' + minutosDesdeSalida + ' min';
      }
      return contenido;
    }

    function actualizarMarcadores(estacionamientos) {
      const recibidos = new Set();
      let apareceEstacionamientoPropio = false;
      estacionamientos.forEach(docente => {
        const id = String(docente.id_estacionamiento);
        recibidos.add(id);
        if (Number(docente.id_usuario) === usuarioActual) apareceEstacionamientoPropio = true;
        const salidaConfirmada = docente.estado === 'Finalizado';
        const icono = iconos[salidaConfirmada ? 'verde' : colorPorTiempo(docente.salida)];
        const contenido = crearContenido(docente);
        let marcador = marcadores.get(id);
        if (!marcador) {
          marcador = L.marker([docente.latitud, docente.longitud], { icon: icono }).addTo(map);
          marcadores.set(id, marcador);
        }
        marcador.setLatLng([docente.latitud, docente.longitud]);
        marcador.setIcon(icono);
        marcador.bindPopup(contenido);
      });

      // Si MySQL ya liberó el lugar, el marcador deja de venir en la consulta.
      marcadores.forEach((marcador, id) => {
        if (!recibidos.has(id)) {
          map.removeLayer(marcador);
          marcadores.delete(id);
        }
      });

      // Cuando MySQL cumple los cinco minutos, se recarga una sola vez para habilitar los controles.
      if (esperandoLiberacionPropia && !apareceEstacionamientoPropio) {
        esperandoLiberacionPropia = false;
        location.reload();
      }
    }

    async function consultarEstacionamientos() {
      try {
        const respuesta = await fetch('home.php?estacionamientos=1&_=' + Date.now(), { cache: 'no-store' });
        if (!respuesta.ok) throw new Error();
        const datos = await respuesta.json();
        if (!datos.ok || !Array.isArray(datos.estacionamientos)) throw new Error();
        actualizarMarcadores(datos.estacionamientos);
      } catch (error) {
        console.error('No se pudieron actualizar los estacionamientos.', error);
      }
    }

    actualizarMarcadores(<?= json_encode($estacionados, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>);

    document.addEventListener('click', evento => {
      const enlaceRuta = evento.target.closest('.boton-como-ir');
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
    // La misma consulta actualiza autos nuevos, colores y salidas confirmadas.
    setInterval(consultarEstacionamientos, 5000);
    const botonUbicacion = document.getElementById('marcarUbicacion');
    const vehiculoEstacionamiento = document.getElementById('vehiculoEstacionamiento');
    const estadoMapa = document.getElementById('estadoMapa');
    const ventanaSalida = document.getElementById('ventanaSalida');
    const formularioSalida = document.getElementById('formularioSalida');
    const horaSalida = document.getElementById('horaSalida');
    let textoBoton = <?= $estacionamientoPropio ? "'Editar estacionamiento'" : "'Marcar mi estacionamiento'" ?>;
    let idEstacionamientoActivo = <?= json_encode($estacionamientoPropio['id_estacionamiento'] ?? '') ?>;
    let horaSalidaExistente = <?= json_encode($estacionamientoPropio ? substr($estacionamientoPropio['hora_fin'], 0, 5) : null) ?>;
    let posicionElegida;
    let modoManual = false;
    botonUbicacion.addEventListener('click', () => {
      if (!vehiculoEstacionamiento.value) {
        estadoMapa.textContent = 'Seleccioná el auto con el que estacionaste.';
        return;
      }
      modoManual = !modoManual;
      botonUbicacion.textContent = modoManual ? 'Cancelar' : textoBoton;
      map.getContainer().classList.toggle('modo-manual', modoManual);
      estadoMapa.textContent = modoManual ? 'Tocá en el mapa el lugar donde estacionaste.' : 'Selección cancelada.';
    });
    map.on('click', ({ latlng }) => {
      if (!modoManual) return;
      posicionElegida = latlng;
      modoManual = false;
      botonUbicacion.textContent = textoBoton;
      map.getContainer().classList.remove('modo-manual');
      const sugerida = new Date(Date.now() + 60 * 60000);
      horaSalida.value = horaSalidaExistente || (String(sugerida.getHours()).padStart(2, '0') + ':' + String(sugerida.getMinutes()).padStart(2, '0'));
      ventanaSalida.hidden = false;
      horaSalida.focus();
    });
    document.getElementById('cerrarSalida').addEventListener('click', () => ventanaSalida.hidden = true);
    const botonConfirmarSalida = document.getElementById('confirmarSalida');
    const botonEliminar = document.getElementById('eliminarEstacionamiento');

    async function prepararNuevoEstacionamiento(mensaje) {
      idEstacionamientoActivo = '';
      horaSalidaExistente = null;
      posicionElegida = undefined;
      modoManual = false;
      textoBoton = 'Marcar mi estacionamiento';
      botonUbicacion.textContent = textoBoton;
      map.getContainer().classList.remove('modo-manual');
      ventanaSalida.hidden = true;
      botonConfirmarSalida?.remove();
      botonEliminar?.remove();
      esperandoLiberacionPropia = false;
      estadoMapa.textContent = mensaje;
      await Promise.all([consultarEstacionamientos(), consultarProbabilidades()]);
    }

    function recargarControlesDesdeServidor() {
      window.location.replace('home.php?actualizado=' + Date.now() + '#mapa-estacionamiento');
    }

    if (botonConfirmarSalida) botonConfirmarSalida.addEventListener('click', () => {
      if (!confirm('¿Confirmás que ya saliste del estacionamiento?')) return;
      fetch('home.php', { method: 'POST', body: new URLSearchParams({ accion: 'confirmar_salida' }) })
        .then(async respuesta => {
          if (!respuesta.ok) throw new Error();
          await prepararNuevoEstacionamiento('Salida confirmada. Ya podés registrar otro estacionamiento.');
          recargarControlesDesdeServidor();
        })
        .catch(() => estadoMapa.textContent = 'No se pudo confirmar la salida.');
    });
    if (botonEliminar) botonEliminar.addEventListener('click', () => {
      if (!confirm('¿Querés cancelar este estacionamiento? Quedará registrado en el historial.')) return;
      fetch('home.php', { method: 'POST', body: new URLSearchParams({ accion: 'eliminar_estacionamiento' }) })
        .then(async respuesta => {
          if (!respuesta.ok) throw new Error();
          await prepararNuevoEstacionamiento('Estacionamiento cancelado. Ya podés registrar otro.');
          recargarControlesDesdeServidor();
        })
        .catch(() => estadoMapa.textContent = 'No se pudo cancelar el estacionamiento.');
    });
    formularioSalida.addEventListener('submit', evento => {
      evento.preventDefault();
      const datos = new URLSearchParams({ accion: 'estacionar', id_estacionamiento: idEstacionamientoActivo, matricula: vehiculoEstacionamiento.value, latitud: posicionElegida.lat, longitud: posicionElegida.lng, hora_salida: horaSalida.value });
      fetch('home.php', { method: 'POST', body: datos })
        .then(async respuesta => {
          const resultado = await respuesta.json().catch(() => ({}));
          if (!respuesta.ok || !resultado.ok) throw new Error(resultado.mensaje || 'No se pudo guardar el estacionamiento.');
          location.reload();
        })
        .catch(error => {
          ventanaSalida.hidden = true;
          estadoMapa.textContent = error.message || 'No se pudo guardar el estacionamiento.';
        });
    });
  </script>
</body>
</html>
