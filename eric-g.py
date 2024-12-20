import os
import csv

def sum_cores_in_csv_files(root_folder):
    total_cores = 0
    
    # Walk through directories recursively to find CSV files named RVTools_tabvHost.csv
    for foldername, subfolders, filenames in os.walk(root_folder):
        for filename in filenames:
            if filename == 'RVTools_tabvHost.csv':
                file_path = os.path.join(foldername, filename)
                
                try:
                    with open(file_path) as csvfile:
                        reader = csv.reader(csvfile)
                        
                        # Find the index of '# Cores' column
                        headers = next(reader)
                        cores_index = None
                        for idx, header in enumerate(headers):
                            if header == "# Cores":
                                cores_index = idx
                                break
                        
                        if cores_index is not None:
                            core_count = 0
                            for row in reader:
                                try:
                                    core_value = int(row[cores_index])
                                    core_count += core_value
                                except ValueError:
                                    pass
                        
                    print(f"Processed file: {file_path}")
                    total_cores += core_count
                    
                except Exception as e:
                    print(f"Error processing file {file_path}: {str(e)}")
    
    return total_cores

if __name__ == "__main__":
    root_folder = "."
    if not os.path.exists(root_folder):
        raise ValueError("The provided path does not exist.")
        
    print(f"Sum of all cores found in RVTools_tabvHost.csv files under the current directory:")
    print(sum_cores_in_csv_files(root_folder))
