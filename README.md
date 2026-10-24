# Olist E-commerce Analytics

SQL analysis of 100K+ orders from the Olist Brazilian e-commerce dataset (Kaggle).

## Business Questions
1. How do orders and revenue trend month by month?
2. Which states generate the most revenue?
3. How long does delivery take, and how often are orders late?
4. What share of customers come back?
5. Does late delivery hurt customer reviews?

## Key Findings
- Late deliveries reduced the average review score from **4.29 (on time)** to **2.57 (late)**.
- North-east states have the worst delivery performance: **AL ~23.9%** and **MA ~19.7%** of orders arrive late.
- RJ has high order volume (12,350 delivered orders) with ~13.5% late, so improving it would fix many orders.

## Recommendations
- Switch logistics partners or open a local warehouse in north-east states (AL, MA, PI, CE, SE).
- Prioritise reducing late deliveries in high-volume states like RJ.

## Tools Used
MySQL, SQL (JOINs, CTEs, window functions such as LAG), Power BI (in progress)

## Files
- `olist_analysis.sql`: 13 queries (revenue, AOV, delivery time, late %, repeat customers, MoM growth, delay vs review score, late % by state)



