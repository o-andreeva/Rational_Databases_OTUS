USE [int_shop_otus]
GO



---- задаем параметры для пагинации
DECLARE @page_size INT,
@offset_num INT,
@page_num INT

SELECT @page_size = 4, @offset_num = 5, @page_num = 6 ;




---- реализовать по страничную выдачу каталога товаров


    --- window functions method

SELECT *
FROM 
( SELECT c.first_name, c.last_name, c.registration_date, o.date_time as order_date_time , ds.[status] , ROW_NUMBER() OVER (ORDER BY o.date_time) as row_num
FROM client_order as o
INNER JOIN client as c ON o.client_id = c.client_id
INNER JOIN delivery_status as ds on ds.id = o.order_delivery_status_id) as co
WHERE  row_num > @offset_num AND row_num <= @page_size + @offset_num;

    

	--- offset method

SELECT c.first_name, c.last_name, c.registration_date, o.date_time as order_date_time,  ds.[status]
FROM client_order as o
INNER JOIN client as c ON o.client_id = c.client_id
INNER JOIN delivery_status as ds on ds.id = o.order_delivery_status_id
ORDER BY o.date_time
OFFSET ((@page_num  - 1) * @page_size) ROWS
FETCH NEXT @page_size ROWS ONLY;




---- перестроить демонстрацию иерархии категорий с помощью рекурсивного CTE 

--- запрос ниже выдает иерархию продукции, последний столбец Level показывает на каком уровне находится иерархия
--- также показывается визуально пложение типа продукта в иерархии (name_hierar), и генерится полный путь к минимальному типу продуткта

WITH prod_hierar(min_type_id, min_type_name, name_hierar,  general_type_name, general_type_id, [level], path_to_product)  AS
	 (
	 SELECT 
	     ph.min_type_id, 
		 ph.min_type_name,
	     CAST (ph.min_type_name AS NVARCHAR (100)),
		 ph.general_type_name,
		 ph.general_type_id,
		 1, 
		 CAST (ph.min_type_name AS NVARCHAR (100))
	 FROM product_hierarcy as ph
	 WHERE ph.general_type_id IS NULL

	UNION ALL
	 
	 SELECT 
         ph1.min_type_id, 
		 ph1.min_type_name,
	     CAST (REPLICATE('|---', [Level]) + ph1.min_type_name  AS NVARCHAR (100)),
		 ph1.general_type_name,
		 ph1.general_type_id, 
		 [level] + 1,
		  CAST (cte.path_to_product + '\' + ph1.min_type_name AS NVARCHAR(100))
	 FROM product_hierarcy as ph1
	 INNER JOIN prod_hierar as cte ON cte.min_type_id = ph1.general_type_id

	 )


 SELECT *
	 FROM prod_hierar;
