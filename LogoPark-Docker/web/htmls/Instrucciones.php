<?php
session_start();
if (!isset($_SESSION['id_usuario'])) {
  header('Location: ../index.html');
  exit();
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LOGOPARK - Instrucciones</title>
  <link rel="stylesheet" href="../css/estilos.css?v=20260819-4">
  <link rel="stylesheet" href="../css/usuario.css?v=20261021-2">
</head>
<body class="page-instrucciones">
  <header class="encabezado-instrucciones">
    <a href="home.php">LOGOPARK</a>
    <a class="volver-mapa" href="home.php#mapa-estacionamiento">Volver al mapa</a>
  </header>
  <main class="instrucciones-contenido">
    <h1>Instrucciones de uso</h1>
    <p class="instrucciones-intro">Todo lo necesario para registrar y consultar un estacionamiento.</p>

    <section>
      <h2>Cómo marcar tu estacionamiento</h2>
      <ol>
        <li>Elegí tu auto.</li>
        <li>Presioná “Marcar mi estacionamiento”.</li>
        <li>Tocá en el mapa el lugar donde estacionaste.</li>
        <li>Indicá la hora estimada de salida y guardá el estacionamiento.</li>
        <li>Si te retirás antes, presioná “Confirmar salida”.</li>
      </ol>
    </section>

    <section>
      <h2>Colores de las calles</h2>
      <p>Verde, amarillo y rojo indican la disponibilidad estimada de los tramos donde se puede estacionar.</p>
      <p class="nota-instrucciones"><strong>Gris:</strong> está prohibido estacionar. LogoPark no permite guardar un estacionamiento sobre esos tramos.</p>
    </section>

    <section>
      <h2>Colores de los autos</h2>
      <div class="instrucciones-autos">
        <article><img src="../Imagenes/auto-verde.png" alt="Auto verde"><div><strong>Verde</strong><span>Se libera en 5 minutos o menos, o el conductor confirmó su salida.</span></div></article>
        <article><img src="../Imagenes/auto-amarillo.png" alt="Auto amarillo"><div><strong>Amarillo</strong><span>Se libera entre 6 y 30 minutos.</span></div></article>
        <article><img src="../Imagenes/auto-rojo.png" alt="Auto rojo"><div><strong>Rojo</strong><span>Se libera en más de 30 minutos.</span></div></article>
      </div>
      <p class="nota-instrucciones">Los colores cambian automáticamente según la hora estimada. Si se confirma una salida anticipada, se muestra cuánto tiempo pasó y el auto desaparece del mapa a los 5 minutos.</p>
    </section>
  </main>
</body>
</html>
