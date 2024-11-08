# TSG OS logfile cleaner
TSG OS Logfile Cleaner is a tool designed to clean up log files in the TSG OS. It helps users automate the deletion of old and unnecessary log files, saving disk space and keeping the system's log directory organized.

## Features
* `Flexible Configuration`: Users can customize cleaning policies, such as retaining log files.
* `Scoring System`: Calculate a score based on the file's last modification time to decide which files to delete. An `score_adj` parameter is provided to adjust the score.
* `Multiple Directories`: Support cleaning multiple directories, each with configurable `low_watermark` and `high_watermark`. Cleaning starts when the total size of files in a directory exceeds `high_watermark` and continues until it falls below `low_watermark`.
* `Dry-Run Mode`: Simulate the cleaning process and display the files that would be deleted without actually removing them.
* `Daemon Mode`: Continuously check and clean files based on a preset schedule.
## Usage
You can read help info using the following command:
```shell
python3 {dir}/logfile-cleaner.py
```
1. Add new configuration that the format is toml to the specified configuration file:
```shell
vi {dir}/cleaner.toml
```
2. Run the logfile cleaner:
```shell
python3 logfile-cleaner.py --config {dir}/cleaner.toml
```
## Configuration
The configuration file supports the following sections:
### Main Section
Configure general settings for running the cleaner.
* `interval_s`: The time interval in seconds between file cleans. Default: 30s.
* `loglevel`: Pick a logging level. Valid log levels are: "error", "warn", "info", "debug". Default: "info".

Example:
```toml
[main]
interval_s=30
loglevel="info"
```
### Watched Directories
Specify directories to monitor for log files. You can configure multiple entries in this section. 
* `path`: The directory to monitor.
* `low_watermark`: The low watermark for cleaning directories. Supported values include percentages (e.g., 50%) or sizes (e.g., 1B, 1KB, 1MB, 1GB).
* `high_watermark`: The high watermark for cleaning directories. Supported values include percentages (e.g., 50%) or sizes (e.g., 1B, 1KB, 1MB, 1GB).

Example:
```toml
[[watched_dir]]
path = "/var/log/watched_dir0"
low_watermark = "0B"
high_watermark = "1B"

[[watched_dir]]
path = "/var/log/watched_dir1"
low_watermark = "50%"
high_watermark = "75%"
```
### Clean Exclude
Configure specific log files or directories to exclude from cleaning.
* `path`: The path or glob pattern.

Example:
```toml
[[clean_exclude]]
path="/var/log/watched_dir0/*.json"
[[clean_exclude]]
path="/var/log/watched_dir1/exclude.md"
```
### Clean Score Adjustment
Adjust the scores for files to influence the deletion process.
* `path`: Directory path or file path.
* `score_adj`: The adjusted score.

Example:
```toml
[[clean_score_adj]]
path="/var/log/wathed_dir0/sub_dir0"
score_adj=1000
[[clean_score_adj]]
path="/var/log/wathed_dir1/score_adj1.json"
score_adj=1000
```