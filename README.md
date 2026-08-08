# Sales Analytics: SQL + Power BI

An end-to-end sales analytics project — a relational database designed and queried in **MySQL**, connected to an interactive **Power BI** dashboard for business insights.

## Overview

This project simulates a retail sales business with customers, products, orders, and order line items. It covers the full analytics workflow: schema design, data generation, SQL analysis (joins, window functions, CTEs), and dashboard building in Power BI.

- **Database:** MySQL
- **Dashboard:** Power BI
- **Scale:** 200 customers, 49 products, 1,000 orders, 2,100+ order line items

## Project Structure

```
sql-powerbi-sales-analysis/
├── sql/
│   ├── sales_project.sql       # Schema + data (run this first)
│   └── analysis_queries.sql    # Analytical queries + Power BI-ready view
├── powerbi/
│   └── sales project.pbix      # Power BI dashboard file
├── screenshots/
│   ├── powerbi sc/              # Dashboard pages, model view, DAX measures
│   └── sql sc/                  # ER diagram, sample query results
└── README.md
```

## Database Schema

Four related tables form the core of the project:

- **customers** — customer_id, name, email, city, state, region, segment, signup_date
- **products** — product_id, product_name, category, cost, price
- **orders** — order_id, customer_id, order_date, status, payment_method
- **order_items** — order_item_id, order_id, product_id, quantity, unit_price, discount

See `screenshots/sql sc/EER diagram.png` for the entity-relationship diagram.

## SQL Highlights

`analysis_queries.sql` includes 10 analytical queries covering:

- Revenue, profit, and average order value KPIs
- Monthly revenue trend and month-over-month growth (`LAG()` window function)
- Top products and categories by revenue and margin
- Customer ranking by lifetime spend (`RANK()`)
- Regional and segment-level revenue breakdown
- Repeat vs. one-time customer analysis
- A reusable `vw_sales_fact` view — a flattened fact table imported directly into Power BI

## Power BI Dashboard

Built across 4 report pages:

1. **Overview** — KPI cards (Revenue, Profit, Orders, AOV), monthly revenue trend, category donut, regional breakdown
2. **Products** — Top 10 products by revenue, category/margin table, revenue-vs-margin scatter
3. **Customers** — Top customers by spend, segment breakdown, repeat customer rate
4. **Regions** — Revenue by region on a map, region × segment comparison

Key DAX measures include `Total Revenue`, `Profit Margin %`, `Revenue MoM %`, `Repeat Customer %`, and `RANKX`-based product/customer rankings.

## Key Insights

From the analysis (see `sql/analysis_queries.sql` for the underlying queries):

- **Total revenue:** $1.55M across 737 completed/shipped/processing orders, with a 44.6% profit margin
- **Electronics** is the top category at 31.3% of revenue, followed by Sporting Goods (21.7%)
- **West, South, and Midwest** regions are closely matched (~28–30% each); East trails at 11.8%
- **79.6% of customers are repeat buyers** — a strong retention signal for the business
- Top single product by revenue: **Smartwatch** ($92.5K)

## How to Run This Project

1. Import the database: `mysql -u root -p < sql/sales_project.sql`
2. Run the analysis queries in `sql/analysis_queries.sql` to explore the data, or use the `vw_sales_fact` view directly
3. Open `powerbi/sales project.pbix` in Power BI Desktop (update the MySQL connection under Transform Data → Data Source Settings if needed)

## Tech Stack

`MySQL` · `SQL (Window Functions, CTEs, Views)` · `Power BI` · `DAX`
