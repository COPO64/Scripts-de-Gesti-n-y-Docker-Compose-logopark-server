-- Instalación limpia de LogoPark para XAMPP / MariaDB 10.4 o superior.
-- No elimina ni reemplaza una base existente.
-- Antes de importar, eliminá manualmente la base logopark anterior desde phpMyAdmin.

CREATE DATABASE IF NOT EXISTS logopark CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE logopark;

CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL DEFAULT '',
    usuario VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20) NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    contrasenia VARCHAR(255) NOT NULL,
    rol ENUM('usuario', 'admin') NOT NULL DEFAULT 'usuario'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vehiculo (
    matricula VARCHAR(10) PRIMARY KEY,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    anio INT NOT NULL,
    color VARCHAR(30) NOT NULL,
    tamanio VARCHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE usuario_vehiculo (
    id_usuario INT NOT NULL,
    matricula VARCHAR(10) NOT NULL,
    PRIMARY KEY (id_usuario, matricula),
    CONSTRAINT fk_usuario_vehiculo_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_usuario_vehiculo_vehiculo FOREIGN KEY (matricula) REFERENCES vehiculo(matricula) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tramos_calle (
    id_tramo INT AUTO_INCREMENT PRIMARY KEY,
    codigo_osm VARCHAR(40) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    geometria JSON NOT NULL,
    capacidad_estimada INT UNSIGNED NOT NULL,
    ocupacion_simulada INT UNSIGNED NOT NULL DEFAULT 0,
    permite_estacionar TINYINT(1) NOT NULL DEFAULT 1,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    INDEX idx_tramos_activos (activo),
    INDEX idx_tramos_permite_estacionar (permite_estacionar)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE estacionamiento (
    id_estacionamiento INT AUTO_INCREMENT PRIMARY KEY,
    estado ENUM('Disponible','Ocupado','Proxima salida','Finalizado','Cancelado') NULL,
    latitud DECIMAL(10,7) NULL,
    longitud DECIMAL(10,7) NULL,
    id_tramo INT NULL,
    INDEX idx_estacionamiento_tramo_estado (id_tramo, estado),
    CONSTRAINT fk_estacionamiento_tramo FOREIGN KEY (id_tramo) REFERENCES tramos_calle(id_tramo) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ocupacion (
    id_ocupacion INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NULL,
    matricula VARCHAR(10) NOT NULL,
    id_estacionamiento INT NOT NULL,
    fecha DATE NULL,
    hora_inicio TIME NULL,
    hora_fin TIME NULL,
    tiempo_estimado INT NULL,
    fecha_hora_ingreso DATETIME NULL,
    salida_estimada DATETIME NULL,
    salida_real DATETIME NULL,
    fecha_cancelacion DATETIME NULL,
    INDEX idx_ocupacion_usuario (id_usuario),
    INDEX idx_ocupacion_salida_real (salida_real),
    CONSTRAINT fk_ocupacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_ocupacion_vehiculo FOREIGN KEY (matricula) REFERENCES vehiculo(matricula),
    CONSTRAINT fk_ocupacion_estacionamiento FOREIGN KEY (id_estacionamiento) REFERENCES estacionamiento(id_estacionamiento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE rangos_disponibilidad (
    id_rango TINYINT UNSIGNED PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL UNIQUE,
    porcentaje_minimo TINYINT UNSIGNED NOT NULL,
    porcentaje_maximo TINYINT UNSIGNED NOT NULL,
    color_hex CHAR(7) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO usuario (nombre, apellido, usuario, telefono, email, contrasenia, rol)
VALUES
    ('Administrador', 'LogoPark', 'admin', NULL, 'logopark26@gmail.com', '$2b$10$28hXgwcdR7Je/1ikD2XuOuN708sf47bK4XAUdCAgCmri3QVMbGn2y', 'admin'),
    ('Andrés', 'Molino', 'amolino', NULL, 'amolino.profe@gmail.com', '$2y$10$7EwBgYmqMzlOZelFJL2AduS5ri/oKmyj1pze/1p19cAuOKNACLEDS', 'usuario'),
    ('Santiago', 'Martínez', 'smartinez', NULL, 'santiago.martinez@docente.ceibal.edu.uy', '$2y$10$7EwBgYmqMzlOZelFJL2AduS5ri/oKmyj1pze/1p19cAuOKNACLEDS', 'usuario'),
    ('Ivanna', 'Levy', 'ilevy', NULL, 'ivannalevy.de@docente.ceibal.edu.uy', '$2y$10$7EwBgYmqMzlOZelFJL2AduS5ri/oKmyj1pze/1p19cAuOKNACLEDS', 'usuario');

INSERT INTO rangos_disponibilidad (id_rango, nombre, porcentaje_minimo, porcentaje_maximo, color_hex)
VALUES
    (1, 'Rojo', 0, 24, '#DC3545'),
    (2, 'Amarillo', 25, 74, '#F4C542'),
    (3, 'Verde', 75, 100, '#28A745');

INSERT INTO tramos_calle
    (codigo_osm, nombre, geometria, capacidad_estimada, ocupacion_simulada, activo)
VALUES    ('osm-fca1bd4c5070657f7fd6', 'Avelino Miranda — tramo 1', '{"type":"LineString","coordinates":[[-56.1651178,-34.8927729],[-56.1649862,-34.8927605],[-56.1649241,-34.8927579],[-56.1648546,-34.8927667],[-56.164795,-34.8927793],[-56.1647149,-34.892811],[-56.1645193,-34.8929217]]}', 0, 0, 1),
    ('osm-5921be6f74ec618615a0', 'Avelino Miranda — tramo 2', '{"type":"LineString","coordinates":[[-56.1645193,-34.8929217],[-56.1637684,-34.8933377],[-56.1636271,-34.893416]]}', 0, 0, 1),
    ('osm-d0f23bb2f74cc9700990', 'Avelino Miranda — tramo 3', '{"type":"LineString","coordinates":[[-56.1636271,-34.893416],[-56.1635789,-34.8934425],[-56.1634376,-34.8935206]]}', 0, 0, 1),
    ('osm-39f47facddafbc9630ee', 'Avelino Miranda — tramo 4', '{"type":"LineString","coordinates":[[-56.1634376,-34.8935206],[-56.1633537,-34.893566],[-56.1626992,-34.893938]]}', 0, 0, 1),
    ('osm-ac4c339742513b99b2e2', 'Avelino Miranda — tramo 5', '{"type":"LineString","coordinates":[[-56.1626992,-34.893938],[-56.1625484,-34.8940115]]}', 0, 0, 1),
    ('osm-7a1f680ac004e6f4b27d', 'Avelino Miranda — tramo 6', '{"type":"LineString","coordinates":[[-56.1625484,-34.8940115],[-56.1624156,-34.8940811],[-56.1619844,-34.8943312],[-56.1615694,-34.8945718]]}', 0, 0, 1),
    ('osm-183a0451afe3730630ef', 'Avelino Miranda — tramo 7', '{"type":"LineString","coordinates":[[-56.1615694,-34.8945718],[-56.1611231,-34.89481]]}', 0, 0, 1),
    ('osm-436509617c6088baa445', 'Avenida 8 de Octubre — tramo 1', '{"type":"LineString","coordinates":[[-56.1651475,-34.8959544],[-56.1643469,-34.8944084],[-56.1642465,-34.8942544],[-56.1638974,-34.8938778],[-56.1634838,-34.8933611],[-56.1625929,-34.892252]]}', 0, 0, 1),
    ('osm-e392b86f19f1e0ad4997', 'Avenida 8 de Octubre — tramo 2', '{"type":"LineString","coordinates":[[-56.1650753,-34.8959805],[-56.1644464,-34.8947111],[-56.1642912,-34.8944351],[-56.1642495,-34.8943716],[-56.1641826,-34.8942855],[-56.1638063,-34.8938862],[-56.1634147,-34.8934],[-56.1628019,-34.8926394],[-56.1625323,-34.8923196]]}', 0, 0, 1),
    ('osm-c84534da8f429d8c2b3f', 'Avenida 8 de Octubre — tramo 3', '{"type":"LineString","coordinates":[[-56.1649556,-34.894181],[-56.1643135,-34.8941107],[-56.1642265,-34.8940928],[-56.1641397,-34.8940688],[-56.1640538,-34.8940412],[-56.1639727,-34.8940091],[-56.1638917,-34.8939634],[-56.1638326,-34.8939269],[-56.1638007,-34.8939049],[-56.1637667,-34.8938814],[-56.1636969,-34.8938223],[-56.1635574,-34.8936576],[-56.1635153,-34.8936078],[-56.1634376,-34.8935206]]}', 0, 0, 1),
    ('osm-2454188ca1415cca6772', 'Avenida 8 de Octubre — tramo 4', '{"type":"LineString","coordinates":[[-56.1636271,-34.893416],[-56.1635662,-34.8933416],[-56.1629846,-34.8926316]]}', 0, 0, 1),
    ('osm-de95200ea11600114642', 'Avenida 8 de Octubre — tramo 5', '{"type":"LineString","coordinates":[[-56.1634376,-34.8935206],[-56.1627122,-34.8926396],[-56.1625899,-34.892471],[-56.1625323,-34.8923196]]}', 0, 0, 1),
    ('osm-a81fd307a6eb49dd1034', 'Avenida 8 de Octubre — tramo 6', '{"type":"LineString","coordinates":[[-56.1629846,-34.8926316],[-56.1629427,-34.8925772],[-56.1627504,-34.8923619],[-56.1625929,-34.892252]]}', 0, 0, 1),
    ('osm-b5ac567704fbf06632cc', 'Avenida 8 de Octubre — tramo 7', '{"type":"LineString","coordinates":[[-56.1625929,-34.892252],[-56.1623868,-34.8919973],[-56.1623132,-34.8919032]]}', 0, 0, 1),
    ('osm-824cffb6f0f9d4770164', 'Avenida 8 de Octubre — tramo 8', '{"type":"LineString","coordinates":[[-56.1625323,-34.8923196],[-56.1622992,-34.8920387],[-56.1622288,-34.8919533]]}', 0, 0, 1),
    ('osm-8513af8402b6d5f8d8ed', 'Avenida 8 de Octubre — tramo 9', '{"type":"LineString","coordinates":[[-56.1623132,-34.8919032],[-56.1618666,-34.8913719],[-56.1608392,-34.8901393],[-56.1604303,-34.889647],[-56.1602453,-34.8894947]]}', 0, 0, 1),
    ('osm-51a566add5b7a1e4617f', 'Avenida 8 de Octubre — tramo 10', '{"type":"LineString","coordinates":[[-56.1622288,-34.8919533],[-56.1617818,-34.8914245],[-56.1607448,-34.8901838],[-56.1603311,-34.8896943]]}', 0, 0, 1),
    ('osm-31d799bfd482f8399a94', 'Avenida 8 de Octubre — tramo 11', '{"type":"LineString","coordinates":[[-56.1603311,-34.8896943],[-56.1602453,-34.8894947]]}', 0, 0, 1),
    ('osm-717158a0b40d89e4521d', 'Avenida 8 de Octubre — tramo 12', '{"type":"LineString","coordinates":[[-56.1602453,-34.8894947],[-56.1590927,-34.8881112]]}', 0, 0, 1),
    ('osm-6e3e8a6992a2d068851d', 'Avenida 8 de Octubre — tramo 13', '{"type":"LineString","coordinates":[[-56.1590927,-34.8881112],[-56.1583219,-34.8872006]]}', 0, 0, 1),
    ('osm-f3dac839ef6990e202b4', 'Avenida 8 de Octubre — tramo 14', '{"type":"LineString","coordinates":[[-56.1583219,-34.8872006],[-56.1565372,-34.8850507]]}', 0, 0, 1),
    ('osm-187f7c239c85a3ee7995', 'Avenida 8 de Octubre — tramo 15', '{"type":"LineString","coordinates":[[-56.1565372,-34.8850507],[-56.1555731,-34.8838864]]}', 0, 0, 1),
    ('osm-3969bf7179535c72d612', 'Avenida 8 de Octubre — tramo 16', '{"type":"LineString","coordinates":[[-56.1555731,-34.8838864],[-56.1554429,-34.8837621],[-56.1552563,-34.8836362],[-56.1550782,-34.8835337],[-56.1546941,-34.8833116],[-56.15424,-34.883049],[-56.1541237,-34.8829817]]}', 0, 0, 1),
    ('osm-b7d7f1d5d0e2e45a29d8', 'Avenida 8 de Octubre — tramo 17', '{"type":"LineString","coordinates":[[-56.1541237,-34.8829817],[-56.1529536,-34.8822812]]}', 0, 0, 1),
    ('osm-90ee20e7487f94b99279', 'Avenida 8 de Octubre — tramo 18', '{"type":"LineString","coordinates":[[-56.1529536,-34.8822812],[-56.1526839,-34.8821237],[-56.1526169,-34.8820837]]}', 0, 0, 1),
    ('osm-92645fe61cd27ee32640', 'Avenida 8 de Octubre — tramo 19', '{"type":"LineString","coordinates":[[-56.1526169,-34.8820837],[-56.152512,-34.8820189]]}', 0, 0, 1),
    ('osm-ec8dac109341d3c2f6da', 'Avenida Cataluña — tramo 1', '{"type":"LineString","coordinates":[[-56.1511516,-34.8957357],[-56.151095,-34.8957187],[-56.1510707,-34.8957176],[-56.1510567,-34.8957169],[-56.1509827,-34.895727],[-56.1509284,-34.8957491],[-56.150894,-34.8957759],[-56.1508531,-34.8958273]]}', 1, 0, 1),
    ('osm-4cec280f25a6241351fd', 'Avenida Cataluña — tramo 2', '{"type":"LineString","coordinates":[[-56.1508182,-34.8960209],[-56.150775,-34.8960796]]}', 0, 0, 1),
    ('osm-bfc0eb3a1f551da42c71', 'Avenida Cataluña — tramo 3', '{"type":"LineString","coordinates":[[-56.1505622,-34.8961883],[-56.1505031,-34.8961968]]}', 0, 0, 1),
    ('osm-aa041fe3ec36257fd1ec', 'Avenida Cataluña — tramo 4', '{"type":"LineString","coordinates":[[-56.1475987,-34.8958476],[-56.1475599,-34.8957946],[-56.1475257,-34.8957455]]}', 0, 0, 1),
    ('osm-3ab876310dadffb8bcdd', 'Avenida Centenario — tramo 1', '{"type":"LineString","coordinates":[[-56.1556251,-34.8912039],[-56.1556332,-34.8911348],[-56.1556331,-34.8910695],[-56.1556251,-34.8910174],[-56.1556117,-34.8909678],[-56.1555709,-34.8908813],[-56.1554336,-34.8906523],[-56.1549994,-34.8899255]]}', 15, 0, 1),
    ('osm-720bc9eff410869bc693', 'Avenida Centenario — tramo 2', '{"type":"LineString","coordinates":[[-56.1552068,-34.8911021],[-56.1552629,-34.8909567],[-56.1552827,-34.8908966],[-56.1552846,-34.890847],[-56.1552635,-34.8907657],[-56.1547849,-34.8900084]]}', 13, 4, 1),
    ('osm-ee8d5f43f97f8caaf0cb', 'Avenida Centenario — tramo 3', '{"type":"LineString","coordinates":[[-56.1552068,-34.8911021],[-56.1551895,-34.89115],[-56.1551208,-34.8913376]]}', 1, 0, 1),
    ('osm-de2a7aa1c60c0e37c940', 'Avenida Centenario — tramo 4', '{"type":"LineString","coordinates":[[-56.1549994,-34.8899255],[-56.1541374,-34.8884585]]}', 18, 6, 1),
    ('osm-cfb7806e87a8a0917288', 'Avenida Centenario — tramo 5', '{"type":"LineString","coordinates":[[-56.1547849,-34.8900084],[-56.1539388,-34.8885399]]}', 18, 3, 1),
    ('osm-d49585d2602e742dca3e', 'Avenida Centenario — tramo 6', '{"type":"LineString","coordinates":[[-56.1541374,-34.8884585],[-56.1541132,-34.8884133],[-56.1538989,-34.88798]]}', 4, 4, 1),
    ('osm-cc3363a2ddf967f0fc5f', 'Avenida Centenario — tramo 7', '{"type":"LineString","coordinates":[[-56.1539388,-34.8885399],[-56.1536892,-34.8880464]]}', 4, 0, 1),
    ('osm-31499cc508cf435d53bd', 'Avenida Centenario — tramo 8', '{"type":"LineString","coordinates":[[-56.1538989,-34.88798],[-56.1537958,-34.8877483]]}', 1, 0, 1),
    ('osm-1204f31532ffe1f54c38', 'Avenida Centenario — tramo 9', '{"type":"LineString","coordinates":[[-56.1537958,-34.8877483],[-56.153682,-34.8874941]]}', 1, 0, 1),
    ('osm-819eb01e9278eb3e3b24', 'Avenida Centenario — tramo 10', '{"type":"LineString","coordinates":[[-56.1536892,-34.8880464],[-56.1535992,-34.8878545],[-56.1534692,-34.8875624]]}', 4, 2, 1),
    ('osm-0a7516cf9110a04ae0c2', 'Avenida Centenario — tramo 11', '{"type":"LineString","coordinates":[[-56.153682,-34.8874941],[-56.1533976,-34.8867439],[-56.1531533,-34.8861039],[-56.1530407,-34.8857502]]}', 21, 1, 1),
    ('osm-d0aee769d48b5038647a', 'Avenida Centenario — tramo 12', '{"type":"LineString","coordinates":[[-56.1534692,-34.8875624],[-56.1534298,-34.8874768],[-56.1533837,-34.8873611]]}', 0, 0, 1),
    ('osm-408f707a688f2beef2e2', 'Avenida Centenario — tramo 13', '{"type":"LineString","coordinates":[[-56.1533837,-34.8873611],[-56.1531495,-34.8867516],[-56.1529434,-34.8861571],[-56.1528757,-34.8859275]]}', 17, 16, 1),
    ('osm-9fdec5de7ff23ebf1ee3', 'Avenida Centenario — tramo 14', '{"type":"LineString","coordinates":[[-56.1530407,-34.8857502],[-56.1529399,-34.8853798]]}', 2, 0, 1),
    ('osm-744a12926970755144d0', 'Avenida Centenario — tramo 15', '{"type":"LineString","coordinates":[[-56.1529536,-34.8822812],[-56.1525286,-34.8824676]]}', 2, 0, 1),
    ('osm-1f3914c4b9b408a41327', 'Avenida Centenario — tramo 16', '{"type":"LineString","coordinates":[[-56.1529399,-34.8853798],[-56.152844,-34.8849866],[-56.1527741,-34.8846544]]}', 7, 0, 1),
    ('osm-2364e4160af6f7a91340', 'Avenida Centenario — tramo 17', '{"type":"LineString","coordinates":[[-56.1528757,-34.8859275],[-56.1527275,-34.8854144]]}', 4, 0, 1),
    ('osm-dbcdeaaaf6c510b003e5', 'Avenida Centenario — tramo 18', '{"type":"LineString","coordinates":[[-56.1527741,-34.8846544],[-56.1527219,-34.8843805],[-56.1527055,-34.8842778],[-56.1525307,-34.8831719]]}', 17, 3, 1),
    ('osm-6451fc8525696384a7be', 'Avenida Centenario — tramo 19', '{"type":"LineString","coordinates":[[-56.1527275,-34.8854144],[-56.1525476,-34.8846872]]}', 7, 3, 1),
    ('osm-94f761d9593044ddf87d', 'Avenida Centenario — tramo 20', '{"type":"LineString","coordinates":[[-56.1526169,-34.8820837],[-56.1525788,-34.8822105],[-56.1525286,-34.8824676]]}', 2, 2, 1),
    ('osm-bc6fb92a1915d58a2018', 'Avenida Centenario — tramo 21', '{"type":"LineString","coordinates":[[-56.1525476,-34.8846872],[-56.1525025,-34.8844079],[-56.1523931,-34.8837841],[-56.1523085,-34.8831975]]}', 17, 6, 1),
    ('osm-2c5d5beaa193e8eba4a8', 'Avenida Centenario — tramo 22', '{"type":"LineString","coordinates":[[-56.1525307,-34.8831719],[-56.1523085,-34.8831975]]}', 0, 0, 1),
    ('osm-755c7ebecd2e200f5e14', 'Avenida Centenario — tramo 23', '{"type":"LineString","coordinates":[[-56.1525307,-34.8831719],[-56.1525127,-34.8826762],[-56.1525286,-34.8824676]]}', 6, 2, 1),
    ('osm-5484e560d32eac112300', 'Avenida Centenario — tramo 24', '{"type":"LineString","coordinates":[[-56.1523085,-34.8831975],[-56.1522971,-34.883103],[-56.1522901,-34.8830599],[-56.1522828,-34.8830307],[-56.1522587,-34.8829988],[-56.1522246,-34.8829672],[-56.1519971,-34.8828658],[-56.1519189,-34.8828279]]}', 4, 0, 1),
    ('osm-5453717e5d7f3f777afe', 'Avenida Doctor Alfredo Navarro — tramo 1', '{"type":"LineString","coordinates":[[-56.151217,-34.893798],[-56.1511535,-34.8938861],[-56.1511183,-34.8939099],[-56.1510332,-34.893932],[-56.1510126,-34.8939322],[-56.1509816,-34.8939322],[-56.150939,-34.8939323],[-56.1508898,-34.8939234]]}', 2, 0, 1),
    ('osm-96f23d1491fb2f05f5e6', 'Avenida Doctor Alfredo Navarro — tramo 2', '{"type":"LineString","coordinates":[[-56.151217,-34.893798],[-56.1512136,-34.8937312],[-56.1512026,-34.8937014],[-56.15117,-34.8936616],[-56.1511616,-34.8936531],[-56.1511419,-34.8936412],[-56.1510896,-34.8936186],[-56.1509835,-34.8935899]]}', 0, 0, 1),
    ('osm-ecec14dc425633a8e4ee', 'Avenida Doctor Alfredo Navarro — tramo 3', '{"type":"LineString","coordinates":[[-56.1509835,-34.8935899],[-56.1508615,-34.8936467]]}', 0, 0, 1),
    ('osm-e6ee0fc5b8e58f967407', 'Avenida Doctor Alfredo Navarro — tramo 4', '{"type":"LineString","coordinates":[[-56.1508898,-34.8939234],[-56.150816,-34.8939071],[-56.1507644,-34.8938983],[-56.1507155,-34.8938965],[-56.1506702,-34.8939053],[-56.1506506,-34.8939138],[-56.1505824,-34.8939433],[-56.1505384,-34.8939655],[-56.1504518,-34.8940145],[-56.1503792,-34.894052],[-56.1502723,-34.8941079],[-56.1499999,-34.8942446],[-56.1498652,-34.8943077],[-56.1498288,-34.8943257],[-56.1496866,-34.8943992],[-56.1496027,-34.8944507]]}', 13, 0, 1),
    ('osm-1d11fb98a75c1644b70e', 'Avenida Doctor Alfredo Navarro — tramo 5', '{"type":"LineString","coordinates":[[-56.1508615,-34.8936467],[-56.1507067,-34.8937173]]}', 0, 0, 1),
    ('osm-b042f37aea93fa15ac4e', 'Avenida Doctor Alfredo Navarro — tramo 6', '{"type":"LineString","coordinates":[[-56.1507067,-34.8937173],[-56.1505592,-34.8937922],[-56.1499303,-34.8941114],[-56.1497719,-34.8942036]]}', 9, 8, 1),
    ('osm-72f35616e5ad5cd6924f', 'Avenida Doctor Alfredo Navarro — tramo 7', '{"type":"LineString","coordinates":[[-56.1497719,-34.8942036],[-56.1497044,-34.8942464],[-56.1495202,-34.8943783]]}', 1, 0, 1),
    ('osm-f8349e0d30435177451e', 'Avenida Doctor Alfredo Navarro — tramo 8', '{"type":"LineString","coordinates":[[-56.1496027,-34.8944507],[-56.1495223,-34.8945063],[-56.1491245,-34.8947921]]}', 4, 0, 1),
    ('osm-05bd8a7bc8936831f62a', 'Avenida Doctor Alfredo Navarro — tramo 9', '{"type":"LineString","coordinates":[[-56.1495202,-34.8943783],[-56.1491537,-34.8946415],[-56.1486616,-34.8949928]]}', 9, 0, 1),
    ('osm-faa3ba86b4cb0821892c', 'Avenida Doctor Alfredo Navarro — tramo 10', '{"type":"LineString","coordinates":[[-56.1491245,-34.8947921],[-56.1487623,-34.8950468]]}', 2, 0, 1),
    ('osm-6480df08c31aa3054eda', 'Avenida Doctor Alfredo Navarro — tramo 11', '{"type":"LineString","coordinates":[[-56.1487623,-34.8950468],[-56.1480077,-34.8955438],[-56.1476896,-34.8957687],[-56.1475987,-34.8958476]]}', 13, 2, 1),
    ('osm-f30fe8efee62896b6360', 'Avenida Doctor Alfredo Navarro — tramo 12', '{"type":"LineString","coordinates":[[-56.1486616,-34.8949928],[-56.147791,-34.8955724],[-56.147615,-34.895696],[-56.1475257,-34.8957455]]}', 13, 1, 1),
    ('osm-661f0c895aeb056adc3a', 'Avenida Doctor Américo Ricaldoni — tramo 1', '{"type":"LineString","coordinates":[[-56.1596029,-34.8945262],[-56.1595828,-34.89444],[-56.1593391,-34.8937549],[-56.1589333,-34.8925591]]}', 24, 20, 1),
    ('osm-a2da4d69c8c13f39e944', 'Avenida Doctor Américo Ricaldoni — tramo 2', '{"type":"LineString","coordinates":[[-56.1596029,-34.8945262],[-56.1596209,-34.8946238],[-56.1596236,-34.8947591],[-56.1596187,-34.8949243],[-56.1595978,-34.8951371],[-56.1595617,-34.8953427]]}', 8, 1, 1),
    ('osm-a4ae326393ccfa13528a', 'Avenida Doctor Américo Ricaldoni — tramo 3', '{"type":"LineString","coordinates":[[-56.1595617,-34.8953427],[-56.15952,-34.8955969],[-56.1595236,-34.8956466],[-56.1595259,-34.8956795],[-56.1595387,-34.8957208],[-56.1595509,-34.8957608]]}', 0, 0, 1),
    ('osm-7fbaf6b6e454cb3ab4a9', 'Avenida Doctor Américo Ricaldoni — tramo 4', '{"type":"LineString","coordinates":[[-56.1594828,-34.8960971],[-56.1594387,-34.8961465],[-56.1593927,-34.8962092],[-56.1593559,-34.8963096],[-56.1593206,-34.8964791]]}', 0, 0, 1),
    ('osm-2888fecdf1aaa4a274fc', 'Avenida Doctor Américo Ricaldoni — tramo 5', '{"type":"LineString","coordinates":[[-56.1593206,-34.8964791],[-56.159228,-34.8969365]]}', 3, 0, 1),
    ('osm-c3439e37a8a3553cc006', 'Avenida Doctor Américo Ricaldoni — tramo 6', '{"type":"LineString","coordinates":[[-56.1592941,-34.8953066],[-56.1592391,-34.8955298],[-56.1592044,-34.8955805],[-56.1591556,-34.895644],[-56.159112,-34.8956933]]}', 0, 0, 1),
    ('osm-c55f174c83e1740f6044', 'Avenida Doctor Américo Ricaldoni — tramo 7', '{"type":"LineString","coordinates":[[-56.1592941,-34.8953066],[-56.1593638,-34.8949668],[-56.1593722,-34.8948253],[-56.1593638,-34.8946851],[-56.1593465,-34.8945733],[-56.1593259,-34.8944902],[-56.1592824,-34.8943464],[-56.1590874,-34.8938428],[-56.1589321,-34.8933337],[-56.1587315,-34.892754],[-56.1586349,-34.8924812]]}', 0, 0, 1),
    ('osm-bf968a195ca81eca1971', 'Avenida Doctor Américo Ricaldoni — tramo 8', '{"type":"LineString","coordinates":[[-56.159112,-34.8956933],[-56.1590421,-34.8957064],[-56.1589354,-34.8957101],[-56.1588191,-34.8957048],[-56.1587914,-34.8957021],[-56.1587255,-34.8956951],[-56.15866,-34.8956812],[-56.1585415,-34.895659]]}', 0, 0, 1),
    ('osm-b36acf5ab91a0778d5d0', 'Avenida Doctor Américo Ricaldoni — tramo 9', '{"type":"LineString","coordinates":[[-56.159112,-34.8956933],[-56.1591058,-34.8957023],[-56.1590587,-34.8957606],[-56.1590371,-34.895801],[-56.1590222,-34.895846],[-56.1590161,-34.8959136],[-56.1590251,-34.8959677],[-56.1590346,-34.8959956],[-56.1590495,-34.8960381]]}', 0, 0, 1),
    ('osm-b621834c2bebfb04c2ff', 'Avenida Doctor Américo Ricaldoni — tramo 10', '{"type":"LineString","coordinates":[[-56.1590606,-34.8964459],[-56.1590506,-34.8965043],[-56.158998,-34.8968107],[-56.1589718,-34.8968961],[-56.1589272,-34.896977],[-56.1588646,-34.8970803],[-56.1588024,-34.8971475]]}', 7, 1, 1),
    ('osm-8549af9a49c471b4c8f9', 'Avenida Doctor Américo Ricaldoni — tramo 11', '{"type":"LineString","coordinates":[[-56.1590606,-34.8964459],[-56.1590956,-34.8962342],[-56.1590968,-34.8961756],[-56.1590872,-34.896117],[-56.1590718,-34.8960853],[-56.1590495,-34.8960381]]}', 0, 0, 1),
    ('osm-53013e4cab2766944191', 'Avenida Doctor Américo Ricaldoni — tramo 12', '{"type":"LineString","coordinates":[[-56.1590495,-34.8960381],[-56.1589633,-34.8959944],[-56.1587673,-34.8959531],[-56.1585774,-34.8959385],[-56.1584951,-34.8959314]]}', 0, 0, 1),
    ('osm-f5d6602f7f54afe955e8', 'Avenida Doctor Américo Ricaldoni — tramo 13', '{"type":"LineString","coordinates":[[-56.1589333,-34.8925591],[-56.1588912,-34.8924374],[-56.1588324,-34.8922625],[-56.1588124,-34.8921771]]}', 2, 0, 1),
    ('osm-79cfc87274f45cbce54c', 'Avenida Doctor Américo Ricaldoni — tramo 14', '{"type":"LineString","coordinates":[[-56.1586844,-34.8972503],[-56.1580311,-34.8977305],[-56.1578153,-34.8978891],[-56.1577364,-34.8979449],[-56.1576542,-34.8980031]]}', 12, 2, 1),
    ('osm-625b1f5416fdfc9bfbd4', 'Avenida Doctor Américo Ricaldoni — tramo 15', '{"type":"LineString","coordinates":[[-56.1586349,-34.8924812],[-56.1586006,-34.89223],[-56.1586276,-34.8921388]]}', 2, 0, 1),
    ('osm-8bd38be2b6433be71d74', 'Avenida Doctor Américo Ricaldoni — tramo 16', '{"type":"LineString","coordinates":[[-56.1586349,-34.8924812],[-56.1585399,-34.8923447],[-56.1584981,-34.8922135],[-56.158465,-34.8921055]]}', 0, 0, 1),
    ('osm-cbfa9975a04abea50976', 'Avenida Doctor Américo Ricaldoni — tramo 17', '{"type":"LineString","coordinates":[[-56.1576542,-34.8980031],[-56.1575204,-34.8981071]]}', 0, 0, 1),
    ('osm-ad4f94913e085bb54881', 'Avenida Doctor Américo Ricaldoni — tramo 18', '{"type":"LineString","coordinates":[[-56.1575204,-34.8981071],[-56.1574417,-34.8981677],[-56.1567476,-34.8986971]]}', 9, 0, 1),
    ('osm-1ff8a2eaf0a26e5cf6e1', 'Avenida Doctor Américo Ricaldoni — tramo 19', '{"type":"LineString","coordinates":[[-56.1556251,-34.8912039],[-56.1556211,-34.8912393],[-56.1556096,-34.8912838],[-56.1555557,-34.8913911],[-56.1555219,-34.8914346]]}', 1, 0, 1),
    ('osm-6a16ae5cfb75de4f0138', 'Avenida Doctor Américo Ricaldoni — tramo 20', '{"type":"LineString","coordinates":[[-56.1555219,-34.8914346],[-56.1554394,-34.8915329],[-56.1553898,-34.8915767],[-56.154463,-34.8920542]]}', 0, 0, 1),
    ('osm-4f74170a072a97b7ab79', 'Avenida Doctor Américo Ricaldoni — tramo 21', '{"type":"LineString","coordinates":[[-56.1551208,-34.8913376],[-56.1550812,-34.8914331],[-56.1550472,-34.8915019],[-56.155003,-34.8915473],[-56.1548502,-34.8916511],[-56.1544861,-34.8918199],[-56.1540965,-34.8920259]]}', 0, 0, 1),
    ('osm-1077df1a69e6a288481e', 'Avenida Doctor Américo Ricaldoni — tramo 22', '{"type":"LineString","coordinates":[[-56.154463,-34.8920542],[-56.154221,-34.8921791]]}', 0, 0, 1),
    ('osm-716bc496c56a967806d4', 'Avenida Doctor Américo Ricaldoni — tramo 23', '{"type":"LineString","coordinates":[[-56.154221,-34.8921791],[-56.1537959,-34.8923943]]}', 3, 1, 1),
    ('osm-9f0fd4bff73acc8f1cd7', 'Avenida Doctor Américo Ricaldoni — tramo 24', '{"type":"LineString","coordinates":[[-56.1540965,-34.8920259],[-56.153795,-34.8921714],[-56.1536829,-34.8922255]]}', 2, 1, 1),
    ('osm-269bc7c424c369efff51', 'Avenida Doctor Américo Ricaldoni — tramo 25', '{"type":"LineString","coordinates":[[-56.1537959,-34.8923943],[-56.1524104,-34.8930911],[-56.1514402,-34.8935784],[-56.1513383,-34.8936367],[-56.1512789,-34.8936964],[-56.1512502,-34.8937353],[-56.151217,-34.893798]]}', 30, 10, 1),
    ('osm-cd04487e6403ec8c7029', 'Avenida Doctor Américo Ricaldoni — tramo 26', '{"type":"LineString","coordinates":[[-56.1536829,-34.8922255],[-56.1531124,-34.8925102]]}', 4, 1, 1),
    ('osm-384f08e76e62bcb1bf04', 'Avenida Doctor Américo Ricaldoni — tramo 27', '{"type":"LineString","coordinates":[[-56.1531124,-34.8925102],[-56.151317,-34.8934194],[-56.1509835,-34.8935899]]}', 24, 4, 1),
    ('osm-98a81e7a283155cb81dd', 'Avenida Doctor Américo Ricaldoni — tramo 28', '{"type":"LineString","coordinates":[[-56.151217,-34.893798],[-56.1511923,-34.8939956],[-56.1511292,-34.8947136],[-56.1510993,-34.8951497],[-56.1510826,-34.895394],[-56.1510817,-34.8954752],[-56.1510891,-34.8955564],[-56.1511009,-34.895624],[-56.1511516,-34.8957357]]}', 22, 8, 1),
    ('osm-6c3c6c05718c8444f493', 'Avenida Doctor Américo Ricaldoni — tramo 29', '{"type":"LineString","coordinates":[[-56.1508988,-34.8951918],[-56.1508531,-34.8958273]]}', 6, 0, 1),
    ('osm-4b066d2fa0e2fb7fafc1', 'Avenida Doctor Américo Ricaldoni — tramo 30', '{"type":"LineString","coordinates":[[-56.1508988,-34.8951918],[-56.1509033,-34.8951368],[-56.1509602,-34.8945734],[-56.1509798,-34.8943073],[-56.1509961,-34.894083],[-56.1509886,-34.8940495],[-56.1509755,-34.8940194],[-56.1509342,-34.8939656],[-56.1508898,-34.8939234]]}', 14, 1, 1),
    ('osm-83407519222c078513d8', 'Avenida Doctor Américo Ricaldoni — tramo 31', '{"type":"LineString","coordinates":[[-56.1508898,-34.8939234],[-56.1508582,-34.8938743],[-56.1508443,-34.893829],[-56.1508497,-34.8937546],[-56.1508555,-34.89371],[-56.1508615,-34.8936467]]}', 0, 0, 1),
    ('osm-44294a6bbd114cffdea5', 'Avenida Doctor Américo Ricaldoni — tramo 32', '{"type":"LineString","coordinates":[[-56.1508531,-34.8958273],[-56.1508397,-34.8958893],[-56.1508182,-34.8960209]]}', 0, 0, 1),
    ('osm-3f0fe7abb88f0e20c56c', 'Avenida Doctor Francisco Soca — tramo 1', '{"type":"LineString","coordinates":[[-56.1575508,-34.8981834],[-56.1575204,-34.8981071]]}', 0, 0, 1),
    ('osm-12be40fa8aa75ca7f9d5', 'Avenida Doctor Lorenzo Merola — tramo 1', '{"type":"LineString","coordinates":[[-56.1585415,-34.895659],[-56.1585453,-34.8955529],[-56.1584748,-34.8951253],[-56.1583217,-34.8948447],[-56.1581567,-34.8946391],[-56.1580175,-34.8945418],[-56.1579237,-34.8943252],[-56.157813,-34.8942741],[-56.1576963,-34.8941237],[-56.1576253,-34.8940464],[-56.1575607,-34.8939513],[-56.1575157,-34.8938608],[-56.1574863,-34.8937298],[-56.1575072,-34.8935631],[-56.1574992,-34.8934729],[-56.1574849,-34.8934007],[-56.1574454,-34.8933102],[-56.1574121,-34.8932654],[-56.1573594,-34.8932191],[-56.1573121,-34.8931748],[-56.1572647,-34.8931241],[-56.1570781,-34.8929786],[-56.1568964,-34.8928916],[-56.1568613,-34.8928827],[-56.1567497,-34.8928545],[-56.1565377,-34.8927854],[-56.156381,-34.8927212]]}', 33, 3, 1),
    ('osm-afd73a551b7685d4a845', 'Avenida Doctor Lorenzo Merola — tramo 2', '{"type":"LineString","coordinates":[[-56.1585415,-34.895659],[-56.1584951,-34.8959314]]}', 0, 0, 1),
    ('osm-bfde564eaa0d206298a1', 'Avenida Doctor Lorenzo Merola — tramo 3', '{"type":"LineString","coordinates":[[-56.1584951,-34.8959314],[-56.1584416,-34.8960255],[-56.1583844,-34.8961331],[-56.158316,-34.89626],[-56.1582427,-34.89638],[-56.1581483,-34.8965095],[-56.1580252,-34.8966408],[-56.1579826,-34.8966781],[-56.157927,-34.8967267],[-56.1578299,-34.8968068],[-56.1577485,-34.8968595]]}', 9, 1, 1),
    ('osm-4057bf24736199f1239c', 'Avenida Doctor Lorenzo Merola — tramo 4', '{"type":"LineString","coordinates":[[-56.1577485,-34.8968595],[-56.1576632,-34.8969158],[-56.1576064,-34.8969508],[-56.157437,-34.8970264],[-56.1572917,-34.8970796]]}', 2, 0, 1),
    ('osm-c0c64c45e2191cd729de', 'Avenida Doctor Lorenzo Merola — tramo 5', '{"type":"LineString","coordinates":[[-56.1572917,-34.8970796],[-56.1571285,-34.8970841],[-56.1569607,-34.8970671],[-56.1568173,-34.8970327],[-56.1567829,-34.8970244],[-56.1565558,-34.8969582]]}', 4, 4, 1),
    ('osm-1c0334df357cfeedad22', 'Avenida Doctor Lorenzo Merola — tramo 6', '{"type":"LineString","coordinates":[[-56.1572917,-34.8970796],[-56.1569399,-34.8971764],[-56.1569067,-34.8971855],[-56.1568063,-34.8972177]]}', 2, 0, 1),
    ('osm-ef75cfd20623603dcd35', 'Avenida Doctor Lorenzo Merola — tramo 7', '{"type":"LineString","coordinates":[[-56.156381,-34.8927212],[-56.1563284,-34.8926987],[-56.1562299,-34.892648],[-56.1560988,-34.892557],[-56.1559727,-34.8924479],[-56.1559516,-34.8924342],[-56.1558925,-34.8923977],[-56.1557658,-34.8923518],[-56.1549703,-34.8922786],[-56.154854,-34.8922868],[-56.154732,-34.8923085],[-56.1546365,-34.8923529],[-56.1546096,-34.8923663],[-56.1544086,-34.8925225]]}', 15, 8, 1),
    ('osm-e62f0a88b69829ba9b36', 'Avenida Doctor Luis Morquio — tramo 1', '{"type":"LineString","coordinates":[[-56.1637055,-34.8971056],[-56.1635369,-34.8970581],[-56.1634994,-34.8970571],[-56.1630149,-34.8968609],[-56.1629742,-34.8968461],[-56.1627791,-34.8967754]]}', 8, 4, 1),
    ('osm-773c1bcb84d6d285d19b', 'Avenida Doctor Luis Morquio — tramo 2', '{"type":"LineString","coordinates":[[-56.1623353,-34.8966067],[-56.1618869,-34.8964519]]}', 3, 0, 1),
    ('osm-43f75eda1806148a3ed1', 'Avenida Doctor Luis Morquio — tramo 3', '{"type":"LineString","coordinates":[[-56.1611038,-34.8962254],[-56.1608335,-34.8961592],[-56.1606231,-34.8961153]]}', 3, 0, 1),
    ('osm-0492c9ba6afe396ff373', 'Avenida Doctor Luis Morquio — tramo 4', '{"type":"LineString","coordinates":[[-56.1595509,-34.8957608],[-56.1594861,-34.895708],[-56.159422,-34.895673],[-56.1593392,-34.8956591],[-56.1592478,-34.895659],[-56.159178,-34.8956717],[-56.159112,-34.8956933]]}', 0, 0, 1),
    ('osm-51498e6cd5120280bcbe', 'Avenida Doctor Luis Morquio — tramo 5', '{"type":"LineString","coordinates":[[-56.1594828,-34.8960971],[-56.1594092,-34.8961359],[-56.1593577,-34.8961483],[-56.159306,-34.8961523],[-56.1592626,-34.8961507],[-56.1592052,-34.8961372],[-56.1591869,-34.8961296],[-56.1591339,-34.8961049],[-56.1590987,-34.89608],[-56.1590495,-34.8960381]]}', 0, 0, 1),
    ('osm-9c53947d10c3889b746f', 'Avenida Doctor Manuel Albo — tramo 1', '{"type":"LineString","coordinates":[[-56.1603311,-34.8896943],[-56.1602519,-34.8897008],[-56.1601783,-34.8897049],[-56.1600783,-34.8897359]]}', 0, 0, 1),
    ('osm-7e0673d4c620af3ce808', 'Avenida Doctor Manuel Albo — tramo 2', '{"type":"LineString","coordinates":[[-56.1602453,-34.8894947],[-56.1600783,-34.8897359]]}', 0, 0, 1),
    ('osm-6e51654e604a6d429d93', 'Avenida Doctor Manuel Albo — tramo 3', '{"type":"LineString","coordinates":[[-56.1600783,-34.8897359],[-56.1600181,-34.8898253]]}', 0, 0, 1),
    ('osm-e35f67efed3906026f39', 'Avenida Doctor Manuel Albo — tramo 4', '{"type":"LineString","coordinates":[[-56.1600181,-34.8898253],[-56.1599531,-34.8897895],[-56.1599218,-34.8897663],[-56.1598927,-34.8897384],[-56.1598735,-34.8897145],[-56.1598543,-34.8896873],[-56.1598355,-34.8896541]]}', 0, 0, 1),
    ('osm-cc6cdc21eadeed0ed27e', 'Avenida Doctor Manuel Albo — tramo 5', '{"type":"LineString","coordinates":[[-56.1600181,-34.8898253],[-56.1597007,-34.8902995]]}', 0, 0, 1),
    ('osm-0108a07905f338608bdc', 'Avenida Doctor Manuel Albo — tramo 6', '{"type":"LineString","coordinates":[[-56.1597007,-34.8902995],[-56.1596253,-34.8903514],[-56.1594215,-34.8906314],[-56.1593883,-34.8906557],[-56.159342,-34.8906771],[-56.1592864,-34.8907042]]}', 0, 0, 1),
    ('osm-68789c065656d616028c', 'Avenida Doctor Manuel Albo — tramo 7', '{"type":"LineString","coordinates":[[-56.1597007,-34.8902995],[-56.1596813,-34.8903627],[-56.159405,-34.8907956]]}', 0, 0, 1),
    ('osm-3bb3dd3ea09ed5c6d616', 'Avenida Doctor Manuel Albo — tramo 8', '{"type":"LineString","coordinates":[[-56.159405,-34.8907956],[-56.1591693,-34.8911693],[-56.1590601,-34.8913352],[-56.1589939,-34.8914594],[-56.158942,-34.8915869],[-56.1588628,-34.8918026],[-56.1588258,-34.8919034],[-56.1588098,-34.8920009]]}', 0, 0, 1),
    ('osm-2bbf69f0852bd22cca9d', 'Avenida Doctor Manuel Albo — tramo 9', '{"type":"LineString","coordinates":[[-56.1592864,-34.8907042],[-56.1592877,-34.8907754],[-56.1592732,-34.8908323],[-56.159015,-34.8912032],[-56.1588925,-34.8914276],[-56.1588269,-34.8915852],[-56.1586928,-34.8919731]]}', 0, 0, 1),
    ('osm-fa05759a9bcb38d3df4f', 'Avenida Doctor Manuel Albo — tramo 10', '{"type":"LineString","coordinates":[[-56.1588124,-34.8921771],[-56.1588098,-34.8920009]]}', 0, 0, 1),
    ('osm-03c686c5c85d84422ad4', 'Avenida Doctor Manuel Albo — tramo 11', '{"type":"LineString","coordinates":[[-56.1586928,-34.8919731],[-56.1586613,-34.8920532]]}', 0, 0, 1),
    ('osm-5db628cdc9f6385581cf', 'Avenida Doctor Manuel Albo — tramo 12', '{"type":"LineString","coordinates":[[-56.1586613,-34.8920532],[-56.1586276,-34.8921388]]}', 0, 0, 1),
    ('osm-3ab7d959d2606e3a730a', 'Avenida Federico R. Vidiella — tramo 1', '{"type":"LineString","coordinates":[[-56.1544977,-34.8937117],[-56.1545155,-34.893841],[-56.1545216,-34.8940271],[-56.1545202,-34.8940854],[-56.1545114,-34.8942139],[-56.1544851,-34.8943715],[-56.1544752,-34.8944144]]}', 5, 5, 1),
    ('osm-3f0af83b7ae5524b4883', 'Avenida Federico R. Vidiella — tramo 2', '{"type":"LineString","coordinates":[[-56.1544977,-34.8937117],[-56.1545259,-34.8936519],[-56.154494,-34.8934659],[-56.1544762,-34.8933602],[-56.1544697,-34.8932905]]}', 2, 1, 1),
    ('osm-6141b37790dc55c56a27', 'Avenida Federico R. Vidiella — tramo 3', '{"type":"LineString","coordinates":[[-56.1544977,-34.8937117],[-56.1544455,-34.8936592],[-56.1544212,-34.8935541],[-56.1543929,-34.8934575],[-56.154335,-34.893308]]}', 2, 0, 1),
    ('osm-414a34721d93117cc537', 'Avenida Federico R. Vidiella — tramo 4', '{"type":"LineString","coordinates":[[-56.1544752,-34.8944144],[-56.1544607,-34.8944774],[-56.1544409,-34.8945555],[-56.1544148,-34.8946289],[-56.1543836,-34.8947195],[-56.1543326,-34.8948393],[-56.1542827,-34.8949378],[-56.1542203,-34.8950409],[-56.1541726,-34.8951182],[-56.1541117,-34.895201],[-56.1540553,-34.8952734],[-56.1539956,-34.8953434],[-56.153933,-34.8954079]]}', 8, 0, 1),
    ('osm-5adae501cc7ce87e9df2', 'Avenida Federico R. Vidiella — tramo 5', '{"type":"LineString","coordinates":[[-56.1544697,-34.8932905],[-56.1544652,-34.8932044]]}', 0, 0, 1),
    ('osm-e4d1a9d4abf332aa8ca5', 'Avenida Federico R. Vidiella — tramo 6', '{"type":"LineString","coordinates":[[-56.1544652,-34.8932044],[-56.1544604,-34.8931219],[-56.1544404,-34.8929459],[-56.1544183,-34.8927908]]}', 2, 0, 1),
    ('osm-33caf453daf3df608d2e', 'Avenida Federico R. Vidiella — tramo 7', '{"type":"LineString","coordinates":[[-56.154463,-34.8920542],[-56.1544086,-34.8925225]]}', 2, 0, 1),
    ('osm-49e3c44dd12de64c3acf', 'Avenida Federico R. Vidiella — tramo 8', '{"type":"LineString","coordinates":[[-56.1544183,-34.8927908],[-56.1544031,-34.8926678],[-56.1544086,-34.8925225]]}', 1, 0, 1),
    ('osm-a526ac8afa7cb213cac9', 'Avenida Federico R. Vidiella — tramo 9', '{"type":"LineString","coordinates":[[-56.1544086,-34.8925225],[-56.1543912,-34.8924594],[-56.1543586,-34.8923645],[-56.1543291,-34.8923147],[-56.1542865,-34.8922603],[-56.154221,-34.8921791]]}', 2, 0, 1),
    ('osm-6435f2d6d42fa477cf6a', 'Avenida Federico R. Vidiella — tramo 10', '{"type":"LineString","coordinates":[[-56.154335,-34.893308],[-56.1542952,-34.8932397]]}', 0, 0, 1),
    ('osm-ff2a9a099fd9a8e81cf9', 'Avenida Federico R. Vidiella — tramo 11', '{"type":"LineString","coordinates":[[-56.1542952,-34.8932397],[-56.1537959,-34.8923943]]}', 7, 1, 1),
    ('osm-90573409ee4067c64d2c', 'Avenida Federico R. Vidiella — tramo 12', '{"type":"LineString","coordinates":[[-56.154221,-34.8921791],[-56.1541771,-34.8921212],[-56.1540965,-34.8920259]]}', 0, 0, 1),
    ('osm-988c50a7a41483d315fa', 'Avenida Federico R. Vidiella — tramo 13', '{"type":"LineString","coordinates":[[-56.153933,-34.8954079],[-56.1538481,-34.8955513],[-56.1538103,-34.8955832],[-56.1537264,-34.8956559],[-56.1536299,-34.8957416],[-56.1535759,-34.8958049],[-56.1535211,-34.8958934],[-56.1534828,-34.8959684],[-56.1534574,-34.8960369],[-56.1534397,-34.8961319],[-56.1534343,-34.8961882],[-56.1534213,-34.8963242]]}', 8, 1, 1),
    ('osm-f6a18feb32cbcc18179d', 'Avenida Federico R. Vidiella — tramo 14', '{"type":"LineString","coordinates":[[-56.153933,-34.8954079],[-56.1537339,-34.8954954],[-56.1534675,-34.8956988],[-56.1533751,-34.8957724],[-56.1532908,-34.8958573],[-56.1532447,-34.8959134],[-56.1532084,-34.895975],[-56.1531687,-34.896057],[-56.1531381,-34.896168],[-56.1531126,-34.8962905]]}', 9, 0, 1),
    ('osm-a84042944c21242705f6', 'Avenida Federico R. Vidiella — tramo 15', '{"type":"LineString","coordinates":[[-56.1537959,-34.8923943],[-56.1537266,-34.8922915],[-56.1536829,-34.8922255]]}', 0, 0, 1),
    ('osm-c2e69545bb740f0f775d', 'Avenida General José Garibaldi — tramo 1', '{"type":"LineString","coordinates":[[-56.1637873,-34.8862562],[-56.163689,-34.8863163],[-56.1633524,-34.8866318]]}', 0, 0, 1),
    ('osm-ecc806aa56975db6a041', 'Avenida General José Garibaldi — tramo 2', '{"type":"LineString","coordinates":[[-56.1633524,-34.8866318],[-56.1625956,-34.8873176]]}', 0, 0, 1),
    ('osm-572b94527170e68bb247', 'Avenida General José Garibaldi — tramo 3', '{"type":"LineString","coordinates":[[-56.1625956,-34.8873176],[-56.1618211,-34.8880258]]}', 0, 0, 1),
    ('osm-db13b9ab15a6e2c7117d', 'Avenida General José Garibaldi — tramo 4', '{"type":"LineString","coordinates":[[-56.1618211,-34.8880258],[-56.1610062,-34.8887496]]}', 0, 0, 1),
    ('osm-13c63e01908190456b60', 'Avenida General José Garibaldi — tramo 5', '{"type":"LineString","coordinates":[[-56.1610062,-34.8887496],[-56.1602453,-34.8894947]]}', 0, 0, 1),
    ('osm-dfd8f4d9ade04461750e', 'Avenida General José Garibaldi — tramo 6', '{"type":"LineString","coordinates":[[-56.1602453,-34.8894947],[-56.1600425,-34.8895736],[-56.1598355,-34.8896541]]}', 0, 0, 1),
    ('osm-cbb54f378da953abf81d', 'Avenida General José Garibaldi — tramo 7', '{"type":"LineString","coordinates":[[-56.1598355,-34.8896541],[-56.1591501,-34.8898774]]}', 0, 0, 1),
    ('osm-6ea43798b67c0b4a4c42', 'Avenida General José Garibaldi — tramo 8', '{"type":"LineString","coordinates":[[-56.1591501,-34.8898774],[-56.1585741,-34.8900793]]}', 0, 0, 1),
    ('osm-02078026e43c9e713ebe', 'Avenida General José Garibaldi — tramo 9', '{"type":"LineString","coordinates":[[-56.1585741,-34.8900793],[-56.1582694,-34.8901824]]}', 0, 0, 1),
    ('osm-3d9dc9b28931c248ef4a', 'Avenida General José Garibaldi — tramo 10', '{"type":"LineString","coordinates":[[-56.1582694,-34.8901824],[-56.1580902,-34.8902488]]}', 0, 0, 1),
    ('osm-845b9245a90a7d896a2a', 'Avenida General José Garibaldi — tramo 11', '{"type":"LineString","coordinates":[[-56.1580902,-34.8902488],[-56.1569893,-34.8906244]]}', 0, 0, 1),
    ('osm-4d1b83ef97e7d99c2df6', 'Avenida General José Garibaldi — tramo 12', '{"type":"LineString","coordinates":[[-56.1569893,-34.8906244],[-56.1564854,-34.8908013],[-56.156163,-34.8909716]]}', 0, 0, 1),
    ('osm-5468c19d20c1c47735f8', 'Avenida General José Garibaldi — tramo 13', '{"type":"LineString","coordinates":[[-56.156163,-34.8909716],[-56.1559288,-34.8910907],[-56.1558053,-34.8911611],[-56.1556251,-34.8912039]]}', 0, 0, 1),
    ('osm-63affb39dc8c1524baa7', 'Avenida Italia — tramo 1', '{"type":"LineString","coordinates":[[-56.1648959,-34.894631],[-56.1647763,-34.8946228],[-56.1645152,-34.8946048],[-56.1643868,-34.894589],[-56.1642879,-34.8945613],[-56.1638915,-34.8944062],[-56.1638054,-34.8943725],[-56.1635142,-34.8942596],[-56.1627965,-34.8939779],[-56.1626992,-34.893938]]}', 0, 0, 1),
    ('osm-e230e83e4af90c617712', 'Avenida Italia — tramo 2', '{"type":"LineString","coordinates":[[-56.1648539,-34.8950265],[-56.1647583,-34.8949806],[-56.1645796,-34.8948922],[-56.1639198,-34.8945683],[-56.163712,-34.8944703]]}', 0, 0, 1),
    ('osm-6c4c6768b4a4ed0511cd', 'Avenida Italia — tramo 3', '{"type":"LineString","coordinates":[[-56.163712,-34.8944703],[-56.1634853,-34.8943694],[-56.1630899,-34.894217],[-56.1626646,-34.894053],[-56.1625484,-34.8940115]]}', 0, 0, 1),
    ('osm-9130acde6804d44e2474', 'Avenida Italia — tramo 4', '{"type":"LineString","coordinates":[[-56.1626992,-34.893938],[-56.1625863,-34.8938868],[-56.1609292,-34.8930277],[-56.1606084,-34.8928547]]}', 0, 0, 1),
    ('osm-e5bad8f11a1eb18e0f7d', 'Avenida Italia — tramo 5', '{"type":"LineString","coordinates":[[-56.1625484,-34.8940115],[-56.1619427,-34.893759],[-56.1616703,-34.893638],[-56.1614095,-34.8935057]]}', 0, 0, 1),
    ('osm-cd60500427c08908ff04', 'Avenida Italia — tramo 6', '{"type":"LineString","coordinates":[[-56.1614095,-34.8935057],[-56.161173,-34.893379],[-56.1603936,-34.8929697]]}', 0, 0, 1),
    ('osm-c284d691eb4d4a919f04', 'Avenida Italia — tramo 7', '{"type":"LineString","coordinates":[[-56.1606084,-34.8928547],[-56.1598091,-34.8924172],[-56.1594456,-34.8922195],[-56.1593191,-34.8921555],[-56.1592448,-34.8921197],[-56.1591556,-34.8920894],[-56.1588098,-34.8920009]]}', 0, 0, 1),
    ('osm-dde17e281c6d878d2e9d', 'Avenida Italia — tramo 8', '{"type":"LineString","coordinates":[[-56.1603936,-34.8929697],[-56.1591181,-34.8922758],[-56.1590473,-34.8922438],[-56.158971,-34.8922162],[-56.158912,-34.8922025],[-56.1588124,-34.8921771]]}', 0, 0, 1),
    ('osm-23a5c0446dc063114ff5', 'Avenida Italia — tramo 9', '{"type":"LineString","coordinates":[[-56.1588124,-34.8921771],[-56.1586276,-34.8921388]]}', 0, 0, 1),
    ('osm-6cadaf95cd494d0f39b4', 'Avenida Italia — tramo 10', '{"type":"LineString","coordinates":[[-56.1588124,-34.8921771],[-56.158754,-34.8920961],[-56.158707,-34.892067],[-56.1586613,-34.8920532]]}', 0, 0, 1),
    ('osm-0e86bf31f76c9ee9ef8a', 'Avenida Italia — tramo 11', '{"type":"LineString","coordinates":[[-56.1588098,-34.8920009],[-56.1586928,-34.8919731]]}', 0, 0, 1),
    ('osm-f2eeb2f3fedf680beb3e', 'Avenida Italia — tramo 12', '{"type":"LineString","coordinates":[[-56.1586928,-34.8919731],[-56.1586275,-34.8919326],[-56.1583116,-34.8918542],[-56.1574563,-34.8916372]]}', 0, 0, 1),
    ('osm-23bb0d4f451975bb36df', 'Avenida Italia — tramo 13', '{"type":"LineString","coordinates":[[-56.1586928,-34.8919731],[-56.1586191,-34.891957],[-56.158056,-34.8918363],[-56.1578526,-34.8918127]]}', 0, 0, 1),
    ('osm-1b7e474dd1f89644492a', 'Avenida Italia — tramo 14', '{"type":"LineString","coordinates":[[-56.1586613,-34.8920532],[-56.1585927,-34.8920351],[-56.1580316,-34.8919007],[-56.1578526,-34.8918127]]}', 0, 0, 1),
    ('osm-86e7c9d81782b9c8e1c5', 'Avenida Italia — tramo 15', '{"type":"LineString","coordinates":[[-56.1586276,-34.8921388],[-56.1585624,-34.8921249],[-56.158465,-34.8921055]]}', 0, 0, 1),
    ('osm-39f7fc59951ac7b2562f', 'Avenida Italia — tramo 16', '{"type":"LineString","coordinates":[[-56.158465,-34.8921055],[-56.1580233,-34.892003],[-56.1578257,-34.8919539]]}', 0, 0, 1),
    ('osm-971dd7be045f532a3a71', 'Avenida Italia — tramo 17', '{"type":"LineString","coordinates":[[-56.1578526,-34.8918127],[-56.1575816,-34.891739],[-56.1570895,-34.8916424],[-56.1559446,-34.8913725],[-56.1549524,-34.891128],[-56.1534051,-34.8907437],[-56.1530296,-34.8906085]]}', 0, 0, 1),
    ('osm-12498ba9d28f8e80a13b', 'Avenida Italia — tramo 18', '{"type":"LineString","coordinates":[[-56.1578257,-34.8919539],[-56.1576398,-34.8919389],[-56.156864,-34.891752],[-56.1556805,-34.8914727],[-56.1555219,-34.8914346]]}', 0, 0, 1),
    ('osm-8549518070a33da60051', 'Avenida Italia — tramo 19', '{"type":"LineString","coordinates":[[-56.1578257,-34.8919539],[-56.1575623,-34.8918424],[-56.1559123,-34.8914438],[-56.1549309,-34.891209],[-56.1538899,-34.8909562],[-56.1528719,-34.8907462],[-56.152579,-34.8907036]]}', 0, 0, 1),
    ('osm-0f5aa3bb93edb34f91ef', 'Avenida Italia — tramo 20', '{"type":"LineString","coordinates":[[-56.1574563,-34.8916372],[-56.1559003,-34.8912734],[-56.1558674,-34.8912657],[-56.1556251,-34.8912039]]}', 0, 0, 1),
    ('osm-035734746e13b2e67053', 'Avenida Italia — tramo 21', '{"type":"LineString","coordinates":[[-56.1556251,-34.8912039],[-56.1552068,-34.8911021]]}', 0, 0, 1),
    ('osm-7c6ede3f937f3bf06ea6', 'Avenida Italia — tramo 22', '{"type":"LineString","coordinates":[[-56.1555219,-34.8914346],[-56.1551978,-34.891356],[-56.1551208,-34.8913376]]}', 0, 0, 1),
    ('osm-20a154878e75a8f4e0c6', 'Avenida Italia — tramo 23', '{"type":"LineString","coordinates":[[-56.1552068,-34.8911021],[-56.1550529,-34.891066],[-56.1550251,-34.8910593],[-56.1546508,-34.8909714],[-56.1534291,-34.8906754],[-56.1530296,-34.8906085]]}', 0, 0, 1),
    ('osm-7baf4fcaa4e58175699d', 'Avenida Italia — tramo 24', '{"type":"LineString","coordinates":[[-56.1551208,-34.8913376],[-56.1549743,-34.8913021],[-56.1544543,-34.891176],[-56.1534544,-34.8909407]]}', 0, 0, 1),
    ('osm-eeefa8329d243e21a0d6', 'Avenida Italia — tramo 25', '{"type":"LineString","coordinates":[[-56.1534544,-34.8909407],[-56.1528555,-34.8908032],[-56.152579,-34.8907036]]}', 0, 0, 1),
    ('osm-20b6603295146ed09e7b', 'Avenida Italia — tramo 26', '{"type":"LineString","coordinates":[[-56.1530296,-34.8906085],[-56.1520869,-34.8903684],[-56.1519362,-34.8903306]]}', 0, 0, 1),
    ('osm-78d28a5816a503290225', 'Avenida Italia — tramo 27', '{"type":"LineString","coordinates":[[-56.152579,-34.8907036],[-56.1522708,-34.890632],[-56.1520948,-34.890586],[-56.1520145,-34.8905664],[-56.1518518,-34.8905278]]}', 0, 0, 1),
    ('osm-923592fe2323851c9a8f', 'Avenida Italia — tramo 28', '{"type":"LineString","coordinates":[[-56.1519362,-34.8903306],[-56.1513966,-34.8901995],[-56.1506692,-34.8900026]]}', 0, 0, 1),
    ('osm-dba64bf3b7f156c7aa79', 'Avenida Italia — tramo 29', '{"type":"LineString","coordinates":[[-56.1518518,-34.8905278],[-56.1515799,-34.8904575]]}', 0, 0, 1),
    ('osm-a5f073dc65cae6ddbdaa', 'Avenida Italia — tramo 30', '{"type":"LineString","coordinates":[[-56.1515799,-34.8904575],[-56.1514757,-34.8903714],[-56.1514256,-34.8903305],[-56.1513498,-34.8902883],[-56.1512639,-34.8902528],[-56.1510136,-34.8901796],[-56.15077,-34.8901139],[-56.1507164,-34.8900975],[-56.1506883,-34.8900799],[-56.1506733,-34.8900582],[-56.1506692,-34.8900026]]}', 0, 0, 1),
    ('osm-cc1e60a5b9676051df4d', 'Avenida Italia — tramo 31', '{"type":"LineString","coordinates":[[-56.1515799,-34.8904575],[-56.1506204,-34.8902116],[-56.1505669,-34.8901953]]}', 0, 0, 1),
    ('osm-1528d01780b170e07a1f', 'Avenida Italia — tramo 32', '{"type":"LineString","coordinates":[[-56.1506692,-34.8900026],[-56.150576,-34.8899743],[-56.1502382,-34.88985],[-56.1498008,-34.8896726],[-56.14963,-34.8895903],[-56.1494759,-34.8895225]]}', 0, 0, 1),
    ('osm-76cf8a892ec4033c49cd', 'Avenida Italia — tramo 33', '{"type":"LineString","coordinates":[[-56.1505669,-34.8901953],[-56.1501478,-34.8900584],[-56.1496901,-34.8898719],[-56.1492373,-34.8896787]]}', 0, 0, 1),
    ('osm-586502e86f962a9effd8', 'Avenida Italia — tramo 34', '{"type":"LineString","coordinates":[[-56.1494759,-34.8895225],[-56.1483015,-34.8889829]]}', 0, 0, 1),
    ('osm-070c231ba0efdf97a9e8', 'Avenida Italia — tramo 35', '{"type":"LineString","coordinates":[[-56.1492373,-34.8896787],[-56.148531,-34.8893579]]}', 0, 0, 1),
    ('osm-4c7752658df05dac020c', 'Avenida Italia — tramo 36', '{"type":"LineString","coordinates":[[-56.148531,-34.8893579],[-56.1481374,-34.8891795]]}', 0, 0, 1),
    ('osm-e34b314d78332f53803b', 'Avenida Italia — tramo 37', '{"type":"LineString","coordinates":[[-56.1483015,-34.8889829],[-56.1481441,-34.888904],[-56.147744,-34.8887256]]}', 0, 0, 1),
    ('osm-f149078bfcdcc3be66b6', 'Avenida Italia — tramo 38', '{"type":"LineString","coordinates":[[-56.1483015,-34.8889829],[-56.1483084,-34.889022],[-56.1483077,-34.8890577],[-56.1482852,-34.889107],[-56.148246,-34.8891405],[-56.1481947,-34.889166],[-56.1481374,-34.8891795]]}', 0, 0, 1),
    ('osm-d307515f65d680346128', 'Avenida Italia — tramo 39', '{"type":"LineString","coordinates":[[-56.1481374,-34.8891795],[-56.1480121,-34.8891227],[-56.1478993,-34.8890726],[-56.1476973,-34.8889834],[-56.1476053,-34.8889428]]}', 0, 0, 1),
    ('osm-08c638847056f8149387', 'Avenida Luis Alberto de Herrera — tramo 1', '{"type":"LineString","coordinates":[[-56.1534821,-34.8811011],[-56.153395,-34.8811779]]}', 0, 0, 1),
    ('osm-8a43851a0b66d5fd5dcc', 'Avenida Luis Alberto de Herrera — tramo 2', '{"type":"LineString","coordinates":[[-56.1528825,-34.8816572],[-56.1527972,-34.8817323]]}', 0, 0, 1),
    ('osm-e10cc34b848da3e836d1', 'Avenida Luis Alberto de Herrera — tramo 3', '{"type":"LineString","coordinates":[[-56.1527972,-34.8817323],[-56.1527732,-34.8818264],[-56.1526736,-34.8819844],[-56.1526169,-34.8820837]]}', 2, 0, 1),
    ('osm-c2a6d4999d023e9c57cf', 'Avenida Luis Alberto de Herrera — tramo 4', '{"type":"LineString","coordinates":[[-56.1527972,-34.8817323],[-56.1527282,-34.8817904]]}', 0, 0, 1),
    ('osm-294ce02ab99f4a4b8176', 'Avenida Ramón Anador — tramo 1', '{"type":"LineString","coordinates":[[-56.1475257,-34.8957455],[-56.147457,-34.895778],[-56.1473854,-34.8958093]]}', 0, 0, 1),
    ('osm-b505f825a7ec26a78b8b', 'Avenida Ramón Anador — tramo 2', '{"type":"LineString","coordinates":[[-56.1472119,-34.8958562],[-56.146402,-34.895983],[-56.146287,-34.8959989]]}', 7, 3, 1),
    ('osm-f04cf4c8260b77a06f9a', 'Avenida Ramón Anador — tramo 3', '{"type":"LineString","coordinates":[[-56.1443349,-34.8958339],[-56.1432855,-34.8955611]]}', 9, 5, 1),
    ('osm-46b237cb484e86ea8980', 'Avenida Ramón V. Benzano — tramo 1', '{"type":"LineString","coordinates":[[-56.1576542,-34.8980031],[-56.1575964,-34.8979734],[-56.1575488,-34.8979399],[-56.157336,-34.8977206],[-56.157272,-34.8977001]]}', 3, 1, 1),
    ('osm-815868f522eb783551d3', 'Avenida Ramón V. Benzano — tramo 2', '{"type":"LineString","coordinates":[[-56.1575204,-34.8981071],[-56.1574732,-34.8980146],[-56.1574093,-34.8979086],[-56.1572777,-34.8977529],[-56.157272,-34.8977001]]}', 3, 0, 1),
    ('osm-8c79415c98eb903fdc38', 'Avenida Ramón V. Benzano — tramo 3', '{"type":"LineString","coordinates":[[-56.157272,-34.8977001],[-56.1570002,-34.897416],[-56.1569275,-34.8973417],[-56.1568063,-34.8972177]]}', 5, 0, 1),
    ('osm-92cae59bb9f892135dc9', 'Avenida Ramón V. Benzano — tramo 4', '{"type":"LineString","coordinates":[[-56.1568063,-34.8972177],[-56.1565558,-34.8969582]]}', 2, 0, 1),
    ('osm-1c674be6e9586b38a4c9', 'Avenida Ramón V. Benzano — tramo 5', '{"type":"LineString","coordinates":[[-56.1565558,-34.8969582],[-56.156521,-34.8969228],[-56.1564155,-34.8968345],[-56.1562978,-34.8967501],[-56.1562021,-34.8966998],[-56.156107,-34.8966584]]}', 4, 2, 1),
    ('osm-d625e281d67b56006546', 'Avenida Ramón V. Benzano — tramo 6', '{"type":"LineString","coordinates":[[-56.156107,-34.8966584],[-56.1559904,-34.8966159],[-56.1558672,-34.8965863],[-56.1557122,-34.8965594],[-56.1555457,-34.896539],[-56.1552252,-34.8965089]]}', 7, 7, 1),
    ('osm-75b02478b3e30e0a03e1', 'Avenida Ramón V. Benzano — tramo 7', '{"type":"LineString","coordinates":[[-56.1552252,-34.8965089],[-56.1540179,-34.8963866]]}', 10, 0, 1),
    ('osm-748278f58dea974f8ece', 'Avenida Ramón V. Benzano — tramo 8', '{"type":"LineString","coordinates":[[-56.1540179,-34.8963866],[-56.1535729,-34.8963399],[-56.1535244,-34.8963349],[-56.1534213,-34.8963242]]}', 4, 0, 1),
    ('osm-6a380ad95ad32fb64570', 'Avenida Ramón V. Benzano — tramo 9', '{"type":"LineString","coordinates":[[-56.1534213,-34.8963242],[-56.1531126,-34.8962905]]}', 1, 0, 1),
    ('osm-8da146a3fb9c7270777e', 'Avenida Ramón V. Benzano — tramo 10', '{"type":"LineString","coordinates":[[-56.1531126,-34.8962905],[-56.1530018,-34.8962799],[-56.1529638,-34.8962762],[-56.1527165,-34.8962524],[-56.1523893,-34.8962209],[-56.1522714,-34.8962163],[-56.1520772,-34.8962173],[-56.1517196,-34.8962138]]}', 12, 10, 1),
    ('osm-aba334c0a77ac417451a', 'Avenida Ramón V. Benzano — tramo 11', '{"type":"LineString","coordinates":[[-56.1517196,-34.8962138],[-56.1515561,-34.8962405]]}', 0, 0, 1),
    ('osm-4488a9d6ad4434539f59', 'Avenida Ramón V. Benzano — tramo 12', '{"type":"LineString","coordinates":[[-56.1517196,-34.8962138],[-56.1516011,-34.8961838],[-56.1515147,-34.8961514],[-56.1514677,-34.8961256],[-56.1514286,-34.896104],[-56.1513009,-34.8960084]]}', 3, 0, 1),
    ('osm-85104ace30ef9d1013cc', 'Ayacucho — tramo 1', '{"type":"LineString","coordinates":[[-56.1475257,-34.8957455],[-56.1474927,-34.895671],[-56.1474761,-34.8956258],[-56.1474652,-34.8955491],[-56.1474682,-34.8954555]]}', 2, 2, 1),
    ('osm-3b5a15e29501abf13881', 'Ayacucho — tramo 2', '{"type":"LineString","coordinates":[[-56.1474682,-34.8954555],[-56.1463156,-34.8949311]]}', 14, 7, 1),
    ('osm-e0f751166ba8aa0f2f26', 'Ayacucho — tramo 3', '{"type":"LineString","coordinates":[[-56.1463156,-34.8949311],[-56.1452127,-34.8944331]]}', 13, 0, 1),
    ('osm-ed7e54650b566a316720', 'Ayacucho — tramo 4', '{"type":"LineString","coordinates":[[-56.1452127,-34.8944331],[-56.1442898,-34.894014]]}', 10, 0, 1),
    ('osm-0c05160af7db23bda9b6', 'Azambuya — tramo 1', '{"type":"LineString","coordinates":[[-56.1604312,-34.8831071],[-56.1603535,-34.8831867],[-56.1596243,-34.8837508]]}', 11, 1, 1),
    ('osm-c6ea41366793fbcd4a46', 'Belgrano — tramo 1', '{"type":"LineString","coordinates":[[-56.1547849,-34.8900084],[-56.1546698,-34.8900312],[-56.1546185,-34.8900354],[-56.1545235,-34.8900302],[-56.1526109,-34.8895248],[-56.1525196,-34.8895]]}', 27, 22, 1),
    ('osm-16419611610616834e2a', 'Belgrano — tramo 2', '{"type":"LineString","coordinates":[[-56.1525196,-34.8895],[-56.151254,-34.8890629],[-56.1511851,-34.8890417]]}', 15, 14, 1),
    ('osm-c34cc4635f58f682a656', 'Belgrano — tramo 3', '{"type":"LineString","coordinates":[[-56.1511851,-34.8890417],[-56.150607,-34.8888361],[-56.1499499,-34.8886152]]}', 14, 2, 1),
    ('osm-2af504649cb6be64affe', 'Belgrano — tramo 4', '{"type":"LineString","coordinates":[[-56.1499499,-34.8886152],[-56.1483929,-34.8880607],[-56.148249,-34.8880064]]}', 20, 1, 1),
    ('osm-82c600647a9b9e8de798', 'Bulevar General Artigas — tramo 1', '{"type":"LineString","coordinates":[[-56.1654912,-34.889323],[-56.165451,-34.8897006]]}', 2, 0, 1),
    ('osm-c2325583caf5939b1b91', 'Bulevar General Artigas — tramo 2', '{"type":"LineString","coordinates":[[-56.165451,-34.8897006],[-56.1653937,-34.8902145]]}', 4, 0, 1),
    ('osm-90348c59cfd6e6ac84cf', 'Bulevar General Artigas — tramo 3', '{"type":"LineString","coordinates":[[-56.1653937,-34.8902145],[-56.1652965,-34.8911755]]}', 10, 0, 1),
    ('osm-75f8c59539c97d2fecfb', 'Bulevar General Artigas — tramo 4', '{"type":"LineString","coordinates":[[-56.1652709,-34.8914225],[-56.1652344,-34.8917011]]}', 1, 0, 1),
    ('osm-5ae9fee65d7a5fa57353', 'Bulevar General Artigas — tramo 5', '{"type":"LineString","coordinates":[[-56.1652344,-34.8917011],[-56.1651899,-34.8921272]]}', 3, 1, 1),
    ('osm-f8eb39dd669044077650', 'Bulevar General Artigas — tramo 6', '{"type":"LineString","coordinates":[[-56.1651899,-34.8921272],[-56.1651178,-34.8927729]]}', 6, 2, 1),
    ('osm-d3a00c8c4838566dd2ec', 'Bulevar General Artigas — tramo 7', '{"type":"LineString","coordinates":[[-56.1651178,-34.8927729],[-56.1651031,-34.8928866],[-56.1650824,-34.8930488],[-56.1650513,-34.8933309],[-56.1650118,-34.89369],[-56.1649789,-34.8939776],[-56.1649556,-34.894181]]}', 16, 0, 1),
    ('osm-64493b40f3a42d3b4a31', 'Bulevar General Artigas — tramo 8', '{"type":"LineString","coordinates":[[-56.1649556,-34.894181],[-56.1649483,-34.8942501],[-56.1649099,-34.8945281],[-56.1648959,-34.894631]]}', 3, 0, 1),
    ('osm-860bd62cf9422e90313b', 'Bulevar General Artigas — tramo 9', '{"type":"LineString","coordinates":[[-56.1648959,-34.894631],[-56.164886,-34.8947261],[-56.164868,-34.8948936],[-56.1648539,-34.8950265]]}', 3, 0, 1),
    ('osm-67e50905f55f7896702c', 'Bulevar General Artigas — tramo 10', '{"type":"LineString","coordinates":[[-56.1648539,-34.8950265],[-56.1648384,-34.895154],[-56.1647927,-34.8954586],[-56.1647014,-34.8962774],[-56.1646957,-34.8963352],[-56.1646406,-34.8968246]]}', 21, 1, 1),
    ('osm-ef5ae91e06c73b767849', 'Bulevar General Artigas — tramo 11', '{"type":"LineString","coordinates":[[-56.1646423,-34.8970457],[-56.1646406,-34.8968246]]}', 0, 0, 1),
    ('osm-cff281ed651546e87018', 'Carlos Anaya — tramo 1', '{"type":"LineString","coordinates":[[-56.1644628,-34.8895881],[-56.1636408,-34.8885603]]}', 16, 14, 1),
    ('osm-93a8fdf96aeb1aa61e16', 'Carlos Anaya — tramo 2', '{"type":"LineString","coordinates":[[-56.1636408,-34.8885603],[-56.1625956,-34.8873176]]}', 20, 9, 1),
    ('osm-3e9d69767ff2c85d4dcd', 'Carlos Anaya — tramo 3', '{"type":"LineString","coordinates":[[-56.1625956,-34.8873176],[-56.161764,-34.8863337]]}', 15, 13, 1),
    ('osm-10d2eff438bc1c9cc990', 'Carlos Anaya — tramo 4', '{"type":"LineString","coordinates":[[-56.161764,-34.8863337],[-56.1609438,-34.8853406]]}', 15, 3, 1),
    ('osm-46a41fd1d692436525f2', 'Carlos Anaya — tramo 5', '{"type":"LineString","coordinates":[[-56.1609438,-34.8853406],[-56.1603147,-34.8845833]]}', 11, 5, 1),
    ('osm-271754e33e87be1306b4', 'Carlos Anaya — tramo 6', '{"type":"LineString","coordinates":[[-56.1603147,-34.8845833],[-56.1596243,-34.8837508]]}', 13, 1, 1),
    ('osm-00acdd296ddace135dbc', 'Carlos Anaya — tramo 7', '{"type":"LineString","coordinates":[[-56.1596243,-34.8837508],[-56.1589268,-34.8829236]]}', 12, 11, 1),
    ('osm-c84e1677bf85f30f6fa0', 'Carlos Anaya — tramo 8', '{"type":"LineString","coordinates":[[-56.1589268,-34.8829236],[-56.1583956,-34.8823022]]}', 9, 1, 1),
    ('osm-3d4a9dc2d7beb79b0ee1', 'Carlos Anaya — tramo 9', '{"type":"LineString","coordinates":[[-56.1583956,-34.8823022],[-56.1579828,-34.8818079],[-56.1574148,-34.8811204]]}', 19, 3, 1),
    ('osm-4dbbcdc7ba5835f25c96', 'Carlos Anaya — tramo 10', '{"type":"LineString","coordinates":[[-56.1574148,-34.8811204],[-56.1570574,-34.8807554],[-56.1567498,-34.8803133]]}', 12, 1, 1),
    ('osm-5cc35f08cc2d5f58b313', 'Ciudad de Bahía Blanca — tramo 1', '{"type":"LineString","coordinates":[[-56.1619718,-34.8958393],[-56.1619588,-34.8957796],[-56.1618114,-34.8956012]]}', 1, 1, 1),
    ('osm-94ac3095d3b9af025d59', 'Ciudad de Bahía Blanca — tramo 2', '{"type":"LineString","coordinates":[[-56.1618114,-34.8956012],[-56.1617465,-34.8955261],[-56.1611231,-34.89481]]}', 12, 5, 1),
    ('osm-c8c7440e8dd4cc6cb2a5', 'Ciudad de Bahía Blanca — tramo 3', '{"type":"LineString","coordinates":[[-56.1611231,-34.89481],[-56.1604723,-34.8940455]]}', 11, 5, 1),
    ('osm-c93e2b359ef4edfa5825', 'Ciudad de Bahía Blanca — tramo 4', '{"type":"LineString","coordinates":[[-56.1604723,-34.8940455],[-56.1598104,-34.893277]]}', 11, 6, 1),
    ('osm-1372d35f7a173e8cf06a', 'Ciudad de Bahía Blanca — tramo 5', '{"type":"LineString","coordinates":[[-56.1598104,-34.893277],[-56.1593403,-34.8926583],[-56.1592517,-34.8925777],[-56.1591416,-34.892524],[-56.1591095,-34.8925161],[-56.1590122,-34.8925321],[-56.1589333,-34.8925591]]}', 14, 1, 1),
    ('osm-076703bf9178392a2fac', 'Comandante Braga — tramo 1', '{"type":"LineString","coordinates":[[-56.1620841,-34.8844734],[-56.1620039,-34.8845495],[-56.1609438,-34.8853406]]}', 17, 10, 1),
    ('osm-b7325606ed54dc287eb0', 'Comandante Braga — tramo 2', '{"type":"LineString","coordinates":[[-56.1609438,-34.8853406],[-56.1600465,-34.8859594]]}', 12, 1, 1),
    ('osm-8221f95df0af7a04c579', 'Comandante Braga — tramo 3', '{"type":"LineString","coordinates":[[-56.1600465,-34.8859594],[-56.159172,-34.8865863]]}', 12, 0, 1),
    ('osm-a6d92b5c37bc4c313e98', 'Comandante Braga — tramo 4', '{"type":"LineString","coordinates":[[-56.159172,-34.8865863],[-56.1583219,-34.8872006]]}', 11, 6, 1),
    ('osm-038959d9560f1c4591f1', 'Comodoro Coe — tramo 1', '{"type":"LineString","coordinates":[[-56.146287,-34.8959989],[-56.1461395,-34.8959415],[-56.1457986,-34.8957973]]}', 4, 0, 1),
    ('osm-2878633b0414319d718a', 'Comodoro Coe — tramo 2', '{"type":"LineString","coordinates":[[-56.1452614,-34.8955678],[-56.1441141,-34.8950588],[-56.1439034,-34.8949634],[-56.1438129,-34.8949216],[-56.1437199,-34.8948825]]}', 19, 1, 1),
    ('osm-b38c6eae17260d0df86b', 'Cornelio Cantera — tramo 1', '{"type":"LineString","coordinates":[[-56.1591501,-34.8898774],[-56.15812,-34.8886404]]}', 20, 1, 1),
    ('osm-c7f14ec343b5dae6ea05', 'Cornelio Cantera — tramo 2', '{"type":"LineString","coordinates":[[-56.15812,-34.8886404],[-56.1573924,-34.8877739]]}', 13, 2, 1),
    ('osm-61ebce77a1f4593fa770', 'Cornelio Cantera — tramo 3', '{"type":"LineString","coordinates":[[-56.1573924,-34.8877739],[-56.1565524,-34.8867934]]}', 15, 1, 1),
    ('osm-cd6218b000e0c85ac423', 'Cornelio Cantera — tramo 4', '{"type":"LineString","coordinates":[[-56.1565524,-34.8867934],[-56.1563021,-34.8864995],[-56.1557151,-34.885811]]}', 15, 2, 1),
    ('osm-6863552de6a07ae69708', 'Cornelio Cantera — tramo 5', '{"type":"LineString","coordinates":[[-56.1557151,-34.885811],[-56.1548314,-34.8848181]]}', 16, 1, 1),
    ('osm-400bf346e95bb4d0f650', 'Coronel Lucas Píriz — tramo 1', '{"type":"LineString","coordinates":[[-56.1612451,-34.8837879],[-56.1603147,-34.8845833]]}', 14, 2, 1),
    ('osm-e81da7170b7d8ddde2f4', 'Doctor Atilio Narancio — tramo 1', '{"type":"LineString","coordinates":[[-56.1508988,-34.8951918],[-56.1491032,-34.8950987]]}', 20, 1, 1),
    ('osm-6f7f909726ed485b748b', 'Doctor Atilio Narancio — tramo 2', '{"type":"LineString","coordinates":[[-56.1491032,-34.8950987],[-56.1489568,-34.8950937],[-56.1488752,-34.8950818],[-56.1487623,-34.8950468]]}', 1, 0, 1),
    ('osm-8bb602b131d98a2e3b39', 'Doctor José Brito Foresti — tramo 1', '{"type":"LineString","coordinates":[[-56.1538989,-34.88798],[-56.1536892,-34.8880464]]}', 0, 0, 1),
    ('osm-dd51f599bcc5aa80cc82', 'Doctor José Brito Foresti — tramo 2', '{"type":"LineString","coordinates":[[-56.1536892,-34.8880464],[-56.1535962,-34.8880744],[-56.1535278,-34.8880995],[-56.1534755,-34.8881294],[-56.1534213,-34.8881909],[-56.1533768,-34.8882543],[-56.153313,-34.8883524]]}', 4, 0, 1),
    ('osm-e153e91be4e4bfff6cc7', 'Doctor José Brito Foresti — tramo 3', '{"type":"LineString","coordinates":[[-56.153313,-34.8883524],[-56.1530459,-34.8887228]]}', 4, 1, 1),
    ('osm-8ee4ccd26df0d50e8e29', 'Doctor José Brito Foresti — tramo 4', '{"type":"LineString","coordinates":[[-56.1530459,-34.8887228],[-56.1525196,-34.8895]]}', 11, 0, 1),
    ('osm-a686da2a14af8fb37e33', 'Doctor José Brito Foresti — tramo 5', '{"type":"LineString","coordinates":[[-56.1525196,-34.8895],[-56.1519362,-34.8903306]]}', 12, 4, 1),
    ('osm-63da7078b41fdee8eced', 'Doctor José Brito Foresti — tramo 6', '{"type":"LineString","coordinates":[[-56.1519362,-34.8903306],[-56.1518949,-34.8904244],[-56.1518518,-34.8905278]]}', 0, 0, 1),
    ('osm-d7d465f04835a06880e0', 'Doctor Manuel Quintela — tramo 1', '{"type":"LineString","coordinates":[[-56.1497719,-34.8942036],[-56.1491803,-34.8929636],[-56.1491645,-34.8929211]]}', 18, 6, 1),
    ('osm-f4f87a013536e8e82a11', 'Doctor Manuel Quintela — tramo 2', '{"type":"LineString","coordinates":[[-56.1491645,-34.8929211],[-56.1490978,-34.8927908],[-56.1490661,-34.8927173]]}', 0, 0, 1),
    ('osm-05e41e80e571ad2d1044', 'Doctor Manuel Quintela — tramo 3', '{"type":"LineString","coordinates":[[-56.1490661,-34.8927173],[-56.1489795,-34.8925427]]}', 0, 0, 1),
    ('osm-f48f9a7738ef027cd53f', 'Doctor Manuel Quintela — tramo 4', '{"type":"LineString","coordinates":[[-56.1489795,-34.8925427],[-56.1484244,-34.8913537]]}', 17, 10, 1),
    ('osm-4a11b584142eef9bb107', 'Doctor Manuel Quintela — tramo 5', '{"type":"LineString","coordinates":[[-56.1484244,-34.8913537],[-56.1480801,-34.8906267]]}', 9, 3, 1),
    ('osm-dbd136252a162a60afbb', 'Doctor Manuel Quintela — tramo 6', '{"type":"LineString","coordinates":[[-56.1480801,-34.8906267],[-56.1479176,-34.8902777]]}', 3, 0, 1),
    ('osm-4d575c7cf8c5337f8c64', 'Doctor Pedro Escuder Núñez — tramo 1', '{"type":"LineString","coordinates":[[-56.1528757,-34.8859275],[-56.1528162,-34.8859716],[-56.1527766,-34.8860129],[-56.1527339,-34.886066],[-56.1525983,-34.8863202],[-56.1525374,-34.8864398],[-56.1522926,-34.8869443]]}', 14, 2, 1),
    ('osm-caf7e81263b4d486f56b', 'Doctor Pedro Escuder Núñez — tramo 2', '{"type":"LineString","coordinates":[[-56.1522926,-34.8869443],[-56.1519131,-34.887663]]}', 9, 0, 1),
    ('osm-0e757ef0cd904588484e', 'Doctor Pedro Escuder Núñez — tramo 3', '{"type":"LineString","coordinates":[[-56.1519131,-34.887663],[-56.1516118,-34.8882335]]}', 7, 3, 1),
    ('osm-e3aa7c9629e061dbb720', 'Doctor Pedro Escuder Núñez — tramo 4', '{"type":"LineString","coordinates":[[-56.1516118,-34.8882335],[-56.1511851,-34.8890417]]}', 5, 0, 1),
    ('osm-cf93274b471b8bc8d9cc', 'Doctor Pedro Escuder Núñez — tramo 5', '{"type":"LineString","coordinates":[[-56.1511851,-34.8890417],[-56.1506692,-34.8900026]]}', 6, 0, 1),
    ('osm-1c0a9cceb7700e73d336', 'Estero Bellaco — tramo 1', '{"type":"LineString","coordinates":[[-56.1631381,-34.8853541],[-56.1619809,-34.8861909],[-56.161764,-34.8863337]]}', 20, 11, 1),
    ('osm-7b86ce2ff2c29ccd2c08', 'Estero Bellaco — tramo 2', '{"type":"LineString","coordinates":[[-56.161764,-34.8863337],[-56.1608877,-34.8869543]]}', 12, 11, 1),
    ('osm-bc022460ab5a241e538d', 'Estero Bellaco — tramo 3', '{"type":"LineString","coordinates":[[-56.1608877,-34.8869543],[-56.1602513,-34.8874097],[-56.1600856,-34.8875231],[-56.1600098,-34.887576]]}', 12, 1, 1),
    ('osm-ccd2b2ac58ccfd066019', 'Estero Bellaco — tramo 4', '{"type":"LineString","coordinates":[[-56.1600098,-34.887576],[-56.1592253,-34.8880554],[-56.1590927,-34.8881112]]}', 11, 0, 1),
    ('osm-81d23a9e328fba588b9b', 'Estero Bellaco — tramo 5', '{"type":"LineString","coordinates":[[-56.1590927,-34.8881112],[-56.15812,-34.8886404]]}', 12, 0, 1),
    ('osm-9a03f29c53a1308bb7d5', 'Estero Bellaco — tramo 6', '{"type":"LineString","coordinates":[[-56.15812,-34.8886404],[-56.1571107,-34.8890518]]}', 11, 1, 1),
    ('osm-1e70e4a06d8af465eb79', 'Estero Bellaco — tramo 7', '{"type":"LineString","coordinates":[[-56.1571107,-34.8890518],[-56.156237,-34.8894064]]}', 9, 3, 1),
    ('osm-2f309ca99c1c1c155ce8', 'Estero Bellaco — tramo 8', '{"type":"LineString","coordinates":[[-56.156237,-34.8894064],[-56.1554216,-34.8897524]]}', 9, 0, 1),
    ('osm-17ae2a34af661650682d', 'Estero Bellaco — tramo 9', '{"type":"LineString","coordinates":[[-56.1554216,-34.8897524],[-56.1549994,-34.8899255]]}', 3, 1, 1),
    ('osm-ed49a54a6aefa40eaaba', 'Estero Bellaco — tramo 10', '{"type":"LineString","coordinates":[[-56.1549994,-34.8899255],[-56.1547849,-34.8900084]]}', 0, 0, 1),
    ('osm-3f49c3239be8b08fb8d2', 'Federico Susviela Guarch — tramo 1', '{"type":"LineString","coordinates":[[-56.1556415,-34.8877487],[-56.1553972,-34.8874441]]}', 3, 1, 1),
    ('osm-63f4eb9a8242f3d3e9f4', 'Federico Susviela Guarch — tramo 2', '{"type":"LineString","coordinates":[[-56.1553972,-34.8874441],[-56.1553396,-34.8874795],[-56.1553148,-34.8874928],[-56.1552956,-34.8874972],[-56.1552682,-34.887497],[-56.1552444,-34.8874923],[-56.1552232,-34.8874877],[-56.155184,-34.8874685],[-56.1544696,-34.8869607]]}', 12, 10, 1),
    ('osm-7d971566be3511e3d823', 'Federico Susviela Guarch — tramo 3', '{"type":"LineString","coordinates":[[-56.1549302,-34.8865368],[-56.1547918,-34.8864657],[-56.1533803,-34.8856644]]}', 21, 1, 1),
    ('osm-29d91a6b4902e72bb081', 'Federico Susviela Guarch — tramo 4', '{"type":"LineString","coordinates":[[-56.1533803,-34.8856644],[-56.1533598,-34.8856273],[-56.1529399,-34.8853798]]}', 4, 0, 1),
    ('osm-b0b789fcf9de3dd87d0c', 'Federico Susviela Guarch — tramo 5', '{"type":"LineString","coordinates":[[-56.1533803,-34.8856644],[-56.1533105,-34.885653],[-56.153258,-34.8856499],[-56.1531818,-34.8856612],[-56.1530407,-34.8857502]]}', 2, 0, 1),
    ('osm-926e7f75fe6d17088993', 'Federico Susviela Guarch — tramo 6', '{"type":"LineString","coordinates":[[-56.1529399,-34.8853798],[-56.1527275,-34.8854144]]}', 0, 0, 1),
    ('osm-c57420f7164d771df41b', 'General Las Heras — tramo 1', '{"type":"LineString","coordinates":[[-56.1506692,-34.8900026],[-56.1506023,-34.8901285],[-56.1505669,-34.8901953]]}', 0, 0, 1),
    ('osm-315a6b2bc56788572cc2', 'General Las Heras — tramo 2', '{"type":"LineString","coordinates":[[-56.1505669,-34.8901953],[-56.1502085,-34.8908023],[-56.1501186,-34.8909621],[-56.1498902,-34.8913283]]}', 16, 1, 1),
    ('osm-e67d88fec45d4d3975d4', 'General Las Heras — tramo 3', '{"type":"LineString","coordinates":[[-56.1498902,-34.8913283],[-56.1495589,-34.8918932],[-56.1493477,-34.8922534],[-56.1492611,-34.8924011],[-56.1490661,-34.8927173]]}', 21, 4, 1),
    ('osm-05dbde93660ec7136fe8', 'General Las Heras — tramo 4', '{"type":"LineString","coordinates":[[-56.1490661,-34.8927173],[-56.1484054,-34.8938566]]}', 16, 8, 1),
    ('osm-d20f0652d6bc3b813b84', 'General Las Heras — tramo 5', '{"type":"LineString","coordinates":[[-56.1484054,-34.8938566],[-56.1479203,-34.8946686]]}', 11, 6, 1),
    ('osm-1598cf1bb35081bcffba', 'General Las Heras — tramo 6', '{"type":"LineString","coordinates":[[-56.1479203,-34.8946686],[-56.1474682,-34.8954555]]}', 10, 1, 1),
    ('osm-2f54bff80449f5afd01b', 'General Las Heras — tramo 7', '{"type":"LineString","coordinates":[[-56.1474682,-34.8954555],[-56.1472119,-34.8958562]]}', 4, 0, 1),
    ('osm-b486e4167a984c5537b1', 'General Pagola — tramo 1', '{"type":"LineString","coordinates":[[-56.165451,-34.8897006],[-56.1649909,-34.8896499],[-56.1645432,-34.8896076],[-56.1644628,-34.8895881]]}', 10, 1, 1),
    ('osm-5f486d6d814862e46461', 'General Urquiza — tramo 1', '{"type":"LineString","coordinates":[[-56.1645193,-34.8929217],[-56.1638698,-34.8921508]]}', 11, 4, 1),
    ('osm-500cb2a448876df182c8', 'General Urquiza — tramo 2', '{"type":"LineString","coordinates":[[-56.1638698,-34.8921508],[-56.1633138,-34.8914662],[-56.1632475,-34.8913936]]}', 11, 1, 1),
    ('osm-03703086794a208db766', 'General Urquiza — tramo 3', '{"type":"LineString","coordinates":[[-56.1632475,-34.8913936],[-56.1626034,-34.8906317]]}', 11, 1, 1),
    ('osm-80613a0b8f2950aeaa51', 'General Urquiza — tramo 4', '{"type":"LineString","coordinates":[[-56.1626034,-34.8906317],[-56.1618002,-34.889683]]}', 15, 8, 1),
    ('osm-d94fd4ccebf5c39bb458', 'General Urquiza — tramo 5', '{"type":"LineString","coordinates":[[-56.1618002,-34.889683],[-56.1615785,-34.8894241],[-56.1610062,-34.8887496]]}', 15, 14, 1),
    ('osm-803c34ba9034631c9046', 'General Urquiza — tramo 6', '{"type":"LineString","coordinates":[[-56.1610062,-34.8887496],[-56.1600098,-34.887576]]}', 19, 2, 1),
    ('osm-8a8960a9e384b6d14dca', 'General Urquiza — tramo 7', '{"type":"LineString","coordinates":[[-56.1600098,-34.887576],[-56.159172,-34.8865863]]}', 16, 8, 1),
    ('osm-67085c27a7c1dacc711e', 'General Urquiza — tramo 8', '{"type":"LineString","coordinates":[[-56.159172,-34.8865863],[-56.1572979,-34.8843821]]}', 38, 6, 1),
    ('osm-1a055092f9730732b870', 'General Urquiza — tramo 9', '{"type":"LineString","coordinates":[[-56.1572979,-34.8843821],[-56.1564653,-34.8833774]]}', 16, 1, 1),
    ('osm-096321d4625ad545e57c', 'General Urquiza — tramo 10', '{"type":"LineString","coordinates":[[-56.1564653,-34.8833774],[-56.155547,-34.8822684],[-56.1554777,-34.8822105]]}', 19, 3, 1),
    ('osm-26ecd9693e6e55d44b1a', 'General Urquiza — tramo 11', '{"type":"LineString","coordinates":[[-56.1552469,-34.8821126],[-56.1552944,-34.8820405],[-56.1552986,-34.8819963],[-56.1552842,-34.8819517],[-56.1547603,-34.8813302]]}', 11, 1, 1),
    ('osm-22929b98497f04d6ae70', 'General Urquiza — tramo 12', '{"type":"LineString","coordinates":[[-56.1547603,-34.8813302],[-56.1545612,-34.8810718],[-56.1542454,-34.8807179],[-56.154106,-34.8805777]]}', 11, 6, 1),
    ('osm-acde66eb57949eef4c1c', 'Gerardo Grasso — tramo 1', '{"type":"LineString","coordinates":[[-56.1614541,-34.8923919],[-56.160245,-34.89145],[-56.159405,-34.8907956]]}', 20, 8, 1),
    ('osm-728ecc8232e619edb83f', 'Gerardo Grasso — tramo 2', '{"type":"LineString","coordinates":[[-56.1592864,-34.8907042],[-56.1586433,-34.8901987],[-56.1585741,-34.8900793]]}', 0, 0, 1),
    ('osm-4a0f9b0a2102de3c51dc', 'Gilbert — tramo 1', '{"type":"LineString","coordinates":[[-56.1565524,-34.8867934],[-56.1553972,-34.8874441]]}', 15, 1, 1),
    ('osm-de42cedbdc9fca6df811', 'Gregorio Funes — tramo 1', '{"type":"LineString","coordinates":[[-56.1530459,-34.8887228],[-56.1516118,-34.8882335]]}', 17, 2, 1),
    ('osm-cbf9b3ff48149686ca11', 'Gregorio Funes — tramo 2', '{"type":"LineString","coordinates":[[-56.1516118,-34.8882335],[-56.150377,-34.8878003]]}', 14, 1, 1),
    ('osm-9cafaa13218cdac8eb8b', 'Gregorio Funes — tramo 3', '{"type":"LineString","coordinates":[[-56.150377,-34.8878003],[-56.1488073,-34.8872305]]}', 19, 16, 1),
    ('osm-bcec09f8908822648752', 'Humaita — tramo 1', '{"type":"LineString","coordinates":[[-56.1580902,-34.8902488],[-56.1571509,-34.8891287],[-56.1571107,-34.8890518]]}', 19, 1, 1),
    ('osm-5fed6607d523e818683c', 'Humaita — tramo 2', '{"type":"LineString","coordinates":[[-56.1571107,-34.8890518],[-56.1563399,-34.8877784]]}', 19, 18, 1),
    ('osm-329fce6554c7f3d61ada', 'Héctor Scarone — tramo 1', '{"type":"LineString","coordinates":[[-56.156381,-34.8927212],[-56.1560333,-34.8930037],[-56.1558732,-34.8930876],[-56.1558051,-34.893123],[-56.1556443,-34.8931895],[-56.1555435,-34.8932159],[-56.1553012,-34.8932277]]}', 13, 12, 1),
    ('osm-d9a2996ad56f888c2c56', 'Héctor Scarone — tramo 2', '{"type":"LineString","coordinates":[[-56.1553012,-34.8932277],[-56.1552357,-34.8932182],[-56.1551265,-34.8931904],[-56.1549927,-34.8931625],[-56.1549367,-34.8931576]]}', 2, 0, 1),
    ('osm-f222a145d1291c0de0fa', 'Héctor Scarone — tramo 3', '{"type":"LineString","coordinates":[[-56.1553012,-34.8932277],[-56.1551621,-34.8932538],[-56.1550827,-34.8932623],[-56.1550102,-34.8932618],[-56.1548647,-34.8932427],[-56.1547963,-34.8932468],[-56.1547059,-34.8932551],[-56.1544697,-34.8932905]]}', 8, 0, 1),
    ('osm-7f4af962227169aa2d70', 'Héctor Scarone — tramo 4', '{"type":"LineString","coordinates":[[-56.1549367,-34.8931576],[-56.1548434,-34.8931163],[-56.1547529,-34.8930706],[-56.1546625,-34.8930159],[-56.1545481,-34.892929],[-56.1544801,-34.8928656],[-56.1544183,-34.8927908]]}', 6, 2, 1),
    ('osm-32114e8ce4be499a34c3', 'Héctor Scarone — tramo 5', '{"type":"LineString","coordinates":[[-56.1549367,-34.8931576],[-56.1548813,-34.8931527],[-56.1547773,-34.8931565],[-56.1546814,-34.8931693],[-56.1544652,-34.8932044]]}', 3, 0, 1),
    ('osm-72bf8c02c7a4218b385b', 'Héctor Scarone — tramo 6', '{"type":"LineString","coordinates":[[-56.1544697,-34.8932905],[-56.154335,-34.893308]]}', 0, 0, 1),
    ('osm-720e0f359b6ba89e1fde', 'Héctor Scarone — tramo 7', '{"type":"LineString","coordinates":[[-56.1544652,-34.8932044],[-56.1542952,-34.8932397]]}', 0, 0, 1),
    ('osm-c53dc984c9a536d7be6c', 'Ibirapitá — tramo 1', '{"type":"LineString","coordinates":[[-56.1569893,-34.8906244],[-56.156237,-34.8894064]]}', 18, 17, 1),
    ('osm-2db15eb17c44f1c40ac0', 'Ibirapitá — tramo 2', '{"type":"LineString","coordinates":[[-56.156237,-34.8894064],[-56.1553206,-34.887905]]}', 23, 12, 1),
    ('osm-474b24e1308f1091cf37', 'Jaime Cibils — tramo 1', '{"type":"LineString","coordinates":[[-56.1595202,-34.8823617],[-56.1589268,-34.8829236]]}', 8, 1, 1),
    ('osm-a2d4bf81c21efc70da8a', 'Jaime Cibils — tramo 2', '{"type":"LineString","coordinates":[[-56.1589268,-34.8829236],[-56.158139,-34.8836206]]}', 12, 6, 1),
    ('osm-d5c8882d35d5d3055546', 'Jaime Cibils — tramo 3', '{"type":"LineString","coordinates":[[-56.158139,-34.8836206],[-56.1572979,-34.8843821]]}', 13, 0, 1),
    ('osm-748ad32209fea883484a', 'Jaime Cibils — tramo 4', '{"type":"LineString","coordinates":[[-56.1572979,-34.8843821],[-56.1565372,-34.8850507]]}', 11, 1, 1),
    ('osm-b64966347a491315c0de', 'Jaime Cibils — tramo 5', '{"type":"LineString","coordinates":[[-56.1565372,-34.8850507],[-56.1557151,-34.885811]]}', 13, 6, 1),
    ('osm-a2c8103348611f65dd79', 'Jaime Cibils — tramo 6', '{"type":"LineString","coordinates":[[-56.1557151,-34.885811],[-56.1549302,-34.8865368]]}', 12, 0, 1),
    ('osm-b7f2d80dc147eda52191', 'Jaime Cibils — tramo 7', '{"type":"LineString","coordinates":[[-56.1549302,-34.8865368],[-56.1547869,-34.8866752],[-56.1544696,-34.8869607]]}', 6, 3, 1),
    ('osm-af4937a106f38e833716', 'Jaime Cibils — tramo 8', '{"type":"LineString","coordinates":[[-56.1544696,-34.8869607],[-56.1540505,-34.8873525]]}', 5, 5, 1),
    ('osm-5f005f6f299c2445ed28', 'Jaime Cibils — tramo 9', '{"type":"LineString","coordinates":[[-56.1540505,-34.8873525],[-56.1539565,-34.8874879],[-56.1537958,-34.8877483]]}', 4, 2, 1),
    ('osm-4bfd2e6860dea1b1c0dd', 'Jaime Cibils — tramo 10', '{"type":"LineString","coordinates":[[-56.1540505,-34.8873525],[-56.1538609,-34.8874473],[-56.153682,-34.8874941]]}', 2, 2, 1),
    ('osm-95f8ec5dfe944469302c', 'Jaime Cibils — tramo 11', '{"type":"LineString","coordinates":[[-56.153682,-34.8874941],[-56.1534692,-34.8875624]]}', 0, 0, 1),
    ('osm-1ccdebb109de4f393c77', 'Joanicó — tramo 1', '{"type":"LineString","coordinates":[[-56.1554777,-34.8822105],[-56.1552469,-34.8821126]]}', 0, 0, 1),
    ('osm-151f697106bea7edcd30', 'Joanicó — tramo 2', '{"type":"LineString","coordinates":[[-56.1552469,-34.8821126],[-56.1542861,-34.8816199]]}', 11, 0, 1),
    ('osm-01f541efab92929cf220', 'Joanicó — tramo 3', '{"type":"LineString","coordinates":[[-56.1542861,-34.8816199],[-56.153395,-34.8811779]]}', 10, 1, 1),
    ('osm-06164613b0ad51cd7203', 'Joaquín Secco Illa — tramo 1', '{"type":"LineString","coordinates":[[-56.1583219,-34.8872006],[-56.1573924,-34.8877739]]}', 12, 1, 1),
    ('osm-5e0f1d74edab8304f1a7', 'Joaquín Secco Illa — tramo 2', '{"type":"LineString","coordinates":[[-56.1573924,-34.8877739],[-56.1573152,-34.887794],[-56.1572273,-34.8878079],[-56.1563399,-34.8877784]]}', 10, 1, 1),
    ('osm-1831c904490ab16d2e25', 'Joaquín Secco Illa — tramo 3', '{"type":"LineString","coordinates":[[-56.1563399,-34.8877784],[-56.1556415,-34.8877487]]}', 6, 3, 1),
    ('osm-b84605864c9e92af1894', 'Joaquín Secco Illa — tramo 4', '{"type":"LineString","coordinates":[[-56.1556415,-34.8877487],[-56.1553206,-34.887905]]}', 2, 0, 1),
    ('osm-97b05c7c2aae144fa53f', 'Joaquín Secco Illa — tramo 5', '{"type":"LineString","coordinates":[[-56.1553206,-34.887905],[-56.1545176,-34.8882906]]}', 9, 0, 1),
    ('osm-921cb512b5bb421427fd', 'Joaquín Secco Illa — tramo 6', '{"type":"LineString","coordinates":[[-56.1545176,-34.8882906],[-56.1541374,-34.8884585]]}', 2, 0, 1),
    ('osm-6bc79f17f4362c6fee7b', 'Joaquín Secco Illa — tramo 7', '{"type":"LineString","coordinates":[[-56.1541374,-34.8884585],[-56.1539388,-34.8885399]]}', 0, 0, 1),
    ('osm-48ee90c7a3b73c7f2ea6', 'Jorge Canning — tramo 1', '{"type":"LineString","coordinates":[[-56.1646406,-34.8968246],[-56.1645087,-34.8968081],[-56.1644165,-34.8967894],[-56.1640252,-34.8966373],[-56.1623116,-34.8959713],[-56.1619718,-34.8958393]]}', 34, 19, 1),
    ('osm-bcd045c6edad8d04fe54', 'Jorge Canning — tramo 2', '{"type":"LineString","coordinates":[[-56.1619718,-34.8958393],[-56.1617579,-34.8957679],[-56.161595,-34.8957195]]}', 2, 0, 1),
    ('osm-5fa318491018d0891d4d', 'Jorge Canning — tramo 3', '{"type":"LineString","coordinates":[[-56.161595,-34.8957195],[-56.1614856,-34.8956917],[-56.1609975,-34.8955745],[-56.160513,-34.8954866],[-56.1600728,-34.8954198],[-56.1596634,-34.8953577],[-56.1595617,-34.8953427]]}', 23, 9, 1),
    ('osm-e25b26c4e87069e2e716', 'Jorge Canning — tramo 4', '{"type":"LineString","coordinates":[[-56.1595617,-34.8953427],[-56.1592941,-34.8953066]]}', 0, 0, 1),
    ('osm-db7d84d87e7228824bed', 'José Mazzini — tramo 1', '{"type":"LineString","coordinates":[[-56.1498902,-34.8913283],[-56.1480801,-34.8906267]]}', 22, 3, 1),
    ('osm-6e77d1d7d0ea0a1e94d0', 'José Mazzini — tramo 2', '{"type":"LineString","coordinates":[[-56.1480801,-34.8906267],[-56.147759,-34.8905068]]}', 1, 0, 1),
    ('osm-6f9bd73fc11d48a7e550', 'José Mazzini — tramo 3', '{"type":"LineString","coordinates":[[-56.147759,-34.8905068],[-56.146886,-34.8901807],[-56.1468177,-34.8901544]]}', 10, 1, 1),
    ('osm-feaa70676157021ced7c', 'Juan Cabal — tramo 1', '{"type":"LineString","coordinates":[[-56.1566632,-34.8802546],[-56.1557595,-34.8807743]]}', 11, 6, 1),
    ('osm-a812cc587c8dacb1da62', 'Juan Cabal — tramo 2', '{"type":"LineString","coordinates":[[-56.1557595,-34.8807743],[-56.1547603,-34.8813302]]}', 12, 5, 1),
    ('osm-7ad645d07bc9bd67fcae', 'Juan Cabal — tramo 3', '{"type":"LineString","coordinates":[[-56.1547603,-34.8813302],[-56.1542861,-34.8816199]]}', 4, 1, 1),
    ('osm-38c11bac03f672bdfa83', 'Juan Ramón Gómez — tramo 1', '{"type":"LineString","coordinates":[[-56.1651899,-34.8921272],[-56.1650511,-34.8919439],[-56.1648188,-34.8916252]]}', 0, 0, 1),
    ('osm-ea59fab37d085a514948', 'Juan Ramón Gómez — tramo 2', '{"type":"LineString","coordinates":[[-56.1648188,-34.8916252],[-56.1641755,-34.8908634]]}', 11, 1, 1),
    ('osm-35d6e52f1c4d913c46a2', 'Juan Ramón Gómez — tramo 3', '{"type":"LineString","coordinates":[[-56.1641755,-34.8908634],[-56.1635935,-34.8901605],[-56.163541,-34.8900971]]}', 11, 4, 1),
    ('osm-263d889140b5517e7991', 'Juan Ramón Gómez — tramo 4', '{"type":"LineString","coordinates":[[-56.163541,-34.8900971],[-56.1627687,-34.8891754],[-56.162724,-34.8891221]]}', 15, 5, 1),
    ('osm-ef42adc5c24b617feed3', 'Juan Ramón Gómez — tramo 5', '{"type":"LineString","coordinates":[[-56.162724,-34.8891221],[-56.1619035,-34.8880965],[-56.1618211,-34.8880258]]}', 17, 2, 1),
    ('osm-8f247944ad979a9cfb4e', 'Juan Ramón Gómez — tramo 6', '{"type":"LineString","coordinates":[[-56.1618211,-34.8880258],[-56.161752,-34.8879666],[-56.1609381,-34.8870108],[-56.1608877,-34.8869543]]}', 17, 1, 1),
    ('osm-00255809327edea96c1a', 'Juan Ramón Gómez — tramo 7', '{"type":"LineString","coordinates":[[-56.1608877,-34.8869543],[-56.1600465,-34.8859594]]}', 16, 2, 1),
    ('osm-f82beecd315500b7cf7a', 'Juan Ramón Gómez — tramo 8', '{"type":"LineString","coordinates":[[-56.158139,-34.8836206],[-56.1574627,-34.8828162]]}', 12, 1, 1),
    ('osm-229cb7d7d1cb8f884515', 'Juan Ramón Gómez — tramo 9', '{"type":"LineString","coordinates":[[-56.1574627,-34.8828162],[-56.1564859,-34.8816578]]}', 19, 2, 1),
    ('osm-ad78a7d507a9cec1a2d6', 'Juan Ramón Gómez — tramo 10', '{"type":"LineString","coordinates":[[-56.1564859,-34.8816578],[-56.1557595,-34.8807743]]}', 13, 5, 1),
    ('osm-3730b20904bdab74b7af', 'Juan Ramón Gómez — tramo 11', '{"type":"LineString","coordinates":[[-56.1557595,-34.8807743],[-56.1549178,-34.8797864]]}', 16, 2, 1),
    ('osm-1424ba47a1ef8aa8c115', 'Juan Spikerman — tramo 1', '{"type":"LineString","coordinates":[[-56.1519525,-34.8847642],[-56.1511044,-34.8863894]]}', 24, 12, 1),
    ('osm-509360e2cdb7f6ac42e8', 'Juan Spikerman — tramo 2', '{"type":"LineString","coordinates":[[-56.1511044,-34.8863894],[-56.1507407,-34.8870861]]}', 9, 0, 1),
    ('osm-7ca8be4759d5b792a1ab', 'Juan Spikerman — tramo 3', '{"type":"LineString","coordinates":[[-56.1507407,-34.8870861],[-56.150377,-34.8878003]]}', 9, 3, 1),
    ('osm-b9912b25bcad23138b3a', 'Juan Spikerman — tramo 4', '{"type":"LineString","coordinates":[[-56.150377,-34.8878003],[-56.1499499,-34.8886152]]}', 11, 4, 1),
    ('osm-3ed85b082857de8193ec', 'Juan Spikerman — tramo 5', '{"type":"LineString","coordinates":[[-56.1499499,-34.8886152],[-56.1494759,-34.8895225]]}', 12, 4, 1),
    ('osm-c81bea8abb5b0e099a85', 'Juan Spikerman — tramo 6', '{"type":"LineString","coordinates":[[-56.1492373,-34.8896787],[-56.1480801,-34.8906267]]}', 18, 2, 1),
    ('osm-8818c14f7d4786169cb3', 'Lord Ponsomby — tramo 1', '{"type":"LineString","coordinates":[[-56.1593206,-34.8964791],[-56.1591363,-34.8964556],[-56.1590606,-34.8964459]]}', 0, 0, 1),
    ('osm-6cbb5c2edfd163c8686b', 'Luis Sambucetti — tramo 1', '{"type":"LineString","coordinates":[[-56.1582694,-34.8901824],[-56.1582029,-34.8902631],[-56.1574563,-34.8916372]]}', 22, 12, 1),
    ('osm-ec7aadb66eeeaadb49a4', 'Maipú — tramo 1', '{"type":"LineString","coordinates":[[-56.148531,-34.8893579],[-56.1479176,-34.8902777]]}', 13, 1, 1),
    ('osm-0237125936beb35ef94c', 'Maipú — tramo 2', '{"type":"LineString","coordinates":[[-56.1479176,-34.8902777],[-56.147759,-34.8905068]]}', 1, 0, 1),
    ('osm-187def8c785fe2e82519', 'Maipú — tramo 3', '{"type":"LineString","coordinates":[[-56.147759,-34.8905068],[-56.1469252,-34.8917542]]}', 19, 10, 1),
    ('osm-726a4c8bb2878ddfaceb', 'Maipú — tramo 4', '{"type":"LineString","coordinates":[[-56.1469252,-34.8917542],[-56.1461899,-34.8928381]]}', 16, 6, 1),
    ('osm-93cf8ce083c9b646d651', 'Maipú — tramo 5', '{"type":"LineString","coordinates":[[-56.1461899,-34.8928381],[-56.1456733,-34.8936228]]}', 11, 1, 1),
    ('osm-e97134f3e4879dddef71', 'Maipú — tramo 6', '{"type":"LineString","coordinates":[[-56.1456733,-34.8936228],[-56.1452202,-34.8943218],[-56.1452105,-34.8943552],[-56.1452127,-34.8944331]]}', 11, 4, 1),
    ('osm-d939fbbc8b09893434a3', 'Maipú — tramo 7', '{"type":"LineString","coordinates":[[-56.1452896,-34.8960616],[-56.1452614,-34.8955678]]}', 5, 1, 1),
    ('osm-168c9928acf728a551fd', 'Maipú — tramo 8', '{"type":"LineString","coordinates":[[-56.1452614,-34.8955678],[-56.1452127,-34.8944331]]}', 14, 2, 1),
    ('osm-a5419cc843bc650c6de5', 'Manuel Alonso — tramo 1', '{"type":"LineString","coordinates":[[-56.1491245,-34.8947921],[-56.149115,-34.8948573],[-56.1491111,-34.8949083],[-56.149107,-34.8950214],[-56.1491032,-34.8950987]]}', 2, 2, 1),
    ('osm-13801f5995a97bf77be7', 'Manuel Alonso — tramo 2', '{"type":"LineString","coordinates":[[-56.1491032,-34.8950987],[-56.1490557,-34.8959909],[-56.1490462,-34.896167]]}', 13, 0, 1),
    ('osm-9e4798bda17db0db63ca', 'Mariano Moreno — tramo 1', '{"type":"LineString","coordinates":[[-56.1576966,-34.8809544],[-56.1574148,-34.8811204]]}', 1, 0, 1),
    ('osm-6856c602911d0aeb1c94', 'Mariano Moreno — tramo 2', '{"type":"LineString","coordinates":[[-56.1574148,-34.8811204],[-56.1564859,-34.8816578]]}', 11, 1, 1),
    ('osm-5931e994167a95927dcf', 'Mariano Moreno — tramo 3', '{"type":"LineString","coordinates":[[-56.1564859,-34.8816578],[-56.1561696,-34.8818242],[-56.1558612,-34.8819996],[-56.1554777,-34.8822105]]}', 12, 0, 1),
    ('osm-f1bd1d52870baf303c2f', 'Mariano Moreno — tramo 4', '{"type":"LineString","coordinates":[[-56.1554777,-34.8822105],[-56.1541237,-34.8829817]]}', 18, 3, 1),
    ('osm-c9506d14f52c865d6912', 'Monte Caseros — tramo 1', '{"type":"LineString","coordinates":[[-56.1654912,-34.889323],[-56.1652296,-34.8888676],[-56.1651795,-34.8887783],[-56.164981,-34.888408],[-56.1648886,-34.8882357],[-56.1647878,-34.8880477],[-56.1647269,-34.8879389]]}', 20, 10, 1),
    ('osm-6f714be93c3a52b01ae8', 'Monte Caseros — tramo 2', '{"type":"LineString","coordinates":[[-56.1647269,-34.8879389],[-56.1638367,-34.8863428]]}', 24, 2, 1),
    ('osm-53a21746f0b5bd8836f3', 'Monte Caseros — tramo 3', '{"type":"LineString","coordinates":[[-56.1637254,-34.8861477],[-56.1633877,-34.8856667],[-56.1632433,-34.8854573]]}', 9, 1, 1),
    ('osm-417bab6f4a3dbdfe6ccb', 'Monte Caseros — tramo 4', '{"type":"LineString","coordinates":[[-56.1630773,-34.8852995],[-56.1624485,-34.8847765],[-56.1620841,-34.8844734]]}', 15, 1, 1),
    ('osm-c1dd63acba311e6194c3', 'Monte Caseros — tramo 5', '{"type":"LineString","coordinates":[[-56.1620841,-34.8844734],[-56.1612451,-34.8837879]]}', 12, 5, 1),
    ('osm-01083c9063e0d9cd0c4c', 'Monte Caseros — tramo 6', '{"type":"LineString","coordinates":[[-56.1612451,-34.8837879],[-56.1604312,-34.8831071]]}', 12, 2, 1),
    ('osm-6727d1c71461c231d4d6', 'Monte Caseros — tramo 7', '{"type":"LineString","coordinates":[[-56.1604312,-34.8831071],[-56.1602149,-34.8829301],[-56.1595202,-34.8823617]]}', 13, 5, 1),
    ('osm-639f78916ec5e6d44224', 'Monte Caseros — tramo 8', '{"type":"LineString","coordinates":[[-56.1595202,-34.8823617],[-56.1590053,-34.8819375]]}', 6, 1, 1),
    ('osm-4f5d85c08bbfc25c6b16', 'Monte Caseros — tramo 9', '{"type":"LineString","coordinates":[[-56.1590053,-34.8819375],[-56.1585417,-34.8815612],[-56.1583233,-34.8813856],[-56.158094,-34.8812186]]}', 13, 6, 1),
    ('osm-666efaf8b89dec44428f', 'Monte Caseros — tramo 10', '{"type":"LineString","coordinates":[[-56.1567498,-34.8803133],[-56.1566632,-34.8802546]]}', 0, 0, 1),
    ('osm-9687d35b8c1244b4ae7e', 'Monte Caseros — tramo 11', '{"type":"LineString","coordinates":[[-56.1566632,-34.8802546],[-56.1556326,-34.8795651],[-56.1552464,-34.8792999]]}', 20, 2, 1),
    ('osm-0b81c7449c46ebad6fec', 'Morales — tramo 1', '{"type":"LineString","coordinates":[[-56.163712,-34.8944703],[-56.1636456,-34.8945161],[-56.1636047,-34.8945443],[-56.1626117,-34.8951359]]}', 14, 1, 1),
    ('osm-6f48d8d76842a90a51c9', 'Morales — tramo 2', '{"type":"LineString","coordinates":[[-56.1626117,-34.8951359],[-56.1618114,-34.8956012]]}', 9, 5, 1),
    ('osm-a8bc08cb9de3a3d56a22', 'Morales — tramo 3', '{"type":"LineString","coordinates":[[-56.1618114,-34.8956012],[-56.161595,-34.8957195]]}', 0, 0, 1),
    ('osm-e5869081cfca9d86c974', 'Navarra — tramo 1', '{"type":"LineString","coordinates":[[-56.1484244,-34.8913537],[-56.1479601,-34.8921515]]}', 11, 1, 1),
    ('osm-431e0eee7cd53ceaabe1', 'Navarra — tramo 2', '{"type":"LineString","coordinates":[[-56.1479601,-34.8921515],[-56.1472445,-34.89333]]}', 17, 2, 1),
    ('osm-c4204048511c8264ded4', 'Navarra — tramo 3', '{"type":"LineString","coordinates":[[-56.1472445,-34.89333],[-56.1467821,-34.8941421]]}', 11, 1, 1),
    ('osm-4e4c0b6cc9e638fcc36a', 'Navarra — tramo 4', '{"type":"LineString","coordinates":[[-56.1467821,-34.8941421],[-56.1463156,-34.8949311]]}', 11, 10, 1),
    ('osm-54e82653c7ba9c951f2b', 'Navarra — tramo 5', '{"type":"LineString","coordinates":[[-56.1463156,-34.8949311],[-56.1462543,-34.8950276],[-56.1458185,-34.8957629],[-56.1457986,-34.8957973]]}', 12, 4, 1),
    ('osm-7b3d1bf62a2e5a0c1fb2', 'Navarra — tramo 6', '{"type":"LineString","coordinates":[[-56.1457986,-34.8957973],[-56.1456821,-34.8959973],[-56.1456527,-34.896085]]}', 2, 0, 1),
    ('osm-1a2fe4e40ab2f1694f9f', 'Pedro Olmida — tramo 1', '{"type":"LineString","coordinates":[[-56.1590053,-34.8819375],[-56.1583956,-34.8823022]]}', 7, 6, 1),
    ('osm-9c617913b2ff72b380e9', 'Pedro Olmida — tramo 2', '{"type":"LineString","coordinates":[[-56.1583956,-34.8823022],[-56.1574627,-34.8828162]]}', 11, 10, 1),
    ('osm-84670ad12e36599d05bd', 'Pedro Olmida — tramo 3', '{"type":"LineString","coordinates":[[-56.1574627,-34.8828162],[-56.1564653,-34.8833774]]}', 12, 11, 1),
    ('osm-fd56acab495112b8633d', 'Pedro Olmida — tramo 4', '{"type":"LineString","coordinates":[[-56.1564653,-34.8833774],[-56.1555731,-34.8838864]]}', 11, 4, 1),
    ('osm-5cd0edcc911c687bd647', 'Presidente Berro — tramo 1', '{"type":"LineString","coordinates":[[-56.1653937,-34.8902145],[-56.1652749,-34.8902398],[-56.1641755,-34.8908634]]}', 15, 1, 1),
    ('osm-830c98beed2669b401b3', 'Presidente Berro — tramo 2', '{"type":"LineString","coordinates":[[-56.1641755,-34.8908634],[-56.1632475,-34.8913936]]}', 11, 6, 1),
    ('osm-571c0f6e0c6824f86549', 'Presidente Berro — tramo 3', '{"type":"LineString","coordinates":[[-56.1632475,-34.8913936],[-56.1623132,-34.8919032]]}', 11, 1, 1),
    ('osm-c892e61a6d9c7c311716', 'Presidente Berro — tramo 4', '{"type":"LineString","coordinates":[[-56.1623132,-34.8919032],[-56.1622288,-34.8919533]]}', 0, 0, 1),
    ('osm-21a22ea40c8945cac99a', 'Presidente Berro — tramo 5', '{"type":"LineString","coordinates":[[-56.1622288,-34.8919533],[-56.1614541,-34.8923919]]}', 9, 0, 1),
    ('osm-ad6b65448a70bc6261df', 'Presidente Berro — tramo 6', '{"type":"LineString","coordinates":[[-56.1614541,-34.8923919],[-56.1607332,-34.8927917],[-56.1606084,-34.8928547]]}', 10, 1, 1),
    ('osm-181eb4d6b66af62885ef', 'Presidente Berro — tramo 7', '{"type":"LineString","coordinates":[[-56.1606084,-34.8928547],[-56.1603936,-34.8929697]]}', 0, 0, 1),
    ('osm-9b3684b8b89325bdf7da', 'Presidente Berro — tramo 8', '{"type":"LineString","coordinates":[[-56.1603936,-34.8929697],[-56.1598104,-34.893277]]}', 6, 0, 1),
    ('osm-c600eada6b1903ca61f6', 'Presidente Giro — tramo 1', '{"type":"LineString","coordinates":[[-56.1644628,-34.8895881],[-56.163541,-34.8900971]]}', 11, 10, 1),
    ('osm-05ce6aca162a7b04b0e3', 'Presidente Giro — tramo 2', '{"type":"LineString","coordinates":[[-56.163541,-34.8900971],[-56.1626034,-34.8906317]]}', 11, 4, 1),
    ('osm-8a990f2186828ba97a6b', 'Presidente Lorenzo Batlle — tramo 1', '{"type":"LineString","coordinates":[[-56.1652709,-34.8914225],[-56.1650965,-34.8914864],[-56.1648188,-34.8916252]]}', 4, 0, 1),
    ('osm-8ebbcd34ac19237e717d', 'Presidente Lorenzo Batlle — tramo 2', '{"type":"LineString","coordinates":[[-56.1652344,-34.8917011],[-56.1650203,-34.8916763],[-56.1649274,-34.8916576],[-56.1648188,-34.8916252]]}', 0, 0, 1),
    ('osm-179c6bdfc2b5922ee430', 'Presidente Lorenzo Batlle — tramo 3', '{"type":"LineString","coordinates":[[-56.1648188,-34.8916252],[-56.1638698,-34.8921508]]}', 11, 5, 1),
    ('osm-f98db0e7f260571d4b8c', 'Presidente Lorenzo Batlle — tramo 4', '{"type":"LineString","coordinates":[[-56.1638698,-34.8921508],[-56.1629846,-34.8926316]]}', 10, 1, 1),
    ('osm-bdee1c51330b0dbf4bdc', 'Presidente Lorenzo Batlle — tramo 5', '{"type":"LineString","coordinates":[[-56.1614095,-34.8935057],[-56.1604723,-34.8940455]]}', 11, 1, 1),
    ('osm-21fd89c4a4aa6822817d', 'Presidente Lorenzo Batlle — tramo 6', '{"type":"LineString","coordinates":[[-56.1604723,-34.8940455],[-56.1596029,-34.8945262]]}', 10, 1, 1),
    ('osm-ff854037d41b76705959', 'Profesor Doctor Julio A. Bauzá — tramo 1', '{"type":"LineString","coordinates":[[-56.1637685,-34.8957299],[-56.1626117,-34.8951359]]}', 14, 1, 1),
    ('osm-60120b99bfec57f0b6de', 'Profesor Doctor Julio A. Bauzá — tramo 2', '{"type":"LineString","coordinates":[[-56.1626117,-34.8951359],[-56.1616121,-34.8946199],[-56.1615694,-34.8945718]]}', 13, 1, 1),
    ('osm-e8e7b70f9123b99f0e07', 'Profesor Doctor Pablo Purriel — tramo 1', '{"type":"LineString","coordinates":[[-56.1527741,-34.8846544],[-56.1525476,-34.8846872]]}', 0, 0, 1),
    ('osm-592b25ab5c1b021e77de', 'Profesor Doctor Pablo Purriel — tramo 2', '{"type":"LineString","coordinates":[[-56.1525476,-34.8846872],[-56.1519525,-34.8847642]]}', 5, 0, 1),
    ('osm-b33f2a6f5cec9b682ffa', 'Profesor Doctor Pablo Purriel — tramo 3', '{"type":"LineString","coordinates":[[-56.1519525,-34.8847642],[-56.151042,-34.8840642]]}', 13, 1, 1),
    ('osm-84b3f0735018be10459d', 'Ramón Ortiz — tramo 1', '{"type":"LineString","coordinates":[[-56.153313,-34.8883524],[-56.1519131,-34.887663]]}', 18, 3, 1),
    ('osm-7b42d720682310d11d65', 'Ramón Ortiz — tramo 2', '{"type":"LineString","coordinates":[[-56.1519131,-34.887663],[-56.1507407,-34.8870861]]}', 14, 0, 1),
    ('osm-3b90c087075c4a7c45dd', 'Ramón y Cajal — tramo 1', '{"type":"LineString","coordinates":[[-56.1647269,-34.8879389],[-56.1646737,-34.8879577],[-56.1646274,-34.887976],[-56.1643104,-34.8881502]]}', 3, 0, 1),
    ('osm-500e099cac900abbd0a0', 'Ramón y Cajal — tramo 2', '{"type":"LineString","coordinates":[[-56.1643104,-34.8881502],[-56.1636408,-34.8885603]]}', 8, 1, 1),
    ('osm-889c7fad267e9379551c', 'Ramón y Cajal — tramo 3', '{"type":"LineString","coordinates":[[-56.1636408,-34.8885603],[-56.162724,-34.8891221]]}', 11, 1, 1),
    ('osm-93d779a50e0c37db1475', 'Ramón y Cajal — tramo 4', '{"type":"LineString","coordinates":[[-56.162724,-34.8891221],[-56.1624199,-34.8893004],[-56.1618002,-34.889683]]}', 12, 6, 1),
    ('osm-f3740ac2c8a515cf97ef', 'República Dominicana — tramo 1', '{"type":"LineString","coordinates":[[-56.1533837,-34.8873611],[-56.1532763,-34.8873592],[-56.1531789,-34.8873486],[-56.1530963,-34.8873266],[-56.1523871,-34.8869946],[-56.1522926,-34.8869443]]}', 12, 1, 1),
    ('osm-b7ece8a9db66677d6fb0', 'República Dominicana — tramo 2', '{"type":"LineString","coordinates":[[-56.1522926,-34.8869443],[-56.1511044,-34.8863894]]}', 14, 7, 1),
    ('osm-4dde1891b6ff007020fe', 'República Dominicana — tramo 3', '{"type":"LineString","coordinates":[[-56.1511044,-34.8863894],[-56.1499157,-34.8858363],[-56.1498076,-34.8857854]]}', 16, 14, 1),
    ('osm-6784ebba607b1800a629', 'República del Salvador — tramo 1', '{"type":"LineString","coordinates":[[-56.1489795,-34.8925427],[-56.1479601,-34.8921515]]}', 11, 4, 1),
    ('osm-cbb1cb845317f37991ee', 'República del Salvador — tramo 2', '{"type":"LineString","coordinates":[[-56.1479601,-34.8921515],[-56.1469252,-34.8917542]]}', 11, 4, 1),
    ('osm-a1aa707423a746604ea8', 'República del Salvador — tramo 3', '{"type":"LineString","coordinates":[[-56.1469252,-34.8917542],[-56.1460875,-34.8914329],[-56.1460095,-34.8914001]]}', 10, 6, 1),
    ('osm-d342ddb39203dfe2a95a', 'Santiago Gadea — tramo 1', '{"type":"LineString","coordinates":[[-56.1496027,-34.8944507],[-56.1495202,-34.8943783]]}', 0, 0, 1),
    ('osm-766b02f99f2979ebd349', 'Santiago Gadea — tramo 2', '{"type":"LineString","coordinates":[[-56.1495202,-34.8943783],[-56.1493891,-34.894307],[-56.1484054,-34.8938566]]}', 13, 1, 1),
    ('osm-5ba14d90f34194682318', 'Santiago Gadea — tramo 3', '{"type":"LineString","coordinates":[[-56.1484054,-34.8938566],[-56.1482948,-34.8938061],[-56.1472445,-34.89333]]}', 14, 1, 1),
    ('osm-ff0d9b6f93acfe5be623', 'Santiago Gadea — tramo 4', '{"type":"LineString","coordinates":[[-56.1472445,-34.89333],[-56.1461899,-34.8928381]]}', 12, 1, 1),
    ('osm-b25223f89abe11e7ba84', 'Santiago Gadea — tramo 5', '{"type":"LineString","coordinates":[[-56.1461899,-34.8928381],[-56.1453225,-34.892442]]}', 10, 0, 1),
    ('osm-6cd93be0b1f7a01f819b', 'Senda Alfredo Olivera — tramo 1', '{"type":"LineString","coordinates":[[-56.1569107,-34.8949026],[-56.1567785,-34.8948521],[-56.1565899,-34.8948327],[-56.1564817,-34.8948455],[-56.1561499,-34.8948522],[-56.1560884,-34.8948428],[-56.1560454,-34.894838],[-56.1558646,-34.8947871],[-56.1554612,-34.89464],[-56.154998,-34.894448],[-56.1547743,-34.8944416],[-56.154626,-34.8944332],[-56.1544752,-34.8944144]]}', 0, 0, 1),
    ('osm-93c14d9883c812be5a48', 'Senda Juan Jacinto López Testa — tramo 1', '{"type":"LineString","coordinates":[[-56.1556638,-34.8954059],[-56.1555876,-34.8955887],[-56.1555518,-34.8956776],[-56.1555323,-34.895912],[-56.1555086,-34.896029],[-56.1554428,-34.8961728],[-56.1553772,-34.8962986],[-56.1552252,-34.8965089]]}', 0, 0, 1),
    ('osm-df4887da50765f42b94b', 'Senda Leandro Gómez Harley — tramo 1', '{"type":"LineString","coordinates":[[-56.156107,-34.8966584],[-56.1561414,-34.8965519],[-56.1561323,-34.8965183],[-56.1561144,-34.8964525],[-56.1560553,-34.8962763],[-56.1560047,-34.896073],[-56.1559841,-34.8959512],[-56.1559769,-34.8957798]]}', 0, 0, 1),
    ('osm-ee9aac9e921ee458ea09', 'Senda Virgilio Pereyra — tramo 1', '{"type":"LineString","coordinates":[[-56.154043,-34.8964864],[-56.1540179,-34.8963866]]}', 0, 0, 1),
    ('osm-e67a57e578283001b0b2', 'Sendero Peatonal Profesor Alberto Langlade — tramo 1', '{"type":"LineString","coordinates":[[-56.1577485,-34.8968595],[-56.1574597,-34.8968],[-56.1571182,-34.8967571],[-56.1570316,-34.8967294],[-56.1569446,-34.8966747],[-56.1568442,-34.8965929],[-56.1567785,-34.8965248],[-56.1567238,-34.8964613],[-56.1566479,-34.8963841],[-56.1566029,-34.8963071],[-56.1565588,-34.8962076],[-56.1565111,-34.8960495],[-56.1564776,-34.8959185],[-56.1564618,-34.8957922],[-56.1564594,-34.8956885],[-56.1564851,-34.8955218],[-56.1565174,-34.8954319],[-56.1565609,-34.8953285],[-56.1566605,-34.8951578],[-56.156738,-34.8950637],[-56.156812,-34.8949876],[-56.1569107,-34.8949026]]}', 0, 0, 1),
    ('osm-689de48b1ee73325846c', 'Sendero Peatonal Profesor Alberto Langlade — tramo 2', '{"type":"LineString","coordinates":[[-56.1570232,-34.8947997],[-56.1569107,-34.8949026]]}', 0, 0, 1),
    ('osm-c00728d53fd6a9af23f7', 'Talcahuano — tramo 1', '{"type":"LineString","coordinates":[[-56.1487623,-34.8950468],[-56.1486616,-34.8949928]]}', 0, 0, 1),
    ('osm-9427c9c62b4bf45247ac', 'Talcahuano — tramo 2', '{"type":"LineString","coordinates":[[-56.1486616,-34.8949928],[-56.1480087,-34.8947091],[-56.1479203,-34.8946686]]}', 8, 1, 1),
    ('osm-2c30a4c30f30f4bbc26d', 'Talcahuano — tramo 3', '{"type":"LineString","coordinates":[[-56.1479203,-34.8946686],[-56.1467821,-34.8941421]]}', 14, 0, 1),
    ('osm-2e68d1ee6993506b4acb', 'Talcahuano — tramo 4', '{"type":"LineString","coordinates":[[-56.1467821,-34.8941421],[-56.1456733,-34.8936228]]}', 13, 11, 1),
    ('osm-691ab62afcfd8a9278ff', 'Talcahuano — tramo 5', '{"type":"LineString","coordinates":[[-56.1456733,-34.8936228],[-56.1448502,-34.8932446],[-56.1448078,-34.8932263]]}', 10, 9, 1),
    ('osm-4583aa51d0f166107c52', 'Teniente Juan S Walcalde — tramo 1', '{"type":"LineString","coordinates":[[-56.1643104,-34.8881502],[-56.1633524,-34.8866318]]}', 23, 2, 1),
    ('osm-61ede76ed0be0ef31ee2', 'Tuyutí — tramo 1', '{"type":"LineString","coordinates":[[-56.156163,-34.8909716],[-56.1554216,-34.8897524]]}', 18, 6, 1),
    ('osm-0160f6fd76527f6605c6', 'Tuyutí — tramo 2', '{"type":"LineString","coordinates":[[-56.1554216,-34.8897524],[-56.1545176,-34.8882906]]}', 22, 12, 1),
    ('osm-84bffb2af786358264c2', 'Vehicular/ Peatonal — tramo 1', '{"type":"LineString","coordinates":[[-56.1534544,-34.8909407],[-56.153437,-34.8909892],[-56.153404,-34.8910669],[-56.1533339,-34.8911716],[-56.1532242,-34.8913311],[-56.1531267,-34.8914361],[-56.1530182,-34.8915059],[-56.1528946,-34.8915456],[-56.1527716,-34.8915549],[-56.152604,-34.8915024],[-56.1519329,-34.8912584],[-56.1516422,-34.8911862],[-56.1512919,-34.8911367]]}', 0, 0, 1),
    ('osm-aab5a10e124bf0bccd9e', 'Vehicular/ Peatonal — tramo 2', '{"type":"LineString","coordinates":[[-56.1531124,-34.8925102],[-56.1528469,-34.8921671],[-56.1527693,-34.8920694],[-56.152717,-34.8920088],[-56.1525098,-34.8918801],[-56.152214,-34.8918299],[-56.1520102,-34.8917871]]}', 0, 0, 1),
    ('osm-4525c1b5a45d85927100', 'Vehicular/ Peatonal — tramo 3', '{"type":"LineString","coordinates":[[-56.1518518,-34.8905278],[-56.1517742,-34.8906276],[-56.1517073,-34.8908495],[-56.1516325,-34.890891],[-56.1515548,-34.8909208],[-56.1514772,-34.8909473],[-56.1514239,-34.890976],[-56.1513443,-34.8910575],[-56.1513069,-34.8911016],[-56.1512919,-34.8911367]]}', 0, 0, 1),
    ('osm-230799c9ae8b5acc669d', 'Vehicular/ Peatonal — tramo 4', '{"type":"LineString","coordinates":[[-56.1512919,-34.8911367],[-56.1511953,-34.8911283],[-56.1510075,-34.891106],[-56.150939,-34.8911128],[-56.1508527,-34.8911463]]}', 0, 0, 1),
    ('osm-90e9bebff7f8e1852976', 'Vehicular/ Peatonal — tramo 5', '{"type":"LineString","coordinates":[[-56.1509835,-34.8935899],[-56.1508106,-34.8930032]]}', 0, 0, 1),
    ('osm-00112dd3103a0502e6d4', 'Vehicular/ Peatonal — tramo 6', '{"type":"LineString","coordinates":[[-56.1508106,-34.8930032],[-56.1508067,-34.8930206],[-56.1505216,-34.8930764]]}', 0, 0, 1),
    ('osm-ede79a96a99de514ffb5', 'Vehicular/ Peatonal — tramo 7', '{"type":"LineString","coordinates":[[-56.1508106,-34.8930032],[-56.1508602,-34.8929625],[-56.150887,-34.8929218],[-56.1509219,-34.8928431],[-56.1509266,-34.8927788],[-56.1508941,-34.8927326],[-56.1508441,-34.8926825],[-56.150759,-34.8926185],[-56.1506814,-34.8925962],[-56.1505459,-34.8925676],[-56.1504382,-34.8925852],[-56.1501189,-34.8926261],[-56.1496819,-34.8926613],[-56.1495365,-34.892709],[-56.1494447,-34.8927625],[-56.1493582,-34.8928304],[-56.1492693,-34.8928886],[-56.1491645,-34.8929211]]}', 0, 0, 1),
    ('osm-7f0d1a32eb3d698bce55', 'Vehicular/ Peatonal — tramo 8', '{"type":"LineString","coordinates":[[-56.1507067,-34.8937173],[-56.1505216,-34.8930764]]}', 0, 0, 1),
    ('osm-54e8c5450361d5068ec0', 'Vehicular/ Peatonal — tramo 9', '{"type":"LineString","coordinates":[[-56.1505216,-34.8930764],[-56.1500893,-34.8931669],[-56.1499986,-34.8931198]]}', 0, 0, 1);
-- Prohibiciones verificadas por codigo_osm. El color gris no depende de capacidad ni ocupación.
UPDATE tramos_calle
SET permite_estacionar = 0
WHERE codigo_osm IN (    'osm-5921be6f74ec618615a0', -- Avelino Miranda — tramo 2
    'osm-39f47facddafbc9630ee', -- Avelino Miranda — tramo 4
    'osm-7a1f680ac004e6f4b27d', -- Avelino Miranda — tramo 6
    'osm-436509617c6088baa445', -- Avenida 8 de Octubre — tramo 1
    'osm-51a566add5b7a1e4617f', -- Avenida 8 de Octubre — tramo 10
    'osm-31d799bfd482f8399a94', -- Avenida 8 de Octubre — tramo 11
    'osm-717158a0b40d89e4521d', -- Avenida 8 de Octubre — tramo 12
    'osm-6e3e8a6992a2d068851d', -- Avenida 8 de Octubre — tramo 13
    'osm-f3dac839ef6990e202b4', -- Avenida 8 de Octubre — tramo 14
    'osm-187f7c239c85a3ee7995', -- Avenida 8 de Octubre — tramo 15
    'osm-3969bf7179535c72d612', -- Avenida 8 de Octubre — tramo 16
    'osm-b7d7f1d5d0e2e45a29d8', -- Avenida 8 de Octubre — tramo 17
    'osm-90ee20e7487f94b99279', -- Avenida 8 de Octubre — tramo 18
    'osm-92645fe61cd27ee32640', -- Avenida 8 de Octubre — tramo 19
    'osm-e392b86f19f1e0ad4997', -- Avenida 8 de Octubre — tramo 2
    'osm-c84534da8f429d8c2b3f', -- Avenida 8 de Octubre — tramo 3
    'osm-2454188ca1415cca6772', -- Avenida 8 de Octubre — tramo 4
    'osm-de95200ea11600114642', -- Avenida 8 de Octubre — tramo 5
    'osm-a81fd307a6eb49dd1034', -- Avenida 8 de Octubre — tramo 6
    'osm-b5ac567704fbf06632cc', -- Avenida 8 de Octubre — tramo 7
    'osm-824cffb6f0f9d4770164', -- Avenida 8 de Octubre — tramo 8
    'osm-8513af8402b6d5f8d8ed', -- Avenida 8 de Octubre — tramo 9
    'osm-aa041fe3ec36257fd1ec', -- Avenida Cataluña — tramo 4
    'osm-96f23d1491fb2f05f5e6', -- Avenida Doctor Alfredo Navarro — tramo 2
    'osm-8549af9a49c471b4c8f9', -- Avenida Doctor Américo Ricaldoni — tramo 11
    'osm-53013e4cab2766944191', -- Avenida Doctor Américo Ricaldoni — tramo 12
    'osm-8bd38be2b6433be71d74', -- Avenida Doctor Américo Ricaldoni — tramo 16
    'osm-6a16ae5cfb75de4f0138', -- Avenida Doctor Américo Ricaldoni — tramo 20
    'osm-4f74170a072a97b7ab79', -- Avenida Doctor Américo Ricaldoni — tramo 21
    'osm-a4ae326393ccfa13528a', -- Avenida Doctor Américo Ricaldoni — tramo 3
    'osm-83407519222c078513d8', -- Avenida Doctor Américo Ricaldoni — tramo 31
    'osm-7fbaf6b6e454cb3ab4a9', -- Avenida Doctor Américo Ricaldoni — tramo 4
    'osm-c3439e37a8a3553cc006', -- Avenida Doctor Américo Ricaldoni — tramo 6
    'osm-bf968a195ca81eca1971', -- Avenida Doctor Américo Ricaldoni — tramo 8
    'osm-afd73a551b7685d4a845', -- Avenida Doctor Lorenzo Merola — tramo 2
    'osm-0492c9ba6afe396ff373', -- Avenida Doctor Luis Morquio — tramo 4
    'osm-51498e6cd5120280bcbe', -- Avenida Doctor Luis Morquio — tramo 5
    'osm-9c53947d10c3889b746f', -- Avenida Doctor Manuel Albo — tramo 1
    'osm-fa05759a9bcb38d3df4f', -- Avenida Doctor Manuel Albo — tramo 10
    'osm-03c686c5c85d84422ad4', -- Avenida Doctor Manuel Albo — tramo 11
    'osm-5db628cdc9f6385581cf', -- Avenida Doctor Manuel Albo — tramo 12
    'osm-7e0673d4c620af3ce808', -- Avenida Doctor Manuel Albo — tramo 2
    'osm-6e51654e604a6d429d93', -- Avenida Doctor Manuel Albo — tramo 3
    'osm-e35f67efed3906026f39', -- Avenida Doctor Manuel Albo — tramo 4
    'osm-cc6cdc21eadeed0ed27e', -- Avenida Doctor Manuel Albo — tramo 5
    'osm-0108a07905f338608bdc', -- Avenida Doctor Manuel Albo — tramo 6
    'osm-68789c065656d616028c', -- Avenida Doctor Manuel Albo — tramo 7
    'osm-3bb3dd3ea09ed5c6d616', -- Avenida Doctor Manuel Albo — tramo 8
    'osm-2bbf69f0852bd22cca9d', -- Avenida Doctor Manuel Albo — tramo 9
    'osm-5adae501cc7ce87e9df2', -- Avenida Federico R. Vidiella — tramo 5
    'osm-c2e69545bb740f0f775d', -- Avenida General José Garibaldi — tramo 1
    'osm-3d9dc9b28931c248ef4a', -- Avenida General José Garibaldi — tramo 10
    'osm-845b9245a90a7d896a2a', -- Avenida General José Garibaldi — tramo 11
    'osm-4d1b83ef97e7d99c2df6', -- Avenida General José Garibaldi — tramo 12
    'osm-5468c19d20c1c47735f8', -- Avenida General José Garibaldi — tramo 13
    'osm-ecc806aa56975db6a041', -- Avenida General José Garibaldi — tramo 2
    'osm-572b94527170e68bb247', -- Avenida General José Garibaldi — tramo 3
    'osm-db13b9ab15a6e2c7117d', -- Avenida General José Garibaldi — tramo 4
    'osm-13c63e01908190456b60', -- Avenida General José Garibaldi — tramo 5
    'osm-dfd8f4d9ade04461750e', -- Avenida General José Garibaldi — tramo 6
    'osm-cbb54f378da953abf81d', -- Avenida General José Garibaldi — tramo 7
    'osm-6ea43798b67c0b4a4c42', -- Avenida General José Garibaldi — tramo 8
    'osm-02078026e43c9e713ebe', -- Avenida General José Garibaldi — tramo 9
    'osm-63affb39dc8c1524baa7', -- Avenida Italia — tramo 1
    'osm-6cadaf95cd494d0f39b4', -- Avenida Italia — tramo 10
    'osm-0e86bf31f76c9ee9ef8a', -- Avenida Italia — tramo 11
    'osm-f2eeb2f3fedf680beb3e', -- Avenida Italia — tramo 12
    'osm-23bb0d4f451975bb36df', -- Avenida Italia — tramo 13
    'osm-1b7e474dd1f89644492a', -- Avenida Italia — tramo 14
    'osm-86e7c9d81782b9c8e1c5', -- Avenida Italia — tramo 15
    'osm-39f7fc59951ac7b2562f', -- Avenida Italia — tramo 16
    'osm-971dd7be045f532a3a71', -- Avenida Italia — tramo 17
    'osm-12498ba9d28f8e80a13b', -- Avenida Italia — tramo 18
    'osm-8549518070a33da60051', -- Avenida Italia — tramo 19
    'osm-e230e83e4af90c617712', -- Avenida Italia — tramo 2
    'osm-0f5aa3bb93edb34f91ef', -- Avenida Italia — tramo 20
    'osm-035734746e13b2e67053', -- Avenida Italia — tramo 21
    'osm-7c6ede3f937f3bf06ea6', -- Avenida Italia — tramo 22
    'osm-20a154878e75a8f4e0c6', -- Avenida Italia — tramo 23
    'osm-7baf4fcaa4e58175699d', -- Avenida Italia — tramo 24
    'osm-eeefa8329d243e21a0d6', -- Avenida Italia — tramo 25
    'osm-20b6603295146ed09e7b', -- Avenida Italia — tramo 26
    'osm-78d28a5816a503290225', -- Avenida Italia — tramo 27
    'osm-923592fe2323851c9a8f', -- Avenida Italia — tramo 28
    'osm-dba64bf3b7f156c7aa79', -- Avenida Italia — tramo 29
    'osm-6c4c6768b4a4ed0511cd', -- Avenida Italia — tramo 3
    'osm-a5f073dc65cae6ddbdaa', -- Avenida Italia — tramo 30
    'osm-cc1e60a5b9676051df4d', -- Avenida Italia — tramo 31
    'osm-1528d01780b170e07a1f', -- Avenida Italia — tramo 32
    'osm-76cf8a892ec4033c49cd', -- Avenida Italia — tramo 33
    'osm-586502e86f962a9effd8', -- Avenida Italia — tramo 34
    'osm-070c231ba0efdf97a9e8', -- Avenida Italia — tramo 35
    'osm-4c7752658df05dac020c', -- Avenida Italia — tramo 36
    'osm-e34b314d78332f53803b', -- Avenida Italia — tramo 37
    'osm-f149078bfcdcc3be66b6', -- Avenida Italia — tramo 38
    'osm-d307515f65d680346128', -- Avenida Italia — tramo 39
    'osm-9130acde6804d44e2474', -- Avenida Italia — tramo 4
    'osm-e5bad8f11a1eb18e0f7d', -- Avenida Italia — tramo 5
    'osm-cd60500427c08908ff04', -- Avenida Italia — tramo 6
    'osm-c284d691eb4d4a919f04', -- Avenida Italia — tramo 7
    'osm-dde17e281c6d878d2e9d', -- Avenida Italia — tramo 8
    'osm-23a5c0446dc063114ff5', -- Avenida Italia — tramo 9
    'osm-294ce02ab99f4a4b8176', -- Avenida Ramón Anador — tramo 1
    'osm-aba334c0a77ac417451a', -- Avenida Ramón V. Benzano — tramo 11
    'osm-720e0f359b6ba89e1fde', -- Héctor Scarone — tramo 7
    'osm-e25b26c4e87069e2e716', -- Jorge Canning — tramo 4
    'osm-38c11bac03f672bdfa83', -- Juan Ramón Gómez — tramo 1
    'osm-8818c14f7d4786169cb3', -- Lord Ponsomby — tramo 1
    'osm-8ebbcd34ac19237e717d', -- Presidente Lorenzo Batlle — tramo 2
    'osm-d342ddb39203dfe2a95a', -- Santiago Gadea — tramo 1
    'osm-6cd93be0b1f7a01f819b', -- Senda Alfredo Olivera — tramo 1
    'osm-93c14d9883c812be5a48', -- Senda Juan Jacinto López Testa — tramo 1
    'osm-df4887da50765f42b94b', -- Senda Leandro Gómez Harley — tramo 1
    'osm-ee9aac9e921ee458ea09', -- Senda Virgilio Pereyra — tramo 1
    'osm-e67a57e578283001b0b2', -- Sendero Peatonal Profesor Alberto Langlade — tramo 1
    'osm-84bffb2af786358264c2', -- Vehicular/ Peatonal — tramo 1
    'osm-aab5a10e124bf0bccd9e', -- Vehicular/ Peatonal — tramo 2
    'osm-4525c1b5a45d85927100', -- Vehicular/ Peatonal — tramo 3
    'osm-90e9bebff7f8e1852976', -- Vehicular/ Peatonal — tramo 5
    'osm-00112dd3103a0502e6d4', -- Vehicular/ Peatonal — tramo 6
    'osm-ede79a96a99de514ffb5', -- Vehicular/ Peatonal — tramo 7
    'osm-7f0d1a32eb3d698bce55', -- Vehicular/ Peatonal — tramo 8
    'osm-c55f174c83e1740f6044', -- Avenida Doctor Américo Ricaldoni — tramo 7
    'osm-689de48b1ee73325846c', -- Sendero Peatonal Profesor Alberto Langlade — tramo 2
    'osm-c0c64c45e2191cd729de', -- Avenida Doctor Lorenzo Merola — tramo 5
    'osm-b36acf5ab91a0778d5d0', -- Avenida Doctor Américo Ricaldoni — tramo 9
    'osm-8a43851a0b66d5fd5dcc', -- Avenida Luis Alberto de Herrera — tramo 2
    'osm-08c638847056f8149387', -- Avenida Luis Alberto de Herrera — tramo 1
    'osm-926e7f75fe6d17088993', -- Federico Susviela Guarch — tramo 6
    'osm-63da7078b41fdee8eced', -- Doctor José Brito Foresti — tramo 6
    'osm-c57420f7164d771df41b', -- General Las Heras — tramo 1
    'osm-230799c9ae8b5acc669d', -- Vehicular/ Peatonal — tramo 4
    'osm-54e8c5450361d5068ec0', -- Vehicular/ Peatonal — tramo 9
    'osm-5453717e5d7f3f777afe', -- Avenida Doctor Alfredo Navarro — tramo 1
    'osm-ecec14dc425633a8e4ee', -- Avenida Doctor Alfredo Navarro — tramo 3
    'osm-1d11fb98a75c1644b70e', -- Avenida Doctor Alfredo Navarro — tramo 5
    'osm-90573409ee4067c64d2c', -- Avenida Federico R. Vidiella — tramo 12
    'osm-a84042944c21242705f6' -- Avenida Federico R. Vidiella — tramo 15
);

CREATE VIEW vista_disponibilidad_tramos AS
SELECT
    q.id_tramo,
    q.codigo_osm,
    q.nombre,
    q.geometria,
    q.permite_estacionar,
    q.capacidad_estimada,
    q.ocupacion_simulada,
    CASE WHEN q.permite_estacionar = 0 THEN NULL ELSE q.ocupacion_real END AS ocupacion_real,
    CASE WHEN q.permite_estacionar = 0 THEN NULL ELSE LEAST(q.capacidad_estimada, q.ocupacion_simulada + q.ocupacion_real) END AS total_ocupado,
    CASE WHEN q.permite_estacionar = 0 THEN NULL ELSE GREATEST(0, q.capacidad_estimada - q.ocupacion_simulada - q.ocupacion_real) END AS lugares_libres,
    CASE
        WHEN q.permite_estacionar = 0 THEN NULL
        WHEN q.capacidad_estimada = 0 THEN 0
        ELSE FLOOR(100 * GREATEST(0, q.capacidad_estimada - q.ocupacion_simulada - q.ocupacion_real) / q.capacidad_estimada)
    END AS porcentaje_disponibilidad,
    CASE
        WHEN q.permite_estacionar = 0 THEN 'Prohibido estacionar'
        WHEN q.capacidad_estimada = 0 THEN 'Rojo'
        WHEN FLOOR(100 * GREATEST(0, q.capacidad_estimada - q.ocupacion_simulada - q.ocupacion_real) / q.capacidad_estimada) >= 75 THEN 'Verde'
        WHEN FLOOR(100 * GREATEST(0, q.capacidad_estimada - q.ocupacion_simulada - q.ocupacion_real) / q.capacidad_estimada) >= 25 THEN 'Amarillo'
        ELSE 'Rojo'
    END AS categoria
FROM (
    SELECT
        t.id_tramo,
        t.codigo_osm,
        t.nombre,
        t.geometria,
        t.permite_estacionar,
        t.capacidad_estimada,
        t.ocupacion_simulada,
        COUNT(o.id_ocupacion) AS ocupacion_real
    FROM tramos_calle t
    LEFT JOIN estacionamiento e ON e.id_tramo = t.id_tramo AND e.estado = 'Ocupado'
    LEFT JOIN ocupacion o ON o.id_estacionamiento = e.id_estacionamiento
    WHERE t.activo = 1
    GROUP BY t.id_tramo, t.codigo_osm, t.nombre, t.geometria, t.permite_estacionar, t.capacidad_estimada, t.ocupacion_simulada
) AS q;

-- Verificación: lista los 477 tramos y su estado de estacionamiento.
SELECT codigo_osm, nombre,
       IF(permite_estacionar = 0, 'PROHIBIDO', 'PERMITIDO') AS estacionamiento
FROM tramos_calle
WHERE activo = 1
ORDER BY nombre;

-- Resumen esperado: 138 prohibidos y 339 permitidos.
SELECT permite_estacionar, COUNT(*) AS cantidad
FROM tramos_calle
WHERE activo = 1
GROUP BY permite_estacionar
ORDER BY permite_estacionar;
