USE [int_shop_otus]
GO


WITH ftable as
 (
SELECT  p.product_id, p.[name] as product_name, a.[name] + ': ' + COALESCE( CAST(v.value_date AS varchar(100)), CAST( CONVERT( DOUBLE PRECISION, v.value_num) AS varchar(100)), v.value_text) AS val
from dbo.type_attributes_list as l
inner join dbo.attributes a on a.attr_id = l.attr_id
INNER JOIN dbo.prod_type_minimal as t on t.min_type_id = l.min_type_id
INNER JOIN dbo.product as p on p.prod_type_id= t.min_type_id
INNER JOIN dbo.attribute_type_technical as at_type on at_type.technical_id=a.type_id_technical
INNER JOIN dbo.attribute_value as v on v.type_attribute_id = l.type_attribute_id 
and v.product_id = p.product_id
)


SELECT product_id AS "product_id", [name], 
(
SELECT val as "data()"
FROM ftable
WHERE  product.product_id = ftable.product_id
FOR XML PATH(''))  as "characteristics_list"
FROM product
;
