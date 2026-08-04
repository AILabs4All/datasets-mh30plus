import pandas as pd
import numpy as np
from imblearn.over_sampling import SMOTE
from imblearn.over_sampling import ADASYN
from imblearn.over_sampling import BorderlineSMOTE
from imblearn.over_sampling import KMeansSMOTE
from imblearn.under_sampling import RandomUnderSampler
from imblearn.over_sampling import RandomOverSampler
from imblearn.under_sampling import TomekLinks
from imblearn.under_sampling import EditedNearestNeighbours
from imblearn.under_sampling import NearMiss
from imblearn.under_sampling import ClusterCentroids
import argparse
import time
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import f1_score
from sklearn.metrics import log_loss
from sklearn.metrics import mean_squared_error
from sklearn.metrics import pairwise
from sklearn.model_selection import train_test_split
def __get_instance_random_forest(x_samples_training, y_samples_training, dataset_type= 'int8'):


        x_samples_training = np.array(x_samples_training, dtype=dataset_type)
        y_samples_training = np.array(y_samples_training, dtype=dataset_type)

        instance_model_classifier = RandomForestClassifier(n_estimators=100,
                                                           max_depth=None,
                                                           max_leaf_nodes=None)
        instance_model_classifier.fit(x_samples_training, y_samples_training)


        return instance_model_classifier

def list_of_strs(arg):
    return list(map(str, arg.split(',')))

SAMPLING_METHODS = {
    "random_over": {
        "strategy": "oversampling",
        "sampler": lambda: RandomOverSampler(sampling_strategy="minority", random_state=42),
        "synthetic": False
    },
    "smote": {
        "strategy": "oversampling",
        "sampler": lambda: SMOTE(sampling_strategy="minority", random_state=42),
        "synthetic": True
    },
    "adasyn": {
        "strategy": "oversampling",
        "sampler": lambda: ADASYN(sampling_strategy="minority", random_state=42),
        "synthetic": True
    },
    "borderline_smote": {
        "strategy": "oversampling",
        "sampler": lambda: BorderlineSMOTE(sampling_strategy="minority", random_state=42),
        "synthetic": True
    },
    "random_under": {
        "strategy": "undersampling",
        "sampler": lambda: RandomUnderSampler(sampling_strategy="majority", random_state=42),
        "synthetic": False
    },
    "tomek_links": {
        "strategy": "undersampling",
        "sampler": lambda: TomekLinks(),
        "synthetic": False
    },
    "enn": {
        "strategy": "undersampling",
        "sampler": lambda: EditedNearestNeighbours(),
        "synthetic": False
    },
    "nearmiss": {
        "strategy": "undersampling",
        "sampler": lambda: NearMiss(version=1),
        "synthetic": False
    }
}


def argumentos():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input_dataset', type=str, required=False,
                        help='Arquivo do dataset de entrada (Formato CSV)')
    parser.add_argument('-d', '--input_dir', type=str, required=False,
                        help='Pasta com datasets CSV para processar em lote')
    parser.add_argument('-o', '--output_dir', type=str, required=False,
                        help='Pasta de saida para os datasets balanceados')
    parser.add_argument('-t','--target_class', type=str, required=True,
                        help='Nome da coluna contendo a classe minoritaria')
    parser.add_argument('-s','--sampling_strategy', type=str, required=True,
                        help='metodo de sampling i.e over ou under',  choices=['undersampling','oversampling'])
    parser.add_argument(
        '-m', '--sampling_method',
        type=str,
        required=False,
        default=None,
        choices=list(SAMPLING_METHODS.keys()),
        help=(
            "Tecnica de balanceamento. "
            "Over: random_over, smote, adasyn, borderline_smote, kmeans_smote. "
            "Under: random_under, tomek_links, enn, nearmiss, cluster_centroids. "
            "Obs.: tomek_links e enn aplicam RandomUnderSampler apos a limpeza para balancear o dataset."
        )
    )
    return parser.parse_args()


def validation(dataset_path, target_column):
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
                if column_name != target_column:
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
            if target_column in samples_file.columns:
                malware_samples = samples_file[target_column].value_counts().get(1, 0)
                benign_samples = samples_file[target_column].value_counts().get(0, 0)
                print(f"Number of malware samples (class=1): {malware_samples}", file=f)
                print(f"Number of benign samples (class=0): {benign_samples}", file=f)
            else:
                print(f"'{target_column}' column not found in dataset", file=f)

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


def resolve_inputs(arguments):
    has_file = bool(arguments.input_dataset)
    has_dir = bool(arguments.input_dir)
    if has_file == has_dir:
        print("Error: informe exatamente um entre --input_dataset ou --input_dir.")
        exit(1)

    if has_file:
        if not os.path.isfile(arguments.input_dataset):
            print(f"Error: arquivo nao encontrado: {arguments.input_dataset}")
            exit(1)
        return [arguments.input_dataset]

    if not os.path.isdir(arguments.input_dir):
        print(f"Error: pasta nao encontrada: {arguments.input_dir}")
        exit(1)

    dataset_files = sorted(
        [
            os.path.join(arguments.input_dir, file_name)
            for file_name in os.listdir(arguments.input_dir)
            if file_name.lower().endswith(".csv")
        ]
    )
    if not dataset_files:
        print(f"Error: nenhum arquivo CSV encontrado em: {arguments.input_dir}")
        exit(1)
    return dataset_files


def output_path_for(input_path, output_dir, sampling_strategy, method):
    input_base = os.path.splitext(os.path.basename(input_path))[0]
    output_name = f"{input_base}_balanced_{sampling_strategy}_{method}.csv"
    if output_dir:
        return os.path.join(output_dir, output_name)
    input_folder = os.path.dirname(input_path) or "."
    return os.path.join(input_folder, output_name)


def apply_sampler(method, X, y):
    if method == "tomek_links":
        X_tmp, y_tmp = TomekLinks().fit_resample(X, y)
        return RandomUnderSampler(sampling_strategy="majority", random_state=42).fit_resample(X_tmp, y_tmp)
    if method == "enn":
        X_tmp, y_tmp = EditedNearestNeighbours().fit_resample(X, y)
        return RandomUnderSampler(sampling_strategy="majority", random_state=42).fit_resample(X_tmp, y_tmp)

    sampler = SAMPLING_METHODS[method]["sampler"]()
    return sampler.fit_resample(X, y)


def process_dataset(input_path, arguments, method):
    print(f"\nProcessing: {input_path}")
    dataset_file_loaded = pd.read_csv(input_path, dtype=np.uint8)
    dataset_file_loaded = dataset_file_loaded.dropna()

    if arguments.target_class not in dataset_file_loaded.columns:
        print(f"Error: Target class '{arguments.target_class}' not found in dataset columns")
        print(f"Available columns: {list(dataset_file_loaded.columns)}")
        return False

    X = dataset_file_loaded.drop(arguments.target_class, axis=1)
    y = dataset_file_loaded[arguments.target_class]

    unique_classes = sorted(y.unique().tolist())
    if len(unique_classes) != 2 or set(unique_classes) != {0, 1}:
        print(
            f"Error: O target '{arguments.target_class}' precisa ser binario com valores 0 e 1. "
            f"Valores encontrados: {unique_classes}"
        )
        return False

    selected_method = SAMPLING_METHODS[method]
    X_resampled, y_resampled = apply_sampler(method, X, y)


    X_resampled_df = pd.DataFrame(X_resampled, columns=X.columns)
    X_resampled_df = (X_resampled_df >= 0.5).astype(np.uint8)
    y_resampled_series = pd.Series(y_resampled, name=arguments.target_class)
    y_resampled_series = y_resampled_series.astype(np.uint8).clip(0, 1)

    resampled_df = pd.concat([y_resampled_series, X_resampled_df], axis=1)
    new_file_name = output_path_for(
        input_path,
        arguments.output_dir,
        arguments.sampling_strategy,
        method
    )
    resampled_df.to_csv(new_file_name, index=False, sep=',', header=True)

    print("\n" + "="*50)
    print("Sampling completed!")
    print(f"Resampled dataset saved as: {new_file_name}")
    print(f"Original dataset shape: {dataset_file_loaded.shape}")
    print(f"Resampled dataset shape: {resampled_df.shape}")
    print(f"Original class distribution:\n{y.value_counts().to_dict()}")
    print(f"Resampled class distribution:\n{y_resampled_series.value_counts().to_dict()}")
    os.sync() if hasattr(os, 'sync') else None
    time.sleep(0.5)
    validation(new_file_name, arguments.target_class)


    X_train, X_test, y_train, y_test = train_test_split(X.values, y.values, test_size=0.20, random_state=42)
    X_train_mod, X_test_mod, y_train_mod, y_test_mod = train_test_split(
        X_resampled_df.values, y_resampled_series.values, test_size=0.20, random_state=42
    )


    rd = __get_instance_random_forest(X_train, y_train)

    y_predicted_mod = rd.predict(X_test_mod)
    y_predicted = rd.predict(X_test)
    output_filename = new_file_name.replace('.csv', '') + "_metrics_results.txt"
    with open(output_filename, "w") as f:
            print("\nMétricas testando com os dados reais:", file=f)
            print("Acurácia:", accuracy_score(y_test, y_predicted), file=f)
            print("Precisão:", precision_score(y_test, y_predicted), file=f)
            print("Recall:", recall_score(y_test, y_predicted), file=f)
            print("F1-Score:", f1_score(y_test, y_predicted), file=f)

            print("\nMétricas testando com os dados transformados:", file=f)
            print("Acurácia:", accuracy_score(y_test_mod, y_predicted_mod), file=f)
            print("Precisão:", precision_score(y_test_mod, y_predicted_mod), file=f)
            print("Recall:", recall_score(y_test_mod, y_predicted_mod), file=f)
            print("F1-Score:", f1_score(y_test_mod, y_predicted_mod), file=f)

    return True

if __name__ == "__main__":
    arguments = argumentos()
    method = arguments.sampling_method
    if method is None:
        method = "random_over" if arguments.sampling_strategy == "oversampling" else "random_under"
    print(f"Starting {method} ({arguments.sampling_strategy})")
    selected_method = SAMPLING_METHODS[method]
    if selected_method["strategy"] != arguments.sampling_strategy:
        print(
            f"Error: Metodo '{method}' pertence a '{selected_method['strategy']}' "
            f"e nao a '{arguments.sampling_strategy}'."
        )
        exit(1)
    if arguments.output_dir:
        os.makedirs(arguments.output_dir, exist_ok=True)

    input_files = resolve_inputs(arguments)
    success = 0
    failed = 0
    for dataset_path in input_files:
        try:
            if process_dataset(dataset_path, arguments, method):
                success += 1
            else:
                failed += 1
        except Exception as e:
            failed += 1
            print(f"Error processing '{dataset_path}': {e}")

    print("\n" + "="*50)
    print(f"Finished. Success: {success} | Failed: {failed}")
