# Generate a Gross sales report of individual product sales (aggregated on a month basics at the product level) for croma india customers for FY 2021
# report shall have month, product name and variant, sold qunatity, gross price per item gross price total, variants

#creating a function to calculate fiscal year
	CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_year`(
	calender_date date
	 ) RETURNS int
	     DETERMINISTIC
	 BEGIN
	 	declare fiscal_year int;
		set fiscal_year = year(date_add(calender_date,  interval 4 month ));
	 RETURN fiscal_year;
	 END
    
select  date , p.product, p.variant, sm.sold_quantity, round(gp.gross_price,2) , round(sm.sold_quantity * gp.gross_price,2) as total_gross_price
from fact_sales_monthly sm
join dim_product p using(product_code)
join fact_gross_price gp on gp.product_code = sm.product_code and gp.fiscal_year = get_fiscal_year(sm.date)
join dim_customer c using(customer_code)
where c.customer_code = 90002002 and get_fiscal_year(sm.date)= 2021 

# creating a function for calculating the fiscal quarter and fiscal date
	CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_quarter`(
	calendar_date date
	) RETURNS char(2) CHARSET utf8mb4
		DETERMINISTIC
	BEGIN
		declare var char (2);
		set var = case
		when month(calendar_date) in (9,10,11) then "Q1"
		when month(calendar_date) in (12,1,2) then "Q2"
		when month(calendar_date) in (3,4,5) then "Q3"
		else "Q4"
		end;
	RETURN var;
	END
    
    # fiscal date
    
    CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_date`(
calender_date date
) RETURNS int
    DETERMINISTIC
BEGIN
	declare fiscal_date int;
	set fiscal_date = date_add(calender_date,  interval 4 month );
	
RETURN fiscal_date;
END

# Gross Monthly total sales report for croma

# As a product owner, I need an aggregate monthly gross sales report for croma India customer so that i can track how much sales this particular customer is generating
# for AtliQ and manage relationships with them accordingly

# the report should have the following:
	# 1. Month, 2. Total growth sales amount to croma india in this month
    
select  fiscal_year ,sum(sm.sold_quantity * gp.gross_price) as total_gross_price
from fact_sales_monthly sm
join fact_gross_price gp on gp.product_code = sm.product_code and gp.fiscal_year = get_fiscal_year(sm.date)
join dim_customer c using(customer_code)
where c.customer_code = 90002002 
group by fiscal_year

-- Generate a yearly report for Croma India where there are two columns

-- 1. Fiscal Year
-- 2. Total Gross Sales amount In that year from Croma

select  fiscal_year ,sum(sm.sold_quantity * gp.gross_price) as total_gross_price
from fact_sales_monthly sm
join fact_gross_price gp on gp.product_code = sm.product_code and gp.fiscal_year = get_fiscal_year(sm.date)
join dim_customer c using(customer_code)
where c.customer_code = 90002002 
group by fiscal_year

# creating stored procedures for multiple customer

CREATE DEFINER=`root`@`localhost` PROCEDURE `get gross sales report for customer code`(
c_code text
)
BEGIN
		select  date ,sum(sm.sold_quantity * gp.gross_price) as total_gross_price
	from fact_sales_monthly sm
	join fact_gross_price gp on gp.product_code = sm.product_code and gp.fiscal_year = get_fiscal_year(sm.date)
	join dim_customer c using(customer_code)
	where find_in_set (c.customer_code , c_code )> 0
	group by date;
	END
    
# creating a stored procedure involving control functions like if statements and classify if the total sales > 5 M as Gold else Silver

CREATE DEFINER=`root`@`localhost` PROCEDURE `market_badge`(
 IN in_fiscal_year year, 
 IN in_market_name varchar(30) ,
 OUT badge varchar(15))
BEGIN
	declare total_sold_quantity int default  0;
    # set default value
    if in_market_name = " " then 
    set in_market_name = "India";
    end if;
	select 
		sum(sold_quantity) into total_sold_quantity 
    from fact_sales_monthly f 
    join dim_customer  c using(customer_code)
    where get_fiscal_year(date) = in_fiscal_year and c.market = in_market_name
    group by c.market;
    
    
     if total_sold_quantity > 5000000
     then set badge = "Gold";
     else set badge =  "Silver" ;
	end if;
END


