# Wiki Data Analysis Project Summary

## Databricks
- Using the same AWS-managed Databricks subscription created for the Air Carrier On-Time Performance Analysis project, create a notebook for data ingestion:
    ```
    # Install packages necessary to stream data from the wiki data API
    pip install sseclient-py
    dbutils.library.restartPython()

    # Import libraries needed to perform the data extraction
    import json
    import pandas as pd
    import requests
    import sseclient # from sseclient-py
    from datetime import datetime
    from pyspark.sql import functions as F
    from pyspark.sql.types import *

    # Define the url and headers needed to stream recent changes from the wiki data API
    url = "https://stream.wikimedia.org/v2/stream/recentchange"
    headers = {
        'Accept': 'text/event-stream',
        "User-Agent": "WikiStreamDemo/1.0 (sakthivelooty@gmail.com)"
    }

    # Call the API and load the data in batches as JSON
    batch = []
    print("Listening to Wikidata changes...")
    response = requests.get(url, stream=True, headers=headers)
    response.raise_for_status()
    client = sseclient.SSEClient(response.raw)

    for event in client.events():
        if event.event == 'message':
            data = json.loads(event.data.replace('\\n', '')) 
            if data.get('wiki') == 'wikidatawiki':
                batch.append(data)
        if len(batch) >= 100:
            pdf = pd.DataFrame(batch)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f'/Volumes/workspace/default/external_datasets/wiki_data_1/wikidata_batch_{timestamp}.json' # Replace with your own volume.
            # Save DataFrame as JSON
            pdf.to_json(filename, orient='records', lines=True)
            print("Updated table with data")
            batch = [] # For loop runs continuously, the process must be stopped manually in the notebook.
    ```
    - The volume for `filename` was replaced with `f'/Volumes/workspace_7474650202943341/default/external_datasets/wiki_data/wiki_data_batch_{timestamp}.json'`. This was done by creating an `external_datasets` volume in the `workspace_7474650202943341` workspace, then creating a `wiki_data` in that volume.
    - When the for loop is executed, you will see `Updated table with data` in the cell output for each iteration. This saves the event data to the volume, then creates a data frame with it.
- Create a separate notebook to incrementally load the files streamed from the wiki into a data frame:
    ```
    # Import libraries needed to perform the data extraction
    from pyspark.sql import functions as F

    # Define the input path, checkpoint path, and table name that will be used in the incremental loading
    input_path = "/Volumes/workspace/default/external_datasets/wiki_data/" # Change according to your volume.
    checkpoint_path = f"/Volumes/workspace/default/external_datasets/checkpoints/" # Change according to your volume.
    full_table_name = 'workspace.default.wiki_data_raw' # Change according to your workspace and schema.

    df = (spark.readStream
        .format("cloudFiles") # Enables auto-loader when streaming data.
        .option("cloudFiles.format", "json") # Defines JSON as the file format.
        .option("cloudFiles.inferColumnTypes", "true")
        .option("cloudFiles.schemaLocation", f"{checkpoint_path}/schema")
        .load(input_path)
    )

    df_transformed = df

    # Write the streamed data to a data frame
    (df_transformed.writeStream
        .format("delta") # The databricks auto-loader can only write to a table in delta format.
        .option("checkpointLocation", f"{checkpoint_path}/checkpoint") # Creates a path to save checkpoint files that allow databricks to pickup streaming where it left off in the event of any interruption.
        .option("mergeSchema", "true") # Automatically merges schema changes.
        .outputMode("append") # Continuous data streaming can only write to the table in append mode.
        .toTable(full_table_name)
    )
    ```
    - `input_path` should be the same path as `filename` in the previous notebook.
    - Create a `checkpoints` directory in the `external_datasets` volume for the `checkpoint_path`. This tells databricks where to begin streaming if the previous streaming job is interrupted.
    - Create a `wiki_data_raw` table in the `default` schema for the `full_table_name` variable.
    - Once the streaming is complete, you can run `select * from workspace.default.wiki_data_raw` to check the data.
    - `select count(*) from workspace.default.wiki_data_raw` will tell you how many records have been streamed.
- Create a separate notebook to perform the data curation:
    ```
    # Import libraries needed to perform the data curation
    from pyspark.sql.types import StructType, StructField, StringType, LongType, IntegerType, BooleanType
    from pyspark.sql.functions import * 
    import pandas as pd
    import requests

    # Load the wiki data from the wiki_data_raw table
    wiki_data = spark.table('workspace.default.wiki_data_raw').repartition(10) # Using 10 partitions to load the data allows for better parallelism than the default 2 partitions.

    # Retrieve the label, description, and instance qID for a given qID.
    def batch_fetch(qids):
        """
        Takes a list of QIDs, returns a dict:
        {qid: (label, instance_qid)}.
        """
        url = (
            "https://www.wikidata.org/w/api.php"
            "?action=wbgetentities"
            f"&ids={'|'.join(qids)}"
            "&languages=en"
            "&format=json"
        )
        headers = {
            "User-Agent": "WikidataBatchFetcher/1.0 (sakthivelooty@gmail.com)"
        }
        resp = requests.get(url, headers=headers, timeout=8)
        if resp.status_code != 200: # Raise an error for a bad API response.
            raise RuntimeError(f"HTTP {resp.status_code}")

        out = {}
        for qid, ent in resp.json().get("entities", {}).items():
            label = ent.get("labels", {}).get('en', {}).get("value") 
            desc = ent.get("descriptions", {}).get('en', {}).get("value") 
            p31s  = ent.get("claims", {}).get("P31", [])
            inst_qid = (
                p31s[0]["mainsnak"]["datavalue"]["value"]["id"]  if p31s else None
            )
            
            out[qid] = (label, desc, inst_qid)
        return out


    # Enrich data with 'label' and 'instance_qid' columns.
    def enrich_qids(iterator): # An iterator is a data frame.
        """
        Receives Pandas batches with column 'qid'.
        Returns batches with 2 new columns: label, instance_qid
        """
        cache = {}         # per-worker in-memory cache  {qid: (label, inst_qid)}

        for pdf in iterator:
            # find QIDs we still need to resolve
            missing = [q for q in pdf["qid"].unique() if q not in cache]
            if missing:
                # resolve in chunks of <= 50 QIDs (API limit)
                for i in range(0, len(missing), 50):
                    chunk = missing[i : i + 50]
                    try:
                        cache.update(batch_fetch(chunk))
                    except Exception as e:
                        # fallback: mark failures with the error string
                        cache.update({q: (str(e), None, None) for q in chunk})

            # map cached results back to the batch
            pdf["label"] = pdf["qid"].map(lambda q: cache[q][0])
            pdf["desc"] = pdf["qid"].map(lambda q: cache[q][1])
            pdf["instance_qid"] = pdf["qid"].map(lambda q: cache[q][2])

            yield pdf[["qid", "label", "desc", "instance_qid"]]


    schema = StructType([
        StructField("qid", StringType(), True),
        StructField("label", StringType(), True),
        StructField("desc", StringType(), True),
        StructField("instance_qid", StringType(), True)
    ])

    # Call the above UDF in pandas using the schema
    def get_label_value(data):
        return data.mapInPandas(enrich_qids, schema)

    df_qids = (
        wiki_data
        .withColumn("qid", regexp_extract("title_url", r"Q\d+", 0))
        .select("qid")
        .where(col("qid") != "")
    )

    # Retrieve label values for distinct qIDs in the dataset
    meta_df = get_label_value(df_qids.distinct())

    # Join the wiki data with the metadata based on title.
    wiki_data_enriched_temp = wiki_data.join(meta_df, wiki_data.title == meta_df.qid, "left")

    meta_df.display()

    wiki_data_enriched_temp.display()

    wiki_data_enriched_temp.selectExpr("instance_qid as qid").where('qid is not null').display()

    df_qids = (
        wiki_data_enriched_temp
        .selectExpr("instance_qid as qid")
        .where('qid is not null')
    )

    meta_df = get_label_value(df_qids.distinct()).selectExpr("qid as instance_qid", "label as instance_label", 'desc as instance_desc')

    wiki_data_enriched = wiki_data_enriched_temp.join(meta_df, "instance_qid", "left")

    wiki_data_enriched.display()

    wiki_data_enriched.write.format('delta').option("overwriteSchema", "true").mode('append').saveAsTable('workspace.default.wiki_data_enriched')

    spark.table('workspace.default.wiki_data_enriched').limit(5).display()
    ```
- Once the data has been properly curated, the dashboard can be created:
    - In the databricks UI, under Dashboards, click 'Create new dashboard'.
    - Within the dashboard, use the following query to retrieve the top 50 most updated posts:
        ```
        SELECT qid,
            COALESCE(label, qid)      AS post_name,
            COUNT(*)                  AS number_of_edits
        FROM   sakthivel_ws.default.wiki_data_enriched -- Update with your enriched data table.
        GROUP  BY qid, label
        ORDER  BY number_of_edits DESC
        LIMIT  50;
        ```
    - Use the following query to determine if a post was edited by a bot or human:
        ```
        SELECT IF(bot,'Bot','Human') AS editor_type,
            COUNT(*)              AS edits
        FROM   sakthivel_ws.default.wiki_data_enriched -- Update with your enriched data table.
        GROUP  BY editor_type;
        ```
    - Use the following query to retrieve the top 50 most updated instances:
        ```
        SELECT instance_qid,
            COALESCE(instance_label, instance_qid)      AS post_name,
            COUNT(*)                  AS number_of_edits
        FROM   sakthivel_ws.default.wiki_data_enriched
        GROUP  BY instance_qid, instance_label
        ORDER  BY number_of_edits DESC
        LIMIT  50;
        ```
- These queries will produce data that can be used to populate the dashboard with various types of charts and graphs.