# Proyecto Base de Datos – Restaurante

Repositorio del proyecto final de Bases de Datos I – Universidad Latina de Costa Rica.  
Desarrollado por el equipo:
- Val  
- Tomás  
- Tai  
- Chris  

---

## Descripción general

Este proyecto implementa un sistema de gestión para un restaurante o negocio de comida rápida, modelando sus entidades principales: clientes, empleados, mesas, reservas, pedidos, productos, ingredientes y métodos de pago.

El objetivo fue aplicar los conceptos vistos en clase:
- Modelo Entidad–Relación (E–R)
- Restricciones (PRIMARY KEY, FOREIGN KEY, CHECK, UNIQUE, DEFAULT)
- Creación de vistas con distintos tipos de JOIN (INNER, LEFT, LEFT EXCLUIDO)
- Uso de diagramas de Venn para representar relaciones entre entidades

---

## Estructura del proyecto

restaurante-db/
├─ sql/
│ └─ 00_bootstrap_restaurante.sql ← script principal (creación, datos y vistas)
├─ docs/
│ └─ venn/ ← diagramas de Venn usados en la exposición
└─ README.md

yaml
Copy code

---

## Requisitos técnicos

- Microsoft SQL Server 2019 o superior  
- SQL Server Management Studio (SSMS) 21  
- Permisos de administrador para crear bases de datos locales

---

## Ejecución paso a paso

1. Abrir SQL Server Management Studio (SSMS) 21 y conectarse a la instancia local.  
2. Abrir el archivo:
sql/00_bootstrap_restaurante.sql

markdown
Copy code
3. Ejecutar todo el script (F5).  
El script realizará automáticamente:
- Creación de la base de datos `Restaurante`
- Creación de las tablas con sus restricciones
- Inserción de datos de prueba
- Creación de las vistas
- Ejecución de pruebas rápidas (SELECT TOP (3))

4. Verificar que la base esté creada correctamente:
```sql
SELECT DB_NAME() AS Contexto, COUNT(*) AS Tablas FROM sys.tables;
SELECT name FROM sys.views;
Tablas principales
Tabla	Descripción
Cliente	Registra los datos de los clientes
Empleado	Guarda los empleados del restaurante
Mesa	Define número, capacidad y estado
Reserva	Asocia clientes con mesas y horarios
Metodo_Pago	Formas de pago disponibles
Pedido	Encabezado de los pedidos realizados
Categoria	Clasifica los productos
Ingredientes	Inventario de insumos
Producto	Menú del restaurante
Detalle_Pedido	Detalle de los productos dentro de cada pedido

Vistas creadas
#	Nombre de la vista	Tipo de JOIN / Descripción
1	ReservasEnMesa	INNER JOIN entre Reserva, Cliente y Mesa
2	Pedidos_Por_Cliente	INNER JOIN entre Pedido y Cliente
3	ProductoCategoria	INNER JOIN entre Producto y Categoria
4	DetalleClientes	INNER JOIN (detalle del pedido por cliente)
5	MetodoPagoCliente	INNER JOIN (pedido con método de pago)
6	MesasNoReserva	LEFT JOIN excluido (mesas sin reserva)
7	ClientesQueNoHanPedido	LEFT JOIN excluido (clientes sin pedidos)
8	EmpleadosPedidos	LEFT JOIN (empleados y los pedidos que atendieron)
9	ingredientes	INNER JOIN (productos con ingredientes)
10	Todos	LEFT JOIN (todos los clientes y sus reservas)
11	ClientesConPedidosSinReserva	INNER JOIN + LEFT excluido + GROUP BY (clientes con pedidos pero sin reservas)

Vista adicional destacada
ClientesConPedidosSinReserva

Esta vista muestra los clientes que han realizado pedidos pero no tienen ninguna reserva registrada.
Utiliza un INNER JOIN con Pedido y un LEFT JOIN excluido con Reserva.

sql
Copy code
CREATE VIEW dbo.ClientesConPedidosSinReserva AS
SELECT 
    c.id_cliente,
    c.nombre_cliente,
    c.apellido_cliente,
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    SUM(p.total) AS gasto_total
FROM dbo.Cliente  AS c
INNER JOIN dbo.Pedido  AS p ON p.id_cliente = c.id_cliente
LEFT  JOIN dbo.Reserva AS r ON r.id_cliente = c.id_cliente
WHERE r.id_reserva IS NULL
GROUP BY c.id_cliente, c.nombre_cliente, c.apellido_cliente;
Diagramas y exposición
Durante la exposición se presentaron diagramas de Venn para explicar:

Relaciones entre clientes y reservas

Relaciones entre pedidos y productos

Consultas de exclusión (clientes sin pedidos, mesas sin reservas)

Estos diagramas se encuentran en la carpeta docs/venn/.

Verificación rápida (Smoke Tests)
sql
Copy code
SELECT DB_NAME() AS Contexto, COUNT(*) AS Tablas FROM sys.tables;
SELECT TOP 3 * FROM dbo.Cliente;
SELECT TOP 3 * FROM dbo.ReservasEnMesa;
SELECT TOP 3 * FROM dbo.ClientesConPedidosSinReserva;
Créditos del equipo
Val – Diseño del diagrama E–R

Tomás – Creación de tablas y carga de datos

Tai – Creación de vistas y diagramas de Venn

Chris – Integración final, GitHub y optimización de consultas

Licencia
Uso académico exclusivo – Proyecto Bases de Datos I
Universidad Latina de Costa Rica
