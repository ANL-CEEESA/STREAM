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

# written by @dthierry 2025
# prototype.jl
# notes: This is the case study for the software X paper. Be sure to check the
# instructions at the README.md
#
#
#80#############################################################################


using stre3am
using JuMP
using HiGHS


# pr = prJrnl(@__FILE__)
# setJrnlTag!(pr, "_DEBUG")
# jrnlst!(pr, jrnlMode(0))

# input file (make sure it was generated before.)
f = "./f0.xlsx"

# internal data structure
p = read_params(f);
@info "Data has been loaded.\n"

# sets
s = sets(p)
@info "Sets have been created.\n"


# model
@info "Creating model.\n"
m = createBlockMod(s.P, s.L, p, s)

# linking constraints
attachPeriodBlock(m, p, s)
attachLocationBlock(m, p, s)

# objective function
attachFullObjectiveBlock(m, p, s)

set_optimizer(m, HiGHS.Optimizer)

# (optional) load a discrete state (upper bound)
load_discrete_state(m, p, s)
set_attribute(m, "time_limit", 5.0)

# call solver
@info "Solve.\n"
optimize!(m)
# generate result files
fname = postprocess_d(m, p, s, f)



