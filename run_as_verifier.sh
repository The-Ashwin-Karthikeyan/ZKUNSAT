#!/bin/bash

# Ensure exactly two arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Note: Run \"cmake .\" and \"make\" to build once you have installed the emp-toolkit, emp-zk and NTL libraries."
    echo "Usage: $0 <filename> <max_var> <port_num> <ip_address>"
    echo ""
    echo " - <filename>: Provide the full path or location of the public QBF formula in QDIMACS format as the argument."
    echo " - <max_var>: State the maximum variable in the AIGER file for the certificate as provided by the prover."
    echo " - <port_num>: Port number for the protocol."
    echo " - <ip_address>: IP address for the protocol."
    exit 0
fi

# Check if the argument is -h or --help and display help if so
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Note: Run \"cmake .\" and \"make\" to build once you have installed the emp-toolkit, emp-zk and NTL libraries."
    echo "Usage: $0 <filename> <max_var>"
    echo ""
    echo "<filename>: Provide the full path or location of the public QBF formula in QDIMACS format as the argument."
    echo "<max_var>: State the maximum variable in the AIGER file for the certificate as provided by the prover."
    echo "<port_num>: Port number for the protocol."
    echo "<ip_address>: IP address for the protocol."
    exit 0
fi

# Ensure a filename is provided
if [ -z "$1" ]; then
    echo "Error: No filename provided."
    echo "Use -h or --help for usage information."
    exit 1
fi

# Check if the filename ends with .qdimacs
if [[ "$1" != *.qdimacs ]]; then
    echo "Error: File '$1' must have a .qdimacs extension."
    echo "Use -h or --help for usage information."
    exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
    echo "Error: File '$1' does not exist."
    exit 1
fi

zkqd_aag=${1%.qdimacs}_veri.aag
renamed_qdimacs=${1%.qdimacs}_renamed.qdimacs
neg_qbf=${1%.qdimacs}.negqbf

# If we reach here, the file exists and we can proceed
echo "Processing file: $1"
python3 verifier_backend/rewrite_qdimacs.py "$1" > "$renamed_qdimacs"
python3 verifier_backend/qdimacsmatrix_to_aig_andlines.py "$renamed_qdimacs" "$2" > "$zkqd_aag"
python3 verifier_backend/combine_and_convert_aig_to_cnf.py "--zkskoval-input" "$zkqd_aag" > "$neg_qbf"
echo "Prepared inputs for the ZKHerbrand Verification Protocol."
./test 2 $3 $4 "$zkqdimacs_file"
echo "Cleaning up temporary files..."
rm -f "$zkqdimacs_file"
echo "Done."
