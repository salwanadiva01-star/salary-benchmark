#Cleansing
#1. cek apakah ada null atau tidak
Select * 
from salary.ds_salaries 
where 
work_year is null or 
experience_level is null or 
employment_type is null OR
job_title is null OR
salary is null or
salary_currency is null OR
salary_in_usd is null OR
employee_residence is NULL OR
remote_ratio is null OR
company_location is null OR
company_size is NULL;

#2. Cek baris duplikat
SELECT
    work_year,
    experience_level,
    employment_type,
    job_title,
    salary,
    salary_currency,
    salary_in_usd,
    employee_residence,
    remote_ratio,
    company_location,
    company_size,
    COUNT(*) AS jumlah_muncul
FROM salary.ds_salaries
GROUP BY
    work_year,
    experience_level,
    employment_type,
    job_title,
    salary,
    salary_currency,
    salary_in_usd,
    employee_residence,
    remote_ratio,
    company_location,
    company_size
HAVING COUNT(*) > 1;

#3. Create table
Create table ds_salaries_clean AS
with ranked_salaries as (
  SELECT
    work_year,
    TRIM(experience_level) experience_level,
    TRIM(employment_type) employment_type,
    TRIM(job_title) job_title,
    salary,
    Trim(salary_currency) as salary_currency,
    salary_in_usd,
    TRIM(employee_residence) employee_residence,
    remote_ratio,
    trim(company_location) company_location,
    TRIM(company_size) company_size,
  	ROW_NUMBER () 
  	OVER( PARTITION BY
          work_year,
          experience_level,
          employment_type,
          job_title,
          salary,
          salary_currency,
          salary_in_usd,
          employee_residence,
          remote_ratio,
          company_location,
          company_size
         ORDER BY salary_in_usd DESC, work_year DESC) as rn
  from salary.ds_salaries
  where salary_in_usd > 0 and remote_ratio in (0,50,100))
  
  select
    work_year,
    experience_level,
    case experience_level #UBAH INISIAL JADI KATA YG JELAS
    	when 'EN' then 'Entry-Level/Junior'
        when 'MI' THEN 'Mid-Level/Intermediate'
        When 'SE' THEN 'Senior-Level'
        When 'EX' THEN 'Excecutive-Level/Director'
        else 'Experience-Level'
        end as experience_label,
    employment_type,
    job_title,
    salary,
    salary_currency,
    salary_in_usd,
    employee_residence,
    remote_ratio,
    company_location,
    company_size
from ranked_salaries
WHERE rn = 1;

# A. Patokan Gaji & Jenjang Karier (Compensation Benchmarking)
-- 1. Berapa rata-rata gaji data analyst berdasarkan experience level dan jenis employment?
select avg(salary_in_usd) as average_salary, employment_type, experience_level 
from ds_salaries_clean 
where job_title like '%data analyst%'
group by employment_type, experience_level
order by employment_type, experience_level;
-- 2. Berapa rata-rata dan median gaji (salary_in_usd) per jenjang pengalaman (experience_label) untuk posisi full-time (FT)?
select avg(salary_in_usd) as avgsal, experience_label
from ds_salaries_clean
where employment_type = 'FT'
group by experience_label;
-- 3. Posisi (job_title) mana di bidang Data yang menawarkan kompensasi tertinggi dan mana yang paling banyak permintaannya (jumlah data terbanyak)?
SELECT
    job_title,
    AVG(salary_in_usd) AS avgsal,
    COUNT(job_title) AS banyak
FROM ds_salaries_clean
GROUP BY job_title
ORDER BY banyak desc;

-- 4. Berapa lonjakan persentase kenaikan gaji dari Entry-Level → Mid-Level → Senior-Level pada peran utama (seperti Data Analyst, Data Scientist, dan Data Engineer)?
with ds_1 as (
select 
	job_title,
	avg(case when experience_level = 'EN' THEN salary_in_usd end) as avg_en,
    avg(case when experience_level = 'MI' THEN salary_in_usd end) as avg_mi,
    avg(case when experience_level = 'SE' THEN salary_in_usd end) as avg_se
FROM ds_salaries_clean
WHERE job_title in ('Data Analyst', 'Data Scientist', 'Data Engineer')
group by job_title)

select
job_title,
round(avg_en,2) as avg_en,
round(avg_mi,2) as avg_mi,
round(avg_se,2) as avg_se,
round(((avg_mi-avg_en)/avg_en)*100,2) as percentage_en_to_mi,
round(((avg_se-avg_mi)/avg_mi)*100,2) as percentage_mi_to_se,
round(((avg_se-avg_en)/avg_en)*100,2) as percentage_en_to_se
from ds_1
order by percentage_en_to_se desc;

# B. Tren Pasar & Kebijakan Kerja (Work Mode & Growth)
-- 1. Bagaimana tren pertumbuhan gaji pasar data dari tahun 2020 hingga 2022?
with yearly_salary as
(select
	work_year,
    count(*) as jumlah_data,
    avg(salary_in_usd) as avg_sal
from
	ds_salaries_clean
group by work_year)

select
work_year,
jumlah_data,
avg_sal,
lag(avg_sal)over(order by work_year) as prev_year_avg,
((avg_sal-lag(avg_sal)over(order by work_year))/lag(avg_sal)over(order by work_year))*100 as yoy_growth
from yearly_salary
group by work_year;
-- 2. Apakah skema kerja Full Remote (100), Hybrid (50), atau On-site (0) memberikan kompensasi lebih tinggi—dan bagaimana pergeseran trennya dari tahun ke tahun?
select
work_year,
remote_ratio,
case remote_ratio
	when 0 then 'Full-Time'
    when 50 then 'Hybrid'
    when 100 then 'Remote'
end as work_mode,
COUNT(*) AS jumlah_data,
(COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (PARTITION BY work_year) AS share_pct_in_year,
AVG(salary_in_usd) AS avg_salary_usd
FROM ds_salaries_clean
GROUP BY
    work_year,
    remote_ratio
ORDER BY
    work_year,
    share_pct_in_year;

#3. Di tahun berapa, kenaikan gaji dari mid ke senior itu memiliki kenaikan yang tertinggi? (untuk pekerjaan yang penuh waktu)
with midsal as (
	select 
		avg(salary_in_usd) as avgmidsal,
		work_year
    from 
		ds_salaries_clean
	where
		job_title like '%data analyst%' and
        experience_level = 'MI'
	group by work_year),
    sensal as (
	select 
		avg(salary_in_usd) as avgsensal,
		work_year
    from 
		ds_salaries_clean
	where
        experience_level = 'SE'
	group by work_year),
    t_year as (
    select DISTINCT 
		work_year
	from ds_salaries_clean)
    
    select
		t_year.work_year,
        midsal.avgmidsal,
        sensal.avgsensal,
		abs(midsal.avgmidsal - sensal.avgsensal) as difference
	from 
    t_year
    left join midsal on midsal.work_year = t_year.work_year
    left join sensal on sensal.work_year = t_year.work_year
    order by difference desc;

#C. Geografi & Skala Perusahaan (Location & Company Size Strategy)
-- 1.Negara dengan gaji yang menarik untuk posisi data analyst, exp kerjanya entry level dan menengah / mid
select company_location, avg(salary_in_usd) as average_salary
from ds_salaries_clean
where job_title like '%data analyst%' and remote_ratio = '0' and experience_label in ('Mid-Level/Intermediate', 'Entry-Level/Junior')
group by company_location
order by average_salary desc;

-- 2.Negara mana (company_location) yang menjadi pusat dengan kompensasi tertinggi (minimal memiliki 10 sampel agar tidak bias)?
select company_location, avg(salary_in_usd) as average_salary
from ds_salaries_clean
group by company_location
order by average_salary desc;

-- 3. Apakah terdapat perbedaan gaji antara karyawan yang tinggal di negara yang sama dengan lokasi perusahaan (employee_residence = company_location) dibandingkan talenta lintas negara (cross-border remote)?
select
case when employee_residence = company_location then 'Same country'
else 'cross-border' end as residency_status,
avg(salary_in_usd) as avgsal,
min(salary_in_usd) as minsal,
max(salary_in_usd) as maxsal
from ds_salaries_clean
group by case when employee_residence = company_location then 'Same country'
else 'cross-border' end
order by avgsal desc;
