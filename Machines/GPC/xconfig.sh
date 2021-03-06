#!/bin/bash
WRFTOOLS="${CODE_ROOT}/WRF Tools/"
## scenario definition section
NAME='test'
# GHG emission scenario
GHG='RCP8.5' # CAMtr_volume_mixing_ratio.* file to be used
# time period and cycling interval
CYCLING="monthly.1979-2009" # stepfile to be used (leave empty if not cycling)
# I/O and archiving
IO='fineIO' # this is used for namelist construction and archiving
ARSYS='HPSS' # archiving on HPSS
AVGSYS='GPC' # post-processing on GPC
# use default scripts and intervals for archiving and post-processing

## configure data sources
RUNDIR="${PWD}" # must not contain spaces!
# source data definition
DATATYPE='CESM'
DATADIR="/scratch/p/peltier/marcdo/archive/tb20trcn1x1/"

## namelist definition section
# list of namelist groups and used snippets
MAXDOM=2 # number of domains in WRF and WPS
RES='30km'
DOM="arb2-${RES}"
# WRF
TIME_CONTROL="cycling,$IO"
DIAGS='hitop'
PHYSICS='clim'
NOAH_MP=''
DOMAINS="${DATATYPE,,}-${RES},${DOM}-grid" # lower-case datatype
FDDA='spectral'
DYNAMICS='default'
BDY_CONTROL='clim'
NAMELIST_QUILT=''
# WPS
# SHARE,GEOGRID, and METGRID usually don't have to be set manually
GEOGRID="${DOM},${DOM}-grid"
## namelist modifications by group
# you can make modifications to namelist groups in the {NMLGRP}_MOD variables
# the line in the *_MOD variable will replace the corresponding entry in the template
# you can separate multiple modifications by colons ':'
#PHYSICS_MOD=' cu_physics = 3, 3, 3,: shcu_physics = 0, 0, 0,: sf_surface_physics = 4, 4, 4,'
POLARWRF=0 # use PolarWRF
FLAKE=1 # use FLake

## system settings
# WPSWCT, WRFWCT, WRFNODES # wallclock time and number of nodes
# WPS executables
WPSSYS="GPC" # also affects unccsm.exe
# set path for metgrid.exe and real.exe explicitly using METEXE and REALEXE
# WRF executable
WRFSYS="GPC"
# set path for geogrid.exe and wrf.exe eplicitly using GEOEXE and WRFEXE
