# Image Compressing Bash Script

*Note: I have no affiliation with "mozjpeg" or "Mozilla". This script is inspired by the work of u/drinkpainttillufaint.*

- [Link to the topic](https://www.reddit.com/r/commandline/comments/nxen24/optimize_jpgpng_files_near_losslessly_with/)
- [Link to the initial script](https://pastebin.com/vfqnSHne)
- [Link to his v2 script](https://pastebin.com/6EZSjJmQ)
- [Link to the topic v2](https://www.reddit.com/r/commandline/comments/o0qprw/3098_smaller_jpgpng_files_with_mozjpeg/)

## Dependencies

To use this script you will need the following package installed and fully working :
   - [mozjpeg](https://github.com/mozilla/mozjpeg)
   - [GNU parallel](https://www.gnu.org/software/parallel/)
   - [GNU bc](https://www.gnu.org/software/bc/)

## Script Overview

This Bash script is designed to compress JPG and PNG files into optimized JPG files using the `mozjpeg` tool. It processes files in a way that keeps the original images intact and provides detailed reports on the sizes of both the original and the compressed images. The script also runs tasks in parallel to speed up the process, taking advantage of multiple CPU cores.

## Key Features

1. **Source and Destination Directories:**
   - `SOURCE_DIR` is set to the current directory (`.`), where your original images are located.
   - `DEST_DIR` is set to `compressed_directory`, which is where the script will save the compressed images.

2. **Counters Initialization:**
   - The script initializes counters for tracking the number of files processed, the total size of the original images, and the total size of the compressed images.
   - It also notes the start time to calculate the total processing duration later.

3. **Temporary Files:**
   - Temporary files are used to keep track of the counters. These files are initialized to zero at the start of the script.

4. **Compression Simulation:**
   - The script includes a function called `simulate_compression` that runs `mozjpeg` with different settings to find the best compression parameters. It logs the results to temporary files for further analysis.

5. **File Processing:**
   - The `process_file` function handles each image file individually. It:
     - Determines where the compressed file will be saved in the destination directory.
     - Creates any necessary directories.
     - Logs the file’s original size and name.
     - Runs an initial compression test.
     - If the compressed file is larger than the original, it skips further processing. Otherwise, it tests various compression settings to find the best result.
     - Compresses the image with the best settings and saves it in the destination directory.
     - Updates counters with the new size information and logs the results.

6. **Parallel Processing:**
   - To speed things up, the script uses the `find` command to locate JPG and PNG files and processes them in parallel using the `parallel` command.

7. **Summary and Cleanup:**
   - After processing all the images, the script reads from the temporary counter files to get final counts and sizes.
   - It then prints a summary that includes the number of files processed, total original and compressed sizes, the total reduction in size, and the overall processing time.
   - Finally, it cleans up all temporary files used during the process.

## How It Works

1. **Initialization:**
   - The script sets the source and destination directories and prepares temporary files for tracking progress.

2. **Simulating Compression:**
   - The `simulate_compression` function tests different `mozjpeg` settings to find the optimal compression parameters.

3. **Processing Files:**
   - The `process_file` function manages each image file by determining where it should be saved, running compression tests, and applying the best settings found.

4. **Exporting and Processing:**
   - It exports necessary variables and functions for use in parallel processing, starts the processing of files, and waits for completion.

5. **Final Summary:**
   - The script prints out a summary of its work, including how many files were processed, the total size reduction, and the time spent.

6. **Cleanup:**
   - It wraps up by deleting temporary files and displaying a final end time.

---

Overall, this script is a powerful tool for optimizing image storage, combining efficient compression with parallel processing to handle large numbers of files quickly while keeping track of important metrics.
