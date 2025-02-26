# Privacy Preserving Skolem Function Verifier

This project implements an interactive protocol that proves to a verifier (Bob) that the prover (Alice) has a valid skolem function for a public QBF.

## Overview

Note: The implementation is not complete

## Limitations

- The prover reveals the number of and gates and the number of input variables in the skolem AIGER.
- If the skolem function AIGER has the lines 'a b b+1' or 'a b+1 b' it has to be replaced with 'a 0 0'. This is most commonly occurs as 'a 0 1' or 'a 1 0'.
- The Skolem function cannot have any latches as of now.

## Toolchain

File- QBF (PCNF in qdimacs format) -> Tool-depqbf -> File- QBF-trace -> Tool-qrpcheck -> File- QBF-qrpprf -> Tool-qrpcert -> File- QBF-cert (This is the skolem function in (ascii) AIGER format.) -> Tool-./prover_backend/preprocess_skolem_cert.py -> File- QBF-preprocessed-cert -> Tool-./prover_backend/skolemaig_for_zk.py (Take QBF as additional input)

## Dependencies

## Installation

