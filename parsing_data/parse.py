import os
import subprocess
from Gem5McPATParser import parse_data
import shutil
# python3 Gem5McPATParser.py -c  ../m5out_copy/base/rob192_10k_config.json -s ../m5out_copy/base/rob192_10k_128kB -t template_x86.xml

print("Begin parsing!")
input_stats_dir = "../gem5/m5out"
print_lvl = '5'

# directories with respect to the cmd_dir:
mcpat = "../mcpat/mcpat"
output_dir = "mcpat_out"
mcpat_in_dir = "mcpat_in"

python = "python3 Gem5McPATParser.py"
template = "template_x86.xml"

def mkdir(dir):
    try:
        os.makedirs(dir)
    except FileExistsError:
        pass

def rmdir(dir):
    if os.path.exists(dir):
        shutil.rmtree(dir)

def list_all_sub_directories(directory):
    return [name for name in os.listdir(directory) \
      if os.path.isdir(os.path.join(directory, name))]

# clean directories before computing
rmdir(output_dir)
rmdir(mcpat_in_dir)
mkdir(output_dir)
mkdir(mcpat_in_dir)

subdirs = list_all_sub_directories(input_stats_dir)

for subdir in subdirs:
    path = input_stats_dir + "/" + subdir
    for f in os.listdir(path):
        # only pick the files with gem5 statistics
        # these don't have '_config' in their name
        if '_config' not in f:
            stats_path = path + "/" + f
            config_path = path + "/" + f + "_config.json"
            out = os.path.join(output_dir, subdir + '_' + f + '.txt')
            out = open(out, "x")
            mcpat_in = os.path.join(mcpat_in_dir, subdir + '_' + f + '.xml')

            parse_data(stats_path, config_path, template, mcpat_in)
            cmd = "./mcpat/mcpat -infile " + mcpat_in + " -print_level " + print_lvl
            print(cmd)
            subprocess.Popen(cmd, shell=True, stdout=out)

os.wait()
