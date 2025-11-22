import os


input_file = "MuseControlLite/requirements.txt"
output_file = "requirements_m.txt"

lines = []

# Read the input file
with open(input_file, "r") as file:
    lines = file.readlines()
    #  modify each line as pip install {line} --force-reinstall
    for i in range(len(lines)):
        lines[i] = lines[i].strip()
        lines[i] = f"!pip install {lines[i]} --force-reinstall\n"

# Write the modified lines to the output file
with open(output_file, "w") as file:
    file.writelines(lines)

# Check if the output file exists
if os.path.exists(output_file):
    print(f"Output file '{output_file}' created successfully.")
    
