USE int_shop_otus

GO 


------ Обновление столбца date_time первого заказа

--- нет даты первого заказа

UPDATE client 
SET first_order_date_time = NULL
GO 

EXEC sp_update_first_order_date
GO

--- отбираются только значения с NULL и по ним ищется дата первого заказа, если она появилась - UPDATE

---- появились даты
SELECT *
FROM client 


---- каждый день процедура будет данные по столбцу first_order_date_time
----------------------------------------------
----------------------------------------------
----------------------------------------------



------ Триггер на обновление price_change
--- Изменить цену в таблице Product и показать что на строку прибавилось
--- Удалить новую строку

-- текущая цена 40
SELECT *
FROM product
WHERE product_id = 4

----- 37 строк
SELECT COUNT(*) 
FROM price_change

---- Цена обновлена
UPDATE product
SET current_price = 60
WHERE  product_id = 4

--- Изменение колва строк +1
SELECT COUNT(*) 
FROM price_change

---- Демонстрация внесенных изменений
SELECT *
FROM price_change
WHERE product_id = 4

--- Удаляем строку
DELETE FROM price_change
WHERE date_time_change =  (SELECT MAX(date_time_change) FROM  price_change) ---AND product_id = 4




----------------------------------------------
----------------------------------------------
----------------------------------------------



-------------
------    Procedure_promo_update

--- есть таблица с промо и сроками его действия - нужно обновить  current_promo согласно таблице и текущей дате

SELECT *
FROM product

UPDATE product
SET current_promo = 0

UPDATE product
SET current_promo = 0.8
WHERE product_id = 14;
GO

EXEC update_promo


SELECT *
FROM product;



----------------------------------------------
----------------------------------------------
----------------------------------------------


----- Check attributes - Function with User Defined Data type

--- функция для определения ошибок в описании товаров

SELECT product_id, [name],ptm.product_type_name,  dbo.attribute_values_check(product_id) as attr_check
FROM product as p
INNER JOIN prod_type_minimal as ptm
ON  ptm.min_type_id = p.prod_type_id
WHERE  dbo.attribute_values_check(product_id) = 'NO';


----------------------------------------------
----------------------------------------------
----------------------------------------------

----- Procedure for att_val with mistakes


--- Объявлем табличную переменную, где будем хранить id и названия продуктов, по которым нужно найти неверные значения аттрибутов
DECLARE @product_id_to_check AS product_id_to_check ;

	
---- вставляем в таблицу значения, которые выдает функция.  

INSERT INTO  @product_id_to_check(product_id, product_name)
SELECT product_id, [name] as product_name
FROM product as p
--- выбираем только те продукты, которые не проходят проверку
WHERE  dbo.attribute_values_check(product_id) = 'NO';

--- Выпоняем процедуру, передавая в неё таблицу с определенным нами типом данных
EXEC dbo.p_att_val_with_error @product_id_to_check



----------------------------------------------
----------------------------------------------
----------------------------------------------

---sp_update_product_rest
--- обновление рест продукта с учетом закупок и продажи

UPDATE product
SET rest_quantity = 0
GO 


EXEC sp_update_product_rest


SELECT *
FROM product



----------------------------------------------
----------------------------------------------
----------------------------------------------

--------- Transactions_int_shop_otus_third