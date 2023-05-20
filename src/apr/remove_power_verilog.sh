#!/usr/bin/env bash

if [ "$1" != "" ]; then
    # , .VDD ( VDD )
    sed -i -E "s/, \.VDD \( VDD \)\s+//g" $1
    # , .VSS ( VSS )
    sed -i -E "s/, \.VSS \( VSS \)\s+//g" $1
    # remove lines with WELLTAP
    sed -i "/^WELLTAP/d" $1
    # remove lines with FILLCELL
    sed -i "/^FILLCELL/d" $1
fi
