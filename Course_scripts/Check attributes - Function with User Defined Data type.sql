USE int_shop_otus

GO 


--- � �������� ��������� ������� ��������, ����� ����������� ������ � �������� ���������. ( 2 000 000 �� ���������� ������, ������ ������������ �������)
--- ������ �� ������������� ���, ����� �������� ����� ��������. ������� �� �������������, ��� ���� ����� ����� ������ ����� � �������� ��������� ��������� (������), �� ��������� � ������ ����� ����� �����������. ���� ����� �������� ������ ��������, �� � ��� ����� ���� ��� � ����������� �������� (������ ������������ � ��������� � �����) ��� � �������������.
--- ����� �������� ��� "������ �����������", ���� � ����� ���� �������� ��� ����� � ��������� ���������, �� ��� ���� ����� ����� ������ �������� ��������. ��������, ��� ���� ������, ��� ������������ ��������, �� �� ������������ ������. �.� ������ ������������ '��������' �� ����� ����� ��� ��������� ���������, �� ����� ����� ��� �����. ��� �������� ��� ����� ������.
--- ������� � ���� ���� 
	--- ������� � ����� ������ ���������� �������� prod_type_minimal
	--- ������� �� ������� ��������� ���������� attributes, � ������� ����� ��������, ����� ��� ������ ������ ��������� ��� ��� ���� ������� (��������, ��������� � ������)
    --- ������� �� ���������� ���������� ��������� attribute_value (��������� ����� ����� ��������&��� � ���������� �������)
	--- ������� attributes_check, ������� �������� ��� ��������� ��������, ��� ������� ���������&����. ��� ��� �� ����� �� �������� ��� ��������, �� '������&������ �����������' � '��������&������ ������������' �� ������ ����� ����� �����������
	--- � ������� ������� type_attributes_list, ������� ��������� ����� ����� ����������� ��� � �������� ����������
--- ������ ���� ����� ��� ����������� �������� ������ � ��

--- � ��� ���� ������� ����?
--- ��������� �� id �������� ���� �� ���� �����-�� ���������� �� ������-���� ������ ���������. ��� ���� ��� ����� ��������� ��� ���� ���������� - ���������, ���������, ����. (����� ���� Free Text, ��� ��� ������������������ ������). � ����� ���������� ������� ��� ����� ������ �������� ����� ��� �� �� � ��������� (� ��� ���������� ����������) ��� ���� ��������.


DROP FUNCTION  IF EXISTS dbo.attribute_values_check;
GO

DROP TYPE IF EXISTS flag_for_prod_with_wrong_att_val 
GO

--- ������� User defined ��� ������, ������� ����� ���������� �������. (�������� 'OK' ��� "NO")
CREATE TYPE flag_for_prod_with_wrong_att_val FROM NVARCHAR(2) 
GO


DROP VIEW IF EXISTS all_att_val_prod_mached;
GO

--- ���� �� ��������� ���������� ������ ���� - ������� VIEW, ������� ����� �������������� � �������
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



----- ������� �������, ������� �������� �� ���� id ��������, ���������� ��� �� ����������� �������� � ���� ��������� 


CREATE FUNCTION dbo.attribute_values_check(@product_id INT)
RETURNS  flag_for_prod_with_wrong_att_val 
AS
BEGIN 

--- ������� ���������� flag ���� �������� OK, �� ������ ��� �������� ��������� � �������� ����������, ���� ���� � ����� ������ - �������� 'NO'
DECLARE @flag flag_for_prod_with_wrong_att_val

---- �� ��������� �������, ���� �� �������� � ������������ ���������� ����������
---- ������� ��������� ��������, ����� �������� ��������, � ���������� ����
---- ��� ������������ ���������� ������� �� ���������� CASE WHEN, ���� ��������� ������ � ������ ('������') - �������� �������� ���������� � ���������� ���� �� ����������� 

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



--- �������� ������ �������
--- ��������� ���� ������� �� ������� ������ ���������, � ������� ���� �������� � ������������ ����������. ����� ����� 4 ��������.
--- �� ��������, � ����� ������ ��������� ��������, ��� ����� �� ����� ���������, �� ���� �� ��� ����� �� ����� ��������� ������ � �� ����� ������������ ������ ��������

SELECT product_id, [name],ptm.product_type_name,  dbo.attribute_values_check(product_id) as attr_check
FROM product as p
INNER JOIN prod_type_minimal as ptm
ON  ptm.min_type_id = p.prod_type_id
WHERE  dbo.attribute_values_check(product_id) = 'NO';

--- �� ��������, ��� � ������� ��������� ���� �������� �� ���������� ����������, �.�. �������� �� ������� � ������� attributes_check
