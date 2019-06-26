#!/bin/bash -l
#
#-----------------------------------------------------------------------
#
# This script generates NetCDF lateral boundary condition (LBC) files 
# that contain data for the halo region of a regional grid.  One file is
# generated for each lateral boundary update time -- not including the 
# initial (i.e. model start) time -- up to the end of the model run.  
# For example, if the lateral boundary fields are to be updated every 3
# hours (this update interval is determined by the variable LBC_UPDATE_-
# INTVL_HRS) and the FV3SAR forecast is to run for 24 hours (the fore-
# cast length is determined by the variable fcst_len_hrs), then a file 
# is generated for each of the forecast hours 3, 6, 9, 12, 15, 18, and
# 24 (but not hour 0 since that is handled by the script that generates 
# the initial conditions file).  All the generated NetCDF LBC files are
# placed in the directory WORKDIR_ICSLBCS_CDATE, defined as
#
#   WORKDIR_ICSLBCS_CDATE="$WORKDIR_ICSLBCS/$CDATE"
#
# where CDATE is the externally specified starting date and hour-of-day
# of the current FV3SAR cycle.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Set the name of and create the directory in which the output from this
# script will be placed (if it doesn't already exist).
#
#-----------------------------------------------------------------------
#
WORKDIR_ICSLBCS_CDATE="$WORKDIR_ICSLBCS/$CDATE"
WORKDIR_ICSLBCS_CDATE_LBCS_WORK="$WORKDIR_ICSLBCS_CDATE/LBCS_work"
mkdir_vrfy -p "$WORKDIR_ICSLBCS_CDATE_LBCS_WORK"
cd ${WORKDIR_ICSLBCS_CDATE_LBCS_WORK}
#-----------------------------------------------------------------------
#
# Set the directory in which all executables called by this script are
# located.
#
#-----------------------------------------------------------------------
#
export exec_dir="$FV3SAR_DIR/exec"
#
#-----------------------------------------------------------------------
#
# Load modules and set machine-dependent parameters.
#
#-----------------------------------------------------------------------
#
case "$MACHINE" in
#
"WCOSS_C")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"WCOSS")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"DELL")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"THEIA")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

   ulimit -s unlimited
   ulimit -a

   module purge
   module load intel/18.1.163
   module load impi/5.1.1.109
   module load netcdf/4.3.0
   module load hdf5/1.8.14
   module load wgrib2/2.0.8
   module load contrib wrap-mpi
   module list

  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"   

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"JET")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"ODIN")
#
  ;;
#
"CHEYENNE")
#
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Create links to the grid and orography files with 4 halo cells.  These
# are needed by chgres_cube to create the boundary data.
#
#-----------------------------------------------------------------------
#
# Are these still needed for chgres_cube???
ln_vrfy -sf $WORKDIR_SHVE/${CRES}_grid.tile7.halo${nh4_T7}.nc \
            $WORKDIR_SHVE/${CRES}_grid.tile7.nc

ln_vrfy -sf $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${nh4_T7}.nc \
            $WORKDIR_SHVE/${CRES}_oro_data.tile7.nc
#
#-----------------------------------------------------------------------
#
# Find the directory in which the wgrib2 executable is located.
#
#-----------------------------------------------------------------------
#
WGRIB2_DIR=$( which wgrib2 ) || print_err_msg_exit "\
Directory in which the wgrib2 executable is located not found:
  WGRIB2_DIR = \"${WGRIB2_DIR}\"
"
#
#-----------------------------------------------------------------------
#
# Set the directory containing the external model output files.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_FILES_DIR="${EXTRN_MDL_FILES_BASEDIR_LBCS}/${CDATE}"
#
#-----------------------------------------------------------------------
#
# Source the file (generated by a previous task) that contains variable
# definitions (e.g. forecast hours, file and directory names, etc) re-
# lated to the exteranl model run that is providing fields from which
# we will generate LBC files for the FV3SAR.
#
#-----------------------------------------------------------------------
#
. ${EXTRN_MDL_FILES_DIR}/${EXTRN_MDL_INFO_FN}
#
#-----------------------------------------------------------------------
#
# Get the name of the external model to use in the chgres FORTRAN name-
# list file.
#
#-----------------------------------------------------------------------
#
case "$EXTRN_MDL_NAME_LBCS" in
#
"GFS")
  external_model="GFS"
  ;;
"RAPX")
  external_model="RAP"
  ;;
"HRRRX")
  external_model="HRRR"
  ;;
*)
  print_err_msg_exit "\
The external model name to use in the chgres FORTRAN namelist file is 
not specified for this external model:
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\"
"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Get the name of the physics suite to use in the chgres FORTRAN name-
# list file.
#
#-----------------------------------------------------------------------
#
case "$CCPP_phys_suite" in
#
"GFS")
  phys_suite="GFS"
  ;;
"GSD")
  phys_suite="GSD"
  ;;
*)
  print_err_msg_exit "\
The physics suite name to use in the chgres FORTRAN namelist file is not
specified for this physics suite:
  CCPP_phys_suite = \"${CCPP_phys_suite}\"
"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Loop through the LBC update times and run chgres for each such time to
# obtain an LBC file for each that can be used as input to the FV3SAR.
#
#-----------------------------------------------------------------------
#
fn_sfc_nemsio=""

num_fhrs="${#EXTRN_MDL_LBC_UPDATE_FHRS[@]}"
for (( i=0; i<=$(( $num_fhrs - 1 )); i++ )); do
#
# Get the forecast hour of the external model.
#
  fhr="${EXTRN_MDL_LBC_UPDATE_FHRS[$i]}"
#
# Set external model output file name and file type/format.  Note that
# these are now inputs into chgres.
#
  fn_atm_nemsio=""
  fn_grib2=""
  input_type=""

  case "$EXTRN_MDL_NAME_LBCS" in
  "GFS")
    fn_atm_nemsio="${EXTRN_MDL_FNS[$i]}"
    input_type="gfs_gaussian" # For spectral GFS Gaussian grid in nemsio format.
#    input_type="gaussian"     # For FV3-GFS Gaussian grid in nemsio format.
    ;;
  "RAPX")
    fn_grib2="${EXTRN_MDL_FNS[$i]}"
    input_type="grib2"
    ;;
  "HRRRX")
    fn_grib2="${EXTRN_MDL_FNS[$i]}"
    input_type="grib2"
    ;;
  *)
    print_err_msg_exit "\
The external model output file name and input file type to use in the 
chgres FORTRAN namelist file are not specified for this external model:
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\"
"
    ;;
  esac
#
# Get the starting year, month, day, and hour of the the external model
# run.  Then add the forecast hour to it to get a date and time corres-
# ponding to the current forecast time.
#
#  yyyy="${EXTRN_MDL_CDATE:0:4}"
  mm="${EXTRN_MDL_CDATE:4:2}"
  dd="${EXTRN_MDL_CDATE:6:2}"
  hh="${EXTRN_MDL_CDATE:8:2}"
  yyyymmdd="${EXTRN_MDL_CDATE:0:8}"

  cdate_crnt_fhr=$( date --utc --date "${yyyymmdd} ${hh} UTC + ${fhr} hours" "+%Y%m%d%H" )
#
# Get the year, month, day, and hour corresponding to the current fore-
# cast time of the the external model.
#
#  yyyy="${cdate_crnt_fhr:0:4}"
  mm="${cdate_crnt_fhr:4:2}"
  dd="${cdate_crnt_fhr:6:2}"
  hh="${cdate_crnt_fhr:8:2}"
#
# Build the FORTRAN namelist file that chgres_cube will read in.
#
  cat > fort.41 <<EOF
&config
 fix_dir_target_grid="/scratch3/BMC/det/beck/FV3-CAM/sfc_climo_final_C3343"
 mosaic_file_target_grid="${EXPTDIR}/INPUT/${CRES}_mosaic.nc"
 orog_dir_target_grid="${EXPTDIR}/INPUT"
 orog_files_target_grid="${CRES}_oro_data.tile7.halo${nh4_T7}.nc"
 vcoord_file_target_grid="${FV3SAR_DIR}/fix/fix_am/global_hyblev.l65.txt"
 mosaic_file_input_grid=""
 orog_dir_input_grid=""
 base_install_dir="/scratch3/BMC/det/beck/FV3-CAM/UFS_UTILS_chgres_bug_fix"
 wgrib2_path="${WGRIB2_DIR}"
 data_dir_input_grid="${EXTRN_MDL_FILES_DIR}"
 atm_files_input_grid="${fn_atm_nemsio}"
 sfc_files_input_grid="${fn_sfc_nemsio}"
 grib2_file_input_grid="${fn_grib2}"
 cycle_mon=${mm}
 cycle_day=${dd}
 cycle_hour=${hh}
 convert_atm=.true.
 convert_sfc=.false.
 convert_nst=.false.
 regional=2
 input_type="${input_type}"
 external_model="${external_model}"
 phys_suite="${phys_suite}"
 numsoil_out=9
 replace_vgtyp=.false.
 replace_sotyp=.false.
 replace_vgfrc=.false.
 tg3_from_soil=.true.
/
EOF
#
# Run chgres_cube.
#
#  ${APRUN} ${exec_dir}/global_chgres.exe || print_err_msg_exit "\
#${APRUN} /scratch3/BMC/det/beck/FV3-CAM/UFS_UTILS_chgres_bug_fix/sorc/chgres_cube.fd/exec/global_chgres.exe || print_err_msg_exit "\
${APRUN} /scratch3/BMC/det/beck/FV3-CAM/UFS_UTILS_chgres_bug_fix/exec/chgres_cube.exe || print_err_msg_exit "\
Call to executable to generate lateral boundary conditions file for the
the FV3SAR failed."
#
# Move LBCs file for the current lateral boundary update time to the ICs
# /LBCs work directory.  Note that we rename the file using the forecast
# hour of the FV3SAR (which is not necessarily the same as that of the 
# external model since their start times may be offset).
#
  fcst_hhh_FV3SAR=$( printf "%03d" "${LBC_UPDATE_FCST_HRS[$i]}" )
  mv_vrfy gfs_bndy.nc ${WORKDIR_ICSLBCS_CDATE}/gfs_bndy.tile7.${fcst_hhh_FV3SAR}.nc

done
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

========================================================================
Lateral boundary condition (LBC) files generated successfully for all 
LBC update hours!!!
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
