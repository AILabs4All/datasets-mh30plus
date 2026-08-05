# 📊 Android Malware Datasets — Original, Reduced & Balanced Versions

This artifact provides Android malware detection datasets in three versions — **original**, **dimensionality-reduced**, and **class-balanced** — together with the `sampling_script.py` script (balancing and validation metrics) and the `maldatagen_execution.sh` script, which runs the full synthetic data generation pipeline using an **Autoencoder (AE)** and a **Variational Autoencoder (VAE)** on the balanced datasets.

> The original and reduced datasets are provided as-is in the repository. The scripts in this artifact perform **class balancing** (over/undersampling) and **synthetic data generation** (AE/VAE) on top of them; the dimensionality reduction itself is not re-executed here.

The goal is to support the reproduction of the experiments in the associated paper, which analyzes how **class balancing** and **dimensionality reduction** affect Android malware detection, using Recall, F1-score, and execution time as metrics. More broadly, the datasets can also support related research on malware detection and synthetic data generation.

> **Associated paper:** _When Balancing Harms: Structural Conditions That Degrade Android Malware Detection After Class Imbalance Correction_
>
> **Abstract:** Class imbalance is a recurrent challenge in Android malware detection, and class balancing is often adopted to improve minority-class detection. This paper compares original, dimensionality-reduced, and class-balanced versions of 11 Android malware datasets, using Recall, F1-score, and execution time. Dimensionality reduction followed by class balancing improved performance in 7 of the 11 datasets; in MH100k, this combination increased Recall from 0.63 to 0.99 and reduced execution time by approximately 99%. However, class balancing reduced performance in 4 datasets, especially in cases characterized by high sparsity, reduced diversity, or near-balanced class distributions, indicating that it should be empirically validated rather than applied by default.

---

# 📑 README structure

This README is organized into the following sections:

| Section | Description |
| ------- | ----------- |
| **Considered Badges** | Badges submitted for evaluation |
| **Basic information** | Execution environment, hardware, and software |
| **Dependencies** | Libraries, versions, and datasets used |
| **Security concerns** | Risks of running the artifact |
| **Installation** | Step-by-step environment setup |
| **Minimal test** | Quick run to validate the installation |
| **Experiments** | Reproduction of the paper's claims |
| **LICENSE** | Artifact license |

Repository layout:

```
datasets-mh30plus/
├── Originais/                  # Complete datasets (all features)
├── Reduzidos/                  # Datasets after feature selection
├── Balanceados/                # Balanced datasets (under/oversampling)
├── Backup/                     # Data backups
├── sampling_script.py          # Balancing and evaluation script
├── maldatagen_execution.sh     # AE/VAE pipeline (synthetic data generation)
├── requirements.txt            # Python dependencies
├── .gitattributes              # Git LFS configuration for the CSVs
└── README.md
```

---

# 🏅 Considered Badges

The badges considered for this artifact are: **Available (SeloD)**, **Functional (SeloF)**, and **Sustainable (SeloS)**.


---

# ⚙️ Basic information

The artifact consists of:

1. **Datasets** in CSV format (original, reduced, and balanced).
2. **`sampling_script.py`** — applies balancing techniques and generates validation metrics using a **Random Forest** classifier.
3. **`maldatagen_execution.sh`** — clones the [`Maldatagen_additional_metrics`](https://github.com/MalwareDataLab/Maldatagen_additional_metrics) repository, moves the balanced datasets, and runs the synthetic data generation experiments with **AE** and **VAE**.

### Tested execution environment

- **Operating system:** Ubuntu 22.04 LTS (Linux x86-64)
- **Python:** 3.10+
- **Architecture:** x86-64

### Hardware requirements

- **CPU:** 4 cores or more (recommended)
- **RAM:** minimum **16 GB**; **64 GB** recommended for the larger datasets (`mh100k` and `androcrawl`)
- **Disk:** approximately **10–50 GB** free for the datasets and outputs
- **GPU (optional):** recommended for the AE/VAE experiments, which train for 300 epochs with 5-fold validation

> ⏱️ **Expected runtimes:**
> - Balancing (`sampling_script.py`): seconds to a few minutes per dataset.
> - AE/VAE pipeline (`maldatagen_execution.sh`): **several hours per experiment** (2 models × N datasets). A GPU and background execution are recommended.

---

# 📦 Dependencies

### Balancing (`sampling_script.py`)

Dependencies are listed in `requirements.txt`:

| Library            | Minimum version |
| ------------------ | --------------- |
| `pandas`           | ≥ 1.3.0         |
| `numpy`            | ≥ 1.21.0        |
| `scikit-learn`     | ≥ 1.0.0         |
| `imbalanced-learn` | ≥ 0.9.0         |
| `scipy`            | ≥ 1.7.0         |
| `joblib`           | ≥ 1.1.0         |

### AE/VAE pipeline (`maldatagen_execution.sh`)

In addition to the above, the pipeline requires the external `Maldatagen_additional_metrics` repository and its dependencies (installed automatically by the script from that repository's `requirements.txt`, or, if absent, `tensorflow`, `keras`, `matplotlib`, and `seaborn`). **`git`** and **`python3`** must also be available on the `PATH`.

**Datasets used** (included in the repository, under `Originais/`, `Reduzidos/`, and `Balanceados/`):

| Dataset | Selection | Features (Full) | Features (Red.) | Under (Ben/Mal) | Over (Ben/Mal) | Undersampling | Oversampling |
| ------- | --------- | --------------- | --------------- | --------------- | -------------- | ------------- | ------------ |
| `mh100k` | statistical | 24,833 | 93 | 9,800 | 92,175 | ENN + RandomUnderSampler | RandomOverSampler |
| `kronodroid_real_device` | statistical | 286 | 29 | 36,755 | 41,382 | ENN + RandomUnderSampler | ADASYN |
| `kronodroid_emulator` | statistical | 286 | 25 | 28,745 | 35,246 | ENN + RandomUnderSampler | SMOTE |
| `drebin215` | rfe | 215 | 64 | 5,555 | 9,476 | ENN + RandomUnderSampler | SMOTE |
| `defensedroid_prs` | semidroid | 2,877 | 144 | 5,975 | 6,000 | ENN + RandomUnderSampler | RandomOverSampler |
| `defensedroid_apicalls_katz` | rfe | 6,002 | 300 | 5,222 | 5,254 | ENN + RandomUnderSampler | RandomOverSampler |
| `defensedroid_apicalls_degree` | rfe | 6,002 | 300 | 5,222 | 5,254 | ENN + RandomUnderSampler | RandomOverSampler |
| `defensedroid_apicalls_closeness` | rfe | 4,274 | 213 | 5,222 | 5,254 | ENN + RandomUnderSampler | RandomOverSampler |
| `android_permissions` | statistical | 151 | 13 | 9,077 | 17,787 | ENN + RandomUnderSampler | SMOTE |
| `androcrawl` | statistical | 141 | 12 | 10,170 | 86,574 | NearMiss | SMOTE |
| `adroit` | rfe | 166 | 66 | 3,418 | 8,058 | NearMiss | RandomOverSampler |

> 📁 **Note:** the CSV files are versioned with **Git LFS** (see `.gitattributes`). Git LFS must be installed to download the data correctly.

**Third-party resource access:** the datasets are already included in the repository. The AE/VAE pipeline automatically clones the public `Maldatagen_additional_metrics` repository from GitHub — no keys or credentials are required.

---

# 🔒 Security concerns

Running this artifact **poses no risk** to reviewers.

The datasets contain only numerical feature vectors (binary attributes and the class label), **with no malware binaries, executables, or real malicious samples**. The scripts only read CSV files, resample data, train models, and generate synthetic data.

> ⚠️ **Note:** `maldatagen_execution.sh` **clones an external GitHub repository** and **installs dependencies via `pip`**. It is recommended to run it inside a virtual environment (`venv`) or container to isolate installations from the reviewer's system.

---

# 💾 Installation

### 1. Install Git LFS

Required to download the CSVs:

```bash
sudo apt-get update && sudo apt-get install -y git-lfs git
git lfs install
```

### 2. Clone the repository

```bash
git clone https://github.com/AILabs4All/datasets-mh30plus.git
cd datasets-mh30plus
git lfs pull
```

### 3. Create a virtual environment and install dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Verify the installation

```bash
python sampling_script.py --help
```

This command should display the script's help with its options, indicating the environment is ready.

---

# ✅ Minimal test

The minimal test applies a simple, fast *oversampling* method to a single reduced dataset, validating the full balancing pipeline (**read → balance → validate → metrics**), without relying on the time-consuming AE/VAE training.

```bash
python sampling_script.py \
  --input_dataset Reduzidos/drebin215.csv \
  --target_class class \
  --sampling_strategy oversampling \
  --sampling_method random_over \
  --output_dir saida_teste
```

> 📝 Adjust `--target_class` to the actual label column name in the CSV (e.g., `class`), and the file path if the name under `Reduzidos/` differs.

**Expected result:** upon completion (a few seconds to a few minutes), the `saida_teste/` folder will contain:

- `drebin215_balanced_oversampling_random_over.csv` — the balanced dataset
- `..._validation_results.txt` — validation report (class counts, missing/invalid values, number of rows and columns)
- `..._metrics_results.txt` — metrics (accuracy, precision, recall, F1) of the Random Forest evaluated on the real and transformed data

The terminal will show the original and resampled shapes, along with the class distributions before and after balancing.

---

# 🧪 Experiments

The full workflow has two stages: **(1)** dataset balancing and **(2)** synthetic data generation with AE/VAE.

### `sampling_script.py` parameters

| Flag | Description |
| ---- | ----------- |
| `-i, --input_dataset` | Path to a single CSV |
| `-d, --input_dir` | Folder with multiple CSVs for batch processing |
| `-o, --output_dir` | Output folder for the balanced datasets |
| `-t, --target_class` | Name of the (minority) class column |
| `-s, --sampling_strategy` | `oversampling` or `undersampling` |
| `-m, --sampling_method` | Specific method (see below) |

**Available methods:**

- *Oversampling:* `random_over`, `smote`, `adasyn`, `borderline_smote`
- *Undersampling:* `random_under`, `tomek_links`, `enn`, `nearmiss`

> The `tomek_links` and `enn` methods apply `RandomUnderSampler` after cleaning to complete the balancing.

## Claim #1 — Generating the balanced datasets

Reproduces the balanced versions from the dataset table. Example for `kronodroid_emulator` (SMOTE):

```bash
python sampling_script.py \
  -i Reduzidos/kronodroid_emulator.csv \
  -t class \
  -s oversampling \
  -m smote \
  -o Balanced_Datasets
```

For *undersampling*, example with `mh100k` (ENN + RandomUnderSampler):

```bash
python sampling_script.py \
  -i Reduzidos/mh100k.csv \
  -t class \
  -s undersampling \
  -m enn \
  -o Balanced_Datasets
```

- **Expected resources:** up to ~4–8 GB of RAM for the larger datasets; seconds to a few minutes per dataset.
- **Expected result:** a balanced CSV with an approximately equal class distribution, plus the corresponding `_validation_results.txt` and `_metrics_results.txt` files.

> 📈 **Paper's central claim:** combining dimensionality reduction with class balancing improves performance in 7 of the 11 datasets but degrades it in 4. For `mh100k`, comparing the reduced version without balancing to the reduced + balanced version, Recall rises from **0.63 to 0.99**, with an ~99% reduction in execution time. The `_metrics_results.txt` files allow verifying Recall and F1-score, and the timing output in the terminal allows comparing execution cost.

## Claim #2 — Synthetic data generation with AE/VAE

After generating the balanced datasets (previous stage, with output in `Balanced_Datasets/`), run the full pipeline:

```bash
chmod +x maldatagen_execution.sh
./maldatagen_execution.sh
```

The script runs interactively (asking for confirmation at each step):

1. Checks for `git` and `python3`.
2. Clones (or updates) the `Maldatagen_additional_metrics` repository.
3. Installs dependencies.
4. Moves the balanced datasets (`balanced_*.csv`) to `Maldatagen_additional_metrics/Datasets/`.
5. Runs the **AE** and **VAE** experiments for each dataset.

**Model configuration (as in the paper):**

- **Autoencoder (AE):** 300 epochs · latent dimension 128 · `leakyrelu` · dropout 0.10 · layers `128 128` · batch 8 · loss `mean_squared_error` · Adam optimizer · 5 folds.
- **Variational Autoencoder (VAE):** latent dimension 32 · `leakyrelu` · dropout 0.25 · encoder `128 128` / decoder `160 320` · batch 64 · loss `cross_entropy_kl` · Adam optimizer · 5 folds.

- **Expected resources:** intensive training; **GPU recommended**. Each experiment may take **several hours**.
- **Expected result:** results in `Maldatagen_additional_metrics/outputs/full_experiments/`, logs in `outputs/logs_*/`, and a `summary.txt` with the status (✅ success / ❌ error) of each model × dataset combination.

> 🎲 **Reproducibility:** balancing uses `random_state=42`, ensuring deterministic results across runs in the same environment. In the AE/VAE experiments, small numerical variations may occur due to the stochastic nature of training and to differences in hardware or library versions.

---

# 📄 LICENSE

This artifact is released under the **MIT License**. See the [`LICENSE`](LICENSE) file at the repository root for the full text.

```
MIT License — Copyright (c) 2026 Lucas Ferreira, Angelo Gaspar, Anna Luiza
```

---

# 👥 Maintainers

| Name |
| ---- |
| Lucas Ferreira |
| Angelo Gaspar |
| Anna Luiza |
