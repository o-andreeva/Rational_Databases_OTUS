USE [int_shop_otus]
GO



 ---   ЗАДАНИЕ № 1 : Запросы на встравку данных INSERT VALUES
 
 INSERT INTO dbo.manufacturer (manifact_id, manufact_name, site, country_of_orign,	[description])
 OUTPUT inserted.*
 VALUES (7, 'NewLine',  'NewLine.com', 'Белоруссия', 'Новый производитель ииновационных колготок') ,
(8, 'Долька Апельсина',  'DolkaApelsina.com', 'Маррокко', 'Производитель самых вкусных, настоящих мандаринов и апельсинов') 

 ;

 
 ---- ЗАДАНИЕ № 2 : Запросы на insert с использованием Select

--- Вставка запланированных промо в таблицу, которые больше текущей даты

INSERT INTO dbo.product_promotion
 OUTPUT inserted.*
SELECT product_id,	percentage_promo, start_date_time, end_date_time, response_emp_id,	comment
FROM dbo.promo_planned
WHERE start_date_time >  (SELECT SYSDATETIME());




---- ЗАДАНИЕ № 3 :  Изменение данных UPDATE, UPDATE с использованием JOIN


-- Обновляем rest_quantity с учетом произошедших поставок, выполненых заказов и заказов в обработке от клиентов на текущий момент

UPDATE dbo.product
SET rest_quantity =  prd_rest.rest
OUTPUT  inserted.*
FROM dbo.product
INNER JOIN 
---   здесь собраны все id и остаток по ним (prd_rest)
	(SELECT  suplied_products.product_id as prd_id, ISNULL(suplied_products.sup_qua, 0) - ISNULL(sold_products.ord_qua, 0) as rest
	FROM 
		--- здесь собраны все продукты и фактические поставки по ним (сумма по количеству)
		(SELECT p.product_id , SUM(i.quantity) AS sup_qua
		FROM dbo.product AS p
		INNER JOIN dbo.products_in_supply_order AS i ON i.product_id  = p.product_id
		INNER JOIN dbo.supply AS s ON s.supply_id = i.supply_id
		INNER JOIN dbo.supply_status_id AS ord_sp ON ord_sp.status_id = s.status_id
		WHERE  ord_sp.status_name = 'Доставлено'
		GROUP BY  p.product_id )  AS suplied_products

	LEFT JOIN -- так как могут быть поставленные продукты для продажи, но не разу ещё не купленные, они должны попасть в таблицу с остатками, поэтому не INNER JOIN

	      --- здесь собраны все продукты, выполенные заказы и обрабатываемые по ним (сумма по количеству)
		(SELECT p.product_id , SUM(i.quantity) AS ord_qua
		FROM dbo.product AS p
		INNER JOIN dbo.items_in_order AS i ON p.product_id = i.product_id
		INNER JOIN dbo.client_order AS o ON o.order_id = i.order_id
		INNER JOIN dbo.delivery_status AS ord_st ON ord_st.id = o.order_delivery_status_id
		WHERE ord_st.[status] <> 'Отмена'
		GROUP BY  p.product_id)  AS sold_products 

	ON suplied_products.product_id =  sold_products.product_id )    
	AS prd_rest

ON  prd_rest.prd_id = dbo.product.product_id 
 -- добавляем условие, что обновление должно происходить только если сохранненое значение отличается от вычисленного
 -- таким образом уменьшаем кол-во блокировок таблицы и обновляем только то, что действительно изменилось.
WHERE rest_quantity <>  prd_rest.rest ;


 -- UPDATE current_promо - актуализируем текущие промо по продукту в столбце current_promo. Если промо попадает в промежуток дат, то столбец current_promo в таблице Product обновляется 
 -- Возможно недетермитированное обновление (если по одному продукту 2 промо в настоящий момент) поэтому используется оконная функция - отбирается последнее значение промо в выборке по id
 -- Чтобы предупредить недетерминированное обновление, выбираем только те у которых наибольшая дата старта и наименьшая дата окончания 
 -- т.е. если промо на продукт будет идти 19 год в размере 5% и на этот же продукт в июле 19 будет промо в размере 10% - запрос обновления проставит 10 процентов и июле, и будет ставить 5% - остальное время

 UPDATE dbo.product 
 SET product.current_promo = promo.last_val
 OUTPUT  inserted.*
 FROM  
	(SELECT DISTINCT product_id, LAST_VALUE(percentage_promo) OVER(PARTITION BY product_id ORDER BY start_date_time ASC, end_date_time DESC
	ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) as last_val
	FROM  dbo.product_promotion
	WHERE  start_date_time < GETDATE()  and end_date_time >  GETDATE()
	) AS promo
WHERE promo.product_id = product.product_id  AND  product.current_promo <> promo.last_val;



----- ЗАДАНИЕ № 4 : Delete

DELETE dbo.manufacturer
 OUTPUT Deleted.*
WHERE manifact_id = 7 or manifact_id = 8;

 -- очищаем таблицу промоакций от будущих промо
DELETE dbo.product_promotion
 OUTPUT Deleted.*
WHERE  start_date_time > (select SYSDATETIME());



----- Merge – потренироваться и прочувствовать

MERGE dbo.distributor as t
USING (select * FROM dbo.updated_new_distributors) as s
ON  (t.dist_id = s.dist_id)

WHEN MATCHED THEN UPDATE SET
 t.[name] = s.[name],
 t.general_address = s.general_address,
 t.general_phone = s.general_phone,
 t.min_order_money = s.min_order_money,
 t.min_supply_days = s.min_supply_days,
 t.max_supply_days = s.max_supply_days,
 t.[site] = s.[site]

WHEN NOT MATCHED THEN 
    INSERT VALUES(s.dist_id, s.[name], s.general_address, s.general_phone, s.min_order_money, s.min_supply_days, s.max_supply_days, s.[site])

OUTPUT $action AS [Операция], inserted.*;
