

USE int_shop_otus
GO


--- Транзакция - заказ клиентом товара на доставку / на самовывоз.
--- Требования: 1) клиент не может заказать товара больше, чем есть в наличии
---- 2) два и более клиентов осуществляющих заказ одновременно, не должны заказать больше, чем есть в наличии, а если точнее, нельзя допустить чтобы был оплачен товар которого нет и rest_quantity в таблице product перестало отражать реальное кол-во продукта, которое есть в магазине

--- Какие таблицы меняются в результате заказа (3 таблицы) :
--- product - столбец rest_quantity
--- items_in_order - появляются новые записи в количестве заказанных уникальных SKU (из каких продуктов состоит заказ, корзина)
--- client_order - появляется строка заказа. 


--- РЕШЕНИЕ
--- чтобы корректно отразить Rest of Product при коммите транзакции (и добавить инфо о заказе в другие таблицы), мы должны учитывать не только текущий rest в таблице Product, но и товары, которые остальные пользователи сейчас заказывают на сайте


  --- создаю таблицу, куда будут сохраняться все товары в процессе заказа со всех текущих транзакций
  --- Когда транзакция закомичена, то она удаляет все успешно заказанные товары из items_for_ordering, rest в таблице по заказанным Product уменьшается, 
  --- при откате транзакции, т.е. когда Rest по продукту минус товары, которые заказываются сейчас другими пользователелями, - заказанное количество в текущем заказе будет меньше нуля, мы также очищаем эту таблицу, так как транзакция откатывается и продукты, участвующие в транзакции, уже не items_for_ordering




DROP TABLE IF EXISTS items_for_ordering;


---- таблица с данными по заказу клиентов (корзина товаров, которые сейчас преобретают пользователи на сайте). 

CREATE TABLE [dbo].[items_for_ordering](
	[product_id] [int] NOT NULL,
	[price] [numeric](8, 2) NOT NULL,
	[promo_percentage] [numeric](4, 2) NOT NULL,    
	[quantity] [int] NOT NULL,
	[user_id] [int]  NOT NULL )


---- допустим перед началом транзакции есть ещё какой-то юзер, который тоже находится в стадии заказа
--- и может одновременно заказывать теже товары
------ на сайте уже производит заказ клиент под номером 10
INSERT INTO items_for_ordering (product_id, price, promo_percentage, quantity, [user_id])
VALUES(  '1', '150','0','1', '10'),
      (  '2', '90', '0','1', '10' )


----  А это данные интересующего нас пользователя,  он нажал кнопку "Оформить заказ". Про нему пройдет транзакция.
--- текущий остаток по продукту с id = 1 , равен 36, а по продукту с id=2 остаток равен 9
---  если мы в последней строке поставим не 8, а 9 - транзакция перестанет выполняться 
INSERT INTO items_for_ordering (product_id, price, promo_percentage, quantity, [user_id])
VALUES( '1', '150', '0', '2' , '2'),
      ('2', '90', '0', '9' , '2')




---  БД получила информацию о заказе и должна ее обработать

BEGIN TRY 

BEGIN TRANSACTION 

---- передаем номер id заказывающего клиента перед тразакцией в переменную
DECLARE @user_id INT
SELECT @user_id = 2;


DECLARE @flag INT 


 ---- существует ли хотя бы один товар в корзине клиента, который может сделать сток отрицательным? Если да, то мы должны прервать транзакцию
SELECT  @flag = COUNT(1)
FROM items_for_ordering as ifo
LEFT JOIN product as p ON p.product_id = ifo.product_id
LEFT JOIN (SELECT product_id, SUM(quantity) sum_qua  FROM  items_for_ordering  WHERE user_id <> 2  GROUP BY product_id) as in_ord_filter ON in_ord_filter.product_id = ifo.product_id
WHERE p.rest_quantity - in_ord_filter.sum_qua - ifo.quantity < 0


IF @flag <> 0
    BEGIN 
     ROLLBACK TRANSACTION
	 PRINT 'Товар/Товары не возможно купить. Остаток будет отрицательный, если выполнить транзакцию'

	---- очищаем таблицу с продуктами, которые сейчас заказываются
	---- транзакция откатывается, значит, товары не находятся в стадии заказа (до тех про, пока клиент не нажмет 'Оформить заказ')
   DELETE FROM items_for_ordering
   WHERE  items_for_ordering.[user_id] = @user_id 

	END
ELSE 
	BEGIN
	
	PRINT 'Заказ можно оформлять'


	---- обновляем rest в product
	 UPDATE product  
	 SET  rest_quantity = rest_quantity - ifo.quantity
	 FROM product
	 INNER JOIN 
	 items_for_ordering as ifo ON ifo.product_id = product.product_id 



	---- добавляем строку заказа
	--- вычисляем какой номер id заказа надо добавить

	DECLARE @maxid INT
	SELECT @maxid = MAX(o.order_id) + 1 FROM client_order as o

	INSERT INTO client_order (order_id, date_time, order_pay_status_id, delivery_type, order_delivery_status_id, delivery_address, delivered_date_time, client_id, response_courier_id)
	VALUES( @maxid,  GETDATE(), 1, 0 , 2 , 'Усиевича д 6', NULL, @user_id, NULL )


	---- добавлем items in order
	
	INSERT INTO items_in_order (product_id,price, promo_percentage, order_id, quantity )
	SELECT product_id, price, promo_percentage, @maxid, quantity
	FROM items_for_ordering
	WHERE  items_for_ordering.[user_id] = @user_id 

	---- очищаем таблицу с продуктами, которые сейчас заказываются
   DELETE FROM items_for_ordering
   WHERE  items_for_ordering.[user_id] = @user_id 

---- коммитим изменения
  COMMIT TRANSACTION MyFirstTran

	END


END TRY



--- Если на этапе оформления заказа (добавления записей в таблицы) возникнет какая-то ошибка
--- откатываем транзакцию
BEGIN  CATCH
	ROLLBACK
		---- очищаем таблицу с продуктами, которые сейчас заказываются, удаляем только то, что не получилось заказать у конкретного юзера
		---- если юзер вновь нажмет закзать, то таблица опять заполнится 
   DELETE FROM items_for_ordering
   WHERE  items_for_ordering.[user_id] = @user_id 

   PRINT 'Возникла ошибка на этапе добавления данных'

END CATCH




------ Если транзакция прошла успешно, запускаем этот кусок кода, чтобы вернуть все обратно  
------ возвращаем базу в привычное состояние, так как это был всего лишь тест



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

