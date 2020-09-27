import re

#
# Generate a kernel jump table given the existing jump table include file and the kernel.lbl file
#

labels = {}

with open("kernel.lbl", "r") as label_file:
    binding = 1
    while binding:
        binding = label_file.readline()
        m = re.search("^(\w+)\s*=\s*\$00(\w+)", binding)
        if m:
            label = m.group(1)
            value = m.group(2)
            labels[label] = value

with open("src\kernel_inc.txt", "r") as src:
    with open("src\kernel_inc.asm", "w") as dest:
        for cnt, line in enumerate(src):
            m = re.search("^(\w+)\s*=\s*\%ADDR\%", line)
            if m:
                label = m.group(1)
                if label in labels:
                    value = labels[label]
                    new_line = re.sub("\%ADDR\%", "${:06X}".format(int(value, 16)), line)
                    dest.write(new_line)
                else:
                    dest.write("; Undefined label for: {}".format(line))
            else:
                dest.write(line)
