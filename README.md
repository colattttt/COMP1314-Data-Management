<h2>1.0 System Overview</h2>

<p>
The Gold Price Tracker System is a Bash-based data collection and reporting tool designed to 
automate the retrieval, storage, and analysis of gold price data. The system downloads live gold 
price information from Kitco, extracts key market values including Ask, Bid, Day High, Day 
Low, Change, and Change Percentage, and stores the results in a MySQL database for 
structured querying and visualisation.
</p>

<p>
In addition to raw price data, the system captures price-by-weight values such as Ounce, Gram, 
Kilo, Pennyweight, Tola, and Tael. These unit-based prices are stored in a separate table to 
allow each gold-price record to be analysed across different measurement units.
</p>

<p>
The script also converts USD prices into AUD, CAD, and JPY using Kitco’s exchange-rate 
values, enabling the database to maintain multi-currency time-stamped records for plotting and 
analysis.
</p>

<h2>1.1 Project Folder Structure</h2>

<pre>
project_root/
├─ goldpricetracker.sh
├─ plot_gold.sh
├─ raw.html
├─ logs/
│  ├─ cron.log
│  ├─ goldtracker_error.log
│  └─ plot.log
├─ plot_data/
│  ├─ plotdata_ask.txt
│  ├─ plotdata_bid.txt
│  ├─ plotdata_high.txt
│  └─ plotdata_low.txt
└─ plot_images/
   ├─ usd_ask_price.png
   └─ ... (other generated PNG plots)
</pre>

<ul>
  <li>Scripts are stored in the root directory for easy execution.</li>
  <li>Log files are separated into the logs folder for debugging and auditing.</li>
  <li>Temporary plot data exported from MySQL is stored in plot_data folder.</li>
  <li>Generated charts are saved in plot_images folder to keep outputs separate from code.</li>
</ul>

<hr>

<h2>2.0 Prerequisites and Installation</h2>

<p>
This coursework runs on Linux (tested on Ubuntu via WSL). The following tools must be 
installed:
</p>

<ol>
  <li>curl – used to download the raw HTML page from Kitco</li>
  <li>grep – used to extract price values using regular expressions</li>
  <li>bc – used to perform floating-point calculations during currency conversion</li>
  <li>MySQL client – used to insert and query data in the gold_tracker database</li>
  <li>Gnuplot – used to generate PNG price charts in plot_gold.sh</li>
</ol>

<p>
These packages are commonly available on Ubuntu and can be installed using:
</p>

<pre>sudo apt install -y curl grep bc mysql-client gnuplot</pre>

<h2>2.1 MySQL Database Setup</h2>

<p>
The scripts require a MySQL database named gold_tracker. This database stores reference data 
(currencies and units) as well as time-series gold price data collected by the script. The 
goldpricetracker.sh script inserts one row per currency per execution into the gold_prices table.
</p>

<p>
For each inserted gold-price record, the script then inserts six related rows into the 
gold_unit_prices table to store price-by-weight values.
</p>

<p><strong>Required Tables:</strong></p>

<pre>
currencies        currency_id (PK), currency_code
units             unit_id (PK), unit_name
gold_prices       gold_id (PK), currency_id (FK), ask_price, bid_price,
                  high_price, low_price, change_value, change_percent,
                  timestamp_local, timestamp_ny
gold_unit_prices  id (PK), currency_id (FK), gold_id (FK), unit_id (FK), price
</pre>

<p>
The database schema follows a normalised design where each gold-price record is linked to 
multiple unit-price records using foreign keys. The full SQL schema is included in the 
submission folder as an exported .sql file.
</p>

<hr>

<h2>3.0 Running the Data Collection Script (goldpricetracker.sh)</h2>

<p>
Step 1: Make the script executable (first-time setup only)
</p>

<pre>chmod +x goldpricetracker.sh</pre>

<p>
Step 2: Run the script from the project root folder
</p>

<pre>./goldpricetracker.sh</pre>

<p>
When executed, the script first changes into its own directory using
<code>cd "$(dirname "$0")"</code>. This ensures relative paths work correctly under both manual execution and Cron.
</p>

<h2>3.1 Script Output (Terminal Display)</h2>

<p>
When the script runs, it prints a formatted live report directly to the terminal. The output shows 
the local timestamp and the corresponding New York (NY) time, followed by the USD gold 
prices, including Ask, Bid, Day High, Day Low, Change, and Change Percentage. It also 
displays the price-by-weight values such as Ounce, Gram, Kilo, Pennyweight, Tola, and Tael.
</p>

<p>
After displaying USD data, the script converts the prices into AUD, CAD, and JPY using the 
extracted exchange rates and prints the same report format for each currency. This immediate 
terminal output allows the user to quickly verify that both the data extraction and currency 
conversion processes are working correctly.
</p>

<h2>3.2 Data Stored in MySQL</h2>

<p>
The script stores the collected data in a structured and normalised form in MySQL. For each 
currency, one record is inserted into the gold_prices table to represent a single price reading.
This record is then linked to multiple entries in the gold_unit_prices table, which store the 
corresponding prices for different weight units.
</p>

<p>
This process is performed first for USD, and then repeated for each converted currency (AUD, 
CAD, JPY). By linking unit prices to a single gold-price record, the database maintains 
consistency and ensures that all unit-based values belong to the same price reading.
</p>

<hr>

<h2>4.0 Automating Data Collection with Cron</h2>

<p>
The goldpricetracker.sh script can be automated using Cron, allowing gold-price data to be 
collected without manual execution.
</p>

<p><strong>Step 1: Configure the Cron job</strong></p>

<p>
In this coursework, the script is scheduled to run once every hour. Before executing the script, 
Cron switches into the project directory to ensure that all relative paths work correctly.
</p>

<pre>
0 * * * * cd /mnt/c/Users/pohsh/GitHub/COMP1314-Data-Management &&
./goldpricetracker.sh >> logs/cron.log 2>> logs/goldtracker_error.log
</pre>

<p><strong>Step 2: Logging behaviour</strong></p>

<p>
Normal script output is appended to the cron.log file in the logs folder. Any errors (such as 
network failures or database issues) are written to goldtracker_error.log.
</p>

<p><strong>Step 3: Verify the Cron job</strong></p>

<pre>crontab -l</pre>

<p>
This confirms that the automated data-collection task has been successfully scheduled.
</p>

<hr>

<h2>5.0 Plotting Gold Prices (plot_gold.sh)</h2>

<p>
The plot_gold.sh script queries the gold_tracker database and generates PNG graphs using 
gnuplot. It automatically creates the folders plot_images and plot_data if they do not exist.
</p>

<h2>5.1 Plot Types and Commands</h2>

<p>
Step 1: Make the script executable (first-time setup only)
</p>

<pre>chmod +x plot_gold.sh</pre>

<p>
Step 2: Run the script with a price type and currency code
</p>

<pre>./plot_gold.sh ask USD</pre>

<p>
Supported price types: ask, bid, high, low.<br>
Supported currencies: USD, AUD, CAD, JPY.
</p>

<h2>5.2 Output Files Generated</h2>

<ol>
  <li>A plot-data file in the plot_data folder (for example plotdata_ask.txt)</li>
  <li>A PNG image in the plot_images folder (for example usd_ask_price.png)</li>
  <li>A timestamped entry in the plot.log file indicating which plot image was generated</li>
</ol>

<hr>

<h2>6.0 Logs and Error Handling</h2>

<p>
The goldpricetracker.sh script records runtime errors in the goldtracker_error.log file located 
in the logs folder. Errors may include network failures, empty downloads, or missing values 
caused by changes in Kitco’s page structure.
</p>

<p>
The plot_gold.sh script records each successfully generated plot in the plot.log file. Each 
log entry includes a timestamp and the name of the generated PNG image.
</p>

<h2>7.0 Files Used by the System</h2>

<pre>
goldpricetracker.sh   Downloads Kitco HTML, extracts values, displays report,
                      and inserts data into MySQL.
plot_gold.sh          Exports price history from MySQL and generates PNG graphs.
raw.html              Latest downloaded Kitco HTML (overwritten each run).
goldtracker_error.log Error log for download, extraction, and MySQL issues.
plot.log              Log of generated plot images.
plot_data             Temporary files used as gnuplot input.
plot_images           Generated PNG graphs.
</pre>

<hr>

<h2>8.0 Troubleshooting</h2>

<ol>
  <li>Ensure that the MySQL service is running and that the gold_tracker database exists.</li>
  <li>Verify that all required tables (currencies, units, gold_prices, gold_unit_prices) are
    created and contain the correct reference IDs used by the scripts.</li>
  <li>Confirm that the mysql command can run in non-interactive mode (for example, under
    Cron) without prompting for a password. If required, configure a MySQL client option
    file (.my.cnf).</li>
  <li>Check the goldtracker_error.log file in the logs folder for errors such as curl download
    failures, empty HTML files, or missing extracted values.</li>
  <li>Ensure that grep -P is available on the system. If not, install GNU grep
    or adjust the extraction commands.</li>
  <li>Verify that gnuplot is installed and that the files in the plot_data folder contain valid
    columns (DATE, TIME, and value)</li>
</ol>

<h2>9.0 Additional Notes</h2>

<p>
This coursework uses relative paths for all generated files. The script changes into its own 
directory at runtime to ensure consistent behaviour under manual execution and Cron. For best results, the project folder structure should remain unchanged so that logs, plots,
and data files are stored in their expected locations.
</p>