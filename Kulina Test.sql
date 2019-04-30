CREATE DATABASE test;
CREATE TABLE test.orders(
	order_id INT PRIMARY KEY,
    user_id VARCHAR(50),
    lunch_type VARCHAR(50),
    days_of_subscription INT,
    box INT
);
INSERT INTO test.orders
VALUES (91881, '1011', 'Basic Lunch', 2, 10),
	(82191, '1012', 'Deluxe Lunch', 5, 8),
    (73817, '1011', 'Healthy Lunch', 3, 3),
    (91289, '1013', 'Healthy Lunch', 10,1),
    (81828, '1012', 'Deluxe Lunch',2,2),
    (82917, '1012', 'Healthy Lunch',2,1);
CREATE TABLE test.deliveries(
	delivery_id INT PRIMARY KEY,
    order_id INT,
    delivery_date DATETIME,
    box INT
);
INSERT INTO test.deliveries
VALUES (101910, 91881, '2018-08-01',10),
	(101891, 82191, '2018-08-01',8),
    (110000, 91881, '2018-08-02',10),
    (110011, 82191, '2018-08-02',8),
    (110200, 73817, '2018-08-02',3),
    (142932, 91289, '2018-08-10',1),
    (169281, 81828, '2018-08-20',2),
    (187181, 81828, '2018-08-25',2);
CREATE TABLE test.cashbacks(
	delivery_id INT PRIMARY KEY,
    cashback INT
);
INSERT INTO test.cashbacks
VALUES (101910,50000),
	(101891,38400),
    (110000,50000),
    (110011,38400),
    (110200,10500),
    (169281,3000),
    (187181,3000);
CREATE TABLE test.targeted_table AS (SELECT DISTINCT user_id FROM test.orders);
ALTER TABLE test.targeted_table
	ADD (total_orders INT,
		total_boxes_ordered INT,
        total_deluxe_boxes INT,
        total_basic_boxes INT,
        total_healthy_boxes INT,
        total_boxes_delivered INT,
        boxes_remaining INT,
        total_cashback INT);
UPDATE test.targeted_table AS T0
JOIN(
	SELECT orders.user_id, COUNT(DISTINCT order_id) AS total_orders FROM test.orders
    GROUP BY user_id) AS T1
    ON T0.user_id = T1.user_id
SET T0.total_orders = T1.total_orders;
UPDATE test.targeted_table AS T0
JOIN(
	SELECT orders.user_id, SUM(orders.days_of_subscription * orders.box) AS total_boxes_ordered FROM test.orders
    GROUP BY user_id) AS T1
    ON T0.user_id = T1.user_id
SET T0.total_boxes_ordered = T1.total_boxes_ordered;
UPDATE test.targeted_table AS T0
JOIN(
	SELECT orders.user_id, SUM(case when orders.lunch_type = 'Healthy Lunch' then orders.days_of_subscription * orders.box else 0 end) AS total_healthy_boxes FROM test.orders
    GROUP BY user_id) AS T1
    ON T0.user_id = T1.user_id
SET T0.total_healthy_boxes = T1.total_healthy_boxes;
ALTER TABLE test.orders
ADD (boxes_delivered INT);
UPDATE test.orders AS T0
JOIN(
	SELECT deliveries.order_id, SUM(box) AS boxes_delivered FROM test.deliveries
    GROUP BY order_id) AS T1
    ON T0.order_id = T1.order_id
SET T0.boxes_delivered = T1.boxes_delivered;
UPDATE test.targeted_table AS T0
JOIN(
	SELECT orders.user_id, SUM(boxes_delivered) AS total_boxes_delivered FROM test.orders
    GROUP BY user_id) AS T1
    ON T0.user_id = T1.user_id
SET T0.total_boxes_delivered = T1.total_boxes_delivered;
UPDATE test.targeted_table
SET boxes_remaining = total_boxes_ordered - total_boxes_delivered;
ALTER TABLE test.deliveries
ADD (cashback INT);
UPDATE test.deliveries AS T0
JOIN (SELECT cashbacks.delivery_id, cashback FROM test.cashbacks) AS T1
ON T0.delivery_id = T1.delivery_id
SET T0.cashback = T1.cashback;
ALTER TABLE test.orders
ADD (cashback INT);
UPDATE test.orders AS T0
JOIN(
	SELECT deliveries.order_id, SUM(cashback) AS cashback FROM test.deliveries
    GROUP BY order_id) AS T1
    ON T0.order_id = T1.order_id
SET T0.cashback = T1.cashback;
UPDATE test.targeted_table AS T0
JOIN(
	SELECT orders.user_id, SUM(cashback) AS total_cashback FROM test.orders
    GROUP BY user_id) AS T1
    ON T0.user_id = T1.user_id
SET T0.total_cashback = T1.total_cashback;
UPDATE test.targeted_table
SET total_cashback = 0 WHERE total_cashback IS NULL;
SELECT * FROM test.targeted_table;
