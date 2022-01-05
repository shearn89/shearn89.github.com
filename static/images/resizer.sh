#!/bin/bash

if [[ -z $1 ]]
then
  echo 'must provide input and output'
  exit 1
else
  INPUT=$1
fi
if [[ -z $2 ]]
then
  echo 'must provide input and output'
  exit 1
else
  OUTPUT=$2
fi

MAGIC=green
# convert -density 1536 -resize 200x100 apache-nifi.svg -compose Copy -gravity center -background red -extent 800x400 -compose Copy -transparent red apache-nifi.png
convert $INPUT -compose Copy -gravity center -background $MAGIC -extent 800x400 -compose Copy -transparent $MAGIC $OUTPUT
