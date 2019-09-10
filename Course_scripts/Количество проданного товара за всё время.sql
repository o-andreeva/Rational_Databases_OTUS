USE [int_shop_otus]
GO

select SUM(a.quantity)
From dbo.items_in_order as a

Select * 
FROM dbo.product_hierarcy

Select * 
FROM dbo.prod_type_minimal



USE [int _shop_otus]
GO

--- Формирование доступного списка характеристик по всем товарам ----


Select l.attr_id, a.[name], l.min_type_id, t.product_type_name ,l.type_attribute_id, p.product_id, p.[name], at_type.[name], v.value_date, v.value_num, v.value_text, a.attr_abbreviation
from dbo.type_attributes_list as l
inner join dbo.attributes a on a.attr_id = l.attr_id
INNER JOIN dbo.prod_type_minimal as t on t.min_type_id = l.min_type_id
INNER JOIN dbo.product as p on p.prod_type_id= t.min_type_id
INNER JOIN dbo.attribute_type_technical as at_type on at_type.technical_id=a.type_id_technical
INNER JOIN dbo.attribute_value as v on v.type_attribute_id = l.type_attribute_id and v.product_id = p.product_id
ORDER BY  p.[name]

UPDATE dbo.attributes
SET attr_abbreviation = 'стр.' WHERE attr_abbreviation = 'страниц'


Select *
FROM  dbo.attributes_check


--- Количетсво проданного товара за всё время ----

SELECT p.[name], p.product_id, SUM(i.quantity) as Sold_quantity
FROM [int _shop_otus].dbo.product as p
INNER JOIN dbo.items_in_order as i ON p.product_id = i.product_id
INNER JOIN dbo.client_order as o on o.order_id = i.order_id
INNER JOIN dbo.delivery_status as ds on o.order_delivery_status_id = ds.id
WHERE ds.[status] <> 'Отмена'
Group BY p.[name], p.product_id

Select *
From dbo.products_in_supply_order



