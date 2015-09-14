#!/usr/bin/env bash
## ======================================================================
## Run PXF regressions from build environment.  
##
##   Assumptions:
##
##     o The "gpdemo" directory has already been used to instantiate a
##       HAWQ cluster. The HAWQ cluster was instantiated to support the
##       installcheck-good execution.
##
##     o A single-cluster environment has already been deployed and
##       the correspondinbg PHD stack is running.
##
## ======================================================================

## ----------------------------------------------------------------------
## source environemnt files - this is needed to be able to restart the
## HAWQ cluster.
##
##   cluster_env.sh
##
##     MASTER_DATA_DIRECTORY
##     PGPORT
##
##   greenplum_path.sh
##
##     GPHOME
##     PATH
##     LD_LIBRARY_PATH
##     PYTHONPATH
##     PYTHONHOME
##     OPENSSL_CONF
##     LIBHDFS3_CONF
##     HADOOP_ROOT
##     HBASE_ROOT
## ----------------------------------------------------------------------

if [ -f ${BLDWRAP_TOP}/src/gpdemo/cluster_env.sh ] && \
   [ -f ${BLDWRAP_TOP}/src/greenplum-db-devel/greenplum_path.sh ]; then
    source ${BLDWRAP_TOP}/src/gpdemo/cluster_env.sh
    source ${BLDWRAP_TOP}/src/greenplum-db-devel/greenplum_path.sh
else
    echo "FATAL: hawq environmnent is not available"
    exit 1
fi

##
## start HAWQ
##

hawq start cluster -a

##
## Display HAWQ version string
##

echo `date` "Checking version"
echo "psql -p ${PGPORT} template1 -c \"select version();\""
echo "==============================================================================="
psql -p ${PGPORT} template1 -c "select version();" | grep "Post"
echo "==============================================================================="

##
## run pxf regression
##

SINGLECLUSTER=singlecluster-${SINGLECLUSTER_AS:=PHD}

export GPHD_ROOT=${BLDWRAP_TOP}/${SINGLECLUSTER}
export PXF_ROOT=${BLDWRAP_TOP}/${SINGLECLUSTER}/pxf

##
## Display running environment
##

echo ""
echo "----------------------------------------------------------------------"
echo "Running environment"
echo "----------------------------------------------------------------------"
echo ""
env
echo ""
echo "----------------------------------------------------------------------"
echo "Running java processes"
echo "----------------------------------------------------------------------"
echo ""
ps auxww | grep java | grep -v grep
echo ""
echo "----------------------------------------------------------------------"
echo "Running postgres processes"
echo "----------------------------------------------------------------------"
echo ""
ps auxww | grep postgres | grep -v grep
echo ""
echo "----------------------------------------------------------------------"

##
## Run PXF regressions
##

pushd ${BLDWRAP_TOP}/src/pxf

## Compile and copy regression resources to $GPHD_ROOT/pxf
make regression-resources
$GPHD_ROOT/bin/stop-pxf.sh
sleep 2s
$GPHD_ROOT/bin/start-pxf.sh

if [ ! -f $GPHD_ROOT/pxf/regression-test.jar ]; then
	echo WARNING: GPHD_ROOT/pxf/regression-test.jar doesnt exist
	echo GPHD_ROOT := $GPHD_ROOT
fi

## run the regressions
make regressions
PXF_REGRESSION_STATUS=$?

popd

##
## stop HAWQ
##

hawq stop cluster -a -M immediate

ps auxww | grep postgres | grep -v grep
if [ $? = 0 ]; then
    ps auxww | grep postgres | grep -v grep
    echo "FATAL: postgres processes are still running."
    exit 1
else
    echo "All postgres processes are stopped."
    exit $PXF_REGRESSION_STATUS
fi
