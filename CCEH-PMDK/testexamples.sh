TEST_ROOT=${HOME}/workloads/CCEH/CCEH-PMDK

PMEMWRAP_ROOT=${HOME}/PmemWrap
OUT_LOC=${TEST_ROOT}/outputs

PMIMAGE=/mnt/pmem0/test_cceh
COPYFILE=${PMIMAGE}_flushed
#BIN=single_threaded_cceh
BIN=$1

export PMEMWRAP_MULTITHREAD=SINGLE

if [[ ${BIN} =~ ^(multi_threaded_cceh|multi_threaded_cceh_CoW)$ ]]; then
    THREAD_OPT=16
    export PMEMWRAP_MULTITHREAD=MULTI
fi

patch Makefile < ${TEST_ROOT}/patch/MakefilePatch/CCEH-PMDK.patch
cd src
sed -i '1s/^/\}\n/' *.h
sed -i '1s/^/#include "libpmemobj.h"\n/' *.h
sed -i '1s/^/#include "libpmem.h"\n/' *.h
sed -i '1s/^/extern "C" \{\n/' *.h
cp ${PMEMWRAP_ROOT}/libpmem.h ${TEST_ROOT}/src
cp ${PMEMWRAP_ROOT}/libpmemobj.h ${TEST_ROOT}/src

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

make clean -j$(nproc)

rm ${TEST_ROOT}/src/libpmem.h
rm ${TEST_ROOT}/src/libpmemobj.h

cd ${TEST_ROOT}/src
sed -i '1,4d' *.h

cd ${TEST_ROOT}
patch -R Makefile < ${TEST_ROOT}/patch/MakefilePatch/CCEH-PMDK.patch