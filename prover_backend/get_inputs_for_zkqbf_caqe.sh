#!/bin/bash
# This script runs caqe on each instance in each subdirectory in <input_dir>.
# In each subdirectory, it finds the one file (with a .qdimacs extension),
# runs <caqe_dir>/./caqe on it
# with a 300-second timeout. The output is saved to the corresponding .aag file.

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <input_dir> <zkqbf_dir> <caqe_dir> <abc_dir> <aiger_dir>"
    echo " (1) <input_dir> should be the path to the directory containing the subdirectories."
    echo "     each subdirectory should contain exactly one file with a .qdimacs extension."
    echo " (2) <zkqbf_dir> should be the path to the zkqbf directory."
    echo " (3) <caqe_dir> should be the path to the caqe directory."
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
  aagfile="${base%.qdimacs}_renamed.aag"
  certfile="${base%.qdimacs}_renamed.cert"
  qmafile="${base%.qdimacs}_renamed.qma"
  cnffile="${base%.qdimacs}_renamed.cnf"

  # Full path for the proof file
  renamed_output="$dir$renamedfile"
  aag_output="$dir$aagfile"
  cert_output="$dir$certfile"
  qma_output="$dir$qmafile"
  cnf_output="$dir$cnffile"

  # Run ../depqbf with a 30-second timeout and save the output to the proof file
  timeout 120 python3 $2/prover_backend/rewrite_qdimacs.py "$file" > "$renamed_output"
  timeout 300 $3/./caqe -c "$renamed_output" > "$aag_output"
  timeout 120 python3 $2/prover_backend/cadet_preprocess.py "$aag_output" "$renamed_output" > "$cert_output"
  max_var=$(python3 "$2/prover_backend/get_cert_maxvar.py" "$cert_output")
  timeout 120 python3 $2/prover_backend/qdimacsmatrix_to_aig_andlines.py "$renamed_output" "$max_var" > "$qma_output"
  timeout 120 python3 $2/prover_backend/combine_and_convert_aig_to_cnf.py "$cert_output" "$qma_output" > "$cnf_output"
done
