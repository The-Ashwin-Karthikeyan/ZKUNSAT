#!/bin/bash
# This script runs cadet on each instance in each subdirectory in 2QBF.
# In each subdirectory, it finds the one file (with a .qdimacs extension),
# runs cadet/./cadet on it
# with a 30-second timeout. The output is saved to the corresponding .prf file.

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <input_dir> <zkqbf_dir> <cadet_dir> <abc_dir> <aiger_dir>"
    echo " (1) <input_dir> should be the path to the directory containing the subdirectories."
    echo "     each subdirectory should contain exactly one file with a .qdimacs extension."
    echo " (2) <zkqbf_dir> should be the path to the zkqbf directory."
    echo " (3) <cadet_dir> should be the path to the cadet directory."
    echo " (4) <abc_dir> should be the path to the abc directory."
    echo " (5) <aiger_dir> should be the path to the aiger (toolset: https://github.com/arminbiere/aiger) directory."
    exit 1
fi

# Loop over each subdirectory in crafted-qbfeval20
for dir in $1/*/; do
  # Find the single file in the subdirectory
  file=$(find "$dir" -maxdepth 1 -type f | head -n 1)
  
  # If no file was found, skip to the next directory
  if [ -z "$file" ]; then
    echo "Warning: No file found in directory $dir" >&2
    continue
  fi

  # Extract the base filename (e.g., CR.qdimacs)
  base=$(basename "$file")

  # Replace the .qdimacs extension with .prf
  renamedfile="${base%.qdimacs}_renamed.qdimacs"
  aigerfile="${base%.qdimacs}_renamed.aig"
  minaigerfile="${base%.qdimacs}_renamed_min.aig"
  minaagfile="${base%.qdimacs}_renamed_min.aag"
  certfile="${base%.qdimacs}_renamed_min.cert"
  qmafile="${base%.qdimacs}_renamed.qma"
  cnffile="${base%.qdimacs}_renamed.cnf"

  # Full path for the proof file
  renamed_output="$dir$renamedfile"
  aiger_output="$dir$aigerfile"
  min_aiger_output="$dir$minaigerfile"
  min_aag_output="$dir$minaagfile"
  cert_output="$dir$certfile"
  qma_output="$dir$qmafile"
  cnf_output="$dir$cnffile"

  # Run ../depqbf with a 30-second timeout and save the output to the proof file
  timeout 30 python3 $2/prover_backend/rewrite_qdimacs.py "$file" > "$renamed_output"
  timeout 60 $3/./cadet --qbfcert -c "$aiger_output" "$renamed_output" > "$file".result
  timeout 30 $4/abc -c "read $aiger_output; dc2; write $min_aiger_output;"
  timeout 30 $5/./aigtoaig "$min_aiger_output" "$min_aag_output"
  timeout 30 $2/prover_backend/cadet_preprocess.py "$min_aag_output" "$renamed_output" > "$cert_output"
  max_var=$(python3 "$2/prover_backend/get_cert_maxvar.py" "$cert_output")
  timeout 30 $2/prover_backend/qdmiacsmatrix_to_aig_andlines.py "$renamed_output" "$max_var" > "$qma_output"
  timeout 30 $2/prover_backend/combine_and_convert_aig_to_cnf.py "$cert_output" "$qma_output" > "$cnf_output"
done
