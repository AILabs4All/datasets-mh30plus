import pandas as pd
import numpy as np
from imblearn.over_sampling import SMOTE
from imblearn.over_sampling import SMOTENC
from sklearn.preprocessing import StandardScaler
from imblearn.under_sampling import RandomUnderSampler
from imblearn.over_sampling import RandomOverSampler
import argparse
import warnings
import ssl
import csv
import math
import time
import os

def argumentos():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input_dataset', type=str, required=True,
                        help='Arquivo do dataset de entrada (Formato CSV)')
    parser.add_argument('-t','--target_class', type=str, required=True,
                        help='Nome da coluna contendo a classe minoritaria')
    parser.add_argument('-s','--sampling_strategy', type=str, required=True,
                        help='metodo de sampling i.e over ou under',  choices=['undersampling','oversampling'])
    return parser.parse_args()
def validation(dataset_path):
    """Validate dataset for completeness and correctness"""
    if dataset_path is None:
        return 0
    
    try:
        samples_file = pd.read_csv(dataset_path, dtype=np.uint8)
        output_filename = dataset_path.replace('.csv', '') + "_validation_results.txt"
        
        # Use context manager for safe file handling
        with open(output_filename, "w") as f:
            if samples_file.empty:
                print("empty dataset", file=f)
                return 1
                
            columns = samples_file.columns.values.tolist()
            list_of_columns_missing_values = []
            list_of_columns_with_wrong_values = []
            
            for column_name in columns:
                # Check for missing values
                if samples_file[column_name].isnull().any():
                    missing_indices = samples_file[samples_file[column_name].isnull()].index.tolist()
                    missing_indices.append(column_name)
                    list_of_columns_missing_values.append(missing_indices)
                
                # Check for wrong values (only for non-class binary columns)
                if column_name != 'class':
                    if not samples_file[column_name].isin([0, 1]).all():
                        wrong_indices = samples_file[
                            (~samples_file[column_name].isin([0, 1])) & 
                            (samples_file[column_name].notna())
                        ].index.tolist()
                        wrong_indices.append(column_name)
                        list_of_columns_with_wrong_values.append(wrong_indices)
            
            # Report missing values
            if list_of_columns_missing_values:
                for column in list_of_columns_missing_values:
                    column_name = column[-1]
                    indices = column[:-1]
                    print(f"Column '{column_name}' has missing values at indices: {indices}", file=f)
            
            # Report wrong values
            if list_of_columns_with_wrong_values:
                for column in list_of_columns_with_wrong_values:
                    column_name = column[-1]
                    indices = column[:-1]
                    print(f"Column '{column_name}' has non-binary values at indices: {indices}", file=f)
            
            # Check class distribution
            if 'class' in samples_file.columns:
                malware_samples = samples_file['class'].value_counts().get(1, 0)
                benign_samples = samples_file['class'].value_counts().get(0, 0)
                print(f"Number of malware samples (class=1): {malware_samples}", file=f)
                print(f"Number of benign samples (class=0): {benign_samples}", file=f)
            else:
                print("'class' column not found in dataset", file=f)
            
            # Dataset statistics
            print(f"Number of columns: {len(samples_file.columns)}", file=f)
            print(f"Number of rows: {len(samples_file)}", file=f)
            
            # Check for truncated rows
            expected_columns = len(samples_file.columns)
            truncated_rows = 0
            for idx, row in samples_file.iterrows():
                if len(row) != expected_columns or row.isnull().all():
                    truncated_rows += 1
                    print(f"Row {idx} appears truncated or empty", file=f)
            
            if truncated_rows > 0:
                print(f"WARNING: Found {truncated_rows} potentially truncated rows", file=f)
            
            return len(list_of_columns_missing_values) + len(list_of_columns_with_wrong_values)
            
    except Exception as e:
        print(f"Error during validation: {e}")
        # Try to create error log
        try:
            with open(f"{dataset_path}_validation_error.txt", "w") as err_f:
                err_f.write(f"Validation failed: {str(e)}")
        except:
            pass
        return -1
if __name__ == "__main__":
    arguments = argumentos()
    print("Starting SMOTE " + arguments.sampling_strategy) 
    
    # Load and clean dataset
    dataset_file_loaded = pd.read_csv(arguments.input_dataset,dtype=np.uint8)
    dataset_file_loaded = dataset_file_loaded.dropna()
    
    # Check if target class exists
    if arguments.target_class not in dataset_file_loaded.columns:
        print(f"Error: Target class '{arguments.target_class}' not found in dataset columns")
        print(f"Available columns: {list(dataset_file_loaded.columns)}")
        exit(1)
    
    # Separate features and target
    X = dataset_file_loaded.drop(arguments.target_class, axis=1)
    y = dataset_file_loaded[arguments.target_class]
    
    class_counts = y.value_counts()
    majority_class = class_counts.idxmax()
    minority_class = class_counts.idxmin()
    if arguments.sampling_strategy == "oversampling":
        # SMOTE for oversampling the minority class
        ros = RandomOverSampler(sampling_strategy="minority", random_state=42)
        X_resampled, y_resampled = ros.fit_resample(X, y)
    elif arguments.sampling_strategy == "undersampling":
        # RandomUnderSampler for undersampling the majority class
        rus = RandomUnderSampler(sampling_strategy='majority', random_state=42)
        X_resampled, y_resampled = rus.fit_resample(X, y)
 
    resampled_df = resampled_df = pd.concat(
    [pd.DataFrame(y_resampled), pd.DataFrame(X_resampled)],
    axis=1,)
    
    # Generate output filename based on sampling strategy
    base_name = arguments.input_dataset.replace('.csv', '')
    new_file_name = f"{base_name}_balanced_{arguments.sampling_strategy}.csv"
    
    # Save the resampled dataset
    resampled_df.to_csv(new_file_name, index=False, sep=',', header=True)
    
    # Print statistics
    print("\n" + "="*50)
    print(f"Sampling completed!")
    print(f"Resampled dataset saved as: {new_file_name}")
    print(f"Original dataset shape: {dataset_file_loaded.shape}")
    print(f"Resampled dataset shape: {resampled_df.shape}")
    print(f"Original class distribution:\n{y.value_counts().to_dict()}")
    print(f"Resampled class distribution:\n{pd.Series(y_resampled).value_counts().to_dict()}")
    os.sync() if hasattr(os, 'sync') else None

# Small delay to ensure file is written
    time.sleep(0.5)

    # Now validate
    # Validate the new file
    validation(new_file_name)
