# Databricks Air Carrier On-Time Performance Analysis Project

## Overview
This project demonstrates the analysis of an open-source data set from the US DOT related to US Air Carrier Performance. Download the data as a pre-zipped file with the recommended columns selected. Data will be transformed in Databricks using the medallion architecture and analyzed using PySpark in Databricks. Analysis will focus on the following data:
- Flight Information:
    - FlightDate: Date of the flight
    - Reporting_Airline: The airline operating the flight
    - Flight_Number_Reporting_Airline: Flight number
    - Tail_Number: Aircraft ID
- Origin & Destination:
    - Origin, Dest: Airport code
    - OriginCityName, DestCityName: City names
    - OriginState, DestState: State codes
- Scheduled vs. Actual Time:
    - CRSDeptTime, DeptTime: Scheduled and actual departure time
    - CRSArrTime, ArrTime: Scheduled and actual arrival time
    - DepDelay, ArrDelay: Delay in departure or arrival (in minutes)
- Cancellations & Diversions:
    - Cancelled: Whether the flight was cancelled (1 = yes, 0 = no)
    - Cancellation Code: Reason for cancellation (e.g. weather, security)
    - Diverted: Whether the flight was diverted
- Delay Cause:
    - CarrierDelay, WeatherDelay, NASDelay, SecurityDelay, LateAircraftDelay

Data Analysis will be broken down into the following phases:
1. Ingestion
    1. Read the main OTP CSV file(s) into the DataFrame.
    1. Read the Airport lookup table into `airports_df`.
    1. Read the Carriers lookup table into `carriers_df`.
1. Data Preparations & Joins
    1. Clean column names.
    1. Join Flights with Carriers.
    1. Join Flights with Airports (Origin & Destination).
1. Aggregations & Analysis
    1. Average Arrival Delay per Carrier.
    1. Cancellation Rate per Carrier and Reason.
    1. Busiest Airports (by Departure).
    1. Most Frequent Routes.
    1. Average Delay by Route.
    1. Airports with No Departure Flights.

Data Sources:
1. [On-Time Performance Report](https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2025_1.zip)
1. [Airport Maps](https://www.transtats.bts.gov/Download_Lookup.asp?Y11x72=Y_NVecbeg)
1. [Carrier Maps](https://www.transtats.bts.gov/Download_Lookup.asp?Y11x72=Y_haVdhR_PNeeVRef)

Technologies Used:
1. Databricks Notebooks
1. Databricks Workflow (for orchestration)
1. Delta Lake (Databricks Data Storage)
1. Unity Catalogs (Databricks Table Metadata Storage)