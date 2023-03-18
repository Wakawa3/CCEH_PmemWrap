TEST_ROOT=${HOME}/workloads/CCEH/CCEH-PMDK

PMEMWRAP_ROOT=${HOME}/PmemWrap
OUT_LOC=${TEST_ROOT}/outputs_safepm

PMIMAGE=/mnt/pmem0/test_cceh
COPYFILE=${PMIMAGE}_flushed
#BIN=single_threaded_cceh
BIN=$1

export ASAN_OPTIONS=halt_on_error=0:suppressions=/home/satoshi/PmemWrap/MyASan.supp

export PMEMWRAP_MULTITHREAD=SINGLE

if [[ ${BIN} =~ ^(multi_threaded_cceh|multi_threaded_cceh_CoW)$ ]]; then
    THREAD_OPT=16
    export PMEMWRAP_MULTITHREAD=MULTI
fi

cd ${TEST_ROOT}
make clean -j$(nproc)
make -j$(nproc)

rm ${PMIMAGE} ${COPYFILE}

export PMEMWRAP_ABORT=0
export PMEMWRAP_WRITECOUNTFILE=YES
export PMEMWRAP_MEMCPY=NO_MEMCPY
${TEST_ROOT}/bin/${BIN} ${PMIMAGE} 20 ${THREAD_OPT}
export PMEMWRAP_WRITECOUNTFILE=ADD
export PMEMWRAP_ABORTCOUNT_LOOP=20

OUTPUT_TEXT=${OUT_LOC}/${BIN}_output.txt
ABORT_TEXT=${OUT_LOC}/${BIN}_abort.txt
ERROR_TEXT=${OUT_LOC}/${BIN}_error.txt

echo "" > ${OUTPUT_TEXT}
echo "" > ${ABORT_TEXT}
echo "" > ${ERROR_TEXT}
# echo "" > ${OUT_LOC}/${BIN}_memcpy.txt

for i in `seq 20`
do
    echo "${i}" >> ${OUTPUT_TEXT}
    echo "${i}" >> ${ABORT_TEXT}
    echo "${i}" >> ${ERROR_TEXT}
    export PMEMWRAP_ABORT=1
    export PMEMWRAP_SEED=${i}
    export PMEMWRAP_MEMCPY=NO_MEMCPY
    ${TEST_ROOT}/bin/${BIN} ${PMIMAGE} 20 ${THREAD_OPT} >> ${OUTPUT_TEXT} 2>> ${ABORT_TEXT}
    ${PMEMWRAP_ROOT}/PmemWrap_memcpy.out ${PMIMAGE} ${COPYFILE}
#  >> ${OUT_LOC}/${BIN}_memcpy.txt

    export PMEMWRAP_ABORT=0
    export PMEMWRAP_MEMCPY=NO_MEMCPY
    timeout -k 1 30 bash -c "${TEST_ROOT}/bin/${BIN} ${PMIMAGE} 20 ${THREAD_OPT} >> ${OUTPUT_TEXT} 2>> ${ERROR_TEXT}" 2>>${ABORT_TEXT}
    echo "timeout $?" >> ${ABORT_TEXT}
    rm ${PMIMAGE} ${COPYFILE}
    
    echo "" >> ${OUTPUT_TEXT}
    echo "" >> ${ABORT_TEXT}
    echo "" >> ${ERROR_TEXT}
done