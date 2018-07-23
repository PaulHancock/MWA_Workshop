#! /bin/bash

# USER CONFIG: change this to your project directory
base='/astro/mwasci/phancock/D0009/'

usage()
{
echo "obs_apply_cal.sh [-d dep] [-q queue] [-c calid] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=gpuq
  -c calid    : obsid for calibrator.
                processing/calid/calid_*_solutions.bin will be used
                to calibrate if it exists, otherwise job will fail.
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
dep=
queue='-p gpuq'
calid=
tst=


# parse args and set options
while getopts ':td:q:c:' OPTION
do
    case "$OPTION" in
        d)
            dep=${OPTARG}
            ;;
	c)
	    calid=${OPTARG}
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

set -uo pipefail
# if obsid is empty then just print help

if [[ -z ${obsnum} ]]
then
    usage
fi

if [[ ! -z ${dep} ]]
then
    dep="--dependency=afterok:${dep}"
fi

# look for the calibrator solutions file
calfile=($( ls -1 ${base}/processing/${calid}/${calid}_*_solutions.bin))
calfile=${calfile[0]}

if [[ $? != 0 ]]
then
    echo "Could not find calibrator file"
    echo "looked for: ${base}/${calid}/${calid}_*_solutions.bin"
    exit 1
fi


script="${base}queue/apply_cal_${obsnum}.sh"
cat ${base}/bin/apply_cal.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                     -e "s:BASEDIR:${base}:g" \
                                     -e "s:CALFILE:${calfile}:g"  > ${script}

sub="sbatch ${dep} ${queue} ${script}"

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
