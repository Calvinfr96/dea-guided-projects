CREATE DATABASE retail;

 

USE retail;

 

CREATE TABLE customers (

  customer_id BIGINT PRIMARY KEY AUTO_INCREMENT,

  email       VARCHAR(200),

  first_name  VARCHAR(100),

  last_name   VARCHAR(100),

  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

);

 

CREATE TABLE products (

  product_id  BIGINT PRIMARY KEY AUTO_INCREMENT,

  name        VARCHAR(200),

  category    VARCHAR(100),

  price       DECIMAL(10,2),

  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);

 

CREATE TABLE orders (

  order_id    BIGINT PRIMARY KEY AUTO_INCREMENT,

  customer_id BIGINT,

  status      VARCHAR(30),

  total       DECIMAL(10,2),

  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

);

 

INSERT INTO customers (email, first_name, last_name) VALUES

 ('alice@test.com','Alice','Smith'),

 ('bob@test.com','Bob','Johnson');

 

INSERT INTO products (name, category, price) VALUES

 ('Laptop','Electronics',1200),

 ('Phone','Electronics',700);

 

INSERT INTO orders (customer_id, status, total) VALUES

 (1, 'NEW', 1200),

 (2, 'NEW', 700);