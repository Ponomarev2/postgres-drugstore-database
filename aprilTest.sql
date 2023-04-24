-- Задание 1

-- Создание таблиц
CREATE TABLE products (
  name TEXT PRIMARY KEY,
	vital BOOLEAN NOT NULL,
	type TEXT NOT NULL,
	recipe TEXT
);

CREATE TABLE drugstores (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
	place TEXT NOT NULL,
	form TEXT NOT NULL
);

CREATE TABLE sales (
	id SERIAL PRIMARY KEY,
  date TIMESTAMP NOT NULL,
	checknum INTEGER NOT NULL,
	drugstore_id INTEGER REFERENCES drugstores(id),
	product TEXT REFERENCES products(name),
	quantity INTEGER NOT NULL,
	price REAL NOT NULL
);

-- Создание индексов
CREATE INDEX ON products(name);
CREATE INDEX ON drugstores(id);
CREATE INDEX ON sales(id);




-- Задание 2
-- Разработать хранимые процедуры для редактора товаров

-- Вывод списка товаров с фильтрами по Жизненно-важный и по типу
CREATE OR REPLACE FUNCTION get_products(v BOOLEAN, t TEXT) RETURNS TABLE(n TEXT, v BOOL, t TEXT, r TEXT)
LANGUAGE SQL
AS $$
  SELECT * FROM products WHERE vital=v AND type=t;
$$;

SELECT n AS "Название",
			 CASE
				 WHEN v THEN 'Да'
				 ELSE 'Нет'
       END AS "Жизненно-важный",
			 t AS "Тип товара",
			 r AS "Рецептурность"
FROM get_products(true, 'Антибиотик');


-- Добавление/изменение товара
CREATE OR REPLACE PROCEDURE add_product(n TEXT, v BOOLEAN, t TEXT, r TEXT)
LANGUAGE SQL
AS $$
  UPDATE products SET vital=v, type=t, recipe=r WHERE name=n;
	INSERT INTO products (name, vital, type, recipe)
			SELECT n, v, t, r
      WHERE NOT EXISTS (SELECT 1 FROM products WHERE name=n);
$$;

-- Удаление товара
CREATE OR REPLACE PROCEDURE del_product(n TEXT)
LANGUAGE SQL
AS $$
  DELETE FROM products WHERE name=n;
$$;


-- Задание 3
-- Написать SQL-запросы

-- 1.	Рассчитать среднюю цену типов товаров по всем аптекам и отсортировать по убыванию (от большей цены к меньшей) 
SELECT
	t1.drugstore_id,
	t1.type,
	AVG(t1.price) AS avg_price
FROM
	(SELECT * FROM sales JOIN products ON sales.product=products.name) AS t1
GROUP BY t1.drugstore_id, t1.type
ORDER BY t1.drugstore_id ASC, avg_price DESC;

-- 2.	Вывести 10 самых продаваемых товаров (по кол-ву упаковок) за май 2022 года по всем аптекам города Краснодара (от большего к меньшему).
SELECT
	t1.product,
	SUM(t1.quantity) AS qty
FROM
	(SELECT * FROM sales JOIN drugstores ON sales.drugstore_id=drugstores.id 
	 		WHERE sales.date >= '2022-05-01'
  		AND sales.date < '2022-06-01'
			AND drugstores.place='Краснодар') AS t1
GROUP BY t1.product
ORDER BY qty DESC
LIMIT 10;

-- 3.	Вывести товары и кол-во уникальных аптек, где данный товар продавался в течение 2022 года.
SELECT
	t1.product,
	COUNT(t1.drugstore_id) as count_unique_stores
FROM
	(SELECT DISTINCT drugstore_id, product 
	 		FROM sales 
			WHERE sales.date >= '2022-01-01'
  		AND sales.date < '2023-01-01' ) AS t1
GROUP BY t1.product
ORDER BY count_unique_stores ASC;

-- 4.	Вывести товары, которые в 2021 году не продавались в городе Краснодаре, но продавались где-то еще.
SELECT product FROM
	(SELECT name FROM products 
	WHERE name NOT IN
	(SELECT product FROM sales JOIN drugstores ON sales.drugstore_id=drugstores.id 
	 WHERE sales.date >= '2021-01-01'
				AND sales.date < '2022-01-01'
				AND drugstores.place = 'Краснодар')) AS t1
INNER JOIN			
	(SELECT product FROM sales JOIN drugstores ON sales.drugstore_id=drugstores.id 
	 WHERE sales.date >= '2021-01-01'
				AND sales.date < '2022-01-01'
				AND drugstores.place != 'Краснодар') AS t2
ON t1.name = t2.product;


-- 5.	Вывести 3 города, в котором находится больше всего аптек.
SELECT 
	place AS "Город",
	COUNT(*) AS "Кол-во аптек"
FROM drugstores 
GROUP BY place 
ORDER BY "Кол-во аптек" DESC 
LIMIT 3;


-- 6.	Выбрать товары, которые за 2021 год продавались не менее 10 упаковок в месяц, и среди них выбрать самую дорогую продажу. 
--    Вывести поля дата, аптека, город, товар, цена.
SELECT date, drugstore_id, place, product, price, (price * quantity) AS sum_of_sale
FROM sales JOIN drugstores ON sales.drugstore_id=drugstores.id 
WHERE product in
	(SELECT product 
	FROM
		(SELECT 
				DISTINCT product,
				COUNT(month_of_sales) AS count_of_month
			FROM
				(SELECT TO_CHAR(DATE_TRUNC('month', date), 'MM/YYYY')
								 AS  month_of_sales,
								 product, 
								 SUM(quantity) as amount
					FROM sales
					WHERE sales.date >= '2021-01-01'
						AND sales.date < '2022-01-01'
					GROUP BY DATE_TRUNC('month', date), product
					ORDER BY month_of_sales) AS t1
			WHERE t1.amount >= 10
			GROUP BY t1.product) as t2
		WHERE t2.count_of_month = 12)
AND sales.date >= '2021-01-01'
AND sales.date < '2022-01-01'
ORDER BY sum_of_sale DESC
LIMIT 1;



-- Задание 4
-- Напишите SQL-запрос для вывода списка запросов, выполняющихся в настоящий момент на сервере.
SELECT * 
FROM pg_stat_activity
WHERE state = 'active' 
ORDER BY query_start desc;