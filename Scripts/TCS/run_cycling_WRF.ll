#!/usr/bin/bash
# Specifies the name of the shell to use for the job 
# @ shell = /usr/bin/bash
# @ job_name = cycling_WRF
# @ wall_clock_limit = 06:00:00
# @ node = 4 
# @ tasks_per_node = 64
# @ environment = COPY_ALL; MEMORY_AFFINITY=MCM; MP_SYNC_QP=YES; \
#                MP_RFIFO_SIZE=16777216; MP_SHM_ATTACH_THRESH=500000; \
#                MP_EUIDEVELOP=min; MP_USE_BULK_XFER=yes; \
#                MP_RDMA_MTU=4K; MP_BULK_MIN_MSG_SIZE=64k; MP_RC_MAX_QP=8192; \
#                PSALLOC=early; NODISCLAIM=true
# @ job_type = parallel
# @ class = verylong
# @ node_usage = not_shared
# @ output = $(job_name).$(jobid).out
# @ error = $(job_name).$(jobid).out
#=====================================
## this is necessary in order to avoid core dumps for batch files
## which can cause the system to be overloaded
# ulimits
# @ core_limit = 0
#=====================================
## necessary to force use of infiniband network for MPI traffic
# @ network.MPI = sn_all,not_shared,US,HIGH
#=====================================
# @ queue

# check if $NEXTSTEP is set, and exit, if not
set -e # abort if anything goes wrong
if [[ -z "${NEXTSTEP}" ]]; then exit 1; fi
CURRENTSTEP="${NEXTSTEP}" # $NEXTSTEP will be overwritten


## job settings
export SCRIPTNAME="run_${LOADL_JOB_NAME}.ll" # WRF suffix assumed
export DEPENDENCY="run_${LOADL_JOB_NAME%_WRF}_WPS.pbs" # run WPS on GPC (WPS suffix substituted for WRF)
export CLEARWDIR=0 # do not clear working director
# run configuration
export NODES=5 # also has to be set in LL section
export TASKS=64 # number of MPI task per node (Hpyerthreading!)
export THREADS=1 # number of OpenMP threads
# directory setup
export INIDIR="${LOADL_STEP_INITDIR}" # launch directory
export RUNNAME="${CURRENTSTEP}" # step name, not job name!
export WORKDIR="${INIDIR}/${RUNNAME}/"

## real.exe settings
# optional arguments: $RUNREAL, $RAMIN, $RAMOUT
# folders: $REALIN, $REALOUT
# N.B.: RAMIN/OUT only works within a single node!

## WRF settings
# optional arguments: $RUNWRF, $GHG ($RAD, $LSM) 
export GHG='A2' # GHG emission scenario
# folders: $WRFIN, $WRFOUT, $TABLES
export REALOUT="${WORKDIR}" # this should be default anyway
export WRFIN="${WORKDIR}" # same as $REALOUT
export WRFOUT="${INIDIR}/wrfout/" # output directory


## setup job environment
cd "${INIDIR}"
source setupTCS.sh # load machine-specific stuff


## start execution
# work in existing work dir, created by caller instance
# N.B.: don't remove namelist files in working directory

# read next step from stepfile
NEXTSTEP=$(python cycling.py ${CURRENTSTEP})

# launch WPS for next step (if $NEXTSTEP is not empty)
if [[ -n "${NEXTSTEP}" ]]
 then
	echo "   ***   Launching WPS for next step: ${NEXTSTEP}   ***   "
	echo
	# submitting independent WPS job to GPC (not TCS!)
	ssh gpc-f104n084 "cd \"${INIDIR}\"; qsub ./${DEPENDENCY} -v NEXTSTEP=${NEXTSTEP}"
	#cho '   >>>   Skip WPS for now.   <<<'
fi


## run WRF for this step
echo
echo "   ***   Launching WRF for current step: ${CURRENTSTEP}   ***   "
date
echo

# prepare directory
cd "${INIDIR}"
./prepWorkDir.sh
# run script
./execWRF.sh
# mock restart files for testing (correct linking)
#if [[ -n "${NEXTSTEP}" ]]; then	  
#	touch "${WORKDIR}/wrfrst_d01_${NEXTSTEP}_00"
#	touch "${WORKDIR}/wrfrst_d01_${NEXTSTEP}_01" 
#fi 
wait # wait for WRF and WPS to finish

# end timing
echo
echo "   ***   WRF step ${CURRENTSTEP} completed   ***   "
date
echo


## launch WRF for next step (if $NEXTSTEP is not empty)
if [[ -n "${NEXTSTEP}" ]]
  then
	NEXTDIR="${INIDIR}/${NEXTSTEP}" # next $WORKDIR
	cd "${NEXTDIR}"
	# link restart files
	echo 
	echo "Linking restart files to next working directory:"
	echo "${NEXTDIR}"
	for RESTART in "${WORKDIR}"/wrfrst_d??_*; do
		if [[ ! -h "${RESTART}" ]]; then ln -sf "${RESTART}"; fi # if not a link itself
	done
	# check for WRF input files (in next working directory)
	if [[ ! -e "${INIDIR}/${NEXTSTEP}/wrfinput_d01" ]]
	  then
		echo
		echo "   ***   Waiting for WPS to complete...   ***"
		echo
		while [[ ! -e "${INIDIR}/${NEXTSTEP}/wrfinput_d01" ]]; do
			sleep 5 # need faster turnover to submit next step
		done
	fi
	# start next cycle
	cd "${INIDIR}"
	echo
	echo "   ***   Launching WRF for next step: ${NEXTSTEP}   ***   "
	echo
	# submit next job to LoadLeveler (TCS)
	#ssh tcs-f11n06 "cd \"${INIDIR}\"; export NEXTSTEP=${NEXTSTEP}; llsubmit ./${SCRIPTNAME}"
	export NEXTSTEP=${NEXTSTEP}
	llsubmit ./${SCRIPTNAME}
fi
