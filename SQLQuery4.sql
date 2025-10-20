CREATE DATABASE Restaurante;
GO
USE Restaurante;
GO

---------------------------
-- TABLAS
---------------------------

-- 1) Cliente
CREATE TABLE dbo.Cliente (
  id_cliente       INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  nombre_cliente   NVARCHAR(15) NOT NULL,
  apellido_cliente NVARCHAR(15) NOT NULL,
  telefono         NVARCHAR(10) UNIQUE,
  correo           NVARCHAR(100) UNIQUE,
  -- mejoras suaves:
  CONSTRAINT CK_Cliente_TelefonoFormato
    CHECK (telefono IS NULL OR telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
  CONSTRAINT CK_Cliente_CorreoFormato
    CHECK (correo IS NULL OR correo LIKE '%@%.%')
);
GO

-- 2) Empleado
CREATE TABLE dbo.Empleado (
  id_empleado       INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  nombre_empleado   NVARCHAR(15) NOT NULL,
  apellido_empleado NVARCHAR(15) NOT NULL,
  puesto            NVARCHAR(15) NOT NULL,
  salario           MONEY NOT NULL DEFAULT (367000),
  CONSTRAINT CK_Empleado_SalarioMin CHECK (salario >= 200000),
  CONSTRAINT CK_Empleado_Puesto CHECK (puesto IN (N'Cocinera',N'Mesero',N'Cajera',N'Gerente'))
);
GO

-- 3) Mesa
CREATE TABLE dbo.Mesa (
  id_mesa     INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  numero_mesa INT UNIQUE NOT NULL,
  capacidad   INT NOT NULL,
  estado      BIT NOT NULL DEFAULT(0),  -- 0 disponible / 1 ocupada
  CONSTRAINT CK_Mesa_CapacidadPositiva CHECK (capacidad > 0)
);
GO

-- 4) Reserva
CREATE TABLE dbo.Reserva (
  id_reserva     INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  fecha_reserva  DATE NOT NULL,
  hora_reserva   TIME NOT NULL,         
  id_cliente     INT NOT NULL,
  id_mesa        INT NOT NULL,
  CONSTRAINT FK_Reserva_Cliente FOREIGN KEY (id_cliente) REFERENCES dbo.Cliente (id_cliente),
  CONSTRAINT FK_Reserva_Mesa    FOREIGN KEY (id_mesa)    REFERENCES dbo.Mesa (id_mesa),
  CONSTRAINT CK_Reserva_FechaFutura CHECK (fecha_reserva >= CAST(GETDATE() AS date))
);
GO

-- (mesa, fecha, hora)
CREATE UNIQUE INDEX UX_Reserva_MesaFechaHora
  ON dbo.Reserva(id_mesa, fecha_reserva, hora_reserva);
GO

-- 5) Metodo_Pago
CREATE TABLE dbo.Metodo_Pago (
  id_metodoP        INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  tipo_pago         NVARCHAR(10) UNIQUE NOT NULL,
  descripcion_pago  NVARCHAR(200) DEFAULT ('Sin descripcion'),
  CONSTRAINT CK_MetodoPago_Tipos CHECK (tipo_pago IN (N'Efectivo',N'Tarjeta',N'Sinpe',N'Cupon'))
);
GO

-- 6) Pedido
CREATE TABLE dbo.Pedido (
  id_pedido   INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  fecha       DATE NULL DEFAULT (CAST(GETDATE() AS date)),
  hora        TIME NULL DEFAULT (CONVERT(time, GETDATE())),
  total       MONEY NOT NULL CHECK (total > 0),
  id_cliente  INT NOT NULL,
  id_empleado INT NOT NULL,
  id_metodoP  INT NOT NULL,
  CONSTRAINT FK_Pedido_Cliente       FOREIGN KEY (id_cliente)  REFERENCES dbo.Cliente (id_cliente),
  CONSTRAINT FK_Pedido_Empleado      FOREIGN KEY (id_empleado) REFERENCES dbo.Empleado (id_empleado),
  CONSTRAINT FK_Pedido_Metodo_Pago   FOREIGN KEY (id_metodoP)  REFERENCES dbo.Metodo_Pago (id_metodoP)
);
GO

-- 7) Categoria
CREATE TABLE dbo.Categoria (
  id_categoria      INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  nombre_categoria  NVARCHAR(50) NOT NULL,
  descripcion       NVARCHAR(200) DEFAULT ('Sin descripcion')
);
GO

-- Evitar duplicados de nombre de categoría
CREATE UNIQUE INDEX UQ_Categoria_Nombre ON dbo.Categoria(nombre_categoria);
GO

-- 8) Ingredientes
CREATE TABLE dbo.Ingredientes (
  id_ingrediente     INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  nombre_ingrediente NVARCHAR(25) UNIQUE NOT NULL,
  cantidad_stock     INT NULL DEFAULT(0),
  CONSTRAINT CK_Ingredientes_Cantidad CHECK (cantidad_stock >= 0)
);
GO

-- 9) Producto
CREATE TABLE dbo.Producto (
  id_producto     INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  nombre_producto NVARCHAR(75) UNIQUE NOT NULL,
  precio          MONEY NOT NULL,             -- NOT NULL
  id_categoria    INT NOT NULL,
  CONSTRAINT CK_Producto_Precio CHECK (precio > 0),
  CONSTRAINT FK_Producto_Categoria FOREIGN KEY (id_categoria) REFERENCES dbo.Categoria (id_categoria)
);
GO

-- 10) Detalle_Pedido
CREATE TABLE dbo.Detalle_Pedido (
  id_detalleP   INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  cantidad      INT   NOT NULL CHECK (cantidad > 0),
  subtotal      MONEY NOT NULL CHECK (subtotal > 0),
  id_pedido     INT NOT NULL,
  id_producto   INT NOT NULL,
  id_ingrediente INT NOT NULL,
  CONSTRAINT FK_Detalle_Pedido_Pedido      FOREIGN KEY (id_pedido)     REFERENCES dbo.Pedido (id_pedido),
  CONSTRAINT FK_Detalle_Pedido_Producto    FOREIGN KEY (id_producto)   REFERENCES dbo.Producto (id_producto),
  CONSTRAINT FK_Detalle_Pedido_Ingrediente FOREIGN KEY (id_ingrediente)REFERENCES dbo.Ingredientes (id_ingrediente)
);
GO

---------------------------
-- DATOS (del equipo)
---------------------------
INSERT INTO dbo.Cliente (nombre_cliente, apellido_cliente, telefono, correo) VALUES
 ('Juan',  'Perez',      '7988-1234', 'juan.perez@gmail.com'),
 ('Maria', 'Rodriguez',  '8747-5678', 'maria.rodriguez@gmail.com'),
 ('Carlos','Gomez',      '8912-4321', 'carlos.gomez@gmail.com'),
 ('Laura', 'Fernandez',  '8346-8765', 'laura.fernandez@gmail.com');
SELECT * FROM dbo.Cliente;

INSERT INTO dbo.Empleado (nombre_empleado, apellido_empleado, puesto, salario) VALUES
 ('Ana',  'Lopez',   'Cocinera', 410000),
 ('Mario','Sanchez', 'Mesero',   367000),
 ('Paula','Herrera', 'Cajera',   367000),
 ('Jose', 'Vargas',  'Gerente',  500000);
SELECT * FROM dbo.Empleado;

INSERT INTO dbo.Mesa (numero_mesa, capacidad, estado) VALUES
 (1, 4, 0),
 (2, 2, 1),
 (3, 6, 0),
 (4, 8, 1);
SELECT * FROM dbo.Mesa;

INSERT INTO dbo.Reserva (fecha_reserva, hora_reserva, id_cliente, id_mesa) VALUES
 ('2025-10-20', '18:00:00', 1, 1),
 ('2025-10-21', '12:30:00', 2, 2),
 ('2025-10-22', '19:00:00', 3, 3),
 ('2025-10-23', '20:15:00', 4, 4);
SELECT * FROM dbo.Reserva;

INSERT INTO dbo.Metodo_Pago (tipo_pago, descripcion_pago) VALUES
 ('Efectivo', 'Pago en efectivo'),
 ('Tarjeta',  'Pago con tarjeta credito/debito'),
 ('Sinpe',    'Pago con sinpe movil'),
 ('Cupon',    'Pago con cupon');
SELECT * FROM dbo.Metodo_Pago;

INSERT INTO dbo.Pedido (fecha, hora, total, id_cliente, id_empleado, id_metodoP) VALUES
 ('2025-10-20', '18:30:00', 6500, 1, 2, 1),
 ('2025-10-21', '13:00:00', 5000, 2, 1, 2),
 ('2025-10-22', '19:15:00', 4500, 3, 2, 3),
 ('2025-10-23', '20:45:00', 4200, 4, 1, 1);
SELECT * FROM dbo.Pedido;

INSERT INTO dbo.Categoria (nombre_categoria, descripcion) VALUES
 ('Bebidas', 'Bebidas frias y calientes'),
 ('Comida',  'Platos principales'),
 ('Postres', 'Dulces y postres');
SELECT * FROM dbo.Categoria;

INSERT INTO dbo.Ingredientes (nombre_ingrediente, cantidad_stock) VALUES
 ('Leche', 50),
 ('Harina',100),
 ('Queso', 30),
 ('Tomate',40);
SELECT * FROM dbo.Ingredientes;

INSERT INTO dbo.Producto (nombre_producto, precio, id_categoria) VALUES
 ('Jugo de naranja',   1500, 1),
 ('Pizza Margarita',   5000, 2),
 ('Pastel de chocolate',3000, 3),
 ('Cafe',              1200, 1);
SELECT * FROM dbo.Producto;

INSERT INTO dbo.Detalle_Pedido (id_pedido, id_producto, id_ingrediente, cantidad, subtotal) VALUES
 (1, 1, 1, 1, 1500),
 (1, 2, 3, 1, 5000),
 (2, 2, 4, 1, 5000),
 (3, 3, 1, 1, 3000),
 (3, 4, 1, 1, 1200),
 (4, 4, 1, 1, 1200);
SELECT * FROM dbo.Detalle_Pedido;
GO

---------------------------
-- VISTAS (10 del equipo)
---------------------------

-- 1
CREATE VIEW dbo.ReservasEnMesa AS
SELECT 
  r.id_reserva      AS ID_Reserva,
  c.nombre_cliente  AS Cliente,
  m.numero_mesa     AS Numero_Mesa,
  m.capacidad       AS Capacidad,
  r.fecha_reserva   AS Fecha,
  r.hora_reserva    AS Hora
FROM dbo.Reserva  r
INNER JOIN dbo.Cliente c ON r.id_cliente = c.id_cliente
INNER JOIN dbo.Mesa    m ON r.id_mesa    = m.id_mesa;
GO

-- 2
CREATE VIEW dbo.Pedidos_Por_Cliente AS
SELECT 
  c.nombre_cliente AS NombreCliente,
  c.apellido_cliente AS ApellidoCliente,
  p.id_pedido     AS ID_Pedido,
  p.fecha         AS Fecha,
  p.hora          AS Hora,
  p.total         AS Total
FROM dbo.Pedido  p
INNER JOIN dbo.Cliente c ON p.id_cliente = c.id_cliente;
GO

-- 3
CREATE VIEW dbo.ProductoCategoria AS
SELECT  
  p.nombre_producto  AS Producto,
  p.precio           AS Precio,
  c.nombre_categoria AS Categoria,
  c.descripcion      AS Descripcion
FROM dbo.Producto p
INNER JOIN dbo.Categoria c ON p.id_categoria = c.id_categoria;
GO

-- 4 (corregido el typo 'oN' -> 'ON')
CREATE VIEW dbo.DetalleClientes AS
SELECT  
  dp.id_detalleP       AS ID_Detalle,
  cl.nombre_cliente    AS Cliente,
  pr.nombre_producto   AS Producto,
  dp.cantidad          AS Cantidad,
  dp.subtotal          AS Subtotal
FROM dbo.Detalle_Pedido dp
INNER JOIN dbo.Pedido    p  ON dp.id_pedido   = p.id_pedido
INNER JOIN dbo.Cliente   cl ON p.id_cliente   = cl.id_cliente
INNER JOIN dbo.Producto  pr ON dp.id_producto = pr.id_producto;
GO

-- 5
CREATE VIEW dbo.MetodoPagoCliente AS
SELECT  
  p.id_pedido      AS ID_Pedido,
  c.nombre_cliente AS Cliente,
  mp.tipo_pago     AS MetodoPago,
  p.total          AS Total
FROM dbo.Pedido p
INNER JOIN dbo.Cliente     c  ON p.id_cliente  = c.id_cliente
INNER JOIN dbo.Metodo_Pago mp ON p.id_metodoP  = mp.id_metodoP;
GO

-- 6
CREATE VIEW dbo.MesasNoReserva AS
SELECT m.numero_mesa AS NumeroMesa,
       m.capacidad   AS Capacidad,
       m.estado      AS Estado
FROM dbo.Mesa m
LEFT JOIN dbo.Reserva r ON m.id_mesa = r.id_mesa
WHERE r.id_reserva IS NULL;
GO

-- 7
CREATE VIEW dbo.ClientesQueNoHanPedido AS
SELECT  
  c.id_cliente       AS ID_Cliente,
  c.nombre_cliente   AS Nombre,
  c.apellido_cliente AS Apellido,
  c.telefono         AS Telefono,
  c.correo           AS Correo
FROM dbo.Cliente c
LEFT JOIN dbo.Pedido p ON c.id_cliente = p.id_cliente
WHERE p.id_pedido IS NULL;
GO

-- (insert útil para ver la vista #7 en acción)
INSERT INTO dbo.Cliente (nombre_cliente, apellido_cliente, telefono, correo)
VALUES ('LuisPa', 'Chuzo', '9991-9999', 'JuegoGenshin@gmail.com');
GO

-- 8
CREATE VIEW dbo.EmpleadosPedidos AS
SELECT 
  e.id_empleado   AS ID_Empleado,
  e.nombre_empleado AS Empleado,
  e.puesto        AS Puesto,
  p.id_pedido     AS ID_Pedido,
  p.total         AS Total
FROM dbo.Empleado e
LEFT JOIN dbo.Pedido p ON e.id_empleado = p.id_empleado;
GO

-- 9
CREATE VIEW dbo.ingredientes AS
SELECT 
  pr.nombre_producto    AS Producto,
  i.nombre_ingrediente  AS Ingrediente,
  dp.cantidad           AS Cantidad,
  dp.subtotal           AS Subtotal
FROM dbo.Detalle_Pedido dp
INNER JOIN dbo.Producto    pr ON dp.id_producto   = pr.id_producto
INNER JOIN dbo.Ingredientes i ON dp.id_ingrediente = i.id_ingrediente;
GO

-- 10
CREATE VIEW dbo.Todos AS
SELECT 
  c.id_cliente     AS ID_Cliente,
  c.nombre_cliente AS Cliente,
  r.id_reserva     AS ID_Reserva,
  r.fecha_reserva  AS Fecha,
  r.hora_reserva   AS Hora
FROM dbo.Cliente c
LEFT JOIN dbo.Reserva r ON c.id_cliente = r.id_cliente;
GO

---------------------------
-- 11) Vista nueva (Venn)
-- Clientes con pedidos pero SIN reservas
---------------------------
CREATE VIEW dbo.ClientesConPedidosSinReserva AS
SELECT 
  c.id_cliente,
  c.nombre_cliente,
  c.apellido_cliente,
  COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
  SUM(p.total)                AS gasto_total
FROM dbo.Cliente  AS c
INNER JOIN dbo.Pedido  AS p ON p.id_cliente = c.id_cliente
LEFT  JOIN dbo.Reserva AS r ON r.id_cliente = c.id_cliente
WHERE r.id_reserva IS NULL
GROUP BY c.id_cliente, c.nombre_cliente, c.apellido_cliente;
GO

---------------------------
-- SMOKE TESTS
---------------------------
SELECT DB_NAME() AS Contexto,
       (SELECT COUNT(*) FROM sys.tables) AS Tablas,
       (SELECT COUNT(*) FROM sys.views)  AS Vistas;

SELECT TOP 3 * FROM dbo.Todos; 
SELECT TOP 3 * FROM dbo.Pedidos_Por_Cliente; 
SELECT TOP 3 * FROM dbo.ingredientes; 
SELECT TOP 3 * FROM dbo.ReservasEnMesa;
SELECT TOP 3 * FROM dbo.EmpleadosPedidos; 
SELECT TOP 3 * FROM dbo.ClientesQueNoHanPedido;
SELECT TOP 3 * FROM dbo.MesasNoReserva;
SELECT TOP 3 * FROM dbo.MetodoPagoCliente;
SELECT TOP 3 * FROM dbo.DetalleClientes; 
SELECT TOP 3 * FROM dbo.ProductoCategoria; 
SELECT TOP 3 * FROM dbo.ClientesConPedidosSinReserva;
