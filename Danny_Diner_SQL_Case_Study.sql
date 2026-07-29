CREATE DATABASE dannys_diner;
USE dannys_diner;
CREATE TABLE sales (
    customer_id CHAR(1),
    order_date DATE,
    product_id INT
);

CREATE TABLE menu (
    product_id INT,
    product_name VARCHAR(20),
    price INT
);

CREATE TABLE members (
    customer_id CHAR(1),
    join_date DATE
);

INSERT INTO sales VALUES
('A','2021-01-01',1),
('A','2021-01-01',2),
('A','2021-01-07',2),
('A','2021-01-10',3),
('A','2021-01-11',3),
('A','2021-01-11',3),
('B','2021-01-01',2),
('B','2021-01-02',2),
('B','2021-01-04',1),
('B','2021-01-11',1),
('B','2021-01-16',3),
('B','2021-02-01',3),
('C','2021-01-01',3),
('C','2021-01-01',3),
('C','2021-01-07',3);

INSERT INTO menu VALUES
(1,'sushi',10),
(2,'curry',15),
(3,'ramen',12);

INSERT INTO members VALUES
('A','2021-01-07'),
('B','2021-01-09');

Select * from sales;
select * from menu;
select * from members;

SELECT COUNT(*) FROM members;

-- Question 1 : What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id,
    SUM(m.price) AS total_amount_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- Question 2 : How many days has each customer visited the restaurant?
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS visit_days
FROM sales
GROUP BY customer_id;

-- Question 3 : What was the first item from the menu purchased by each customer?
SELECT
    s.customer_id,
    m.product_name,
    s.order_date
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
WHERE (s.customer_id, s.order_date) IN (
    SELECT
        customer_id,
        MIN(order_date)
    FROM sales
    GROUP BY customer_id
)
ORDER BY s.customer_id;

-- Question 4 : What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    m.product_name,
    COUNT(*) AS total_purchases
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchases DESC
LIMIT 1;

-- Question 5 :Which item was the most popular for each customer?
SELECT
    customer_id,
    product_name,
    order_count
FROM (
    SELECT
        s.customer_id,
        m.product_name,
        COUNT(*) AS order_count,
        DENSE_RANK() OVER (
            PARTITION BY s.customer_id
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM sales s
    JOIN menu m
        ON s.product_id = m.product_id
    GROUP BY
        s.customer_id,
        m.product_name
) t
WHERE rnk = 1;

-- Question 6 :Which item was purchased first by the customer after they became a member? 
SELECT
    customer_id,
    product_name,
    order_date
FROM (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.order_date
        ) AS rn
    FROM sales s
    JOIN members mem
        ON s.customer_id = mem.customer_id
    JOIN menu m
        ON s.product_id = m.product_id
    WHERE s.order_date >= mem.join_date
) t
WHERE rn = 1;

-- Question 7 :Which item was purchased just before the customer became a member?
SELECT
    customer_id,
    product_name,
    order_date
FROM (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.order_date DESC
        ) AS rn
    FROM sales s
    JOIN members mem
        ON s.customer_id = mem.customer_id
    JOIN menu m
        ON s.product_id = m.product_id
    WHERE s.order_date < mem.join_date
) t
WHERE rn = 1;

-- Question 8 :What is the total items and amount spent for each member before they became a member?
SELECT
    s.customer_id,
    COUNT(*) AS total_items,
    SUM(m.price) AS total_amount
FROM sales s
JOIN members mem
    ON s.customer_id = mem.customer_id
JOIN menu m
    ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;

-- Question 9 :If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales s
JOIN menu m
    ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- Question 10 :In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN s.order_date BETWEEN mem.join_date
                                AND DATE_ADD(mem.join_date, INTERVAL 6 DAY)
                THEN m.price * 20
            WHEN m.product_name = 'sushi'
                THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales s
JOIN members mem
    ON s.customer_id = mem.customer_id
JOIN menu m
    ON s.product_id = m.product_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;