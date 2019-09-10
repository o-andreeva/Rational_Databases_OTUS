USE int_shop_otus

GO 


------ ���������� ������� date_time ������� ������

--- ��� ���� ������� ������

UPDATE client 
SET first_order_date_time = NULL
GO 

EXEC sp_update_first_order_date
GO

--- ���������� ������ �������� � NULL � �� ��� ������ ���� ������� ������, ���� ��� ��������� - UPDATE

---- ��������� ����
SELECT *
FROM client 


---- ������ ���� ��������� ����� ������ �� ������� first_order_date_time
----------------------------------------------
----------------------------------------------
----------------------------------------------



------ ������� �� ���������� price_change
--- �������� ���� � ������� Product � �������� ��� �� ������ �����������
--- ������� ����� ������

-- ������� ���� 40
SELECT *
FROM product
WHERE product_id = 4

----- 37 �����
SELECT COUNT(*) 
FROM price_change

---- ���� ���������
UPDATE product
SET current_price = 60
WHERE  product_id = 4

--- ��������� ����� ����� +1
SELECT COUNT(*) 
FROM price_change

---- ������������ ��������� ���������
SELECT *
FROM price_change
WHERE product_id = 4

--- ������� ������
DELETE FROM price_change
WHERE date_time_change =  (SELECT MAX(date_time_change) FROM  price_change) ---AND product_id = 4




----------------------------------------------
----------------------------------------------
----------------------------------------------



-------------
------    Procedure_promo_update

--- ���� ������� � ����� � ������� ��� �������� - ����� ��������  current_promo �������� ������� � ������� ����

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

--- ������� ��� ����������� ������ � �������� �������

SELECT product_id, [name],ptm.product_type_name,  dbo.attribute_values_check(product_id) as attr_check
FROM product as p
INNER JOIN prod_type_minimal as ptm
ON  ptm.min_type_id = p.prod_type_id
WHERE  dbo.attribute_values_check(product_id) = 'NO';


----------------------------------------------
----------------------------------------------
----------------------------------------------

----- Procedure for att_val with mistakes


--- �������� ��������� ����������, ��� ����� ������� id � �������� ���������, �� ������� ����� ����� �������� �������� ����������
DECLARE @product_id_to_check AS product_id_to_check ;

	
---- ��������� � ������� ��������, ������� ������ �������.  

INSERT INTO  @product_id_to_check(product_id, product_name)
SELECT product_id, [name] as product_name
FROM product as p
--- �������� ������ �� ��������, ������� �� �������� ��������
WHERE  dbo.attribute_values_check(product_id) = 'NO';

--- �������� ���������, ��������� � �� ������� � ������������ ���� ����� ������
EXEC dbo.p_att_val_with_error @product_id_to_check



----------------------------------------------
----------------------------------------------
----------------------------------------------

---sp_update_product_rest
--- ���������� ���� �������� � ������ ������� � �������

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