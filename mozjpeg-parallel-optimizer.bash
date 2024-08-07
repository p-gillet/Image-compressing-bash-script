#!/bin/bash
# This script recursively compresses jpg and png files to jpg files using "mozjpeg" and keeps the original files intact. It reports the sizes of original and compressed images.

#COPYRIGHT: this script is made available under the Creative Commons CC0 1.0 Universal Public Domain Dedication (https://creativecommons.org/publicdomain/zero/1.0/deed.en). The original creator of this script has no affiliation with "mozjpeg" or "Mozilla".

SOURCE_DIR="."  # Source directory that contains images to compress
DEST_DIR="./compressed_directory"  # Destination directory for compressed images
LOG_FILE="./log.csv" # Destination of the log file

# Initialize counters
file_count=0
original_size_total=0
compressed_size_total=0
start_time=$(date +%s)

# Create temporary files for counters
file_count_file=$(mktemp)
original_size_total_file=$(mktemp)
compressed_size_total_file=$(mktemp)
echo 0 > "$file_count_file"
echo 0 > "$original_size_total_file"
echo 0 > "$compressed_size_total_file"

# Temporary files to RAM as variables.
R0=$(mktemp -p /dev/shm/)
R1=$(mktemp -p /dev/shm/)
R2=$(mktemp -p /dev/shm/)

# Function to simulate compression with given parameters and log results
simulate_compression() {
    local file
    local params
    file=$1
    params=$2
	
    mozjpeg -memdst $params "$file" > "$R0" 2>&1
    n=$(grep -oE "[0-9]+" "$R0")
    printf "\n%s\t%s" "$n" "$params" >> "$R1"
}

process_file() {
    local i
    local R0
    local R1
    local R2
    i="$1"
    R0=$(mktemp -p /dev/shm/)
    R1=$(mktemp -p /dev/shm/)
    R2=$(mktemp -p /dev/shm/)

    # Determine the corresponding path in the destination directory
    dest_path="$DEST_DIR/${i#"$SOURCE_DIR"/}"
    dest_dir=$(dirname "$dest_path")

    # Create the destination directory if it doesn't exist
    mkdir -p "$dest_dir"

    S=$(date +%s)
	
    # Filename and size saved. If the name has newlines or tabs, they are converted to spaces so the names display well in terminal.
    name="$(stat --printf="%n" "$i" | tr '\n' ' ' | tr '\t' ' ')"
    size="$(stat --printf="%s" "$i")"

    # Initial compression simulation
    mozjpeg -memdst -dct float -quant-table 1 -nojfif -dc-scan-opt 2 "$i" > "$R0" 2>&1
    n=$(grep -oE "[0-9]+" "$R0")
    printf "%s\t-dct float -quant-table 1 -nojfif -dc-scan-opt 2" > "$R1" "$n"

	# If optimized size is larger than original size, then file is skipped. Else: other parameters are tested.
    if ((size < n)); then
        printf "|%9s| |%9s| |%10s| |%4s| |%-62s| |%s|\n" "$size" "-skipped-" "----" "----" "" "$name"
	# Fill the log file with the file's data
	echo "${size};-skipped-;----;----;----;${name}" >> log.csv
    else
        # Additional compression parameters
        declare -a params=(
            "-dct int -quant-table 2 -nojfif -dc-scan-opt 2"
            "-dct int -quant-table 3 -nojfif -dc-scan-opt 2"
            "-dct int -tune-ms-ssim -nojfif -dc-scan-opt 2"
            "-dct int -tune-ms-ssim -quant-table 3 -nojfif -dc-scan-opt 2"
            "-dct int -tune-ssim -nojfif -dc-scan-opt 2"
            "-dct int -tune-ssim -quant-table 0 -nojfif -dc-scan-opt 2"
            "-dct int -tune-ssim -quant-table 1 -nojfif -dc-scan-opt 2"
            "-dct int -tune-ssim -quant-table 2 -nojfif -dc-scan-opt 2"
            "-dct int -tune-ssim -quant-table 3 -nojfif -dc-scan-opt 1"
            "-dct int -tune-ssim -quant-table 3 -nojfif -dc-scan-opt 2"
            "-dct int -tune-ssim -quant-table 4 -nojfif -dc-scan-opt 2"
            "-quant-table 2 -nojfif -dc-scan-opt 1"
            "-quant-table 2 -nojfif -dc-scan-opt 2"
            "-tune-ssim -nojfif -dc-scan-opt 2"
            "-tune-ssim -quant-table 1 -nojfif -dc-scan-opt 2"
            "-tune-ssim -quant-table 2 -nojfif"
            "-tune-ssim -quant-table 2 -nojfif -dc-scan-opt 0"
            "-tune-ssim -quant-table 2 -nojfif -dc-scan-opt 2"
            "-tune-ssim -quant-table 3 -nojfif -dc-scan-opt 1"
            "-tune-ssim -quant-table 3 -nojfif -dc-scan-opt 2"
        )

        for param in "${params[@]}"; do
            simulate_compression "$i" "$param"
        done

        # Smallest bytesize is found via sort from the simulation. Parameters used to obtain this size are then extracted and used in mozjpeg to produce an actual compressed file.
        sort -n "$R1" > "$R2"
        par=$(head -n1 "$R2" | cut -f2)
	compressed_path="${dest_path%.*}_opti.jpg" # Remove the old extension and add _opti.jpg
        mozjpeg $par "$i" > "$compressed_path"

        # Update counters atomically
        {
            flock -x 200

            original_size_total=$(<"$original_size_total_file")
            compressed_size_total=$(<"$compressed_size_total_file")
            file_count=$(<"$file_count_file")

            original_size_total=$((original_size_total + size))
            compressed_size=$(stat --printf="%s" "$compressed_path")
            compressed_size_total=$((compressed_size_total + compressed_size))
            file_count=$((file_count + 1))

            echo "$original_size_total" > "$original_size_total_file"
            echo "$compressed_size_total" > "$compressed_size_total_file"
            echo "$file_count" > "$file_count_file"
        } 200>"$file_count_file.lock"

        # Time spent on processing and compressed vs original size in percentage are calculated and displayed.
        percent=$((200 * compressed_size / size % 2 + 100 * compressed_size / size))
        E=$(date +%s)
        time_spent=$((E - S))
        printf "|%9s| |%9s| |%9d%%| |%4s| |%-62s| |%s|\n" "$size" "$compressed_size" "$percent" "$time_spent" "$par" "$name" 
	# Fill the log file with the file's data
	echo "${size};${compressed_size};${percent};${time_spent};${par};${name}" >> log.csv
    fi

    # Temp files are removed from RAM.
    rm -f "$R0" "$R1" "$R2"
}

export -f simulate_compression
export -f process_file
export SOURCE_DIR
export DEST_DIR
export file_count_file
export original_size_total_file
export compressed_size_total_file

# Print the header
printf "START:\t%s\n" "$(date)"
printf "|%9s| |%9s| |%10s| |%s| |%-62s| |%-s|\n" "orig." "now" "% of orig." "sec." "parameters used" "path"

# Create the log file and append the header if it does not already exist 
if [ ! -f $LOG_FILE ] 
then
    echo "orig.;now;% of orig.;sec.;parameters used;path" >> log.csv
fi

# Find in the source directory while ignoring the destination directory all JPG/JPEG/PNG. Pipe the result to execute process_file in parallel  
find "$SOURCE_DIR" -path "$DEST_DIR" -prune -o -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0 | parallel -0 -j "$(nproc)" process_file

# Read the final values from the temporary files, calculate elapsed time and size saved with compression
file_count=$(<"$file_count_file")
original_size_total=$(<"$original_size_total_file")
compressed_size_total=$(<"$compressed_size_total_file")
end_time=$(date +%s)
total_time=$((end_time - start_time))
size_reduction_mo=$(echo "scale=2; $((original_size_total - compressed_size_total)) / 1000000" | bc)

# Print the summary
printf -- '-%.s' {1..58} ; echo
printf "Total files processed: %d (file that were skipped are not counted !)\n" "$file_count"
printf "Total original size: %d bytes\n" "$original_size_total"
printf "Total compressed size: %d bytes\n" "$compressed_size_total"
printf "Total size reduction: %.2f Mo\n"  "$size_reduction_mo"
printf "Total processing time: %d seconds\n" "$total_time"
printf "All files have been compressed and saved in the '%s' directory.\n" "$DEST_DIR"
printf "END:\t%s\n" "$(date)"
printf -- '-%.s' {1..58} ; echo

# Clean up temporary files
rm -f "$file_count_file" "$original_size_total_file" "$compressed_size_total_file" "$file_count_file.lock"
