#!/bin/bash

# Complete script to move balanced datasets to Maldatagen and run AE/VAE experiments

set -e  # Stop on error

echo "=========================================================="
echo "COMPLETE PIPELINE: BALANCED DATASETS -> AE/VAE EXPERIMENTS"
echo "=========================================================="
echo ""

# Configuration
REPO_DIR="Maldatagen_additional_metrics"
BALANCED_DIR="Balanced_Datasets"
DATASET_DIR="$REPO_DIR/Datasets"

# Function to check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        echo "❌ Git is not installed. Please install git first."
        exit 1
    fi
}

# Function to check if python3 is installed
check_python() {
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python3 is not installed. Please install Python3 first."
        exit 1
    fi
}

# Function to clone or update repository
setup_repository() {
    echo "📦 Setting up repository..."
    
    if [ -d "$REPO_DIR" ]; then
        echo "   Directory '$REPO_DIR' already exists."
        read -p "   Update existing repository? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "   Updating repository..."
            cd "$REPO_DIR"
            git pull
            cd ..
        else
            echo "   Using existing repository."
        fi
    else
        echo "   Cloning repository..."
        git clone https://github.com/MalwareDataLab/Maldatagen_additional_metrics.git "$REPO_DIR"
        echo "   ✅ Repository cloned successfully!"
    fi
    
    # Create Datasets directory if it doesn't exist
    mkdir -p "$DATASET_DIR"
    
    # Check if main.py exists
    if [ ! -f "$REPO_DIR/main.py" ]; then
        echo "❌ main.py not found in cloned repository!"
        echo "   Please check the repository structure."
        exit 1
    fi
    
    echo "✅ Repository ready."
    echo ""
}

# Function to install dependencies
install_dependencies() {
    echo "📦 Installing dependencies..."
    
    # Check for requirements.txt
    if [ -f "$REPO_DIR/requirements.txt" ]; then
        echo "   Installing from requirements.txt..."
        pip3 install -r "$REPO_DIR/requirements.txt"
    else
        echo "   No requirements.txt found. Installing common dependencies..."
        pip3 install pandas numpy scikit-learn imbalanced-learn tensorflow keras matplotlib seaborn
    fi
    
    echo "✅ Dependencies installed."
    echo ""
}

# Function to move balanced datasets
move_balanced_datasets() {
    echo "=========================================================="
    echo "STEP 1: MOVING BALANCED DATASETS"
    echo "=========================================================="
    echo ""
    
    # Check if Balanced_Datasets exists
    if [ ! -d "$BALANCED_DIR" ]; then
        echo "❌ Error: '$BALANCED_DIR' directory not found!"
        echo "   Please run the sampling script first to generate balanced datasets."
        exit 1
    fi
    
    # Check if there are balanced datasets
    BALANCED_FILES=$(ls -1 "$BALANCED_DIR"/balanced_*.csv 2>/dev/null | wc -l)
    if [ $BALANCED_FILES -eq 0 ]; then
        echo "❌ Error: No balanced datasets found in '$BALANCED_DIR'!"
        echo "   Please run the sampling script first to generate balanced datasets."
        exit 1
    fi
    
    echo "📁 Found $BALANCED_FILES balanced datasets in '$BALANCED_DIR/'"
    echo ""
    
    # Check if there are already datasets in the Datasets directory
    EXISTING_DATASETS=$(ls -1 "$DATASET_DIR"/*.csv 2>/dev/null | wc -l)
    if [ $EXISTING_DATASETS -gt 0 ]; then
        echo "⚠️  Warning: '$DATASET_DIR' already contains $EXISTING_DATASETS CSV files."
        echo "   These will be overwritten with the balanced datasets."
        read -p "   Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Cancelled by user"
            exit 1
        fi
    fi
    
    # Show what will be moved
    echo ""
    echo "BALANCED DATASETS TO BE MOVED:"
    echo "----------------------------------------"
    ls -1 "$BALANCED_DIR"/balanced_*.csv | while read -r file; do
        FILENAME=$(basename "$file")
        SIZE=$(du -h "$file" | cut -f1)
        echo "   • $FILENAME ($SIZE)"
    done
    echo ""
    
    # Confirm before moving
    read -p "Proceed with moving $BALANCED_FILES files? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled by user"
        exit 1
    fi
    
    echo ""
    echo "✅ Moving files..."
    echo ""
    
    # Move the files
    MOVED=0
    for file in "$BALANCED_DIR"/balanced_*.csv; do
        if [ -f "$file" ]; then
            FILENAME=$(basename "$file")
            DEST_FILE="$DATASET_DIR/$FILENAME"
            
            # Move the file (overwrite if exists)
            mv -f "$file" "$DEST_FILE"
            if [ $? -eq 0 ]; then
                echo "   ✅ Moved: $FILENAME"
                ((MOVED++))
            else
                echo "   ❌ Failed to move: $FILENAME"
            fi
        fi
    done
    
    echo ""
    echo "✅ Moved $MOVED files to $DATASET_DIR/"
    echo ""
    
    # Check if Balanced_Datasets is empty now
    REMAINING=$(ls -1 "$BALANCED_DIR"/*.csv 2>/dev/null | wc -l)
    if [ $REMAINING -eq 0 ]; then
        echo "✅ Balanced_Datasets directory is now empty."
        read -p "Remove empty Balanced_Datasets directory? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rmdir "$BALANCED_DIR"
            echo "✅ Removed: $BALANCED_DIR/"
        fi
    fi
    
    echo ""
}

# Function to run AE/VAE experiments
run_experiments() {
    echo "=========================================================="
    echo "STEP 2: RUNNING AE AND VAE EXPERIMENTS"
    echo "=========================================================="
    echo ""
    
    # Get all datasets (including balanced ones)
    DATASETS=($(ls -1 "$DATASET_DIR"/*.csv 2>/dev/null | xargs -n1 basename))
    
    if [ ${#DATASETS[@]} -eq 0 ]; then
        echo "❌ No datasets found in $DATASET_DIR/"
        echo "   Please ensure datasets are in the correct location."
        exit 1
    fi
    
    echo "📋 Datasets found in $DATASET_DIR/:"
    for i in "${!DATASETS[@]}"; do
        SIZE=$(du -h "$DATASET_DIR/${DATASETS[$i]}" | cut -f1)
        echo "   $((i+1)). ${DATASETS[$i]} ($SIZE)"
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
        exit 1
    fi
    
    # Create log directory
    LOG_DIR="$REPO_DIR/outputs/logs_full_$(date '+%Y%m%d_%H%M%S')"
    mkdir -p "$LOG_DIR"
    
    # Change to repository directory
    cd "$REPO_DIR"
    
    START_TIME=$(date +%s)
    
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
            FILE_SIZE=$(du -h "$DATASET_PATH" | cut -f1)
            echo "   📦 File size: $FILE_SIZE"
            
            OUTPUT_DIR="outputs/full_experiments/${MODEL}/${DATASET_NAME}"
            LOG_FILE="${LOG_DIR}/${MODEL}_${DATASET_NAME}.log"
            EXP_START=$(date +%s)
            
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
            
            # Execute main.py with logging
            python3 main.py \
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
    
    # Return to original directory
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
    echo "📋 Logs saved in: $LOG_DIR"
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
                if grep -q "✅ SUCCESS" "$LOG_FILE"; then
                    TEMPO=$(grep "✅ SUCCESS" "$LOG_FILE" | grep -oP '\d+h \d+m' || echo "N/A")
                    echo "✅ ${MODEL} - ${DATASET_NAME} (${TEMPO})" >> "$SUMMARY_FILE"
                elif grep -q "❌ ERROR" "$LOG_FILE"; then
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
    TOTAL_SUCCESS=$(grep -c "✅" "$SUMMARY_FILE" || echo "0")
    TOTAL_ERRORS=$(grep -c "❌" "$SUMMARY_FILE" || echo "0")
    
    echo ""
    echo "📊 Final Statistics:"
    echo "   ✅ Successes: $TOTAL_SUCCESS/$TOTAL_EXPERIMENTS"
    echo "   ❌ Errors: $TOTAL_ERRORS/$TOTAL_EXPERIMENTS"
    echo ""
}

# Main execution
START_TIME=$(date +%s)

# Check prerequisites
check_git
check_python

# Setup repository
setup_repository

# Install dependencies
install_dependencies

# Move balanced datasets
move_balanced_datasets

# Run AE/VAE experiments
run_experiments

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

echo "=========================================================="
echo "                    PIPELINE COMPLETE                      "
echo "=========================================================="
echo ""
echo "✅ Full pipeline completed successfully!"
echo ""
echo "⏱️  Total execution time: $(($TOTAL_DURATION / 86400))d $(($TOTAL_DURATION % 86400 / 3600))h $(($TOTAL_DURATION % 3600 / 60))m"
echo ""
echo "📁 Results location: $REPO_DIR/outputs/full_experiments/"
echo "📋 Logs location: $REPO_DIR/outputs/logs_*/"
echo ""
echo "=========================================================="
