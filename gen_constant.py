import sys
import pathlib as path

if len(sys.argv) < 3:
    raise Exception("Usage: python gen_constant.py [target_dir] [output].gd")

dir = path.Path(sys.argv[1])
file = open(sys.argv[2], 'x')
file.write("class_name MinigameHeader\n")

header_set = set()

for child in dir.iterdir():
    p = path.Path(child)
    lines = []
    with p.open() as f:
        lines = f.readlines()
    for line in lines:
        if line.startswith("@"):
            header_set.add(line[1:len(line) - 1])

for header in header_set:
    file.write(f"const {header} = \"{header}\"\n")

file.close()
