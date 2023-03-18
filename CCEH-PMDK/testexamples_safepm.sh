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

echo "" > ${OUT_LOC}/${BIN}_output.txt
echo "" > ${OUT_LOC}/${BIN}_abort.txt
echo "" > ${OUT_LOC}/${BIN}_error.txt
# echo "" > ${OUT_LOC}/${BIN}_memcpy.txt

for i in `seq 20`
do
    echo "${i}" >> ${OUT_LOC}/${BIN}_output.txt
    echo "${i}" >> ${OUT_LOC}/${BIN}_abort.txt
    echo "${i}" >> ${OUT_LOC}/${BIN}_error.txt
    export PMEMWRAP_ABORT=1
    export PMEMWRAP_SEED=${i}
    export PMEMWRAP_MEMCPY=NO_MEMCPY
    ${TEST_ROOT}/bin/${BIN} ${PMIMAGE} 20 ${THREAD_OPT} >> ${OUT_LOC}/${BIN}_output.txt 2>> ${OUT_LOC}/${BIN}_abort.txt
    ${PMEMWRAP_ROOT}/PmemWrap_memcpy.out ${PMIMAGE} ${COPYFILE}
#  >> ${OUT_LOC}/${BIN}_memcpy.txt

    export PMEMWRAP_ABORT=0
    export PMEMWRAP_MEMCPY=NO_MEMCPY
    timeout -k 1 30 bash -c "${TEST_ROOT}/bin/${BIN} ${PMIMAGE} 20 ${THREAD_OPT} >> ${OUT_LOC}/${BIN}_output.txt 2>> ${OUT_LOC}/${BIN}_error.txt" 2>>${OUT_LOC}/${BIN}_abort.txt
    echo "timeout $?" >> ${OUT_LOC}/${BIN}_abort.txt
    rm ${PMIMAGE} ${COPYFILE}
    
    echo "" >> ${OUT_LOC}/${BIN}_output.txt
    echo "" >> ${OUT_LOC}/${BIN}_abort.txt
    echo "" >> ${OUT_LOC}/${BIN}_error.txt
done