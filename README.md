# A semi-automated pipeline for the reduction of MWA data

This repo is a striped down fork of [MWA-fast-image-transients](https://github.com/PaulHancock/MWA-fast-image-transients).
The goal of this pipeline is to reduce the data observed by the MWA.

The pipeline is written for the Pawsey-Galaxy system which uses a SLURM job scheduler.

## Credits
Please credit Paul Hancock and Gemma Anderson if you use this code, or
incorporate it into your own workflow, as per the [licence](LICENCE).
Please acknowledge the use of this code by citing this repository, and until
we have a publication accepted on this work, we request that we be added as
co-authors on papers that rely on this code.

## Structure
- bin: executable files and template scripts
- processing: directory in which all the data is processed
- queue: location from which scripts are run
- queue/logs: log files

## Scripts and templates
Templates for scripts are `bin/*.tmpl`, these are modified by the `bin/obs_*.sh` scripts and the completed script is then put in `queue/<obsid>_*.sh` and submitted to SLURM.

### obs_asvo.sh
Use the [ASVO-mwa](https://asvo.mwatelescope.org) service to do the conversion job and then download the resulting measurement set.

usage:
```
obs_asvo.sh [-d dep] [-s timeav] [-k freqav] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -s timeav  : time averaging in sec. default = no averaging
  -k freqav  : freq averaging in KHz. default = no averaging
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```
uses templates:
- `asvo_dl_cotter.tmpl` (obsnum->OBSNUM/timeav->TRES/freqav->FRES)

### obs_calibrate.sh
Generate calibration solutions for a given observation.
This is done in a two stage process, and results in the final calibration solutions being applied to the dataset.

Usage:
```
obs_calibrate.sh [-d dep] [-q queue] [-n calname] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=gpuq
  -n calname : The name of the calibrator.
               Implies that this is a calibrator observation
               and so calibration will be done.
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses templates:
- `calibrate.tmpl` (calname->CALIBRATOR)
  - creates a new calibration solution using the calibrator model corresponding to the given name: file is `<obsnum>_<calmodel>_solutions_initial.bin`
  - plots the calibration solutions
  - applies the calibration solution to the data
  - runs `aoflagger` on the calibrated data
  - creates a new calibration solution: file is `<obsnum>_<calmodel>_solutions.bin`
  - replot the solutions
  

### obs_apply_cal.sh
Apply a pre-existing calibration solution to a measurement set.

Usage:
```
obs_apply_cal.sh [-d dep] [-q queue] [-c calid] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=gpuq
  -c calid    : obsid for calibrator.
                processing/calid/calid_*_solutions.bin will be used
                to calibrate if it exists, otherwise job will fail.
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process
```

uses tempaltes:
- `apply_cal.tmpl` (obsnum->OBSNUM, cal->CALOBSID)
  - applies the calibration solution from one data set to another


### obs_image.sh
Image a single observation.

Usage: 
```
obs_image.sh [-d dep] [-q queue] [-s imsize] [-p pixscale] [-c] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=gpuq
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -c         : clean image. Default False.
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```
uses tempaltes:
- `image.tmpl` (obsnum->OBSNUM/imsize->IMSIZE/scale->SCALE/clean->CLEAN)
  - make a single time/freq image and clean
  - perform primary beam correction on this image.

### obs_flag.sh
Perform flagging on a measurement set.
This consists of running `aoflagger` on the dataset (always), and if there is a supplied flag file it will be applied before running `aoflagger`


Usage:
```
obs_flag.sh [-d dep] [-q queue] [-f flagfile] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=gpuq
  -f flagfile : file to use for flagging
                default is processing/<obsnum>_tile_to_flag.txt
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process
```

uses tempaltes:
- `flag.tmpl` (obsnum->OBSNUM)

No job is submitted if the flagging file doesn't exist so this script is safe to include always.

### obs_flag_tiles.sh
Flags a single observation using the corresponding flag file.
The flag file should contain a list of integers being the tile numbers (all on one line, space separated).
This does *not* run `aoflagger`.


usage: 
```
obs_flag_tiles.sh [-d dep] [-q queue] [-f flagfile] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=gpuq
  -f flagfile : file to use for flagging
                default is processing/<obsnum>_tile_to_flag.txt
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process
```

uses templates:
- `flag_tiles.tmpl` (obsnum->OBSNUM)

### obs_sfind.sh
Run source finding on all the 2m, 28s, and 0.5s cadence stokes I, beam
corrected images for a given observation. 
(Or at least the subset which exist).

usage:
```
obs_sfind.sh [-d dep] [-q queue] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=gpuq
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process

```

uses tempaltes:
- `sfind.tmpl` (obsnum->OBSNUM)
  - run `BANE` and then `aegean` on each of the images
  

