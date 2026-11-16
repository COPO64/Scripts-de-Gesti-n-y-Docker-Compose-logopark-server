<?php
session_start();
if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../index.html');
    exit();
}
require_once '../Scripts/php/conexion.php';
$id_usuario = $_SESSION['id_usuario'];
function escapar($texto)
{
    return htmlspecialchars((string) $texto, ENT_QUOTES, 'UTF-8');
}
function normalizarMatricula($matricula)
{
    return strtoupper(preg_replace('/\s+/', ' ', trim($matricula)));
}
function leerDatosAuto()
{
    return [
        'matricula' => normalizarMatricula($_POST['matricula'] ?? ''),
        'marca' => trim($_POST['marca'] ?? ''),
        'modelo' => trim($_POST['modelo'] ?? ''),
        'anio' => (int) ($_POST['anio'] ?? 0),
        'color' => trim($_POST['color'] ?? ''),
        'tamanio' => trim($_POST['tamanio'] ?? '')
    ];
}
function datosAutoCompletos($auto)
{
    return $auto['matricula'] !== ''
        && $auto['marca'] !== ''
        && $auto['modelo'] !== ''
        && $auto['anio'] > 0
        && $auto['color'] !== ''
        && $auto['tamanio'] !== '';
}
$url = "https://carapi.app/api/makes/v2?year=2020&limit=100";
$curl = curl_init($url);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
$respuesta = curl_exec($curl);
curl_close($curl);
$datos = json_decode($respuesta, true);
$marcas = $datos['data'] ?? [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'] ?? '';
    if ($accion === 'agregar') {
        $auto = leerDatosAuto();
        if (!datosAutoCompletos($auto)) {
            header('Location: MiAuto.php?error=datos');
            exit();
        }
        try {
            $conexion->beginTransaction();
            $consulta = $conexion->prepare(
                'INSERT INTO vehiculo
                (matricula, marca, modelo, anio, color, tamanio)
                VALUES (?, ?, ?, ?, ?, ?)'
            );
            $consulta->execute([
                $auto['matricula'],
                $auto['marca'],
                $auto['modelo'],
                $auto['anio'],
                $auto['color'],
                $auto['tamanio']
            ]);
            $consulta = $conexion->prepare(
                'INSERT INTO usuario_vehiculo
                (id_usuario, matricula)
                VALUES (?, ?)'
            );
            $consulta->execute([
                $id_usuario,
                $auto['matricula']
            ]);
            $conexion->commit();
            header('Location: MiAuto.php?guardado=1');
            exit();
        } catch (PDOException $error) {
            if ($conexion->inTransaction()) {
                $conexion->rollBack();
            }
            header('Location: MiAuto.php?error=repetido');
            exit();
        }
    }
    if ($accion === 'editar') {
        $matriculaOriginal = normalizarMatricula($_POST['matricula_original'] ?? '');
        $auto = leerDatosAuto();
        if ($matriculaOriginal === '' || !datosAutoCompletos($auto)) {
            header('Location: MiAuto.php?error=editar');
            exit();
        }
        try {
            $conexion->beginTransaction();
            $consulta = $conexion->prepare('SELECT COUNT(*) FROM usuario_vehiculo WHERE id_usuario = ? AND matricula = ?');
            $consulta->execute([$id_usuario, $matriculaOriginal]);
            if (!$consulta->fetchColumn()) {
                throw new PDOException('Auto no encontrado');
            }
            if ($auto['matricula'] !== $matriculaOriginal) {
                $consulta = $conexion->prepare('INSERT INTO vehiculo (matricula, marca, modelo, anio, color, tamanio) VALUES (?, ?, ?, ?, ?, ?)');
                $consulta->execute([$auto['matricula'], $auto['marca'], $auto['modelo'], $auto['anio'], $auto['color'], $auto['tamanio']]);
                // La matrícula nueva se aplica solamente al estacionamiento activo.
                // Los registros finalizados conservan el vehículo histórico original.
                $conexion->prepare("UPDATE ocupacion o INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento SET o.matricula = ? WHERE o.matricula = ? AND o.id_usuario = ? AND e.estado = 'Ocupado'")
                    ->execute([$auto['matricula'], $matriculaOriginal, $id_usuario]);
                $conexion->prepare('INSERT INTO usuario_vehiculo (id_usuario, matricula) VALUES (?, ?)')->execute([$id_usuario, $auto['matricula']]);
                $conexion->prepare('DELETE FROM usuario_vehiculo WHERE id_usuario = ? AND matricula = ?')->execute([$id_usuario, $matriculaOriginal]);
                $conexion->prepare('DELETE FROM vehiculo WHERE matricula = ? AND NOT EXISTS (SELECT 1 FROM usuario_vehiculo WHERE matricula = ?) AND NOT EXISTS (SELECT 1 FROM ocupacion WHERE matricula = ?)')->execute([$matriculaOriginal, $matriculaOriginal, $matriculaOriginal]);
            } else {
                $consulta = $conexion->prepare('UPDATE vehiculo SET marca = ?, modelo = ?, anio = ?, color = ?, tamanio = ? WHERE matricula = ?');
                $consulta->execute([$auto['marca'], $auto['modelo'], $auto['anio'], $auto['color'], $auto['tamanio'], $auto['matricula']]);
            }
            $conexion->commit();
            header('Location: MiAuto.php?editado=1');
            exit();
        } catch (PDOException $error) {
            if ($conexion->inTransaction()) {
                $conexion->rollBack();
            }
            header('Location: MiAuto.php?error=editar');
            exit();
        }
    }
    if ($accion === 'eliminar') {
        $matricula = normalizarMatricula($_POST['matricula'] ?? '');
        if ($matricula !== '') {
            try {
                $conexion->beginTransaction();
                $consulta = $conexion->prepare(
                    "SELECT COUNT(*)
                    FROM ocupacion o
                    INNER JOIN estacionamiento e ON e.id_estacionamiento = o.id_estacionamiento
                    WHERE o.id_usuario = ? AND o.matricula = ?
                    AND (e.estado = 'Ocupado' OR (e.estado = 'Finalizado' AND o.salida_real > DATE_SUB(NOW(), INTERVAL 5 MINUTE)))"
                );
                $consulta->execute([$id_usuario, $matricula]);
                if ($consulta->fetchColumn() > 0) {
                    $conexion->rollBack();
                    header('Location: MiAuto.php?error=estacionamiento');
                    exit();
                }
                $consulta = $conexion->prepare(
                    'DELETE FROM usuario_vehiculo
                    WHERE id_usuario = ?
                    AND matricula = ?'
                );
                $consulta->execute([
                    $id_usuario,
                    $matricula
                ]);
                $consulta = $conexion->prepare(
                    'DELETE FROM vehiculo
                    WHERE matricula = ?
                    AND NOT EXISTS (
                        SELECT 1
                        FROM usuario_vehiculo
                        WHERE matricula = ?
                    )'
                    . ' AND NOT EXISTS (SELECT 1 FROM ocupacion WHERE matricula = ?)'
                );
                $consulta->execute([
                    $matricula,
                    $matricula,
                    $matricula
                ]);
                $conexion->commit();
                header('Location: MiAuto.php?eliminado=1');
                exit();
            } catch (PDOException $error) {
                if ($conexion->inTransaction()) {
                    $conexion->rollBack();
                }
            }
        }
        header('Location: MiAuto.php?error=eliminar');
        exit();
    }
}
$consulta = $conexion->prepare(
    'SELECT
        v.matricula,
        v.marca,
        v.modelo,
        v.anio,
        v.color,
        v.tamanio
    FROM vehiculo v
    INNER JOIN usuario_vehiculo uv
        ON uv.matricula = v.matricula
    WHERE uv.id_usuario = ?
    ORDER BY v.matricula'
);
$consulta->execute([$id_usuario]);
$autos = $consulta->fetchAll(PDO::FETCH_ASSOC);
$nombre = $_SESSION['nombre'] ?? 'Mi perfil';
$consultaEmail = $conexion->prepare('SELECT email FROM usuario WHERE id_usuario = ?');
$consultaEmail->execute([$id_usuario]);
$emailUsuario = $consultaEmail->fetchColumn() ?: '';
$iniciales = strtoupper(substr($nombre, 0, 2));
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LOGOPARK - Mis autos</title>
    <link rel="stylesheet" href="../css/estilos.css?v=20260819-4">
    <link rel="stylesheet" href="../css/usuario.css?v=20261111-4">
</head>
<body class="page-autos">
    <header class="encabezado">
        <a class="encabezadoNombre" href="home.php">
            LOGOPARK
        </a>
        <div class="perfil-acciones">
            <button id="botonPerfil" class="boton-perfil" type="button" aria-expanded="false"
                aria-controls="menuPerfil">
                <span class="Iniciales">
                    <?= escapar($iniciales) ?>
                </span>
                <span class="nombre-usuario">
                    <?= escapar($nombre) ?>
                </span>
                <span aria-hidden="true">
                    ⌄
                </span>
            </button>
            <nav id="menuPerfil" class="Menu">
                <div class="Menu-header">
                    <span class="Iniciales-grande">
                        <?= escapar($iniciales) ?>
                    </span>
                    <div>
                        <strong><?= escapar($nombre) ?></strong>
                        <small><?= escapar($emailUsuario) ?></small>
                    </div>
                </div>
                <a class="menu-principal" href="home.php#mapa-estacionamiento">
                    Registrar estacionamiento
                </a>
                <a class="activo" href="MiAuto.php">
                    Ingresar un auto
                </a>
                <a href="Estadisticas.php">
                    Estadísticas
                </a>
                <a href="EditarPerfil.php">
                    Editar Perfil
                </a>
                <a class="Menu-salir" href="../Scripts/php/logout.php">
                    Cerrar sesión
                </a>
            </nav>
        </div>
    </header>
    <main class="autos-layout">
        <section class="autos-intro">
            <img src="../Imagenes/logo-logopark-transparente.png" alt="Logo LogoPark">
            <p>MIS AUTOS</p>
            <span>
                Registrá los vehículos que usás para estacionar.
            </span>
        </section>
        <section class="autos-formulario">
            <h1>Ingresar un auto</h1>
            <p>
                Completá los datos del vehículo.
            </p>
            <?php if (isset($_GET['guardado']) || isset($_GET['editado']) || isset($_GET['eliminado'])): ?>
                <div class="mensaje-exito">
                    <?php if (isset($_GET['editado'])): ?>Auto editado correctamente.<?php elseif (isset($_GET['eliminado'])): ?>Auto eliminado correctamente.<?php else: ?>Auto guardado correctamente.<?php endif; ?>
                </div>
            <?php elseif (isset($_GET['error'])): ?>
                <div class="mensaje-error">
                    <?php if ($_GET['error'] === 'estacionamiento'): ?>
                        No podés eliminar este auto mientras tenga un estacionamiento activo o hayan pasado menos de cinco minutos desde su salida.
                    <?php else: ?>
                        No se pudo guardar. Verificá los datos o comprobá que la matrícula no esté repetida.
                    <?php endif; ?>
                </div>
            <?php endif; ?>
            <form action="MiAuto.php" method="post" id="formularioAuto">
                <input type="hidden" name="accion" value="agregar">
                <input type="hidden" id="marcaGuardar" name="marca">
                <input type="hidden" id="modeloGuardar" name="modelo">
                <div class="campos-grid">
                    <div>
                        <label for="matricula">
                            Matrícula
                        </label>
                        <input id="matricula" class="campo-matricula" name="matricula" type="text" maxlength="10" placeholder="ABC 1234" autocapitalize="characters"
                            required>
                    </div>
                    <div>
                        <label for="anio">
                            Año
                        </label>
                        <select id="anio" name="anio" required>
                            <option value="">
                                Seleccioná un año
                            </option>
                            <?php for ($a = 2020; $a >= 2015; $a--): ?>
                                <option value="<?= $a ?>">
                                    <?= $a ?>
                                </option>
                            <?php endfor; ?>
                        </select>
                    </div>
                    <div>
                        <label for="marca">
                            Marca
                        </label>
                        <select id="marca" required>
                            <option value="">
                                Seleccioná una marca
                            </option>
                            <?php foreach ($marcas as $marcaAPI): ?>
                                <option value="<?= escapar($marcaAPI['name']) ?>" data-id="<?= escapar($marcaAPI['id']) ?>">
                                    <?= escapar($marcaAPI['name']) ?>
                                </option>
                            <?php endforeach; ?>
                            <option value="Otro">
                                Otro / No aparece mi marca
                            </option>
                        </select>
                    </div>
                    <div id="marcaManualContenedor" style="display:none;">
                        <label for="marcaManual">
                            Escribí la marca
                        </label>
                        <input id="marcaManual" type="text" placeholder="Ej: Suzuki">
                    </div>
                    <div id="modeloContenedor">
                        <label for="modelo">
                            Modelo
                        </label>
                        <select id="modelo" required>
                            <option value="">
                                Primero elegí año y marca
                            </option>
                        </select>
                    </div>
                    <div id="modeloManualContenedor" style="display:none;">
                        <label for="modeloManual">
                            Escribí el modelo
                        </label>
                        <input id="modeloManual" type="text" placeholder="Ej: Swift">
                    </div>
                    <div id="versionContenedor">
                        <label for="version">
                            Versión
                        </label>
                        <select id="version" name="version" required>
                            <option value="">
                                Primero elegí un modelo
                            </option>
                        </select>
                    </div>
                    <div>
                        <label for="color">
                            Color
                        </label>
                        <select id="color" name="color" required>
                            <option value="">
                                Seleccioná
                            </option>
                            <option>Blanco</option>
                            <option>Negro</option>
                            <option>Gris</option>
                            <option>Rojo</option>
                            <option>Azul</option>
                            <option>Otro</option>
                        </select>
                    </div>
                    <div>
                        <label for="tamano">
                            Tamaño
                        </label>
                        <select id="tamano" name="tamanio" required>
                            <option value="">
                                Seleccioná
                            </option>
                            <option value="Chico">
                                Chico
                            </option>
                            <option value="Mediano">
                                Mediano
                            </option>
                            <option value="Grande">
                                Grande
                            </option>
                        </select>
                        <small id="mensajeMedidas">
                            Elegí una versión para calcular
                            el tamaño automáticamente.
                        </small>
                    </div>
                </div>
                <div id="vistaPreviaAuto" style="
                        display:none;
                        margin-top:24px;
                        text-align:center;
                    ">
                    <h3>
                        Vista previa del auto
                    </h3>
                    <div id="imagenPreviaContenedor" style="
                            max-width:520px;
                            margin:auto;
                            min-height:220px;
                        ">
                    </div>
                    <small>
                        La imagen es una representación
                        del modelo seleccionado.
                    </small>
                </div>
                <div class="acciones">
                    <a href="home.php">
                        Cancelar
                    </a>
                    <button type="submit">
                        Guardar auto
                    </button>
                </div>
            </form>
        </section>
    </main>
    <section class="mis-autos">
        <h2>
            Autos registrados
        </h2>
        <?php if (empty($autos)): ?>
            <p class="sin-autos">
                Todavía no ingresaste ningún auto.
            </p>
        <?php else: ?>
            <div class="autos-lista">
                <?php foreach ($autos as $auto): ?>
                    <article class="auto-card">
                        <?php if (!empty($auto['anio'])): ?>
                            <div style="
                                    width:100%;
                                    min-height:170px;
                                    display:flex;
                                    align-items:center;
                                    justify-content:center;
                                    margin-bottom:14px;
                                ">
                                <img data-auto-marca="<?= escapar($auto['marca']) ?>"
                                    data-auto-modelo="<?= escapar($auto['modelo']) ?>" data-auto-anio="<?= escapar($auto['anio']) ?>"
                                    data-auto-ancho="400" alt="<?= escapar(
                                        $auto['marca']
                                        . ' '
                                        . $auto['modelo']
                                    ) ?>" style="
                                        width:100%;
                                        max-width:320px;
                                        height:170px;
                                        object-fit:contain;
                                    ">
                            </div>
                        <?php endif; ?>
                        <strong>
                            <?= escapar(strtoupper($auto['matricula'])) ?>
                        </strong>
                        <dl>
                            <div>
                                <dt>Marca</dt>
                                <dd>
                                    <?= escapar($auto['marca']) ?>
                                </dd>
                            </div>
                            <div>
                                <dt>Modelo</dt>
                                <dd>
                                    <?= escapar($auto['modelo']) ?>
                                </dd>
                            </div>
                            <div>
                                <dt>Año</dt>
                                <dd>
                                    <?php if (!empty($auto['anio'])): ?>
                                        <?= escapar($auto['anio']) ?>
                                    <?php else: ?>
                                        Sin dato
                                    <?php endif; ?>
                                </dd>
                            </div>
                            <div>
                                <dt>Color</dt>
                                <dd>
                                    <?= escapar($auto['color']) ?>
                                </dd>
                            </div>
                            <div>
                                <dt>Tamaño</dt>
                                <dd>
                                    <?= escapar($auto['tamanio']) ?>
                                </dd>
                            </div>
                        </dl>
                        <details class="edicion-auto">
                            <summary>Editar auto</summary>
                        <form action="MiAuto.php" method="post" class="formulario-editar-auto">
                            <input type="hidden" name="accion" value="editar">
                            <input type="hidden" name="matricula_original" value="<?= escapar($auto['matricula']) ?>">
                            <label>Matrícula
                                <input class="campo-matricula" name="matricula" type="text" maxlength="10" value="<?= escapar(strtoupper($auto['matricula'])) ?>" autocapitalize="characters" required>
                            </label>
                            <label>Marca
                                <input name="marca" type="text" maxlength="50" value="<?= escapar($auto['marca']) ?>" required>
                            </label>
                            <label>Modelo
                                <input name="modelo" type="text" maxlength="50" value="<?= escapar($auto['modelo']) ?>" required>
                            </label>
                            <label>Año
                                <input name="anio" type="number" min="1900" max="<?= date('Y') + 1 ?>" value="<?= escapar($auto['anio']) ?>" required>
                            </label>
                            <label>Color
                                <input name="color" type="text" maxlength="30" value="<?= escapar($auto['color']) ?>" required>
                            </label>
                            <label>Tamaño
                                <select name="tamanio" required>
                                    <?php foreach (['Chico', 'Mediano', 'Grande'] as $opcionTamano): ?>
                                        <option value="<?= $opcionTamano ?>" <?= $auto['tamanio'] === $opcionTamano ? 'selected' : '' ?>><?= $opcionTamano ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </label>
                            <div class="acciones-edicion">
                                <button type="submit">Guardar cambios</button>
                            </div>
                        </form>
                        </details>
                        <form action="MiAuto.php" method="post" class="formulario-eliminar-auto" onsubmit="return confirm('¿Eliminar este auto de tu lista? Su historial se conservará.');">
                            <input type="hidden" name="accion" value="eliminar">
                            <input type="hidden" name="matricula" value="<?= escapar($auto['matricula']) ?>">
                            <button class="btn-eliminar" type="submit">
                                Eliminar auto
                            </button>
                        </form>
                    </article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </section>
    <script src="../Scripts/js/menu_perfil.js?v=20261111-1"></script>
    <script src="../Scripts/js/imagenes_autos.js?v=20261111-1"></script>
    <script>
        const anio = document.getElementById('anio');
        const marca = document.getElementById('marca');
        const modelo = document.getElementById('modelo');
        const version = document.getElementById('version');
        const tamano = document.getElementById('tamano');
        const marcaManual =
            document.getElementById('marcaManual');
        const modeloManual =
            document.getElementById('modeloManual');
        const marcaManualContenedor =
            document.getElementById('marcaManualContenedor');
        const modeloManualContenedor =
            document.getElementById('modeloManualContenedor');
        const modeloContenedor =
            document.getElementById('modeloContenedor');
        const versionContenedor =
            document.getElementById('versionContenedor');
        const marcaGuardar =
            document.getElementById('marcaGuardar');
        const modeloGuardar =
            document.getElementById('modeloGuardar');
        const mensajeMedidas =
            document.getElementById('mensajeMedidas');
        const formulario =
            document.getElementById('formularioAuto');
        const vistaPreviaAuto =
            document.getElementById('vistaPreviaAuto');
        const imagenPreviaContenedor =
            document.getElementById('imagenPreviaContenedor');
        function cargarModelos() {
            if (
                anio.value === '' ||
                marca.value === '' ||
                marca.value === 'Otro'
            ) {
                return;
            }
            modelo.innerHTML =
                '<option value="">Cargando modelos...</option>';
            version.innerHTML =
                '<option value="">Primero elegí un modelo</option>';
            tamano.value = '';
            const opcionMarca =
                marca.options[marca.selectedIndex];
            const idMarca =
                opcionMarca.getAttribute('data-id');
            fetch(
                '../Scripts/php/carapi_modelos.php'
                + '?marca='
                + encodeURIComponent(idMarca)
                + '&anio='
                + encodeURIComponent(anio.value)
            )
                .then(function (respuesta) {
                    return respuesta.json();
                })
                .then(function (datos) {
                    modelo.innerHTML =
                        '<option value="">Seleccioná un modelo</option>';
                    if (datos.data) {
                        datos.data.forEach(function (auto) {
                            const opcion =
                                document.createElement('option');
                            opcion.value = auto.name;
                            opcion.textContent = auto.name;
                            modelo.appendChild(opcion);
                        });
                    }
                    const otro =
                        document.createElement('option');
                    otro.value = 'Otro';
                    otro.textContent =
                        'Otro / No aparece mi modelo';
                    modelo.appendChild(otro);
                })
                .catch(function () {
                    modelo.innerHTML =
                        '<option value="">Error al cargar modelos</option>';
                    mensajeMedidas.textContent =
                        'No se pudieron cargar los modelos.';
                });
        }
        function cargarVersiones() {
            if (
                anio.value === '' ||
                marca.value === '' ||
                modelo.value === ''
            ) {
                return;
            }
            version.innerHTML =
                '<option value="">Cargando versiones...</option>';
            tamano.value = '';
            const parametros =
                new URLSearchParams({
                    anio: anio.value,
                    marca: marca.value,
                    modelo: modelo.value
                });
            fetch(
                '../Scripts/php/carapi_versiones.php?'
                + parametros.toString()
            )
                .then(function (respuesta) {
                    return respuesta.json();
                })
                .then(function (datos) {
                    version.innerHTML =
                        '<option value="">Seleccioná una versión</option>';
                    if (
                        !datos.data ||
                        datos.data.length === 0
                    ) {
                        version.innerHTML =
                            '<option value="">Sin versiones disponibles</option>';
                        version.required = false;
                        mensajeMedidas.textContent =
                            'No encontramos versiones. Elegí el tamaño manualmente.';
                        return;
                    }
                    version.required = true;
                    datos.data.forEach(function (auto) {
                        const opcion =
                            document.createElement('option');
                        opcion.value = auto.id;
                        opcion.textContent =
                            auto.description
                            ||
                            auto.trim
                            ||
                            'Versión ' + auto.id;
                        version.appendChild(opcion);
                    });
                })
                .catch(function () {
                    version.innerHTML =
                        '<option value="">Error al cargar versiones</option>';
                    version.required = false;
                    mensajeMedidas.textContent =
                        'No pudimos cargar las versiones. Elegí el tamaño manualmente.';
                });
        }
        function cargarMedidas() {
            if (version.value === '') {
                return;
            }
            tamano.value = '';
            mensajeMedidas.textContent =
                'Calculando tamaño...';
            fetch(
                '../Scripts/php/carapi_medidas.php'
                + '?id='
                + encodeURIComponent(version.value)
            )
                .then(function (respuesta) {
                    return respuesta.json();
                })
                .then(function (datos) {
                    if (datos.error) {
                        mensajeMedidas.textContent =
                            'No encontramos las medidas. Elegí el tamaño manualmente.';
                        return;
                    }
                    tamano.value = datos.tamano;
                    mensajeMedidas.textContent =
                        'Largo: '
                        + datos.largo
                        + ' m - Tamaño: '
                        + datos.tamano;
                })
                .catch(function () {
                    mensajeMedidas.textContent =
                        'No pudimos calcular el tamaño. Elegilo manualmente.';
                });
        }
        function cambiarMarca() {
            const manual =
                marca.value === 'Otro';
            marcaManualContenedor.style.display =
                manual ? 'block' : 'none';
            modeloManualContenedor.style.display =
                manual ? 'block' : 'none';
            modeloContenedor.style.display =
                manual ? 'none' : 'block';
            versionContenedor.style.display =
                manual ? 'none' : 'block';
            marcaManual.required = manual;
            modeloManual.required = manual;
            modelo.disabled = manual;
            version.disabled = manual;
            modelo.innerHTML =
                '<option value="">Primero elegí año y marca</option>';
            version.innerHTML =
                '<option value="">Primero elegí un modelo</option>';
            tamano.value = '';
            if (manual) {
                mensajeMedidas.textContent =
                    'Elegí el tamaño manualmente.';
            } else {
                marcaManual.value = '';
                modeloManual.value = '';
                version.required = true;
                mensajeMedidas.textContent =
                    'Elegí una versión para calcular el tamaño automáticamente.';
                cargarModelos();
            }
            actualizarImagen();
        }
        function cambiarModelo() {
            const manual =
                modelo.value === 'Otro';
            modeloManualContenedor.style.display =
                manual ? 'block' : 'none';
            versionContenedor.style.display =
                manual ? 'none' : 'block';
            modeloManual.required = manual;
            version.disabled = manual;
            version.required = !manual;
            tamano.value = '';
            if (manual) {
                mensajeMedidas.textContent =
                    'Elegí el tamaño manualmente.';
            } else {
                modeloManual.value = '';
                mensajeMedidas.textContent =
                    'Elegí una versión para calcular el tamaño automáticamente.';
                cargarVersiones();
            }
            actualizarImagen();
        }
        function actualizarImagen() {
            let marcaElegida = marca.value;
            let modeloElegido = modelo.value;
            if (marca.value === 'Otro') {
                marcaElegida =
                    marcaManual.value.trim();
                modeloElegido =
                    modeloManual.value.trim();
            }
            else if (modelo.value === 'Otro') {
                modeloElegido =
                    modeloManual.value.trim();
            }
            if (
                anio.value === '' ||
                marcaElegida === '' ||
                modeloElegido === ''
            ) {
                vistaPreviaAuto.style.display =
                    'none';
                imagenPreviaContenedor.innerHTML =
                    '';
                return;
            }
            imagenPreviaContenedor.innerHTML = '';
            const imagen =
                document.createElement('img');
            imagen.dataset.autoMarca = marcaElegida;
            imagen.dataset.autoModelo = modeloElegido;
            imagen.dataset.autoAnio = anio.value;
            imagen.dataset.autoAncho = '600';
            imagen.alt =
                marcaElegida
                + ' '
                + modeloElegido
                + ' '
                + anio.value;
            imagen.style.width = '100%';
            imagen.style.maxWidth = '500px';
            imagen.style.height = '240px';
            imagen.style.objectFit = 'contain';
            imagenPreviaContenedor.appendChild(imagen);
            vistaPreviaAuto.style.display = 'block';
        }
        formulario.addEventListener(
            'submit',
            function (evento) {
                if (marca.value === 'Otro') {
                    marcaGuardar.value =
                        marcaManual.value.trim();
                } else {
                    marcaGuardar.value =
                        marca.value;
                }
                if (
                    marca.value === 'Otro' ||
                    modelo.value === 'Otro'
                ) {
                    modeloGuardar.value =
                        modeloManual.value.trim();
                } else {
                    modeloGuardar.value =
                        modelo.value;
                }
                if (
                    marcaGuardar.value === '' ||
                    modeloGuardar.value === ''
                ) {
                    evento.preventDefault();
                    alert(
                        'Completá la marca y el modelo.'
                    );
                }
            }
        );
        anio.addEventListener(
            'change',
            function () {
                cargarModelos();
                actualizarImagen();
            }
        );
        marca.addEventListener(
            'change',
            cambiarMarca
        );
        modelo.addEventListener(
            'change',
            cambiarModelo
        );
        version.addEventListener(
            'change',
            cargarMedidas
        );
        marcaManual.addEventListener(
            'input',
            actualizarImagen
        );
        modeloManual.addEventListener(
            'input',
            actualizarImagen
        );
        document.querySelectorAll('.campo-matricula').forEach(function (campo) {
            campo.addEventListener('input', function () {
                campo.value = campo.value.toUpperCase();
            });
        });
    </script>
</body>
</html>
