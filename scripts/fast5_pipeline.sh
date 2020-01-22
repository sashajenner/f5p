#!/bin/bash
# @author: Hasindu Gamaarachchi (hasindu@unsw.edu.au)
# @coauthor: Sasha Jenner (jenner.sasha@gmail.com)

###############################################################################
USAGE="Usage: $0 -f <format> [options ...] <filepath>"
: ${3?$USAGE} # require at least 3 args else give usage message

HELP=$"Flags:
-f, --format        follows a specified format of fast5 and fastq files
        --778           <in_dir>
                        |-- fast5/
                            |-- <prefix>.fast5.tar
                        |-- fastq/
                            |-- fastq_*.<prefix>.fastq.gz
        
        --NA            <in_dir>
                        |-- fast5/
                            |-- <prefix>.fast5
                        |-- fastq/
                            |-- <prefix>/
                                |-- <prefix>.fastq

        --zebra         [directory]               Newest format
                        |-- fast5/
                            |-- [prefix].fast5
                        |-- fastq/
                            |-- [prefix].fastq
                                
-h, --help          help message"

format_specified=false # assume no format specified

## Handle flags
while [ ! $# -eq 0 ]; do # while there are arguments
    case "$1" in

        --format | -f)
			format_specified=true

			case "$2" in

				--778 | --NA | --zebra)
					FORMAT=$2
					;;

				*)
					echo "Incorrect or no format specified"
					echo $USAGE
					echo "$HELP"
					exit 1
					;;
            esac
			shift
			;;

        --help | -h)
            echo $USAGE
            echo "$HELP"
            exit 0
            ;;
        
        *)
            FILE=$1
            ;;

    esac
    shift
done

if ! $format_specified; then # exit if no format specified
	echo "No format specified!"
	echo $USAGE
	echo "$HELP"
	exit 1
fi

## Changeable definitions

# program paths
MINIMAP=/nanopore/bin/minimap2-arm
METHCALL=/nanopore/bin/f5c # or nanopolish
SAMTOOLS=/nanopore/bin/samtools

REF_FA=/nanopore/reference/hg38noAlt.fa # reference fasta for methylation call
REF_IDX=/nanopore/reference/hg38noAlt.idx # reference index for minimap2

# temporary space on the local storage or the network mount
SCRATCH=/nanopore/scratch

###############################################################################

if [ "$FORMAT" = "--778" ]; then

    F5_TAR_FILEPATH=$FILE # first argument
    F5_DIR=${F5_TAR_FILEPATH%/*} # strip filename from .fast5.tar filepath
    PARENT_DIR=${F5_DIR%/*} # get folder one heirarchy higher

    # name of the .fast5.tar file (strip the path and get only the name with extension)
    F5_TAR_FILENAME=$(basename $F5_TAR_FILEPATH)
    # name of the .fast5.tar file without extensions
    F5_PREFIX=${F5_TAR_FILENAME%%.*}

    # derive the locations of input and output files
    FQ_GZ_FILEPATH=$PARENT_DIR/fastq/fastq_*.$F5_PREFIX.fastq.gz
    SAM_DIR=$PARENT_DIR/sam
    BAM_DIR=$PARENT_DIR/bam
    METH_DIR=$PARENT_DIR/methylation
    LOG_DIR=$PARENT_DIR/log2

    # derive the locations of temporary files
    F5_DIR_LOCAL=$SCRATCH/$F5_PREFIX
    FQ_LOCAL=$SCRATCH/$F5_PREFIX.fastq
    SAM_LOCAL=$SCRATCH/$F5_PREFIX.sam
    BAM_LOCAL=$SCRATCH/$F5_PREFIX.bam
    METH_LOCAL=$SCRATCH/$F5_PREFIX.tsv
    LOG_LOCAL=$SCRATCH/$F5_PREFIX.log
    MINIMAP_LOCAL=$SCRATCH/$F5_PREFIX.minimap

    # (todo : optimise? --overwrite flag with tar?)
    test -d $F5_DIR_LOCAL && rm -rf $F5_DIR_LOCAL # remove local fast5 directory if it exists
    mkdir -p $F5_DIR_LOCAL # make local fast5 directory and create parent directories if needed
    tar -xf $F5_TAR_FILEPATH -C $F5_DIR_LOCAL # untar fast5 file into local fast5 directory

    gunzip -dc < $FQ_GZ_FILEPATH > $FQ_LOCAL # unzip fastq file locally

elif [ "$FORMAT" = "--NA" ]; then
    
    F5_FILEPATH=$FILE # first argument
    F5_DIR=${F5_FILEPATH%/*} # strip filename from .fast5 filepath
    PARENT_DIR=${F5_DIR%/*} # get folder one heirarchy higher

    # name of the .fast5 file (strip the path and get only the name with extension)
    F5_FILENAME=$(basename $F5_FILEPATH)
    # name of the .fast5 file without the extension
    F5_PREFIX=${F5_FILENAME%.*}

    # derive the locations of input and output files
    FQ_FILEPATH=$PARENT_DIR/fastq/$F5_PREFIX/$F5_PREFIX.fastq
    SAM_DIR=$PARENT_DIR/sam
    BAM_DIR=$PARENT_DIR/bam
    METH_DIR=$PARENT_DIR/methylation
    LOG_DIR=$PARENT_DIR/log2

    # derive the locations of temporary files
    F5_DIR_LOCAL=$SCRATCH/$F5_PREFIX
    FQ_LOCAL=$SCRATCH/$F5_PREFIX.fastq
    SAM_LOCAL=$SCRATCH/$F5_PREFIX.sam
    BAM_LOCAL=$SCRATCH/$F5_PREFIX.bam
    METH_LOCAL=$SCRATCH/$F5_PREFIX.tsv
    LOG_LOCAL=$SCRATCH/$F5_PREFIX.log
    MINIMAP_LOCAL=$SCRATCH/$F5_PREFIX.minimap

    test -d $F5_DIR_LOCAL && rm -rf $F5_DIR_LOCAL # remove local fast5 directory if it exists
    mkdir -p $F5_DIR_LOCAL # make local fast5 directory and create parent directories if needed
    cp $F5_FILEPATH $F5_DIR_LOCAL # copy fast5 file into local fast5 directory

    cat $FQ_FILEPATH > $FQ_LOCAL

elif [ "$FORMAT" = "--zebra" ]; then

    F5_FILEPATH=$FILE # first argument
    F5_DIR=${F5_FILEPATH%/*} # strip filename from .fast5 filepath
    PARENT_DIR=${F5_DIR%/*} # get folder one heirarchy higher

    # name of the .fast5 file (strip the path and get only the name with extension)
    F5_FILENAME=$(basename $F5_FILEPATH)
    # name of the .fast5 file without the extension
    F5_PREFIX=${F5_FILENAME%.*}

    # derive the locations of input and output files
    FQ_FILEPATH=$PARENT_DIR/fastq/$F5_PREFIX.fastq
    SAM_DIR=$PARENT_DIR/sam
    BAM_DIR=$PARENT_DIR/bam
    METH_DIR=$PARENT_DIR/methylation
    LOG_DIR=$PARENT_DIR/log2

    # derive the locations of temporary files
    F5_DIR_LOCAL=$SCRATCH/$F5_PREFIX
    FQ_LOCAL=$SCRATCH/$F5_PREFIX.fastq
    SAM_LOCAL=$SCRATCH/$F5_PREFIX.sam
    BAM_LOCAL=$SCRATCH/$F5_PREFIX.bam
    METH_LOCAL=$SCRATCH/$F5_PREFIX.tsv
    LOG_LOCAL=$SCRATCH/$F5_PREFIX.log
    MINIMAP_LOCAL=$SCRATCH/$F5_PREFIX.minimap

    test -d $F5_DIR_LOCAL && rm -rf $F5_DIR_LOCAL # remove local fast5 directory if it exists
    mkdir -p $F5_DIR_LOCAL # make local fast5 directory and create parent directories if needed
    cp $F5_FILEPATH $F5_DIR_LOCAL # copy fast5 file into local fast5 directory

    cat $FQ_FILEPATH > $FQ_LOCAL

fi

exit_status=0 # assume success

# index
/usr/bin/time -v $METHCALL index -d $F5_DIR_LOCAL $FQ_LOCAL 2> $LOG_LOCAL || (exit_status=1; echo "index failed")

# minimap
/usr/bin/time -v $MINIMAP -x map-ont -a -t4 -K5M --secondary=no --multi-prefix=$MINIMAP_LOCAL $REF_IDX $FQ_LOCAL > $SAM_LOCAL 2>> $LOG_LOCAL || (exit_status=1; echo "minimap failed")

# sorting
/usr/bin/time -v $SAMTOOLS sort -@3 $SAM_LOCAL > $BAM_LOCAL 2>> $LOG_LOCAL || (exit_status=1; echo "samtools sorting failed")
/usr/bin/time -v $SAMTOOLS index $BAM_LOCAL 2>> $LOG_LOCAL || (exit_status=1; echo "samtools index failed")

# methylation
/usr/bin/time -v $METHCALL call-methylation -t 4 -r $FQ_LOCAL -g $REF_FA -b $BAM_LOCAL -K 256 > $METH_LOCAL  2>> $LOG_LOCAL || (exit_status=1; echo "methylation failed")

# copy results to the correct place and create directories first if they do not exist
mkdir -p $METH_DIR && cp $METH_LOCAL "$_"
mkdir -p $SAM_DIR && cp $SAM_LOCAL "$_"
mkdir -p $BAM_DIR && cp $BAM_LOCAL "$_"
mkdir -p $LOG_DIR && cp $LOG_LOCAL "$_"
    
# remove the rest    
rm -rf $F5_DIR_LOCAL # remove all from the local fast5 directory
# remove all fastq files
rm -f $FQ_LOCAL $FQ_LOCAL.index $FQ_LOCAL.index.fai $FQ_LOCAL.index.gzi $FQ_LOCAL.index.readdb
rm -f $SAM_LOCAL $BAM_LOCAL $BAM_LOCAL.bai $METH_LOCAL # remove SAM, BAM and methylation files

exit $exit_status # return the exit status