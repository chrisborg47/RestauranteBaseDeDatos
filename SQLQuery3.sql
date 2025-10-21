/* ===========================================
   RESET LIMPIO Y PARCHE DE RESTRICCIONES
   Objetivo: trabajar con BD 'Restaurante'
=========================================== */

---------------------------------------------
-- 1) Reset limpio de BD
---------------------------------------------
USE master;
GO

IF DB_ID('Restaurante') IS NOT NULL
BEGIN
    ALTER DATABASE Restaurante SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Restaurante;
END;
GO

CREATE DATABASE Restaurante;
GO

USE Restaurante;
GO

/* En este punto, EJECUTA tu script del equipo que crea
   las tablas, inserts y vistas sobre 'Restaurante'.
   Si YA lo ejecutaste antes, vuelve a ejecutarlo aquí
   (y no pasará nada con los INSERT UNIQUE ya hechos).
*/


/* =========================================================
   2) PARCHE DE CALIDAD (CHECK/DEFAULT/UNIQUE/Índices)
   (solo altera si existen las tablas; asume tus nombres)
========================================================= */

-- ===== Cliente =====
IF OBJECT_ID('dbo.Cliente','U') IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Cliente_TelefonoFormato')
    ALTER TABLE dbo.Cliente
      ADD CONSTRAINT CK_Cliente_TelefonoFormato
          CHECK (telefono IS NULL OR telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]');

  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Cliente_CorreoFormato')
    ALTER TABLE dbo.Cliente
      ADD CONSTRAINT CK_Cliente_CorreoFormato
          CHECK (correo IS NULL OR correo LIKE '%@%.%');
END
GO

-- ===== Empleado =====
IF OBJECT_ID('dbo.Empleado','U') IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Empleado_Puesto')
    ALTER TABLE dbo.Empleado
      ADD CONSTRAINT CK_Empleado_Puesto
          CHECK (puesto IN (N'Cocinera',N'Mesero',N'Cajera',N'Gerente'));

  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Empleado_SalarioMin')
    ALTER TABLE dbo.Empleado
      ADD CONSTRAINT CK_Empleado_SalarioMin
          CHECK (salario >= 200000);
END
GO

-- ===== Mesa =====
IF OBJECT_ID('dbo.Mesa','U') IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Mesa_CapacidadPositiva')
    ALTER TABLE dbo.Mesa
      ADD CONSTRAINT CK_Mesa_CapacidadPositiva CHECK (capacidad > 0);

  IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_Mesa_Estado')
    ALTER TABLE dbo.Mesa
      ADD CONSTRAINT DF_Mesa_Estado DEFAULT(0) FOR estado;  -- 0 disponible
END
GO

-- ===== Reserva =====
IF OBJECT_ID('dbo.Reserva','U') IS NOT NULL
BEGIN
  /* Quitar UNIQUE en hora_reserva si existe (constraint o índice) */
  DECLARE @uq sysname, @ix sysname, @sql nvarchar(max);

  -- ¿Unique CONSTRAINT sobre la columna?
  SELECT TOP(1) @uq = kc.name
  FROM sys.key_constraints kc
  JOIN sys.tables t ON t.object_id = kc.parent_object_id
  JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
  JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
  WHERE kc.[type] = 'UQ'
    AND t.name = 'Reserva'
    AND c.name = 'hora_reserva';

  IF @uq IS NOT NULL
  BEGIN
     SET @sql = N'ALTER TABLE dbo.Reserva DROP CONSTRAINT ' + QUOTENAME(@uq) + N';';
     EXEC sp_executesql @sql;
  END
  ELSE
  BEGIN
     -- ¿Índice único simple en la columna?
     SELECT TOP(1) @ix = i.name
     FROM sys.indexes i
     JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
     JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
     WHERE i.object_id = OBJECT_ID('dbo.Reserva')
       AND i.is_unique = 1
       AND c.name = 'hora_reserva';

     IF @ix IS NOT NULL
     BEGIN
        SET @sql = N'DROP INDEX ' + QUOTENAME(@ix) + N' ON dbo.Reserva;';
        EXEC sp_executesql @sql;
     END
  END

  -- Índice único correcto por mesa+fecha+hora (evita doble reserva misma mesa/fecha/hora)
  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Reserva_MesaFechaHora' AND object_id = OBJECT_ID('dbo.Reserva'))
     CREATE UNIQUE INDEX UX_Reserva_MesaFechaHora
     ON dbo.Reserva(id_mesa, fecha_reserva, hora_reserva);

  -- Fecha hoy o futura
  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Reserva_FechaFutura')
     ALTER TABLE dbo.Reserva
       ADD CONSTRAINT CK_Reserva_FechaFutura
           CHECK (fecha_reserva >= CAST(GETDATE() AS date));
END
GO

-- ===== Metodo_Pago =====
IF OBJECT_ID('dbo.Metodo_Pago','U') IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_MetodoPago_Tipos')
    ALTER TABLE dbo.Metodo_Pago
      ADD CONSTRAINT CK_MetodoPago_Tipos
          CHECK (tipo_pago IN (N'Efectivo',N'Tarjeta',N'Sinpe',N'Cupon'));
END
GO

-- ===== Pedido =====
IF OBJECT_ID('dbo.Pedido','U') IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_Pedido_Fecha')
    ALTER TABLE dbo.Pedido
      ADD CONSTRAINT DF_Pedido_Fecha DEFAULT (CAST(GETDATE() AS date)) FOR fecha;

  IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_Pedido_Hora')
    ALTER TABLE dbo.Pedido
      ADD CONSTRAINT DF_Pedido_Hora  DEFAULT (CONVERT(time, GETDATE())) FOR hora;
END
GO

-- ===== Categoria =====
IF OBJECT_ID('dbo.Categoria','U') IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Categoria_Nombre' AND object_id = OBJECT_ID('dbo.Categoria'))
     CREATE UNIQUE INDEX UQ_Categoria_Nombre ON dbo.Categoria(nombre_categoria);
END
GO

-- ===== Ingredientes =====
IF OBJECT_ID('dbo.Ingredientes','U') IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_Ingredientes_Cantidad')
    ALTER TABLE dbo.Ingredientes
      ADD CONSTRAINT DF_Ingredientes_Cantidad DEFAULT(0) FOR cantidad_stock;

  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Ingredientes_Cantidad')
    ALTER TABLE dbo.Ingredientes
      ADD CONSTRAINT CK_Ingredientes_Cantidad CHECK (cantidad_stock >= 0);
END
GO

-- ===== Producto =====
IF OBJECT_ID('dbo.Producto','U') IS NOT NULL
BEGIN
  -- asegurar NOT NULL
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Producto') AND name = 'precio' AND is_nullable = 1)
     ALTER TABLE dbo.Producto ALTER COLUMN precio MONEY NOT NULL;

  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Producto_Precio')
     ALTER TABLE dbo.Producto
       ADD CONSTRAINT CK_Producto_Precio CHECK (precio > 0);
END
GO

-- ===== Detalle_Pedido =====
IF OBJECT_ID('dbo.Detalle_Pedido','U') IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Detalle_Subtotal')
    ALTER TABLE dbo.Detalle_Pedido
      ADD CONSTRAINT CK_Detalle_Subtotal CHECK (subtotal > 0);
END
GO


/* ===========================================
   3) SMOKE TESTS
=========================================== */
SELECT DB_NAME() AS Contexto,
       (SELECT COUNT(*) FROM sys.tables) AS Tablas,
       (SELECT COUNT(*) FROM sys.views)  AS Vistas;

SELECT TOP 3 * FROM dbo.Cliente;
SELECT TOP 3 * FROM dbo.Pedido;
SELECT TOP 3 * FROM dbo.Producto;

SELECT TOP 3 * FROM dbo.ReservasEnMesa;
SELECT TOP 3 * FROM dbo.MesasNoReserva;
SELECT TOP 3 * FROM dbo.ClientesQueNoHanPedido;
