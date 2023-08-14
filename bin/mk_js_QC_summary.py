#!/usr/bin/env python3

# import modules
import argparse
import json
import re

# create parser Argument
parser = argparse.ArgumentParser(description="extract count information from Pairtools stats output file")

# import counts from Pairtools stats output (-PT.stats.txt) from command line argument
parser.add_argument("-PTstats", help="pairtools statistics output file [sample name].pairs.stat")
args = parser.parse_args()

# extract sample name from file name
sample_name = re.split(".pairs.stat", args.PTstats)[0]

# extract count information (read pairs = rp) and put it in a dictionary
pt_stats_dict = {}

with open(args.PTstats, "r") as pt_stats_info:
    for line in pt_stats_info:
        attrb_stats_info = line.split()
        pt_stats_dict[attrb_stats_info[0]] = float(attrb_stats_info[1])

# calculate missing cis-contact bracket and valid read pairs and add them to dictionary
cis_below_1kb = pt_stats_dict["cis"] - pt_stats_dict["cis_1kb+"]
valid_rp = pt_stats_dict["cis_1kb+"] + pt_stats_dict["trans"]

pt_stats_dict["cis_below_1kb"] = cis_below_1kb
pt_stats_dict["valid_rp"] = valid_rp

# calculate percentages
pt_stats_percent_of_total = {}
pt_stats_percent_of_valid_rp = {}
pt_stats_percent_of_nodup = {}

for stat in pt_stats_dict:
    percent_of_total = round(100 / pt_stats_dict["total"] * pt_stats_dict[stat], 2)
    pt_stats_percent_of_total[stat] = percent_of_total
    if not valid_rp == 0:
        percent_of_valid_rp = round(100 / valid_rp * pt_stats_dict[stat], 2)
        pt_stats_percent_of_valid_rp[stat] = percent_of_valid_rp
    else:
        pt_stats_percent_of_valid_rp[stat] = 0
    if not pt_stats_dict["total_nodups"] == 0:
        percent_of_nodup = round(100 / pt_stats_dict["total_nodups"] * pt_stats_dict[stat], 2)
        pt_stats_percent_of_nodup[stat] = percent_of_nodup
    else:
        pt_stats_percent_of_nodup[stat] = 0

# create .json file
pt_stats_json = {
    "samples": [
        {
            "sample name": sample_name,
            "total reads": {
                "reads": "{:,}".format(pt_stats_dict["total"]),
                "percent of total": pt_stats_percent_of_total["total"],
            },
            "mapped reads": {
                "reads": "{:,}".format(pt_stats_dict["total_mapped"]),
                "percent of total": pt_stats_percent_of_total["total_mapped"],
            },
            "duplicated reads": {
                "reads": "{:,}".format(pt_stats_dict["total_dups"]),
                "percent of total": pt_stats_percent_of_total["total_dups"],
            },
            "non-duplicated mapped reads": {
                "reads": "{:,}".format(pt_stats_dict["total_nodups"]),
                "percent of total": pt_stats_percent_of_total["total_nodups"],
                "percent of nodup": pt_stats_percent_of_nodup["total_nodups"],
            },
            "valid read pairs (cis above 1kb + trans)": {
                "reads": "{:,}".format(valid_rp),
                "percent of total": pt_stats_percent_of_total["valid_rp"],
                "percent of valid": pt_stats_percent_of_valid_rp["valid_rp"],
                "percent of nodup": pt_stats_percent_of_nodup["valid_rp"],
            },
            "trans read pairs": {
                "reads": "{:,}".format(pt_stats_dict["trans"]),
                "percent of total": pt_stats_percent_of_total["trans"],
                "percent of valid": pt_stats_percent_of_valid_rp["trans"],
                "percent of nodup": pt_stats_percent_of_nodup["trans"],
            },
            "cis read pairs": {
                "total cis": {
                    "reads": "{:,}".format(pt_stats_dict["cis"]),
                    "percent of total": pt_stats_percent_of_total["cis"],
                    "percent of valid": pt_stats_percent_of_valid_rp["cis"],
                    "percent of nodup": pt_stats_percent_of_nodup["cis"],
                },
                "cis below 1 kb": {
                    "reads": "{:,}".format(pt_stats_dict["cis_below_1kb"]),
                    "percent of total": pt_stats_percent_of_total["cis_below_1kb"],
                    "percent of valid": pt_stats_percent_of_valid_rp["cis_below_1kb"],
                    "percent of nodup": pt_stats_percent_of_nodup["cis_below_1kb"],
                },
                "cis >= 1 kb": {
                    "reads": "{:,}".format(pt_stats_dict["cis_1kb+"]),
                    "percent of total": pt_stats_percent_of_total["cis_1kb+"],
                    "percent of valid": pt_stats_percent_of_valid_rp["cis_1kb+"],
                    "percent of nodup": pt_stats_percent_of_nodup["cis_1kb+"],
                },
                "cis >= 10 kb": {
                    "reads": "{:,}".format(pt_stats_dict["cis_10kb+"]),
                    "percent of total": pt_stats_percent_of_total["cis_10kb+"],
                    "percent of valid": pt_stats_percent_of_valid_rp["cis_10kb+"],
                    "percent of nodup": pt_stats_percent_of_nodup["cis_10kb+"],
                },
            },
        }
    ]
}

# print table to terminal and save .json to file
json_out = json.dumps(pt_stats_json, indent=2)

json_out_file = sample_name + "PT_stats_summary.json"
outfile = open(json_out_file, "w")
outfile.write(json_out)

print(json_out)
