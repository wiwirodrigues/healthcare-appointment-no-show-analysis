-- =======================================================
-- HEALTHCARE APPOINTMENT NO-SHOW ANALYSIS
-- 03 - PATIENT HISTORY AND RISK SEGMENTATION
-- =======================================================

USE appointments;

-- -------------------------------------------------------
-- 1. Patient history with window functions
-- -------------------------------------------------------
-- Only appointments BEFORE the current one are counted,
-- to avoid using future information.
-- ScheduledDay and AppointmentID break ties when a patient
-- has more than one appointment on the same day.

CREATE OR REPLACE VIEW v_appointment_risk AS
WITH patient_history AS (
    SELECT
        PatientId,
        AppointmentID,
        AppointmentDay,
        Neighbourhood,
        lead_time_days,
        lead_band,
        SMS_received,
        Scholarship,
        No_show,
        COUNT(*) OVER w AS prior_appointments,
        COALESCE(
            SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) OVER w,
            0
        ) AS prior_no_shows
    FROM appointments
    WINDOW w AS (
        PARTITION BY PatientId
        ORDER BY AppointmentDay, ScheduledDay, AppointmentID
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    )
)
SELECT
    *,
    -- Used in H3.4
    CASE
        WHEN prior_appointments = 0 THEN 'First visit'
        WHEN prior_no_shows = 0     THEN 'Returning, no prior no-show'
        ELSE 'Prior no-show'
    END AS no_show_history,
    -- Risk tier: 8+ days is always High Risk;
    -- shorter lead times move up one tier if the patient has a prior no-show
    CASE
        WHEN lead_time_days >= 8 THEN 'High Risk'
        WHEN lead_time_days BETWEEN 4 AND 7
            THEN CASE WHEN prior_no_shows > 0 THEN 'High Risk' ELSE 'Medium Risk' END
        ELSE
            CASE WHEN prior_no_shows > 0 THEN 'Medium Risk' ELSE 'Low Risk' END
    END AS risk_tier
FROM patient_history;

-- Inspect the view
SELECT *
FROM v_appointment_risk
LIMIT 20;

-- -------------------------------------------------------
-- 2. H3.4 - No-show history
-- -------------------------------------------------------
SELECT
    no_show_history,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM v_appointment_risk
GROUP BY no_show_history;

-- -------------------------------------------------------
-- 3. Risk tier summary (table in the README)
-- -------------------------------------------------------
SELECT
    risk_tier,
    COUNT(*) AS total_appointments,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_appointments,
    ROUND(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS no_show_rate,
    ROUND(
        SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / SUM(SUM(CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END)) OVER (),
        1
    ) AS pct_of_all_no_shows
FROM v_appointment_risk
GROUP BY risk_tier
ORDER BY no_show_rate DESC;

-- -------------------------------------------------------
-- 4. Final dataset exported to Power BI
-- -------------------------------------------------------
SELECT
    PatientId,
    AppointmentID,
    AppointmentDay,
    Neighbourhood,
    lead_time_days,
    lead_band,
    SMS_received,
    Scholarship,
    No_show,
    prior_appointments,
    prior_no_shows,
    no_show_history,
    risk_tier
FROM v_appointment_risk;
