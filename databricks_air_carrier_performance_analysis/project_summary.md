# Databricks Air Carrier On-Time Performance Analysis Project Summary

## AWS Marketplace
- Subscribe to Databricks Data Intelligence Platform. While the subscription request is in progress, set up the account:
    - Enable AWS Marketplace deployment integration.
    - Create a databricks account to access the 14-day $400 free trial.
        - Email: francis.snowboard@gmail.com
        - AWS Region: us-east-1
    - Leave all other settings as default and create the account.
    - When the account is created, a workspace may automatically be created, which will create a corresponding stack in CloudFormation. If this doesn't occur, create the workspace manually.
    - Verify the workspace belongs to the previously created account, under Users.
    - Create a new compute cluster with minimal compute power to minimize costs:
        - Choose the Shared Compute Policy.
        - Disable Photon Acceleration.
        - Choose the m5d.large worker type under the General Purpose category.
        - Choose to terminate the worker after 10 minutes of inactivity.
- Verify the previously created compute cluster works by creating a new notebook and running the following SQL query: `select * from samples.tpch.customer limit 10;`. Here, `samples` is a catalog, `tpch` is a schema, and `customer` is a table. All of these artifacts are automatically created with the workspace.
- To prevent incurring ongoing costs from the Databricks subscription, delete the following resources once they are no longer needed:
    - CloudFormation Stack
    - EC2 Elastic IP
    - S3 Bucket
    - AWS Marketplace Subscription

## Databricks
- Create a new managed volume in the AWS-managed Databricks workspace and the default schema for that workspace.
- Create a Python notebook to perform the source extraction. Use the following code in the notebook:
    ```
    # Shows available LSB modules, as well as the current version of Ubuntu being used in the notebook.
    !lsb_release -a

    # Displays all folders present in the workspace at the root level.
    %fs ls

    # Import necessary python libraries
    from pyspark.sql.functions import *
    from pyspark.sql.types import *
    import requests
    import zipfile
    import os
    import pandas as pd
    from datetime import datetime

    # Create dictionary of required datasets
    source_data = {
        "On_Time_performance_Report_URL" : f"https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2025_1.zip",

        "Airports_Maps": "https://www.transtats.bts.gov/Download_Lookup.asp?Y11x72=Y_NVecbeg",
        
        "Carriers_Maps": "https://www.transtats.bts.gov/Download_Lookup.asp?Y11x72=Y_haVdhR_PNeeVRef"
    }

    # Define a method to download ZIP files from above dictionary
    def download_zip(url, output_path):
        response = requests.get(url, stream=True)
        response.raise_for_status()  # Raise error for bad status
        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"Download complete; File in path {output_path}")

    # Define a function to extract the content from the zip files and save them in another directory
    def extract_zip(zip_path, extract_to):
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to)
        print(f"Extraction complete; File in path {extract_to}")

    # Define a function to find csv files in the content extracted from the zip files
    def find_csv_file(directory):
        for file in os.listdir(directory):
            if file.endswith('.csv'):
                return os.path.join(directory, file)
        return None

    # Use a for loop to download the zip files from the dictionary and extract their contents
    # Download links not working in Databricks workspace. Needed to manually upload CSV files to the previously created volume.
    data_path = "/Volumes/workspace_7474650202943341/default/air_carrier_sample_dataset/"

    for source, url in source_data.items():
        print(f"Processing {source}...")
        ZIP_URL = url
        ZIP_FILE = data_path + source + ".zip"; os.makedirs(os.path.dirname(ZIP_FILE), exist_ok=True)
        EXTRACT_DIR = data_path + source + "/"

        download_zip(ZIP_URL, ZIP_FILE)
        try:
            extract_zip(ZIP_FILE, EXTRACT_DIR)
            csv_file = find_csv_file(EXTRACT_DIR)

        # print(csv_file)
        except zipfile.BadZipFile:
            print(f"Error: File is not a zip file.", e, EXTRACT_DIR)
            csv_file = ZIP_FILE
        if csv_file:
            print(f"reading  file from {csv_file}")
            pyspark_df = spark.read.csv(csv_file, header=True, inferSchema=True)
            pyspark_df.write.mode(write_mode).saveAsTable(f"workspace.default.{source}")
        else:
            print("No CSV file found in the extracted ZIP.")

    # Alternate code used to fix the above issue. Manually uploaded zip files to the volume.
    # Encountered metadata mismatch error and could not create tables
    table_data = {
        "On_Time_performance_Report": "On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_2025_1.csv",
        "Airports_Maps": "L_AIRPORT.csv",
        "Carriers_Maps": "L_UNIQUE_CARRIERS.csv"
    }

    def find_csv_file(directory):
        for table_name, file_name in table_data.items():
            file_path = os.path.join(directory, file_name)
            pyspark_df = spark.read.csv(file_path, header=True, inferSchema=True)
            try:
                pyspark_df.write.mode("append").saveAsTable(table_name)
            except Exception as e:
                print(f"Error saving table {table_name} for file {file_path}: {e}")
        return None
    
    data_path = "/Volumes/workspace_7474650202943341/default/air_carrier_sample_dataset/"
    find_csv_file(data_path)
    ```
- Now that the data has been extracted from the source, it can be curated. Create a separate Python notebook to perform the curation using the following code:
    ```
    # import necessary python libraries
    from pyspark.sql import functions as F
    from pyspark.sql.types import *
    from pyspark.sql.functions import element_at

    # Use the tables created during source extraction to create data frames
    flights_df = spark.table('workspace_7474650202943341.default.on_time_performance_report')
    carriers_df = spark.table('workspace_7474650202943341.default.carriers_maps')
    airports_df = spark.table('workspace_7474650202943341.default.airports_maps')

    # Select the columns from flights_df that are needed for analysis
    columns_to_keep = [
        "FlightDate", "Reporting_Airline", "Tail_Number", "Flight_Number_Reporting_Airline",
        "Origin", "OriginCityName", "OriginState",
        "Dest", "DestCityName", "DestState",
        "CRSDepTime", "DepTime", "DepDelay", "DepDelayMinutes", "DepDel15", "DepTimeBlk",
        "TaxiOut", "WheelsOff", "WheelsOn", "TaxiIn", # For operational efficiency
        "CRSArrTime", "ArrTime", "ArrDelay", "ArrDelayMinutes", "ArrDel15", "ArrTimeBlk",
        "Cancelled", "CancellationCode", "Diverted",
        "CRSElapsedTime", "ActualElapsedTime", "AirTime", # For operational efficiency
        "CarrierDelay", "WeatherDelay", "NASDelay", "SecurityDelay", "LateAircraftDelay",
        "Year", "Month", "DayofMonth", "DayOfWeek"
    ]

    flights_selected_df = flights_df.select(*columns_to_keep) # Selects all of the columns in the list from the data frame.

    # Rename the columns from flights_selected_df (using snake case convention)
    flights_renamed_df = flights_selected_df \
        .withColumnRenamed("FlightDate", "flight_date") \
        .withColumnRenamed("Reporting_Airline", "carrier_code") \
        .withColumnRenamed("Origin", "origin_code") \
        .withColumnRenamed("Dest", "dest_code") \
        .withColumnRenamed("ArrDelayMinutes", "arr_delay_mins") \
        .withColumnRenamed("DepDelayMinutes", "dep_delay_mins") \
        .withColumnRenamed("Cancelled", "cancelled") \
        .withColumnRenamed("Diverted", "diverted") \
        .withColumnRenamed("CRSElapsedTime", "crs_elapsed_time") \
        .withColumnRenamed("ActualElapsedTime", "actual_elapsed_time") \
        .withColumnRenamed("AirTime", "air_time") \
        .withColumnRenamed("TaxiOut", "taxi_out") \
        .withColumnRenamed("TaxiIn", "taxi_in") \
        .withColumnRenamed("CarrierDelay", "carrier_delay") \
        .withColumnRenamed("WeatherDelay", "weather_delay") \
        .withColumnRenamed("NASDelay", "nas_delay") \
        .withColumnRenamed("SecurityDelay", "security_delay") \
        .withColumnRenamed("LateAircraftDelay", "late_aircraft_delay")

    # Cast the columns from flights_renamed_df to the appropriate data type
    flights_casted_df = flights_renamed_df \
        .withColumn("flight_date", F.to_date(F.col("flight_date"))) \
        .withColumn("arr_delay_mins", F.col("arr_delay_mins").cast(DoubleType())) \
        .withColumn("dep_delay_mins", F.col("dep_delay_mins").cast(DoubleType())) \
        .withColumn("cancelled", F.col("cancelled").cast(IntegerType())) \
        .withColumn("diverted", F.col("diverted").cast(IntegerType())) \
        .withColumn("DepDel15", F.col("DepDel15").cast(IntegerType())) \
        .withColumn("ArrDel15", F.col("ArrDel15").cast(IntegerType())) \
        .withColumn("crs_elapsed_time", F.col("crs_elapsed_time").cast(DoubleType())) \
        .withColumn("actual_elapsed_time", F.col("actual_elapsed_time").cast(DoubleType())) \
        .withColumn("air_time", F.col("air_time").cast(DoubleType())) \
        .withColumn("taxi_out", F.col("taxi_out").cast(DoubleType())) \
        .withColumn("taxi_in", F.col("taxi_in").cast(DoubleType())) \
        .withColumn("carrier_delay", F.col("carrier_delay").cast(DoubleType())) \
        .withColumn("weather_delay", F.col("weather_delay").cast(DoubleType())) \
        .withColumn("nas_delay", F.col("nas_delay").cast(DoubleType())) \
        .withColumn("security_delay", F.col("security_delay").cast(DoubleType())) \
        .withColumn("late_aircraft_delay", F.col("late_aircraft_delay").cast(DoubleType()))

    # Select numeric columns that should not be null
    numeric_cols_to_fill = [
        "carrier_delay", "weather_delay", "nas_delay", "security_delay", "late_aircraft_delay",
        "taxi_out", "taxi_in", "air_time", "actual_elapsed_time", "crs_elapsed_time",
        "arr_delay_mins", "dep_delay_mins" 
    ]

    # Fill columns only if 0 makes sense contextually
    flights_final_df = flights_casted_df.na.fill(0, subset=numeric_cols_to_fill)

    # Cache the final data frame for efficiency purposes (not supported on serverless compute)
    flights_final_df.cache()

    # Prepare lookup tables for airports and carriers
    airports_df = airports_df \
        .withColumn('city', F.try_element_at(F.split(F.col('Description'), ": "), F.lit(1))) \
        .withColumn('airport_full_name', F.try_element_at(F.split(F.col('Description'), ": "), F.lit(2)))

    airports_lookup = airports_df.select(
        F.col("Code").alias("airport_code"),
        F.col("city").alias("airport_city"),
        F.col("airport_full_name")
    ).distinct()

    carriers_lookup = carriers_df.select(
        F.col("Code").alias("carrier_code_lookup"),
        F.col("Description").alias("carrier_name")
    ).distinct()

    # Join flight data with carrier data based on carrier lookup code
    base_join = flights_final_df \
        .join(carriers_lookup, flights_final_df.carrier_code == carriers_lookup.carrier_code_lookup, "left")

    # Join the base_join with origin airport lookup data
    origin_join = base_join \
        .join(airports_lookup.alias("origin_apt"), base_join.origin_code == F.col("origin_apt.airport_code"), "left") \
        .select(base_join["*"], carriers_lookup["carrier_name"],
                F.col("origin_apt.airport_full_name").alias("origin_airport_name"),
                F.col("origin_apt.airport_city").alias("origin_city_code"))

    # Join the origin_join with the destination airport lookup data
    full_flight_data = origin_join \
        .join(airports_lookup.alias("dest_apt"), origin_join.dest_code == F.col("dest_apt.airport_code"), "left") \
        .select(origin_join["*"], # Select all from previous join
                F.col("dest_apt.airport_full_name").alias("dest_airport_name"),
                F.col("dest_apt.airport_city").alias("dest_state_code"))

    # Select and potentially rename final columns for clarity
    # (Example selecting a subset, adjust as needed)
    full_flight_data = full_flight_data.select(
            "flight_date", "Year", "Month", "DayofMonth", "DayOfWeek",
            "carrier_code", "carrier_name",
            "Tail_Number", "Flight_Number_Reporting_Airline",
            "origin_code", "origin_airport_name", "origin_city_code",
            "dest_code", "dest_airport_name", "dest_state_code",
            "DepTimeBlk", "ArrTimeBlk",
            "dep_delay_mins", "DepDel15",
            "arr_delay_mins", "ArrDel15",
            "cancelled", "diverted", "CancellationCode",
            "carrier_delay", "weather_delay", "nas_delay", "security_delay", "late_aircraft_delay",
            "taxi_out", "taxi_in", "air_time", "actual_elapsed_time", "crs_elapsed_time")

    full_flight_data.write.mode("append").saveAsTable("full_flight_data")

    # Create a new schema for silver layer and store the full_flight_data there
    create schema if not exists workspace_7474650202943341.silver
    full_flight_data.write.mode("overwrite").saveAsTable("workspace_7474650202943341.silver.full_flight_data") # "overwrite" mode is used for creating the table. "append" mode is used for modifying the existing table.
    ```
- Now that the data has been curated (cleaned and transformed), it can be analyzed. Create a separate Python notebook to perform the analysis using the following code:
    ```
    # Import necessary python libraries
    from pyspark.sql import functions as F
    from pyspark.sql.types import *

    # Load the full_flight_data table
    full_flight_data = spark.table("workspace_7474650202943341.silver.full_flight_data")

    # Overall delay metrics analysis
    overall_metrics = full_flight_data \
        .filter(F.col("cancelled") == 0) \
        .agg(
            F.avg("arr_delay_mins").alias("average_arrival_delay"),
            F.avg("dep_delay_mins").alias("average_departure_delay"),
            (F.sum(F.when(F.col("ArrDel15") > 0, 1).otherwise(0)) / F.count("*") * 100).alias("percentage_arrivals_delayed_15min"),
            (F.sum(F.when(F.col("DepDel15") > 0, 1).otherwise(0)) / F.count("*") * 100).alias("percentage_departure_delayed_15min")
        )

    overall_metrics.display()

    # Delay metrics by carrier
    delay_by_carrier = full_flight_data \
        .filter(F.col("cancelled") == 0) \
        .groupBy("carrier_name") \
        .agg(
            F.avg("arr_delay_mins").alias("avg_arrival_delay"),
            (F.sum(F.when(F.col("ArrDel15") > 0, 1).otherwise(0)) / F.count("*") * 100).alias("percentage_arrivals_delayed"),
            F.count("*").alias("total_flights")
        ).filter(F.col("carrier_name").isNotNull()).orderBy(F.desc("avg_arrival_delay"))

    delay_by_carrier.orderBy(F.col('avg_arrival_delay').desc(), F.col('percentage_arrivals_delayed').desc()).display()

    # Delay metrics by origin airport
    delay_by_origin_airport = full_flight_data \
        .filter(F.col("cancelled") == 0) \
        .groupBy("origin_airport_name") \
        .agg(
            F.avg("dep_delay_mins").alias("avg_departure_delay"),
            (F.sum(F.when(F.col("DepDel15") > 0, 1).otherwise(0)) / F.count("*") * 100).alias("percentage_departures_delayed"),
            F.count("*").alias("total_departing_flights")
        ).filter(F.col("origin_airport_name").isNotNull()).orderBy(F.desc("avg_departure_delay"))

    delay_by_origin_airport.display()

    # Delay metrics by route
    delay_by_route = full_flight_data \
        .filter(F.col("cancelled") == 0) \
        .groupBy("origin_airport_name", "dest_airport_name") \
        .agg(F.avg("arr_delay_mins").alias("avg_arrival_delay"), F.count("*").alias("total_flights")) \
        .filter(F.col("origin_airport_name").isNotNull() & F.col("dest_airport_name").isNotNull()) \
        .orderBy(F.desc("avg_arrival_delay"))

    delay_by_route.display()

    # Delay cause analysis
    delay_cause_summary = full_flight_data \
    .filter((F.col("cancelled") == 0) & (F.col("arr_delay_mins") > 0)) \
    .agg(
        F.avg("carrier_delay").alias("avg_carrier_delay"), F.sum("carrier_delay").alias("total_carrier_delay"),
        F.avg("weather_delay").alias("avg_weather_delay"), F.sum("weather_delay").alias("total_weather_delay"),
        F.avg("nas_delay").alias("avg_nas_delay"), F.sum("nas_delay").alias("total_nas_delay"),
        F.avg("security_delay").alias("avg_security_delay"), F.sum("security_delay").alias("total_security_delay"),
        F.avg("late_aircraft_delay").alias("avg_late_aircraft_delay"), F.sum("late_aircraft_delay").alias("total_late_aircraft_delay")
    )

    delay_cause_summary = delay_cause_summary.withColumn("total_delay_sum", F.col("total_carrier_delay") + F.col("total_weather_delay") + F.col("total_nas_delay") + F.col("total_security_delay") + F.col("total_late_aircraft_delay"))

    delay_cause_summary = delay_cause_summary.select("*",
        (F.when(F.col("total_delay_sum") > 0, (F.col("total_carrier_delay") / F.col("total_delay_sum")) * 100).otherwise(0)).alias("percent_carrier"),
        (F.when(F.col("total_delay_sum") > 0, (F.col("total_weather_delay") / F.col("total_delay_sum")) * 100).otherwise(0)).alias("percent_weather"),
        (F.when(F.col("total_delay_sum") > 0, (F.col("total_nas_delay") / F.col("total_delay_sum")) * 100).otherwise(0)).alias("percent_nas"),
        (F.when(F.col("total_delay_sum") > 0, (F.col("total_security_delay") / F.col("total_delay_sum")) * 100).otherwise(0)).alias("percent_security"),
        (F.when(F.col("total_delay_sum") > 0, (F.col("total_late_aircraft_delay") / F.col("total_delay_sum")) * 100).otherwise(0)).alias("percent_late_aircraft")
    )

    delay_cause_summary.display()

    # Cancellation reason analysis
    cancel_code_mapping = spark.createDataFrame([
            ('A', 'Carrier'), ('B', 'Weather'), ('C', 'NAS'), ('D', 'Security')
        ], ["CancellationCode", "ReasonDescription"])

    cancellation_reasons = full_flight_data \
        .filter(F.col("cancelled") == 1) \
        .groupBy("CancellationCode") \
        .agg(F.count("*").alias("cancellation_count")) \
        .join(cancel_code_mapping, "CancellationCode", "left") \
        .orderBy(F.desc("cancellation_count"))

    cancellation_reasons.display()

    # Cancellation rate by carrier
    cancellation_rate_carrier = full_flight_data \
        .groupBy("carrier_name") \
        .agg((F.sum("cancelled") / F.count("*") * 100).alias("cancellation_rate_percent")) \
        .filter(F.col("carrier_name").isNotNull()) \
        .orderBy(F.desc("cancellation_rate_percent"))

    cancellation_rate_carrier.display()

    # Cancellation rate by route
    cancellation_rate_route = (full_flight_data 
    .groupBy("origin_airport_name", "dest_airport_name") 
    .agg((F.sum("cancelled") / F.count("*") * 100).alias("cancellation_rate_percent"), F.count("*").alias("total_flights")) 
    .filter(F.col("origin_airport_name").isNotNull() & F.col("dest_airport_name").isNotNull()) 
    .filter(F.col("total_flights") > 50) # Optional: Filter for routes with significant traffic
    .orderBy(F.desc("cancellation_rate_percent")))
            
    cancellation_rate_route.display()

    # Operational efficiency analysis
    valid_efficiency_flights = full_flight_data \
        .filter((F.col("cancelled") == 0) & (F.col("diverted") == 0)) \
        .filter(F.col("taxi_out").isNotNull() & F.col("taxi_in").isNotNull() & \
                F.col("air_time").isNotNull() & F.col("actual_elapsed_time").isNotNull() & \
                F.col("crs_elapsed_time").isNotNull())

    valid_efficiency_flights.display()

    # Taxi-out time analysis
    avg_taxi_out = valid_efficiency_flights \
        .groupBy("origin_airport_name") \
        .agg(F.avg("taxi_out").alias("avg_taxi_out_time")) \
        .filter(F.col("origin_airport_name").isNotNull()) \
        .orderBy(F.desc("avg_taxi_out_time"))

    avg_taxi_out.display()

    # Taxi-in time analysis
    avg_taxi_in = valid_efficiency_flights \
        .groupBy("dest_airport_name") \
        .agg(F.avg("taxi_in").alias("avg_taxi_in_time")) \
        .filter(F.col("dest_airport_name").isNotNull()) \
        .orderBy(F.desc("avg_taxi_in_time"))

    avg_taxi_in.display()

    # Average air time in minutes
    efficiency = valid_efficiency_flights \
        .groupBy("carrier_name", "origin_airport_name", "dest_airport_name") \
        .agg(
            F.avg("air_time").alias("avg_air_time_mins"),
            F.count("*").alias("total_flights")
            ) \
        .filter(F.col("total_flights") > 30) \
        .orderBy(F.desc("avg_air_time_mins"))

    efficiency.display()

    # Ground time analysis
    ground_time_analysis = valid_efficiency_flights \
        .withColumn("ground_time", F.col("actual_elapsed_time") - F.col("air_time")) \
        .groupBy("carrier_name", "origin_airport_name", "dest_airport_name") \
        .agg(F.avg("ground_time").alias("avg_ground_time_mins"), F.count("*").alias("total_flights")) \
        .filter(F.col("total_flights") > 30) \
        .orderBy(F.desc("avg_ground_time_mins"))

    ground_time_analysis.display()

    # Defines a common granularity across all tables
    key_cols = ["carrier_name", "origin_airport_name", "dest_airport_name"]

    # Delay by route
    delay_by_route = full_flight_data.filter(F.col("cancelled") == 0) \
        .groupBy(*key_cols) \
        .agg(
            F.avg("arr_delay_mins").alias("avg_arrival_delay"),
            F.count("*").alias("total_flights"),
            F.sum(F.when(F.col("ArrDel15") > 0, 1).otherwise(0)).alias("num_arr_delayed")
        )

    # Cancellation by route
    cancellation_rate_route = full_flight_data.groupBy(*key_cols) \
        .agg(
            F.sum("cancelled").alias("cancelled_flights"),
            F.count("*").alias("total_flights_cancel")
        ).withColumn("cancellation_rate", F.col("cancelled_flights") / F.col("total_flights_cancel") * 100)

    # Efficiency - padding
    efficiency_padding = full_flight_data.filter((F.col("cancelled") == 0) & (F.col("diverted") == 0)) \
        .withColumn("flight_time_padding", F.col("actual_elapsed_time") - F.col("crs_elapsed_time")) \
        .groupBy(*key_cols) \
        .agg(
            F.avg("flight_time_padding").alias("avg_padding_mins"),
            F.avg("air_time").alias("avg_air_time_mins")
        )

    # Efficiency - ground time
    ground_time = full_flight_data.filter((F.col("cancelled") == 0) & (F.col("diverted") == 0)) \
        .withColumn("ground_time", F.col("actual_elapsed_time") - F.col("air_time")) \
        .groupBy(*key_cols) \
        .agg(F.avg("ground_time").alias("avg_ground_time"))

    # Join all metrics
    final_dashboard_table = delay_by_route \
        .join(cancellation_rate_route, key_cols, "outer") \
        .join(efficiency_padding, key_cols, "outer") \
        .join(ground_time, key_cols, "outer")

    # Create gold schema and save dashboard
    create schema if not exists workspace_7474650202943341.gold
    final_dashboard_table.write.mode("overwrite").saveAsTable("workspace_7474650202943341.gold.final_dashboard_table")
    final_dashboard_table.display()
    ```

## Workflow Orchestration
- Modify the source extraction code to download air carrier data dynamically based on the year and month:
    ```
    current_date = dbutils.widgets.get("current_date") #YYYY-MM-DD
    write_mode = dbutils.widgets.get("mode") #YYYY-MM-DD

    run_date_dt = datetime.strptime(current_date, "%Y-%m-%d")

    year_month = run_date_dt.strftime("%Y_%m") #YYYY_MM

    source_data = {
        "On_Time_performance_Report_URL" : f"https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_{year_month}.zip",

        "Airports_Maps": "https://www.transtats.bts.gov/Download_Lookup.asp?Y11x72=Y_NVecbeg",
        
        "Carriers_Maps": "https://www.transtats.bts.gov/Download_Lookup.asp?Y11x72=Y_haVdhR_PNeeVRef"
    }
    ```
- Once the code is updated, create a job to perform the carrier analysis on a regular basis. Create a source extraction task for this job under the Workflows section of the databricks UI:
    - Choose Notebook as the type.
    - Choose the current workspace where the data is stored.
    - Choose the previously created source_extraction notebook.
    - Choose the serverless compute.
    - Add parameters in the form of key-value pairs as follows:
        - current_date: {{current_date}}
        - mode: append
- Add a dependent curation task to the previously created source extraction task. Use the same settings as before. No parameters are needed for this task.
- Add one more dependent analysis task to the previously created curation task. Use the same settings as before. No parameters are needed for this task.
- Add a trigger to the job that will allow it to run automatically once a month, in order to extract, curate, and analyze new data as it is uploaded to the source.