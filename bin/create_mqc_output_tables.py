#!/usr/bin/env python3

# import modules
import argparse
import json

# create parser Argument
parser = argparse.ArgumentParser(description="generate output table to use in MultiQC report generation")

# import counts from Pairtools stats output (-PT.stats.txt) from command line argument
parser.add_argument("-js_file", help="list of .json files outputted by md_js_QC_summary.py")
args = parser.parse_args()

# extract information (read pairs = rp) and put it in a dictionary
js_stats_dict = {}

json_file = open(args.js_file)
json_data = json.load(json_file)

for i in json_data["samples"]:
    sample_name = i["sample name"]
    basic_data = {"sample": i["sample name"]}

# create basic reads stat .json file

# basic_reads_stat = {
#    "plot_type": "table",
#    "section_name": "Basic Reads Statistic",
#    "description": "Reads per sample, reads mapping to the provided genome, duplicated reads based on pairtools and non-duplicated and mapped reads.",
#    "data": {
#        sample_name: {
#            "total": "{:,}".format(pt_stats_dict["total"]),
#            "mapped (% of total))": "{:,}".format(pt_stats_dict["total_mapped"]),
#            "percent of total": pt_stats_percent_of_total["total_mapped"],
#            "duplicates": "{:,}".format(pt_stats_dict["total_dups"]),
#            "percent of total": pt_stats_percent_of_total["total_dups"],
#            "non-duplicated mapped reads": "{:,}".format(pt_stats_dict["total_nodups"]),
#            "percent of total": pt_stats_percent_of_total["total_nodups"],
#            "percent of nodup": pt_stats_percent_of_nodup["total_nodups"],
#        }
#    },
# }

# create cis read pairs .json file

# create trans read pairs .json file

# create valid read pairs .json file


# print table to terminal and save .json to file
json_basic_out = json.dumps(basic_data, indent=2)
json_basic_out_file = sample_name + "basic_stats.json"
basic_outfile = open(json_basic_out_file, "w")
basic_outfile.write(json_basic_out)

print(json_basic_out)
