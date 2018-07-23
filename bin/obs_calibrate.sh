#! /bin/bash

# USER CONFIG: change this to your project directory
base='/astro/mwasci/phancock/D0009/'

usage()
{
echo "obs_calibrate.sh [-d dep] [-q queue] [-n calname] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=gpuq
  -n calname : The name of the calibrator.
               Implies that this is a calibrator observation 
               and so calibration will be done.
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
dep=
queue='-p gpuq'
calname=
tst=

# parse args and set options
while getopts ':td:q:n:' OPTION
do
    case "$OPTION" in
	d)
	    dep=${OPTARG}
	    ;;

	n)
	    calname=${OPTARG}
	    ;;
	q)
	    queue="-p ${OPTARG}"
	    ;;
	t)
	    tst=1
	    ;;
	? | : | h)
	    usage
	    ;;
  esac
done
# set the obsid to be the first non option
shift  "$(($OPTIND -1))"
obsnum=$1

# if obsid is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi

# set dependency
if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi


script="${base}queue/calibrate_${obsnum}.sh"
cat ${base}/bin/calibrate.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                     -e "s:BASEDIR:${base}:g" \
                                     -e "s:CALIBRATOR:${calname}:g"  > ${script}

sub="sbatch ${depend} ${queue} ${script}"

if [[ ! -z ${tst} ]]
then
    echo "script is ${script}"
    echo "submit via:"
    echo "${sub}"
    exit 0
fi

# submit job
jobid=($(${sub}))
jobid=${jobid[3]}

echo "Submitted ${script} as ${jobid}"
