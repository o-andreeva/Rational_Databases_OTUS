USE int_shop_otus

GO 

---- в базе есть функция, которая показывает есть ли проблема у продукта со значениями аттрибутов.
---- Но непонятно какие именно это значения, для этого напишем процедуру, которая будет явно будет показывать на values с которыми проблема.

DROP PROCEDURE  IF EXISTS dbo.p_att_val_with_error
GO

DROP TYPE IF EXISTS product_id_to_check 
GO

---- в процедуру мы будем передавать табличную переменную, которая будет содержать id и название продукта
---- Создаем для неё тип
CREATE TYPE product_id_to_check AS TABLE(
product_id INT NOT NULL,
product_name NVARCHAR(80) NOT NULL
)

GO



---- Создаем процедуру. На вход она будем получать таблицу id и названий продуктов
    CREATE PROCEDURE dbo.p_att_val_with_error
	@prod_id AS product_id_to_check READONLY
    AS  
    BEGIN
	

	--- с помошью UNION ALL объединяем результаты трех проверок
		SELECT text_table.type_attribute_id, product_id, product_name,  min_type_id, product_type_name,attr_id, attr_name, technical_id, val_type, value_text , value_num, value_date, min_val_num, max_val_num, max_date, min_date
		FROM 
		( ---- Проверяем текстовые значения
		SELECT tal.type_attribute_id, p.product_id, product_name,  ptm.min_type_id, ptm.product_type_name, a.attr_id, a.[name] as attr_name, att.technical_id, att.[name] as val_type, av.value_text , av.value_num, av.value_date
		FROM attributes AS a
		INNER JOIN attribute_type_technical AS att ON  a.type_id_technical = att.technical_id
		INNER JOIN type_attributes_list AS tal ON tal.attr_id = a.attr_id
		INNER JOIN prod_type_minimal AS ptm ON ptm.min_type_id = tal.min_type_id
		INNER JOIN attribute_value AS av ON av.type_attribute_id = tal.type_attribute_id
		INNER JOIN @prod_id AS p ON av.product_id = p.product_id
		WHERE att.[name] = 'List' ) as text_table  
		LEFT JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id AND text_table.value_text = att_c.possible_value
		WHERE possible_value IS NULL

		UNION ALL 

		SELECT  text_table.type_attribute_id, product_id, product_name,  min_type_id, product_type_name,attr_id, attr_name, technical_id, val_type, value_text , value_num, value_date, min_val_num, max_val_num, max_date, min_date
		FROM 
		( ---- Проверяем численные аттрибуты
		SELECT tal.type_attribute_id, p.product_id, product_name,  ptm.min_type_id, ptm.product_type_name, a.attr_id, a.[name] as attr_name, att.technical_id, att.[name] as val_type, av.value_text , av.value_num, av.value_date
		FROM attributes AS a
		INNER JOIN attribute_type_technical AS att ON  a.type_id_technical = att.technical_id
		INNER JOIN type_attributes_list AS tal ON tal.attr_id = a.attr_id
		INNER JOIN prod_type_minimal AS ptm ON ptm.min_type_id = tal.min_type_id
		INNER JOIN attribute_value AS av ON av.type_attribute_id = tal.type_attribute_id
		INNER JOIN @prod_id AS p ON av.product_id = p.product_id
		WHERE att.[name] = 'Integer' OR att.[name] = 'Decimal') as text_table  
		INNER JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id 
		WHERE value_num <= att_c.min_val_num OR value_num >= att_c.max_val_num 

		UNION ALL 

		SELECT  text_table.type_attribute_id, product_id, product_name,  min_type_id, product_type_name,attr_id, attr_name, technical_id, val_type, value_text , value_num, value_date, min_val_num, max_val_num, max_date, min_date
		FROM 
		( ---- Проверяем аттрибуты дат
		SELECT tal.type_attribute_id, p.product_id,  product_name,  ptm.min_type_id, ptm.product_type_name, a.attr_id, a.[name] as attr_name, att.technical_id, att.[name] as val_type, av.value_text , av.value_num, av.value_date
		FROM attributes AS a
		INNER JOIN attribute_type_technical AS att ON  a.type_id_technical = att.technical_id
		INNER JOIN type_attributes_list AS tal ON tal.attr_id = a.attr_id
		INNER JOIN prod_type_minimal AS ptm ON ptm.min_type_id = tal.min_type_id
		INNER JOIN attribute_value AS av ON av.type_attribute_id = tal.type_attribute_id
		INNER JOIN @prod_id AS p ON av.product_id = p.product_id
		WHERE att.[name] = 'Date') as text_table  
		INNER JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id 
		WHERE value_date <= att_c.min_date OR value_date >= att_c.max_date

    END ;
	GO




----- ПРОВЕРКА ПРОЦЕДУРЫ


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



--- Результат выполнения:
--- Мы видим с каким аттрибутом проблема, как назвается аттрибут, и какое значение имеет ошибочный аттрибут
--- Например, Есть проблема со странами производства - "Кита" - яано недописан Китай. "Новая Зеландия" указана для одного из iPhone - нужно проверить ошибка или такое действительно возможно. Если возможно - обновить attributes_check, чтобы данные начали проходить проверку.
--- Количество мекаписелей - 1 000 000  - явная ошибка данных - необходимо исправление - долно быть в диапазоне от 5 до 30
--- Дата выпуска на рынок 2030-01-01 - явная ошибка в дате.

--- Нам не нужно перелапачивать значения всех аттрибутов всех продуктов, благодаря процедуре мы сразу видим только ошибки.
 
