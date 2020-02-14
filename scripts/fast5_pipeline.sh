#!/bin/bash
# @author: Hasindu Gamaarachchi (hasindu@unsw.edu.au)
# @coauthor: Sasha Jenner (jenner.sasha@gmail.com)
#
# MIT License
#      
# Copyright (c) 2019 Hasindu Gamaarachchi, 2020 Sasha Jenner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################

USAGE="Usage: $0 -f [format] [options ...] [fast5_filepath]"
: ${2?$USAGE} # require at least 2 args else give usage message

HELP=$"Flags:
-f [format], --format=[format]          Follows a specified format of fast5 and fastq files
        --778           [directory]
                        |-- fast5/
                            |-- <prefix>.fast5.tar
                        |-- fastq/
                            |-- fastq_*.<prefix>.fastq.gz
        
        --NA            [directory]
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

        -f)
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

        --format=*)
			format_specified=true
            format="${1#*=}"

			case "$format" in

				--778 | --NA | --zebra)
					FORMAT=$format
					;;

				*)
					echo "Incorrect or no format specified"
					echo $USAGE
					echo "$HELP"
					exit 1
					;;
            esac
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

if [ "$FORMAT" = "--zebra" ]; then # Zebrafish reference genome
    REF_FA=/mnt/zebrafish/zebrafish_genome.fa # reference fasta for methylation call
    REF_IDX=/mnt/zebrafish/zebrafish_genome.idx # reference index for minimap2

else # Human reference genome
    REF_FA=/nanopore/reference/hg38noAlt.fa # reference fasta for methylation call
    REF_IDX=/nanopore/reference/hg38noAlt.idx # reference index for minimap2
fi

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
/usr/bin/time -v $METHCALL index -d $F5_DIR_LOCAL $FQ_LOCAL 2> $LOG_LOCAL
if [$? -ne 0]; then
    exit_status=1
    echo "index failed" >> $LOG_LOCAL
fi

# minimap
/usr/bin/time -v $MINIMAP -x map-ont -a -t4 -K5M --secondary=no --multi-prefix=$MINIMAP_LOCAL $REF_IDX $FQ_LOCAL > $SAM_LOCAL 2>> $LOG_LOCAL
if [$? -ne 0]; then
    exit_status=1
    echo "minimap failed" >> $LOG_LOCAL
fi

# sorting
/usr/bin/time -v $SAMTOOLS sort -@3 $SAM_LOCAL > $BAM_LOCAL 2>> $LOG_LOCAL
if [$? -ne 0]; then
    exit_status=1
    echo "samtools sorting failed" >> $LOG_LOCAL
fi
/usr/bin/time -v $SAMTOOLS index $BAM_LOCAL 2>> $LOG_LOCAL
if [$? -ne 0]; then
    exit_status=1
    echo "samtools index failed" >> $LOG_LOCAL
fi

# methylation
/usr/bin/time -v $METHCALL call-methylation -t 4 -r $FQ_LOCAL -g $REF_FA -b $BAM_LOCAL -K 256 > $METH_LOCAL  2>> $LOG_LOCAL
if [$? -ne 0]; then
    exit_status=1
    echo "methylation failed" >> $LOG_LOCAL
fi

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

echo $exit_status >> $LOG_LOCAL

exit $exit_status # return the exit status