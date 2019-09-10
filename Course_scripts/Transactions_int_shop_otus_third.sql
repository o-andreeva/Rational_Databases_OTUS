

USE int_shop_otus
GO


--- ���������� - ����� �������� ������ �� �������� / �� ���������.
--- ����������: 1) ������ �� ����� �������� ������ ������, ��� ���� � �������
---- 2) ��� � ����� �������� �������������� ����� ������������, �� ������ �������� ������, ��� ���� � �������, � ���� ������, ������ ��������� ����� ��� ������� ����� �������� ��� � rest_quantity � ������� product ��������� �������� �������� ���-�� ��������, ������� ���� � ��������

--- ����� ������� �������� � ���������� ������ (3 �������) :
--- product - ������� rest_quantity
--- items_in_order - ���������� ����� ������ � ���������� ���������� ���������� SKU (�� ����� ��������� ������� �����, �������)
--- client_order - ���������� ������ ������. 


--- �������
--- ����� ��������� �������� Rest of Product ��� ������� ���������� (� �������� ���� � ������ � ������ �������), �� ������ ��������� �� ������ ������� rest � ������� Product, �� � ������, ������� ��������� ������������ ������ ���������� �� �����


  --- ������ �������, ���� ����� ����������� ��� ������ � �������� ������ �� ���� ������� ����������
  --- ����� ���������� ����������, �� ��� ������� ��� ������� ���������� ������ �� items_for_ordering, rest � ������� �� ���������� Product �����������, 
  --- ��� ������ ����������, �.�. ����� Rest �� �������� ����� ������, ������� ������������ ������ ������� ����������������, - ���������� ���������� � ������� ������ ����� ������ ����, �� ����� ������� ��� �������, ��� ��� ���������� ������������ � ��������, ����������� � ����������, ��� �� items_for_ordering




DROP TABLE IF EXISTS items_for_ordering;


---- ������� � ������� �� ������ �������� (������� �������, ������� ������ ����������� ������������ �� �����). 

CREATE TABLE [dbo].[items_for_ordering](
	[product_id] [int] NOT NULL,
	[price] [numeric](8, 2) NOT NULL,
	[promo_percentage] [numeric](4, 2) NOT NULL,    
	[quantity] [int] NOT NULL,
	[user_id] [int]  NOT NULL )


---- �������� ����� ������� ���������� ���� ��� �����-�� ����, ������� ���� ��������� � ������ ������
--- � ����� ������������ ���������� ���� ������
------ �� ����� ��� ���������� ����� ������ ��� ������� 10
INSERT INTO items_for_ordering (product_id, price, promo_percentage, quantity, [user_id])
VALUES(  '1', '150','0','1', '10'),
      (  '2', '90', '0','1', '10' )


----  � ��� ������ ������������� ��� ������������,  �� ����� ������ "�������� �����". ��� ���� ������� ����������.
--- ������� ������� �� �������� � id = 1 , ����� 36, � �� �������� � id=2 ������� ����� 9
---  ���� �� � ��������� ������ �������� �� 8, � 9 - ���������� ���������� ����������� 
INSERT INTO items_for_ordering (product_id, price, promo_percentage, quantity, [user_id])
VALUES( '1', '150', '0', '2' , '2'),
      ('2', '90', '0', '9' , '2')




---  �� �������� ���������� � ������ � ������ �� ����������

BEGIN TRY 

BEGIN TRANSACTION 

---- �������� ����� id ������������� ������� ����� ���������� � ����������
DECLARE @user_id INT
SELECT @user_id = 2;


DECLARE @flag INT 


 ---- ���������� �� ���� �� ���� ����� � ������� �������, ������� ����� ������� ���� �������������? ���� ��, �� �� ������ �������� ����������
SELECT  @flag = COUNT(1)
FROM items_for_ordering as ifo
LEFT JOIN product as p ON p.product_id = ifo.product_id
LEFT JOIN (SELECT product_id, SUM(quantity) sum_qua  FROM  items_for_ordering  WHERE user_id <> 2  GROUP BY product_id) as in_ord_filter ON in_ord_filter.product_id = ifo.product_id
WHERE p.rest_quantity - in_ord_filter.sum_qua - ifo.quantity < 0


IF @flag <> 0
    BEGIN 
     ROLLBACK TRANSACTION
	 PRINT '�����/������ �� �������� ������. ������� ����� �������������, ���� ��������� ����������'

	---- ������� ������� � ����������, ������� ������ ������������
	---- ���������� ������������, ������, ������ �� ��������� � ������ ������ (�� ��� ���, ���� ������ �� ������ '�������� �����')
   DELETE FROM items_for_ordering
   WHERE  items_for_ordering.[user_id] = @user_id 

	END
ELSE 
	BEGIN
	
	PRINT '����� ����� ���������'


	---- ��������� rest � product
	 UPDATE product  
	 SET  rest_quantity = rest_quantity - ifo.quantity
	 FROM product
	 INNER JOIN 
	 items_for_ordering as ifo ON ifo.product_id = product.product_id 



	---- ��������� ������ ������
	--- ��������� ����� ����� id ������ ���� ��������

	DECLARE @maxid INT
	SELECT @maxid = MAX(o.order_id) + 1 FROM client_order as o

	INSERT INTO client_order (order_id, date_time, order_pay_status_id, delivery_type, order_delivery_status_id, delivery_address, delivered_date_time, client_id, response_courier_id)
	VALUES( @maxid,  GETDATE(), 1, 0 , 2 , '�������� � 6', NULL, @user_id, NULL )


	---- �������� items in order
	
	INSERT INTO items_in_order (product_id,price, promo_percentage, order_id, quantity )
	SELECT product_id, price, promo_percentage, @maxid, quantity
	FROM items_for_ordering
	WHERE  items_for_ordering.[user_id] = @user_id 

	---- ������� ������� � ����������, ������� ������ ������������
   DELETE FROM items_for_ordering
   WHERE  items_for_ordering.[user_id] = @user_id 

---- �������� ���������
  COMMIT TRANSACTION MyFirstTran

	END


END TRY



--- ���� �� ����� ���������� ������ (���������� ������� � �������) ��������� �����-�� ������
--- ���������� ����������
BEGIN  CATCH
	ROLLBACK
		---- ������� ������� � ����������, ������� ������ ������������, ������� ������ ��, ��� �� ���������� �������� � ����������� �����
		---- ���� ���� ����� ������ �������, �� ������� ����� ���������� 
   DELETE FROM items_for_ordering
   WHERE  items_for_ordering.[user_id] = @user_id 

   PRINT '�������� ������ �� ����� ���������� ������'

END CATCH




------ ���� ���������� ������ �������, ��������� ���� ����� ����, ����� ������� ��� �������  
------ ���������� ���� � ��������� ���������, ��� ��� ��� ��� ����� ���� ����



DELETE FROM items_in_order
WHERE order_id = (SELECT MAX(order_id) FROM client_order)


DELETE FROM client_order 
WHERE order_id = (SELECT MAX(order_id) FROM client_order)


 UPDATE product  
	 SET  rest_quantity = rest_quantity + ifo.quantity
	 FROM product
	 INNER JOIN 
	 items_for_ordering as ifo ON ifo.product_id = product.product_id 


DROP TABLE IF EXISTS items_for_ordering;

