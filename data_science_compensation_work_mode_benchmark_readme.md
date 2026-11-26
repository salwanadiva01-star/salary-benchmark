# Data Science Compensation & Work Mode Benchmark (2020–2022)

An end-to-end data analytics and business intelligence project exploring global compensation trends, career progression benchmarks, work-mode shifts (Remote, Hybrid, On-site), and geographic salary gaps across Data roles using **MySQL** and **Looker Studio**.

---

## 1. Background and Overview

### Business Context
The rapid expansion of data-driven teams between 2020 and 2022 accelerated by the global shift toward remote work created significant variance in compensation across roles, experience levels, and regions. Without clear market benchmarks, HR teams and hiring managers risk under-offering top talent or misaligning salary bands across domestic and cross-border hires.

### Project Objectives
This project analyzes 3 years of global Data Science compensation data to answer four core business questions:
1. **Compensation Benchmarking & Career Progression**
 How do average salaries scale across experience levels (`Entry` → `Mid` → `Senior` → `Executive`) for core Data roles (*Data Scientist*, *Data Engineer*, *Data Analyst*)?
2. **Market Growth Trends**
How did global data compensation grow year-over-year (YoY) from 2020 to 2022?
3. **Work Policy Impact**
How has the adoption of Full Remote (`100`), Hybrid (`50`), and On-site (`0`) work shifted over time, and which work mode offers higher compensation?
4. **Geographic & Cross-Border Strategy**
What is the compensation gap between employees residing in the same country as their employer (`Same Country`) versus international remote hires (`Cross-Border`)?

### Tech Stack
* **Database & Data Wrangling**
  MySQL (`CTE`, `ROW_NUMBER()`, `LAG()`, Window Functions, Conditional Aggregation)
* **Business Intelligence & Visualization**
  Looker Studio (Interactive KPI Scorecards, Dynamic Filters, Salary Band & Residency Tables)

---

## 2. Data Structure Overview

The raw dataset (`salary.ds_salaries`) was audited, standardized, and deduplicated in MySQL into a clean analytical table (`ds_salaries_clean`) containing **565 unique records** spanning **2020–2022**.

### Data Cleaning Pipeline (`MySQL`)
* **Null & Domain Validation**, Audited all 11 columns for `NULL` values (0 nulls found) and filtered for valid records (`salary_in_usd > 0` and `remote_ratio IN (0, 50, 100)`).
* **Deduplication,** Applied `ROW_NUMBER() OVER (PARTITION BY ...)` across all attributes to identify and remove **42 exact duplicate rows** (reducing the dataset from 607 to **565 clean rows**).
* **String & Label Standardization,** Trimmed whitespace (`TRIM()`) and mapped experience codes (`EN`, `MI`, `SE`, `EX`) into readable labels (`experience_label`).

### Schema Summary (`ds_salaries_clean` — 565 Rows, 12 Columns)

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `work_year` | `INT` | Year the salary was paid (`2020`, `2021`, `2022`). |
| `experience_level` | `VARCHAR` | Experience code (`EN` = Entry, `MI` = Mid, `SE` = Senior, `EX` = Executive). |
| `experience_label` | `VARCHAR` | Standardized label (`Entry-Level/Junior` to `Executive-Level/Director`). |
| `employment_type` | `VARCHAR` | Contract type (`FT` = Full-Time, `PT` = Part-Time, `CT` = Contract, `FL` = Freelance). |
| `job_title` | `VARCHAR` | Standardized role title (e.g., *Data Scientist*, *Data Engineer*, *Data Analyst*). |
| `salary` | `INT` | Gross salary amount in original local currency. |
| `salary_currency` | `VARCHAR` | ISO 4217 currency code (e.g., `USD`, `EUR`, `GBP`). |
| `salary_in_usd` | `INT` | Standardized annual compensation converted to USD (primary metric). |
| `employee_residence` | `VARCHAR` | Employee's primary country of residence (ISO 3166 country code). |
| `remote_ratio` | `INT` | Remote work proportion: `0` (On-site), `50` (Hybrid), `100` (Full Remote). |
| `company_location` | `VARCHAR` | Country of the employer's main office or contracting branch. |
| `company_size` | `VARCHAR` | Organization headcount tier (`S` < 50, `M` 50–250, `L` > 250 employees). |

---

## 3. Executive Summary

* **Accelerating Market Compensation**
Average global data salaries rose from **$95,813** in 2020 to **$99,430** in 2021 (**+3.78% YoY**), before surging to **$123,089** in 2022 (**+23.79% YoY**), driven by heightened demand for senior talent.
* **Senior-Level Career Multiplier**
Moving from Entry-Level (`EN`) to Senior-Level (`SE`) yields more than double the compensation across all core roles led by **Data Scientists (+172.38%)**, followed by **Data Engineers (+129.76%)** and **Data Analysts (+107.49%)**.
* **Full Remote Dominance**
Full Remote (`remote_ratio = 100`) grew from **50.00%** of roles in 2020 to **69.78%** in 2022, while consistently commanding the highest average compensation (**$127,772** in 2022) compared to On-site (**$114,673**) and Hybrid (**$97,876**).
* **Geographic Compensation Gap**
Employees working in the **Same Country** as their employer earn an average of **$113,969**, representing a **+48.48% premium** over **Cross-Border** talent (**$76,758**), reflecting location-adjusted pay structures.

---

## 4. Insights Deep Dive

### A. Role Demand & Career Progression (`EN` → `MI` → `SE`)
Across the 565 records, **Data Scientist** (`130` records, avg `$103,336`), **Data Engineer** (`121` records, avg `$109,750`), and **Data Analyst** (`82` records, avg `$90,090`) represent the highest-demand roles. For Full-Time (`FT`) positions overall, average pay scales sharply from Entry-Level (`$64,457`) to Mid-Level (`$88,203`), Senior-Level (`$138,839`), and Executive/Director (`$190,728`).

| Core Role | Entry (`EN`) Avg | Mid (`MI`) Avg | Senior (`SE`) Avg | Jump `EN → MI` | Jump `MI → SE` | Total Jump `EN → SE` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Data Scientist** | $55,331 | $81,892 | $150,711 | +48.00% | +84.04% | **+172.38%** |
| **Data Engineer** | $58,934 | $83,896 | $135,404 | +42.36% | +61.39% | **+129.76%** |
| **Data Analyst** | $53,961 | $72,188 | $111,964 | +33.78% | +55.10% | **+107.49%** |

* **Key Takeaway:** The sharpest pay inflection occurs during the transition from **Mid-Level to Senior-Level** (+55% to +84%), making senior retention and clear promotion bands critical for HR planning.

### B. Year-over-Year Market Growth & Work Mode Shift (2020–2022)
Using SQL window functions (`LAG()` and `PARTITION BY work_year`), the data reveals both rising sample volume and a structural shift away from Hybrid work toward Full Remote arrangements in 2022:

| Year | Sample (`n`) | Overall Avg Salary | YoY Growth | Full Remote (`100`) Share & Avg | Hybrid (`50`) Share & Avg | On-site (`0`) Share & Avg |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **2020** | 72 | $95,813 | — | 50.00% ($106,694) | 29.17% ($77,591) | 20.83% ($95,210) |
| **2021** | 215 | $99,430 | +3.78% | 53.95% ($113,407) | 30.23% ($78,566) | 15.81% ($91,631) |
| **2022** | 278 | $123,089 | **+23.79%** | **69.78% ($127,772)** | 4.32% ($97,876) | 25.90% ($114,673) |

* **Key Takeaway:** By 2022, nearly **7 out of 10** data positions operated 100% remotely (`194` of `278` roles), and Full Remote roles out-earned On-site roles by **+$13,100** on average.

### C. Geographic Compensation & Cross-Border Strategy
* **Top Compensation Hubs**
Among major markets with strong sample representation, the **United States (`US`)** leads global compensation with an average of **$144,293**, followed by **Canada (`CA`)** at **$100,122**, **Great Britain (`GB`)** at **$81,650**, and **Germany (`DE`)** at **$81,560**. For Entry & Mid-level On-site *Data Analysts*, the **US** (`$87,627`) and **Canada** (`$69,750`) offer the most competitive starting benchmarks.
* **Same Country vs. Cross-Border Gap:**

| Residency Status | Avg Salary (USD) | Min Salary (USD) | Max Salary (USD) |
| :--- | :---: | :---: | :---: |
| **Same Country** (`employee_residence = company_location`) | **$113,969** | $2,859 | $600,000 |
| **Cross-Border** (`employee_residence != company_location`) | **$76,758** | $5,679 | $225,000 |

* **Key Takeaway:** Companies hiring cross-border remote talent realize an average cost difference of **$37,211 per role** compared to domestic hires, highlighting the widespread adoption of regional cost-of-living salary tiers.

---

## Strategic Recommendations

1. **Establish Role- and Level-Specific Salary Bands:** Use the dashboard's `Min–Average–Max` benchmarks per `job_title` and `experience_label` to standardize offer letters and budget proactively for Mid-to-Senior transitions.
2. **Maintain Remote-First Hiring Flexibility:** With **69.78%** of 2022 roles operating fully remote, offering remote flexibility remains essential to attract competitive Senior Data Engineers and Data Scientists.
3. **Formalize Transparent Cross-Border Pay Tiers:** Define clear geographic compensation tiers for international remote hires so offers remain locally competitive while maintaining internal pay equity.
