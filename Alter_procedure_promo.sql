USE [int_shop_otus]
GO
/****** Object:  StoredProcedure [dbo].[update_promo]    Script Date: 05.09.2019 18:05:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[update_promo] AS
BEGIN 


------ Первый вариант

UPDATE product 
SET product.current_promo =  pp.promo_perc
FROM
		(SELECT distinct product_promotion.product_id,
		LAST_VALUE(percentage_promo) OVER (PARTITION BY product_promotion.product_id ORDER BY start_date_time ASC, end_date_time DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as promo_perc
		FROM product_promotion 
		WHERE start_date_time < CURRENT_TIMESTAMP AND
		end_date_time > CURRENT_TIMESTAMP
		) as pp
Where product.product_id = pp.product_id AND 
		pp.promo_perc <> product.current_promo

END;



-----------------
----------------- Второй вариант
-----------------
UPDATE product 
SET product.current_promo = 
		(SELECT DISTINCT
		LAST_VALUE(percentage_promo) OVER (PARTITION BY product_promotion.product_id ORDER BY start_date_time ASC, end_date_time DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as promo_perc
		FROM product_promotion
		WHERE start_date_time < CURRENT_TIMESTAMP AND
		end_date_time > CURRENT_TIMESTAMP AND
		product.product_id = product_promotion.product_id AND 
		product_promotion.percentage_promo <> product.current_promo)
WHERE product.product_id in ( SELECT 
		product_id
		FROM product_promotion
		WHERE start_date_time < CURRENT_TIMESTAMP AND
		end_date_time > CURRENT_TIMESTAMP )



