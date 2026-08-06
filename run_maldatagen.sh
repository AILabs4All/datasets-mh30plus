#!/bin/bash

# Script to run AE/VAE experiments on datasets in Maldatagen
# Usage: ./run_experiments.sh

# Get the current directory
CURRENT_DIR="$(pwd)"
REPO_DIR="Maldatagen_additional_metrics"
DATASET_DIR="$REPO_DIR/Datasets"
VENV_DIR="$REPO_DIR/venv"

echo "=========================================================="
echo "RUNNING AE AND VAE EXPERIMENTS"
echo "=========================================================="
echo ""
echo "📂 Current directory: $CURRENT_DIR"
echo "📂 Looking for datasets in: $DATASET_DIR"
echo ""

# Check if datasets directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "❌ Repository directory '$REPO_DIR' not found in current directory!"
    echo "   Current directory contents:"
    ls -la
    echo ""
    echo "   Please make sure you're in the correct directory."
    echo "   The directory should contain the '$REPO_DIR' folder."
    exit 1
fi

# Check if datasets exist
if [ ! -d "$DATASET_DIR" ]; then
    echo "❌ Datasets directory not found: $DATASET_DIR"
    echo "   Creating it..."
    mkdir -p "$DATASET_DIR"
    echo "   Please run move_datasets.sh first to populate it."
    exit 1
fi

# Check for CSV files using absolute path from current directory
DATASET_COUNT=$(ls -1 "$CURRENT_DIR/$DATASET_DIR"/*.csv 2>/dev/null | wc -l)
if [ $DATASET_COUNT -eq 0 ]; then
    echo "❌ No datasets found in $DATASET_DIR/"
    echo "   Current contents of $DATASET_DIR/:"
    ls -la "$DATASET_DIR" 2>/dev/null || echo "   (Directory empty)"
    echo ""
    echo "   Please run move_datasets.sh first to move datasets."
    exit 1
fi

echo "📋 Found $DATASET_COUNT datasets in $DATASET_DIR/"
echo ""

# Function to check if a file is a Git LFS pointer
is_lfs_pointer() {
    local file="$1"
    if [ -f "$file" ] && head -n 1 "$file" 2>/dev/null | grep -q "^version https://git-lfs"; then
        return 0
    else
        return 1
    fi
}

# Check for LFS pointers using absolute path
HAS_LFS=0
echo "🔍 Checking datasets..."
for file in "$CURRENT_DIR/$DATASET_DIR"/*.csv; do
    if [ -f "$file" ]; then
        if is_lfs_pointer "$file"; then
            echo "   ⚠️  $(basename "$file") is an LFS pointer!"
            HAS_LFS=1
        fi
    fi
done

if [ $HAS_LFS -eq 1 ]; then
    echo ""
    echo "❌ Some datasets are Git LFS pointers, not actual data!"
    echo "   Please ensure all datasets are real CSV files."
    echo "   Run move_datasets.sh again to fix this."
    exit 1
fi

echo "   ✅ All datasets are real CSV files"
echo ""

# Change to repository directory
cd "$REPO_DIR" || exit 1

# Function to setup virtual environment
setup_venv() {
    echo "=========================================================="
    echo "SETTING UP VIRTUAL ENVIRONMENT"
    echo "=========================================================="
    echo ""

    # Check Python version
    PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '(?<=Python )\d+\.\d+')
    echo "🐍 Python version: $PYTHON_VERSION"

    # Check if venv exists
    if [ -d "$VENV_DIR" ]; then
        echo "📦 Virtual environment already exists at: $VENV_DIR"
        read -p "   Recreate virtual environment? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "   Removing old virtual environment..."
            rm -rf "$VENV_DIR"
            echo "   Creating new virtual environment..."
            python3 -m venv "$VENV_DIR"
            echo "   ✅ Virtual environment created"
        else
            echo "   Using existing virtual environment"
        fi
    else
        echo "📦 Creating virtual environment..."
        python3 -m venv "$VENV_DIR"
        echo "   ✅ Virtual environment created at: $VENV_DIR"
    fi

    echo ""
    echo "🔧 Installing essential dependencies for AE/VAE experiments..."

    # Use the venv's pip directly
    "$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel

    # Install core scientific packages
    echo "   📦 Installing core scientific packages..."
    "$VENV_DIR/bin/pip" install numpy pandas matplotlib seaborn scikit-learn scipy

    # Install TensorFlow (the main requirement)
    echo "   📦 Installing TensorFlow (this may take several minutes)..."
    "$VENV_DIR/bin/pip" install tensorflow

    # Install additional packages needed for the project
    echo "   📦 Installing additional packages..."
    "$VENV_DIR/bin/pip" install \
        absl-py \
        astunparse \
        cachetools \
        certifi \
        charset-normalizer \
        contourpy \
        cycler \
        flatbuffers \
        fonttools \
        gast \
        google-auth \
        google-auth-oauthlib \
        google-pasta \
        grpcio \
        h5py \
        idna \
        joblib \
        keras \
        keras-preprocessing \
        kiwisolver \
        markdown \
        markupsafe \
        matplotlib \
        oauthlib \
        opt-einsum \
        packaging \
        pillow \
        plotly \
        protobuf \
        pyasn1 \
        pyasn1-modules \
        pyparsing \
        python-dateutil \
        pytz \
        requests \
        requests-oauthlib \
        rsa \
        scikit-learn \
        scipy \
        seaborn \
        six \
        tenacity \
        tensorboard \
        tensorboard-data-server \
        tensorboard-plugin-wit \
        termcolor \
        threadpoolctl \
        typing-extensions \
        urllib3 \
        werkzeug \
        wheel \
        wrapt \
        xgboost \
        gputil \
        psutil

    # Verify installation
    echo ""
    echo "🔍 Verifying installation..."
    if "$VENV_DIR/bin/python" -c "import numpy, pandas, tensorflow, sklearn" 2>/dev/null; then
        echo "   ✅ Core packages installed successfully!"
    else
        echo "   ⚠️  Some packages may not have installed correctly."
        echo "   Attempting to fix numpy..."
        "$VENV_DIR/bin/pip" install --force-reinstall numpy
    fi

    echo ""
    echo "✅ Virtual environment setup complete!"
    echo ""
}

# Setup virtual environment
setup_venv

# Get all datasets - use the absolute path from current directory
DATASETS=()
while IFS= read -r file; do
    if [ -n "$file" ]; then
        # Get just the filename
        DATASETS+=("$(basename "$file")")
    fi
done < <(find "$CURRENT_DIR/$DATASET_DIR" -maxdepth 1 -name "*.csv" -type f 2>/dev/null | sort)

# Debug: show what was found
echo "DEBUG: Found ${#DATASETS[@]} datasets"
if [ ${#DATASETS[@]} -eq 0 ]; then
    echo "DEBUG: Listing files in $CURRENT_DIR/$DATASET_DIR:"
    ls -la "$CURRENT_DIR/$DATASET_DIR"/*.csv 2>/dev/null || echo "No CSV files found"
    cd ..
    exit 1
fi

echo "📊 Datasets to process:"
for i in "${!DATASETS[@]}"; do
    FILE_PATH="$CURRENT_DIR/$DATASET_DIR/${DATASETS[$i]}"
    SIZE=$(du -h "$FILE_PATH" 2>/dev/null | cut -f1 || echo "unknown")
    LINES=$(wc -l < "$FILE_PATH" 2>/dev/null || echo "unknown")
    echo "   $((i+1)). ${DATASETS[$i]} ($SIZE, $LINES lines)"
done
echo ""

# AE Configuration (from paper)
AE_CONFIG="
    --number_k_folds 5 \
    --save_data True \
    --autoencoder_number_epochs 300 \
    --autoencoder_latent_dimension 128 \
    --autoencoder_activation_function leakyrelu \
    --autoencoder_dropout_decay_rate_encoder 0.10 \
    --autoencoder_dropout_decay_rate_decoder 0.10 \
    --autoencoder_dense_layer_sizes_encoder 128 128 \
    --autoencoder_dense_layer_sizes_decoder 128 128 \
    --autoencoder_batch_size 8 \
    --autoencoder_loss_function mean_squared_error \
    --autoencoder_momentum 0.8 \
    --autoencoder_latent_mean_distribution 0.5 \
    --autoencoder_latent_stander_deviation 0.125 \
    --autoencoder_initializer_mean 0.0 \
    --autoencoder_initializer_deviation 0.125 \
    --autoencoder_training_algorithm Adam \
    --verbosity 20
"

# VAE Configuration (from paper)
VAE_CONFIG="
    --number_k_folds 5 \
    --save_data True \
    --variational_autoencoder_number_epochs 300 \
    --variational_autoencoder_latent_dimension 32 \
    --variational_autoencoder_activation_function leakyrelu \
    --variational_autoencoder_dropout_decay_rate_encoder 0.25 \
    --variational_autoencoder_dropout_decay_rate_decoder 0.25 \
    --variational_autoencoder_dense_layer_sizes_encoder 128 128 \
    --variational_autoencoder_dense_layer_sizes_decoder 160 320 \
    --variational_autoencoder_batch_size 64 \
    --variational_autoencoder_loss_function cross_entropy_kl \
    --variational_autoencoder_momentum 0.8 \
    --variational_autoencoder_mean_distribution 0.5 \
    --variational_autoencoder_stander_deviation 0.125 \
    --variational_autoencoder_initializer_mean 0.0 \
    --variational_autoencoder_initializer_deviation 0.125 \
    --variational_autoencoder_training_algorithm Adam \
    --verbosity 20
"

MODELS=("autoencoder" "variational")
TOTAL_DATASETS=${#DATASETS[@]}
TOTAL_MODELS=${#MODELS[@]}
TOTAL_EXPERIMENTS=$((TOTAL_DATASETS * TOTAL_MODELS))
CURRENT_EXPERIMENT=0

echo "📊 Total experiments to run: $TOTAL_EXPERIMENTS"
echo "   • Datasets: $TOTAL_DATASETS"
echo "   • Models: AE, VAE"
echo "   • Estimated time: Several hours per experiment"
echo ""

read -p "⚠️  Start experiments? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled by user"
    cd ..
    exit 1
fi

# Create log directory
LOG_DIR="outputs/logs_full_$(date '+%Y%m%d_%H%M%S')"
mkdir -p "$LOG_DIR"

# Ensure the Logs directory exists at the root level for each experiment
# This is a pre-emptive fix for the directory creation issue
echo "🔧 Pre-creating experiment directories to avoid race conditions..."

for MODEL in "${MODELS[@]}"; do
    for DATASET in "${DATASETS[@]}"; do
        DATASET_NAME="${DATASET%.csv}"
        OUTPUT_DIR="outputs/full_experiments/${MODEL}/${DATASET_NAME}"

        # Create ALL required subdirectories
        mkdir -p "$OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR/Logs"
        mkdir -p "$OUTPUT_DIR/ModelsSaved"
        mkdir -p "$OUTPUT_DIR/GraphsSaved"
        mkdir -p "$OUTPUT_DIR/DataGenerated"
        mkdir -p "$OUTPUT_DIR/DataGenerated/Training"
        mkdir -p "$OUTPUT_DIR/DataGenerated/Validation"
        mkdir -p "$OUTPUT_DIR/DataGenerated/Test"

        # Also create a logging.log file to prevent the FileNotFoundError
        touch "$OUTPUT_DIR/Logs/logging.log" 2>/dev/null || true
    done
done

echo "   ✅ All directories pre-created"
echo ""

START_TIME=$(date +%s)

# Set the Python interpreter from venv
PYTHON="$VENV_DIR/bin/python"

# Verify numpy is installed
echo "🔍 Verifying installation..."
if ! "$PYTHON" -c "import numpy" 2>/dev/null; then
    echo "❌ NumPy not installed properly!"
    echo "   Attempting to reinstall..."
    "$VENV_DIR/bin/pip" install --force-reinstall numpy
fi

for MODEL in "${MODELS[@]}"; do
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    if [ "$MODEL" == "autoencoder" ]; then
        echo "║  MODEL: AUTOENCODER (AE)                         ║"
    else
        echo "║  MODEL: VARIATIONAL AUTOENCODER (VAE)            ║"
    fi
    echo "╚════════════════════════════════════════════════════╝"
    echo ""

    for DATASET in "${DATASETS[@]}"; do
        CURRENT_EXPERIMENT=$((CURRENT_EXPERIMENT + 1))
        DATASET_PATH="Datasets/${DATASET}"
        DATASET_NAME="${DATASET%.csv}"

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📊 Experiment [$CURRENT_EXPERIMENT/$TOTAL_EXPERIMENTS]"
        echo "   Model: ${MODEL}"
        echo "   Dataset: ${DATASET_NAME}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Check if dataset exists
        if [ ! -f "$DATASET_PATH" ]; then
            echo "⚠️  Dataset not found: $DATASET_PATH"
            echo "   Skipping..."
            echo ""
            continue
        fi

        # Show dataset info
        FILE_SIZE=$(du -h "$DATASET_PATH" 2>/dev/null | cut -f1 || echo "unknown")
        LINES=$(wc -l < "$DATASET_PATH" 2>/dev/null || echo "unknown")
        echo "   📦 File size: $FILE_SIZE, Lines: $LINES"

        OUTPUT_DIR="outputs/full_experiments/${MODEL}/${DATASET_NAME}"
        LOG_FILE="${LOG_DIR}/${MODEL}_${DATASET_NAME}.log"
        EXP_START=$(date +%s)

        # Ensure directories exist (redundant but safe)
        mkdir -p "$OUTPUT_DIR/Logs"
        mkdir -p "$OUTPUT_DIR/ModelsSaved"
        mkdir -p "$OUTPUT_DIR/GraphsSaved"
        mkdir -p "$OUTPUT_DIR/DataGenerated/Training"
        mkdir -p "$OUTPUT_DIR/DataGenerated/Validation"
        mkdir -p "$OUTPUT_DIR/DataGenerated/Test"

        # Ensure logging.log exists
        touch "$OUTPUT_DIR/Logs/logging.log" 2>/dev/null || true

        # Select configuration
        if [ "$MODEL" == "autoencoder" ]; then
            CONFIG=$AE_CONFIG
        else
            CONFIG=$VAE_CONFIG
        fi

        echo "▶️  Starting training..."
        echo "   Log: $LOG_FILE"
        echo "   ⚠️  This may take several HOURS!"
        echo ""

        # Execute main.py with the venv's Python
        # Set environment variable to prevent oneDNN warnings if desired
        export TF_ENABLE_ONEDNN_OPTS=0

        "$PYTHON" main.py \
            --model_type "$MODEL" \
            --data_load_path_file_input "$DATASET_PATH" \
            --output_dir "$OUTPUT_DIR" \
            $CONFIG 2>&1 | tee "$LOG_FILE"

        EXIT_CODE=${PIPESTATUS[0]}

        EXP_END=$(date +%s)
        DURATION=$((EXP_END - EXP_START))

        if [ $EXIT_CODE -eq 0 ]; then
            echo ""
            echo "✅ Completed in $(($DURATION / 3600))h $(($DURATION % 3600 / 60))m $(($DURATION % 60))s"
            echo "📁 Results: $OUTPUT_DIR"
            echo "✅ SUCCESS - Time: $(($DURATION / 3600))h $(($DURATION % 3600 / 60))m" >> "$LOG_FILE"
        else
            echo ""
            echo "❌ ERROR processing (Exit code: $EXIT_CODE)"
            echo "   Time until error: $(($DURATION / 60))m $(($DURATION % 60))s"
            echo "❌ Check log: $LOG_FILE"
            echo "❌ ERROR - Exit code: $EXIT_CODE - Time: $(($DURATION / 60))m" >> "$LOG_FILE"
        fi

        echo ""
    done
done

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

cd ..

echo "=========================================================="
echo "                    EXPERIMENTS COMPLETE                   "
echo "=========================================================="
echo ""
echo "✅ All experiments completed!"
echo ""
echo "⏱️  Total time: $(($TOTAL_DURATION / 86400))d $(($TOTAL_DURATION % 86400 / 3600))h $(($TOTAL_DURATION % 3600 / 60))m"
echo ""
echo "📁 Results saved in: $REPO_DIR/outputs/full_experiments/"
echo "📋 Logs saved in: $REPO_DIR/$LOG_DIR"
echo ""

# Generate summary report
SUMMARY_FILE="${LOG_DIR}/summary.txt"
echo "EXPERIMENT SUMMARY" > "$SUMMARY_FILE"
echo "========================================" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')" >> "$SUMMARY_FILE"
echo "Total time: $(($TOTAL_DURATION / 86400))d $(($TOTAL_DURATION % 86400 / 3600))h $(($TOTAL_DURATION % 3600 / 60))m" >> "$SUMMARY_FILE"
echo "Datasets: $TOTAL_DATASETS" >> "$SUMMARY_FILE"
echo "Experiments: $TOTAL_EXPERIMENTS" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "Datasets processed:" >> "$SUMMARY_FILE"
echo "------------------" >> "$SUMMARY_FILE"
for DATASET in "${DATASETS[@]}"; do
    echo "  • $DATASET" >> "$SUMMARY_FILE"
done

echo "" >> "$SUMMARY_FILE"
echo "Experiment Status:" >> "$SUMMARY_FILE"
echo "------------------" >> "$SUMMARY_FILE"

for MODEL in "${MODELS[@]}"; do
    for DATASET in "${DATASETS[@]}"; do
        DATASET_NAME="${DATASET%.csv}"
        LOG_FILE="${LOG_DIR}/${MODEL}_${DATASET_NAME}.log"
        if [ -f "$LOG_FILE" ]; then
            if grep -q "✅ SUCCESS" "$LOG_FILE" 2>/dev/null; then
                TEMPO=$(grep "✅ SUCCESS" "$LOG_FILE" 2>/dev/null | grep -oP '\d+h \d+m' || echo "N/A")
                echo "✅ ${MODEL} - ${DATASET_NAME} (${TEMPO})" >> "$SUMMARY_FILE"
            elif grep -q "❌ ERROR" "$LOG_FILE" 2>/dev/null; then
                echo "❌ ${MODEL} - ${DATASET_NAME}" >> "$SUMMARY_FILE"
            else
                echo "⚠️  ${MODEL} - ${DATASET_NAME} (incomplete)" >> "$SUMMARY_FILE"
            fi
        else
            echo "❓ ${MODEL} - ${DATASET_NAME} (no log found)" >> "$SUMMARY_FILE"
        fi
    done
done

echo ""
echo "📄 Summary saved in: $SUMMARY_FILE"
echo ""
cat "$SUMMARY_FILE"

# Calculate final statistics
TOTAL_SUCCESS=$(grep -c "✅" "$SUMMARY_FILE" 2>/dev/null || echo "0")
TOTAL_ERRORS=$(grep -c "❌" "$SUMMARY_FILE" 2>/dev/null || echo "0")

echo ""
echo "📊 Final Statistics:"
echo "   ✅ Successes: $TOTAL_SUCCESS/$TOTAL_EXPERIMENTS"
echo "   ❌ Errors: $TOTAL_ERRORS/$TOTAL_EXPERIMENTS"
echo ""
