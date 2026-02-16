1)-- Доходы по месяцам (из таблицы дебиторской задолженности)
SELECT
    DATE_TRUNC('month', "Payment Date") AS month,
    SUM("Total Open Amount") AS total_revenue
FROM df_ar_open
GROUP BY month
ORDER BY month;

-- Расходы по месяцам (из таблицы счетов-фактур)
SELECT
    DATE_TRUNC('month', "Posting Date") AS month,
    SUM("Invoice Amount") AS total_expenses
FROM df_invoice
GROUP BY month
ORDER BY month;

-- Прибыль по месяцам (доходы - расходы)
WITH revenue AS (
    SELECT
        DATE_TRUNC('month', "Payment Date") AS month,
        SUM("Total Open Amount") AS total_revenue
    FROM df_ar_open
    GROUP BY month
),
expenses AS (
    SELECT
        DATE_TRUNC('month', "Posting Date") AS month,
        SUM("Invoice Amount") AS total_expenses
    FROM df_invoice
    GROUP BY month
)
SELECT
    COALESCE(r.month, e.month) AS month,
    COALESCE(total_revenue, 0) AS revenue,
    COALESCE(total_expenses, 0) AS expenses,
    COALESCE(total_revenue, 0) - COALESCE(total_expenses, 0) AS profit
FROM revenue r
FULL OUTER JOIN expenses e ON r.month = e.month
ORDER BY month;


2)WITH weekly_revenue AS (
    SELECT
        DATE_TRUNC('week', "Payment Date") AS week,
        SUM("Total Open Amount") AS revenue
    FROM df_ar_open
    GROUP BY week
)
SELECT
    week,
    revenue,
    LAG(revenue) OVER (ORDER BY week) AS prev_week_revenue,
    revenue - LAG(revenue) OVER (ORDER BY week) AS revenue_diff
FROM weekly_revenue
ORDER BY week;

3)-- Для выбранного месяца (например, '2020-01-01')
WITH daily_revenue AS (
    SELECT
        "Payment Date"::DATE AS day,
        SUM("Total Open Amount") AS daily_total
    FROM df_ar_open
    WHERE DATE_TRUNC('month', "Payment Date") = '2020-01-01' -- параметр
    GROUP BY day
)
SELECT
    day,
    daily_total,
    AVG(daily_total) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d
FROM daily_revenue
ORDER BY day;

4)SELECT
    c."Customer Name",
    SUM(a."Total Open Amount") AS overdue_total
FROM df_ar_open a
JOIN df_customers_data c ON a."Customer Number" = c."Customer ID"
WHERE a."Due Date" < CURRENT_DATE
  AND a."In Open" = 1  -- или статус открыт
GROUP BY c."Customer Name"
ORDER BY overdue_total DESC
LIMIT 10;

5)SELECT
    c."Customer Name",
    SUM(CASE
        WHEN a."Payment Date" <= a."Due Date" THEN a."Total Open Amount"
        ELSE 0
    END) AS paid_on_time,
    SUM(CASE
        WHEN a."Payment Date" > a."Due Date" OR (a."Payment Date" IS NULL AND a."In Open" = 1)
        THEN a."Total Open Amount"
        ELSE 0
    END) AS overdue_amount
FROM df_ar_open a
JOIN df_customers_data c ON a."Customer Number" = c."Customer ID"
GROUP BY c."Customer Name"
ORDER BY c."Customer Name";

6)-- По доходам
SELECT
    SUM("Total Open Amount") AS total_revenue,
    AVG("Total Open Amount") AS avg_revenue,
    MIN("Total Open Amount") AS min_revenue,
    MAX("Total Open Amount") AS max_revenue
FROM df_ar_open;

-- По расходам
SELECT
    SUM("Invoice Amount") AS total_expenses,
    AVG("Invoice Amount") AS avg_expenses,
    MIN("Invoice Amount") AS min_expenses,
    MAX("Invoice Amount") AS max_expenses
FROM df_invoice;

7)SELECT ...
FROM df_ar_open
WHERE DATE_TRUNC('month', "Payment Date") = {{month}}

WHERE EXTRACT(MONTH FROM "Payment Date") = {{month_number}}
  AND EXTRACT(YEAR FROM "Payment Date") = {{year}}
