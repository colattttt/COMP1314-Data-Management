<h1>Gold Price Tracker System</h1>

<h2>1.0 System Overview</h2>
<p>
The Gold Price Tracker System is a Bash-based data collection and reporting tool designed to automate the retrieval, storage, and analysis of gold price data. The system downloads live gold price information from Kitco, extracts key market values including Ask, Bid, Day High, Day Low, Change, and Change Percentage, and stores the results in a MySQL database for structured querying and visualisation.
</p>

<p>
In addition to raw price data, the system captures price-by-weight values such as Ounce, Gram, Kilo, Pennyweight, Tola, and Tael. These unit-based prices are stored in a separate table to allow each gold-price record to be analysed across different measurement units.
</p>

<p>
The script also converts USD prices into AUD, CAD, and JPY using Kitco’s exchange-rate values, enabling the database to maintain multi-currency price records. This design supports automated plotting, historical analysis, and reporting of gold price trends over time.
</p>

<hr>

<h2>1.1 Project Folder Structure</h2>
<p>
All scripts use relative paths and are designed to be executed from the project root directory.
</p>

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
   └─ ... (other PNG plots)
</pre>

<hr>

<h2>2.0 Prerequisites and Installation</h2>
<p>
This project is designed for Linux environments such as Ubuntu on WSL. Before running the scripts, ensure the following tools are installed and available in the system PATH:
</p>

<ul>
  <li>curl – used to download Kitco HTML data</li>
  <li>grep with PCRE support (grep -P) – used for regex extraction</li>
  <li>bc – used for currency conversion calculations</li>
  <li>mysql client – used to insert and query data</li>
  <li>gnuplot – used to generate PNG charts</li>
</ul>

<h3>2.1 Required Packages</h3>
<pre>
sudo apt update
sudo apt install -y curl grep bc mysql-client gnuplot
</pre>

<hr>

<h2>2.2 MySQL Database Setup</h2>
<p>
The scripts expect a MySQL database named <b>gold_tracker</b>. The database follows a normalised design and contains reference tables for currencies and units, as well as two data tables for storing gold prices.
</p>

<p>
The full SQL schema is provided in the submission folder as an exported <code>.sql</code> file.
</p>

<table border="1" cellpadding="6">
<tr>
  <th>Table</th>
  <th>Purpose / Required Fields</th>
</tr>
<tr>
  <td>currencies</td>
  <td>currency_id (PK), currency_code</td>
</tr>
<tr>
  <td>units</td>
  <td>unit_id (PK), unit_name</td>
</tr>
<tr>
  <td>gold_prices</td>
  <td>gold_id (PK), currency_id (FK), ask_price, bid_price, high_price, low_price, change_value, change_percent, timestamp_local, timestamp_ny</td>
</tr>
<tr>
  <td>gold_unit_prices</td>
  <td>id (PK), currency_id (FK), gold_id (FK), unit_id (FK), price</td>
</tr>
</table>

<hr>

<h2>3.0 Running the Data Collection Script (goldpricetracker.sh)</h2>

<h3>Step 1: Make the script executable (first-time only)</h3>
<pre>chmod +x goldpricetracker.sh</pre>

<h3>Step 2: Run the script from the project root</h3>
<pre>./goldpricetracker.sh</pre>

<p>
When executed, the script switches into its own directory using <code>cd "$(dirname "$0")"</code> to ensure all relative paths work correctly, even when executed by Cron.
</p>

<h3>3.1 What the Script Displays</h3>
<p>
The script prints a live report showing local time, New York time, USD prices (Ask, Bid, High, Low, Change, Change Percentage), and unit-based prices. The same report is then generated for AUD, CAD, and JPY after currency conversion.
</p>

<h3>3.2 Data Stored in MySQL</h3>
<p>
For each currency execution:
</p>
<ol>
  <li>One gold-price record is inserted into the <code>gold_prices</code> table.</li>
  <li>Six related unit-price records are inserted into <code>gold_unit_prices</code>.</li>
</ol>

<p>
This process is performed for USD first, then repeated for AUD, CAD, and JPY. This ensures all unit prices remain correctly linked to the same gold-price record.
</p>

<hr>

<h2>4.0 Automating Data Collection with Cron</h2>

<h3>Step 1: Configure Cron</h3>
<pre>
0 * * * * cd /mnt/c/Users/pohsh/GitHub/COMP1314-Data-Management && ./goldpricetracker.sh >> logs/cron.log 2>> logs/goldtracker_error.log
</pre>

<p>
This configuration runs the script at the start of every hour. Normal output is written to <code>cron.log</code>, while errors are written to <code>goldtracker_error.log</code>.
</p>

<h3>Step 2: Verify Cron</h3>
<pre>crontab -l</pre>

<hr>

<h2>5.0 Plotting Gold Prices (plot_gold.sh)</h2>
<p>
The plotting script retrieves historical data from MySQL and generates PNG graphs using Gnuplot. Required folders are created automatically if they do not exist.
</p>

<h3>5.1 Running the Plot Script</h3>
<pre>chmod +x plot_gold.sh</pre>
<pre>./plot_gold.sh ask USD</pre>

<p>
Supported price types: ask, bid, high, low<br>
Supported currencies: USD, AUD, CAD, JPY
</p>

<h3>5.2 Output Files Generated</h3>
<ul>
  <li>Plot data file in <code>plot_data</code></li>
  <li>PNG image in <code>plot_images</code></li>
  <li>Timestamped log entry in <code>plot.log</code></li>
</ul>

<hr>

<h2>6.0 Logs and Error Handling</h2>
<p>
Runtime errors from <code>goldpricetracker.sh</code> are recorded in <code>goldtracker_error.log</code>. Generated plot files are logged with timestamps in <code>plot.log</code>.
</p>

<hr>

<h2>8.0 Troubleshooting</h2>
<ul>
  <li>Ensure MySQL is running and the database exists</li>
  <li>Verify required tables and IDs</li>
  <li>Ensure MySQL works in non-interactive mode</li>
  <li>Check error logs for extraction or network failures</li>
  <li>Confirm grep -P and gnuplot are installed</li>
</ul>

<hr>

<h2>9.0 Additional Notes</h2>
<p>
Relative paths are used throughout the project. The folder structure should remain unchanged to ensure correct execution under both manual and Cron-based runs.
</p>

<p>
The <code>raw.html</code> file is included only as a sample snapshot and is overwritten each time the tracker runs.
</p>
