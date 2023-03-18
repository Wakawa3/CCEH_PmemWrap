TEST_ROOT=${HOME}/workloads/CCEH/CCEH-PMDK

rm ${TEST_ROOT}/src/libpmem.h
rm ${TEST_ROOT}/src/libpmemobj.h

cd ${TEST_ROOT}
patch -R Makefile < ${TEST_ROOT}/patch/MakefilePatch/CCEH-PMDK.patch

cd ${TEST_ROOT}/src
sed -i '1,4d' *.h