(function () {
    const claveImagenes = 'ci_96e8cfef41fc0da84814a6389d79e3c12919acf5dc02773491a6d4a3';

    function cargarImagenAuto(imagen) {
        const marca = imagen.dataset.autoMarca || '';
        const modelo = imagen.dataset.autoModelo || '';
        const anio = imagen.dataset.autoAnio || '';
        const ancho = imagen.dataset.autoAncho || '400';

        if (marca === '' || modelo === '') {
            return;
        }

        const parametros = new URLSearchParams({
            make: marca,
            model: modelo,
            year: anio,
            view: 'front34',
            width: ancho,
            key: claveImagenes
        });

        imagen.addEventListener('error', function () {
            imagen.style.display = 'none';
            const aviso = document.createElement('span');
            aviso.className = 'imagen-auto-no-disponible';
            aviso.textContent = 'Imagen no disponible para este modelo.';
            imagen.parentElement.appendChild(aviso);
        }, { once: true });

        imagen.src = 'https://carimagesapi.com/image?' + parametros.toString();
    }

    function buscarImagenes(contenedor) {
        if (contenedor.matches && contenedor.matches('img[data-auto-marca]')) {
            cargarImagenAuto(contenedor);
        }
        if (contenedor.querySelectorAll) {
            contenedor.querySelectorAll('img[data-auto-marca]').forEach(cargarImagenAuto);
        }
    }

    buscarImagenes(document);

    new MutationObserver(function (cambios) {
        cambios.forEach(function (cambio) {
            cambio.addedNodes.forEach(buscarImagenes);
        });
    }).observe(document.body, { childList: true, subtree: true });
}());
