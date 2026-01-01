# Hospital_Patient_Visit-Billing-System

Project Overview

This project is a Hospital Patient & Billing Management System built using MySQL.
It demonstrates real-world SQL concepts such as data cleaning, aggregations, subqueries, window functions, views, stored procedures, and triggers applied to hospital visit and billing data.

The project simulates how hospitals analyze revenue, track patient visits, monitor doctor performance, and maintain billing accuracy.

 Database Table Used

Table Name: hospital_visits

Key Columns:

visit_id

patient_id

patient_name

age

doctor_name

department

visit_type

visit_date

diagnosis_description

billing_amount

paid_amount

payment_method

follow_up_flag

 Data Cleaning & Data Manipulation

Increased paid_amount by 5% for insurance payments

Set age = NULL where age is less than 1

Deleted records with billing_amount = 0

Removed manually marked invalid patient records

📊 Business Analysis Queries
🔹 Revenue Analysis

Total revenue

Paid revenue

Outstanding revenue

Revenue by doctor

Revenue by department

Monthly revenue trend

🔹 Patient Analysis

Top 10 patients by total spending

Patients with visit count above average

High-value patients (billing > 2000)

🔹 Visit Analysis

Average billing per visit type

Count of visits requiring follow-up

 Advanced SQL Features Used
 Subqueries

Patients with visits above average

Visits with billing higher than patient's average

Doctors earning above average revenue

 Window Functions

Running total of daily revenue

Ranking doctors by revenue

Previous & next day revenue using LAG() and LEAD()

Views Created

monthly_billing – Monthly revenue summary

Doctor_Perf – Doctor performance metrics

High_Value_Patients – Patients with high billing amounts

 Stored Procedures

settle_pmt

Adds payment amount for a specific visit

followup

Marks a visit as requiring follow-up

Triggers

Billing Update Audit Trigger

Logs changes made to billing amounts into an audit table

Outstanding Amount Trigger

Automatically calculates outstanding amount before inserting a visit record
