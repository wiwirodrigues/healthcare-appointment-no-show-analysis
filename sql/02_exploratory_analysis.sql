-- =======================================================
-- HEALTHCARE APPOINTMENT NO-SHOW ANALYSIS
-- 02 - EXPLORATORY DATA ANALYSIS
-- =======================================================
-- These queries produce the contingency tables
-- used in the chi-square tests (Excel).

USE appointments;

-- 1. Overall no-show rate (expected: 20.2%)
SELECT
    No_show,
    COUNT(*) AS total_appointments,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 2) AS pct_of_total
FROM appointments
GROUP BY No_show;

-- 2. H1.1 - Lead time (6 groups)
SELECT
    lead_time_group,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY lead_time_group
ORDER BY MIN(lead_time_days);

-- 3. H1.2 - Day of week (Saturday excluded: 39 appointments)
SELECT
    day_name,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
WHERE day_name <> 'Saturday'
GROUP BY day_name
ORDER BY no_show_rate DESC;

-- 4. H2.1 - SMS, raw comparison
SELECT
    CASE WHEN SMS_received = 1 THEN 'Received SMS' ELSE 'No SMS' END AS sms_status,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY sms_status;

-- 5. H2.2 - SMS within each lead-time group (controls for lead time)
SELECT
    lead_time_group,
    CASE WHEN SMS_received = 1 THEN 'Received SMS' ELSE 'No SMS' END AS sms_status,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY lead_time_group, sms_status
ORDER BY MIN(lead_time_days), sms_status;

-- 6. H3.1 - Age group
SELECT
    age_group,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY age_group
ORDER BY no_show_rate DESC;

-- 7. H3.1 - Gender
SELECT
    Gender,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY Gender;

-- 8. H3.2 / H3.3 - Scholarship and health conditions
--    (change the column to Hypertension, Diabetes, Alcoholism or has_disability)
SELECT
    Scholarship,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY Scholarship;

-- 9. H4.1 - Neighborhoods with at least 200 appointments
SELECT
    Neighbourhood,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate,
    RANK() OVER (
        ORDER BY SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) DESC
    ) AS rate_rank
FROM appointments
GROUP BY Neighbourhood
HAVING COUNT(*) >= 200
ORDER BY no_show_rate DESC;
