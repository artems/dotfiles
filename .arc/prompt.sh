#!/bin/bash

__arc_ps1 () {
    local branch=`arc info 2> /dev/null | sed -e '/^branch: /! d' | sed -e 's/branch: //'`

    if [[ -n $branch ]]
    then
        echo " ( ${branch}) "
    fi
 }
