USE int_shop_otus
GO

EXECUTE AS USER = 'MarketingAnalyst'
GO

CREATE TRIGGER add_price_change
ON PRODUCT FOR UPDATE
AS
BEGIN 

	DECLARE @current_user  NVARCHAR(100)
	SELECT @current_user = CURRENT_USER 


	IF  @current_user  = 'MarketingAnalyst' 
	BEGIN

	INSERT INTO price_change(product_id, date_time_change, response_emp_id, price_old_value , price_new_value)
    SELECT  inserted.product_id, CURRENT_TIMESTAMP, 1, deleted.current_price,  inserted.current_price
	FROM inserted
	INNER JOIN deleted on inserted.product_id = deleted.product_id

	END
	
	ELSE ROLLBACK TRAN

END;


UPDATE product
SET current_price =100
WHERE product_id = 1;
