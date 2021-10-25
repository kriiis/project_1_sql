USE magist;

-- Describe the database
SELECT * FROM information_schema.columns WHERE table_schema = 'magist';
DESCRIBE customers;

#How many orders are there in the dataset? - 99441
SELECT COUNT(*)
FROM orders;

#Are orders actually delivered? What is the actual status of the orders? How many in each category?
SELECT order_status, COUNT(*)
FROM orders
GROUP BY order_status;

#Is Magist having user growth? - 
SELECT 
	YEAR(order_purchase_timestamp) AS year, 
    MONTH(order_purchase_timestamp) as month, 
    COUNT(customer_id)
FROM orders
GROUP BY year, month
ORDER BY year, month ASC;

#How many products are there in the products table?
SELECT COUNT(DISTINCT product_id)
FROM products;

#check all rows for duplicate products based on other columns in table products
select count(*)
from
	(select product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm, Count(*)
	from products
group by product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm
having count(*) > 1
order by count(*) desc
) prod;

#using with to check for duplicates in products
WITH temp_table AS
	(SELECT 
		product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm, 
		COUNT(*) AS num_duplicates
	FROM products
	GROUP BY 
		product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm
	HAVING COUNT(product_id) > 1
	ORDER BY COUNT(*) DESC)
    
Select count(*) from temp_table; 

#Which are the categories with most products? 
SELECT product_category_name, COUNT(product_id) AS num_prod
FROM products
GROUP BY product_category_name
ORDER BY num_prod DESC
LIMIT 20;

#How many of those products were present in actual transactions?
SELECT p.product_category_name, pc.product_category_name_english, COUNT(p.product_id) AS num_prod
FROM order_items oi
INNER JOIN products p ON p.product_id = oi.product_id
INNER JOIN product_category_name_translation pc ON pc.product_category_name = p.product_category_name
GROUP BY p.product_category_name
ORDER BY num_prod DESC;

#What’s the price for the most expensive and cheapest products?
SELECT MAX(price) as most_expensive, MIN(price) as cheapest
FROM order_items;

#What are the highest and lowest payment values?
SELECT MAX(payment_value) AS highest_payment, ROUND(MIN(payment_value),2) AS lowest_payment
FROM order_payments;


#In relation to the products

#What categories of tech products does Magist have?
#Eniac is specialised in Apple compatible accessories
    
select *
from product_category_name_translation
WHERE product_category_name_english IN ('electronics','computers_accessories','pc_gamer','computers','consoles_games', 'telephony', 'watches_gifts');    

#How many products of these tech categories have been sold (within the time window of the database snapshot)? 
select p.product_category_name, pc.product_category_name_english, COUNT(p.product_id) as num_prod
from product_category_name_translation as pc
inner join products p on p.product_category_name = pc.product_category_name
inner join order_items oi on oi.product_id = p.product_id
where p.product_category_name in ('eletronicos', 'informatica_acessorios', 'pcs', 'telefonia', 'relogios_presentes') 
group by p.product_category_name
order by num_prod desc;

#above query using aliases instead of inner join - num sold products in tech categories
select product_category_name, count(p.product_id) as num_prod
from products as p, order_items as oi, orders as o
where p.product_id = oi.product_id 
	and oi.order_id = o.order_id
    and p.product_category_name in ('eletronicos', 'informatica_acessorios', 'pcs', 'telefonia', 'relogios_presentes') 
group by p.product_category_name
order by num_prod desc;

#number of sold tech products
select sum(num_prod)
from (
	select product_category_name, count(p.product_id) as num_prod
	from products as p, order_items as oi, orders as o
	where p.product_id = oi.product_id 
	and oi.order_id = o.order_id
    and p.product_category_name in ('eletronicos', 'informatica_acessorios', 'pcs', 'telefonia', 'relogios_presentes') 
	group by p.product_category_name
	order by num_prod desc) a;

#What percentage do sold tech products represent from the overall number of products sold? (21333 * 100)/112650 = about 19%
SELECT 
	(SELECT SUM(products_sold) AS tech_products FROM
		(SELECT 
				product_category_name, 
				count(product_category_name) as products_sold
			FROM 
				order_items oi 
					LEFT JOIN products p ON oi.product_id = p.product_id 
		WHERE p.product_category_name in ('eletronicos', 'informatica_acessorios', 'pcs', 'telefonia', 'relogios_presentes')
		GROUP BY product_category_name) a) /
	(SELECT COUNT(*) FROM order_items) * 100 AS percentage_tech_products;

#sum of products per categories for making a diagram
select categories, sum(prod_count)
from
	(SELECT products.product_category_name,product_category_name_translation.product_category_name_english,COUNT(products.product_id) as prod_count,
	CASE
	WHEN product_category_name_translation.product_category_name_english IN ('food','food_drink','drinks','party_supplies','christmas_supplies') THEN 'Food & Drink & Party'
	WHEN product_category_name_translation.product_category_name_english IN ('auto') THEN 'Automotive'
    WHEN product_category_name_translation.product_category_name_english IN ('sports_leisure') THEN 'Sports & Leisure'
	WHEN product_category_name_translation.product_category_name_english IN ('art','arts_and_craftmanship') THEN 'Arts & Crafts'
	WHEN product_category_name_translation.product_category_name_english IN ('pc_gamer','consoles_games') THEN 'Games'
    WHEN product_category_name_translation.product_category_name_english IN ('electronics','computers_accessories','computers','telephony','watches_gifts') THEN 'Tech'
	WHEN product_category_name_translation.product_category_name_english IN ('fashion_bags_accessories','fashion_shoes','fashion_sport','fashio_female_clothing','fashion_male_clothing','fashion_childrens_clothes','fashion_underwear_beach','luggage_accessories') THEN 'Fashion'
	WHEN product_category_name_translation.product_category_name_english IN ('bed_bath_table','home_confort','home_comfort_2','air_conditioning','home_appliances','home_appliances_2','small_appliances','la_cuisine','furniture_mattress_and_upholstery','furniture_bedroom','furniture_living_room','small_appliances_home_oven_and_coffee','portable_kitchen_food_processors','housewares','kitchen_dining_laundry_garden_furniture','furniture_decor') THEN 'Home & Furniture'
	WHEN product_category_name_translation.product_category_name_english IN ('home_construction','construction_tools_construction','costruction_tools_tools','construction_tools_lights','costruction_tools_garden','construction_tools_safety', 'flowers','garden_tools') THEN 'Construction & Garden'
	WHEN product_category_name_translation.product_category_name_english IN ('books_imported','books_general_interest','books_technical') THEN 'Book'
	WHEN product_category_name_translation.product_category_name_english IN ('health_beauty','perfumery') THEN 'Beauty'
    WHEN product_category_name_translation.product_category_name_english IN ('baby','toys','diapers_and_hygiene') THEN 'Baby'
	WHEN product_category_name_translation.product_category_name_english IN ('agro_industry_and_commerce','industry_commerce_and_business', 'stationery', 'security_and_services', 'office_furniture') THEN 'Office & Security & Industry'
	WHEN product_category_name_translation.product_category_name_english IN ('audio','cds_dvds_musicals','cine_photo','dvds_blu_ray','musical_instruments','music','tablets_printing_image') THEN 'Music & Images'
	Else 'Other'
	END AS categories
	FROM product_category_name_translation 
	INNER JOIN products ON product_category_name_translation.product_category_name = products.product_category_name
	GROUP BY product_category_name, categories) as new_cat
group by categories;

#sum of sold products per category
select categories, sum(sold_prod_count)
from
	(SELECT products.product_category_name,product_category_name_translation.product_category_name_english,COUNT(oi.product_id) as sold_prod_count,
	CASE
	WHEN product_category_name_translation.product_category_name_english IN ('food','food_drink','drinks','party_supplies','christmas_supplies') THEN 'Food & Drink & Party'
	WHEN product_category_name_translation.product_category_name_english IN ('auto') THEN 'Automotive'
    WHEN product_category_name_translation.product_category_name_english IN ('sports_leisure') THEN 'Sports & Leisure'
	WHEN product_category_name_translation.product_category_name_english IN ('art','arts_and_craftmanship') THEN 'Arts & Crafts'
	WHEN product_category_name_translation.product_category_name_english IN ('pc_gamer','consoles_games') THEN 'Games'
    WHEN product_category_name_translation.product_category_name_english IN ('electronics','computers_accessories','computers','telephony','watches_gifts') THEN 'Tech'
	WHEN product_category_name_translation.product_category_name_english IN ('fashion_bags_accessories','fashion_shoes','fashion_sport','fashio_female_clothing','fashion_male_clothing','fashion_childrens_clothes','fashion_underwear_beach','luggage_accessories') THEN 'Fashion'
	WHEN product_category_name_translation.product_category_name_english IN ('bed_bath_table','home_confort','home_comfort_2','air_conditioning','home_appliances','home_appliances_2','small_appliances','la_cuisine','furniture_mattress_and_upholstery','furniture_bedroom','furniture_living_room','small_appliances_home_oven_and_coffee','portable_kitchen_food_processors','housewares','kitchen_dining_laundry_garden_furniture','furniture_decor') THEN 'Home & Furniture'
	WHEN product_category_name_translation.product_category_name_english IN ('home_construction','construction_tools_construction','costruction_tools_tools','construction_tools_lights','costruction_tools_garden','construction_tools_safety', 'flowers','garden_tools') THEN 'Construction & Garden'
	WHEN product_category_name_translation.product_category_name_english IN ('books_imported','books_general_interest','books_technical') THEN 'Book'
	WHEN product_category_name_translation.product_category_name_english IN ('health_beauty','perfumery') THEN 'Beauty'
    WHEN product_category_name_translation.product_category_name_english IN ('baby','toys','diapers_and_hygiene') THEN 'Baby'
	WHEN product_category_name_translation.product_category_name_english IN ('agro_industry_and_commerce','industry_commerce_and_business', 'stationery', 'security_and_services', 'office_furniture') THEN 'Office & Security & Industry'
	WHEN product_category_name_translation.product_category_name_english IN ('audio','cds_dvds_musicals','cine_photo','dvds_blu_ray','musical_instruments','music','tablets_printing_image') THEN 'Music & Images'
	Else 'Other'
	END AS categories
	FROM product_category_name_translation 
	INNER JOIN products ON product_category_name_translation.product_category_name = products.product_category_name
    inner join order_items oi on oi.product_id = products.product_id
	GROUP BY product_category_name, categories) as new_cat
group by categories;

#show number of products in each product category for all product categories
select p.product_category_name, pc.product_category_name_english, COUNT(p.product_id) as num_prod
from product_category_name_translation as pc
inner join products p on p.product_category_name = pc.product_category_name
inner join order_items oi on oi.product_id = p.product_id
group by p.product_category_name
order by num_prod desc;

#What’s the average price of the products being sold? - calculates the average price of all sold products, although some were sold more then 1 time
select avg(price), Min(price), Max(price)
from order_items;

#average price of sold products - first calculate avg of same products in group and then avergage over all products
select avg(aprice), Min(aprice), Max(aprice)
from (
 select avg(price) as aprice
 from order_items
 group by product_id
 ) a;

# avg, min, max price of all the products that have been sold for top seller
select avg(oi.price), Min(oi.price), Max(oi.price)
from order_items as oi, sellers as s
where oi.seller_id = s.seller_id
and s.seller_id = '53243585a1d6dc2643021fd1853d8905';

#avg price for tech products for each tech category
select pc.product_category_name_english, round(avg(price),2)
from order_items oi
inner join products p on p.product_id = oi.product_id
inner join product_category_name_translation pc on pc.product_category_name = p.product_category_name
WHERE pc.product_category_name_english IN ('electronics','computers_accessories', 'computers', 'telephony', 'watches_gifts')
Group by pc.product_category_name_english
order by avg(price) desc;

#avg price for tech products without category
select round(avg(price),2)
from order_items oi
inner join products p on p.product_id = oi.product_id
inner join product_category_name_translation pc on pc.product_category_name = p.product_category_name
WHERE pc.product_category_name_english IN ('electronics','computers_accessories','computers', 'telephony', 'watches_gifts');

#Are expensive tech products popular? - Look at the function CASE WHEN to accomplish this task.
#popular products based on number of orders in price categories for all tech products, for each tech category
select avg(price), count(order_item_id) as num_orders, pc.product_category_name,
	case
		when price > 1000 then 'expensive'
        when price < 100 then 'cheap'
        else 'affordable'
	end as price_cat
from order_items oi
inner join products p on p.product_id = oi.product_id
inner join product_category_name_translation pc on pc.product_category_name = p.product_category_name
WHERE pc.product_category_name_english IN ('electronics','computers_accessories','pc_gamer','computers','consoles_games', 'telephony', 'watches_gifts')
group by price_cat, p.product_category_name
order by p.product_category_name, num_orders desc; 

#In relation to sellers
#How many sellers are there?
SELECT COUNT(*) AS Sellers FROM sellers;

#whats the avergae monthly revenue of magists sellers
select seller_id, round(avg(revenue_ym),2) as average_monthly_income, round(min(revenue_ym), 2) as min_monthly_income, round(max(revenue_ym),2) as max_monthly_income, year, month
from (
	select year(shipping_limit_date) as year, month(shipping_limit_date) as month, seller_id, SUM(price) as revenue_ym
	from order_items
	group by year(shipping_limit_date), month(shipping_limit_date), seller_id
    ) as temp
group by year, month
order by year, month;

#What’s the average revenue of sellers that sell tech products?
select seller_id, round(avg(revenue_ym),2) as average_monthly_income, round(min(revenue_ym), 2) as min_monthly_income, round(max(revenue_ym),2) as max_monthly_income, year, month
from (
	select year(oi.shipping_limit_date) as year, month(oi.shipping_limit_date) as month, oi.seller_id, SUM(oi.price) as revenue_ym
	from order_items oi
    inner join products p on p.product_id = oi.product_id
    where p.product_category_name in ('eletronicos', 'informatica_acessorios', 'pcs', 'telefonia', 'relogios_presentes')
	group by year(oi.shipping_limit_date), month(oi.shipping_limit_date), oi.seller_id
    ) as temp
group by year, month
order by year, month;

#city where the biggest tech seller comes from
SELECT g.city 
FROM sellers s
inner join geo g on g.zip_code_prefix = s.seller_zip_code_prefix
where s.seller_id = '53243585a1d6dc2643021fd1853d8905';

#In relation to the delivery time:

#What’s the average time between the order being placed and the product being delivered? avg delivery time for each seller of tech products
select avg(datediff(order_delivered_customer_date, order_purchase_timestamp)) as avg_delivery_time, p.product_category_name, o.order_status, s.seller_id   
from orders o
inner join order_items oi on oi.order_id = o.order_id
inner join products p on p.product_id = oi.product_id
inner join product_category_name_translation pc on pc.product_category_name = p.product_category_name
inner join sellers s on oi.seller_id = s.seller_id
where pc.product_category_name_english in ('electronics','computers_accessories','pc_gamer','computers','consoles_games', 'telephony', 'watches_gifts') and o.order_status = 'delivered'
group by s.seller_id
order by avg_delivery_time desc;

#How many orders are delivered on time vs orders delivered with a delay?
select  
	count(case when datediff(order_estimated_delivery_date, order_delivered_customer_date) >= 0 then 1 end) as 'on time',
	count(case when datediff(order_estimated_delivery_date, order_delivered_customer_date) < 0 then 1 end) as 'delayed'
from orders
where order_status = 'delivered';

WITH main AS ( 
	SELECT * FROM orders
	WHERE order_delivered_customer_date AND order_estimated_delivery_date IS NOT NULL
    ),
    d1 AS (
	SELECT order_delivered_customer_date - order_estimated_delivery_date AS delay FROM main
    ), 
    d2 AS (
	SELECT 
		CASE WHEN delay > 0 THEN 1 ELSE 0 END AS pos_del,
		CASE WHEN delay <=0 THEN 1 ELSE 0 END AS neg_del FROM d1
	GROUP BY delay
    )
SELECT SUM(pos_del) AS delay, SUM(neg_del) AS on_time FROM d2;


#avg estimated delivery duration per category, min and max estimated delivery times vs real average delivery time
select avg(datediff(o.order_estimated_delivery_date, o.order_purchase_timestamp)) as estimated_avg_del_time, 
max(datediff(o.order_estimated_delivery_date, o.order_purchase_timestamp)) as max_estimated_del_time, 
min(datediff(o.order_estimated_delivery_date, o.order_purchase_timestamp)) as min_estimated_del_time, 
avg(datediff(o.order_delivered_customer_date, o.order_purchase_timestamp)) as real_avg_del_time,
p.product_category_name
from orders o
inner join order_items oi on o.order_id = oi.order_id
inner join products p on p.product_id = oi.product_id
where p.product_category_name in ('consoles_games', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'telefonia', 'relogios_presentes')
group by p.product_category_name;

#number of deliveries in 5 categories, very fast < 3 days, acceptable > 3 < 8 days, long > 8 < 20 days, too long > 20 < 50 days, ridiculous > 50 days    
select del_cat, count(del_cat)
from (
	select p.product_category_name,
		case 
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 3 then 'very fast delivery < 3 days'
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) > 3 and datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 8 then 'acceptable delivery'
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) > 8 and datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 20 then 'long delivery'
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) > 20 and datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 50 then 'too long delivery'
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) > 50 then 'ridiculous'
		end as del_cat
	from orders o
	inner join order_items oi on o.order_id = oi.order_id
	inner join products p on p.product_id = oi.product_id
	where order_status = 'delivered' 
	and p.product_category_name in ('consoles_games', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'telefonia', 'relogios_presentes')
    ) a
    group by del_cat;

#delivery times for cities sao paulo and rio de janeiro    
select del_cat, city, count(del_cat)
from (
	select p.product_category_name, city,
		case 
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 3 then 'very fast delivery < 3 days'
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) > 3 and datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 8 then 'acceptable delivery'
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) > 8 and datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 20 then 'long delivery'
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) > 20 and datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 50 then 'too long delivery'
			when datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) > 50 then 'ridiculous'
		end as del_cat
	from orders o
	inner join order_items oi on o.order_id = oi.order_id
	inner join products p on p.product_id = oi.product_id
    inner join customers c on c.customer_id = o.customer_id
    inner join geo g on g.zip_code_prefix = c.customer_zip_code_prefix
	where order_status = 'delivered' 
    and city in ('sao paulo', 'rio de janeiro')
	and p.product_category_name in ('consoles_games', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'telefonia', 'relogios_presentes')) a
    group by city, del_cat;
    

#select different dates from order_items
select o.order_purchase_timestamp, o.order_delivered_customer_date, o.order_estimated_delivery_date, oi.shipping_limit_date, datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) as del_time, datediff(o.order_estimated_delivery_date, o.order_purchase_timestamp) as est_del_time
from orders as o, order_items as oi, products as p
where o.order_id = oi.order_id
and oi.product_id = p.product_id
and product_category_name = 'pcs';
  

#Is there any pattern for delayed orders, e.g. big products being delayed more often?
with main as ( 
	SELECT * FROM orders
	WHERE order_delivered_customer_date AND order_estimated_delivery_date IS NOT NULL
    ),
    d1 as (
	SELECT *, datediff(order_estimated_delivery_date, order_delivered_customer_date) AS delay FROM main
    )
	SELECT
		case
			when delay <= 7 then '< 7 days delayed' 
            when delay > 7 and delay <= 21 then 'delay between 8 and 21 days '
			when delay > 21 and delay <= 100 then 'delay between 22 and 100 days'
            else '> 100 days delayed'
            end as delay_cat,
            avg(product_weight_g)/1000 as avg_prod_weight_kg,
            avg(product_length_cm) as avg_prod_length,
            avg(product_height_cm) as avg_prod_height,
            avg(product_width_cm) as avg_prod_width,
            count(*) as prod_count
    FROM d1 a
    INNER JOIN order_items b
    ON a.order_id = b.order_id
    INNER JOIN products c
    ON b.product_id = c.product_id
    WHERE delay > 0
    group by delay_cat
    ORDER BY delay DESC, product_weight_g DESC;

#where do tech customers live
select city, state, lat, lng, count(c.customer_id) as num_customers
from geo g
inner join customers c on c.customer_zip_code_prefix = g.zip_code_prefix
inner join orders o on o.customer_id = c.customer_id
inner join order_items oi on oi.order_id = o.order_id
inner join products p on p.product_id = oi.product_id
where p.product_category_name in ('consoles_games', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'telefonia', 'relogios_presentes')
group by city
having num_customers > 50
order by num_customers desc
limit 20;

# reviews per category
select review_score, review_comment_message
from order_reviews odr
inner join orders o on o.order_id = odr.order_id
inner join order_items oi on oi.order_id = o.order_id
inner join products p on p.product_id = oi.product_id
where p.product_category_name in ('consoles_games', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'telefonia', 'relogios_presentes');
