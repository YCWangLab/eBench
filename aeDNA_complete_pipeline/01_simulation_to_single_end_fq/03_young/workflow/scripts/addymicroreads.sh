#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=18
#SBATCH --mem=70000
#SBATCH -o addymicroreads

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMMON_INPUTS_DIR=${COMMON_INPUTS_DIR:-$(cd "$SCRIPT_DIR/../../../01_common_inputs" && pwd)}
REFERENCE_ROOT=${REFERENCE_ROOT:-$SCRIPT_DIR/../../../00_reference_download/work/split_genomes}

OUTPUT_DIR="/online1/ycsc_wx/ycwang/aeDNA/young/fragmented_microreads"
REF_DIR="$REFERENCE_ROOT/micro"
READS_DIR="/online1/ycsc_wx/ycwang/aeDNA/young/reads"
LEN_DIS_WHOLE="$COMMON_INPUTS_DIR/fragmentation/young_len_dis.txt"
GARGAMMEL="/online1/ycsc_wx/ycwang/PATH/gargammel/bin/fragSim"

mkdir -p "$OUTPUT_DIR"
a=1
while ((a <= 30)); do

    output_micro="${OUTPUT_DIR}/${a}.fa"
    rm -f "$output_micro"
    
    reads_file="${READS_DIR}/${a}.txt"
    if [[ ! -f "$reads_file" ]]; then
        echo "错误: 读取数文件 $reads_file 不存在!" >&2
        let "a++"
        continue
    fi
    
    c=1
    for micro_file in ${REF_DIR}/*.fna; do
        bname=$(basename "$micro_file" .fna)
        
        b=$(sed -n "${c}p" "$reads_file")
        export SEED=$((a * 1000 + c))
        
        if [[ -s "$micro_file" ]]; then
            echo "处理样本 $a, 基因组 $bname, 核基因组读取数 $b"

            index_file="${micro_file}.fai"
            if [[ ! -f "$index_file" ]]; then
                echo "为核基因组创建索引: $micro_file"
                samtools faidx "$micro_file" || {
                    echo "无法创建核基因组索引文件" >&2
                    exit 1
                }
            fi

            temp_output="${OUTPUT_DIR}/${a}_${bname}_micro_temp.fa"
            "$GARGAMMEL" \
                -n "$b" \
                -f "$LEN_DIS_WHOLE" \
                -o "${temp_output}.gz" \
                "$micro_file"

            if [[ -f "${temp_output}.gz" ]]; then
                gzip -d "${temp_output}.gz"
                cat "$temp_output" >> "$output_micro"
                rm -f "$temp_output"
                echo "成功添加 ${bname} 的核基因组片段"
            else
                echo "警告: ${bname} 的核基因组片段未生成!" >&2
            fi
        else
            echo "警告: 核基因组文件 $micro_file 不存在或为空，跳过核基因组模拟"
        fi
        
        ((c++))
    done
    ((a++))
done

