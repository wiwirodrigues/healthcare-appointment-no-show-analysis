-- =======================================================
-- HEALTHCARE APPOINTMENT NO-SHOW ANALYSIS
-- 02 - EXPLORATORY DATA ANALYSIS
-- =======================================================

USE appointments;

-- 1. Overall no-show rate
SELECT 
    No_show,
    COUNT(*) AS total_appointments,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM appointments),
        2
    ) AS pct_of_total
FROM appointments
GROUP BY No_show;

-- 2. Does the day of the week matter?
SELECT 
    DAYNAME(AppointmentDay) AS Appointment_day,
    COUNT(*) AS Total_appointments,
    SUM(
        CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END
    ) AS no_shows,
    ROUND(
        SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS rate_of_no_shows
FROM appointments
GROUP BY DAYNAME(AppointmentDay)
ORDER BY rate_of_no_shows DESC;

-- 3. Does lead time matter?
SELECT 
    CASE 
        WHEN lead_time_days = 0 THEN 'Same Day'
        WHEN lead_time_days BETWEEN 1 AND 3 THEN 'Short (1-3 Days)'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN 'Within a week'
        ELSE 'Long Lead (8+ days)'
    END AS lead_time_bucket,
    COUNT(*) AS total_appointments,
    ROUND(
        SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS no_show_rate
FROM appointments
GROUP BY lead_time_bucket
ORDER BY no_show_rate DESC;

-- 4. No-show rate by age group
SELECT 
    CASE 
        WHEN Age BETWEEN 0 AND 12 THEN 'Child'
        WHEN Age BETWEEN 13 AND 19 THEN 'Teen'
        WHEN Age BETWEEN 20 AND 39 THEN 'Young Adult'
        WHEN Age BETWEEN 40 AND 59 THEN 'Adult'
        ELSE 'Senior'
    END AS Age_group,
    COUNT(*) AS Total_appointments,
    ROUND(
        SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS No_show_rate
FROM appointments
GROUP BY Age_group
ORDER BY No_show_rate DESC;

-- 5. Are SMS reminders associated with different no-show rates?
SELECT 
    CASE
        WHEN SMS_received = 1 THEN 'Received SMS'
        ELSE 'No SMS'
    END AS Sms_status,
    COUNT(*) AS Total_appointments,
    ROUND(
        SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS No_show_rate
FROM appointments
GROUP BY Sms_status;

-- 6. Neighborhoods with the highest no-show rates
-- Only neighborhoods with at least 100 appointments
SELECT 
    Neighbourhood,
    COUNT(*) AS Total_appointments,
    ROUND(
        SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS No_show_rate,
    RANK() OVER (
        ORDER BY
            ROUND(
                SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END)
                * 100.0 / COUNT(*),
                2
            ) DESC
    ) AS Risk_rank
FROM appointments
GROUP BY Neighbourhood
HAVING Total_appointments >= 100
ORDER BY No_show_rate DESC
LIMIT 15;
