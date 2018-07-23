#! /bin/bash

# USER CONFIG: change this to your project directory
base='/astro/mwasci/phancock/D0009/'

usage()
{
echo "obs_image.sh [-d dep] [-q queue] [-s imsize] [-p pixscale] [-c] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=gpuq
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -c         : clean image. Default False.
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
dep=
queue='-p gpuq'
imsize=
pixscale=
clean=
tst=

# parse args and set options
while getopts ':tcd:q:s:p:' OPTION
do
    case "$OPTION" in
	d)
	    dep=${OPTARG}
	    ;;
	q)
	    queue="-p ${OPTARG}"
	    ;;
	s)
	    imsize=${OPTARG}
	    ;;
	p)
	    pixscale=${OPTARG}
	    ;;
	c)
	    clean="yes"
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


if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi


# start the real program

script="${base}queue/image_${obsnum}.sh"
cat ${base}/bin/image.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:BASEDIR:${base}:g" \
                                 -e "s:IMSIZE:${imsize}:g" \
                                 -e "s:SCALE:${pixscale}:g" \
                                 -e "s:CLEAN:${clean}:g" > ${script}

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
