#!/bin/bash

usage()
{
	printf "Usage: $0 [opt] [val]\n\n"
	printf "          -c cpuid       Collect data of the specified cpu id\n"
	printf "          -t threadid    Collect data of the specified thread id\n"
	printf "          -p processid   Collect data of the specified process id\n"
	printf "          -h             Help\e[0m\n\n"
	exit 0
}

if [ ! -n "$1" ] || [ ! -n "$2" ]; then
	usage
fi

opt_type="h"
while getopts c:t:p:h opt
do
	case $opt in
	c) opt_type="c" ;;
	t) opt_type="t" ;;
	p) opt_type="p" ;;
	h|?) usage ;;
	esac
done

# 执行后在当前目录下会生成采样数据 perf.data
rm -rf perf.data

if [ $opt_type == "c" ]; then
	printf "\e[32m Collect data on cpu $2\e[0m\n"
	perf record -e cpu-clock --call-graph dwarf -C $2 -- sleep 5
elif [ $opt_type == "t" ]; then
	printf "\e[32m Collect data on thread $2\e[0m\n"
	perf record -e cpu-clock --call-graph dwarf -t $2 -- sleep 5
elif [ $opt_type == "p" ]; then
	printf "\e[32m Collect data on process $2\e[0m\n"
	perf record -e cpu-clock --call-graph dwarf -p $2 -- sleep 5
else
	usage
fi

if [ ! -f "perf.data" ]; then
	echo "Please Collect data !"
	exit 0
fi

if [ ! -d FlameGraph ]; then
	echo "git clone https://github.com/brendangregg/FlameGraph.git"
	git clone https://github.com/brendangregg/FlameGraph.git
fi

rm -rf perf.unfold
rm -rf perf.folded
rm -rf perf.svg

printf "\e[32m Convert data to flame graph\e[0m\n"

perf script | /opt/tsg/tools/FlameGraph/stackcollapse-perf.pl | /opt/tsg/tools/FlameGraph/flamegraph.pl >perf.svg

# 使用浏览器查看 perf.svg, 在浏览器中使用 Ctrl + F 进行关键字搜索
