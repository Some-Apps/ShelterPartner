import csv

def modify_csv(input_file, output_file):
    with open(input_file, mode='r') as infile, open(output_file, mode='w', newline='') as outfile:
        reader = csv.reader(infile)
        writer = csv.writer(outfile)
        
        # Write the header
        header = next(reader)
        writer.writerow(header)
        
        # Process each row
        for row in reader:
            row[0] = 'shelter_partner_' + row[0]
            writer.writerow(row)

# File paths
base_path = '/Users/jaredjones/Documents/GitHub/ShelterPartner/Flutter/shelter_partner/assets/csv/'
files = ['cats.csv', 'dogs.csv']

for file in files:
    input_file = base_path + file
    output_file = base_path + file.replace('.csv', '_modified.csv')
    modify_csv(input_file, output_file)
