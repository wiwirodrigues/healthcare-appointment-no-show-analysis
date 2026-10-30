# Healthcare Appointment No-Show Analysis

SQL, Excel and Power BI analysis of 110,521 medical appointments, combining a structured business-problem approach with chi-square hypothesis testing to identify what is associated with missed appointments and which actions to test first.

**[View the interactive Power BI dashboard](https://app.powerbi.com/view?r=eyJrIjoiNGRlYTU5ZTktZDUzMy00OTg0LThhNTktOTYzZmVjMzc5MTAyIiwidCI6Ijk1NDYxM2ZhLWUzN2UtNDZkNi04NGYxLTJmYjNmMzY3MjExMyJ9)**

## Key Findings

- **1 in 5 appointments ends in a no-show (20.2%)**, not the 30% cited in the Kaggle dataset description.
- **Lead time is the dominant factor.** The no-show rate rises from **4.6%** for same-day appointments to **33.0%** for appointments booked 31+ days ahead (Cramér's V = 0.295). Appointments booked one day or more ahead account for **92% of all no-shows**.
- **SMS reminders show a Simpson's paradox.** In the raw data, patients who received an SMS missed *more* (27.6% vs 16.7%), because SMS is only sent for appointments booked well in advance. Within the same lead-time group, SMS is associated with **3.1 to 7.3 p.p. fewer no-shows**.
- **Past behavior repeats.** Patients with a prior no-show miss 26.9% of the time, against 18.8% for returning patients who never missed.
- **Recommendation:** run a controlled pilot of **SMS with active confirmation** (confirm or cancel) for appointments booked 4+ days ahead, and refill cancelled slots through a waiting list.

![Executive presentation](assets/01_cover.png)

## Project Overview

Patient no-shows create idle capacity, longer waiting lists and rework for scheduling teams. This project follows a structured problem-solving method (**DEASA**: Define, Structure, Analyze, Solutions, Present):

1. **Define** the problem with the ACERT framework.
2. **Structure** it as a MECE hypothesis tree.
3. **Analyze** the data with MySQL, test each hypothesis with chi-square in Excel and build a Power BI dashboard.
4. **Develop solutions** prioritized by evidence, impact and feasibility.
5. **Present** the results in an executive deck in English, built on the pyramid principle.

## Business Problem

**Central question:** how can we reduce no-shows to medical appointments?

| ACERT | Definition |
| --- | --- |
| **Actors** | Unit management (decision maker): use the schedule efficiently · Scheduling team: fewer no-shows, late cancellations and rework · Doctors: fewer idle slots and better continuity of care · Patients: be able to attend and receive care |
| **Success criteria** | Reduce the no-show rate from the 20.2% baseline (target to be validated with management) without increasing waiting times |
| **Scope** | Appointment records of the health unit, April 29 to June 8, 2016 (about six weeks) |
| **Restrictions** | Data quality and availability, existing resources only, patient privacy (LGPD), and observational data that cannot prove causation |
| **Time** | Not set; to be defined with management |

## Dataset

[Medical Appointment No-Shows](https://www.kaggle.com/datasets/joniarroba/noshowappointments) (Kaggle). After cleaning, the analysis included **110,521 appointments**.

| Variable | Description |
| --- | --- |
| PatientId | Patient identifier |
| AppointmentID | Appointment identifier |
| Gender | Patient gender |
| Age | Patient age |
| Neighbourhood | Neighborhood where the patient lives |
| Scholarship | Whether the patient receives a government welfare benefit (low-income families) |
| Hypertension, Diabetes, Alcoholism | Health condition indicators |
| Disability_count | Number of disabilities (0 to 4) |
| SMS_received | Whether an SMS reminder was received |
| ScheduledDay | Date and time the appointment was booked |
| AppointmentDay | Date of the appointment |
| No_show | Whether the patient missed the appointment ("Yes" = missed) |
| lead_time_days | Days between booking and appointment |

## Data Cleaning (MySQL)

- Standardized column names and converted date fields
- Removed invalid ages (−1) and negative lead times
- Created `lead_time_days`, `lead_time_group` (6 groups, for the tests), `lead_band` (4 groups, for the dashboard), `age_group`, `day_name` and `has_disability` (1 if Disability_count > 0)
- In `03_risk_analysis.sql`, used window functions to count each patient's `prior_appointments` and `prior_no_shows` (only appointments **before** the current one, to avoid using future information), then derived `no_show_history` (First visit / Returning, no prior no-show / Prior no-show) and `risk_tier`

## Statistical Testing

### Why the chi-square test

Each hypothesis asks whether **no-show (Yes/No)** depends on a **categorical** variable (lead-time group, SMS, age group, neighborhood...). The chi-square test of independence is built for exactly this:

- **The outcome is categorical.** No-show is a proportion, not an average, so t-tests do not apply.
- **The predictors are categorical**, with two or more groups. One test covers all groups at once (e.g., 6 lead-time groups) instead of many pairwise comparisons.
- **Its assumptions are met.** With 110,000 rows, expected counts are well above 5 in almost every cell. Small groups were excluded where they were not (Saturday, neighborhoods with < 200 appointments).
- **It is transparent.** It compares observed counts with the counts expected if there were no relationship, and can be built step by step in Excel.

### What the chi-square does *not* tell us, and how this was handled

| Limitation | How it was handled |
| --- | --- |
| With a large sample, almost any difference is "significant" | A hypothesis is confirmed only if **p < 0.05 *and* the rate difference ≥ 3 p.p.** (≥ 5 p.p. for lead time) |
| It does not measure strength | **Cramér's V** reported as effect size (< 0.10 weak · 0.10–0.30 moderate · > 0.30 strong) |
| It does not show direction | No-show rates compared group by group |
| It compares two variables at a time and can be confounded | **Stratified tests**: SMS and neighborhood re-tested within each lead-time group (H2.2, H4.2) |
| It assumes independent observations | Some patients have several appointments; p-values are slightly optimistic, so decisions rely on effect sizes |
| It does not fit before/after measurements on the same patients | The pilot should use an **A/B design** (chi-square); a before/after on the same patients would need **McNemar's test** |

### Test used for each hypothesis

| Hypothesis | Test | d.f. | Notes |
| --- | --- | --- | --- |
| H1.1 Lead time | Chi-square, 6 × 2 | 5 | |
| H1.2 Weekday | Chi-square, 5 × 2 | 4 | Saturday excluded (39 appointments, unstable rate) |
| H1.3 Concentration | No test: share of no-shows vs share of appointments | — | A distribution question, not an association question |
| H2.1 Raw SMS | Chi-square, 2 × 2 | 1 | Confounded by lead time |
| H2.2 SMS controlled | Chi-square 2 × 2 **within each** lead-time group | 1 per group | Same-day group has no SMS |
| H3.1 Age · Gender | Chi-square, 5 × 2 · 2 × 2 | 4 · 1 | |
| H3.2 Scholarship | Chi-square, 2 × 2 | 1 | |
| H3.3 Health conditions | Chi-square, 2 × 2 for each condition | 1 | `has_disability` used instead of the 0–4 count (tiny groups) |
| H3.4 History | Chi-square, 3 × 2 | 2 | 87% of the χ² comes from the "prior no-show" group |
| H4.1 Neighborhoods | Chi-square, 69 × 2 | 68 | Only neighborhoods with ≥ 200 appointments |
| H4.2 Neighborhood controlled | Rate comparison within each lead-time group | — | 6 high-rate neighborhoods vs all others |

## Results

| Hypothesis | Main finding | Difference | Cramér's V | Verdict |
| --- | --- | --- | --- | --- |
| H1.1 Lead time | 4.6% same day → 33.0% at 31+ days | 28.4 p.p. | 0.295 | Confirmed |
| H1.2 Weekday | 19.3% (Thu) to 21.2% (Fri) | 1.9 p.p. | 0.016 | Rejected |
| H1.3 Concentration | Top two lead-time groups hold only 42.9% of no-shows; they are spread across all groups booked 1+ day ahead | — | — | Rejected (not concentrated) |
| H2.1 Raw SMS | 27.6% with SMS vs 16.7% without | +10.9 p.p. | 0.127 | Confounded |
| H2.2 SMS controlled | Lower rates with SMS in every group of 4+ days | −3.1 to −7.3 p.p. | 0.035–0.076 | Confirmed |
| H3.1 Age | Teen 26.0% → Senior 15.3% | 10.7 p.p. | 0.079 | Confirmed |
| H3.1 Gender | 20.3% vs 20.0% (p = 0.17) | 0.3 p.p. | 0.004 | Rejected |
| H3.2 Scholarship | 23.7% with vs 19.8% without | 3.9 p.p. | 0.029 | Confirmed (weak) |
| H3.3 Hypertension | 17.3% vs 20.9% | 3.6 p.p. | 0.036 | Confirmed (weak) |
| H3.3 Diabetes · Alcoholism · Disability | Differences of 0.1 to 2.4 p.p. | < 3 p.p. | ≤ 0.015 | Rejected |
| H3.4 No-show history | 26.9% with prior no-show vs 18.8% without | 8.0 p.p. | 0.064 | Confirmed |
| H4.1 Neighborhoods | 6 of 69 neighborhoods ≥ 3 p.p. above average (9.9% of appointments) | up to 8.7 p.p. | 0.066 | Confirmed (limited impact) |
| H4.2 Neighborhood × lead time | Gap persists in every lead-time group | +1.2 to +12.0 p.p. | — | Confirmed |

![Lead time](assets/02_lead_time.png)

![SMS](assets/03_sms_paradox.png)

![History and neighborhoods](assets/04_history_neighborhoods.png)

## Risk Segmentation (SQL)

A rule-based segmentation in `03_risk_analysis.sql` combines **lead time** and the patient's **prior no-show behavior** to flag appointments that may need extra follow-up. Appointments booked 8+ days ahead are always High Risk; shorter lead times move up a tier when the patient has missed previous appointments.

| Risk tier | Appointments | Share of appointments | No-show rate | Share of all no-shows |
| --- | --- | --- | --- | --- |
| High Risk | 45,548 | 41.2% | 30.8% | 62.8% |
| Medium Risk | 17,470 | 15.8% | 23.7% | 18.5% |
| Low Risk | 47,503 | 43.0% | 8.7% | 18.6% |
| **Total** | **110,521** | **100%** | **20.2%** | **100%** |

**Reading:** the High Risk tier holds 41% of appointments but 63% of all no-shows, so focusing reminders and confirmations on it reaches most of the problem with less effort. Low Risk appointments miss only 8.7% of the time.

This is a rule-based segmentation, not a predictive model, and it was not validated on new data. It was not used as a variable in the hypothesis tests, because it is built from the same variables being tested.

## Power BI Dashboard

- **KPI cards:** total appointments (110,521), no-show rate (20.2%) and median lead time (4 days)
- **No-show rate by day of week**, with Saturday omitted (only 39 appointments)
- **No-show rate by lead time:** same day 4.6%, 1–3 days 22.9%, 4–7 days 25.2%, 8+ days 32.1%
- **Appointments and share of no-shows by risk tier**, with a risk-tier filter
- **Top 15 neighborhoods** by no-show rate
- **Appointment detail table** with lead time, prior appointments, prior no-shows, SMS and risk tier

[![Dashboard preview](assets/dashboard_preview.png)](https://app.powerbi.com/view?r=eyJrIjoiNGRlYTU5ZTktZDUzMy00OTg0LThhNTktOTYzZmVjMzc5MTAyIiwidCI6Ijk1NDYxM2ZhLWUzN2UtNDZkNi04NGYxLTJmYjNmMzY3MjExMyJ9)

**[Open the interactive dashboard](https://app.powerbi.com/view?r=eyJrIjoiNGRlYTU5ZTktZDUzMy00OTg0LThhNTktOTYzZmVjMzc5MTAyIiwidCI6Ijk1NDYxM2ZhLWUzN2UtNDZkNi04NGYxLTJmYjNmMzY3MjExMyJ9)** (no login required)

## Recommendations and Action Plan

| Initiative | Priority | Proposed decision |
| --- | --- | --- |
| SMS with active confirmation | 1 | Test through a controlled pilot |
| Refill cancelled slots (waiting list) | 2 | Assess together with the cancellation process |
| Targeted reminder for patients with prior no-shows | 3 | Test with a control group |
| Neighborhood differences | Investigate | Understand access barriers before intervening, without penalizing residents |

Rough sizing: extending SMS to the ~40% of 4+ day appointments without one could avoid about 1,270 no-shows (≈ 5.7% of all no-shows), *if* the observed association were causal. That is why the pilot comes first.

![Recommendation](assets/05_recommendation.png)

## Limitations

- Observational data: the results show association, not causation.
- Only April 29 to June 8, 2016 (about six weeks); no-show history is truncated at the start of the period.
- No data on reason for missing, distance to the unit, specialty, or when and how SMS messages were sent.

## Tools

- **MySQL:** data cleaning, transformation, window functions and risk segmentation
- **Excel:** pivot tables and chi-square tests
- **Power BI:** dashboard
- **PowerPoint:** problem structuring (ACERT, hypothesis tree, hypothesis matrix, action plan) and executive presentation
- **GitHub:** documentation and version control

## Project Structure

```
healthcare-appointment-no-show-analysis/
│
├── README.md
│
├── sql/
│   ├── 01_data_cleaning.sql
│   ├── 02_exploratory_analysis.sql
│   └── 03_risk_analysis.sql
│
├── excel/
│   └── chi_square_tests.xlsx
│
├── powerbi/
│   └── healthcare_no_show_dashboard.pbix
│
└── assets/
    ├── 01–05 presentation slides (.png)
    └── dashboard_preview.png
