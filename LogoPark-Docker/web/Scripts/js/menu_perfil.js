const botonPerfil = document.getElementById('botonPerfil');
const menuPerfil = document.getElementById('menuPerfil');
const perfilAcciones = document.querySelector('.perfil-acciones');

function cerrarMenuPerfil() {
    menuPerfil.classList.remove('abierto');
    botonPerfil.setAttribute('aria-expanded', 'false');
}

if (botonPerfil && menuPerfil && perfilAcciones) {
    botonPerfil.addEventListener('click', function () {
        const abierto = menuPerfil.classList.toggle('abierto');
        botonPerfil.setAttribute('aria-expanded', String(abierto));
    });

    document.addEventListener('click', function (evento) {
        if (!perfilAcciones.contains(evento.target)) {
            cerrarMenuPerfil();
        }
    });

    document.addEventListener('keydown', function (evento) {
        if (evento.key === 'Escape') {
            cerrarMenuPerfil();
        }
    });
}
