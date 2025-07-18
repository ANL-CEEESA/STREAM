# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: STRE3AM: Strategic Technology Roadmapping and Energy, 
# Environmental, and Economic Analysis Model
# By: Argonne National Laboratory
# BSD-3 OPEN SOURCE LICENSE

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.

# ******************************************************************************
# DISCLAIMER
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ******************************************************************************

# vim: expandtab colorcolumn=80 tw=80

# written by David Thierry @dthierry 2024
# stre3am_d.jl
# description: module definition for STRE3AM
# log:
#
#
#80#############################################################################
module stre3am_d
export params, write_params, read_params, sets, createBlockMod, attachPeriodBlock, attachLocationBlock, attachFullObjectiveBlock, load_discrete_state, save_discrete_state, postprocess_d, append_fuelnames!, append_units_names!, append_tech_names!, min_ep1ge!, vintage_terms!, terminalValue, gen_loan_window, gen_pay_window, co2Total, check_discrete_state_file

include("./kern/kern.jl")
include("./mod/bm.jl")
include("./post/postprocess.jl")

version = VersionNumber(1, 0, 0)
@info "stre3am_d $(version) 2024"
end
