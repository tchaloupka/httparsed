#!/bin/bash

SRC_FILES="-Isource/ source/*.d"

set -v -e -o pipefail

if [ -z $DC ]; then DMD="dmd"; fi

if [ $DC = "ldc2" ]; then DMD="ldmd2"; fi

rm -f *test*

if [ "$COVERAGE" = true ]; then
    $DMD -version=CI_MAIN -cov -debug -g -unittest -w -vcolumns -of=httparsed-unittest-cov $SRC_FILES
    ./httparsed-unittest-cov
    wget https://codecov.io/bash -O codecov.sh
    bash codecov.sh
else
    # unittests no SSE
    $DMD -version=CI_MAIN -debug -g -unittest -w -vcolumns -of=httparsed-unittest $SRC_FILES
    ./httparsed-unittest

    # unittests with possible SSE
    $DMD -version=CI_MAIN -debug -g -unittest -w -vcolumns -mcpu=native -of=httparsed-sse-unittest $SRC_FILES
    ./httparsed-sse-unittest

    # betterC unitests no SSE
    $DMD -version=CI_MAIN -debug -g -unittest -w -vcolumns -betterC -of=httparsed-bc-unittest $SRC_FILES
    ./httparsed-bc-unittest

    # betterC unitests with possible SSE
    $DMD -version=CI_MAIN -debug -g -unittest -w -vcolumns -mcpu=native -betterC -of=httparsed-bc-sse-unittest $SRC_FILES
    ./httparsed-bc-sse-unittest

    # release build test
    $DMD -version=CI_MAIN -release -O -w -mcpu=native -inline -of=httparsed-release-test $SRC_FILES
    ./httparsed-release-test
fi
