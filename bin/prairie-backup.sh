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

# Execute the script with a command like:
#   ./prairie-backup.sh ~/MyData ~/MyTIFFs ~/MyZIPs

# Author: Curtis Rueden

scriptDir="$(dirname "$0")"

baseDir="$1"
tiffDest="$2"
zipDest="$3"
if [ "$baseDir" == "" -o "$tiffDest" == "" -o "$zipDest" == "" ];
then
  echo "Usage: prairie-backup.sh baseDirectory tiffDestination zipDestination"
  exit 1
fi

if [ ! -e "$baseDir" ];
then
  echo "Base directory '$baseDir' does not exist!"
  exit 2
fi

bioFormats="$scriptDir/loci_tools.jar"
if [ ! -e "$bioFormats" ];
then
  echo "Please download Bio-Formats (loci_tools.jar) from:"
  echo "    http://loci.wisc.edu/bio-formats/downloads"
  echo
  echo "And place it in the same directory as this script."
  exit 3
fi

# exit if anything goes wrong!
set -e

# create destination folders, if they do not exist already
if [ ! -e "$tiffDest" ];
then
  mkdir -p "$tiffDest"
fi
if [ ! -e "$zipDest" ];
then
  mkdir -p "$zipDest"
fi

# ensure all paths are absolute
baseDir=$(cd "$baseDir" && pwd)
tiffDest=$(cd "$tiffDest" && pwd)
zipDest=$(cd "$zipDest" && pwd)

# search for XML files (which are assumed to indicate Prairie datasets)
IFS='\
'
for xmlFile in `find "$baseDir" -name '*.xml'`
do
  # datasetDir is the folder containing the XML file
  datasetDir="$(dirname "$xmlFile")"

  # datasetBase is the datasetDir's parent folder
  datasetBase="$(dirname "$datasetDir")"

  # datasetSuffix is the dataset's path fragment after the base directory
  datasetSuffix="${datasetBase#$baseDir}"

  # datasetName is the name of the Prairie dataset (from its folder)
  datasetName="$(basename "$datasetDir")"
  datasetFullName="$datasetSuffix$datasetName"

  # omeTiffPath is the path to the converted OME-TIFF file
  omeTiffDir="$tiffDest$datasetSuffix"
  omeTiffPath="$omeTiffDir/$datasetName.ome.tif"

  # zipPath is the path to the compressed ZIP archive
  zipDir="$zipDest$datasetSuffix"
  zipPath="$zipDir/$datasetName.zip"

  # convert Prairie dataset to compressed OME-TIFF
  echo
  echo "Converting '$datasetFullName' to OME-TIFF..."
  if [ -e "$omeTiffPath" ];
  then
    # OME-TIFF file already exists; skip this dataset
    echo "OME-TIFF file already exists. Moving on..."
    continue
  fi
  set +e
  mkdir -p "$omeTiffDir"
  java -Xmx2g -cp "$scriptDir/loci_tools.jar" \
    loci.formats.tools.ImageConverter \
    -compression LZW "$xmlFile" "$omeTiffPath" > /dev/null
  if [ $? -gt 0 ]; then
    # something went wrong; skip this dataset
    echo "Error converting. Moving on..."
    continue
  fi
  set -e

  # compress Prairie dataset to ZIP file
  echo
  echo "Compressing '$datasetFullName' to ZIP..."
  if [ -e "$zipPath" ];
  then
    # ZIP file already exists; skip this dataset
    echo "ZIP file already exists. Moving on..."
    continue
  fi
  # make the directory
  mkdir -p "${zipDir:-1}"
  (cd "$datasetBase" && zip -r9 "$zipPath" "$datasetName" > /dev/null)

  # delete uncompressed Prairie dataset
  echo
  echo "Deleting '$datasetFullName'..."
  rm -rf "$datasetDir"
done
