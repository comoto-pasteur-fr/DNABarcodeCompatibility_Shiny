#! /bin/bash

# Check that docker is installed
hash docker
if [ $? -eq 1 ]; then echo 'docker is not installed, please install it first'; fi

# Create a docker image for DNABarcodeCompatibility_Shiny
docker build --no-cache -t etournay/dna_barcode_compatibility_shiny .

