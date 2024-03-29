USE [master]
GO
/****** Object:  Database [int_shop_otus]    Script Date: 10.09.2019 21:28:53 ******/
CREATE DATABASE [int_shop_otus]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'int _shop_otus', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\int _shop_otus.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'int _shop_otus_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\int _shop_otus_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [int_shop_otus] SET COMPATIBILITY_LEVEL = 140
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [int_shop_otus].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [int_shop_otus] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [int_shop_otus] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [int_shop_otus] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [int_shop_otus] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [int_shop_otus] SET ARITHABORT OFF 
GO
ALTER DATABASE [int_shop_otus] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [int_shop_otus] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [int_shop_otus] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [int_shop_otus] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [int_shop_otus] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [int_shop_otus] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [int_shop_otus] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [int_shop_otus] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [int_shop_otus] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [int_shop_otus] SET  DISABLE_BROKER 
GO
ALTER DATABASE [int_shop_otus] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [int_shop_otus] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [int_shop_otus] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [int_shop_otus] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [int_shop_otus] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [int_shop_otus] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [int_shop_otus] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [int_shop_otus] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [int_shop_otus] SET  MULTI_USER 
GO
ALTER DATABASE [int_shop_otus] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [int_shop_otus] SET DB_CHAINING OFF 
GO
ALTER DATABASE [int_shop_otus] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [int_shop_otus] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [int_shop_otus] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [int_shop_otus] SET QUERY_STORE = OFF
GO
USE [int_shop_otus]
GO
/****** Object:  User [MarketingAnalyst]    Script Date: 10.09.2019 21:28:53 ******/
CREATE USER [MarketingAnalyst] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [MarketingAnalyst]
GO
/****** Object:  Schema [production]    Script Date: 10.09.2019 21:28:53 ******/
CREATE SCHEMA [production]
GO
/****** Object:  Schema [sales]    Script Date: 10.09.2019 21:28:53 ******/
CREATE SCHEMA [sales]
GO
/****** Object:  UserDefinedDataType [dbo].[flag_for_prod_with_wrong_att_val]    Script Date: 10.09.2019 21:28:53 ******/
CREATE TYPE [dbo].[flag_for_prod_with_wrong_att_val] FROM [nvarchar](2) NULL
GO
/****** Object:  UserDefinedTableType [dbo].[product_id_to_check]    Script Date: 10.09.2019 21:28:53 ******/
CREATE TYPE [dbo].[product_id_to_check] AS TABLE(
	[product_id] [int] NOT NULL,
	[product_name] [nvarchar](80) NOT NULL
)
GO
/****** Object:  UserDefinedTableType [dbo].[wrong_attr_val_table]    Script Date: 10.09.2019 21:28:53 ******/
CREATE TYPE [dbo].[wrong_attr_val_table] AS TABLE(
	[type_attribute_id] [int] NOT NULL,
	[product_id] [int] NOT NULL,
	[product_name] [nvarchar](80) NOT NULL,
	[min_type_id] [int] NOT NULL,
	[product_type_name] [nvarchar](100) NOT NULL,
	[attr_id] [int] NOT NULL,
	[attr_name] [nvarchar](50) NOT NULL,
	[attr_value_type_id] [int] NOT NULL,
	[attr_value_type_name] [nvarchar](15) NOT NULL,
	[value_text] [nvarchar](15) NULL,
	[value_num] [decimal](9, 2) NULL,
	[value_date] [date] NULL
)
GO
/****** Object:  UserDefinedFunction [dbo].[attribute_values_check]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[attribute_values_check](@product_id INT)
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
		all_att_val_prod_mached as text_table  
		LEFT JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id AND text_table.value_text = att_c.possible_value
		WHERE possible_value IS NULL AND val_type = 'List' AND product_id = @product_id )

	THEN 'NO'

	 WHEN EXISTS 

		(SELECT 1
		FROM 
		all_att_val_prod_mached as text_table  
		LEFT JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id 
		WHERE  (val_type = 'Integer' OR val_type = 'Decimal') AND product_id = @product_id AND (value_num <= att_c.min_val_num OR value_num >= att_c.max_val_num ))


	THEN 'NO'

	 WHEN EXISTS 
	   (SELECT 1
		FROM 
		all_att_val_prod_mached as text_table  
		LEFT JOIN dbo.attributes_check AS att_c
		ON text_table.type_attribute_id = att_c.type_attribute_id 
		WHERE val_type = 'Date' AND product_id = @product_id AND (value_date <= att_c.min_date OR value_date >= att_c.max_date))


	THEN 'NO'

	ELSE 'OK'
	END


RETURN  @flag
END;
GO
/****** Object:  Table [dbo].[prod_type_minimal]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[prod_type_minimal](
	[min_type_id] [int] NOT NULL,
	[product_type_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](1000) NULL,
 CONSTRAINT [PK_prod_type_minimal] PRIMARY KEY CLUSTERED 
(
	[min_type_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[attribute_type_technical]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[attribute_type_technical](
	[technical_id] [tinyint] NOT NULL,
	[name] [nvarchar](15) NULL,
 CONSTRAINT [PK_attribute_type_technical] PRIMARY KEY CLUSTERED 
(
	[technical_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[attribute_value]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[attribute_value](
	[value_text] [nvarchar](50) NULL,
	[value_num] [decimal](9, 2) NULL,
	[value_date] [date] NULL,
	[type_attribute_id] [int] NOT NULL,
	[product_id] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[attributes]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[attributes](
	[attr_id] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[description] [varchar](500) NULL,
	[type_id_general] [tinyint] NOT NULL,
	[type_id_technical] [tinyint] NOT NULL,
	[attr_abbreviation] [varchar](30) NULL,
 CONSTRAINT [PK_attributes] PRIMARY KEY CLUSTERED 
(
	[attr_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[type_attributes_list]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[type_attributes_list](
	[type_attribute_id] [int] NOT NULL,
	[used_in_filter] [bit] NOT NULL,
	[min_type_id] [int] NOT NULL,
	[attr_id] [int] NOT NULL,
 CONSTRAINT [PK_type_attributes_list] PRIMARY KEY CLUSTERED 
(
	[type_attribute_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[product]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product](
	[product_id] [int] NOT NULL,
	[name] [nvarchar](80) NOT NULL,
	[current_price] [numeric](8, 2) NOT NULL,
	[created_at] [datetime] NOT NULL,
	[rest_quantity] [int] NOT NULL,
	[manufact_id] [int] NOT NULL,
	[prod_type_id] [int] NOT NULL,
	[current_promo] [numeric](4, 2) NOT NULL,
 CONSTRAINT [PK__Product] PRIMARY KEY CLUSTERED 
(
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[charactericticsList]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW  [dbo].[charactericticsList] as

Select l.attr_id, a.[name] as attr_name, l.min_type_id, t.product_type_name ,l.type_attribute_id, p.product_id, p.[name] as product_name, at_type.[name] as atrr_type, v.value_date, v.value_num, v.value_text, a.attr_abbreviation
from dbo.type_attributes_list as l
inner join dbo.attributes a on a.attr_id = l.attr_id
INNER JOIN dbo.prod_type_minimal as t on t.min_type_id = l.min_type_id
INNER JOIN dbo.product as p on p.prod_type_id= t.min_type_id
INNER JOIN dbo.attribute_type_technical as at_type on at_type.technical_id=a.type_id_technical
INNER JOIN dbo.attribute_value as v on v.type_attribute_id = l.type_attribute_id and v.product_id = p.product_id
GO
/****** Object:  Table [dbo].[attribute_type_general]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[attribute_type_general](
	[general_id] [tinyint] NOT NULL,
	[name] [nvarchar](15) NULL,
 CONSTRAINT [PK_attribute_type_general] PRIMARY KEY CLUSTERED 
(
	[general_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[all_att_val_prod_mached]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--- дабы не создавать повторений кусков кода - создаем VIEW, которое будет использоваться в функции
CREATE VIEW [dbo].[all_att_val_prod_mached] AS
SELECT tal.type_attribute_id, p.product_id, p.[name] as product_name,  ptm.min_type_id, ptm.product_type_name, a.attr_id, a.[name] as attr_name, att.technical_id, att.[name] as val_type, av.value_text , av.value_num, av.value_date
FROM attributes AS a
INNER JOIN attribute_type_general AS atg ON a.type_id_general = atg.general_id 
INNER JOIN attribute_type_technical AS att ON  a.type_id_technical = att.technical_id
INNER JOIN type_attributes_list AS tal ON tal.attr_id = a.attr_id
INNER JOIN prod_type_minimal AS ptm ON ptm.min_type_id = tal.min_type_id
INNER JOIN attribute_value AS av ON av.type_attribute_id = tal.type_attribute_id
INNER JOIN product AS p ON av.product_id = p.product_id;
GO
/****** Object:  Table [dbo].[attributes_check]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[attributes_check](
	[type_attribute_id] [int] NOT NULL,
	[possible_value] [nvarchar](50) NULL,
	[max_val_num] [decimal](9, 2) NULL,
	[min_val_num] [decimal](9, 2) NULL,
	[max_date] [date] NULL,
	[min_date] [date] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[client]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[client](
	[client_id] [int] NOT NULL,
	[first_name] [nvarchar](50) NOT NULL,
	[last_name] [nvarchar](50) NOT NULL,
	[email] [nvarchar](320) NOT NULL,
	[password] [nvarchar](50) NOT NULL,
	[phone] [nvarchar](50) NOT NULL,
	[phone_2] [nvarchar](50) NULL,
	[address] [nvarchar](100) NULL,
	[registration_date] [date] NOT NULL,
	[gender_id] [tinyint] NULL,
	[first_order_date_time] [datetime2](7) NULL,
 CONSTRAINT [PK_client] PRIMARY KEY CLUSTERED 
(
	[client_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[client_order]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[client_order](
	[order_id] [int] NOT NULL,
	[date_time] [datetime] NOT NULL,
	[order_pay_status_id] [tinyint] NOT NULL,
	[delivery_type] [bit] NOT NULL,
	[order_delivery_status_id] [tinyint] NOT NULL,
	[delivery_address] [nvarchar](110) NOT NULL,
	[delivered_date_time] [datetime] NULL,
	[client_id] [int] NOT NULL,
	[response_courier_id] [int] NULL,
 CONSTRAINT [PK_order] PRIMARY KEY CLUSTERED 
(
	[order_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[delivery_status]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[delivery_status](
	[id] [tinyint] NOT NULL,
	[status] [nvarchar](50) NULL,
 CONSTRAINT [PK_delivery_status] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[distributor]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[distributor](
	[dist_id] [smallint] NOT NULL,
	[name] [nvarchar](80) NOT NULL,
	[general_address] [nvarchar](100) NOT NULL,
	[general_phone] [nvarchar](50) NOT NULL,
	[min_order_money] [money] NOT NULL,
	[min_supply_days] [tinyint] NOT NULL,
	[max_supply_days] [tinyint] NOT NULL,
	[site] [nvarchar](80) NULL,
 CONSTRAINT [PK_distributor] PRIMARY KEY CLUSTERED 
(
	[dist_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[distributor_contact]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[distributor_contact](
	[dist_employ_id] [int] NOT NULL,
	[fist_name] [nvarchar](50) NULL,
	[last_name] [nvarchar](50) NULL,
	[working_phone_number] [nvarchar](50) NULL,
	[email] [nvarchar](320) NULL,
	[position] [nvarchar](60) NULL,
	[gender] [tinyint] NULL,
	[dist_id] [smallint] NULL,
 CONSTRAINT [PK_distributor_contact] PRIMARY KEY CLUSTERED 
(
	[dist_employ_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[items_in_order]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[items_in_order](
	[product_id] [int] NOT NULL,
	[price] [numeric](8, 2) NOT NULL,
	[promo_percentage] [numeric](4, 2) NOT NULL,
	[order_id] [int] NOT NULL,
	[quantity] [int] NOT NULL,
 CONSTRAINT [PK_items_in_order] PRIMARY KEY CLUSTERED 
(
	[product_id] ASC,
	[order_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[manufacturer]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[manufacturer](
	[manifact_id] [int] NOT NULL,
	[manufact_name] [nvarchar](60) NOT NULL,
	[site] [nvarchar](50) NULL,
	[country_of_orign] [nvarchar](35) NOT NULL,
	[description] [nvarchar](1000) NULL,
 CONSTRAINT [PK__Manufact] PRIMARY KEY CLUSTERED 
(
	[manifact_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[payment_status]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[payment_status](
	[id] [tinyint] NOT NULL,
	[status] [nvarchar](50) NULL,
 CONSTRAINT [PK_payment_status] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[price_change]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[price_change](
	[product_id] [int] NOT NULL,
	[date_time_change] [datetime] NOT NULL,
	[response_emp_id] [int] NOT NULL,
	[price_old_value] [numeric](8, 2) NOT NULL,
	[price_new_value] [numeric](8, 2) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[product_hierarcy]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product_hierarcy](
	[min_type_id] [int] NOT NULL,
	[min_type_name] [nvarchar](80) NULL,
	[general_type_id] [int] NULL,
	[general_type_name] [nvarchar](80) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[product_promotion]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product_promotion](
	[product_id] [int] NOT NULL,
	[percentage_promo] [numeric](4, 2) NOT NULL,
	[start_date_time] [datetime] NOT NULL,
	[end_date_time] [datetime] NOT NULL,
	[response_emp_id] [int] NOT NULL,
	[comment] [nvarchar](150) NOT NULL,
 CONSTRAINT [PK_product_promotion] PRIMARY KEY CLUSTERED 
(
	[product_id] ASC,
	[start_date_time] ASC,
	[end_date_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[products_in_supply_order]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[products_in_supply_order](
	[product_id] [int] NOT NULL,
	[supply_id] [int] NOT NULL,
	[quantity] [smallint] NOT NULL,
	[suplier_price] [money] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[promo_planned]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[promo_planned](
	[product_id] [int] NOT NULL,
	[percentage_promo] [numeric](4, 2) NOT NULL,
	[start_date_time] [datetime] NOT NULL,
	[end_date_time] [datetime] NOT NULL,
	[response_emp_id] [int] NOT NULL,
	[comment] [nvarchar](150) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[responsible_courier]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[responsible_courier](
	[courier_id] [int] NOT NULL,
	[first_name] [nvarchar](50) NOT NULL,
	[last_name] [nvarchar](50) NOT NULL,
	[employ_status_id] [tinyint] NOT NULL,
	[phone] [nvarchar](50) NOT NULL,
	[first_working_day] [date] NOT NULL,
	[last_working_day] [date] NULL,
 CONSTRAINT [PK_responsible_courier] PRIMARY KEY CLUSTERED 
(
	[courier_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[review]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[review](
	[review_id] [int] NOT NULL,
	[client_review_text] [nvarchar](2000) NULL,
	[mark_id] [tinyint] NULL,
	[anonymously] [bit] NULL,
	[date] [timestamp] NULL,
	[product_id] [int] NULL,
	[order_id] [int] NULL,
 CONSTRAINT [PK_review] PRIMARY KEY CLUSTERED 
(
	[review_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[supply]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[supply](
	[supply_id] [int] NOT NULL,
	[start_date_time] [datetime] NOT NULL,
	[end_date_time] [datetime] NULL,
	[status_id] [tinyint] NOT NULL,
	[dist_id] [smallint] NOT NULL,
	[response_id] [int] NOT NULL,
 CONSTRAINT [PK_supply] PRIMARY KEY CLUSTERED 
(
	[supply_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[supply_status_id]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[supply_status_id](
	[status_id] [tinyint] NOT NULL,
	[status_name] [nvarchar](50) NULL,
 CONSTRAINT [PK_supply_status_id] PRIMARY KEY CLUSTERED 
(
	[status_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[updated_new_distributors]    Script Date: 10.09.2019 21:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[updated_new_distributors](
	[dist_id] [smallint] NOT NULL,
	[name] [nvarchar](80) NOT NULL,
	[general_address] [nvarchar](100) NOT NULL,
	[general_phone] [nvarchar](50) NOT NULL,
	[min_order_money] [money] NOT NULL,
	[min_supply_days] [tinyint] NOT NULL,
	[max_supply_days] [tinyint] NOT NULL,
	[site] [nvarchar](80) NULL
) ON [PRIMARY]
GO
INSERT [dbo].[attribute_type_general] ([general_id], [name]) VALUES (1, N'Text')
INSERT [dbo].[attribute_type_general] ([general_id], [name]) VALUES (2, N'Number')
INSERT [dbo].[attribute_type_general] ([general_id], [name]) VALUES (3, N'Date')
INSERT [dbo].[attribute_type_technical] ([technical_id], [name]) VALUES (1, N'Free Text')
INSERT [dbo].[attribute_type_technical] ([technical_id], [name]) VALUES (2, N'Integer')
INSERT [dbo].[attribute_type_technical] ([technical_id], [name]) VALUES (3, N'Decimal')
INSERT [dbo].[attribute_type_technical] ([technical_id], [name]) VALUES (4, N'Date')
INSERT [dbo].[attribute_type_technical] ([technical_id], [name]) VALUES (5, N'List')
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Кита', NULL, NULL, 10, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(6.60 AS Decimal(9, 2)), NULL, 11, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(4000.00 AS Decimal(9, 2)), NULL, 12, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'IOS', NULL, NULL, 13, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(120.00 AS Decimal(9, 2)), NULL, 14, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(128.00 AS Decimal(9, 2)), NULL, 15, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, NULL, CAST(N'2019-01-01' AS Date), 16, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(2.00 AS Decimal(9, 2)), NULL, 17, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(16.00 AS Decimal(9, 2)), NULL, 18, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 19, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'нет', NULL, NULL, 20, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'138,4 мм 67,3 мм 7,3 мм', NULL, NULL, 21, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Серебристый', NULL, NULL, 42, 7)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Серебристый', NULL, NULL, 42, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'нет', NULL, NULL, 20, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'138,4 мм 67,3 мм 7,3 мм', NULL, NULL, 21, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 19, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(16.00 AS Decimal(9, 2)), NULL, 18, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(2.00 AS Decimal(9, 2)), NULL, 17, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, NULL, CAST(N'2019-01-01' AS Date), 16, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(32.00 AS Decimal(9, 2)), NULL, 15, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(8.00 AS Decimal(9, 2)), NULL, 14, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'IOS', NULL, NULL, 13, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(4000.00 AS Decimal(9, 2)), NULL, 12, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(10.00 AS Decimal(9, 2)), NULL, 11, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Новая Зеландия', NULL, NULL, 10, 9)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(10.00 AS Decimal(9, 2)), NULL, 11, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(4000.00 AS Decimal(9, 2)), NULL, 12, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'IOS', NULL, NULL, 13, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(8.00 AS Decimal(9, 2)), NULL, 14, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Китай ', NULL, NULL, 10, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(64.00 AS Decimal(9, 2)), NULL, 15, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, NULL, CAST(N'2030-01-01' AS Date), 16, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(2.00 AS Decimal(9, 2)), NULL, 17, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(16.00 AS Decimal(9, 2)), NULL, 18, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 19, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'нет', NULL, NULL, 20, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'138,4 мм 67,3 мм 7,3 мм', NULL, NULL, 21, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Серебристый', NULL, NULL, 42, 8)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Черный', NULL, NULL, 42, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 20, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'158,4 мм 77,3 мм 8,3 мм', NULL, NULL, 21, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'нет', NULL, NULL, 19, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(1000000.00 AS Decimal(9, 2)), NULL, 18, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(3.00 AS Decimal(9, 2)), NULL, 17, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, NULL, CAST(N'2019-01-01' AS Date), 16, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(128.00 AS Decimal(9, 2)), NULL, 15, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(16.00 AS Decimal(9, 2)), NULL, 14, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Android', NULL, NULL, 13, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(5000.00 AS Decimal(9, 2)), NULL, 12, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(12.50 AS Decimal(9, 2)), NULL, 11, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Китай ', NULL, NULL, 10, 10)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(990.00 AS Decimal(9, 2)), NULL, 38, 15)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(2015.00 AS Decimal(9, 2)), NULL, 39, 15)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Русский', NULL, NULL, 40, 15)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Мягкая', NULL, NULL, 36, 15)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Тодди Мак Грегор', NULL, NULL, 37, 15)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Мягкая', NULL, NULL, 35, 13)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Россия', NULL, NULL, 31, 13)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(90.00 AS Decimal(9, 2)), NULL, 32, 13)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'A3', NULL, NULL, 33, 13)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'В линейку', NULL, NULL, 34, 13)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Без оформления', NULL, NULL, 34, 14)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'A2', NULL, NULL, 33, 14)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(120.00 AS Decimal(9, 2)), NULL, 32, 14)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Россия', NULL, NULL, 31, 14)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Твердая', NULL, NULL, 35, 14)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Мягкая', NULL, NULL, 36, 17)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Светлана Светлитская', NULL, NULL, 37, 17)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(450.00 AS Decimal(9, 2)), NULL, 38, 17)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(2018.00 AS Decimal(9, 2)), NULL, 39, 17)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Русский', NULL, NULL, 40, 17)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Израиль', NULL, NULL, 4, 6)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Пакет', NULL, NULL, 5, 6)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(20.20 AS Decimal(9, 2)), NULL, 6, 6)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Русский', NULL, NULL, 40, 16)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(2019.00 AS Decimal(9, 2)), NULL, 39, 16)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(700.00 AS Decimal(9, 2)), NULL, 38, 16)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Арнджей Мурат', NULL, NULL, 37, 16)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Твердая', NULL, NULL, 36, 16)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Россия', NULL, NULL, 1, 4)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Пакет', NULL, NULL, 2, 4)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(10.00 AS Decimal(9, 2)), NULL, 3, 4)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(20.00 AS Decimal(9, 2)), NULL, 3, 5)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Пакет', NULL, NULL, 2, 5)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Израиль', NULL, NULL, 1, 5)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(81.00 AS Decimal(9, 2)), NULL, 22, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'1920x1080', NULL, NULL, 23, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 24, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(2.00 AS Decimal(9, 2)), NULL, 25, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 26, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 27, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'DVIx2, USBx4, AVI', NULL, NULL, 28, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(4.00 AS Decimal(9, 2)), NULL, 29, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'48.8*73*20.7 см', NULL, NULL, 30, 11)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'58.8*79*30.7 см', NULL, NULL, 30, 12)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(16.00 AS Decimal(9, 2)), NULL, 29, 12)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'DVIx2, USBx4, Cart Rider', NULL, NULL, 28, 12)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 27, 12)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'да', NULL, NULL, 26, 12)
GO
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(3.00 AS Decimal(9, 2)), NULL, 25, 12)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'нет', NULL, NULL, 24, 12)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'720x1020', NULL, NULL, 23, 12)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (NULL, CAST(110.00 AS Decimal(9, 2)), NULL, 22, 12)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Греция', NULL, NULL, 7, 1)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Корзина', NULL, NULL, 8, 1)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Средние', NULL, NULL, 9, 1)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Желтые', NULL, NULL, 41, 1)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Красные', NULL, NULL, 41, 2)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Крупные', NULL, NULL, 9, 2)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Пакет', NULL, NULL, 8, 2)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Россия', NULL, NULL, 7, 2)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Россия', NULL, NULL, 7, 3)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Короб', NULL, NULL, 8, 3)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Мелкие', NULL, NULL, 9, 3)
INSERT [dbo].[attribute_value] ([value_text], [value_num], [value_date], [type_attribute_id], [product_id]) VALUES (N'Зеленые', NULL, NULL, 41, 3)
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (1, N'Страна производства', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (2, N'фасовка', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (3, N'Средняя длина плода', N'Not Assigned', 2, 3, N'см')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (4, N'Средний диаметр плода', N'Not Assigned', 2, 3, N'см')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (5, N'размер плода', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (6, N'Диагональ Экрана', N'Not Assigned', 2, 3, N'см')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (7, N'Объем батареи', N'Not Assigned', 2, 2, N'mAч')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (8, N'Операционная система', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (9, N'Оперативная память', N'Not Assigned', 2, 2, N'ГБ')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (10, N'Встроенная память', N'Not Assigned', 2, 2, N'ГБ')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (11, N'Дата выпуска на рынок', N'Not Assigned', 3, 4, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (12, N'Количество камер', N'Not Assigned', 2, 2, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (13, N'Количество мегапикселей', N'Not Assigned', 2, 2, N'MP')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (14, N'Вторая SIM', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (15, N'Наличие карты памяти', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (16, N'Размеры', N'Not Assigned', 1, 1, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (17, N'Разрешение экрана', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (18, N'Поддержка 3D', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (19, N'Количество HDMI', N'Not Assigned', 2, 2, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (20, N'Наличие  Wi-Fi', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (21, N'Наличие Smart TV', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (22, N'Дополнительные разъемы', N'Not Assigned', 1, 1, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (23, N'Количество страниц', N'Not Assigned', 2, 2, N'стр.')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (24, N'Формат', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (25, N'Оформление страниц', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (26, N'Тип Обложки', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (27, N'Автор', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (28, N'Год выпуска', N'Not Assigned', 2, 2, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (29, N'Язык издания', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes] ([attr_id], [name], [description], [type_id_general], [type_id_technical], [attr_abbreviation]) VALUES (30, N'Цвет', N'Not Assigned', 1, 5, N'')
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (1, N'Россия', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (1, N'Израиль', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (2, N'Пакет', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (4, N'Израиль', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (5, N'Пакет', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (7, N'Греция', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (7, N'Россия', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (8, N'Корзина', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (8, N'Пакет', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (8, N'Короб', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (9, N'Средние', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (9, N'Крупные', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (9, N'Мелкие', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (10, N'Китай ', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (13, N'IOS', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (13, N'Android', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (19, N'да', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (19, N'нет', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (20, N'нет', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (20, N'да', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (23, N'1920x1080', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (23, N'720x1020', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (24, N'да', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (24, N'нет', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (26, N'да', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (27, N'да', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (31, N'Россия', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (33, N'A3', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (33, N'A2', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (34, N'В линейку', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (34, N'Без оформления', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (35, N'Мягкая', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (35, N'Твердая', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (36, N'Мягкая', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (36, N'Твердая', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (37, N'Тодди Мак Грегор', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (37, N'Светлана Светлитская', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (37, N'Арнджей Мурат', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (40, N'Русский', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (41, N'Желтые', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (41, N'Красные', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (41, N'Зеленые', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (42, N'Серебристый', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (42, N'Черный', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (26, N'Нет', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (40, N'Английский', NULL, NULL, NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (11, NULL, CAST(15.00 AS Decimal(9, 2)), CAST(2.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (12, NULL, CAST(5000.00 AS Decimal(9, 2)), CAST(800.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (14, NULL, CAST(32.00 AS Decimal(9, 2)), CAST(2.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (15, NULL, CAST(200.00 AS Decimal(9, 2)), CAST(2.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (17, NULL, CAST(5.00 AS Decimal(9, 2)), CAST(0.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (18, NULL, CAST(30.00 AS Decimal(9, 2)), CAST(5.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (38, NULL, CAST(2000.00 AS Decimal(9, 2)), CAST(20.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (39, NULL, CAST(2020.00 AS Decimal(9, 2)), CAST(2000.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (32, NULL, CAST(500.00 AS Decimal(9, 2)), CAST(10.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (6, NULL, CAST(60.00 AS Decimal(9, 2)), CAST(10.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (3, NULL, CAST(30.00 AS Decimal(9, 2)), CAST(8.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (22, NULL, CAST(200.00 AS Decimal(9, 2)), CAST(30.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (25, NULL, CAST(5.00 AS Decimal(9, 2)), CAST(0.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (29, NULL, CAST(50.00 AS Decimal(9, 2)), CAST(2.00 AS Decimal(9, 2)), NULL, NULL)
INSERT [dbo].[attributes_check] ([type_attribute_id], [possible_value], [max_val_num], [min_val_num], [max_date], [min_date]) VALUES (16, NULL, NULL, NULL, CAST(N'2020-01-01' AS Date), CAST(N'2010-01-01' AS Date))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (1, N'Юлия', N'Черемныx', N'89028770034_@gmail.com', N'34gtgtw454545', N'89028770034', N'', N'Ленинина д 4', CAST(N'2018-12-01' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (2, N'Владислав', N'Щукин', N'89105229650_@gmail.com', N'34gtgtw454546', N'89105229650', N'', N'Ленинина д 5', CAST(N'2018-12-02' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (3, N'Борис', N'Татарчевский', N'89501944796_@gmail.com', N'34gtgtw454547', N'89501944796', N'', N'Ленинина д 6', CAST(N'2018-12-03' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (4, N'Евгения', N'Грачева', N'89506498536_@gmail.com', N'34gtgtw454548', N'89506498536', N'', N'Ленинина д 7', CAST(N'2018-12-04' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (5, N'Марина', N'Бушуева', N'89222145883_@gmail.com', N'34gtgtw454549', N'89222145883', N'89222745885', N'Ленинина д 8', CAST(N'2018-12-05' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (6, N'Юлия', N'Мавлютова', N'89221333327_@gmail.com', N'34gtgtw454550', N'89221333327', N'', N'Ленинина д 9', CAST(N'2018-12-06' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (7, N'Екатерина', N'Некрасова', N'89041684175_@gmail.com', N'34gtgtw454551', N'89041684175', N'', N'Ленинина д 10', CAST(N'2018-12-07' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (8, N'Эльвира', N'Тажиева', N'89655321999_@gmail.com', N'34gtgtw454552', N'89655321999', N'', N'Ленинина д 11', CAST(N'2018-12-08' AS Date), 0, CAST(N'2019-01-12T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (9, N'Иван', N'Почечун', N'89655422731_@gmail.com', N'34gtgtw454553', N'89655422731', N'', N'Ленинина д 12', CAST(N'2018-12-09' AS Date), 1, CAST(N'2019-01-13T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (10, N'Анна', N'Волобуева', N'89028716367_@gmail.com', N'34gtgtw454554', N'89028716367', N'89028716367', N'Ленинина д 13', CAST(N'2018-12-10' AS Date), 0, CAST(N'2019-01-14T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (11, N'Елена', N'Игнатьева', N'89021514891_@gmail.com', N'34gtgtw454555', N'89021514891', N'', N'Ленинина д 14', CAST(N'2018-12-11' AS Date), 1, CAST(N'2019-01-15T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (12, N'Вера', N'Кузнецова', N'89028732185_@gmail.com', N'34gtgtw454556', N'89028732185', N'', N'Ленинина д 15', CAST(N'2018-12-12' AS Date), 0, CAST(N'2019-01-16T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (13, N'Екатерина', N'Сикимова', N'89644884418_@gmail.com', N'34gtgtw454557', N'89644884418', N'', N'Ленинина д 16', CAST(N'2018-12-13' AS Date), 1, CAST(N'2019-01-17T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (14, N'Ирина', N'Мамонтова', N'89220377811_@gmail.com', N'34gtgtw454558', N'89220377811', N'', N'Ленинина д 17', CAST(N'2018-12-14' AS Date), 0, CAST(N'2019-01-18T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (15, N'Мария', N'Шипиловская', N'89122575557_@gmail.com', N'34gtgtw454559', N'89122575557', N'', N'Ленинина д 18', CAST(N'2018-12-15' AS Date), 1, CAST(N'2019-01-19T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (16, N'Лейла', N'Дурнева', N'89220252021_@gmail.com', N'34gtgtw454560', N'89220252021', N'', N'Ленинина д 19', CAST(N'2018-12-16' AS Date), 0, CAST(N'2019-01-20T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (17, N'Николай', N'Соломин', N'89090058780_@gmail.com', N'34gtgtw454561', N'89090058780', N'', N'Ленинина д 20', CAST(N'2018-12-17' AS Date), 1, CAST(N'2019-01-21T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (18, N'Ольга', N'Ильященко', N'89995665306_@gmail.com', N'34gtgtw454562', N'89995665306', N'89995665506', N'Ленинина д 21', CAST(N'2018-12-18' AS Date), 0, CAST(N'2019-01-22T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (19, N'Николай', N'Федоров', N'89505569807_@gmail.com', N'34gtgtw454563', N'89505569807', N'', N'Ленинина д 22', CAST(N'2018-12-19' AS Date), 1, CAST(N'2019-01-23T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (20, N'Алёна', N'Полинская', N'89089163888_@gmail.com', N'34gtgtw454564', N'89089163888', N'', N'Ленинина д 23', CAST(N'2018-12-20' AS Date), 0, CAST(N'2019-01-24T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (21, N'Ольга', N'Власова', N'89292183919_@gmail.com', N'34gtgtw454565', N'89292183919', N'', N'Ленинина д 24', CAST(N'2018-12-21' AS Date), 1, CAST(N'2019-05-20T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (22, N'Яна', N'Бизянова', N'89045441346_@gmail.com', N'34gtgtw454566', N'89045441346', N'', N'Ленинина д 25', CAST(N'2018-12-22' AS Date), 0, CAST(N'2019-05-21T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (23, N'Елена', N'Дударева', N'89221196264_@gmail.com', N'34gtgtw454567', N'89221196264', N'', N'Ленинина д 26', CAST(N'2018-12-23' AS Date), 1, CAST(N'2019-05-22T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (24, N'Ярослав', N'Касьянов', N'89655458067_@gmail.com', N'34gtgtw454568', N'89655458067', N'', N'Ленинина д 27', CAST(N'2018-12-24' AS Date), 0, CAST(N'2019-05-23T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (25, N'Наталья', N'Казанцева', N'89122505085_@gmail.com', N'34gtgtw454569', N'89122505085', N'', N'Ленинина д 28', CAST(N'2018-12-25' AS Date), 1, CAST(N'2019-05-24T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (26, N'Илья', N'Самойлов', N'89221219282_@gmail.com', N'34gtgtw454570', N'89221219282', N'', N'Ленинина д 29', CAST(N'2018-12-26' AS Date), 0, CAST(N'2019-05-25T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (27, N'Юлия', N'Голдобина', N'89995659577_@gmail.com', N'34gtgtw454571', N'89995659577', N'89995659577', N'Ленинина д 30', CAST(N'2018-12-27' AS Date), 1, CAST(N'2019-05-26T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (28, N'Дилмурод', N'Байназаров', N'89030808383_@gmail.com', N'34gtgtw454572', N'89030808383', N'', N'Ленинина д 31', CAST(N'2018-12-28' AS Date), 0, CAST(N'2019-05-27T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (29, N'Елена', N'Никонова', N'89049864350_@gmail.com', N'34gtgtw454573', N'89049864350', N'', N'Ленинина д 32', CAST(N'2018-12-29' AS Date), 1, CAST(N'2019-05-28T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (30, N'Марина', N'Ледяйкина', N'89827012820_@gmail.com', N'34gtgtw454574', N'89827012820', N'', N'Ленинина д 33', CAST(N'2018-12-30' AS Date), 0, CAST(N'2019-05-29T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (31, N'Иван', N'Корниенко', N'89521491856_@gmail.com', N'34gtgtw454575', N'89521491856', N'', N'Ленинина д 34', CAST(N'2018-12-31' AS Date), 1, CAST(N'2019-05-30T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (32, N'Дмитрий', N'Лебедев', N'89122249886_@gmail.com', N'34gtgtw454576', N'89122249886', N'89722249886', N'Ленинина д 35', CAST(N'2019-01-01' AS Date), 0, CAST(N'2019-05-31T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (33, N'Зоя', N'Иванова', N'89041748686_@gmail.com', N'34gtgtw454577', N'89041748686', N'', N'Ленинина д 36', CAST(N'2019-01-02' AS Date), 1, CAST(N'2019-06-01T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (34, N'Светлана', N'Чеченева', N'89122821131_@gmail.com', N'34gtgtw454578', N'89122821131', N'', N'Ленинина д 37', CAST(N'2019-01-03' AS Date), 0, CAST(N'2019-06-02T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (35, N'Валерий', N'Иванов', N'89122840765_@gmail.com', N'34gtgtw454579', N'89122840765', N'', N'Ленинина д 38', CAST(N'2019-01-04' AS Date), 1, CAST(N'2019-06-03T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (36, N'Александр', N'Неуймин', N'89126563433_@gmail.com', N'34gtgtw454580', N'89126563433', N'', N'Ленинина д 39', CAST(N'2019-01-05' AS Date), 0, CAST(N'2019-02-09T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (37, N'Марина', N'Семенова', N'89226188030_@gmail.com', N'34gtgtw454581', N'89226188030', N'89226788050', N'Ленинина д 40', CAST(N'2019-01-06' AS Date), 1, CAST(N'2019-02-10T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (38, N'Рима', N'Мурзина', N'89090032333_@gmail.com', N'34gtgtw454582', N'89090032333', N'', N'Ленинина д 41', CAST(N'2019-01-07' AS Date), 0, CAST(N'2019-02-11T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (39, N'Сергей', N'Александров', N'89043837131_@gmail.com', N'34gtgtw454583', N'89043837131', N'', N'Ленинина д 42', CAST(N'2019-01-08' AS Date), 1, CAST(N'2019-02-12T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (40, N'Наталья', N'Попова', N'89221457962_@gmail.com', N'34gtgtw454584', N'89221457962', N'', N'Ленинина д 43', CAST(N'2019-01-09' AS Date), 0, CAST(N'2019-02-13T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (41, N'Виталий', N'Бирюков', N'89086371567_@gmail.com', N'34gtgtw454585', N'89086371567', N'', N'Ленинина д 44', CAST(N'2019-01-10' AS Date), 1, CAST(N'2019-02-14T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (42, N'Владимир', N'Бухтояров', N'89090076875_@gmail.com', N'34gtgtw454586', N'89090076875', N'89090076875', N'Ленинина д 45', CAST(N'2019-01-11' AS Date), 0, CAST(N'2019-02-15T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (43, N'Анастасия', N'Бонина', N'89527252839_@gmail.com', N'34gtgtw454587', N'89527252839', N'', N'Ленинина д 46', CAST(N'2019-01-12' AS Date), 1, CAST(N'2019-02-16T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (44, N'Евгения', N'Антонова', N'89533804093_@gmail.com', N'34gtgtw454588', N'89533804093', N'', N'Ленинина д 47', CAST(N'2019-01-13' AS Date), 0, CAST(N'2019-02-17T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (45, N'Ольга', N'Родина', N'89122972723_@gmail.com', N'34gtgtw454589', N'89122972723', N'89722972725', N'Ленинина д 48', CAST(N'2019-01-14' AS Date), 1, CAST(N'2019-02-18T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (46, N'Лариса', N'Дроздова', N'89506407424_@gmail.com', N'34gtgtw454590', N'89506407424', N'', N'Ленинина д 49', CAST(N'2019-01-15' AS Date), 0, CAST(N'2019-02-19T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (47, N'Олеся', N'Фуртикова', N'89501966815_@gmail.com', N'34gtgtw454591', N'89501966815', N'', N'Ленинина д 50', CAST(N'2019-01-16' AS Date), 1, CAST(N'2019-02-20T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (48, N'Елена', N'Рудина', N'89001986490_@gmail.com', N'34gtgtw454592', N'89001986490', N'', N'Ленинина д 51', CAST(N'2019-01-17' AS Date), 0, CAST(N'2019-02-21T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (49, N'Полина', N'Чирикова', N'89826381838_@gmail.com', N'34gtgtw454593', N'89826381838', N'', N'Ленинина д 52', CAST(N'2019-01-18' AS Date), 1, CAST(N'2019-02-22T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (50, N'Евгений', N'Маракин', N'89028756248_@gmail.com', N'34gtgtw454594', N'89028756248', N'', N'Ленинина д 53', CAST(N'2019-01-19' AS Date), 0, CAST(N'2019-02-23T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (51, N'Ирина', N'Рыбина', N'89222050094_@gmail.com', N'34gtgtw454595', N'89222050094', N'', N'Ленинина д 54', CAST(N'2019-01-20' AS Date), 1, CAST(N'2019-02-24T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (52, N'Наталья', N'Контрактова', N'89826002073_@gmail.com', N'34gtgtw454596', N'89826002073', N'', N'Ленинина д 55', CAST(N'2019-01-21' AS Date), 0, CAST(N'2019-02-25T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (53, N'Ксения', N'Фроленкова', N'89226123484_@gmail.com', N'34gtgtw454597', N'89226123484', N'', N'Ленинина д 56', CAST(N'2019-01-22' AS Date), 1, CAST(N'2019-02-26T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (54, N'Михаил', N'Черницкий', N'89126601164_@gmail.com', N'34gtgtw454598', N'89126601164', N'', N'Ленинина д 57', CAST(N'2019-01-23' AS Date), 0, CAST(N'2019-02-27T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (55, N'Максим', N'Шерстень', N'89122959524_@gmail.com', N'34gtgtw454599', N'89122959524', N'', N'Ленинина д 58', CAST(N'2019-01-24' AS Date), 1, CAST(N'2019-02-28T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (56, N'Мария', N'Филиппова', N'89068159739_@gmail.com', N'34gtgtw454600', N'89068159739', N'', N'Ленинина д 59', CAST(N'2019-01-25' AS Date), 0, CAST(N'2019-03-01T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (57, N'Ольга', N'Морозова', N'89222006835_@gmail.com', N'34gtgtw454601', N'89222006835', N'89222006855', N'Ленинина д 60', CAST(N'2019-01-26' AS Date), 1, CAST(N'2019-03-02T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (58, N'Константин', N'Фатыков', N'89193723409_@gmail.com', N'34gtgtw454602', N'89193723409', N'', N'Ленинина д 61', CAST(N'2019-01-27' AS Date), 0, CAST(N'2019-03-03T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (59, N'Полина', N'Кузнецова', N'89122189513_@gmail.com', N'34gtgtw454603', N'89122189513', N'', N'Ленинина д 62', CAST(N'2019-01-28' AS Date), 1, CAST(N'2019-03-04T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (60, N'Юлия', N'Фонарева', N'89226057524_@gmail.com', N'34gtgtw454604', N'89226057524', N'', N'Ленинина д 63', CAST(N'2019-01-29' AS Date), 0, CAST(N'2019-03-05T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (61, N'Илья', N'Ситников', N'89090070903_@gmail.com', N'34gtgtw454605', N'89090070903', N'', N'Ленинина д 64', CAST(N'2019-01-30' AS Date), 1, CAST(N'2019-03-06T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (62, N'Евгения', N'Отева', N'89122886386_@gmail.com', N'34gtgtw454606', N'89122886386', N'', N'Ленинина д 65', CAST(N'2019-01-31' AS Date), 0, CAST(N'2019-03-07T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (63, N'Гульшат', N'Клюкина', N'89826521827_@gmail.com', N'34gtgtw454607', N'89826521827', N'89826527827', N'Ленинина д 66', CAST(N'2019-02-01' AS Date), 1, CAST(N'2019-03-08T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (64, N'Надежда', N'Назарова', N'89826900771_@gmail.com', N'34gtgtw454608', N'89826900771', N'', N'Ленинина д 67', CAST(N'2019-02-02' AS Date), 0, CAST(N'2019-03-09T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (65, N'Евгений', N'Перязев', N'89826416197_@gmail.com', N'34gtgtw454609', N'89826416197', N'', N'Ленинина д 68', CAST(N'2019-02-03' AS Date), 1, CAST(N'2019-03-10T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (66, N'Анжелика', N'Гарбузова', N'89226079390_@gmail.com', N'34gtgtw454610', N'89226079390', N'', N'Ленинина д 69', CAST(N'2019-02-04' AS Date), 0, CAST(N'2019-03-11T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (67, N'Марина', N'Кузнецова', N'89122720433_@gmail.com', N'34gtgtw454611', N'89122720433', N'', N'Ленинина д 70', CAST(N'2019-02-05' AS Date), 1, CAST(N'2019-03-12T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (68, N'Любовь', N'Бокитько', N'89222983170_@gmail.com', N'34gtgtw454612', N'89222983170', N'89222985770', N'Ленинина д 71', CAST(N'2019-02-06' AS Date), 0, CAST(N'2019-03-13T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (69, N'Олег', N'Русаков', N'89827286858_@gmail.com', N'34gtgtw454613', N'89827286858', N'', N'Ленинина д 72', CAST(N'2019-02-07' AS Date), 1, CAST(N'2019-03-14T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (70, N'Рустам', N'Валитов', N'89122663584_@gmail.com', N'34gtgtw454614', N'89122663584', N'', N'Ленинина д 73', CAST(N'2019-02-08' AS Date), 0, CAST(N'2019-03-15T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (71, N'Алена', N'Трубенкова', N'89193966699_@gmail.com', N'34gtgtw454615', N'89193966699', N'89795966699', N'Ленинина д 74', CAST(N'2019-02-09' AS Date), 1, CAST(N'2019-03-16T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (72, N'Ксения', N'Шмуратко', N'89221122936_@gmail.com', N'34gtgtw454616', N'89221122936', N'', N'Ленинина д 75', CAST(N'2019-02-10' AS Date), 0, CAST(N'2019-03-17T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (73, N'Виталий', N'Лопатин', N'89126163889_@gmail.com', N'34gtgtw454617', N'89126163889', N'', N'Ленинина д 76', CAST(N'2019-02-11' AS Date), 1, CAST(N'2019-03-18T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (74, N'Вера', N'Грехова', N'89221112015_@gmail.com', N'34gtgtw454618', N'89221112015', N'', N'Ленинина д 77', CAST(N'2019-02-12' AS Date), 0, CAST(N'2019-03-19T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (75, N'Алла', N'Холодарева', N'89122205050_@gmail.com', N'34gtgtw454619', N'89122205050', N'', N'Ленинина д 78', CAST(N'2019-02-13' AS Date), 1, CAST(N'2019-03-20T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (76, N'Анастасия', N'Чубарова', N'89502068866_@gmail.com', N'34gtgtw454620', N'89502068866', N'', N'Ленинина д 79', CAST(N'2019-02-14' AS Date), 0, CAST(N'2019-03-21T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (77, N'Ольга', N'Новоселова', N'89222051220_@gmail.com', N'34gtgtw454621', N'89222051220', N'', N'Ленинина д 80', CAST(N'2019-02-15' AS Date), 1, CAST(N'2019-03-22T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (78, N'Марина', N'Степанова', N'89045455146_@gmail.com', N'34gtgtw454622', N'89045455146', N'89045455746', N'Ленинина д 81', CAST(N'2019-02-16' AS Date), 0, CAST(N'2019-03-23T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (79, N'Марина', N'Солган', N'89326134422_@gmail.com', N'34gtgtw454623', N'89326134422', N'', N'Ленинина д 82', CAST(N'2019-02-17' AS Date), 1, CAST(N'2019-03-24T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (80, N'Дарья', N'Большедворова', N'89226010149_@gmail.com', N'34gtgtw454624', N'89226010149', N'', N'Ленинина д 83', CAST(N'2019-02-18' AS Date), 0, CAST(N'2019-03-25T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (81, N'Анастасия', N'Кутлиева', N'89120474424_@gmail.com', N'34gtgtw454625', N'89120474424', N'', N'Ленинина д 84', CAST(N'2019-02-19' AS Date), 1, CAST(N'2019-03-26T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (82, N'Марина', N'Иордатий', N'89028773318_@gmail.com', N'34gtgtw454626', N'89028773318', N'', N'Ленинина д 85', CAST(N'2019-02-20' AS Date), 0, CAST(N'2019-03-27T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (83, N'Игорь', N'Панаско', N'89069340388_@gmail.com', N'34gtgtw454627', N'89069340388', N'', N'Ленинина д 86', CAST(N'2019-02-21' AS Date), 1, CAST(N'2019-03-28T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (84, N'Владимир', N'Мельников', N'89226115539_@gmail.com', N'34gtgtw454628', N'89226115539', N'', N'Ленинина д 87', CAST(N'2019-02-22' AS Date), 0, CAST(N'2019-03-29T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (85, N'Екатерина', N'Бесчастных', N'89321294039_@gmail.com', N'34gtgtw454629', N'89321294039', N'', N'Ленинина д 88', CAST(N'2019-02-23' AS Date), 1, CAST(N'2019-03-30T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (86, N'Александр', N'Кичигин', N'89126655775_@gmail.com', N'34gtgtw454630', N'89126655775', N'', N'Ленинина д 89', CAST(N'2019-02-24' AS Date), 0, CAST(N'2019-03-31T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (87, N'Наталия', N'Маколдина', N'89126213328_@gmail.com', N'34gtgtw454631', N'89126213328', N'', N'Ленинина д 90', CAST(N'2019-02-25' AS Date), 1, CAST(N'2019-04-01T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (88, N'Елена', N'Кошолап', N'89292183322_@gmail.com', N'34gtgtw454632', N'89292183322', N'', N'Ленинина д 91', CAST(N'2019-02-26' AS Date), 0, CAST(N'2019-04-02T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (89, N'Евгения', N'Степанова', N'89655177586_@gmail.com', N'34gtgtw454633', N'89655177586', N'', N'Ленинина д 92', CAST(N'2019-02-27' AS Date), 1, CAST(N'2019-04-03T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (90, N'Елена', N'Клепикова', N'89120470208_@gmail.com', N'34gtgtw454634', N'89120470208', N'', N'Ленинина д 93', CAST(N'2019-02-28' AS Date), 0, CAST(N'2019-04-04T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (91, N'Александр', N'Кучин', N'89221344844_@gmail.com', N'34gtgtw454635', N'89221344844', N'', N'Ленинина д 94', CAST(N'2019-03-01' AS Date), 1, CAST(N'2019-04-05T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (92, N'Анна', N'Пестова', N'89126946815_@gmail.com', N'34gtgtw454636', N'89126946815', N'89126946815', N'Ленинина д 95', CAST(N'2019-03-02' AS Date), 0, CAST(N'2019-04-06T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (93, N'Татьяна', N'Войдеславер', N'89826226440_@gmail.com', N'34gtgtw454637', N'89826226440', N'', N'Ленинина д 96', CAST(N'2019-03-03' AS Date), 1, CAST(N'2019-04-07T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (94, N'Валерия', N'Васильева', N'89530099005_@gmail.com', N'34gtgtw454638', N'89530099005', N'', N'Ленинина д 97', CAST(N'2019-03-04' AS Date), 0, CAST(N'2019-04-08T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (95, N'Артем', N'Рассохин', N'89122305221_@gmail.com', N'34gtgtw454639', N'89122305221', N'', N'Ленинина д 98', CAST(N'2019-03-05' AS Date), 1, CAST(N'2019-04-09T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (96, N'Вероника', N'Петракова', N'89122512140_@gmail.com', N'34gtgtw454640', N'89122512140', N'', N'Ленинина д 99', CAST(N'2019-03-06' AS Date), 0, CAST(N'2019-04-10T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (97, N'Светлана', N'Русинова', N'89221309850_@gmail.com', N'34gtgtw454641', N'89221309850', N'89221309850', N'Ленинина д 100', CAST(N'2019-03-07' AS Date), 1, CAST(N'2019-04-11T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (98, N'Ольга', N'Юрченко', N'89122651033_@gmail.com', N'34gtgtw454642', N'89122651033', N'', N'Ленинина д 101', CAST(N'2019-03-08' AS Date), 0, CAST(N'2019-04-12T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (99, N'Фавия', N'Сафиуллина', N'89122485135_@gmail.com', N'34gtgtw454643', N'89122485135', N'', N'Ленинина д 102', CAST(N'2019-03-09' AS Date), 1, CAST(N'2019-04-13T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (100, N'Алия', N'Федусова', N'89028754903_@gmail.com', N'34gtgtw454644', N'89028754903', N'', N'Ленинина д 103', CAST(N'2019-03-10' AS Date), 0, CAST(N'2019-04-14T00:00:00.0000000' AS DateTime2))
GO
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (101, N'Максим', N'Куршаков', N'89521495830_@gmail.com', N'34gtgtw454645', N'89521495830', N'89521495830', N'Ленинина д 104', CAST(N'2019-03-11' AS Date), 1, CAST(N'2019-04-15T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (102, N'Евгений', N'Яковлев', N'89126303761_@gmail.com', N'34gtgtw454646', N'89126303761', N'', N'Ленинина д 105', CAST(N'2019-03-12' AS Date), 0, CAST(N'2019-04-16T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (103, N'Валентина', N'Клементьева', N'89126779128_@gmail.com', N'34gtgtw454647', N'89126779128', N'89726779728', N'Ленинина д 106', CAST(N'2019-03-13' AS Date), 1, CAST(N'2019-04-17T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (104, N'Егор', N'Масасин', N'89536065876_@gmail.com', N'34gtgtw454648', N'89536065876', N'', N'Ленинина д 107', CAST(N'2019-03-14' AS Date), 0, CAST(N'2019-04-18T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (105, N'Олеся', N'Субботина', N'89226053354_@gmail.com', N'34gtgtw454649', N'89226053354', N'', N'Ленинина д 108', CAST(N'2019-03-15' AS Date), 1, CAST(N'2019-04-19T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (106, N'Александр', N'Печеневский', N'89961769725_@gmail.com', N'34gtgtw454650', N'89961769725', N'', N'Ленинина д 109', CAST(N'2019-03-16' AS Date), 0, CAST(N'2019-04-20T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (107, N'Анастасия', N'Ковалева', N'89527340819_@gmail.com', N'34gtgtw454651', N'89527340819', N'', N'Ленинина д 110', CAST(N'2019-03-17' AS Date), 1, CAST(N'2019-04-21T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (108, N'Эмилия', N'Минина', N'89122413520_@gmail.com', N'34gtgtw454652', N'89122413520', N'', N'Ленинина д 111', CAST(N'2019-03-18' AS Date), 0, CAST(N'2019-01-25T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (109, N'Юрий', N'Ефимов', N'89122101625_@gmail.com', N'34gtgtw454653', N'89122101625', N'', N'Ленинина д 112', CAST(N'2019-03-19' AS Date), 1, CAST(N'2019-01-26T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (110, N'Наталья', N'Берсенева', N'89826167274_@gmail.com', N'34gtgtw454654', N'89826167274', N'', N'Ленинина д 113', CAST(N'2019-03-20' AS Date), 0, CAST(N'2019-01-27T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (111, N'Артем', N'Аскаров', N'89226015635_@gmail.com', N'34gtgtw454655', N'89226015635', N'', N'Ленинина д 114', CAST(N'2019-03-21' AS Date), 1, CAST(N'2019-01-28T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (112, N'Сергей', N'Бушмелев', N'89226081676_@gmail.com', N'34gtgtw454656', N'89226081676', N'', N'Ленинина д 115', CAST(N'2019-03-22' AS Date), 0, CAST(N'2019-01-29T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (113, N'Анастасия', N'Кузьмина', N'89122609142_@gmail.com', N'34gtgtw454657', N'89122609142', N'89122609142', N'Ленинина д 116', CAST(N'2019-03-23' AS Date), 1, CAST(N'2019-01-30T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (114, N'Юлия', N'Яценко', N'89226086420_@gmail.com', N'34gtgtw454658', N'89226086420', N'', N'Ленинина д 117', CAST(N'2019-03-24' AS Date), 0, CAST(N'2019-01-31T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (115, N'Арина', N'Аубекерова', N'89022582124_@gmail.com', N'34gtgtw454659', N'89022582124', N'', N'Ленинина д 118', CAST(N'2019-03-25' AS Date), 1, CAST(N'2019-02-01T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (116, N'Александр', N'Шулаков', N'89126939505_@gmail.com', N'34gtgtw454660', N'89126939505', N'', N'Ленинина д 119', CAST(N'2019-03-26' AS Date), 0, CAST(N'2019-02-02T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (117, N'Анна', N'Засыпалова', N'89122068575_@gmail.com', N'34gtgtw454661', N'89122068575', N'', N'Ленинина д 120', CAST(N'2019-03-27' AS Date), 1, CAST(N'2019-02-03T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (118, N'Юлия', N'Кораблева', N'89826604590_@gmail.com', N'34gtgtw454662', N'89826604590', N'', N'Ленинина д 121', CAST(N'2019-03-28' AS Date), 0, CAST(N'2019-02-04T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (119, N'Татьяна', N'Сатюкова', N'89630511815_@gmail.com', N'34gtgtw454663', N'89630511815', N'', N'Ленинина д 122', CAST(N'2019-03-29' AS Date), 1, CAST(N'2019-02-05T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (120, N'Владимир', N'Лядов', N'89126187997_@gmail.com', N'34gtgtw454664', N'89126187997', N'', N'Ленинина д 123', CAST(N'2019-03-30' AS Date), 0, CAST(N'2019-02-06T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (121, N'Андрей', N'Ан', N'89122128949_@gmail.com', N'34gtgtw454665', N'89122128949', N'', N'Ленинина д 124', CAST(N'2019-03-31' AS Date), 1, CAST(N'2019-02-07T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (122, N'Евгений', N'Чжен', N'89058000190_@gmail.com', N'34gtgtw454666', N'89058000190', N'89058000190', N'Ленинина д 125', CAST(N'2019-04-01' AS Date), 0, CAST(N'2019-02-08T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (123, N'Николай', N'Дерипаско', N'89827680151_@gmail.com', N'34gtgtw454667', N'89827680151', N'', N'Ленинина д 126', CAST(N'2019-04-02' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (124, N'Александр', N'Кузнецов', N'89506479200_@gmail.com', N'34gtgtw454668', N'89506479200', N'', N'Ленинина д 127', CAST(N'2019-04-03' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (125, N'Анна', N'Горшкова', N'89617610407_@gmail.com', N'34gtgtw454669', N'89617610407', N'', N'Ленинина д 128', CAST(N'2019-04-04' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (126, N'Варвара', N'Тонкова', N'89506534449_@gmail.com', N'34gtgtw454670', N'89506534449', N'', N'Ленинина д 129', CAST(N'2019-04-05' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (127, N'Алина', N'Бородина', N'89090097575_@gmail.com', N'34gtgtw454671', N'89090097575', N'', N'Ленинина д 130', CAST(N'2019-04-06' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (128, N'Анастасия', N'Алексеева', N'89827064917_@gmail.com', N'34gtgtw454672', N'89827064917', N'', N'Ленинина д 131', CAST(N'2019-04-07' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (129, N'Роман', N'Карпов', N'89126664269_@gmail.com', N'34gtgtw454673', N'89126664269', N'', N'Ленинина д 132', CAST(N'2019-04-08' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (130, N'Фарид', N'Абубакиров', N'89043829971_@gmail.com', N'34gtgtw454674', N'89043829971', N'', N'Ленинина д 133', CAST(N'2019-04-09' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (131, N'Наталья', N'Столбова', N'89122629191_@gmail.com', N'34gtgtw454675', N'89122629191', N'', N'Ленинина д 134', CAST(N'2019-04-10' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (132, N'Светлана', N'Подмосковная', N'89221508037_@gmail.com', N'34gtgtw454676', N'89221508037', N'', N'Ленинина д 135', CAST(N'2019-04-11' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (133, N'Влада', N'Бровкина', N'89122608729_@gmail.com', N'34gtgtw454677', N'89122608729', N'', N'Ленинина д 136', CAST(N'2019-04-12' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (134, N'Анна', N'Дергачева', N'89221032148_@gmail.com', N'34gtgtw454678', N'89221032148', N'', N'Ленинина д 137', CAST(N'2019-04-13' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (135, N'Виктория', N'Боброва', N'89617747526_@gmail.com', N'34gtgtw454679', N'89617747526', N'', N'Ленинина д 138', CAST(N'2019-04-14' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (136, N'Георгий', N'Чухланцев', N'89221712607_@gmail.com', N'34gtgtw454680', N'89221712607', N'', N'Ленинина д 139', CAST(N'2019-04-15' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (137, N'Анна', N'Семерикова', N'89001976343_@gmail.com', N'34gtgtw454681', N'89001976343', N'', N'Ленинина д 140', CAST(N'2019-04-16' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (138, N'Мария', N'Гучева', N'89826455261_@gmail.com', N'34gtgtw454682', N'89826455261', N'', N'Ленинина д 141', CAST(N'2019-04-17' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (139, N'Александр', N'Изгарев', N'89089245022_@gmail.com', N'34gtgtw454683', N'89089245022', N'', N'Ленинина д 142', CAST(N'2019-04-18' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (140, N'Мария', N'Сидарович', N'89126955576_@gmail.com', N'34gtgtw454684', N'89126955576', N'', N'Ленинина д 143', CAST(N'2019-01-19' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (141, N'Джесси', N'Джесси', N'14048341973_@gmail.com', N'34gtgtw454685', N'14048341973', N'', N'Ленинина д 144', CAST(N'2019-01-20' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (142, N'Виктория', N'Кокшарова', N'89826387034_@gmail.com', N'34gtgtw454686', N'89826387034', N'', N'Ленинина д 145', CAST(N'2019-01-21' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (143, N'Елизавета', N'Кочурина', N'89505427585_@gmail.com', N'34gtgtw454687', N'89505427585', N'', N'Ленинина д 146', CAST(N'2019-01-22' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (144, N'Наимжон', N'Сокиев', N'89090168845_@gmail.com', N'34gtgtw454688', N'89090168845', N'', N'Ленинина д 147', CAST(N'2019-01-23' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (145, N'Максим', N'Ковков', N'89126323402_@gmail.com', N'34gtgtw454689', N'89126323402', N'', N'Ленинина д 148', CAST(N'2019-01-24' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (146, N'Марина', N'Лютикова', N'89089235107_@gmail.com', N'34gtgtw454690', N'89089235107', N'', N'Ленинина д 149', CAST(N'2019-01-25' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (147, N'Виктория', N'Марарова', N'89655414797_@gmail.com', N'34gtgtw454691', N'89655414797', N'', N'Ленинина д 150', CAST(N'2019-01-26' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (148, N'Яна', N'Бабинчук', N'89995633100_@gmail.com', N'34gtgtw454692', N'89995633100', N'', N'Ленинина д 151', CAST(N'2019-01-27' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (149, N'Александр', N'Табатчиков', N'89222024230_@gmail.com', N'34gtgtw454693', N'89222024230', N'', N'Ленинина д 152', CAST(N'2019-01-28' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (150, N'Дмитрий', N'Гончаров', N'89222220828_@gmail.com', N'34gtgtw454694', N'89222220828', N'', N'Ленинина д 153', CAST(N'2019-01-29' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (151, N'Диана', N'Доценко', N'89222969289_@gmail.com', N'34gtgtw454695', N'89222969289', N'', N'Ленинина д 154', CAST(N'2019-01-30' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (152, N'Марина', N'Полозова', N'89126466493_@gmail.com', N'34gtgtw454696', N'89126466493', N'', N'Ленинина д 155', CAST(N'2019-01-31' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (153, N'Андрей', N'Воробьев', N'89193981011_@gmail.com', N'34gtgtw454697', N'89193981011', N'', N'Ленинина д 156', CAST(N'2019-02-01' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (154, N'Ольга', N'Кетова', N'89505492115_@gmail.com', N'34gtgtw454698', N'89505492115', N'', N'Ленинина д 157', CAST(N'2019-02-02' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (155, N'Зинаида', N'Уханова', N'89530044283_@gmail.com', N'34gtgtw454699', N'89530044283', N'', N'Ленинина д 158', CAST(N'2019-02-03' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (156, N'Алексей', N'Захаров', N'89089046252_@gmail.com', N'34gtgtw454700', N'89089046252', N'', N'Ленинина д 159', CAST(N'2019-02-04' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (157, N'Марат', N'Ахьямов', N'89530569543_@gmail.com', N'34gtgtw454701', N'89530569543', N'', N'Ленинина д 160', CAST(N'2019-02-05' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (158, N'Лев', N'Вычуров', N'89321118962_@gmail.com', N'34gtgtw454702', N'89321118962', N'', N'Ленинина д 161', CAST(N'2019-02-06' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (159, N'Радион', N'Андрианов', N'89221936943_@gmail.com', N'34gtgtw454703', N'89221936943', N'', N'Ленинина д 162', CAST(N'2019-02-07' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (160, N'Александр', N'Вяткин', N'89025866222_@gmail.com', N'34gtgtw454704', N'89025866222', N'', N'Ленинина д 163', CAST(N'2019-02-08' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (161, N'Агарон', N'Саканян', N'89090038767_@gmail.com', N'34gtgtw454705', N'89090038767', N'', N'Ленинина д 164', CAST(N'2019-02-09' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (162, N'Артём', N'Панов', N'89221378565_@gmail.com', N'34gtgtw454706', N'89221378565', N'', N'Ленинина д 165', CAST(N'2019-02-10' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (163, N'Полина', N'Кочнева', N'89089204444_@gmail.com', N'34gtgtw454707', N'89089204444', N'', N'Ленинина д 166', CAST(N'2019-02-11' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (164, N'Зиля', N'Галимова', N'89221405605_@gmail.com', N'34gtgtw454708', N'89221405605', N'', N'Ленинина д 167', CAST(N'2019-02-12' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (165, N'Семён', N'Рявкин', N'89043861847_@gmail.com', N'34gtgtw454709', N'89043861847', N'', N'Ленинина д 168', CAST(N'2019-02-13' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (166, N'Илья', N'Леконцев', N'89505414840_@gmail.com', N'34gtgtw454710', N'89505414840', N'', N'Ленинина д 169', CAST(N'2019-02-14' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (167, N'Эдуард', N'Гараев', N'89826599896_@gmail.com', N'34gtgtw454711', N'89826599896', N'', N'Ленинина д 170', CAST(N'2019-02-15' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (168, N'Надим', N'Мирземагомедов', N'89292351555_@gmail.com', N'34gtgtw454712', N'89292351555', N'', N'Ленинина д 171', CAST(N'2019-02-16' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (169, N'Артем', N'Золотухин', N'89827075347_@gmail.com', N'34gtgtw454713', N'89827075347', N'', N'Ленинина д 172', CAST(N'2019-02-17' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (170, N'Ирина', N'Данилова', N'89923385232_@gmail.com', N'34gtgtw454714', N'89923385232', N'', N'Ленинина д 173', CAST(N'2019-02-18' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (171, N'Дмитрий', N'Демкин', N'89536052653_@gmail.com', N'34gtgtw454715', N'89536052653', N'', N'Ленинина д 174', CAST(N'2019-02-19' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (172, N'Дмитрий', N'Долгодворов', N'89022711145_@gmail.com', N'34gtgtw454716', N'89022711145', N'', N'Ленинина д 175', CAST(N'2019-02-20' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (173, N'Анна', N'Чапурина', N'89221013030_@gmail.com', N'34gtgtw454717', N'89221013030', N'', N'Ленинина д 176', CAST(N'2019-02-21' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (174, N'Оксана', N'Кириллова', N'89000414182_@gmail.com', N'34gtgtw454718', N'89000414182', N'', N'Ленинина д 177', CAST(N'2019-02-22' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (175, N'Муршида', N'Аюпова', N'89826124220_@gmail.com', N'34gtgtw454719', N'89826124220', N'', N'Ленинина д 178', CAST(N'2019-02-23' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (176, N'Татьяна', N'Демина', N'89043860876_@gmail.com', N'34gtgtw454720', N'89043860876', N'', N'Ленинина д 179', CAST(N'2019-02-24' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (177, N'Алина', N'Вяткина', N'89226085222_@gmail.com', N'34gtgtw454721', N'89226085222', N'', N'Ленинина д 180', CAST(N'2019-02-25' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (178, N'Артем', N'Федотов', N'89827472054_@gmail.com', N'34gtgtw454722', N'89827472054', N'', N'Ленинина д 181', CAST(N'2019-02-26' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (179, N'Эрматов', N'Эрматов', N'89506349211_@gmail.com', N'34gtgtw454723', N'89506349211', N'', N'Ленинина д 182', CAST(N'2019-02-27' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (180, N'Ульяна', N'Кокотова', N'89014133754_@gmail.com', N'34gtgtw454724', N'89014133754', N'', N'Ленинина д 183', CAST(N'2019-02-28' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (181, N'Алексей', N'Южанин', N'89049833361_@gmail.com', N'34gtgtw454725', N'89049833361', N'', N'Ленинина д 184', CAST(N'2019-03-01' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (182, N'Татьяна', N'Зыкова', N'89122619751_@gmail.com', N'34gtgtw454726', N'89122619751', N'', N'Ленинина д 185', CAST(N'2019-03-02' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (183, N'Екатерина', N'Холстинина', N'89129847727_@gmail.com', N'34gtgtw454727', N'89129847727', N'', N'Ленинина д 186', CAST(N'2019-03-03' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (184, N'Дмитрий', N'Орлов', N'89126505882_@gmail.com', N'34gtgtw454728', N'89126505882', N'', N'Ленинина д 187', CAST(N'2019-03-04' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (185, N'Елена', N'Елисеева', N'89068043386_@gmail.com', N'34gtgtw454729', N'89068043386', N'', N'Ленинина д 188', CAST(N'2019-03-05' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (186, N'Лариса', N'Андрюк', N'89634494859_@gmail.com', N'34gtgtw454730', N'89634494859', N'', N'Ленинина д 189', CAST(N'2019-03-06' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (187, N'Арина', N'Лобанова', N'89126238345_@gmail.com', N'34gtgtw454731', N'89126238345', N'', N'Ленинина д 190', CAST(N'2019-03-07' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (188, N'Алена', N'Корсакова', N'89617718346_@gmail.com', N'34gtgtw454732', N'89617718346', N'', N'Ленинина д 191', CAST(N'2019-03-08' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (189, N'Александр', N'Евтеев', N'89126042051_@gmail.com', N'34gtgtw454733', N'89126042051', N'', N'Ленинина д 192', CAST(N'2019-03-09' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (190, N'Юрий', N'Гуров', N'89097009938_@gmail.com', N'34gtgtw454734', N'89097009938', N'', N'Ленинина д 193', CAST(N'2019-03-10' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (191, N'Анна', N'Жданова', N'89226070045_@gmail.com', N'34gtgtw454735', N'89226070045', N'', N'Ленинина д 194', CAST(N'2019-03-11' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (192, N'Артем', N'Крамарь', N'89827504740_@gmail.com', N'34gtgtw454736', N'89827504740', N'', N'Ленинина д 195', CAST(N'2019-03-12' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (193, N'Александр', N'Сумин', N'89089101027_@gmail.com', N'34gtgtw454737', N'89089101027', N'', N'Ленинина д 196', CAST(N'2019-03-13' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (194, N'Дмитрий', N'Шаипкин', N'89506555826_@gmail.com', N'34gtgtw454738', N'89506555826', N'', N'Ленинина д 197', CAST(N'2019-03-14' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (195, N'Денис', N'Свистунов', N'89222228580_@gmail.com', N'34gtgtw454739', N'89222228580', N'', N'Ленинина д 198', CAST(N'2019-03-15' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (196, N'Егор', N'Есин', N'89030823541_@gmail.com', N'34gtgtw454740', N'89030823541', N'', N'Ленинина д 199', CAST(N'2019-03-16' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (197, N'Никита', N'Клюсов', N'89021511688_@gmail.com', N'34gtgtw454741', N'89021511688', N'', N'Ленинина д 200', CAST(N'2019-03-17' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (198, N'Елизавета', N'Пестрикова', N'89995597416_@gmail.com', N'34gtgtw454742', N'89995597416', N'', N'Ленинина д 201', CAST(N'2019-03-18' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (199, N'Анна', N'Лагунова', N'89126449502_@gmail.com', N'34gtgtw454743', N'89126449502', N'', N'Ленинина д 202', CAST(N'2019-03-19' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (200, N'Амелия', N'Сарапульцева', N'89501903393_@gmail.com', N'34gtgtw454744', N'89501903393', N'', N'Ленинина д 203', CAST(N'2019-03-20' AS Date), 0, NULL)
GO
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (201, N'Антон', N'Степанов', N'89221472708_@gmail.com', N'34gtgtw454745', N'89221472708', N'', N'Ленинина д 204', CAST(N'2019-03-21' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (202, N'Марина', N'Золотова', N'89126271101_@gmail.com', N'34gtgtw454746', N'89126271101', N'', N'Ленинина д 205', CAST(N'2019-03-22' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (203, N'Елена', N'Полотова', N'89221273364_@gmail.com', N'34gtgtw454747', N'89221273364', N'', N'Ленинина д 206', CAST(N'2019-03-23' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (204, N'Константин', N'Мымрин', N'89658485533_@gmail.com', N'34gtgtw454748', N'89658485533', N'', N'Ленинина д 207', CAST(N'2019-03-24' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (205, N'Денис', N'Иванов', N'89655733447_@gmail.com', N'34gtgtw454749', N'89655733447', N'', N'Ленинина д 208', CAST(N'2019-03-25' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (206, N'Виктор', N'Алейников', N'89530403534_@gmail.com', N'34gtgtw454750', N'89530403534', N'', N'Ленинина д 209', CAST(N'2019-03-26' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (207, N'Татьяна', N'Оносова', N'89501941027_@gmail.com', N'34gtgtw454751', N'89501941027', N'', N'Ленинина д 210', CAST(N'2019-03-27' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (208, N'Татьяна', N'Шавкунова', N'89043837213_@gmail.com', N'34gtgtw454752', N'89043837213', N'', N'Ленинина д 211', CAST(N'2019-03-28' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (209, N'Анастасия', N'Мифтахова', N'89506508360_@gmail.com', N'34gtgtw454753', N'89506508360', N'', N'Ленинина д 212', CAST(N'2019-03-29' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (210, N'Татьяна', N'Колмогорова', N'89041686220_@gmail.com', N'34gtgtw454754', N'89041686220', N'', N'Ленинина д 213', CAST(N'2019-03-30' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (211, N'Тимур', N'Сафаров', N'89221446768_@gmail.com', N'34gtgtw454755', N'89221446768', N'', N'Ленинина д 214', CAST(N'2019-03-31' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (212, N'Алёна', N'Шипаева', N'89826437263_@gmail.com', N'34gtgtw454756', N'89826437263', N'89826457265', N'Ленинина д 215', CAST(N'2019-04-01' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (213, N'Олеговна', N'Бородина', N'89002004910_@gmail.com', N'34gtgtw454757', N'89002004910', N'', N'Ленинина д 216', CAST(N'2019-04-02' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (214, N'Андрей', N'Минаев', N'89536049519_@gmail.com', N'34gtgtw454758', N'89536049519', N'', N'Ленинина д 217', CAST(N'2019-04-03' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (215, N'Любовь', N'Смолина', N'89122485171_@gmail.com', N'34gtgtw454759', N'89122485171', N'', N'Ленинина д 218', CAST(N'2019-04-04' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (216, N'Ирина', N'Бондаренко', N'89222987694_@gmail.com', N'34gtgtw454760', N'89222987694', N'', N'Ленинина д 219', CAST(N'2019-04-05' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (217, N'Алёна', N'Чулкова', N'89292145998_@gmail.com', N'34gtgtw454761', N'89292145998', N'', N'Ленинина д 220', CAST(N'2019-04-06' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (218, N'Владимир', N'Кондратьев', N'89995599202_@gmail.com', N'34gtgtw454762', N'89995599202', N'', N'Ленинина д 221', CAST(N'2019-04-07' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (219, N'Миляуша', N'Закиева', N'89603975764_@gmail.com', N'34gtgtw454763', N'89603975764', N'', N'Ленинина д 222', CAST(N'2019-04-08' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (220, N'Михаил', N'Игнатьев', N'89024497577_@gmail.com', N'34gtgtw454764', N'89024497577', N'', N'Ленинина д 223', CAST(N'2019-04-09' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (221, N'Марина', N'Бунькова', N'89089226001_@gmail.com', N'34gtgtw454765', N'89089226001', N'', N'Ленинина д 224', CAST(N'2019-04-10' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (222, N'Анна', N'Гайцева', N'89826311123_@gmail.com', N'34gtgtw454766', N'89826311123', N'', N'Ленинина д 225', CAST(N'2019-04-11' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (223, N'Татьяна', N'Шляпникова', N'89041679231_@gmail.com', N'34gtgtw454767', N'89041679231', N'', N'Ленинина д 226', CAST(N'2019-04-12' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (224, N'Фарил', N'Фазлиахметов', N'89221782205_@gmail.com', N'34gtgtw454768', N'89221782205', N'', N'Ленинина д 227', CAST(N'2019-04-13' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (225, N'Ольга', N'Кузнецова', N'89045482848_@gmail.com', N'34gtgtw454769', N'89045482848', N'', N'Ленинина д 228', CAST(N'2019-04-14' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (226, N'Ирина', N'Рябкова', N'89923470148_@gmail.com', N'34gtgtw454770', N'89923470148', N'', N'Ленинина д 229', CAST(N'2019-04-15' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (227, N'Дарья', N'Пинясова', N'89014398472_@gmail.com', N'34gtgtw454771', N'89014398472', N'', N'Ленинина д 230', CAST(N'2019-04-16' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (228, N'Алексей', N'Левенских', N'89122896528_@gmail.com', N'34gtgtw454772', N'89122896528', N'', N'Ленинина д 231', CAST(N'2019-04-17' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (229, N'Анастасия', N'Берсенева', N'89826977322_@gmail.com', N'34gtgtw454773', N'89826977322', N'', N'Ленинина д 232', CAST(N'2019-04-18' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (230, N'Ольга', N'Кулакова', N'89068053363_@gmail.com', N'34gtgtw454774', N'89068053363', N'', N'Ленинина д 233', CAST(N'2019-04-19' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (231, N'Татьяна', N'Фомина', N'89122135257_@gmail.com', N'34gtgtw454775', N'89122135257', N'', N'Ленинина д 234', CAST(N'2019-04-20' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (232, N'Юлия', N'Пожидаева', N'89826537945_@gmail.com', N'34gtgtw454776', N'89826537945', N'', N'Ленинина д 235', CAST(N'2019-04-21' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (233, N'Никита', N'Нуйкин', N'89995614541_@gmail.com', N'34gtgtw454777', N'89995614541', N'', N'Ленинина д 236', CAST(N'2019-04-22' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (234, N'Александр', N'Чижов', N'89019506466_@gmail.com', N'34gtgtw454778', N'89019506466', N'', N'Ленинина д 237', CAST(N'2019-04-23' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (235, N'Анна', N'Меньшикова', N'89827476867_@gmail.com', N'34gtgtw454779', N'89827476867', N'', N'Ленинина д 238', CAST(N'2019-04-24' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (236, N'Гульнара', N'Сергеева', N'89655219391_@gmail.com', N'34gtgtw454780', N'89655219391', N'', N'Ленинина д 239', CAST(N'2019-04-25' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (237, N'Ярослав', N'Иванов', N'89826155685_@gmail.com', N'34gtgtw454781', N'89826155685', N'', N'Ленинина д 240', CAST(N'2019-04-26' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (238, N'Василий', N'Аношин', N'89630556364_@gmail.com', N'34gtgtw454782', N'89630556364', N'', N'Ленинина д 241', CAST(N'2019-04-27' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (239, N'Анастасия', N'Воронина', N'89221344355_@gmail.com', N'34gtgtw454783', N'89221344355', N'', N'Ленинина д 242', CAST(N'2019-04-28' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (240, N'Александр', N'Докторов', N'89827290999_@gmail.com', N'34gtgtw454784', N'89827290999', N'', N'Ленинина д 243', CAST(N'2019-04-29' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (241, N'Максим', N'Янилов', N'_@gmail.com', N'34gtgtw454785', N'', N'', N'Ленинина д 244', CAST(N'2019-04-30' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (242, N'Татьяна', N'Макарова', N'89002135683_@gmail.com', N'34gtgtw454786', N'89002135683', N'', N'Ленинина д 245', CAST(N'2019-05-01' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (243, N'Светлана', N'Пушкарева', N'89022544697_@gmail.com', N'34gtgtw454787', N'89022544697', N'', N'Ленинина д 246', CAST(N'2019-05-02' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (244, N'Анастасия', N'Будник', N'89221271311_@gmail.com', N'34gtgtw454788', N'89221271311', N'', N'Ленинина д 247', CAST(N'2019-05-03' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (245, N'Юлия', N'Лямкина', N'89221595115_@gmail.com', N'34gtgtw454789', N'89221595115', N'', N'Ленинина д 248', CAST(N'2019-05-04' AS Date), 1, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (246, N'Софья', N'Шмелева', N'89049815503_@gmail.com', N'34gtgtw454790', N'89049815503', N'', N'Ленинина д 249', CAST(N'2019-05-05' AS Date), 0, NULL)
INSERT [dbo].[client] ([client_id], [first_name], [last_name], [email], [password], [phone], [phone_2], [address], [registration_date], [gender_id], [first_order_date_time]) VALUES (247, N'Ахлиддин', N'Кодиров', N'89193798390_@gmail.com', N'34gtgtw454791', N'89193798390', N'', N'Ленинина д 250', CAST(N'2019-05-06' AS Date), 1, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (1, CAST(N'2019-01-12T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 8, 1)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (2, CAST(N'2019-01-13T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 9, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (3, CAST(N'2019-01-14T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 10, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (4, CAST(N'2019-01-15T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-01-16T00:00:00.000' AS DateTime), 11, 4)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (5, CAST(N'2019-01-16T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 12, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (6, CAST(N'2019-01-17T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 13, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (7, CAST(N'2019-01-18T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 14, 7)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (8, CAST(N'2019-01-19T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 15, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (9, CAST(N'2019-01-20T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-01-21T00:00:00.000' AS DateTime), 16, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (10, CAST(N'2019-01-21T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-01-22T00:00:00.000' AS DateTime), 17, 10)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (11, CAST(N'2019-01-22T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-01-23T00:00:00.000' AS DateTime), 18, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (12, CAST(N'2019-01-23T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-01-24T00:00:00.000' AS DateTime), 19, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (13, CAST(N'2019-01-24T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-01-25T00:00:00.000' AS DateTime), 20, 13)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (14, CAST(N'2019-01-25T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 108, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (15, CAST(N'2019-01-26T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-01-27T00:00:00.000' AS DateTime), 109, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (16, CAST(N'2019-01-27T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-01-28T00:00:00.000' AS DateTime), 110, 2)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (17, CAST(N'2019-01-28T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-01-29T00:00:00.000' AS DateTime), 111, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (18, CAST(N'2019-01-29T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-01-30T00:00:00.000' AS DateTime), 112, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (19, CAST(N'2019-01-30T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-01-31T00:00:00.000' AS DateTime), 113, 5)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (20, CAST(N'2019-01-31T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-01T00:00:00.000' AS DateTime), 114, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (21, CAST(N'2019-02-01T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-02T00:00:00.000' AS DateTime), 115, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (22, CAST(N'2019-02-02T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 116, 8)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (23, CAST(N'2019-02-03T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-04T00:00:00.000' AS DateTime), 117, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (24, CAST(N'2019-02-04T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 118, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (25, CAST(N'2019-02-05T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-02-06T00:00:00.000' AS DateTime), 119, 11)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (26, CAST(N'2019-02-06T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 120, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (27, CAST(N'2019-02-07T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-08T00:00:00.000' AS DateTime), 121, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (28, CAST(N'2019-02-08T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 122, 14)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (29, CAST(N'2019-02-09T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-10T00:00:00.000' AS DateTime), 36, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (30, CAST(N'2019-02-10T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-11T00:00:00.000' AS DateTime), 37, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (31, CAST(N'2019-02-11T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-02-12T00:00:00.000' AS DateTime), 38, 3)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (32, CAST(N'2019-02-12T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-13T00:00:00.000' AS DateTime), 39, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (33, CAST(N'2019-02-13T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 40, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (34, CAST(N'2019-02-14T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-02-15T00:00:00.000' AS DateTime), 41, 6)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (35, CAST(N'2019-02-15T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-16T00:00:00.000' AS DateTime), 42, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (36, CAST(N'2019-02-16T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-17T00:00:00.000' AS DateTime), 43, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (37, CAST(N'2019-02-17T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-02-18T00:00:00.000' AS DateTime), 44, 9)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (38, CAST(N'2019-02-18T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 45, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (39, CAST(N'2019-02-19T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-20T00:00:00.000' AS DateTime), 46, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (40, CAST(N'2019-02-20T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-02-21T00:00:00.000' AS DateTime), 47, 12)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (41, CAST(N'2019-02-21T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-22T00:00:00.000' AS DateTime), 48, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (42, CAST(N'2019-02-22T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-23T00:00:00.000' AS DateTime), 49, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (43, CAST(N'2019-02-23T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 50, 1)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (44, CAST(N'2019-02-24T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-25T00:00:00.000' AS DateTime), 51, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (45, CAST(N'2019-02-25T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-26T00:00:00.000' AS DateTime), 52, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (46, CAST(N'2019-02-26T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-02-27T00:00:00.000' AS DateTime), 53, 4)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (47, CAST(N'2019-02-27T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-02-28T00:00:00.000' AS DateTime), 54, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (48, CAST(N'2019-02-28T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 55, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (49, CAST(N'2019-03-01T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-02T00:00:00.000' AS DateTime), 56, 7)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (50, CAST(N'2019-03-02T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-03T00:00:00.000' AS DateTime), 57, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (51, CAST(N'2019-03-03T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-04T00:00:00.000' AS DateTime), 58, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (52, CAST(N'2019-03-04T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-05T00:00:00.000' AS DateTime), 59, 10)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (53, CAST(N'2019-03-05T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 60, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (54, CAST(N'2019-03-06T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-07T00:00:00.000' AS DateTime), 61, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (55, CAST(N'2019-03-07T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-08T00:00:00.000' AS DateTime), 62, 13)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (56, CAST(N'2019-03-08T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-09T00:00:00.000' AS DateTime), 63, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (57, CAST(N'2019-03-09T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 64, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (58, CAST(N'2019-03-10T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-11T00:00:00.000' AS DateTime), 65, 2)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (59, CAST(N'2019-03-11T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-12T00:00:00.000' AS DateTime), 66, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (60, CAST(N'2019-03-12T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-13T00:00:00.000' AS DateTime), 67, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (61, CAST(N'2019-03-13T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-14T00:00:00.000' AS DateTime), 68, 5)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (62, CAST(N'2019-03-14T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 69, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (63, CAST(N'2019-03-15T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-16T00:00:00.000' AS DateTime), 70, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (64, CAST(N'2019-03-16T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-17T00:00:00.000' AS DateTime), 71, 8)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (65, CAST(N'2019-03-17T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-18T00:00:00.000' AS DateTime), 72, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (66, CAST(N'2019-03-18T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-19T00:00:00.000' AS DateTime), 73, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (67, CAST(N'2019-03-19T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 74, 11)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (68, CAST(N'2019-03-20T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-21T00:00:00.000' AS DateTime), 75, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (69, CAST(N'2019-03-21T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-22T00:00:00.000' AS DateTime), 76, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (70, CAST(N'2019-03-22T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-23T00:00:00.000' AS DateTime), 77, 14)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (71, CAST(N'2019-03-23T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-24T00:00:00.000' AS DateTime), 78, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (72, CAST(N'2019-03-24T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 79, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (73, CAST(N'2019-03-25T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-26T00:00:00.000' AS DateTime), 80, 3)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (74, CAST(N'2019-03-26T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-27T00:00:00.000' AS DateTime), 81, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (75, CAST(N'2019-03-27T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-03-28T00:00:00.000' AS DateTime), 82, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (76, CAST(N'2019-03-28T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-03-29T00:00:00.000' AS DateTime), 83, 6)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (77, CAST(N'2019-03-29T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 84, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (78, CAST(N'2019-03-30T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 85, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (79, CAST(N'2019-03-31T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-04-01T00:00:00.000' AS DateTime), 86, 9)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (80, CAST(N'2019-04-01T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-02T00:00:00.000' AS DateTime), 87, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (81, CAST(N'2019-04-02T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-03T00:00:00.000' AS DateTime), 88, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (82, CAST(N'2019-04-03T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-04-04T00:00:00.000' AS DateTime), 89, 12)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (83, CAST(N'2019-04-04T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 90, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (84, CAST(N'2019-04-05T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-06T00:00:00.000' AS DateTime), 91, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (85, CAST(N'2019-04-06T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-04-07T00:00:00.000' AS DateTime), 92, 1)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (86, CAST(N'2019-04-07T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-08T00:00:00.000' AS DateTime), 93, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (87, CAST(N'2019-04-08T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-09T00:00:00.000' AS DateTime), 94, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (88, CAST(N'2019-04-09T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 95, 4)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (89, CAST(N'2019-04-10T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-11T00:00:00.000' AS DateTime), 96, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (90, CAST(N'2019-04-11T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-12T00:00:00.000' AS DateTime), 97, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (91, CAST(N'2019-04-12T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-04-13T00:00:00.000' AS DateTime), 98, 7)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (92, CAST(N'2019-04-13T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-14T00:00:00.000' AS DateTime), 99, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (93, CAST(N'2019-04-14T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 100, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (94, CAST(N'2019-04-15T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-04-16T00:00:00.000' AS DateTime), 101, 10)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (95, CAST(N'2019-04-16T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-17T00:00:00.000' AS DateTime), 102, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (96, CAST(N'2019-04-17T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-18T00:00:00.000' AS DateTime), 103, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (97, CAST(N'2019-04-18T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-04-19T00:00:00.000' AS DateTime), 104, 13)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (98, CAST(N'2019-04-19T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 105, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (99, CAST(N'2019-04-20T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-21T00:00:00.000' AS DateTime), 106, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (100, CAST(N'2019-04-21T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-04-22T00:00:00.000' AS DateTime), 107, 2)
GO
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (101, CAST(N'2019-04-22T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-23T00:00:00.000' AS DateTime), 108, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (102, CAST(N'2019-04-23T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-24T00:00:00.000' AS DateTime), 109, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (103, CAST(N'2019-04-24T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 110, 5)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (104, CAST(N'2019-04-25T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-26T00:00:00.000' AS DateTime), 111, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (105, CAST(N'2019-04-26T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-27T00:00:00.000' AS DateTime), 112, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (106, CAST(N'2019-04-27T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-04-28T00:00:00.000' AS DateTime), 113, 8)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (107, CAST(N'2019-04-28T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-04-29T00:00:00.000' AS DateTime), 114, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (108, CAST(N'2019-04-29T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 115, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (109, CAST(N'2019-04-30T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-01T00:00:00.000' AS DateTime), 116, 11)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (110, CAST(N'2019-05-01T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-02T00:00:00.000' AS DateTime), 117, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (111, CAST(N'2019-05-02T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-03T00:00:00.000' AS DateTime), 118, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (112, CAST(N'2019-05-03T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-04T00:00:00.000' AS DateTime), 119, 14)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (113, CAST(N'2019-05-04T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 120, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (114, CAST(N'2019-05-05T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-06T00:00:00.000' AS DateTime), 121, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (115, CAST(N'2019-05-06T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-07T00:00:00.000' AS DateTime), 122, 3)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (116, CAST(N'2019-05-07T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-08T00:00:00.000' AS DateTime), 8, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (117, CAST(N'2019-05-08T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-09T00:00:00.000' AS DateTime), 9, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (118, CAST(N'2019-05-09T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 10, 6)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (119, CAST(N'2019-05-10T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-11T00:00:00.000' AS DateTime), 11, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (120, CAST(N'2019-05-11T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-12T00:00:00.000' AS DateTime), 12, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (121, CAST(N'2019-05-12T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-13T00:00:00.000' AS DateTime), 13, 9)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (122, CAST(N'2019-05-13T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-14T00:00:00.000' AS DateTime), 14, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (123, CAST(N'2019-05-14T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 15, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (124, CAST(N'2019-05-15T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-16T00:00:00.000' AS DateTime), 16, 12)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (125, CAST(N'2019-05-16T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-17T00:00:00.000' AS DateTime), 17, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (126, CAST(N'2019-05-17T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-18T00:00:00.000' AS DateTime), 18, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (127, CAST(N'2019-05-18T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-19T00:00:00.000' AS DateTime), 19, 1)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (128, CAST(N'2019-05-19T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 20, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (129, CAST(N'2019-05-20T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-21T00:00:00.000' AS DateTime), 21, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (130, CAST(N'2019-05-21T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-22T00:00:00.000' AS DateTime), 22, 4)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (131, CAST(N'2019-05-22T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-23T00:00:00.000' AS DateTime), 23, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (132, CAST(N'2019-05-23T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-24T00:00:00.000' AS DateTime), 24, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (133, CAST(N'2019-05-24T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 25, 7)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (134, CAST(N'2019-05-25T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-26T00:00:00.000' AS DateTime), 26, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (135, CAST(N'2019-05-26T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-27T00:00:00.000' AS DateTime), 27, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (136, CAST(N'2019-05-27T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-28T00:00:00.000' AS DateTime), 28, 10)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (137, CAST(N'2019-05-28T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-05-29T00:00:00.000' AS DateTime), 29, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (138, CAST(N'2019-05-29T00:00:00.000' AS DateTime), 1, 0, 1, N'', NULL, 30, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (139, CAST(N'2019-05-30T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-05-31T00:00:00.000' AS DateTime), 31, 13)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (140, CAST(N'2019-05-31T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-06-01T00:00:00.000' AS DateTime), 32, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (141, CAST(N'2019-06-01T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-06-02T00:00:00.000' AS DateTime), 33, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (142, CAST(N'2019-06-02T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-06-03T00:00:00.000' AS DateTime), 34, 2)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (143, CAST(N'2019-06-03T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-06-04T00:00:00.000' AS DateTime), 35, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (144, CAST(N'2019-06-04T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-06-05T00:00:00.000' AS DateTime), 36, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (145, CAST(N'2019-06-05T00:00:00.000' AS DateTime), 3, 1, 4, N'Ленина д 7', CAST(N'2019-06-06T00:00:00.000' AS DateTime), 37, 5)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (146, CAST(N'2019-06-06T00:00:00.000' AS DateTime), 2, 0, 3, N'', NULL, 38, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (147, CAST(N'2019-06-07T00:00:00.000' AS DateTime), 2, 0, 3, N'', NULL, 39, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (148, CAST(N'2019-06-08T00:00:00.000' AS DateTime), 2, 1, 3, N'Ленина д 7', NULL, 40, 8)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (149, CAST(N'2019-06-09T00:00:00.000' AS DateTime), 3, 0, 3, N'', NULL, 41, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (150, CAST(N'2019-06-10T00:00:00.000' AS DateTime), 3, 0, 3, N'', NULL, 42, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (151, CAST(N'2019-06-11T00:00:00.000' AS DateTime), 3, 1, 3, N'Ленина д 7', NULL, 43, 11)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (152, CAST(N'2019-06-12T00:00:00.000' AS DateTime), 2, 0, 3, N'', NULL, 44, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (153, CAST(N'2019-06-13T00:00:00.000' AS DateTime), 3, 0, 3, N'', NULL, 45, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (154, CAST(N'2019-06-14T00:00:00.000' AS DateTime), 3, 1, 3, N'Ленина д 7', NULL, 46, 14)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (155, CAST(N'2019-06-15T00:00:00.000' AS DateTime), 3, 0, 3, N'', NULL, 47, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (156, CAST(N'2019-06-16T00:00:00.000' AS DateTime), 2, 0, 3, N'', NULL, 48, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (157, CAST(N'2019-06-17T00:00:00.000' AS DateTime), 1, 1, 1, N'Ленина д 7', NULL, 49, 3)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (158, CAST(N'2019-06-18T00:00:00.000' AS DateTime), 3, 0, 3, N'', NULL, 50, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (159, CAST(N'2019-06-19T00:00:00.000' AS DateTime), 3, 0, 4, N'', CAST(N'2019-06-20T00:00:00.000' AS DateTime), 51, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (160, CAST(N'2019-06-20T00:00:00.000' AS DateTime), 2, 1, 3, N'Ленина д 7', NULL, 52, 6)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (161, CAST(N'2019-06-21T00:00:00.000' AS DateTime), 3, 0, 3, N'', NULL, 53, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (162, CAST(N'2019-06-22T00:00:00.000' AS DateTime), 3, 0, 3, N'', NULL, 54, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (163, CAST(N'2019-06-23T00:00:00.000' AS DateTime), 3, 1, 3, N'Ленина д 7', NULL, 55, 9)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (164, CAST(N'2019-06-24T00:00:00.000' AS DateTime), 2, 0, 3, N'', NULL, 56, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (165, CAST(N'2019-06-25T00:00:00.000' AS DateTime), 3, 0, 2, N'', NULL, 57, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (166, CAST(N'2019-06-26T00:00:00.000' AS DateTime), 3, 1, 2, N'Ленина д 7', NULL, 58, 12)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (167, CAST(N'2019-06-27T00:00:00.000' AS DateTime), 3, 0, 2, N'', NULL, 59, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (168, CAST(N'2019-06-28T00:00:00.000' AS DateTime), 3, 0, 2, N'', NULL, 60, NULL)
INSERT [dbo].[client_order] ([order_id], [date_time], [order_pay_status_id], [delivery_type], [order_delivery_status_id], [delivery_address], [delivered_date_time], [client_id], [response_courier_id]) VALUES (169, CAST(N'2019-06-29T00:00:00.000' AS DateTime), 3, 1, 2, N'Ленина д 7', NULL, 61, 15)
INSERT [dbo].[delivery_status] ([id], [status]) VALUES (1, N'Отмена')
INSERT [dbo].[delivery_status] ([id], [status]) VALUES (2, N'Собирается')
INSERT [dbo].[delivery_status] ([id], [status]) VALUES (3, N'Доставляется')
INSERT [dbo].[delivery_status] ([id], [status]) VALUES (4, N'Доставлено')
INSERT [dbo].[delivery_status] ([id], [status]) VALUES (5, N'Сформирован')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (1, N'Свежие продукты', N'Маяковская д 10', N'89122205050', 1000.0000, 1, 10, N'qr.com')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (2, N'Техника Быстро', N'Ленинский проспект д 5', N'89502068866', 100000.0000, 2, 3, N'')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (3, N'Д-Дистрибьюшен', N'Карла Маркса д 6', N'89222051220', 400000.0000, 4, 7, N'')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (4, N'Книжный мир', N'Лесная д. 9', N'89045455146', 10000.0000, 1, 1, N'rtyq.ru')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (5, N'Веселый Фермер', N'Арбатская д. 16', N'89326134422', 10000.0000, 4, 7, N'fermer.com')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (6, N'ЛКМ-Дистрибуция', N'Шашкина дом 7', N'89226010149', 60000.0000, 1, 2, N'')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (7, N'Перевозки Петрович', N'Марксисткая д 3', N'89120474424', 50000.0000, 1, 3, N'petrovich.com')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (8, N'IT-дистрибьюшен ', N'Старокачаловская д 9', N'89028773318', 10000.0000, 5, 6, N'')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (9, N'Проект Дистрибуция', N'Ольховская д 6', N'89064560978', 500.0000, 1, 1, N'')
INSERT [dbo].[distributor] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (10, N'Холи Вотерс', N'Краснопресненская д 10', N'89226115539', 20000.0000, 3, 8, N'')
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (1, N'Юлия', N'Черемныx', N'89028770034', N'89028770034_@gmail.com', N'аналитик', 1, 1)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (2, N'Владислав', N'Щукин', N'89105229650', N'89105229650_@gmail.com', N'аналитик', 0, 2)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (3, N'Борис', N'Татарчевский', N'89501944796', N'89501944796_@gmail.com', N'аналитик', 1, 3)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (4, N'Евгения', N'Грачева', N'89506498536', N'89506498536_@gmail.com', N'аналитик', 0, 4)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (5, N'Марина', N'Бушуева', N'89222145883', N'89222145883_@gmail.com', N'бухгалтер', 1, 5)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (6, N'Юлия', N'Мавлютова', N'89221333327', N'89221333327_@gmail.com', N'бухгалтер', 0, 6)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (7, N'Екатерина', N'Некрасова', N'89041684175', N'89041684175_@gmail.com', N'бухгалтер', 1, 7)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (8, N'Эльвира', N'Тажиева', N'89655321999', N'89655321999_@gmail.com', N'бухгалтер', 0, 8)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (9, N'Иван', N'Почечун', N'89655422731', N'89655422731_@gmail.com', N'генеральный директор', 1, 9)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (10, N'Анна', N'Волобуева', N'89028716367', N'89028716367_@gmail.com', N'генеральный директор', 0, 10)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (11, N'Елена', N'Игнатьева', N'89021514891', N'89021514891_@gmail.com', N'генеральный директор', 1, 1)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (12, N'Вера', N'Кузнецова', N'89028732185', N'89028732185_@gmail.com', N'генеральный директор', 0, 2)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (13, N'Екатерина', N'Сикимова', N'89644884418', N'89644884418_@gmail.com', N'главный бухгалтер', 1, 3)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (14, N'Ирина', N'Мамонтова', N'89220377811', N'89220377811_@gmail.com', N'главный бухгалтер', 0, 4)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (15, N'Мария', N'Шипиловская', N'89122575557', N'89122575557_@gmail.com', N'главный бухгалтер', 1, 5)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (16, N'Лейла', N'Дурнева', N'89220252021', N'89220252021_@gmail.com', N'главный бухгалтер', 0, 6)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (17, N'Николай', N'Соломин', N'89090058780', N'89090058780_@gmail.com', N'Директор по логистике', 1, 7)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (18, N'Ольга', N'Ильященко', N'89995665306', N'89995665306_@gmail.com', N'Директор по логистике', 0, 8)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (19, N'Николай', N'Федоров', N'89505569807', N'89505569807_@gmail.com', N'Директор по логистике', 1, 9)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (20, N'Алёна', N'Полинская', N'89089163888', N'89089163888_@gmail.com', N'Директор по логистике', 1, 10)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (21, N'Ольга', N'Власова', N'89292183919', N'89292183919_@gmail.com', N'директор по маркетингу', 0, 1)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (22, N'Яна', N'Бизянова', N'89045441346', N'89045441346_@gmail.com', N'директор по маркетингу', 1, 2)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (23, N'Елена', N'Дударева', N'89221196264', N'89221196264_@gmail.com', N'директор по маркетингу', 0, 3)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (24, N'Ярослав', N'Касьянов', N'89655458067', N'89655458067_@gmail.com', N'директор по маркетингу', 1, 4)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (25, N'Наталья', N'Казанцева', N'89122505085', N'89122505085_@gmail.com', N'Коммерческий директор', 0, 5)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (26, N'Илья', N'Самойлов', N'89221219282', N'89221219282_@gmail.com', N'Коммерческий директор', 1, 6)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (27, N'Юлия', N'Голдобина', N'89995659577', N'89995659577_@gmail.com', N'Коммерческий директор', 0, 7)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (28, N'Дилмурод', N'Байназаров', N'89030808383', N'89030808383_@gmail.com', N'Коммерческий директор', 1, 8)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (29, N'Елена', N'Никонова', N'89049864350', N'89049864350_@gmail.com', N'маркетолог', 0, 9)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (30, N'Марина', N'Ледяйкина', N'89827012820', N'89827012820_@gmail.com', N'маркетолог', 1, 10)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (31, N'Иван', N'Корниенко', N'89521491856', N'89521491856_@gmail.com', N'маркетолог', 0, 1)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (32, N'Дмитрий', N'Лебедев', N'89122249886', N'89122249886_@gmail.com', N'маркетолог', 1, 2)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (33, N'Зоя', N'Иванова', N'89041748686', N'89041748686_@gmail.com', N'секретарь', 0, 3)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (34, N'Светлана', N'Чеченева', N'89122821131', N'89122821131_@gmail.com', N'секретарь', 1, 4)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (35, N'Валерий', N'Иванов', N'89122840765', N'89122840765_@gmail.com', N'секретарь', 0, 5)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (36, N'Александр', N'Неуймин', N'89126563433', N'89028770034_@gmail.com', N'секретарь', 1, 6)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (37, N'Марина', N'Семенова', N'89226188030', N'89105229650_@gmail.com', N'финансовый директор', 0, 7)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (38, N'Рима', N'Мурзина', N'89090032333', N'89501944796_@gmail.com', N'финансовый директор', 1, 8)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (39, N'Сергей', N'Александров', N'89043837131', N'89506498536_@gmail.com', N'финансовый директор', 1, 9)
INSERT [dbo].[distributor_contact] ([dist_employ_id], [fist_name], [last_name], [working_phone_number], [email], [position], [gender], [dist_id]) VALUES (40, N'Наталья', N'Попова', N'89221457962', N'89222145883_@gmail.com', N'финансовый директор', 1, 10)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 1, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 18, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 35, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 48, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 52, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 69, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 86, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 103, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 120, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 137, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 138, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 155, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 156, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 157, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 158, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 159, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 160, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 161, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 162, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (1, CAST(150.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 163, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 2, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 19, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 36, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 48, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 53, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 70, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 87, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 104, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 121, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 139, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (2, CAST(90.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 156, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 3, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 20, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 37, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 54, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 71, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 88, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 105, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 122, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 140, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 157, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (3, CAST(50.50 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 169, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 4, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 14, 7)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 21, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 38, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 55, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 72, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 89, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 106, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 123, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 141, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 158, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (4, CAST(80.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 169, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 5, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 14, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 22, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 39, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 56, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 73, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 90, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 107, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 124, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 142, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 159, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (5, CAST(110.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 169, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 6, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 14, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 23, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 40, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 57, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 74, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 91, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 108, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 125, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 142, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 143, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (6, CAST(60.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 160, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 7, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 24, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 41, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 58, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 75, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 92, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 109, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 126, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 142, 7)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 144, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (7, CAST(89999.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 161, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 8, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 25, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 42, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 59, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 76, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 93, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 110, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 127, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 142, 7)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 145, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (8, CAST(80000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 162, 6)
GO
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 9, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 26, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 43, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 60, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 77, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 94, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 111, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 128, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 146, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (9, CAST(70000.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 163, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 10, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 27, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 44, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 61, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 78, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 95, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 112, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 129, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 147, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (10, CAST(75560.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 164, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 11, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 28, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 45, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 62, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 79, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 96, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 113, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 130, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 148, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (11, CAST(21990.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 165, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 12, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 29, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 46, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 63, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 80, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 97, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 114, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 131, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 149, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (12, CAST(83450.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 166, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 13, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 30, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 47, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 64, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 81, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 98, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 115, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 132, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 150, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (13, CAST(24.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 167, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 14, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 31, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 48, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 65, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 82, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 99, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 116, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 133, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 151, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (14, CAST(100.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 168, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 1, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 2, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 3, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 4, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 5, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 6, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 7, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 8, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 9, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 10, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 11, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 12, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 13, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 14, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 16, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 32, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 49, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 66, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 83, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 100, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 117, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 134, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 152, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (15, CAST(959.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 169, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 16, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 33, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 50, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 67, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 84, 4)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 101, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 118, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 135, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (16, CAST(458.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 153, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 17, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 34, 3)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 51, 6)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 68, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 85, 5)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 102, 1)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 119, 5)
GO
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 136, 2)
INSERT [dbo].[items_in_order] ([product_id], [price], [promo_percentage], [order_id], [quantity]) VALUES (17, CAST(390.00 AS Numeric(8, 2)), CAST(0.00 AS Numeric(4, 2)), 154, 1)
INSERT [dbo].[manufacturer] ([manifact_id], [manufact_name], [site], [country_of_orign], [description]) VALUES (1, N'Apple', N'apple.com', N'America', N'не определено')
INSERT [dbo].[manufacturer] ([manifact_id], [manufact_name], [site], [country_of_orign], [description]) VALUES (2, N'Samsung', N'samsung.com', N'Korea', N'не определено')
INSERT [dbo].[manufacturer] ([manifact_id], [manufact_name], [site], [country_of_orign], [description]) VALUES (3, N'Родная грядка', N'родная_грядка.com', N'Россия', N'не определено')
INSERT [dbo].[manufacturer] ([manifact_id], [manufact_name], [site], [country_of_orign], [description]) VALUES (4, N'Первый урожай', N'первый_урожай.com', N'Россия', N'не определено')
INSERT [dbo].[manufacturer] ([manifact_id], [manufact_name], [site], [country_of_orign], [description]) VALUES (5, N'Book Shelf', N'book_shelf.com', N'Россия', N'не определено')
INSERT [dbo].[manufacturer] ([manifact_id], [manufact_name], [site], [country_of_orign], [description]) VALUES (6, N'Амигос', N'amigos.com', N'Россия', N'не определено')
INSERT [dbo].[payment_status] ([id], [status]) VALUES (1, N'Отмена')
INSERT [dbo].[payment_status] ([id], [status]) VALUES (2, N'Ожидается оплата')
INSERT [dbo].[payment_status] ([id], [status]) VALUES (3, N'Оплачено')
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (1, CAST(N'2019-01-07T00:00:00.000' AS DateTime), 1, CAST(100.00 AS Numeric(8, 2)), CAST(160.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (2, CAST(N'2019-02-07T00:00:00.000' AS DateTime), 2, CAST(90.00 AS Numeric(8, 2)), CAST(80.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (3, CAST(N'2019-01-07T00:00:00.000' AS DateTime), 1, CAST(30.00 AS Numeric(8, 2)), CAST(35.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (4, CAST(N'2019-04-07T00:00:00.000' AS DateTime), 1, CAST(70.00 AS Numeric(8, 2)), CAST(85.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (1, CAST(N'2019-04-03T00:00:00.000' AS DateTime), 1, CAST(160.00 AS Numeric(8, 2)), CAST(150.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (2, CAST(N'2019-02-10T00:00:00.000' AS DateTime), 1, CAST(80.00 AS Numeric(8, 2)), CAST(90.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (3, CAST(N'2019-03-07T00:00:00.000' AS DateTime), 4, CAST(35.00 AS Numeric(8, 2)), CAST(50.50 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (4, CAST(N'2019-02-01T00:00:00.000' AS DateTime), 2, CAST(85.00 AS Numeric(8, 2)), CAST(80.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (10, CAST(N'2019-01-07T00:00:00.000' AS DateTime), 4, CAST(70000.00 AS Numeric(8, 2)), CAST(75560.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (15, CAST(N'2019-02-07T00:00:00.000' AS DateTime), 4, CAST(800.00 AS Numeric(8, 2)), CAST(959.00 AS Numeric(8, 2)))
INSERT [dbo].[price_change] ([product_id], [date_time_change], [response_emp_id], [price_old_value], [price_new_value]) VALUES (4, CAST(N'2019-09-03T20:36:22.357' AS DateTime), 1, CAST(40.00 AS Numeric(8, 2)), CAST(50.00 AS Numeric(8, 2)))
INSERT [dbo].[prod_type_minimal] ([min_type_id], [product_type_name], [description]) VALUES (1, N'яблоки', N'Not Assigned')
INSERT [dbo].[prod_type_minimal] ([min_type_id], [product_type_name], [description]) VALUES (2, N'огурцы', N'Not Assigned')
INSERT [dbo].[prod_type_minimal] ([min_type_id], [product_type_name], [description]) VALUES (3, N'капуста', N'Not Assigned')
INSERT [dbo].[prod_type_minimal] ([min_type_id], [product_type_name], [description]) VALUES (4, N'мобильные телефоны', N'Not Assigned')
INSERT [dbo].[prod_type_minimal] ([min_type_id], [product_type_name], [description]) VALUES (5, N'телевизоры', N'Not Assigned')
INSERT [dbo].[prod_type_minimal] ([min_type_id], [product_type_name], [description]) VALUES (6, N'блокноты', N'Not Assigned')
INSERT [dbo].[prod_type_minimal] ([min_type_id], [product_type_name], [description]) VALUES (7, N'бизнес книги', N'Not Assigned')
INSERT [dbo].[prod_type_minimal] ([min_type_id], [product_type_name], [description]) VALUES (8, N'литература', N'Not Assigned')
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (1, N'Яблоки Гренни, 1 кг', CAST(100.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 36, 4, 1, CAST(0.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (2, N'Яблоки Краснодарские, Красные, 1 кг', CAST(90.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 9, 3, 1, CAST(0.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (3, N'Яблоки Подмосковные, 1кг', CAST(50.50 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 6, 3, 1, CAST(0.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (4, N'Огурцы короткоплодные, 1 кг', CAST(60.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 7, 3, 2, CAST(0.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (5, N'Огурцы Парниковые, 1 кг', CAST(110.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 9, 4, 2, CAST(10.09 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (6, N'Капуста белокочанная', CAST(60.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 7, 3, 3, CAST(45.68 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (7, N'iPhone 8, 128 гб', CAST(89999.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 6, 1, 4, CAST(10.65 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (8, N'iPhone 8, 64 гб', CAST(80000.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 7, 1, 4, CAST(0.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (9, N'iPhone 8, 32 гб', CAST(70000.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 3, 1, 4, CAST(50.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (10, N'Samsung Galaxy A50', CAST(75560.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 43, 2, 4, CAST(0.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (11, N'Телевизор Samsung UE32M5550AU', CAST(21990.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 2, 2, 5, CAST(25.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (12, N'Телевизор Samsung UE32N5300AU', CAST(83450.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 7, 2, 5, CAST(10.09 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (13, N'Блокнот классический, 49 листов', CAST(24.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 7, 5, 6, CAST(90.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (14, N'Блокнот серия "Природа"', CAST(100.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 13, 5, 6, CAST(45.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (15, N'SQL для Чайников ', CAST(959.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 9, 5, 7, CAST(0.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (16, N'Менеджмент 21-го века', CAST(458.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 0, 5, 7, CAST(0.00 AS Numeric(4, 2)))
INSERT [dbo].[product] ([product_id], [name], [current_price], [created_at], [rest_quantity], [manufact_id], [prod_type_id], [current_promo]) VALUES (17, N'Как получить работу мечты', CAST(390.00 AS Numeric(8, 2)), CAST(N'2019-01-01T00:00:00.000' AS DateTime), 43, 5, 7, CAST(9.00 AS Numeric(4, 2)))
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (1, N'яблоки', 1000000, N'фрукты')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (2, N'огурцы', 1000001, N'овощи')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (3, N'капуста', 1000001, N'овощи')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (4, N'мобильные телефоны', 1000002, N'техника')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (5, N'телевизоры', 1000002, N'техника')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (6, N'блокноты', 1000003, N'канцелярия')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (7, N'бизнес книги', 1000004, N'книги')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (8, N'литература', 1000004, N'книги')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (1000000, N'фрукты', 1000005, N'продукты')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (1000001, N'овощи', 1000005, N'продукты')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (1000002, N'техника', 1000006, N'Вся продукция')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (1000003, N'канцелярия', 1000006, N'Вся продукция')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (1000004, N'книги', 1000006, N'Вся продукция')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (1000005, N'продукты', 1000006, N'Вся продукция')
INSERT [dbo].[product_hierarcy] ([min_type_id], [min_type_name], [general_type_id], [general_type_name]) VALUES (1000006, N'Вся продукция', NULL, NULL)
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (2, CAST(8.94 AS Numeric(4, 2)), CAST(N'2019-01-07T00:00:00.000' AS DateTime), CAST(N'2019-01-10T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (3, CAST(45.68 AS Numeric(4, 2)), CAST(N'2019-02-07T00:00:00.000' AS DateTime), CAST(N'2019-02-08T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (4, CAST(10.00 AS Numeric(4, 2)), CAST(N'2019-01-07T00:00:00.000' AS DateTime), CAST(N'2019-03-08T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (5, CAST(10.09 AS Numeric(4, 2)), CAST(N'2019-08-07T00:00:00.000' AS DateTime), CAST(N'2019-10-14T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (6, CAST(45.68 AS Numeric(4, 2)), CAST(N'2019-08-08T00:00:00.000' AS DateTime), CAST(N'2019-09-23T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (7, CAST(90.00 AS Numeric(4, 2)), CAST(N'2019-01-07T00:00:00.000' AS DateTime), CAST(N'2019-01-08T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (7, CAST(20.00 AS Numeric(4, 2)), CAST(N'2019-04-07T00:00:00.000' AS DateTime), CAST(N'2019-04-23T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (7, CAST(20.00 AS Numeric(4, 2)), CAST(N'2019-05-05T00:00:00.000' AS DateTime), CAST(N'2019-05-10T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (7, CAST(10.65 AS Numeric(4, 2)), CAST(N'2019-08-09T00:00:00.000' AS DateTime), CAST(N'2019-09-12T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (8, CAST(45.00 AS Numeric(4, 2)), CAST(N'2019-02-14T00:00:00.000' AS DateTime), CAST(N'2019-02-20T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (8, CAST(50.00 AS Numeric(4, 2)), CAST(N'2019-04-03T00:00:00.000' AS DateTime), CAST(N'2019-04-04T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (8, CAST(5.00 AS Numeric(4, 2)), CAST(N'2019-05-10T00:00:00.000' AS DateTime), CAST(N'2019-05-20T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (8, CAST(20.00 AS Numeric(4, 2)), CAST(N'2019-08-10T00:00:00.000' AS DateTime), CAST(N'2019-08-29T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (9, CAST(35.00 AS Numeric(4, 2)), CAST(N'2019-02-10T00:00:00.000' AS DateTime), CAST(N'2019-02-20T00:00:00.000' AS DateTime), 6, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (9, CAST(50.00 AS Numeric(4, 2)), CAST(N'2019-08-11T00:00:00.000' AS DateTime), CAST(N'2019-10-21T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (10, CAST(25.00 AS Numeric(4, 2)), CAST(N'2019-03-07T00:00:00.000' AS DateTime), CAST(N'2019-03-11T00:00:00.000' AS DateTime), 2, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (10, CAST(10.00 AS Numeric(4, 2)), CAST(N'2019-06-06T00:00:00.000' AS DateTime), CAST(N'2019-06-08T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (10, CAST(60.00 AS Numeric(4, 2)), CAST(N'2019-06-15T00:00:00.000' AS DateTime), CAST(N'2019-06-18T00:00:00.000' AS DateTime), 1, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (10, CAST(35.00 AS Numeric(4, 2)), CAST(N'2019-08-12T00:00:00.000' AS DateTime), CAST(N'2019-09-07T00:00:00.000' AS DateTime), 6, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (11, CAST(5.50 AS Numeric(4, 2)), CAST(N'2019-02-01T00:00:00.000' AS DateTime), CAST(N'2019-02-08T00:00:00.000' AS DateTime), 4, N'Not Assigned')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (11, CAST(25.00 AS Numeric(4, 2)), CAST(N'2019-08-13T00:00:00.000' AS DateTime), CAST(N'2019-09-17T00:00:00.000' AS DateTime), 2, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (12, CAST(10.09 AS Numeric(4, 2)), CAST(N'2019-08-14T00:00:00.000' AS DateTime), CAST(N'2019-09-18T00:00:00.000' AS DateTime), 4, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (13, CAST(90.00 AS Numeric(4, 2)), CAST(N'2019-08-15T00:00:00.000' AS DateTime), CAST(N'2019-10-04T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (13, CAST(10.00 AS Numeric(4, 2)), CAST(N'2019-08-15T00:00:00.000' AS DateTime), CAST(N'2019-12-27T00:00:00.000' AS DateTime), 1, N'promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (14, CAST(45.00 AS Numeric(4, 2)), CAST(N'2019-08-16T00:00:00.000' AS DateTime), CAST(N'2019-09-16T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (14, CAST(10.00 AS Numeric(4, 2)), CAST(N'2019-08-20T00:00:00.000' AS DateTime), CAST(N'2019-09-01T00:00:00.000' AS DateTime), 5, N'promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (17, CAST(8.00 AS Numeric(4, 2)), CAST(N'2019-07-01T00:00:00.000' AS DateTime), CAST(N'2020-08-18T00:00:00.000' AS DateTime), 1, N'Best Promo')
INSERT [dbo].[product_promotion] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (17, CAST(9.00 AS Numeric(4, 2)), CAST(N'2019-08-01T00:00:00.000' AS DateTime), CAST(N'2020-08-18T00:00:00.000' AS DateTime), 1, N'Best')
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (1, 1, 20, 87.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (2, 2, 12, 74.7000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (3, 3, 10, 25.2500)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (4, 4, 11, 64.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (5, 5, 11, 71.5000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (6, 6, 7, 43.8000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (7, 7, 12, 53999.4000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (8, 8, 14, 46400.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (9, 9, 11, 46900.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (10, 10, 14, 68004.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (11, 11, 10, 17372.1000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (12, 12, 10, 45897.5000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (13, 13, 12, 19.9200)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (14, 14, 12, 83.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (15, 15, 17, 537.0400)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (16, 16, 10, 343.5000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (17, 17, 16, 241.8000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (1, 18, 20, 105.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (2, 19, 12, 72.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (3, 20, 9, 43.4300)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (4, 21, 14, 64.8000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (5, 22, 13, 81.4000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (6, 23, 6, 33.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (7, 24, 15, 72899.1900)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (8, 25, 18, 60000.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (9, 26, 10, 52500.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (10, 27, 16, 43824.8000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (11, 28, 12, 16052.7000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (12, 29, 13, 73436.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (13, 30, 13, 12.9600)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (14, 31, 13, 60.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (15, 32, 18, 632.9400)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (16, 1, 9, 293.1200)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (17, 2, 16, 206.7000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (1, 25, 19, 129.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (2, 26, 11, 63.9000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (3, 27, 9, 33.3300)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (4, 28, 11, 47.2000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (5, 29, 12, 69.3000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (6, 30, 10, 48.6000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (7, 31, 13, 62999.3000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (8, 32, 15, 53600.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (9, 1, 11, 58100.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (10, 2, 16, 58936.8000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (11, 3, 10, 19131.3000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (12, 4, 12, 52573.5000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (13, 5, 14, 14.6400)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (14, 6, 14, 62.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (15, 7, 21, 613.7600)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (16, 8, 12, 279.3800)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (17, 3, 16, 284.7000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (1, 20, 50, 87.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (2, 15, 15, 70.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (3, 21, 10, 43.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (10, 11, 45, 65000.0000)
INSERT [dbo].[products_in_supply_order] ([product_id], [supply_id], [quantity], [suplier_price]) VALUES (17, 18, 60, 200.0000)
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (5, CAST(10.09 AS Numeric(4, 2)), CAST(N'2019-08-07T00:00:00.000' AS DateTime), CAST(N'2019-10-14T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (6, CAST(45.68 AS Numeric(4, 2)), CAST(N'2019-08-08T00:00:00.000' AS DateTime), CAST(N'2019-09-23T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (7, CAST(10.65 AS Numeric(4, 2)), CAST(N'2019-08-09T00:00:00.000' AS DateTime), CAST(N'2019-09-12T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (8, CAST(20.00 AS Numeric(4, 2)), CAST(N'2019-08-10T00:00:00.000' AS DateTime), CAST(N'2019-08-29T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (9, CAST(50.00 AS Numeric(4, 2)), CAST(N'2019-08-11T00:00:00.000' AS DateTime), CAST(N'2019-10-21T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (10, CAST(35.00 AS Numeric(4, 2)), CAST(N'2019-08-12T00:00:00.000' AS DateTime), CAST(N'2019-09-07T00:00:00.000' AS DateTime), 6, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (11, CAST(25.00 AS Numeric(4, 2)), CAST(N'2019-08-13T00:00:00.000' AS DateTime), CAST(N'2019-09-17T00:00:00.000' AS DateTime), 2, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (12, CAST(10.09 AS Numeric(4, 2)), CAST(N'2019-08-14T00:00:00.000' AS DateTime), CAST(N'2019-09-18T00:00:00.000' AS DateTime), 4, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (13, CAST(90.00 AS Numeric(4, 2)), CAST(N'2019-08-15T00:00:00.000' AS DateTime), CAST(N'2019-10-04T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (14, CAST(45.00 AS Numeric(4, 2)), CAST(N'2019-08-16T00:00:00.000' AS DateTime), CAST(N'2019-09-16T00:00:00.000' AS DateTime), 1, N'Planned promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (14, CAST(10.00 AS Numeric(4, 2)), CAST(N'2019-08-20T00:00:00.000' AS DateTime), CAST(N'2019-09-01T00:00:00.000' AS DateTime), 5, N'promo')
INSERT [dbo].[promo_planned] ([product_id], [percentage_promo], [start_date_time], [end_date_time], [response_emp_id], [comment]) VALUES (13, CAST(10.00 AS Numeric(4, 2)), CAST(N'2019-08-15T00:00:00.000' AS DateTime), CAST(N'2019-12-27T00:00:00.000' AS DateTime), 1, N'promo')
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (1, N'Виктория', N'Берсенева', 1, N'89221712607', CAST(N'2018-12-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (2, N'Яна', N'Аскаров', 1, N'89001976343', CAST(N'2019-01-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (3, N'Александр', N'Бушмелев', 1, N'89826455261', CAST(N'2019-02-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (4, N'Дмитрий', N'Кузьмина', 1, N'89089245022', CAST(N'2019-03-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (5, N'Диана', N'Яценко', 1, N'89126955576', CAST(N'2019-04-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (6, N'Марина', N'Аубекерова', 1, N'14048341973', CAST(N'2019-05-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (7, N'Андрей', N'Шулаков', 1, N'89826387034', CAST(N'2018-12-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (8, N'Ольга', N'Засыпалова', 1, N'89505427585', CAST(N'2019-01-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (9, N'Зинаида', N'Кораблева', 1, N'89090168845', CAST(N'2019-02-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (10, N'Алексей', N'Сатюкова', 1, N'89126323402', CAST(N'2019-03-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (11, N'Марат', N'Лядов', 1, N'89089235107', CAST(N'2019-04-01' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (12, N'Лев', N'Ан', 1, N'89655414797', CAST(N'2019-04-02' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (13, N'Радион', N'Чжен', 1, N'89995633100', CAST(N'2019-04-03' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (14, N'Александр', N'Дерипаско', 1, N'89222024230', CAST(N'2019-04-04' AS Date), NULL)
INSERT [dbo].[responsible_courier] ([courier_id], [first_name], [last_name], [employ_status_id], [phone], [first_working_day], [last_working_day]) VALUES (15, N'Агарон', N'Кузнецов', 1, N'89222220828', CAST(N'2019-04-05' AS Date), NULL)
INSERT [dbo].[review] ([review_id], [client_review_text], [mark_id], [anonymously], [product_id], [order_id]) VALUES (1, N'Перед покупкой надо требовать проверку на наличие цифрового тюнера, иначе не поймает цифровые каналы. До этого покупал 4-ре аналогичных телевизора Samsung. Все было без проблем. Это пятый, продавец сказал, что проверить можно и дома. Поверил, а зря. Привез домой, при включении не обнаружились символы DTV (антенна не нужна). Подключил кабель, в течении часа пытался поймать цифровые каналы. На прежних телевизорах уходило на это 8-10 минут. Но все бесполезно. ', 3, 0, 10, 4)
INSERT [dbo].[review] ([review_id], [client_review_text], [mark_id], [anonymously], [product_id], [order_id]) VALUES (2, N'Очень вкусные яблоки', 5, 0, 3, 3)
INSERT [dbo].[review] ([review_id], [client_review_text], [mark_id], [anonymously], [product_id], [order_id]) VALUES (3, N'Получился очень вкусный салат из данной капусты - рекомендую', 5, 0, 6, 6)
INSERT [dbo].[review] ([review_id], [client_review_text], [mark_id], [anonymously], [product_id], [order_id]) VALUES (4, N'Книга полезная, преобразил свои знания SQL', 4, 0, 15, 15)
INSERT [dbo].[review] ([review_id], [client_review_text], [mark_id], [anonymously], [product_id], [order_id]) VALUES (5, N'Книга полная вода, крайне не рекомендую', 2, 1, 16, 16)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (1, CAST(N'2019-01-09T00:00:00.000' AS DateTime), NULL, 1, 3, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (2, CAST(N'2019-01-10T00:00:00.000' AS DateTime), NULL, 1, 9, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (3, CAST(N'2019-01-11T00:00:00.000' AS DateTime), NULL, 1, 6, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (4, CAST(N'2019-01-12T00:00:00.000' AS DateTime), CAST(N'2019-01-26T00:00:00.000' AS DateTime), 3, 8, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (5, CAST(N'2019-01-13T00:00:00.000' AS DateTime), CAST(N'2019-01-24T00:00:00.000' AS DateTime), 3, 7, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (6, CAST(N'2019-01-14T00:00:00.000' AS DateTime), CAST(N'2019-01-21T00:00:00.000' AS DateTime), 3, 6, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (7, CAST(N'2019-01-15T00:00:00.000' AS DateTime), CAST(N'2019-01-16T00:00:00.000' AS DateTime), 3, 6, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (8, CAST(N'2019-01-16T00:00:00.000' AS DateTime), CAST(N'2019-02-14T00:00:00.000' AS DateTime), 3, 2, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (9, CAST(N'2019-01-17T00:00:00.000' AS DateTime), CAST(N'2019-01-31T00:00:00.000' AS DateTime), 3, 6, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (10, CAST(N'2019-01-18T00:00:00.000' AS DateTime), CAST(N'2019-01-28T00:00:00.000' AS DateTime), 3, 10, 3)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (11, CAST(N'2019-01-19T00:00:00.000' AS DateTime), CAST(N'2019-01-29T00:00:00.000' AS DateTime), 3, 3, 4)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (12, CAST(N'2019-01-20T00:00:00.000' AS DateTime), CAST(N'2019-02-09T00:00:00.000' AS DateTime), 3, 9, 3)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (13, CAST(N'2019-01-21T00:00:00.000' AS DateTime), CAST(N'2019-02-11T00:00:00.000' AS DateTime), 3, 8, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (14, CAST(N'2019-01-22T00:00:00.000' AS DateTime), CAST(N'2019-01-24T00:00:00.000' AS DateTime), 3, 3, 3)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (15, CAST(N'2019-01-23T00:00:00.000' AS DateTime), CAST(N'2019-01-24T00:00:00.000' AS DateTime), 3, 3, 5)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (16, CAST(N'2019-01-24T00:00:00.000' AS DateTime), CAST(N'2019-02-07T00:00:00.000' AS DateTime), 3, 4, 5)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (17, CAST(N'2019-01-25T00:00:00.000' AS DateTime), CAST(N'2019-02-04T00:00:00.000' AS DateTime), 3, 3, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (18, CAST(N'2019-01-26T00:00:00.000' AS DateTime), CAST(N'2019-02-07T00:00:00.000' AS DateTime), 3, 7, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (19, CAST(N'2019-01-27T00:00:00.000' AS DateTime), CAST(N'2019-02-17T00:00:00.000' AS DateTime), 3, 2, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (20, CAST(N'2019-01-28T00:00:00.000' AS DateTime), CAST(N'2019-02-13T00:00:00.000' AS DateTime), 3, 4, 3)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (21, CAST(N'2019-01-29T00:00:00.000' AS DateTime), CAST(N'2019-02-12T00:00:00.000' AS DateTime), 3, 3, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (22, CAST(N'2019-01-30T00:00:00.000' AS DateTime), CAST(N'2019-01-31T00:00:00.000' AS DateTime), 3, 9, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (23, CAST(N'2019-01-31T00:00:00.000' AS DateTime), CAST(N'2019-02-04T00:00:00.000' AS DateTime), 3, 2, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (24, CAST(N'2019-02-01T00:00:00.000' AS DateTime), CAST(N'2019-02-09T00:00:00.000' AS DateTime), 3, 7, 5)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (25, CAST(N'2019-02-02T00:00:00.000' AS DateTime), CAST(N'2019-02-04T00:00:00.000' AS DateTime), 3, 7, 1)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (26, CAST(N'2019-02-03T00:00:00.000' AS DateTime), CAST(N'2019-03-02T00:00:00.000' AS DateTime), 3, 8, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (27, CAST(N'2019-02-04T00:00:00.000' AS DateTime), CAST(N'2019-03-04T00:00:00.000' AS DateTime), 3, 7, 5)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (28, CAST(N'2019-02-05T00:00:00.000' AS DateTime), CAST(N'2019-02-25T00:00:00.000' AS DateTime), 3, 6, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (29, CAST(N'2019-02-06T00:00:00.000' AS DateTime), CAST(N'2019-02-26T00:00:00.000' AS DateTime), 3, 5, 5)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (30, CAST(N'2019-02-07T00:00:00.000' AS DateTime), CAST(N'2019-03-02T00:00:00.000' AS DateTime), 3, 1, 4)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (31, CAST(N'2019-02-08T00:00:00.000' AS DateTime), CAST(N'2019-02-15T00:00:00.000' AS DateTime), 3, 1, 2)
INSERT [dbo].[supply] ([supply_id], [start_date_time], [end_date_time], [status_id], [dist_id], [response_id]) VALUES (32, CAST(N'2019-02-09T00:00:00.000' AS DateTime), CAST(N'2019-02-17T00:00:00.000' AS DateTime), 3, 6, 1)
INSERT [dbo].[supply_status_id] ([status_id], [status_name]) VALUES (1, N'Отмена')
INSERT [dbo].[supply_status_id] ([status_id], [status_name]) VALUES (2, N'Заказано')
INSERT [dbo].[supply_status_id] ([status_id], [status_name]) VALUES (3, N'Доставлено')
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (1, 1, 2, 1)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (2, 0, 2, 2)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (3, 1, 2, 3)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (4, 0, 3, 1)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (5, 1, 3, 2)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (6, 0, 3, 4)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (7, 1, 1, 1)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (8, 0, 1, 2)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (9, 1, 1, 5)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (10, 0, 4, 1)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (11, 1, 4, 6)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (12, 0, 4, 7)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (13, 1, 4, 8)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (14, 0, 4, 9)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (15, 1, 4, 10)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (16, 0, 4, 11)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (17, 0, 4, 12)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (18, 0, 4, 13)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (19, 0, 4, 14)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (20, 0, 4, 15)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (21, 0, 4, 16)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (22, 0, 5, 6)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (23, 0, 5, 17)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (24, 0, 5, 18)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (25, 0, 5, 19)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (26, 0, 5, 20)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (27, 0, 5, 21)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (28, 0, 5, 22)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (29, 0, 5, 10)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (30, 0, 5, 16)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (31, 0, 6, 1)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (32, 0, 6, 23)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (33, 0, 6, 24)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (34, 0, 6, 25)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (35, 0, 6, 26)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (36, 0, 7, 26)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (37, 0, 7, 27)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (38, 0, 7, 23)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (39, 0, 7, 28)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (40, 0, 7, 29)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (41, 1, 1, 30)
INSERT [dbo].[type_attributes_list] ([type_attribute_id], [used_in_filter], [min_type_id], [attr_id]) VALUES (42, 1, 4, 30)
INSERT [dbo].[updated_new_distributors] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (4, N'Книжный мир', N'Лесная д. 9', N'89045455146', 10000.0000, 1, 1, N'rtyq.ru')
INSERT [dbo].[updated_new_distributors] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (5, N'Веселый Фермер', N'Арбатская д. 16', N'89326134422', 10000.0000, 4, 7, N'fermer.com')
INSERT [dbo].[updated_new_distributors] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (7, N'Перевозки Петрович', N'Марксисткая д 3', N'89120474424', 50000.0000, 1, 3, N'petrovich.com')
INSERT [dbo].[updated_new_distributors] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (8, N'IT-дистрибьюшен ', N'Старокачаловская д 9', N'89028773318', 10000.0000, 5, 6, N'')
INSERT [dbo].[updated_new_distributors] ([dist_id], [name], [general_address], [general_phone], [min_order_money], [min_supply_days], [max_supply_days], [site]) VALUES (9, N'Проект Дистрибуция', N'Ольховская д 6', N'89064560978', 500.0000, 1, 1, N'')
/****** Object:  Index [attr_value_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [attr_value_id_ind] ON [dbo].[attribute_value]
(
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [attr_atr_type_general_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [attr_atr_type_general_ind] ON [dbo].[attributes]
(
	[attr_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [attr_atr_type_techn_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [attr_atr_type_techn_ind] ON [dbo].[attributes]
(
	[attr_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [attr_check_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [attr_check_id_ind] ON [dbo].[attributes_check]
(
	[type_attribute_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [Last_First_Name_Client_NonClusteredIndex]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [Last_First_Name_Client_NonClusteredIndex] ON [dbo].[client]
(
	[last_name] ASC,
	[first_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [client_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [client_id_ind] ON [dbo].[client_order]
(
	[client_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ind_order_date_t]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [ind_order_date_t] ON [dbo].[client_order]
(
	[date_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [resp_cour_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [resp_cour_ind] ON [dbo].[client_order]
(
	[response_courier_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [distr_contact_dist_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [distr_contact_dist_id_ind] ON [dbo].[distributor_contact]
(
	[dist_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [Last_First_Name_Dist-Contact]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [Last_First_Name_Dist-Contact] ON [dbo].[distributor_contact]
(
	[last_name] ASC,
	[fist_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [prod_id_price_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [prod_id_price_ind] ON [dbo].[price_change]
(
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [prod_manufat_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [prod_manufat_id_ind] ON [dbo].[product]
(
	[manufact_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [prod_type_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [prod_type_id_ind] ON [dbo].[product]
(
	[prod_type_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [Product_name_NonClusteredIndex-]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [Product_name_NonClusteredIndex-] ON [dbo].[product]
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_product_hierarcy]    Script Date: 10.09.2019 21:28:54 ******/
ALTER TABLE [dbo].[product_hierarcy] ADD  CONSTRAINT [IX_product_hierarcy] UNIQUE NONCLUSTERED 
(
	[min_type_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [uniq_prod_start_end]    Script Date: 10.09.2019 21:28:54 ******/
ALTER TABLE [dbo].[product_promotion] ADD  CONSTRAINT [uniq_prod_start_end] UNIQUE NONCLUSTERED 
(
	[product_id] ASC,
	[start_date_time] ASC,
	[end_date_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [prod_promo_prod_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [prod_promo_prod_id_ind] ON [dbo].[product_promotion]
(
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [in_supply_order_prod_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [in_supply_order_prod_id_ind] ON [dbo].[products_in_supply_order]
(
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [in_supply_order_supply_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [in_supply_order_supply_id_ind] ON [dbo].[products_in_supply_order]
(
	[supply_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [uniq_prod_id_start_end]    Script Date: 10.09.2019 21:28:54 ******/
ALTER TABLE [dbo].[promo_planned] ADD  CONSTRAINT [uniq_prod_id_start_end] UNIQUE NONCLUSTERED 
(
	[product_id] ASC,
	[start_date_time] ASC,
	[end_date_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [Last_First_Name_Courier-NonClusteredIndex]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [Last_First_Name_Courier-NonClusteredIndex] ON [dbo].[responsible_courier]
(
	[last_name] ASC,
	[first_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ord_id_ind_review]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [ord_id_ind_review] ON [dbo].[review]
(
	[review_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [prod_id_ind_review]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [prod_id_ind_review] ON [dbo].[review]
(
	[review_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [supply_dist_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [supply_dist_id_ind] ON [dbo].[supply]
(
	[dist_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [supply_status_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [supply_status_ind] ON [dbo].[supply]
(
	[status_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [attr_type_list_amin_type_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [attr_type_list_amin_type_id_ind] ON [dbo].[type_attributes_list]
(
	[min_type_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [attr_type_list_atr_id_ind]    Script Date: 10.09.2019 21:28:54 ******/
CREATE NONCLUSTERED INDEX [attr_type_list_atr_id_ind] ON [dbo].[type_attributes_list]
(
	[attr_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[attribute_value]  WITH CHECK ADD  CONSTRAINT [FK_attribute_value_product] FOREIGN KEY([product_id])
REFERENCES [dbo].[product] ([product_id])
GO
ALTER TABLE [dbo].[attribute_value] CHECK CONSTRAINT [FK_attribute_value_product]
GO
ALTER TABLE [dbo].[attribute_value]  WITH CHECK ADD  CONSTRAINT [FK_attribute_value_type_attributes_list] FOREIGN KEY([type_attribute_id])
REFERENCES [dbo].[type_attributes_list] ([type_attribute_id])
GO
ALTER TABLE [dbo].[attribute_value] CHECK CONSTRAINT [FK_attribute_value_type_attributes_list]
GO
ALTER TABLE [dbo].[attributes]  WITH CHECK ADD  CONSTRAINT [FK_attributes_attribute_type_general] FOREIGN KEY([type_id_general])
REFERENCES [dbo].[attribute_type_general] ([general_id])
GO
ALTER TABLE [dbo].[attributes] CHECK CONSTRAINT [FK_attributes_attribute_type_general]
GO
ALTER TABLE [dbo].[attributes]  WITH CHECK ADD  CONSTRAINT [FK_attributes_attribute_type_technical] FOREIGN KEY([type_id_technical])
REFERENCES [dbo].[attribute_type_technical] ([technical_id])
GO
ALTER TABLE [dbo].[attributes] CHECK CONSTRAINT [FK_attributes_attribute_type_technical]
GO
ALTER TABLE [dbo].[attributes_check]  WITH CHECK ADD  CONSTRAINT [FK_attributes_check_type_attributes_list] FOREIGN KEY([type_attribute_id])
REFERENCES [dbo].[type_attributes_list] ([type_attribute_id])
GO
ALTER TABLE [dbo].[attributes_check] CHECK CONSTRAINT [FK_attributes_check_type_attributes_list]
GO
ALTER TABLE [dbo].[client_order]  WITH CHECK ADD  CONSTRAINT [FK_order_client] FOREIGN KEY([client_id])
REFERENCES [dbo].[client] ([client_id])
GO
ALTER TABLE [dbo].[client_order] CHECK CONSTRAINT [FK_order_client]
GO
ALTER TABLE [dbo].[client_order]  WITH CHECK ADD  CONSTRAINT [FK_order_delivery_status] FOREIGN KEY([order_delivery_status_id])
REFERENCES [dbo].[delivery_status] ([id])
GO
ALTER TABLE [dbo].[client_order] CHECK CONSTRAINT [FK_order_delivery_status]
GO
ALTER TABLE [dbo].[client_order]  WITH CHECK ADD  CONSTRAINT [FK_order_payment_status] FOREIGN KEY([order_pay_status_id])
REFERENCES [dbo].[payment_status] ([id])
GO
ALTER TABLE [dbo].[client_order] CHECK CONSTRAINT [FK_order_payment_status]
GO
ALTER TABLE [dbo].[client_order]  WITH CHECK ADD  CONSTRAINT [FK_order_responsible_courier] FOREIGN KEY([response_courier_id])
REFERENCES [dbo].[responsible_courier] ([courier_id])
GO
ALTER TABLE [dbo].[client_order] CHECK CONSTRAINT [FK_order_responsible_courier]
GO
ALTER TABLE [dbo].[distributor_contact]  WITH CHECK ADD  CONSTRAINT [FK_distributor_contact_distributor] FOREIGN KEY([dist_id])
REFERENCES [dbo].[distributor] ([dist_id])
GO
ALTER TABLE [dbo].[distributor_contact] CHECK CONSTRAINT [FK_distributor_contact_distributor]
GO
ALTER TABLE [dbo].[items_in_order]  WITH CHECK ADD  CONSTRAINT [FK_items_in_order_order] FOREIGN KEY([order_id])
REFERENCES [dbo].[client_order] ([order_id])
GO
ALTER TABLE [dbo].[items_in_order] CHECK CONSTRAINT [FK_items_in_order_order]
GO
ALTER TABLE [dbo].[items_in_order]  WITH CHECK ADD  CONSTRAINT [FK_items_in_order_product] FOREIGN KEY([product_id])
REFERENCES [dbo].[product] ([product_id])
GO
ALTER TABLE [dbo].[items_in_order] CHECK CONSTRAINT [FK_items_in_order_product]
GO
ALTER TABLE [dbo].[price_change]  WITH CHECK ADD  CONSTRAINT [FK_price_change_product1] FOREIGN KEY([product_id])
REFERENCES [dbo].[product] ([product_id])
GO
ALTER TABLE [dbo].[price_change] CHECK CONSTRAINT [FK_price_change_product1]
GO
ALTER TABLE [dbo].[prod_type_minimal]  WITH CHECK ADD  CONSTRAINT [FK_prod_type_minimal_product_hierarcy] FOREIGN KEY([min_type_id])
REFERENCES [dbo].[product_hierarcy] ([min_type_id])
GO
ALTER TABLE [dbo].[prod_type_minimal] CHECK CONSTRAINT [FK_prod_type_minimal_product_hierarcy]
GO
ALTER TABLE [dbo].[product]  WITH CHECK ADD  CONSTRAINT [FK_product_manufacturer] FOREIGN KEY([manufact_id])
REFERENCES [dbo].[manufacturer] ([manifact_id])
GO
ALTER TABLE [dbo].[product] CHECK CONSTRAINT [FK_product_manufacturer]
GO
ALTER TABLE [dbo].[product]  WITH CHECK ADD  CONSTRAINT [FK_product_prod_type_minimal] FOREIGN KEY([prod_type_id])
REFERENCES [dbo].[prod_type_minimal] ([min_type_id])
GO
ALTER TABLE [dbo].[product] CHECK CONSTRAINT [FK_product_prod_type_minimal]
GO
ALTER TABLE [dbo].[product_hierarcy]  WITH CHECK ADD  CONSTRAINT [FK_product_hierarcy_product_hierarcy] FOREIGN KEY([general_type_id])
REFERENCES [dbo].[product_hierarcy] ([min_type_id])
GO
ALTER TABLE [dbo].[product_hierarcy] CHECK CONSTRAINT [FK_product_hierarcy_product_hierarcy]
GO
ALTER TABLE [dbo].[product_promotion]  WITH CHECK ADD  CONSTRAINT [FK_product_promotion_product] FOREIGN KEY([product_id])
REFERENCES [dbo].[product] ([product_id])
GO
ALTER TABLE [dbo].[product_promotion] CHECK CONSTRAINT [FK_product_promotion_product]
GO
ALTER TABLE [dbo].[products_in_supply_order]  WITH CHECK ADD  CONSTRAINT [FK_products_in_supply_order_product] FOREIGN KEY([product_id])
REFERENCES [dbo].[product] ([product_id])
GO
ALTER TABLE [dbo].[products_in_supply_order] CHECK CONSTRAINT [FK_products_in_supply_order_product]
GO
ALTER TABLE [dbo].[products_in_supply_order]  WITH CHECK ADD  CONSTRAINT [FK_products_in_supply_order_supply] FOREIGN KEY([supply_id])
REFERENCES [dbo].[supply] ([supply_id])
GO
ALTER TABLE [dbo].[products_in_supply_order] CHECK CONSTRAINT [FK_products_in_supply_order_supply]
GO
ALTER TABLE [dbo].[review]  WITH CHECK ADD  CONSTRAINT [FK_review_order] FOREIGN KEY([order_id])
REFERENCES [dbo].[client_order] ([order_id])
GO
ALTER TABLE [dbo].[review] CHECK CONSTRAINT [FK_review_order]
GO
ALTER TABLE [dbo].[review]  WITH CHECK ADD  CONSTRAINT [FK_review_product] FOREIGN KEY([product_id])
REFERENCES [dbo].[product] ([product_id])
GO
ALTER TABLE [dbo].[review] CHECK CONSTRAINT [FK_review_product]
GO
ALTER TABLE [dbo].[supply]  WITH CHECK ADD  CONSTRAINT [FK_supply_distributor] FOREIGN KEY([dist_id])
REFERENCES [dbo].[distributor] ([dist_id])
GO
ALTER TABLE [dbo].[supply] CHECK CONSTRAINT [FK_supply_distributor]
GO
ALTER TABLE [dbo].[supply]  WITH CHECK ADD  CONSTRAINT [FK_supply_supply_status_id] FOREIGN KEY([status_id])
REFERENCES [dbo].[supply_status_id] ([status_id])
GO
ALTER TABLE [dbo].[supply] CHECK CONSTRAINT [FK_supply_supply_status_id]
GO
ALTER TABLE [dbo].[type_attributes_list]  WITH CHECK ADD  CONSTRAINT [FK_type_attributes_list_attributes] FOREIGN KEY([attr_id])
REFERENCES [dbo].[attributes] ([attr_id])
GO
ALTER TABLE [dbo].[type_attributes_list] CHECK CONSTRAINT [FK_type_attributes_list_attributes]
GO
ALTER TABLE [dbo].[type_attributes_list]  WITH CHECK ADD  CONSTRAINT [FK_type_attributes_list_prod_type_minimal] FOREIGN KEY([min_type_id])
REFERENCES [dbo].[prod_type_minimal] ([min_type_id])
GO
ALTER TABLE [dbo].[type_attributes_list] CHECK CONSTRAINT [FK_type_attributes_list_prod_type_minimal]
GO
ALTER TABLE [dbo].[product_promotion]  WITH CHECK ADD  CONSTRAINT [promotion_check] CHECK  (([percentage_promo]>=(0) AND [percentage_promo]<=(100)))
GO
ALTER TABLE [dbo].[product_promotion] CHECK CONSTRAINT [promotion_check]
GO
ALTER TABLE [dbo].[product_promotion]  WITH CHECK ADD  CONSTRAINT [start_end_dates_check] CHECK  (([end_date_time]>=[start_date_time]))
GO
ALTER TABLE [dbo].[product_promotion] CHECK CONSTRAINT [start_end_dates_check]
GO
ALTER TABLE [dbo].[review]  WITH CHECK ADD  CONSTRAINT [mark_check] CHECK  (([mark_id]<=(5) AND [mark_id]>(0)))
GO
ALTER TABLE [dbo].[review] CHECK CONSTRAINT [mark_check]
GO
/****** Object:  StoredProcedure [dbo].[p_att_val_with_error]    Script Date: 10.09.2019 21:28:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




---- Создаем процедуру. На вход она будем получать таблицу id и названий продуктов
    CREATE PROCEDURE [dbo].[p_att_val_with_error]
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
/****** Object:  StoredProcedure [dbo].[sp_update_first_order_date]    Script Date: 10.09.2019 21:28:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_update_first_order_date]
AS
UPDATE client 
SET first_order_date_time = first_date
FROM 
(SELECT DISTINCT c.client_id,  
MIN(o.date_time) OVER (PARTITION BY c.client_id) as first_date
FROM client_order as o
INNER JOIN client as c ON o.client_id=c.client_id
WHERE c.first_order_date_time IS NULL) as up 
WHERE up.client_id = client.client_id ;
GO
/****** Object:  StoredProcedure [dbo].[sp_update_product_rest]    Script Date: 10.09.2019 21:28:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_update_product_rest]
AS


UPDATE dbo.product
SET rest_quantity =  prd_rest.rest
FROM dbo.product
INNER JOIN 
---   здесь собраны все id и остаток по ним (prd_rest)
	(SELECT  suplied_products.product_id as prd_id, ISNULL(suplied_products.sup_qua, 0) - ISNULL(sold_products.ord_qua, 0) as rest
	FROM 
		--- здесь собраны все продукты и фактические поставки по ним (сумма по количеству)
		(SELECT p.product_id , SUM(i.quantity) AS sup_qua
		FROM dbo.product AS p
		INNER JOIN dbo.products_in_supply_order AS i ON i.product_id  = p.product_id
		INNER JOIN dbo.supply AS s ON s.supply_id = i.supply_id
		INNER JOIN dbo.supply_status_id AS ord_sp ON ord_sp.status_id = s.status_id
		WHERE  ord_sp.status_name = 'Доставлено'
		GROUP BY  p.product_id )  AS suplied_products

	LEFT JOIN -- так как могут быть поставленные продукты для продажи, но не разу ещё не купленные, они должны попасть в таблицу с остатками, поэтому не INNER JOIN

	      --- здесь собраны все продукты, выполенные заказы и обрабатываемые по ним (сумма по количеству)
		(SELECT p.product_id , SUM(i.quantity) AS ord_qua
		FROM dbo.product AS p
		INNER JOIN dbo.items_in_order AS i ON p.product_id = i.product_id
		INNER JOIN dbo.client_order AS o ON o.order_id = i.order_id
		INNER JOIN dbo.delivery_status AS ord_st ON ord_st.id = o.order_delivery_status_id
		WHERE ord_st.[status] <> 'Отмена'
		GROUP BY  p.product_id)  AS sold_products 

	ON suplied_products.product_id =  sold_products.product_id )    
	AS prd_rest

ON  prd_rest.prd_id = dbo.product.product_id 
 -- добавляем условие, что обновление должно происходить только если сохранненое значение отличается от вычисленного
 -- таким образом уменьшаем кол-во блокировок таблицы и обновляем только то, что действительно изменилось.
WHERE rest_quantity <>  prd_rest.rest



;
GO
/****** Object:  StoredProcedure [dbo].[update_promo]    Script Date: 10.09.2019 21:28:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_promo] AS
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
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'product_promotion', @level2type=N'CONSTRAINT',@level2name=N'promotion_check'
GO
USE [master]
GO
ALTER DATABASE [int_shop_otus] SET  READ_WRITE 
GO
