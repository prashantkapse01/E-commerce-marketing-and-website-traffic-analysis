USE mavenfuzzyfactory;

/* 
This project focuses on analyzing and showcasing key business metrics and trends using SQL queries. 
It includes tracking growth in sessions and orders by channel and product, analyzing efficiency improvements in conversion rates 
revenue metrics, and assessing the impact of new product introductions and cross-selling strategies. 
The queries provide insights into seasonal trends, performance optimizations, and strategic milestones since the inception of the business. 
Overall, the project aims to highlight both the quantitative growth and qualitative enhancements that have shaped the business's trajectory over time.
*/

/*
1. -- Query to pull monthly trends for gsearch sessions and orders
-- This query will help in showcasing the growth of the business driven by gsearch.
-- It should aggregate the number of sessions and orders per month for the source 'gsearch'. 
*/ 
SELECT
	YEAR(ws.created_at) AS yr, 
    MONTH(ws.created_at) AS mo, 
    COUNT(DISTINCT ws.website_session_id) AS sessions, 
    COUNT(DISTINCT ord.order_id) AS orders, 
    COUNT(DISTINCT ord.order_id)/COUNT(DISTINCT ws.website_session_id) * 100 AS conv_rate
FROM website_sessions ws
	LEFT JOIN orders ord
	ON ord.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch'
GROUP BY yr,mo;

/*
-- Query to pull monthly trends for gsearch sessions and orders, 
-- split by nonbrand and brand campaigns.
-- This query will help in analyzing if brand campaigns are gaining traction.
-- It should aggregate the number of sessions and orders per month for 'gsearch' source, 
separated by campaign type (nonbrand and brand).
. 
*/ 
SELECT
	YEAR(ws.created_at) AS yr, 
    MONTH(ws.created_at) AS mo, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN ord.order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ord.order_id ELSE NULL END) AS brand_orders
FROM website_sessions ws
	LEFT JOIN orders ord
	ON ord.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch'
GROUP BY yr,mo;


/*
3.	-- Query to pull monthly trends for gsearch nonbrand sessions and orders, 
split by device type.
-- This query will provide a detailed analysis of nonbrand traffic sources,
showcasing monthly sessions and orders by device type.
-- It will help in demonstrating a deep understanding of our traffic sources to the board.
*/ 
SELECT
	YEAR(ws.created_at) AS yr, 
    MONTH(ws.created_at) AS mo, 
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions, 
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN ord.order_id ELSE NULL END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions, 
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN ord.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions ws
	LEFT JOIN orders ord
		ON ord.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
GROUP BY yr,mo;



/*
-- Query to pull monthly trends for sessions and orders from gsearch alongside other channels.
-- This query will help in comparing the performance of gsearch with other traffic sources.
-- It should aggregate the number of sessions and orders per month for each channel,
allowing us to address concerns about the dependency on gsearch.
*/ 
-- first, finding the various utm sources and referers to see the traffic we're getting
SELECT 
DISTINCT 
	utm_source,
    utm_campaign, 
    http_referer
FROM website_sessions;

SELECT
	YEAR(ws.created_at) AS yr, 
    MONTH(ws.created_at) AS mo, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN ws.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN ws.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions ws
	LEFT JOIN orders ord
		ON ord.website_session_id = ws.website_session_id
GROUP BY yr,mo;


/*
5.-- This query will help in telling the story of website performance improvements.
-- It should calculate the conversion rate (orders/sessions) per month,
showcasing the improvements over time.
*/ 
SELECT
	YEAR(ws.created_at) AS yr, 
    MONTH(ws.created_at) AS mo, 
    COUNT(DISTINCT ws.website_session_id) AS sessions, 
    COUNT(DISTINCT ord.order_id) AS orders, 
    COUNT(DISTINCT ord.order_id)/COUNT(DISTINCT ws.website_session_id) * 100 AS conversion_rate    
FROM website_sessions ws
	LEFT JOIN orders ord
		ON ord.website_session_id = ws.website_session_id
GROUP BY yr,mo;


/*
6.-- Query to analyze the lift generated from the test in terms of revenue per billing page session.
-- This query will calculate the revenue per billing page session before and after the test to determine the lift.
-- Additionally, it will pull the number of billing page sessions for the past month to understand the monthly impact.
*/ 
SELECT
	billing_version_seen, 
    COUNT(DISTINCT website_session_id) AS sessions, 
    SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
 FROM( 
SELECT 
	website_pageviews.website_session_id, 
    website_pageviews.pageview_url AS billing_version_seen, 
    orders.order_id, 
    orders.price_usd
FROM website_pageviews 
	LEFT JOIN orders
		ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at > '2022-09-10' -- prescribed in assignment
	AND website_pageviews.created_at < '2022-11-10' -- prescribed in assignment
    AND website_pageviews.pageview_url IN ('/billing','/billing-2')
) AS billing_pageviews_and_order_data
GROUP BY 1
;
-- $22.83 revenue per billing page seen for the old version
-- $33. for the new version
-- LIFT: $8.51 per billing page view

SELECT 
	COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews 
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2') 
	AND created_at BETWEEN '2022-10-27' AND '2022-11-27'; -- past month
    
-- 2,314 billing sessions past month
-- LIFT: $8.51 per billing session
-- VALUE OF BILLING TEST: $19,692 over the past month

/*
7. -- Query to pull overall session and order volume, trended by quarter for the life of the business.
-- This query will help in showcasing the volume growth over time.
-- It should aggregate the number of sessions and orders per quarter.
-- The most recent quarter is incomplete, so decide on the best approach to handle this.
*/ 
SELECT 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr, 
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions, 
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY yr,qtr
ORDER BY yr,qtr
;

/*
8. Query to showcase efficiency improvements since launch, with quarterly figures.
-- This query will calculate quarterly session-to-order conversion rate, revenue per order, and revenue per session.
-- It should aggregate these metrics since the launch of the business to showcase improvements over time. 
*/
SELECT 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr, 
	COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate, 
    SUM(price_usd)/COUNT(DISTINCT orders.order_id) AS revenue_per_order, 
    SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY yr,qtr
ORDER BY yr,qtr
;


/*
9. -- Query to pull quarterly view of orders from specific channels.
-- This query will provide a breakdown of orders by quarter for Gsearch nonbrand, Bsearch nonbrand, 
brand search overall, organic search, and direct type-in.
-- It should aggregate the number of orders quarterly for each specified channel.
*/
SELECT 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS gsearch_nonbrand_orders, 
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS bsearch_nonbrand_orders, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) AS organic_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) AS direct_type_in_orders
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY yr,qtr
ORDER BY yr,qtr;

/*
10. -- Query to show the overall session-to-order conversion rate trends by quarter for specific channels.
-- This query will calculate the session-to-order conversion rate quarterly for Gsearch nonbrand, Bsearch nonbrand, 
brand search overall, organic search, and direct type-in.
-- It should also include notes on any periods where major improvements or optimizations were made.
*/
SELECT 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rt, 
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rt, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_search_conv_rt,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_conv_rt,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_conv_rt
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY yr,qtr
ORDER BY yr,qtr;


/*
11. -- Query to pull monthly trending for revenue and margin by product, along with total sales and revenue.
-- This query will analyze revenue and margin trends monthly for each product, as well as total sales and revenue.
Please note any observed seasonality trends in the data.
*/
SELECT
	YEAR(created_at) AS yr, 
    MONTH(created_at) AS mo, 
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mrfuzzy_rev,
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_marg,
    SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev,
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS lovebear_marg,
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS birthdaybear_rev,
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS birthdaybear_marg,
    SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS minibear_rev,
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS minibear_marg,
    SUM(price_usd) AS total_revenue,  
    SUM(price_usd - cogs_usd) AS total_margin
FROM order_items 
GROUP BY yr,mo
ORDER BY yr,mo;


/*
12. -- Query to analyze the impact of introducing new products.
-- This query will pull monthly sessions to the /products page and show how the percentage of those sessions 
-- clicking through another page has changed over time.
-- Additionally, it will provide a view of how conversion from /products to placing an order has improved.
*/
-- first, identifying all the views of the /products page
CREATE TEMPORARY TABLE products_pageviews
SELECT
	website_session_id, 
    website_pageview_id, 
    created_at AS saw_product_page_at

FROM website_pageviews 
WHERE pageview_url = '/products'
;

SELECT 
	YEAR(saw_product_page_at) AS yr, 
    MONTH(saw_product_page_at) AS mo,
    COUNT(DISTINCT products_pageviews.website_session_id) AS sessions_to_product_page, 
    COUNT(DISTINCT website_pageviews.website_session_id) AS clicked_to_next_page, 
    COUNT(DISTINCT website_pageviews.website_session_id)/COUNT(DISTINCT products_pageviews.website_session_id) AS clickthrough_rt,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT products_pageviews.website_session_id) AS products_to_order_rt
FROM products_pageviews
	LEFT JOIN website_pageviews 
		ON website_pageviews.website_session_id = products_pageviews.website_session_id -- same session
        AND website_pageviews.website_pageview_id > products_pageviews.website_pageview_id -- they had another page AFTER
	LEFT JOIN orders 
		ON orders.website_session_id = products_pageviews.website_session_id
GROUP BY yr,mo;

/*
13. -- Query to pull sales data since December 5, 2023, and analyze cross-selling between products.
-- This query will show sales data for each product since the 4th product became available as a primary product.
-- It will also analyze how well each product cross-sells from one another.
*/
CREATE TEMPORARY TABLE primary_products
SELECT 
	order_id, 
    primary_product_id, 
    created_at AS ordered_at
FROM orders 
WHERE created_at > '2023-12-05' ;-- when the 4th product was added (says so in question)

SELECT
	primary_products.*, 
    order_items.product_id AS cross_sell_product_id
FROM primary_products
	LEFT JOIN order_items 
		ON order_items.order_id = primary_products.order_id
        AND order_items.is_primary_item = 0; -- only bringing in cross-sells;

SELECT 
	primary_product_id, 
    COUNT(DISTINCT order_id) AS total_orders, 
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) AS _xsold_p1,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) AS _xsold_p2,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) AS _xsold_p3,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) AS _xsold_p4,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p1_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p2_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p3_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p4_xsell_rt
FROM
(
SELECT
	primary_products.*, 
    order_items.product_id AS cross_sell_product_id
FROM primary_products
	LEFT JOIN order_items 
		ON order_items.order_id = primary_products.order_id
        AND order_items.is_primary_item = 0 -- only bringing in cross-sells
) AS primary_w_cross_sell
GROUP BY 1;

