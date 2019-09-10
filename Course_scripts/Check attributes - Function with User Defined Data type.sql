USE int_shop_otus

GO 


--- в Интернет магазинах нередка ситуация, когда наблюдаются ошибки в описании продуктов. ( 2 000 000 гб опративной памяти, Страна производства Омерика)
--- Данная БД смоделирована так, чтобы избежать таких моментов. Исходим из предположения, что если взять самое нижнее звено в иерархии категорий продуктов (яблоки), то аттрибуты у такого звена будут одинаковами. Если брать соседние звенья иерархии, то у них могут быть как и совпадающие атрибуты (страна производства у телефонов и яблок) так и несовпадающие.
--- Такой аттрибут как "Страна произодства", хоть и может быть одинаков для яблок и мобильных телефонов, но при этом будет иметь разный диапазон значений. Очевидно, что есть страны, где производятся телефоны, но не производятся яблоки. Т.Е Страна производства 'Молдавия' не будет верна для мобильных телефонов, но будет верна для яблок. При проверке это важно учесть.
--- Поэтому в базе есть 
	--- Таблица с самой низкой категорией продукта prod_type_minimal
	--- Таблица со списком возможных аттрибутов attributes, в которой также отмечено, какой тип данных должен содержать тот или иной атрибут (числовой, текстовый и прочее)
    --- Таблица со значениями аттрибутов продуктов attribute_value (связывает между собой аттрибут&тип и конкретный продукт)
	--- Таблица attributes_check, которая содержит все возможные значения, для каждого аттрибута&типа. Так как мы берем во внимание тип продукта, то 'яблоки&страна произодства' и 'телефоны&страна производства' то список стран будет различаться
	--- И главная таблица type_attributes_list, которая связывает между собой минимальный тип и значения аттрибутов
--- Данный кейс важен для поддержания качества данных в БД

--- В чем идея функции ниже?
--- Проверить по id продукта есть ли хоть какое-то отклонение по какому-либо значию аттрибута. При этом нам нужно проверить все типы аттрибутов - текстовый, численный, даты. (кроме типа Free Text, где нет детерминированного списка). В конце выполнения функции нам нужно просто получить ответ все ли ок с продуктом (с его значениями аттрибутов) или есть проблема.


DROP FUNCTION  IF EXISTS dbo.attribute_values_check;
GO

DROP TYPE IF EXISTS flag_for_prod_with_wrong_att_val 
GO

--- создаем User defined тип данных, который будет возвращать функция. (Значения 'OK' или "NO")
CREATE TYPE flag_for_prod_with_wrong_att_val FROM NVARCHAR(2) 
GO


DROP VIEW IF EXISTS all_att_val_prod_mached;
GO

--- дабы не создавать повторений кусков кода - создаем VIEW, которое будет использоваться в функции
CREATE VIEW all_att_val_prod_mached AS
SELECT tal.type_attribute_id, p.product_id, p.[name] as product_name,  ptm.min_type_id, ptm.product_type_name, a.attr_id, a.[name] as attr_name, att.technical_id, att.[name] as val_type, av.value_text , av.value_num, av.value_date
FROM attributes AS a
INNER JOIN attribute_type_general AS atg ON a.type_id_general = atg.general_id 
INNER JOIN attribute_type_technical AS att ON  a.type_id_technical = att.technical_id
INNER JOIN type_attributes_list AS tal ON tal.attr_id = a.attr_id
INNER JOIN prod_type_minimal AS ptm ON ptm.min_type_id = tal.min_type_id
INNER JOIN attribute_value AS av ON av.type_attribute_id = tal.type_attribute_id
INNER JOIN product AS p ON av.product_id = p.product_id;
GO



----- создаем функцию, которая принимая на вход id продукта, показывает все ли заполненные атрибуты у него корректны 


CREATE FUNCTION dbo.attribute_values_check(@product_id INT)
RETURNS  flag_for_prod_with_wrong_att_val 
AS
BEGIN 

--- Создаем переменную flag если значение OK, то значит все значения аттрибута у продукта корректные, Если хоть в одном ошибка - значение 'NO'
DECLARE @flag flag_for_prod_with_wrong_att_val

---- мы проверяем продукт, есть ли проблема с присвоенными значениями аттрибутов
---- Сначала текстовые значения, потом числовые значения, и последними даты
---- для оптимального выполнения запроса мы используем CASE WHEN, если находится ошибка в тексте ('Рассия') - проверка числовых аттрибутов и аттрибутов даты не выполняется 

SELECT @flag =  
	CASE WHEN EXISTS
		(
		SELECT 1
		FROM 
		(SELECT type_attribute_id,product_id, product_name, min_type_id, product_type_name, attr_id, attr_name, technical_id,  val_type, value_text , value_num, value_date
		FROM all_att_val_prod_mached
		WHERE val_type = 'List' AND product_id =  @product_id ) as text_table  
		LEFT JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id AND text_table.value_text = att_c.possible_value
		WHERE possible_value IS NULL )

	THEN 'NO'

	 WHEN EXISTS 
		(
		SELECT 1
		FROM 
		(SELECT type_attribute_id,product_id, product_name, min_type_id, product_type_name, attr_id, attr_name, technical_id,  val_type, value_text , value_num, value_date
		FROM all_att_val_prod_mached
		WHERE (val_type = 'Integer' OR val_type = 'Decimal')  AND product_id =  @product_id ) as text_table  
		INNER JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id 
		WHERE value_num <= att_c.min_val_num OR value_num >= att_c.max_val_num )

	THEN 'NO'


	 WHEN EXISTS (

		SELECT  1
		FROM 
		(SELECT type_attribute_id,product_id, product_name, min_type_id, product_type_name, attr_id, attr_name, technical_id,  val_type, value_text , value_num, value_date
		FROM all_att_val_prod_mached
		WHERE val_type = 'Date' AND product_id =  @product_id) as text_table  
		INNER JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id 
		WHERE value_date <= att_c.min_date OR value_date >= att_c.max_date
		)

	THEN 'NO'

	ELSE 'OK'
	END


RETURN  @flag
END;
GO



--- ПРОВЕРКА РАБОТЫ ФУНКЦИИ
--- благодаря этой функции мы находим список продуктов, у которых есть проблемы с именованиями аттрибутов. Всего таких 4 продукта.
--- но непоняно, в каких именно значениях проблема, для этого мы пишем процедуру, но зато мы уже знаем по каким продуктам искать и не будем обрабатывать лишние продукты

SELECT product_id, [name],ptm.product_type_name,  dbo.attribute_values_check(product_id) as attr_check
FROM product as p
INNER JOIN prod_type_minimal as ptm
ON  ptm.min_type_id = p.prod_type_id
WHERE  dbo.attribute_values_check(product_id) = 'NO';

--- мы получили, что у четырех продуктов есть проблемы со значениями аттрибутов, т.е. значения не нашлись в таблице attributes_check
