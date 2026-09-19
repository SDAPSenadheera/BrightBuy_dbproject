# Checkout & Transactions Module - Progress Tracker

**Developer:** INDURU ADEESHA
**Role:** Database, Backend (Spring Boot), and Frontend (React) for Checkout Flow

---

## 🟢 Completed Tasks

* **Database Schema Definition:** Drafted and finalized the table structures for the checkout flow.
  * Created `orders` table with auto-incrementing surrogate keys and accurate `DATETIME` logging.
  * Created `order_item` junction table with a composite primary key (`order_id`, `variant_id`) to enforce 3NF normalization.
  * Created `delivery` and `payment` tables accurately linked to the main orders table.
  * Enforced relational integrity using foreign keys with `ON DELETE RESTRICT` to protect historical order data.

## 🟡 Currently Developing

* **ACID Stored Procedure (MySQL):**
  * Developing the `ProcessCheckout` stored procedure to handle atomic stock decrements.
  * Implementing row-level locking (`SELECT ... FOR UPDATE`) on the `VARIANT` table to prevent race conditions during high-traffic periods.
  * Utilizing `JSON_TABLE` to parse incoming cart payloads directly within the database.
  * Writing conditional logic to trigger a `ROLLBACK` if requested quantities exceed available warehouse stock.

## 🔴 Upcoming Tasks

### Backend (Spring Boot & Java)
* **Data Transfer Objects (DTOs):** Define Java record classes to map the incoming JSON cart payload.
* **JDBC Repository:** Configure `JdbcTemplate` and `SimpleJdbcCall` to safely invoke the MySQL stored procedure without using standard ORM features.
* **REST API Controller:** Create the `CheckoutController` to handle POST requests from the client.
* **Error Handling:** Map database rollback events to return an HTTP `409 Conflict` status code to the frontend.

### Frontend (React)
* **Shopping Cart Component (UI-5):** Build the UI to list cart items, modify quantities, and calculate the subtotal.
* **Multi-Step Checkout Flow (UI-8):** 
  * Step 1: Order Summary
  * Step 2: Delivery Mode Selection (Store Pickup vs. Standard Delivery)
  * Step 3: Logistics (City selection and Estimated Delivery Date display)
  * Step 4: Payment Method Selection
* **API Integration:** Connect the React form to the Spring Boot endpoint using `fetch()` or Axios to finalize the order.
* **Order Confirmation (UI-9):** Build the success screen displaying the newly generated Order ID and payment status.