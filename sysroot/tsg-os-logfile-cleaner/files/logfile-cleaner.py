import os
import re
import sys
import toml
import time
import shutil
import psutil
import fnmatch
import argparse
import logging
import subprocess
from sdnotify import SystemdNotifier

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

def set_logging(level_str='INFO'):
    level_str = level_str.upper()
    level = getattr(logging, level_str, logging.INFO)

    if logger.hasHandlers():
        logger.handlers.clear()
    handler = logging.StreamHandler()
    handler.setLevel(level)
    formatter = logging.Formatter('ts=%(asctime)s level=%(levelname)s msg=%(message)s', datefmt='%Y-%m-%dT%H:%M:%SZ')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.info("Set logging level %s." % level_str)

class CommandParser:
    def __init__(self):
        self._parse_arguments()

    def _parse_arguments(self):
        parser = argparse.ArgumentParser(description="Tsg OS Tools - Tsg OS log files cleaner.")
        parser.add_argument('-d', '--daemon',  action='store_true', default = False, 
                            help='enable Tsg OS log files cleaner daemon mode, exit when recv a signal.')
        parser.add_argument('--dry-run', action='store_true', default = False,
                            help='simulate a running.')
        parser.add_argument('--configs', nargs='+', default = ['/opt/tsg/logfile-cleaner/etc/config.toml', '/etc/logfile-cleaner/config.toml.d'],
                            help='Configuration files or directories containing additional *.toml files, default [/opt/tsg/logfile-cleaner/etc/config.toml, /etc/logfile-cleaner/config.toml.d')

        args = parser.parse_args()

        self._daemon = args.daemon
        self._dry_run = args.dry_run
        self._configs = args.configs

    @property
    def daemon(self):
        return self._daemon

    @property
    def dry_run(self):
        return self._dry_run

    @property
    def configs(self):
        return self._configs


class TomlFileLoader:
    def __init__(self, file_path):
        self._file_path = file_path
        self._config = {}
        self._load()

    def _load(self):
        if not self._validate_path():
            return
        try:
            with open(self._file_path, 'r') as file:
                self._config = toml.load(file)
                logger.info("Config file %s loaded successfully." % self._file_path)
        except Exception as e:
            logger.error("Failed to load config file %s." % str(e))
            self._config = {}

    def _validate_path(self):
        if not os.path.isfile(self._file_path):
            logger.error("Fail ot load config. config file %s not found." % self._file_path)
            return False
        return True

    @property
    def config(self):
        return self._config

class TomlDirLoader:
    def __init__(self, dir_path):
        self._dir_path = dir_path
        self._configs = []
        self._load()

    def _load(self):
        if not self._validate_path():
            return
        toml_files = self._get_toml_files()
        for toml_file in toml_files:
            tomlfile_loader = TomlFileLoader(toml_file)
            self._configs.append(tomlfile_loader.config)

    def _validate_path(self):
        if not os.path.isdir(self._dir_path):
            logger.error("Config Loader: config dir not found: %s." % self._dir_path)
            return False
        return True

    def _get_toml_files(self):
        toml_files = []
        for filename in os.listdir(self._dir_path):
            if filename.endswith('.toml'):
                toml_file = os.path.join(self._dir_path, filename)
                toml_files.append(toml_file)
        return toml_files

    @property
    def configs(self):
        return self._configs

class ConfigsMerger:
    def __init__(self, configs):
        self._configs = configs
        self._merged_config = {}
        self._merge()

    def _merge(self):
        for config in self._configs:
            self._merge_src_to_dest(self._merged_config, config)

    def _merge_src_to_dest(self, dest, src):
        for key, value in src.items():
            if key in dest and isinstance(dest[key], dict) and isinstance(value, dict):
                self._merge_src_to_dest(dest[key], value)
            elif key in dest and isinstance(dest[key], list) and isinstance(value, list):
                dest[key].extend(value)
            else:
                dest[key] = value

    @property
    def merged_config(self):
        return self._merged_config

class ConfigLoader:
    def __init__(self, config_paths):
        self._configs_paths = config_paths
        self._configs = []
        self._config = {}
        self._load()
        self._merge_configs()

    def _load(self):
        for config_path in self._configs_paths:
            if os.path.isfile(config_path):
                toml_file_loader = TomlFileLoader(config_path)
                self._configs.append(toml_file_loader.config)
                continue
            if os.path.isdir(config_path):
                toml_dir_loader = TomlDirLoader(config_path)
                self._configs.extend(toml_dir_loader.configs)
                continue
            logger.error("Fail to load configs: Config path %s not found." % config_path)

    def _merge_configs(self):
        configs_merger = ConfigsMerger(self._configs)
        self._config = configs_merger.merged_config

    @property
    def config(self):
        return self._config

class ConfigReader:

    def __init__(self, configs: dict):
        self._configs = configs
        self._add_watermark_in_bytes_for_watch_dirs()

    def _add_watermark_in_bytes_for_watch_dirs(self):
        if "watched_dir" not in self._configs:
            return
        for watched_dir in self._configs["watched_dir"]:
            watched_dir["low_watermark_in_bytes"]  = self._parse_watermark_to_bytes( watched_dir["low_watermark"], watched_dir["path"])
            watched_dir["high_watermark_in_bytes"] = self._parse_watermark_to_bytes( watched_dir["high_watermark"], watched_dir["path"])
            logger.info(f"After parse watched dir: %s, low_watermark: %d bytes, high_watermark: %d bytes." % (watched_dir["path"], watched_dir["low_watermark_in_bytes"], watched_dir["high_watermark_in_bytes"]))
            if watched_dir["low_watermark_in_bytes"] > watched_dir["high_watermark_in_bytes"]:
                logger.error(f"Parse watched dir: %s, low_watermark %d bytes can not be higher than high_watermark %d bytes." % (watched_dir["path"], watched_dir["low_watermark_in_bytes"], watched_dir["high_watermark_in_bytes"]))

    def _parse_watermark_to_bytes(self, watermark, dir_path):
        pattern = r'^(-|\d+%|\d+[KMGT]?B)$'
        match = re.match(pattern, watermark.strip())
        if not match:
            logger.error(f"Watermark format not support: %s in dir %s, example: 10%% or 1GB" % (watermark, dir_path))
            return 0
        if watermark.endswith("%"):
            return self._parse_percent_watermark_to_bytes(watermark, dir_path)
        if watermark.endswith("B"):
            return self._parse_size_watermark_to_bytes(watermark, dir_path)
        return 0

    def _parse_percent_watermark_to_bytes(self, watermark, dir_path):
        pattern = r'^\s*(\d+(?:\.\d+)?)\s*%\s*$'
        try:
            match = re.match(pattern, watermark.strip())
            percentage = float(match.group(1))
            _, used, free = shutil.disk_usage(dir_path)
            total = used + free
            return int(total * percentage / 100)
        except Exception as e:
            logger.error(f"Failed to parse percent format watermark {watermark} of the dir {dir_path}. - {e}")
            return 0

    def _parse_size_watermark_to_bytes(self, watermark, dir_path):
        pattern = r'^\s*(\d+(?:\.\d+)?)\s*([KMGT]?B)\s*$'
        units = {
            'B': 1,
            'KB': 1024,
            'MB': 1024**2,
            'GB': 1024**3,
            'TB': 1024**4
        }
        try:
            match = re.match(pattern, watermark.strip())
            return int(int(match.group(1)) * units[match.group(2)])
        except Exception as e:
            logger.error(f"Failed to parse size format watermark {watermark} of the dir {dir_path}. - {e}")
            return 0

    def read_splited_clean_intervals_s(self):
        clean_interval_s = self._read_clean_interval_s()
        systemd_watchdog_interval_s = 20
        
        n_systemd_watchdog_interval_s = clean_interval_s // systemd_watchdog_interval_s
        remainder = clean_interval_s % systemd_watchdog_interval_s
        
        splited_clean_intervals_s = [systemd_watchdog_interval_s] * n_systemd_watchdog_interval_s 
        if remainder != 0:
            splited_clean_intervals_s.append(remainder)

        return splited_clean_intervals_s

    def _read_clean_interval_s(self):
        if "main" in self._configs and "clean_interval_s" in self._configs["main"]:
            return int(self._configs["main"]["clean_interval_s"])
        return 30


    def read_watched_dirs(self):
        if "watched_dir" not in self._configs:
            return []
        return self._configs["watched_dir"]

    def read_watched_dir_path(self, watched_dir: dict):
        if "path" not in watched_dir:
            return False
        return watched_dir["path"]

    def read_watched_dir_low_watermark(self, watched_dir: dict):
        if "low_watermark_in_bytes" not in watched_dir:
            return sys.maxsize
        return watched_dir["low_watermark_in_bytes"]

    def read_watched_dir_high_watermark(self, watched_dir: dict):
        if "high_watermark_in_bytes" not in watched_dir:
            return 0
        return watched_dir["high_watermark_in_bytes"]

    def read_score_adj_by_path(self, path):
        if "clean_score_adj" not in self._configs:
            return 0
        for clean_score_adj in reversed(self._configs["clean_score_adj"]):
            if ("path" not in clean_score_adj) or ("score_adj" not in clean_score_adj):
                return 0
            if fnmatch.fnmatch(path, clean_score_adj["path"]):
                return int(clean_score_adj["score_adj"])
        return 0

    def is_path_matched_exclude(self, path):
        if "clean_exclude" not in self._configs:
            return False
        for exclude in reversed(self._configs["clean_exclude"]):
            if "path" not in exclude:
                return False
            if fnmatch.fnmatch(path, exclude["path"]):
                return True
        return False

    def read_loglevel(self):
        if ("main" not in self._configs) or ("loglevel" not in self._configs["main"]):
            return "INFO"
        loglevel_str = str(self._configs["main"]["loglevel"]).upper()
        if loglevel_str not in ["DEBUG", "INFO", "WARN", "ERROR"]:
            return "INFO"
        return loglevel_str

class DirFileInfosReader:
    def __init__(self, dir_path, config_reader: ConfigReader, systemd_notifier):
        self._dir_path = dir_path
        self._config_reader = config_reader
        self._systemd_notifier = systemd_notifier
        self._file_infos = []
        self._dir_usage_in_bytes = 0
        self._read()
        self._sort_files_info_by_score()

    def _read(self):
        if not self._validate_path():
            return

        for root, dirs, filenames in os.walk(self._dir_path):
            # exclude mounts.
            dirs[:] = [d for d in dirs if not os.path.ismount(os.path.join(root, d))]
            for filename in sorted(filenames):
                full_path = os.path.join(root, filename)
                # exclude link file.
                if os.path.islink(full_path):
                    logger.debug(f"Not read link file: %s in dir: %s." % (full_path, self._dir_path))
                    continue

                # calc dir size.
                size_in_bytes = os.path.getsize(full_path)
                self._dir_usage_in_bytes += size_in_bytes

                # build score units.
                is_matched_exclude = self._config_reader.is_path_matched_exclude(full_path)
                is_file_open = self._is_file_open(full_path)
                score, score_base, score_adj = self._read_files_score(full_path)
                self._file_infos.append({"path": full_path, "score": score, "score_base": score_base, "score_adj": score_adj, "size_in_bytes": size_in_bytes, "is_matched_exclude": is_matched_exclude,"is_file_open": is_file_open})
                if len(self._file_infos) % 100 == 1:
                    self._systemd_notifier.notify("WATCHDOG=1")

    def _validate_path(self):
        if not os.path.isdir(self._dir_path):
            logger.error("Read dir files info error: failed to find directory: %s." % self._dir_path)
            return False
        return True


    def _is_file_open(self, file_path):
        for proc in psutil.process_iter(['pid', 'open_files']):
            try:
                for file in proc.info['open_files'] or []:
                    if file.path == file_path:
                        return True
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        return False

    def _read_files_score(self, path):
        score_base = int(os.path.getmtime(path))
        score_adj = self._config_reader.read_score_adj_by_path(path)
        score = score_base + score_adj
        logger.debug("File path %s base score %d, adjust score: %d, final score: %d." % (path, score_base, score_adj, score))
        return score, score_base, score_adj

    def _sort_files_info_by_score(self):
        n = len(self._file_infos)
        for i in range(n):
            for j in range(0, n-i-1):
                if self._file_infos[j]["score"] >= self._file_infos[j+1]["score"]:
                    self._file_infos[j], self._file_infos[j+1] = self._file_infos[j+1], self._file_infos[j]
        return self._file_infos

    def read_path_from_file_info(self, file_info):
        return file_info["path"]

    def read_file_size_from_file_info(self, file_info):
        return file_info["size_in_bytes"]

    def read_score_from_file_info(self, file_info):
        return file_info["score"]

    def read_score_base_from_file_info(self, file_info):
        return file_info["score_base"]

    def read_score_adj_from_file_info(self, file_info):
        return file_info["score_adj"]

    def read_is_matched_exclude_from_file_info(self, file_info):
        return file_info["is_matched_exclude"]

    def read_is_file_open_from_file_info(self, file_info):
        return file_info["is_file_open"]

    @property
    def file_infos(self):
        return self._file_infos

    @property
    def dir_usage_in_bytes(self):
        return self._dir_usage_in_bytes

class DirsFilesCleaner:
    def __init__(self, command_parser: CommandParser, config_reader: ConfigReader, systemd_notifier):
        self._command_parser = command_parser
        self._config_reader = config_reader

        self._is_daemon = self._command_parser.daemon
        self._is_dry_run = self._command_parser.dry_run

        self._splited_clean_intervals_s = self._config_reader.read_splited_clean_intervals_s()
        self._systemd_notifier = systemd_notifier

    def clean(self):
        watched_dirs = config_reader.read_watched_dirs()
        while True:
            for watched_dir in watched_dirs:
                self._clean_one_dir_files(
                    config_reader.read_watched_dir_path(watched_dir), 
                    config_reader.read_watched_dir_low_watermark(watched_dir), 
                    config_reader.read_watched_dir_high_watermark(watched_dir)
                )
            if self._is_daemon is not True:
                break

            self._systemd_notifier.notify("WATCHDOG=1")
            for clean_interval_s in self._splited_clean_intervals_s:
                time.sleep(clean_interval_s)
                self._systemd_notifier.notify("WATCHDOG=1")


    def _clean_one_dir_files(self, dir_path, low_watermark, high_watermark):
        if dir_path is None:
            return

        if low_watermark > high_watermark:
            return

        reader = DirFileInfosReader(dir_path, self._config_reader, self._systemd_notifier)
        if reader.dir_usage_in_bytes < high_watermark:
            return

        logger.info("Dir %s usage (size: %d bytes) is over the high watermark(size: %d bytes), trying to free bytes down to the low watermark(size: %d bytes)." % (dir_path, reader.dir_usage_in_bytes, high_watermark, low_watermark))
        try_remove_bytes = reader.dir_usage_in_bytes - low_watermark
        for file_info in reader.file_infos:
            if try_remove_bytes <= 0:
                break
            file_path = reader.read_path_from_file_info(file_info)
            file_size = reader.read_file_size_from_file_info(file_info)
            file_score = reader.read_score_from_file_info(file_info)
            if reader.read_is_matched_exclude_from_file_info(file_info):
                logger.info(f"Not remove the file %s(size: %d bytes) that match exclusion rule." % (file_path, file_size))
                continue

            if reader.read_is_file_open_from_file_info(file_info):
                logger.info(f"Not remove the open file %s (size: %d bytes)." % (file_path, file_size))
                continue

            self._remove_file(file_path, file_size, file_score)
            try_remove_bytes -= file_size

    def _remove_file(self, path, file_size, file_score):
        if not self._is_dry_run:
            os.remove(path)
            logger.info(f"File %s(size: %d bytes, score: %d) has been removed." % (path, file_size, file_score))
        else:
            logger.info(f"IN dry-run Mode the file %s(size: %d bytes, score: %d) can be removed." % (path, file_size, file_score))

if __name__ == '__main__':
    set_logging()
    try:
        command_parser = CommandParser()
        config_loader = ConfigLoader(command_parser.configs)
        config_reader = ConfigReader(config_loader.config)
        set_logging(config_reader.read_loglevel())
        # notify watchdog.
        systemd_notifier = SystemdNotifier()
        systemd_notifier.notify("READY=1")
        dirs_files_cleaner = DirsFilesCleaner(command_parser, config_reader, systemd_notifier)
        dirs_files_cleaner.clean()

    except KeyboardInterrupt:
        logger.info("Program interrupted. Exiting gracefully...")

