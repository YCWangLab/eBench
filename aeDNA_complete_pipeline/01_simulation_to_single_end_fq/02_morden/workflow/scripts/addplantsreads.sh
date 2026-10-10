#!/bin/bash
#SBATCH -p q_intel_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=18
#SBATCH --mem=70000
#SBATCH -o addplantsreads.log

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMMON_INPUTS_DIR=${COMMON_INPUTS_DIR:-$(cd "$SCRIPT_DIR/../../../01_common_inputs" && pwd)}
REFERENCE_ROOT=${REFERENCE_ROOT:-$SCRIPT_DIR/../../../00_reference_download/work/split_genomes}

OUTPUT_DIR="/online1/ycsc_wx/ycwang/aeDNA/morden/simulated_plantsreads"
REF_NUCLEAR_DIR="$REFERENCE_ROOT/plants/nuclear"
REF_MITO_DIR="$REFERENCE_ROOT/plants/mitochondrial"
REF_CHLO_DIR="$REFERENCE_ROOT/plants/chloroplast"
READS_DIR="/online1/ycsc_wx/ycwang/aeDNA/morden/plantsreads"
LEN_DIS_NUCLEAR="$COMMON_INPUTS_DIR/fragmentation/modern_len_dis.txt"
LEN_DIS_MITO="$COMMON_INPUTS_DIR/fragmentation/modern_len_dis.txt"

mkdir -p "$OUTPUT_DIR"
a=1
while ((a <= 30)); do

    output_nuclear="${OUTPUT_DIR}/${a}_nuclear.fa"
    output_mito="${OUTPUT_DIR}/${a}_mito.fa"
    output_chlo="${OUTPUT_DIR}/${a}_chlo.fa"
    rm -f "$output_nuclear" "$output_mito" "output_chlo"
    
    reads_file="${READS_DIR}/${a}.plants.txt"
    if [[ ! -f "$reads_file" ]]; then
        echo "错误: 读取数文件 $reads_file 不存在!" >&2
        let "a++"
        continue
    fi
    
    c=1
    for nuclear_file in ${REF_NUCLEAR_DIR}/*.fna; do
        bname=$(basename "$nuclear_file" .fna)
        
        b=$(sed -n "${c}p" "$reads_file")
        export SEED=$((a * 1000 + c))
        
        if [[ -s "$nuclear_file" ]]; then
            echo "处理样本 $a, 基因组 $bname, 核基因组读取数 $b"

            index_file="${nuclear_file}.fai"
            if [[ ! -f "$index_file" ]]; then
                echo "为核基因组创建索引: $nuclear_file"
                samtools faidx "$nuclear_file" || {
                    echo "无法创建核基因组索引文件" >&2
                    exit 1
                }
            fi

            temp_output="${OUTPUT_DIR}/${a}_${bname}_nuclear_temp.fa"
            "fragSim" \
                -n "$b" \
                -f "$LEN_DIS_NUCLEAR" \
                -o "${temp_output}.gz" \
                "$nuclear_file"

            if [[ -f "${temp_output}.gz" ]]; then
                gzip -d "${temp_output}.gz"
                cat "$temp_output" >> "$output_nuclear"
                rm -f "$temp_output"
                echo "成功添加 ${bname} 的核基因组片段"
            else
                echo "警告: ${bname} 的核基因组片段未生成!" >&2
            fi
        else
            echo "警告: 核基因组文件 $nuclear_file 不存在或为空，跳过核基因组模拟"
        fi
        
        mit_b=0

        mito_file="${REF_MITO_DIR}/${bname}.fna"

        if [[ -s "$mito_file" ]]; then
            mito_index_file="${mito_file}.fai"
            if [[ ! -f "$mito_index_file" ]]; then
                echo "为线粒体基因组创建索引: $mito_file"
                samtools faidx "$mito_file" || {
                    echo "无法创建线粒体基因组索引文件" >&2
                    mito_file=""
                }
            fi
            
            if [[ -n "$mito_file" ]]; then

                mit_b=$((b / 50))

         echo "处理样本 $a, 基因组 $bname, 线粒体读取数 $mit_b"
                export SEED=$((a * 1000 + c + 1000000))
                
                temp_output="${OUTPUT_DIR}/${a}_${bname}_mito_temp.fa"
                "fragSim" \
                    -n "$mit_b" \
                    -f "$LEN_DIS_MITO" \
                    -o "${temp_output}.gz" \
                    "$mito_file"
                
                if [[ -f "${temp_output}.gz" ]]; then
                    gzip -d "${temp_output}.gz"
                    cat "$temp_output" >> "$output_mito"
                    rm -f "$temp_output"
                    echo "成功添加 ${bname} 的线粒体片段"
                else
                    echo "警告: ${bname} 的线粒体片段未生成!" >&2
                fi
            fi
        else
            echo "警告: 线粒体基因组文件 $mito_file 不存在或为空，跳过线粒体模拟"
        fi

        chlo_b=0
        chlo_file="${REF_CHLO_DIR}/${bname}.fna"

        if [[ -s "$chlo_file" ]]; then
            chlo_index_file="${chlo_file}.fai"
            if [[ ! -f "$chlo_index_file" ]]; then
                echo "为叶绿体基因组创建索引: $chlo_file"
                samtools faidx "$chlo_file" || {
                    echo "无法创建叶绿体基因组索引文件" >&2
                    chlo_file=""
                }
            fi
            
            if [[ -n "$chlo_file" ]]; then

                chlo_b=$((b / 50))  
                echo "处理样本 $a, 基因组 $bname, 叶绿体读取数 $chlo_b"
                export SEED=$((a * 1000 + c + 2000000))
                
                temp_output="${OUTPUT_DIR}/${a}_${bname}_chlo_temp.fa"
                "fragSim" \
                    -n "$chlo_b" \
                    -f "$LEN_DIS_MITO" \
                    -o "${temp_output}.gz" \
                    "$chlo_file"
                
                if [[ -f "${temp_output}.gz" ]]; then
                    gzip -d "${temp_output}.gz"
                    cat "$temp_output" >> "$output_chlo"
                    rm -f "$temp_output"
                    echo "成功添加 ${bname} 的叶绿体片段"
                else
                    echo "警告: ${bname} 的叶绿体片段未生成!" >&2
                fi
            fi
        else
            echo "警告: 叶绿体基因组文件 $chlo_file 不存在或为空，跳过叶绿体模拟"
        fi

        echo $mit_b >> "${READS_DIR}/${a}.mit.txt"
        echo $chlo_b >> "${READS_DIR}/${a}.chlo.txt"
        
        ((c++))
    done
    ((a++))
done
        echo $mit_b >> "${READS_DIR}/${a}.mit.txt"
        ((c++))
    done
    ((a++))
done
