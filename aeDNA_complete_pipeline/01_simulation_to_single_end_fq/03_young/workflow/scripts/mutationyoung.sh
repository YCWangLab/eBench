#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=18
#SBATCH --mem=70000
#SBATCH -o mutaitiondeep

input_dir="/online1/ycsc_wx/ycwang/aeDNA/young/fragmented_microreads"
output_dir="/online1/ycsc_wx/ycwang/aeDNA/young/mutation_micro"

mkdir -p "$output_dir"
cd "$output_dir"

for file in "$input_dir"/*.fa
do

  bname=$(basename "$file" .fa)
  echo "Processing file: $bname"
  grep '>' "$file" > "$bname.header.txt" 
  awk 'NR%2==0' "$file" | tr '\n' '\t' | sed 's/\t/N/g' | sed '1i\>1' > "$bname.seq.fa" 
  mutation-simulator "$bname.seq.fa" args -sn 0.0001 -titv 1

  if [ ! -f "$bname.fa" ]; then
    echo "Error: Mutation output file $bname.fa not found!"
    continue
  fi
 
  sed '1d' "$bname.fa" | sed 's/N/\n/g' > "$bname.mutation.fa"  
  paste -d'*' "$bname.header.txt" "$bname.mutation.fa" | sed 's/*/\n/g' > "$bname.simulation.fa"
  diff "$file" "$bname.simulation.fa" -y | grep -B 1 '|' | sed '/--/d' | grep '>' | awk '{print $2}' | awk -F '[> ]' '{print $2}' > acession.txt
  cat "$bname.simulation.fa" | seqkit grep -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed 's/$/:v/;n' | sed '$ s/$/ \n/' > "$bname.variation.fa"
  cat "$bname.simulation.fa" | seqkit grep -v -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed '$ s/$/ \n/' > "$bname.invariation.fa"
  cat "$bname.variation.fa" "$bname.invariation.fa" > "$bname.sample.fa"  
  rm -f  acession.txt "$bname.variation.fa" "$bname.invariation.fa" \
     "$bname.header.txt" "$bname.seq.fa" "$bname.mutation.fa" \
     "$bname.simulation.fa" "$bname.fa" "$bname.vcf" "$bname.seq.fa.fai"
done

input_dir="/online1/ycsc_wx/ycwang/aeDNA/young/fragmented_animalsreads"
output_dir="/online1/ycsc_wx/ycwang/aeDNA/young/mutation_animals"

mkdir -p "$output_dir"
cd "$output_dir"

for file in "$input_dir"/*_nuclear.fa
do

  bname=$(basename "$file" .fa)
  echo "Processing file: $bname"

  grep '>' "$file" > "$bname.header.txt"
  awk 'NR%2==0' "$file" | tr '\n' '\t' | sed 's/\t/N/g' | sed '1i\>1' > "$bname.seq.fa"
  mutation-simulator "$bname.seq.fa" args -sn 0.00001 -titv 1

  if [ ! -f "$bname.fa" ]; then
    echo "Error: Mutation output file $bname.fa not found!"
    continue
  fi

  sed '1d' "$bname.fa" | sed 's/N/\n/g' > "$bname.mutation.fa"
  paste -d'*' "$bname.header.txt" "$bname.mutation.fa" | sed 's/*/\n/g' > "$bname.simulation.fa"
  diff "$file" "$bname.simulation.fa" -y | grep -B 1 '|' | sed '/--/d' | grep '>' | awk '{print $2}' | awk -F '[> ]' '{print $2}' > acession.txt
  cat "$bname.simulation.fa" | seqkit grep -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed 's/$/:v/;n' | sed '$ s/$/ \n/' > "$bname.variation.fa"
  cat "$bname.simulation.fa" | seqkit grep -v -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed '$ s/$/ \n/' > "$bname.invariation.fa"
  cat "$bname.variation.fa" "$bname.invariation.fa" > "$bname.sample.fa"
  

  rm -f  acession.txt "$bname.variation.fa" "$bname.invariation.fa" \
     "$bname.header.txt" "$bname.seq.fa" "$bname.mutation.fa" \
     "$bname.simulation.fa" "$bname.fa" "$bname.vcf" "$bname.seq.fa.fai"
done

input_dir="/online1/ycsc_wx/ycwang/aeDNA/young/fragmented_plantsreads"
output_dir="/online1/ycsc_wx/ycwang/aeDNA/young/mutation_plants"

mkdir -p "$output_dir"
cd "$output_dir"

for file in "$input_dir"/*_nuclear.fa
do

  bname=$(basename "$file" .fa)
  echo "Processing file: $bname"

  grep '>' "$file" > "$bname.header.txt"
  awk 'NR%2==0' "$file" | tr '\n' '\t' | sed 's/\t/N/g' | sed '1i\>1' > "$bname.seq.fa"
  mutation-simulator "$bname.seq.fa" args -sn 0.00001 -titv 1
  
  if [ ! -f "$bname.fa" ]; then
    echo "Error: Mutation output file $bname.fa not found!"
    continue
  fi

  sed '1d' "$bname.fa" | sed 's/N/\n/g' > "$bname.mutation.fa"
  paste -d'*' "$bname.header.txt" "$bname.mutation.fa" | sed 's/*/\n/g' > "$bname.simulation.fa"
  diff "$file" "$bname.simulation.fa" -y | grep -B 1 '|' | sed '/--/d' | grep '>' | awk '{print $2}' | awk -F '[> ]' '{print $2}' > acession.txt
  cat "$bname.simulation.fa" | seqkit grep -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed 's/$/:v/;n' | sed '$ s/$/ \n/' > "$bname.variation.fa"
  cat "$bname.simulation.fa" | seqkit grep -v -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed '$ s/$/ \n/' > "$bname.invariation.fa"
  cat "$bname.variation.fa" "$bname.invariation.fa" > "$bname.sample.fa"

  rm -f  acession.txt "$bname.variation.fa" "$bname.invariation.fa" \
     "$bname.header.txt" "$bname.seq.fa" "$bname.mutation.fa" \
     "$bname.simulation.fa" "$bname.fa" "$bname.vcf" "$bname.seq.fa.fai"
done


input_dir="/online1/ycsc_wx/ycwang/aeDNA/young/fragmented_animalsreads"
output_dir="/online1/ycsc_wx/ycwang/aeDNA/young/mutation_animals"


cd "$output_dir"

for file in "$input_dir"/*_mito.fa
do

  bname=$(basename "$file" .fa)
  echo "Processing file: $bname"

  grep '>' "$file" > "$bname.header.txt"
  awk 'NR%2==0' "$file" | tr '\n' '\t' | sed 's/\t/N/g' | sed '1i\>1' > "$bname.seq.fa"
  mutation-simulator "$bname.seq.fa" args -sn 0.0002 -titv 1

  if [ ! -f "$bname.fa" ]; then
    echo "Error: Mutation output file $bname.fa not found!"
    continue
  fi

  sed '1d' "$bname.fa" | sed 's/N/\n/g' > "$bname.mutation.fa"
  paste -d'*' "$bname.header.txt" "$bname.mutation.fa" | sed 's/*/\n/g' > "$bname.simulation.fa"
  diff "$file" "$bname.simulation.fa" -y | grep -B 1 '|' | sed '/--/d' | grep '>' | awk '{print $2}' | awk -F '[> ]' '{print $2}' > acession.txt
  cat "$bname.simulation.fa" | seqkit grep -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed 's/$/:v/;n' | sed '$ s/$/ \n/' > "$bname.variation.fa"
  cat "$bname.simulation.fa" | seqkit grep -v -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed '$ s/$/ \n/' > "$bname.invariation.fa"
  cat "$bname.variation.fa" "$bname.invariation.fa" > "$bname.sample.fa"

  rm -f  acession.txt "$bname.variation.fa" "$bname.invariation.fa" \
     "$bname.header.txt" "$bname.seq.fa" "$bname.mutation.fa" \
     "$bname.simulation.fa" "$bname.fa" "$bname.vcf" "$bname.seq.fa.fai"
done

input_dir="/online1/ycsc_wx/ycwang/aeDNA/young/fragmented_plantsreads"
output_dir="/online1/ycsc_wx/ycwang/aeDNA/young/mutation_plants"


cd "$output_dir"

for file in "$input_dir"/*_mito.fa
do

  bname=$(basename "$file" .fa)
  echo "Processing file: $bname"

  grep '>' "$file" > "$bname.header.txt"
  awk 'NR%2==0' "$file" | tr '\n' '\t' | sed 's/\t/N/g' | sed '1i\>1' > "$bname.seq.fa"
  mutation-simulator "$bname.seq.fa" args -sn 0.0002 -titv 1

  if [ ! -f "$bname.fa" ]; then
    echo "Error: Mutation output file $bname.fa not found!"
    continue
  fi

  sed '1d' "$bname.fa" | sed 's/N/\n/g' > "$bname.mutation.fa"
  paste -d'*' "$bname.header.txt" "$bname.mutation.fa" | sed 's/*/\n/g' > "$bname.simulation.fa"
  diff "$file" "$bname.simulation.fa" -y | grep -B 1 '|' | sed '/--/d' | grep '>' | awk '{print $2}' | awk -F '[> ]' '{print $2}' > acession.txt
  cat "$bname.simulation.fa" | seqkit grep -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed 's/$/:v/;n' | sed '$ s/$/ \n/' > "$bname.variation.fa"
  cat "$bname.simulation.fa" | seqkit grep -v -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed '$ s/$/ \n/' > "$bname.invariation.fa"
  cat "$bname.variation.fa" "$bname.invariation.fa" > "$bname.sample.fa"

  rm -f  acession.txt "$bname.variation.fa" "$bname.invariation.fa" \
     "$bname.header.txt" "$bname.seq.fa" "$bname.mutation.fa" \
     "$bname.simulation.fa" "$bname.fa" "$bname.vcf" "$bname.seq.fa.fai"
done

for file in "$input_dir"/*_chlo.fa
do

  bname=$(basename "$file" .fa)
  echo "Processing file: $bname"

  grep '>' "$file" > "$bname.header.txt"
  awk 'NR%2==0' "$file" | tr '\n' '\t' | sed 's/\t/N/g' | sed '1i\>1' > "$bname.seq.fa"
  mutation-simulator "$bname.seq.fa" args -sn 0.08 -titv 1

  if [ ! -f "$bname.fa" ]; then
    echo "Error: Mutation output file $bname.fa not found!"
    continue
  fi

  sed '1d' "$bname.fa" | sed 's/N/\n/g' > "$bname.mutation.fa"
  paste -d'*' "$bname.header.txt" "$bname.mutation.fa" | sed 's/*/\n/g' > "$bname.simulation.fa"
  diff "$file" "$bname.simulation.fa" -y | grep -B 1 '|' | sed '/--/d' | grep '>' | awk '{print $2}' | awk -F '[> ]' '{print $2}' > acession.txt
  cat "$bname.simulation.fa" | seqkit grep -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed 's/$/:v/;n' | sed '$ s/$/ \n/' > "$bname.variation.fa"
  cat "$bname.simulation.fa" | seqkit grep -v -f acession.txt | tr '\n' '\t' | sed 's/\t>/\n>/g' | sed 's/\t/\n/' | sed 's/\t//g' | sed '$ s/$/ \n/' > "$bname.invariation.fa"
  cat "$bname.variation.fa" "$bname.invariation.fa" > "$bname.sample.fa"

  rm -f  acession.txt "$bname.variation.fa" "$bname.invariation.fa" \
     "$bname.header.txt" "$bname.seq.fa" "$bname.mutation.fa" \
     "$bname.simulation.fa" "$bname.fa" "$bname.vcf" "$bname.seq.fa.fai"
done
