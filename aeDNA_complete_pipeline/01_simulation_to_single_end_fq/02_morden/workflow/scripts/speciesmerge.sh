#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=18
#SBATCH --mem=70000
#SBATCH -o merge

output_dir="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/final_morden"
mkdir -p "$output_dir"

a=1
while [ $a -le 30 ]
do
    echo "Processing sample $a"
    
    micro_file="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/simulated_microreads/${a}.fa"
    animals_file="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/final_animals/${a}.fa"
    plants_file="/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/aeDNA/morden/final_plants/${a}.fa"

    if [ ! -f "$micro_file" ]; then
        echo "Error: File $micro_file not found!" >&2
        let "a++"
        continue
    fi
    
    if [ ! -f "$animals_file" ]; then
        echo "Error: File $animals_file not found!" >&2
        let "a++"
        continue
    fi

    if [ ! -f "$plants_file" ]; then
        echo "Error: File $plants_file not found!" >&2
        let "a++"
        continue
    fi
    
    cat "$micro_file" "$animals_file" "$plants_file" > "$output_dir/${a}.fa"
    
    let "a++"
done

echo "All samples processed successfully"

