#!/bin/bash

# Script to move balanced datasets to Maldatagen Datasets directory
# Usage: ./move_datasets.sh <datasets_directory>

# Show usage if no parameter provided
show_usage() {
    echo "Usage: $0 <datasets_directory>"
    echo ""
    echo "Example: $0 /path/to/Balanced_Datasets"
    echo "   or: $0 Originais/"
    echo ""
    echo "This script will:"
    echo "  1. Clone/update Maldatagen_additional_metrics repository"
    echo "  2. Move all CSV files to the Datasets directory (without LFS conversion)"
    exit 1
}

# Check if directory parameter is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: Datasets directory not specified!"
    show_usage
fi

BALANCED_DIR="$1"

# Remove trailing slash if present
BALANCED_DIR="${BALANCED_DIR%/}"

# Validate the directory exists
if [ ! -d "$BALANCED_DIR" ]; then
    echo "❌ Error: Directory '$BALANCED_DIR' does not exist!"
    show_usage
fi

# Check if directory contains CSV files
CSV_FILES=$(ls -1 "$BALANCED_DIR"/*.csv 2>/dev/null | wc -l)
if [ $CSV_FILES -eq 0 ]; then
    echo "❌ Error: No CSV files found in '$BALANCED_DIR'!"
    echo "   Found these files instead:"
    ls -la "$BALANCED_DIR" | head -10
    echo ""
    echo "   Please ensure your datasets are CSV files in this directory."
    exit 1
fi

echo "=========================================================="
echo "MOVING DATASETS TO MALDATAGEN"
echo "=========================================================="
echo ""
echo "📂 Using datasets from: $BALANCED_DIR"
echo "📊 Found $CSV_FILES CSV files"
echo ""

# Configuration
REPO_DIR="Maldatagen_additional_metrics"
DATASET_DIR="$REPO_DIR/Datasets"

# Function to check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        echo "❌ Git is not installed. Please install git first."
        exit 1
    fi
}

# Function to check if a file is a Git LFS pointer
is_lfs_pointer() {
    local file="$1"
    if [ -f "$file" ] && head -n 1 "$file" 2>/dev/null | grep -q "^version https://git-lfs"; then
        return 0
    else
        return 1
    fi
}

# Function to temporarily disable Git LFS for CSV files
disable_git_lfs_for_csv() {
    echo "🔧 Temporarily disabling Git LFS for CSV files..."

    if [ -d "$REPO_DIR" ]; then
        cd "$REPO_DIR"

        # Check if .gitattributes exists and has CSV LFS rules
        if [ -f ".gitattributes" ]; then
            # Backup the original .gitattributes
            cp .gitattributes .gitattributes.backup

            # Remove or comment out CSV LFS rules
            sed -i 's/^\(.*\.csv.*filter=lfs.*\)/# \1/' .gitattributes
            sed -i 's/^\(.*\.csv.*diff=lfs.*\)/# \1/' .gitattributes
            sed -i 's/^\(.*\.csv.*merge=lfs.*\)/# \1/' .gitattributes

            echo "   ✅ Modified .gitattributes to disable LFS for CSV files"
        else
            echo "   ℹ️  No .gitattributes file found"
        fi

        cd ..
    else
        echo "   ℹ️  Repository directory not found, skipping LFS disable"
    fi
    echo ""
}

# Function to re-enable Git LFS for CSV files
reenable_git_lfs_for_csv() {
    echo "🔧 Re-enabling Git LFS for CSV files..."

    if [ -d "$REPO_DIR" ]; then
        cd "$REPO_DIR"

        # Restore the backup if it exists
        if [ -f ".gitattributes.backup" ]; then
            mv .gitattributes.backup .gitattributes
            echo "   ✅ Restored .gitattributes from backup"
        fi

        cd ..
    fi
    echo ""
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

# Main move function
move_datasets() {
    echo "=========================================================="
    echo "MOVING DATASETS (WITHOUT LFS CONVERSION)"
    echo "=========================================================="
    echo ""

    # Temporarily disable Git LFS for CSV files
    disable_git_lfs_for_csv

    # Count CSV files in the directory
    CSV_FILES=$(ls -1 "$BALANCED_DIR"/*.csv 2>/dev/null | wc -l)

    echo "📁 Found $CSV_FILES CSV files in '$BALANCED_DIR/'"
    echo ""

    # Check if there are already datasets in the Datasets directory
    EXISTING_DATASETS=$(ls -1 "$DATASET_DIR"/*.csv 2>/dev/null | wc -l)
    if [ $EXISTING_DATASETS -gt 0 ]; then
        echo "⚠️  Warning: '$DATASET_DIR' already contains $EXISTING_DATASETS CSV files."
        echo "   These will be overwritten with the datasets from '$BALANCED_DIR'."
        read -p "   Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Cancelled by user"
            reenable_git_lfs_for_csv
            exit 1
        fi
    fi

    # Show what will be moved
    echo ""
    echo "CSV FILES TO BE MOVED:"
    echo "----------------------------------------"
    REAL_COUNT=0
    LFS_COUNT=0
    for file in "$BALANCED_DIR"/*.csv; do
        if [ -f "$file" ]; then
            FILENAME=$(basename "$file")
            SIZE=$(du -h "$file" 2>/dev/null | cut -f1 || echo "unknown")
            if is_lfs_pointer "$file"; then
                echo "   • $FILENAME ($SIZE) ⚠️  LFS POINTER - WILL SKIP"
                ((LFS_COUNT++))
            else
                echo "   • $FILENAME ($SIZE) ✅ Real data"
                ((REAL_COUNT++))
            fi
        fi
    done
    echo ""
    echo "   📊 Summary: $REAL_COUNT real files, $LFS_COUNT LFS pointers (will skip)"
    echo ""

    # Confirm before moving
    read -p "Proceed with moving $REAL_COUNT real files? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled by user"
        reenable_git_lfs_for_csv
        exit 1
    fi

    echo ""
    echo "✅ Moving files (using cp + rm to avoid Git LFS)..."
    echo ""

    # Move the files
    MOVED=0
    SKIPPED=0
    FAILED=0

    for file in "$BALANCED_DIR"/*.csv; do
        if [ -f "$file" ]; then
            FILENAME=$(basename "$file")
            DEST_FILE="$DATASET_DIR/$FILENAME"

            # Skip LFS pointers
            if is_lfs_pointer "$file"; then
                echo "   ⚠️  SKIPPING $FILENAME (LFS pointer, not actual data)"
                ((SKIPPED++))
                continue
            fi

            # Copy the file
            if cp -f "$file" "$DEST_FILE" 2>/dev/null; then
                # Remove the original file
                if rm -f "$file" 2>/dev/null; then
                    echo "   ✅ Moved: $FILENAME"
                    ((MOVED++))
                else
                    echo "   ⚠️  Copied but could not remove original: $FILENAME"
                    ((MOVED++))
                fi
            else
                echo "   ❌ Failed to copy: $FILENAME"
                ((FAILED++))
            fi
        fi
    done

    echo ""
    echo "✅ Successfully moved $MOVED files to $DATASET_DIR/"
    if [ $SKIPPED -gt 0 ]; then
        echo "⚠️  Skipped $SKIPPED files (were LFS pointers)"
    fi
    if [ $FAILED -gt 0 ]; then
        echo "⚠️  Failed to move $FAILED files"
    fi
    echo ""

    # Re-enable Git LFS for CSV files
    reenable_git_lfs_for_csv

    echo "📁 Files now in: $DATASET_DIR/"
    echo "📊 Total datasets available: $(ls -1 "$DATASET_DIR"/*.csv 2>/dev/null | wc -l)"
    echo ""
}

# Main execution
check_git
setup_repository
move_datasets

echo "=========================================================="
echo "MOVE COMPLETE"
echo "=========================================================="
echo ""
echo "✅ Datasets moved to: $DATASET_DIR/"
echo ""
echo "Next step: Run the experiments with:"
echo "  ./run_experiments.sh"
echo ""
echo "=========================================================="
