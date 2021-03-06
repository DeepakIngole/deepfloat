#!/bin/bash -x
# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

if [ $# -eq 0 ]
then
    echo "Must specify design"
    exit 1
fi

export DESIGN_NAME=$1
export EXT=$2
export FREQ=$3
export rundir="${DESIGN_NAME}_${EXT}"

PERIOD=`echo "scale=5;1000/$FREQ"|bc -l`
PERIOD_PS=`echo "scale=5;1000*$PERIOD"|bc -l`

pushd ../
vcs -timescale=1ps/1ps -fsdb -sverilog -y $SYN_HOME/dw/sim_ver +libext+.v+ +incdir+$SYN_HOME/dw/sim_ver +define+SYNOPSYS_DW=1 +define+CLOCK_PERIOD=$PERIOD_PS -f all_rtl.dep paper_syn/Waves_${DESIGN_NAME}.sv

if [[ $? -ne 0 ]]; then
    exit 1
fi

rm -f design.fsdb
./simv

fsdb2saif design.fsdb -o ${DESIGN_NAME}.saif

gzip -f ${DESIGN_NAME}.saif
mv ${DESIGN_NAME}.saif.gz ../../constraints/

popd

pushd ../../..


/bin/cat <<EOM > constraints/${DESIGN_NAME}.func.sdc
set period $PERIOD;
set clk_pins [all_fanin -to [filter_collection [get_pins -of_objects [all_registers]] "full_name =~ *clocked_on || full_name =~ *CP"] -flat -startpoints_only]
echo "[get_object_name \$clk_pins] is used as clock";
foreach_in_collection each_clk_pins \$clk_pins {
create_clock -period \$period -name clk [get_ports [get_object_name \$each_clk_pins]]
set_clock_uncertainty -setup 0.3 [get_ports [get_object_name \$each_clk_pins]]
set_clock_uncertainty -hold 0.05 [get_ports [get_object_name \$each_clk_pins]]
set_input_delay  -clock  clk 0.3 [all_inputs]
set_output_delay -clock  clk 0.3 [all_outputs]
}
EOM

rm -rf ${DESIGN_NAME}_${EXT}
mkdir -p ${DESIGN_NAME}_${EXT}
cd ${DESIGN_NAME}_${EXT}

mkdir -p logs reports results cache

export LOGS_DIR=logs
export REPORTS_DIR=reports
export RESULTS_DIR=results
export CACHE_DIR=cache
export SCRIPTS_DIR=../scripts
dc_shell -topo -f ${SCRIPTS_DIR}/dc_elab.tcl    | tee ${LOGS_DIR}/dc_elab.log
dc_shell -topo -f ${SCRIPTS_DIR}/dc_compile.tcl | tee ${LOGS_DIR}/dc_first_compile.log
/nfs/data/tools/synopsys/pts/N-2017.12-SP1/bin/pt_shell -f ${SCRIPTS_DIR}/pt.tcl | tee ${LOGS_DIR}/pt.log

popd
