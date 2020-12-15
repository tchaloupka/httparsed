#!/bin/bash

SRC_FILES="-Isource/ source/httparsed/*.d"

set -v -e -o pipefail

if [ -z $DC ]; then DC="dmd"; fi

if [ $DC = "ldc2" ]; then DC="ldmd2"; fi

rm -f *-unittest*

if [ "$COVERAGE" = true ]; then
    $DC -version=UTMAIN -cov -debug -g -unittest -w -vcolumns -of=httparsed-unittest-cov $SRC_FILES
    ./httparsed-unittest-cov
    wget https://codecov.io/bash -O codecov.sh
    bash codecov.sh
else
    # unittests no SSE
    $DC -version=UTMAIN -debug -g -unittest -w -vcolumns -of=httparsed-unittest $SRC_FILES
    ./httparsed-unittest

    # unittests with possible SSE
    $DC -version=UTMAIN -debug -g -unittest -w -vcolumns -mcpu=native -of=httparsed-sse-unittest $SRC_FILES
    ./httparsed-sse-unittest

    # betterC unitests no SSE
    $DC -version=UTMAIN -debug -g -unittest -w -vcolumns -betterC -of=httparsed-bc-unittest $SRC_FILES
    ./httparsed-bc-unittest

    # betterC unitests with possible SSE
    $DC -version=UTMAIN -debug -g -unittest -w -vcolumns -mcpu=native -betterC -of=httparsed-bc-sse-unittest $SRC_FILES
    ./httparsed-bc-sse-unittest
fi
