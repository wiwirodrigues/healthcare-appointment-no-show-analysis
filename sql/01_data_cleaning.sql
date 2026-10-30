-- =======================================================
-- HEALTHCARE APPOINTMENT NO-SHOW ANALYSIS
-- 01 - DATA CLEANING AND FEATURE CREATION
-- =======================================================
-- Note: run this script once on the raw Kaggle table.
-- It renames and drops columns, so it is not meant to be re-run.

USE appointments;

-- Inspect the raw data
SELECT *
FROM appointments
LIMIT 10;

-- -------------------------------------------------------
-- 1. Standardize column names
-- -------------------------------------------------------
ALTER TABLE appointments
CHANGE COLUMN Hipertension Hypertension INT,
CHANGE COLUMN Handcap Disability_count INT,
CHANGE COLUMN `No-show` No_show VARCHAR(3);

-- Inspect disability distribution (0 to 4)
SELECT
    Disability_count,
    COUNT(*) AS total_appointments
FROM appointments
GROUP BY Disability_count;

-- -------------------------------------------------------
-- 2. Convert date fields
-- -------------------------------------------------------
ALTER TABLE appointments
ADD COLUMN scheduled_day_clean DATETIME,
ADD COLUMN appointment_day_clean DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE appointments
SET
    scheduled_day_clean = STR_TO_DATE(
        REPLACE(REPLACE(ScheduledDay, 'T', ' '), 'Z', ''),
        '%Y-%m-%d %H:%i:%s'
    ),
    appointment_day_clean = STR_TO_DATE(
        REPLACE(REPLACE(AppointmentDay, 'T', ' '), 'Z', ''),
        '%Y-%m-%d %H:%i:%s'
    );

-- Verify date conversion
SELECT
    ScheduledDay,
    scheduled_day_clean,
    AppointmentDay,
    appointment_day_clean
FROM appointments
LIMIT 10;

-- Replace the original text columns with the clean ones
ALTER TABLE appointments
DROP COLUMN ScheduledDay,
DROP COLUMN AppointmentDay;

ALTER TABLE appointments
CHANGE COLUMN scheduled_day_clean ScheduledDay DATETIME,
CHANGE COLUMN appointment_day_clean AppointmentDay DATE;

-- Study period (appointments: 2016-04-29 to 2016-06-08)
SELECT
    MIN(AppointmentDay) AS first_appointment,
    MAX(AppointmentDay) AS last_appointment
FROM appointments;

-- -------------------------------------------------------
-- 3. Remove invalid records
-- -------------------------------------------------------
-- Age range check
SELECT
    MIN(Age),
    MAX(Age)
FROM appointments;

-- Remove invalid age (1 row)
DELETE FROM appointments
WHERE Age = -1;

-- Lead time = days between booking and appointment
ALTER TABLE appointments
ADD COLUMN lead_time_days INT;

UPDATE appointments
SET lead_time_days = DATEDIFF(AppointmentDay, DATE(ScheduledDay));

-- Check and remove negative lead times (5 rows)
SELECT *
FROM appointments
WHERE lead_time_days < 0;

DELETE FROM appointments
WHERE lead_time_days < 0;

-- Expected result: 110,521 appointments
SELECT COUNT(*) AS total_appointments
FROM appointments;

-- -------------------------------------------------------
-- 4. Derived columns used in the analysis
-- -------------------------------------------------------
ALTER TABLE appointments
ADD COLUMN lead_time_group VARCHAR(20),  -- 6 groups, used in the chi-square tests
ADD COLUMN lead_band       VARCHAR(20),  -- 4 groups, used in the dashboard
ADD COLUMN age_group       VARCHAR(20),
ADD COLUMN day_name        VARCHAR(10),
ADD COLUMN has_disability  TINYINT;

UPDATE appointments
SET
    lead_time_group = CASE
        WHEN lead_time_days = 0              THEN 'Same day'
        WHEN lead_time_days BETWEEN 1 AND 3  THEN '1-3 days'
        WHEN lead_time_days BETWEEN 4 AND 7  THEN '4-7 days'
        WHEN lead_time_days BETWEEN 8 AND 15 THEN '8-15 days'
        WHEN lead_time_days BETWEEN 16 AND 30 THEN '16-30 days'
        ELSE '31+ days'
    END,
    lead_band = CASE
        WHEN lead_time_days = 0             THEN 'Same day'
        WHEN lead_time_days BETWEEN 1 AND 3 THEN '1-3 days'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN '4-7 days'
        ELSE '8+ days'
    END,
    age_group = CASE
        WHEN Age BETWEEN 0 AND 12  THEN 'Child'
        WHEN Age BETWEEN 13 AND 19 THEN 'Teen'
        WHEN Age BETWEEN 20 AND 39 THEN 'Young Adult'
        WHEN Age BETWEEN 40 AND 59 THEN 'Adult'
        ELSE 'Senior'
    END,
    day_name = DAYNAME(AppointmentDay),
    has_disability = CASE WHEN Disability_count > 0 THEN 1 ELSE 0 END;

SET SQL_SAFE_UPDATES = 1;

-- Verify cleaned data
SELECT *
FROM appointments
LIMIT 10;
