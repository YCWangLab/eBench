#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=18
#SBATCH --mem=70000
#SBATCH -o mergemorden

cd /online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden
output_dir="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/final_animals"
mkdir -p "$output_dir"

a=1
while [ $a -le 30 ]
do
    echo "Processing sample $a"
    
    nuclear_file="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/simulated_animalsreads/${a}_nuclear.fa"
    mito_file="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/simulated_animalsreads/${a}_mito.fa"
    

    if [ ! -f "$nuclear_file" ]; then
        echo "Error: File $animals_file not found!" >&2
        let "a++"
        continue
    fi
    
    if [ ! -f "$mito_file" ]; then
        echo "Error: File $animals_file not found!" >&2
        let "a++"
        continue
    fi

    cat "$nuclear_file" "$mito_file" > "$output_dir/${a}.fa"
    
    let "a++"
done

echo "All samples processed successfully"


output_dir="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/final_plants"
mkdir -p "$output_dir"

a=1
while [ $a -le 30 ]
do
    echo "Processing sample $a"
    
    nuclear_file="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/simulated_plantsreads/${a}_nuclear.fa"
    mito_file="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/simulated_plantsreads/${a}_mito.fa"
    chlo_file="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/simulated_plantsreads/${a}_chlo.fa"

    if [ ! -f "$nuclear_file" ]; then
        echo "Error: File $plants_file not found!" >&2
        let "a++"
        continue
    fi
    
    if [ ! -f "$mito_file" ]; then
        echo "Error: File $plants_file not found!" >&2
        let "a++"
        continue
    fi

    if [ ! -f "$chlo_file" ]; then
        echo "Error: File $plants_file not found!" >&2
        let "a++"
        continue
    fi

    cat "$nuclear_file" "$mito_file" "$chlo_file" > "$output_dir/${a}.fa"
    
    let "a++"
done

echo "All samples processed successfully"
