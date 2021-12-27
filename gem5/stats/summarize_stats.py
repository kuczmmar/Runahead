import sys
import csv
import os
from os.path import isfile, join
import pandas as pd


def read_single_stat_file( file, config_name ):
    file1 = open(file, 'r')
    lines = file1.readlines()
    stat_dict = {'0_config': config_name}
    for line in lines:
        line = line.strip()
        if len(line) < 1:
            continue
        line_content = line.split()
        stat_dict[line_content[0]] = line_content[1]
    file1.close()
    return stat_dict

def read_file_line_by_line():
    file1 = open('./stats/targetStats.txt', 'r')
    lines = file1.readlines()
    item_list = []
    for line in lines:
        item_list.append(line.strip())
    file1.close()
    return item_list

def write_to_csv(file, data_dict):
    with open(file, 'w') as output:
        writer = csv.writer(output)
        for key, value in data_dict.items():
            writer.writerow([key, value])

prefixes = ['system.', 'cpu.', 'cpu.mmu.', 'mem_ctrl.dram.',
        'l2cache.', 'fetch.', 'branchPred.'
]

def split_name(key):
    for pref in prefixes:
        if key.startswith(pref):
            key = key.split(pref)[1]
    return key

def filter_out_stats(original_dict):
    target_stats = read_file_line_by_line()
    target_stats.append('0_config')
    
    filtered_dict = {split_name(k): v for (k, v) in original_dict.items() if k in target_stats}
    return filtered_dict

def list_all_sub_directories(directory):
    return [name for name in os.listdir(directory) if os.path.isdir(os.path.join(directory, name))]


input_directory = sys.argv[1]
output_file = sys.argv[2]

subdirectories = list_all_sub_directories(input_directory)

df = pd.DataFrame()
for dir in subdirectories:
    path = input_directory + '/' + dir
    # for f in [f for f in os.listdir(path) if isfile(join(path, f))]:
    for f in os.listdir(path):
        file_path = join(path, f)
        if isfile(file_path):
            stats = filter_out_stats(read_single_stat_file(file_path, dir +"_"+f))
            df = df.append(stats, ignore_index=True)

os.makedirs(os.path.dirname(output_file), exist_ok=True)
df.to_csv(output_file, index=False)