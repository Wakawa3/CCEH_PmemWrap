TEST_ROOT=${HOME}/workloads/CCEH/CCEH-PMDK

PMEMWRAP_ROOT=${HOME}/PmemWrap
OUT_LOC=${TEST_ROOT}/outputs

PMIMAGE=/mnt/pmem0/test_cceh
COPYFILE=${PMIMAGE}_flushed
#BIN=single_threaded_cceh
BIN=$1

if [[ ${BIN} == multi_threaded_cceh ]]; then
    THREAD_OPT=16
fi

cd ${TEST_ROOT}
make clean -j$(nproc)
make -j$(nproc)

rm ${PMIMAGE}

${TEST_ROOT}/bin/${BIN} ${PMIMAGE} 30 ${THREAD_OPT}

echo "" > ${OUT_LOC}/${BIN}_abort.txt
echo "" > ${OUT_LOC}/${BIN}_error.txt

for i in `seq 20`
do
    echo "${i}" >> ${OUT_LOC}/${BIN}_abort.txt
    echo "${i}" >> ${OUT_LOC}/${BIN}_error.txt

    ${TEST_ROOT}/bin/${BIN} ${PMIMAGE} 30 ${THREAD_OPT} >> ${OUT_LOC}/${BIN}_output.txt 2>> ${OUT_LOC}/${BIN}_abort.txt

    bash -c "${TEST_ROOT}/bin/${BIN} ${PMIMAGE} 30 ${THREAD_OPT} >> ${OUT_LOC}/${BIN}_output.txt 2>> ${OUT_LOC}/${BIN}_error.txt" 2>>${OUT_LOC}/${BIN}_abort.txt
    rm ${PMIMAGE}
    echo "" >> ${OUT_LOC}/${BIN}_abort.txt
    echo "" >> ${OUT_LOC}/${BIN}_error.txt
done

make clean -j$(nproc)

