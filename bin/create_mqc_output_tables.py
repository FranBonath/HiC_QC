#!/usr/bin/env python3

# import modules
import argparse
import json

# create parser Argument
parser = argparse.ArgumentParser(description="generate output table to use in MultiQC report generation")

# import counts from Pairtools stats output (-PT.stats.txt) from command line argument
parser.add_argument("-js_file", help="list of .json files outputted by md_js_QC_summary.py")
args = parser.parse_args()

# define output tables
json_files = open(args.js_file, "r").readlines()
basic_data = {
    "id": "custom_table_basic",
    "plot_type": "table",
    "section_name": "Basic Reads Statistic",
    "description": "Reads per sample, reads mapping to the provided genome, duplicated reads based on pairtools and non-duplicated and mapped reads.",
    "data": {},
}

cis_rp_data = {
    "id": "custom_table_cis_rp",
    "plot_type": "table",
    "section_name": "Cis Read Pairs",
    "description": "Reads in the pair are located on the same chromosome. Cis read pairs are further defined by the distance between the reads in base pairs.",
    "data": {},
}

trans_rp_data = {
    "id": "custom_table_trans_rp",
    "plot_type": "table",
    "section_name": "Trans Read Pairs",
    "description": "Reads in the pairs are located on different chromosomes",
    "data": {},
}

valid_rp_data = {
    "id": "custom_table_valid_rp",
    "plot_type": "table",
    "section_name": "Valid Read Pairs",
    "description": "Valid read pairs are comprised of cis read pairs > 1kb and trans read pairs",
    "data": {},
}

barplot_data = {
    "id": "custom_data_basic_bargraph",
    "plot_type": "bargraph",
    "section_name": "Overview HiC reads",
    "description": "Graphic representation of reads lost to mapping, de-duplication and short-distance",
    "pconfig": {
        "id": "custom_data_bargraph",
        "stacking": None,
    },
    "data": {},
}

# iterate through the different json files and extract info
for json_file_single in json_files:
    js_stats_dict = {}
    json_file = open(json_file_single.rstrip())
    json_data = json.load(json_file)

    for i in json_data["samples"]:
        sample_name = i["sample name"]

        # extract information (read pairs = rp) and put it in a dictionary
        barplot_data_single = {
            i["sample name"]: {
                "total": float(i["total reads"]["reads"]),
                "mapped": float(i["mapped reads"]["reads"]),
                "duplicates": float(i["duplicated reads"]["reads"]),
                "valid": float(i["valid read pairs (cis above 1kb + trans)"]["reads"]),
            },
        }
        barplot_data["data"][i["sample name"]] = barplot_data_single[i["sample name"]]

        basic_data_single = {
            i["sample name"]: {
                "total": str(i["total reads"]["reads"]),
                "mapped (% of total)": str(i["mapped reads"]["reads"])
                + " ("
                + str(i["mapped reads"]["percent of total"])
                + ")",
                "duplicates (% of total)": str(i["duplicated reads"]["reads"])
                + " ("
                + str(i["duplicated reads"]["percent of total"])
                + ")",
                "non-duplicates mapped (% of mapped)": str(i["non-duplicated mapped reads"]["reads"])
                + " ("
                + str(i["non-duplicated mapped reads"]["percent of total"])
                + ")",
            },
        }
        basic_data["data"][i["sample name"]] = basic_data_single[i["sample name"]]

        # create cis read pairs .json file
        cis_rp_data_single = {
            i["sample name"]: {
                "total (%total/ %valid/ %nodup)": str(i["cis read pairs"]["total cis"]["reads"])
                + " ("
                + str(i["cis read pairs"]["total cis"]["percent of total"])
                + " / "
                + str(i["cis read pairs"]["total cis"]["percent of valid"])
                + " / "
                + str(i["cis read pairs"]["total cis"]["percent of nodup"])
                + ")",
                "< 1 kb (%total/ %valid/ %nodup)": str(i["cis read pairs"]["cis below 1 kb"]["reads"])
                + " ("
                + str(i["cis read pairs"]["cis below 1 kb"]["percent of total"])
                + " / "
                + str(i["cis read pairs"]["cis below 1 kb"]["percent of valid"])
                + " / "
                + str(i["cis read pairs"]["cis below 1 kb"]["percent of nodup"])
                + ")",
                ">= 1 kb (%total/ %valid/ %nodup)": str(i["cis read pairs"]["cis >= 1 kb"]["reads"])
                + " ("
                + str(i["cis read pairs"]["cis >= 1 kb"]["percent of total"])
                + " / "
                + str(i["cis read pairs"]["cis >= 1 kb"]["percent of valid"])
                + " / "
                + str(i["cis read pairs"]["cis >= 1 kb"]["percent of nodup"])
                + ")",
                ">= 10 kb (%total/ %valid/ %nodup)": str(i["cis read pairs"]["cis >= 10 kb"]["reads"])
                + " ("
                + str(i["cis read pairs"]["cis >= 10 kb"]["percent of total"])
                + " / "
                + str(i["cis read pairs"]["cis >= 10 kb"]["percent of valid"])
                + " / "
                + str(i["cis read pairs"]["cis >= 10 kb"]["percent of nodup"])
                + ")",
            },
        }
        cis_rp_data["data"][i["sample name"]] = cis_rp_data_single[i["sample name"]]

        # create trans read pairs .json file

        trans_rp_data_single = {
            i["sample name"]: {
                "trans rp, reads": str(i["trans read pairs"]["reads"]),
                "trans rp, %total": str(i["trans read pairs"]["percent of total"]),
                "trans rp, %valid": str(i["trans read pairs"]["percent of valid"]),
                "trans rp, %nodup": str(i["trans read pairs"]["percent of nodup"]),
            },
        }
        trans_rp_data["data"][i["sample name"]] = trans_rp_data_single[i["sample name"]]

        # create valid read pairs .json file
        valid_rp_data_single = {
            i["sample name"]: {
                "val rp, reads)": str(i["valid read pairs (cis above 1kb + trans)"]["reads"]),
                "val rp, %total": str(i["valid read pairs (cis above 1kb + trans)"]["percent of total"]),
                "val rp, %nodup": str(i["valid read pairs (cis above 1kb + trans)"]["percent of nodup"]),
            },
        }
        valid_rp_data["data"][i["sample name"]] = valid_rp_data_single[i["sample name"]]


# print table to terminal and save .json to file
json_basic_out = json.dumps(basic_data, indent=2)
json_cis_rp_out = json.dumps(cis_rp_data, indent=2)
json_trans_rp_out = json.dumps(trans_rp_data, indent=2)
json_valid_out = json.dumps(valid_rp_data, indent=2)
json_barplot_out = json.dumps(barplot_data, indent=2)

json_barplot_out_file = sample_name + "_barplot_stats_mqc.json"
barplot_outfile = open(json_barplot_out_file, "w")
barplot_outfile.write(json_barplot_out)

json_basic_out_file = sample_name + "_basic_stats_mqc.json"
basic_outfile = open(json_basic_out_file, "w")
basic_outfile.write(json_basic_out)

json_cis_rp_out_file = sample_name + "_cis_read_pairs_mqc.json"
cis_outfile = open(json_cis_rp_out_file, "w")
cis_outfile.write(json_cis_rp_out)

json_trans_rp_out_file = sample_name + "_trans_read_pairs_mqc.json"
trans_outfile = open(json_trans_rp_out_file, "w")
trans_outfile.write(json_trans_rp_out)

json_valid_out_file = sample_name + "_valid_read_pairs_mqc.json"
valid_outfile = open(json_valid_out_file, "w")
valid_outfile.write(json_valid_out)
