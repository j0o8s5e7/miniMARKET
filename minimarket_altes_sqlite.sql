PRAGMA foreign_keys = ON;

-- =============================================================================
-- ESQUEMA: Minimarket ALTES - Gestion Comercial e Inventario
-- =============================================================================

CREATE TABLE Cliente (
    cliente_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    nombres          VARCHAR(50) NOT NULL,
    apellidos        VARCHAR(50) NOT NULL,
    dni              VARCHAR(15) NOT NULL UNIQUE,
    telefono         VARCHAR(15),
    direccion        VARCHAR(100),
    fecha_registro   DATE NOT NULL,
    estado           BOOLEAN NOT NULL DEFAULT 1
);

CREATE TABLE Empleado (
    empleado_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    nombres          VARCHAR(50) NOT NULL,
    apellidos        VARCHAR(50) NOT NULL,
    dni              VARCHAR(15) NOT NULL UNIQUE,
    cargo            VARCHAR(50) NOT NULL,
    telefono         VARCHAR(15),
    fecha_ingreso    DATE NOT NULL,
    estado           BOOLEAN NOT NULL DEFAULT 1
);

CREATE TABLE Usuario (
    usuario_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    empleado_id      INTEGER NOT NULL UNIQUE,
    username         VARCHAR(30) NOT NULL UNIQUE,
    password         VARCHAR(255) NOT NULL,
    rol              VARCHAR(20) NOT NULL CHECK (rol IN ('administrador','cajero','almacenero')),
    estado           BOOLEAN NOT NULL DEFAULT 1,
    fecha_registro   DATETIME NOT NULL,
    FOREIGN KEY (empleado_id) REFERENCES Empleado(empleado_id)
);

CREATE TABLE Categoria (
    categoria_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre           VARCHAR(50) NOT NULL UNIQUE,
    descripcion      TEXT,
    estado           BOOLEAN NOT NULL DEFAULT 1
);

CREATE TABLE Producto (
    producto_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    categoria_id     INTEGER NOT NULL,
    codigo_barras    VARCHAR(30) NOT NULL UNIQUE,
    nombre           VARCHAR(100) NOT NULL,
    descripcion      TEXT,
    unidad_medida    VARCHAR(20) NOT NULL,
    precio_compra    DECIMAL(10,2) NOT NULL,
    precio_venta     DECIMAL(10,2) NOT NULL,
    estado           BOOLEAN NOT NULL DEFAULT 1,
    FOREIGN KEY (categoria_id) REFERENCES Categoria(categoria_id)
);

CREATE TABLE Proveedor (
    proveedor_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    razon_social     VARCHAR(100) NOT NULL,
    ruc              VARCHAR(20) NOT NULL UNIQUE,
    telefono         VARCHAR(15),
    email            VARCHAR(100),
    direccion        VARCHAR(100),
    contacto         VARCHAR(50),
    estado           BOOLEAN NOT NULL DEFAULT 1
);

CREATE TABLE Caja (
    caja_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    empleado_id      INTEGER NOT NULL,
    fecha_apertura   DATETIME NOT NULL,
    monto_apertura   DECIMAL(10,2) NOT NULL,
    fecha_cierre     DATETIME,
    monto_cierre     DECIMAL(10,2),
    estado           BOOLEAN NOT NULL DEFAULT 1,
    FOREIGN KEY (empleado_id) REFERENCES Empleado(empleado_id)
);

CREATE TABLE Compra (
    compra_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    proveedor_id     INTEGER NOT NULL,
    empleado_id      INTEGER NOT NULL,
    fecha_compra     DATETIME NOT NULL,
    tipo_pago        VARCHAR(20) NOT NULL,
    total            DECIMAL(10,2) NOT NULL,
    estado           BOOLEAN NOT NULL DEFAULT 1,
    FOREIGN KEY (proveedor_id) REFERENCES Proveedor(proveedor_id),
    FOREIGN KEY (empleado_id) REFERENCES Empleado(empleado_id)
);

CREATE TABLE Lote (
    lote_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id      INTEGER NOT NULL,
    numero_lote      VARCHAR(50) NOT NULL UNIQUE,
    fecha_ingreso    DATE NOT NULL,
    fecha_vencimiento DATE,
    cantidad         DECIMAL(10,2) NOT NULL,
    estado           BOOLEAN NOT NULL DEFAULT 1,
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id),
    CHECK (fecha_vencimiento IS NULL OR fecha_vencimiento > fecha_ingreso)
);

CREATE TABLE Detalle_Compra (
    detalle_compra_id INTEGER PRIMARY KEY AUTOINCREMENT,
    compra_id        INTEGER NOT NULL,
    producto_id      INTEGER NOT NULL,
    lote_id          INTEGER NOT NULL,
    cantidad         DECIMAL(10,2) NOT NULL,
    precio_unitario  DECIMAL(10,2) NOT NULL,
    subtotal         DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (compra_id) REFERENCES Compra(compra_id),
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id),
    FOREIGN KEY (lote_id) REFERENCES Lote(lote_id)
);

CREATE TABLE Inventario (
    inventario_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id      INTEGER NOT NULL UNIQUE,
    stock_actual     DECIMAL(10,2) NOT NULL,
    stock_minimo     DECIMAL(10,2) NOT NULL,
    stock_maximo     DECIMAL(10,2) NOT NULL,
    ubicacion        VARCHAR(50),
    fecha_actualizacion DATETIME NOT NULL,
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id)
);

CREATE TABLE Movimiento_Inventario (
    movimiento_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id      INTEGER NOT NULL,
    lote_id          INTEGER NOT NULL,
    empleado_id      INTEGER NOT NULL,
    tipo_movimiento  VARCHAR(20) NOT NULL CHECK (tipo_movimiento IN ('ingreso','salida','ajuste','merma')),
    cantidad         DECIMAL(10,2) NOT NULL,
    fecha_movimiento DATETIME NOT NULL,
    motivo           VARCHAR(100),
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id),
    FOREIGN KEY (lote_id) REFERENCES Lote(lote_id),
    FOREIGN KEY (empleado_id) REFERENCES Empleado(empleado_id)
);

CREATE TABLE Venta (
    venta_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id       INTEGER,
    empleado_id      INTEGER NOT NULL,
    caja_id          INTEGER NOT NULL,
    fecha_venta      DATETIME NOT NULL,
    tipo_comprobante VARCHAR(20) NOT NULL,
    subtotal         DECIMAL(10,2) NOT NULL,
    igv              DECIMAL(10,2) NOT NULL,
    total            DECIMAL(10,2) NOT NULL,
    estado           BOOLEAN NOT NULL DEFAULT 1,
    FOREIGN KEY (cliente_id) REFERENCES Cliente(cliente_id),
    FOREIGN KEY (empleado_id) REFERENCES Empleado(empleado_id),
    FOREIGN KEY (caja_id) REFERENCES Caja(caja_id)
);

CREATE TABLE Detalle_Venta (
    detalle_venta_id INTEGER PRIMARY KEY AUTOINCREMENT,
    venta_id         INTEGER NOT NULL,
    producto_id      INTEGER NOT NULL,
    lote_id          INTEGER NOT NULL,
    cantidad         DECIMAL(10,2) NOT NULL,
    precio_unitario  DECIMAL(10,2) NOT NULL,
    descuento        DECIMAL(10,2) NOT NULL DEFAULT 0,
    subtotal         DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (venta_id) REFERENCES Venta(venta_id),
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id),
    FOREIGN KEY (lote_id) REFERENCES Lote(lote_id)
);

CREATE TABLE Pago (
    pago_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    venta_id         INTEGER NOT NULL,
    metodo_pago      VARCHAR(20) NOT NULL,
    monto            DECIMAL(10,2) NOT NULL,
    fecha_pago       DATETIME NOT NULL,
    referencia       VARCHAR(50),
    FOREIGN KEY (venta_id) REFERENCES Venta(venta_id)
);

-- =============================================================================
-- DATOS DE PRUEBA
-- =============================================================================

-- Categoria
INSERT INTO Categoria (categoria_id, nombre, descripcion, estado) VALUES (1, 'Abarrotes', 'Productos envasados y de consumo basico no perecible', 1);
INSERT INTO Categoria (categoria_id, nombre, descripcion, estado) VALUES (2, 'Bebidas', 'Gaseosas, jugos, agua y otras bebidas', 1);
INSERT INTO Categoria (categoria_id, nombre, descripcion, estado) VALUES (3, 'Limpieza', 'Productos de limpieza para el hogar', 1);
INSERT INTO Categoria (categoria_id, nombre, descripcion, estado) VALUES (4, 'Helados', 'Helados y productos refrigerados', 1);
INSERT INTO Categoria (categoria_id, nombre, descripcion, estado) VALUES (5, 'Articulos varios', 'Articulos de uso cotidiano', 1);

-- Proveedor
INSERT INTO Proveedor (proveedor_id, razon_social, ruc, telefono, email, direccion, contacto, estado) VALUES (1, 'Distribuidora San Fernando S.A.C.', '20456789011', '014567890', 'ventas@sanfernando.pe', 'Av. Argentina 1200, Lima', 'Carlos Ruiz', 1);
INSERT INTO Proveedor (proveedor_id, razon_social, ruc, telefono, email, direccion, contacto, estado) VALUES (2, 'Alicorp Distribuciones S.A.', '20100055237', '016123456', 'pedidos@alicorp.pe', 'Av. Argentina 4793, Lima', 'Maria Soto', 1);
INSERT INTO Proveedor (proveedor_id, razon_social, ruc, telefono, email, direccion, contacto, estado) VALUES (3, 'Backus y Distribuidores Asociados', '20100113610', '016543210', 'contacto@backus.pe', 'Av. Nicolas Ayllon 3986, Ate', 'Jorge Paredes', 1);
INSERT INTO Proveedor (proveedor_id, razon_social, ruc, telefono, email, direccion, contacto, estado) VALUES (4, 'D''Onofrio Distribucion S.A.', '20100020295', '014321098', 'pedidos@donofrio.pe', 'Av. Colonial 150, Lima', 'Ana Vega', 1);
INSERT INTO Proveedor (proveedor_id, razon_social, ruc, telefono, email, direccion, contacto, estado) VALUES (5, 'Comercializadora Limpia Hogar E.I.R.L.', '20601234567', '017654321', 'ventas@limpiahogar.pe', 'Jr. Huanta 800, Lima', 'Luis Campos', 1);

-- Empleado
INSERT INTO Empleado (empleado_id, nombres, apellidos, dni, cargo, telefono, fecha_ingreso, estado) VALUES (1, 'Rosa', 'Altez Huaman', '45123456', 'administrador', '987111222', '2018-03-01', 1);
INSERT INTO Empleado (empleado_id, nombres, apellidos, dni, cargo, telefono, fecha_ingreso, estado) VALUES (2, 'Milagros', 'Flores Diaz', '48222333', 'cajero', '987222333', '2021-06-15', 1);
INSERT INTO Empleado (empleado_id, nombres, apellidos, dni, cargo, telefono, fecha_ingreso, estado) VALUES (3, 'Jhon', 'Quispe Rojas', '47333444', 'cajero', '987333444', '2022-01-10', 1);
INSERT INTO Empleado (empleado_id, nombres, apellidos, dni, cargo, telefono, fecha_ingreso, estado) VALUES (4, 'Pedro', 'Huaman Torres', '46444555', 'almacenero', '987444555', '2020-09-05', 1);
INSERT INTO Empleado (empleado_id, nombres, apellidos, dni, cargo, telefono, fecha_ingreso, estado) VALUES (5, 'Elena', 'Ramos Castillo', '49555666', 'almacenero', '987555666', '2023-02-20', 1);

-- Usuario (contrasena de ejemplo ya 'hasheada'; reemplazar por hash real en produccion)
INSERT INTO Usuario (usuario_id, empleado_id, username, password, rol, estado, fecha_registro) VALUES (1, 1, 'radmin', '$2y$10$hashDeEjemplo01', 'administrador', 1, '2026-01-05 08:00:00');
INSERT INTO Usuario (usuario_id, empleado_id, username, password, rol, estado, fecha_registro) VALUES (2, 2, 'mflores', '$2y$10$hashDeEjemplo02', 'cajero', 1, '2026-01-05 08:00:00');
INSERT INTO Usuario (usuario_id, empleado_id, username, password, rol, estado, fecha_registro) VALUES (3, 3, 'jquispe', '$2y$10$hashDeEjemplo03', 'cajero', 1, '2026-01-05 08:00:00');
INSERT INTO Usuario (usuario_id, empleado_id, username, password, rol, estado, fecha_registro) VALUES (4, 4, 'phuaman', '$2y$10$hashDeEjemplo04', 'almacenero', 1, '2026-01-05 08:00:00');
INSERT INTO Usuario (usuario_id, empleado_id, username, password, rol, estado, fecha_registro) VALUES (5, 5, 'eramos', '$2y$10$hashDeEjemplo05', 'almacenero', 1, '2026-01-05 08:00:00');

-- Cliente
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (1, 'Maria', 'Lopez Garcia', '10111222', '911111111', 'Jr. Los Olivos 123, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (2, 'Juan', 'Perez Rivas', '10222333', '911222222', 'Av. Los Pinos 456, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (3, 'Sofia', 'Torres Nina', '10333444', '911333333', 'Calle Las Rosas 789, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (4, 'Diego', 'Ramirez Leon', '10444555', '911444444', 'Jr. Las Flores 321, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (5, 'Carla', 'Gomez Vera', '10555666', '911555555', 'Av. Primavera 654, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (6, 'Andres', 'Salazar Diaz', '10666777', '911666666', 'Jr. San Martin 111, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (7, 'Lucia', 'Mendoza Ruiz', '10777888', '911777777', 'Calle Las Palmeras 222, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (8, 'Miguel', 'Castro Vega', '10888999', '911888888', 'Av. Los Alamos 333, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (9, 'Paula', 'Herrera Soto', '10999000', '911999999', 'Jr. Union 444, Lima', '2026-01-15', 1);
INSERT INTO Cliente (cliente_id, nombres, apellidos, dni, telefono, direccion, fecha_registro, estado) VALUES (10, 'Renato', 'Vargas Cruz', '10000111', '911000000', 'Av. La Marina 555, Lima', '2026-01-15', 1);

-- Producto (50 productos)
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (1, 1, '7750100000001', 'Arroz Extra Costeno 1kg', 'Arroz Extra Costeno 1kg', 'unidad', 3.20, 4.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (2, 1, '7750100000002', 'Azucar Rubia Cartavio 1kg', 'Azucar Rubia Cartavio 1kg', 'unidad', 3.00, 4.20, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (3, 1, '7750100000003', 'Aceite Vegetal Primor 1L', 'Aceite Vegetal Primor 1L', 'unidad', 8.50, 11.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (4, 1, '7750100000004', 'Fideos Spaghetti Don Vittorio 500g', 'Fideos Spaghetti Don Vittorio 500g', 'unidad', 2.80, 3.90, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (5, 1, '7750100000005', 'Atun Florida en Aceite 170g', 'Atun Florida en Aceite 170g', 'unidad', 4.50, 6.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (6, 1, '7750100000006', 'Menestra Frijol Canario 500g', 'Menestra Frijol Canario 500g', 'unidad', 3.50, 4.80, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (7, 1, '7750100000007', 'Cafe Altomayo Instantaneo 100g', 'Cafe Altomayo Instantaneo 100g', 'unidad', 9.00, 12.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (8, 1, '7750100000008', 'Galletas Soda Field Pack x6', 'Galletas Soda Field Pack x6', 'unidad', 3.20, 4.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (9, 1, '7750100000009', 'Harina Blanca Anita 1kg', 'Harina Blanca Anita 1kg', 'unidad', 3.80, 5.20, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (10, 1, '7750100000010', 'Sal de Mesa Marina 1kg', 'Sal de Mesa Marina 1kg', 'unidad', 1.50, 2.20, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (11, 1, '7750100000011', 'Leche Evaporada Gloria 400g', 'Leche Evaporada Gloria 400g', 'unidad', 3.60, 4.80, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (12, 1, '7750100000012', 'Avena Quaker 400g', 'Avena Quaker 400g', 'unidad', 5.50, 7.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (13, 2, '7750100000013', 'Gaseosa Inca Kola 1.5L', 'Gaseosa Inca Kola 1.5L', 'unidad', 4.50, 6.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (14, 2, '7750100000014', 'Gaseosa Coca Cola 1.5L', 'Gaseosa Coca Cola 1.5L', 'unidad', 4.80, 6.80, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (15, 2, '7750100000015', 'Agua San Luis 625ml', 'Agua San Luis 625ml', 'unidad', 1.20, 2.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (16, 2, '7750100000016', 'Jugo Frugos Naranja 1L', 'Jugo Frugos Naranja 1L', 'unidad', 4.00, 5.80, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (17, 2, '7750100000017', 'Cerveza Pilsen Callao 630ml', 'Cerveza Pilsen Callao 630ml', 'unidad', 5.50, 7.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (18, 2, '7750100000018', 'Gatorade Sabor Uva 500ml', 'Gatorade Sabor Uva 500ml', 'unidad', 3.20, 4.80, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (19, 2, '7750100000019', 'Cifrut Naranja 300ml', 'Cifrut Naranja 300ml', 'unidad', 1.30, 2.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (20, 2, '7750100000020', 'Te Helado San Carlos 500ml', 'Te Helado San Carlos 500ml', 'unidad', 2.50, 3.80, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (21, 2, '7750100000021', 'Agua con Gas Socosani 500ml', 'Agua con Gas Socosani 500ml', 'unidad', 2.20, 3.20, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (22, 2, '7750100000022', 'Energizante Volt 473ml', 'Energizante Volt 473ml', 'unidad', 4.50, 6.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (23, 3, '7750100000023', 'Detergente Ariel 900g', 'Detergente Ariel 900g', 'unidad', 9.50, 13.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (24, 3, '7750100000024', 'Lejia Clorox 1L', 'Lejia Clorox 1L', 'unidad', 3.50, 5.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (25, 3, '7750100000025', 'Jabon de Lavar Bolivar x5', 'Jabon de Lavar Bolivar x5', 'unidad', 6.00, 8.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (26, 3, '7750100000026', 'Limpiavidrios Sapolio 500ml', 'Limpiavidrios Sapolio 500ml', 'unidad', 4.20, 6.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (27, 3, '7750100000027', 'Desinfectante Sapolio 900ml', 'Desinfectante Sapolio 900ml', 'unidad', 6.50, 9.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (28, 3, '7750100000028', 'Escoba de Paja', 'Escoba de Paja', 'unidad', 7.00, 11.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (29, 3, '7750100000029', 'Trapeador Microfibra', 'Trapeador Microfibra', 'unidad', 10.00, 15.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (30, 3, '7750100000030', 'Esponja de Cocina x3', 'Esponja de Cocina x3', 'unidad', 2.00, 3.20, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (31, 3, '7750100000031', 'Bolsas de Basura Renova x10', 'Bolsas de Basura Renova x10', 'unidad', 3.80, 5.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (32, 3, '7750100000032', 'Papel Toalla Elite x2', 'Papel Toalla Elite x2', 'unidad', 5.00, 7.20, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (33, 4, '7750100000033', 'Helado D''Onofrio Vainilla 1L', 'Helado D''Onofrio Vainilla 1L', 'unidad', 8.00, 11.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (34, 4, '7750100000034', 'Helado D''Onofrio Chocolate 1L', 'Helado D''Onofrio Chocolate 1L', 'unidad', 8.00, 11.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (35, 4, '7750100000035', 'Paleta Frozen Fresa', 'Paleta Frozen Fresa', 'unidad', 1.50, 2.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (36, 4, '7750100000036', 'Cono Drumstick Vainilla', 'Cono Drumstick Vainilla', 'unidad', 2.20, 3.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (37, 4, '7750100000037', 'Helado Magnum Almendras', 'Helado Magnum Almendras', 'unidad', 4.00, 6.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (38, 4, '7750100000038', 'Picoteli Chocolate', 'Picoteli Chocolate', 'unidad', 1.00, 1.80, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (39, 4, '7750100000039', 'Helado Lucuma Familiar 1L', 'Helado Lucuma Familiar 1L', 'unidad', 8.20, 11.80, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (40, 5, '7750100000040', 'Papel Higienico Suave x4', 'Papel Higienico Suave x4', 'unidad', 6.50, 9.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (41, 5, '7750100000041', 'Pasta Dental Colgate 90g', 'Pasta Dental Colgate 90g', 'unidad', 4.50, 6.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (42, 5, '7750100000042', 'Shampoo Sedal 400ml', 'Shampoo Sedal 400ml', 'unidad', 8.00, 11.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (43, 5, '7750100000043', 'Jabon de Tocador Protex', 'Jabon de Tocador Protex', 'unidad', 2.20, 3.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (44, 5, '7750100000044', 'Pilas AA Duracell x2', 'Pilas AA Duracell x2', 'unidad', 5.50, 8.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (45, 5, '7750100000045', 'Fosforos Llama x10 cajas', 'Fosforos Llama x10 cajas', 'unidad', 2.00, 3.20, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (46, 5, '7750100000046', 'Desodorante Rexona 150ml', 'Desodorante Rexona 150ml', 'unidad', 9.00, 13.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (47, 5, '7750100000047', 'Cuaderno Universitario 100h', 'Cuaderno Universitario 100h', 'unidad', 4.00, 6.00, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (48, 5, '7750100000048', 'Lapicero Faber Castell', 'Lapicero Faber Castell', 'unidad', 0.80, 1.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (49, 5, '7750100000049', 'Vela Blanca Grande', 'Vela Blanca Grande', 'unidad', 1.50, 2.50, 1);
INSERT INTO Producto (producto_id, categoria_id, codigo_barras, nombre, descripcion, unidad_medida, precio_compra, precio_venta, estado) VALUES (50, 5, '7750100000050', 'Encendedor Bic', 'Encendedor Bic', 'unidad', 2.00, 3.50, 1);

-- Lote (un lote de ingreso por producto)
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (1, 1, 'L-0001', '2026-09-01', '2027-09-01', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (2, 2, 'L-0002', '2026-09-01', '2028-02-23', 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (3, 3, 'L-0003', '2026-09-01', '2027-09-01', 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (4, 4, 'L-0004', '2026-09-01', '2027-09-01', 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (5, 5, 'L-0005', '2026-09-01', '2028-08-31', 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (6, 6, 'L-0006', '2026-09-01', '2027-09-01', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (7, 7, 'L-0007', '2026-09-01', '2028-02-23', 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (8, 8, 'L-0008', '2026-09-01', '2027-02-28', 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (9, 9, 'L-0009', '2026-09-01', '2027-09-01', 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (10, 10, 'L-0010', '2026-09-01', '2028-08-31', 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (11, 11, 'L-0011', '2026-09-01', '2027-09-01', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (12, 12, 'L-0012', '2026-09-01', '2027-09-01', 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (13, 13, 'L-0013', '2026-09-01', '2027-02-28', 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (14, 14, 'L-0014', '2026-09-01', '2027-02-28', 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (15, 15, 'L-0015', '2026-09-01', '2027-09-01', 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (16, 16, 'L-0016', '2026-09-01', '2027-02-28', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (17, 17, 'L-0017', '2026-09-01', '2027-05-29', 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (18, 18, 'L-0018', '2026-09-01', '2027-05-29', 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (19, 19, 'L-0019', '2026-09-01', '2027-02-28', 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (20, 20, 'L-0020', '2026-09-01', '2027-02-28', 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (21, 21, 'L-0021', '2026-09-01', '2027-09-01', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (22, 22, 'L-0022', '2026-09-01', '2027-05-29', 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (23, 23, 'L-0023', '2026-09-01', '2028-08-31', 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (24, 24, 'L-0024', '2026-09-01', '2028-08-31', 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (25, 25, 'L-0025', '2026-09-01', '2028-08-31', 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (26, 26, 'L-0026', '2026-09-01', '2028-08-31', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (27, 27, 'L-0027', '2026-09-01', '2028-08-31', 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (28, 28, 'L-0028', '2026-09-01', NULL, 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (29, 29, 'L-0029', '2026-09-01', NULL, 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (30, 30, 'L-0030', '2026-09-01', NULL, 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (31, 31, 'L-0031', '2026-09-01', NULL, 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (32, 32, 'L-0032', '2026-09-01', NULL, 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (33, 33, 'L-0033', '2026-09-01', '2027-02-28', 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (34, 34, 'L-0034', '2026-09-01', '2027-02-28', 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (35, 35, 'L-0035', '2026-09-01', '2026-11-30', 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (36, 36, 'L-0036', '2026-09-01', '2026-11-30', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (37, 37, 'L-0037', '2026-09-01', '2026-11-30', 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (38, 38, 'L-0038', '2026-09-01', '2026-11-30', 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (39, 39, 'L-0039', '2026-09-01', '2027-02-28', 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (40, 40, 'L-0040', '2026-09-01', NULL, 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (41, 41, 'L-0041', '2026-09-01', '2028-08-31', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (42, 42, 'L-0042', '2026-09-01', '2028-02-23', 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (43, 43, 'L-0043', '2026-09-01', '2028-08-31', 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (44, 44, 'L-0044', '2026-09-01', '2029-08-31', 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (45, 45, 'L-0045', '2026-09-01', NULL, 40.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (46, 46, 'L-0046', '2026-09-01', '2028-02-23', 50.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (47, 47, 'L-0047', '2026-09-01', NULL, 60.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (48, 48, 'L-0048', '2026-09-01', NULL, 70.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (49, 49, 'L-0049', '2026-09-01', NULL, 80.00, 1);
INSERT INTO Lote (lote_id, producto_id, numero_lote, fecha_ingreso, fecha_vencimiento, cantidad, estado) VALUES (50, 50, 'L-0050', '2026-09-01', NULL, 40.00, 1);

-- Inventario (stock inicial = cantidad del lote de ingreso)
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (1, 1, 50.00, 10, 90.00, 'Anaquel 1', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (2, 2, 60.00, 10, 100.00, 'Anaquel 2', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (3, 3, 70.00, 10, 110.00, 'Anaquel 3', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (4, 4, 80.00, 10, 120.00, 'Anaquel 4', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (5, 5, 40.00, 10, 80.00, 'Anaquel 5', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (6, 6, 50.00, 10, 90.00, 'Anaquel 6', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (7, 7, 60.00, 10, 100.00, 'Anaquel 7', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (8, 8, 70.00, 10, 110.00, 'Anaquel 8', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (9, 9, 80.00, 10, 120.00, 'Anaquel 9', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (10, 10, 40.00, 10, 80.00, 'Anaquel 10', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (11, 11, 50.00, 10, 90.00, 'Anaquel 1', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (12, 12, 60.00, 10, 100.00, 'Anaquel 2', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (13, 13, 70.00, 10, 110.00, 'Anaquel 3', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (14, 14, 80.00, 10, 120.00, 'Anaquel 4', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (15, 15, 40.00, 10, 80.00, 'Anaquel 5', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (16, 16, 50.00, 10, 90.00, 'Anaquel 6', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (17, 17, 60.00, 10, 100.00, 'Anaquel 7', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (18, 18, 70.00, 10, 110.00, 'Anaquel 8', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (19, 19, 80.00, 10, 120.00, 'Anaquel 9', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (20, 20, 40.00, 10, 80.00, 'Anaquel 10', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (21, 21, 50.00, 10, 90.00, 'Anaquel 1', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (22, 22, 60.00, 10, 100.00, 'Anaquel 2', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (23, 23, 70.00, 10, 110.00, 'Anaquel 3', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (24, 24, 80.00, 10, 120.00, 'Anaquel 4', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (25, 25, 40.00, 10, 80.00, 'Anaquel 5', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (26, 26, 50.00, 10, 90.00, 'Anaquel 6', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (27, 27, 60.00, 10, 100.00, 'Anaquel 7', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (28, 28, 70.00, 10, 110.00, 'Anaquel 8', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (29, 29, 80.00, 10, 120.00, 'Anaquel 9', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (30, 30, 40.00, 10, 80.00, 'Anaquel 10', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (31, 31, 50.00, 10, 90.00, 'Anaquel 1', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (32, 32, 60.00, 10, 100.00, 'Anaquel 2', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (33, 33, 70.00, 10, 110.00, 'Anaquel 3', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (34, 34, 80.00, 10, 120.00, 'Anaquel 4', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (35, 35, 40.00, 10, 80.00, 'Anaquel 5', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (36, 36, 50.00, 10, 90.00, 'Anaquel 6', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (37, 37, 60.00, 10, 100.00, 'Anaquel 7', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (38, 38, 70.00, 10, 110.00, 'Anaquel 8', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (39, 39, 80.00, 10, 120.00, 'Anaquel 9', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (40, 40, 40.00, 10, 80.00, 'Anaquel 10', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (41, 41, 50.00, 10, 90.00, 'Anaquel 1', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (42, 42, 60.00, 10, 100.00, 'Anaquel 2', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (43, 43, 70.00, 10, 110.00, 'Anaquel 3', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (44, 44, 80.00, 10, 120.00, 'Anaquel 4', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (45, 45, 40.00, 10, 80.00, 'Anaquel 5', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (46, 46, 50.00, 10, 90.00, 'Anaquel 6', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (47, 47, 60.00, 10, 100.00, 'Anaquel 7', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (48, 48, 70.00, 10, 110.00, 'Anaquel 8', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (49, 49, 80.00, 10, 120.00, 'Anaquel 9', '2026-09-01 09:00:00');
INSERT INTO Inventario (inventario_id, producto_id, stock_actual, stock_minimo, stock_maximo, ubicacion, fecha_actualizacion) VALUES (50, 50, 40.00, 10, 80.00, 'Anaquel 10', '2026-09-01 09:00:00');

-- Movimiento_Inventario (ingreso inicial registrado por el almacenero)
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (1, 1, 1, 5, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (2, 2, 2, 4, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (3, 3, 3, 5, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (4, 4, 4, 4, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (5, 5, 5, 5, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (6, 6, 6, 4, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (7, 7, 7, 5, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (8, 8, 8, 4, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (9, 9, 9, 5, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (10, 10, 10, 4, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (11, 11, 11, 5, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (12, 12, 12, 4, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (13, 13, 13, 5, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (14, 14, 14, 4, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (15, 15, 15, 5, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (16, 16, 16, 4, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (17, 17, 17, 5, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (18, 18, 18, 4, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (19, 19, 19, 5, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (20, 20, 20, 4, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (21, 21, 21, 5, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (22, 22, 22, 4, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (23, 23, 23, 5, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (24, 24, 24, 4, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (25, 25, 25, 5, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (26, 26, 26, 4, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (27, 27, 27, 5, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (28, 28, 28, 4, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (29, 29, 29, 5, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (30, 30, 30, 4, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (31, 31, 31, 5, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (32, 32, 32, 4, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (33, 33, 33, 5, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (34, 34, 34, 4, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (35, 35, 35, 5, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (36, 36, 36, 4, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (37, 37, 37, 5, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (38, 38, 38, 4, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (39, 39, 39, 5, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (40, 40, 40, 4, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (41, 41, 41, 5, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (42, 42, 42, 4, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (43, 43, 43, 5, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (44, 44, 44, 4, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (45, 45, 45, 5, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (46, 46, 46, 4, 'ingreso', 50.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (47, 47, 47, 5, 'ingreso', 60.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (48, 48, 48, 4, 'ingreso', 70.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (49, 49, 49, 5, 'ingreso', 80.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (50, 50, 50, 4, 'ingreso', 40.00, '2026-09-01 08:30:00', 'Ingreso inicial de mercaderia');

-- Compra (compra de ejemplo al proveedor Distribuidora San Fernando)
INSERT INTO Compra (compra_id, proveedor_id, empleado_id, fecha_compra, tipo_pago, total, estado) VALUES (1, 1, 1, '2026-09-01 08:00:00', 'contado', 0, 1);

-- Detalle_Compra (detalle de la compra 1, primeros 10 productos)
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (1, 1, 1, 1, 50.00, 3.20, 160.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (2, 1, 2, 2, 60.00, 3.00, 180.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (3, 1, 3, 3, 70.00, 8.50, 595.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (4, 1, 4, 4, 80.00, 2.80, 224.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (5, 1, 5, 5, 40.00, 4.50, 180.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (6, 1, 6, 6, 50.00, 3.50, 175.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (7, 1, 7, 7, 60.00, 9.00, 540.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (8, 1, 8, 8, 70.00, 3.20, 224.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (9, 1, 9, 9, 80.00, 3.80, 304.00);
INSERT INTO Detalle_Compra (detalle_compra_id, compra_id, producto_id, lote_id, cantidad, precio_unitario, subtotal) VALUES (10, 1, 10, 10, 40.00, 1.50, 60.00);
UPDATE Compra SET total = 2642.00 WHERE compra_id = 1;

-- Caja (turno de ejemplo)
INSERT INTO Caja (caja_id, empleado_id, fecha_apertura, monto_apertura, fecha_cierre, monto_cierre, estado) VALUES (1, 2, '2026-09-02 08:00:00', 100.00, '2026-09-02 20:00:00', 850.30, 0);
INSERT INTO Caja (caja_id, empleado_id, fecha_apertura, monto_apertura, fecha_cierre, monto_cierre, estado) VALUES (2, 3, '2026-09-03 08:00:00', 100.00, NULL, NULL, 1);

-- Venta, Detalle_Venta y Pago (transacciones de ejemplo)
INSERT INTO Venta (venta_id, cliente_id, empleado_id, caja_id, fecha_venta, tipo_comprobante, subtotal, igv, total, estado) VALUES (1, 1, 2, 1, '2026-09-02 09:15:00', 'boleta', 32.46, 5.84, 38.30, 1);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (1, 1, 13, 13, 2.00, 6.50, 0, 13.00);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (2, 1, 23, 23, 1.00, 13.50, 0, 13.50);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (3, 1, 39, 39, 1.00, 11.80, 0, 11.80);
INSERT INTO Pago (pago_id, venta_id, metodo_pago, monto, fecha_pago, referencia) VALUES (1, 1, 'efectivo', 38.30, '2026-09-02 09:15:00', 'REF-0001');
INSERT INTO Venta (venta_id, cliente_id, empleado_id, caja_id, fecha_venta, tipo_comprobante, subtotal, igv, total, estado) VALUES (2, 3, 2, 1, '2026-09-02 11:30:00', 'boleta', 22.97, 4.13, 27.10, 1);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (4, 2, 31, 31, 1.00, 5.50, 0, 5.50);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (5, 2, 32, 32, 1.00, 7.20, 0, 7.20);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (6, 2, 18, 18, 3.00, 4.80, 0, 14.40);
INSERT INTO Pago (pago_id, venta_id, metodo_pago, monto, fecha_pago, referencia) VALUES (2, 2, 'yape', 27.10, '2026-09-02 11:30:00', 'REF-0002');
INSERT INTO Venta (venta_id, cliente_id, empleado_id, caja_id, fecha_venta, tipo_comprobante, subtotal, igv, total, estado) VALUES (3, NULL, 2, 1, '2026-09-02 16:45:00', 'boleta', 12.46, 2.24, 14.70, 1);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (7, 3, 1, 1, 1.00, 4.50, 0, 4.50);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (8, 3, 10, 10, 1.00, 2.20, 0, 2.20);
INSERT INTO Detalle_Venta (detalle_venta_id, venta_id, producto_id, lote_id, cantidad, precio_unitario, descuento, subtotal) VALUES (9, 3, 15, 15, 4.00, 2.00, 0, 8.00);
INSERT INTO Pago (pago_id, venta_id, metodo_pago, monto, fecha_pago, referencia) VALUES (3, 3, 'efectivo', 14.70, '2026-09-02 16:45:00', 'REF-0003');

-- Descuenta el stock vendido en Inventario y registra la salida en Movimiento_Inventario
UPDATE Inventario SET stock_actual = stock_actual - 2.00, fecha_actualizacion = '2026-09-02 09:15:00' WHERE producto_id = 13;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (51, 13, 13, 2, 'salida', 2.00, '2026-09-02 09:15:00', 'Venta 1');
UPDATE Inventario SET stock_actual = stock_actual - 1.00, fecha_actualizacion = '2026-09-02 09:15:00' WHERE producto_id = 23;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (52, 23, 23, 2, 'salida', 1.00, '2026-09-02 09:15:00', 'Venta 1');
UPDATE Inventario SET stock_actual = stock_actual - 1.00, fecha_actualizacion = '2026-09-02 09:15:00' WHERE producto_id = 39;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (53, 39, 39, 2, 'salida', 1.00, '2026-09-02 09:15:00', 'Venta 1');
UPDATE Inventario SET stock_actual = stock_actual - 1.00, fecha_actualizacion = '2026-09-02 11:30:00' WHERE producto_id = 31;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (54, 31, 31, 2, 'salida', 1.00, '2026-09-02 11:30:00', 'Venta 2');
UPDATE Inventario SET stock_actual = stock_actual - 1.00, fecha_actualizacion = '2026-09-02 11:30:00' WHERE producto_id = 32;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (55, 32, 32, 2, 'salida', 1.00, '2026-09-02 11:30:00', 'Venta 2');
UPDATE Inventario SET stock_actual = stock_actual - 3.00, fecha_actualizacion = '2026-09-02 11:30:00' WHERE producto_id = 18;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (56, 18, 18, 2, 'salida', 3.00, '2026-09-02 11:30:00', 'Venta 2');
UPDATE Inventario SET stock_actual = stock_actual - 1.00, fecha_actualizacion = '2026-09-02 16:45:00' WHERE producto_id = 1;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (57, 1, 1, 2, 'salida', 1.00, '2026-09-02 16:45:00', 'Venta 3');
UPDATE Inventario SET stock_actual = stock_actual - 1.00, fecha_actualizacion = '2026-09-02 16:45:00' WHERE producto_id = 10;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (58, 10, 10, 2, 'salida', 1.00, '2026-09-02 16:45:00', 'Venta 3');
UPDATE Inventario SET stock_actual = stock_actual - 4.00, fecha_actualizacion = '2026-09-02 16:45:00' WHERE producto_id = 15;
INSERT INTO Movimiento_Inventario (movimiento_id, producto_id, lote_id, empleado_id, tipo_movimiento, cantidad, fecha_movimiento, motivo) VALUES (59, 15, 15, 2, 'salida', 4.00, '2026-09-02 16:45:00', 'Venta 3');

