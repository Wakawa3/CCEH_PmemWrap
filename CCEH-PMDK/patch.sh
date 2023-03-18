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