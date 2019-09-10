USE int_shop_otus 
GO

--- �������� ���������, ������� ���������, ������ ��� �������� �����.
--- ��� ���� ������: 
--- 1) �������� ����� � ������� product ������ ����������������� � ������ ��������� ������� product_promotion � ������������� ��� ����� ������ �����
--- 2) ���� ����� �� �������� �����������, �� promo ������ �����������
--- 3) ���� �� ���� ������� �������� ��� �����, �� ������ �������������� ����� � ���������� ��������� �����
---- 4) ���� ����� �������� � ����� �����, �� ������ ���������� ����� ���������� �� ����������������� 


UPDATE product
SET current_promo = 0

UPDATE product
SET current_promo = 0.8
WHERE product_id = 14;
GO


DROP PROCEDURE IF EXISTS update_promo
GO

CREATE PROCEDURE [dbo].[update_promo] AS
BEGIN 

UPDATE product
SET product.current_promo = for_update.new_promo_perc
FROM

(SELECT p.product_id, ISNULL(promo_perc,0) as new_promo_perc
FROM product as p
LEFT JOIN 
	(
	SELECT DISTINCT
	product_id,
	LAST_VALUE(percentage_promo) OVER (PARTITION BY product_id ORDER BY start_date_time ASC, end_date_time DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as promo_perc,
	MAX(start_date_time) OVER (PARTITION BY product_id) as max_start_date,
	MIN(end_date_time) OVER (PARTITION BY product_id) as min_end_date
	FROM
		(SELECT product_id, percentage_promo, start_date_time, end_date_time  FROM product_promotion
		WHERE start_date_time < CURRENT_TIMESTAMP AND end_date_time > CURRENT_TIMESTAMP) as currrent_promo

	) as cur_promo
ON p.product_id = cur_promo.product_id
WHERE p.current_promo <> ISNULL(promo_perc,0) ) as for_update

WHERE for_update.product_id = product.product_id

END;
GO
EXEC update_promo;