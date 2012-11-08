#!/bin/bash

# prairie-backup.sh
# A script for backing up a directory of Prairie datasets.
# 1) It converts each dataset to compressed OME-TIFF.
# 2) It creates a ZIP archive of the original dataset.
# 3) if the first two steps were successful, it deletes the original folder.

# This script is useful for creating convenient single-file OME-TIFFs,
# as well as archiving the original Prairie data in case something goes wrong.
# It will save space, especially if the ZIP files are then migrated to an
# external backup server.

# Author: Curtis Rueden

baseDir="$(dirname "$0")"

if [ "$*" == "" ];
then
  echo "Usage: prairie-backup.sh baseDirectory [anotherBaseDirectory ...]"
  exit 1
fi

bioFormats="$baseDir/loci_tools.jar"
if [ ! -e "$bioFormats" ];
then
  echo "Please download Bio-Formats (loci_tools.jar) from:"
  echo "    http://loci.wisc.edu/bio-formats/downloads"
  echo
  echo "And place it in the same directory as this script."
  exit 2
fi

# exit if anything goes wrong!
set -e

# search for XML files (which are assumed to indicate Prairie datasets)
IFS='\
'
for xmlFile in `find "$@" -name '*.xml'`
do
  # datasetDir is the folder containing the XML file
  datasetDir="$(dirname "$xmlFile")"

  # datasetBase is the datasetDir's parent folder
  datasetBase="$(dirname "$datasetDir")"

  # datasetName is the name of the Prairie dataset (i.e., its folder name)
  datasetName="$(basename "$datasetDir")"

  # convert Prairie dataset to OME-TIFF
  echo
  echo "Converting '$xmlFile' to OME-TIFF..."
  omeTiff="$datasetName.ome.tif"
  if [ -e "$omeTiff" ];
  then
    # OME-TIFF file already exists; skip this dataset
    echo "OME-TIFF file already exists. Moving on..."
    continue
  fi
  set +e
  java -cp "$baseDir/loci_tools.jar" loci.formats.tools.ImageConverter \
    -compression LZW "$xmlFile" "$omeTiff" > /dev/null
  if [ $? -gt 0 ]; then
    # something went wrong; skip this dataset
    echo "Error converting. Moving on..."
    continue
  fi
  set -e

  # compress Prairie dataset to ZIP file
  echo
  echo "Compressing '$datasetDir' to ZIP..."
  zipFile="$datasetName.zip"
  if [ -e "$zipFile" ];
  then
    # ZIP file already exists; skip this dataset
    echo "ZIP file already exists. Moving on..."
    continue
  fi
  (cd "$datasetBase" && zip -r9 "$datasetName.zip" "$datasetDir" > /dev/null)

  # delete uncompressed Prairie dataset
  echo
  echo "Deleting '$datasetName'..."
  rm -rf "$datasetDir"
done
