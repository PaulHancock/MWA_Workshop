#! /bin/bash

# USER CONFIG: change this to your project directory
base='/astro/mwasci/phancock/D0009/'

usage()
{
echo "obs_sfind.sh [-d dep] [-q queue] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=gpuq
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
dep=
queue='-p gpuq'
tst=

# parse args and set options
while getopts ':td:q:c:' OPTION
do
    case "$OPTION" in
	d)
	    dep=${OPTARG}
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

set -u

# if obsid is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi

if [[ ! -z ${dep} ]] 
then
    dep="--dependency=afterok:${dep}"
fi

script="${base}queue/sfind_${obsnum}.sh"
cat ${base}/bin/sfind.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:BASEDIR:${base}:g"  > ${script}

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
