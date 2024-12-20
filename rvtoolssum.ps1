import os
import pandas as pd
import warnings

NUMBER_OF_CLUSTERS = 3  # Change this to the actual number of clusters

# Function to process a single Excel file for vCPUs
def process_excel_vcpu(file_path):
    try:
        # Read the Excel file, ignoring any formatting or styles
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            excel_data = pd.read_excel(file_path, sheet_name="vCPU", engine="openpyxl", keep_default_na=False)
        
        # Filter out rows where "VM Name" column contains "vCLS" or "NTNX"
        filtered_data = excel_data[~excel_data['VM Name'].str.contains('vCLS|NTNX')].copy()  # Make a copy to avoid SettingWithCopyWarning
        
        # Convert 'vCPUs' column to numeric and handle errors
        filtered_data.loc[:, 'vCPUs'] = pd.to_numeric(filtered_data['vCPUs'], errors='coerce')
        
        # Drop rows with NaN values (due to conversion errors)
        filtered_data.dropna(subset=['vCPUs'], inplace=True)
        
        # Sum the values in the "vCPUs" column
        total_vcpus = filtered_data['vCPUs'].sum()
        
        return total_vcpus
    
    except Exception as e:
        print(f"Error processing vCPU in file '{file_path}': {e}")
        return 0

# Function to process a single Excel file for vMemory
def process_excel_vmemory(file_path):
    try:
        # Read the Excel file, ignoring any formatting or styles
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            excel_data = pd.read_excel(file_path, sheet_name="vMemory", engine="openpyxl", keep_default_na=False)
        
        # Filter out rows where "VM Name" column contains "vCLS" or "NTNX"
        filtered_data = excel_data[~excel_data['VM Name'].str.contains('vCLS|NTNX')].copy()  # Make a copy to avoid SettingWithCopyWarning
        
        # Convert 'Size (MiB)' column to numeric and handle errors
        filtered_data.loc[:, 'Size (GiB)'] = pd.to_numeric(filtered_data['Size (MiB)'], errors='coerce') / 1024  # Convert MiB to GiB
        
        # Drop rows with NaN values (due to conversion errors)
        filtered_data.dropna(subset=['Size (GiB)'], inplace=True)
        
        # Sum the values in the "Size (GiB)" column
        total_memory = filtered_data['Size (GiB)'].sum()
        
        return total_memory
    
    except Exception as e:
        print(f"Error processing vMemory in file '{file_path}': {e}")
        return 0

# Function to process a single Excel file for vPartition
def process_excel_vpartition(file_path):
    try:
        # Read the Excel file, ignoring any formatting or styles
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            excel_data = pd.read_excel(file_path, sheet_name="vPartition", engine="openpyxl", keep_default_na=False)
        
        # Filter out rows where "VM Name" column contains "vCLS" or "NTNX"
        filtered_data = excel_data[~excel_data['VM Name'].str.contains('vCLS|NTNX')].copy()  # Make a copy to avoid SettingWithCopyWarning
        
        # Convert 'Capacity (MiB)' column to numeric and handle errors
        filtered_data.loc[:, 'Capacity (TiB)'] = pd.to_numeric(filtered_data['Capacity (MiB)'], errors='coerce') / (1024 ** 2)  # Convert MiB to TiB
        
        # Drop rows with NaN values (due to conversion errors)
        filtered_data.dropna(subset=['Capacity (TiB)'], inplace=True)
        
        # Sum the values in the "Capacity (TiB)" column
        total_partition = filtered_data['Capacity (TiB)'].sum()
        
        return total_partition
    
    except Exception as e:
        print(f"Error processing vPartition in file '{file_path}': {e}")
        return 0

# Function to iterate through all Excel files in the current directory
def process_excel_folder():
    total_vcpus = 0
    total_memory = 0
    total_partition = 0
    total_virtual_machines = 0
    
    # Get the current directory
    current_directory = os.getcwd()
    
    # Iterate through each file in the current directory
    for filename in os.listdir(current_directory):
        if filename.endswith('.xlsx'):  # Check if the file is an Excel file
            file_path = os.path.join(current_directory, filename)
            total_vcpus += process_excel_vcpu(file_path)
            total_memory += process_excel_vmemory(file_path)
            total_partition += process_excel_vpartition(file_path)
            total_virtual_machines += count_virtual_machines(file_path)
    
    return total_vcpus, total_memory, total_partition, total_virtual_machines

# Function to count the total number of virtual machines in a single Excel file
def count_virtual_machines(file_path):
    try:
        # Read the Excel file, ignoring any formatting or styles
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            excel_data = pd.read_excel(file_path, sheet_name="vCPU", engine="openpyxl", keep_default_na=False)
        
        # Filter out rows where "VM Name" column contains "vCLS" or "NTNX"
        filtered_data = excel_data[~excel_data['VM Name'].str.contains('vCLS|NTNX')]
        
        # Count the number of rows (virtual machines)
        total_virtual_machines = filtered_data.shape[0]
        
        return total_virtual_machines
    
    except Exception as e:
        print(f"Error counting virtual machines in file '{file_path}': {e}")
        return 0

# Main function
def main():
    total_vcpus, total_memory, total_partition, total_virtual_machines = process_excel_folder()
    print("Total vCPUs from all files in the current directory:", total_vcpus)
    print("Total Memory from all files in the current directory (in GiB):", total_memory)
    print("Total Partition Capacity from all files in the current directory (in TiB):", total_partition)
    print("Total Virtual Machines from all files in the current directory:", total_virtual_machines)
    print("Number of Clusters:", NUMBER_OF_CLUSTERS)
    print("Results divided by the number of clusters:")
    print("Total vCPUs per Cluster:", total_vcpus / NUMBER_OF_CLUSTERS)
    print("Total Memory per Cluster (in GiB):", total_memory / NUMBER_OF_CLUSTERS)
    print("Total Partition Capacity per Cluster (in TiB):", total_partition / NUMBER_OF_CLUSTERS)

if __name__ == "__main__":
    main()
