# Wiki Data Analysis Project

## Overview
This project demonstrates the analysis of open-source [wiki data](https://www.wikidata.org/wiki/Wikidata:Main_Page) using Databricks. Data will be continuously streamed from the source and processed using a vectorized user-defined function (UDF). A vectorized UDF is a high-performance function that processes data in batches (using arrays or Pandas Series) rather than row-by-row. By using libraries like NumPy and Apache Arrow, it minimizes overhead and can increase processing speed by up to 100x compared to traditional scalar UDFs.

The vectorized UDFs in this project will be used to decompose (JSON parsing) and analyze the incoming wiki data. Vectorized UDFs are preferred over scalar UDFs for the following reasons:
- Massive Speedups: Processing data in batches (vectorization) enables vectorized CPU instructions, drastically reducing serialization and execution overhead.
- Library Compatibility: Allows seamless use of Python libraries that are built on top of NumPy and Pandas (e.g., scikit-learn, MLlib) without looping manually through rows.
- Pandas UDFs in PySpark allow you to write Python functions using Pandas and apply them to Spark data frames efficiently.
- [Understanding Pandas UDF, applyInPandas, and mapInPandas](https://community.databricks.com/t5/technical-blog/understanding-pandas-udf-applyinpandas-and-mapinpandas/ba-p/75717)
- [Introducing Pandas UDF for PySpark](https://www.databricks.com/blog/2017/10/30/introducing-vectorized-udfs-for-pyspark.html)

The data will be processed using the medallion architecture. The raw wiki data will be placed in the bronze layer. The data will then be formatted and enriched in the gold layer, then displayed in a dashboard. There is no silver layer in this architecture because the data tables are small relative to the other projects, such as the Air Carrier Performance Analysis.