# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: DRE4M: Decarbonization Roadmapping and Energy, Environmental, 
# Economic, and Equity Analysis Model
# By: Argonne National Laboratory
# BSD OPEN SOURCE LICENSE

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

# vim: tabstop=2 shiftwidth=2 expandtab colorcolumn=80 tw=80

import Dates

mutable struct prJrnl
  initT::Dates.DateTime
  finalT::Dates.DateTime
  fname::String
  caller::String
  count::Int32
  tag::String
  function prJrnl()
    it = Dates.now()
    ft = Dates.now()
    f = "UNASSIGNED"
    new(it, ft, f, f, 0, "_")
  end
end

@enum jrnlMode j_start j_log_f j_query

function jrnlst!(pr::prJrnl, jMode::jrnlMode)
  fname = pr.fname
  tag = pr.tag
  if jMode == j_start
    @info "Log start."
    initialTime = Dates.now()  # to log the results, I guess
    pr.initT = initialTime
    fname = Dates.format(initialTime, "eyymmdd_HH_MM_SS")
    @info("Started\t$(initialTime)\n")
    @info("Out files:\t$(fname)\n")
    mkdir(fname*tag)
    fname = "./"*fname*tag*"/"*fname*tag
    pr.fname = fname
    refFile = pr.caller
    run(pipeline(`echo $(refFile)`,
        stdout=fname*"_$(pr.count).out"))
    run(pipeline(`cat $(refFile)`, 
        stdout=fname*"_$(pr.count).out", append=true))
    @info "Caller $(refFile)"
  elseif jMode == j_log_f
    pr.finalT = Dates.now()
    @info "Logged @ $(pr.finalT - pr.initT)"
    refFile = pr.caller
    run(pipeline(`echo $(refFile)`,
        stdout=fname*"_$(pr.count).out"))
    run(pipeline(`cat $(refFile)`, 
        stdout=fname*"_$(pr.count).out", append=true))
    @info "Caller $(refFile)"
  end
  if jMode == j_query
    pr.finalT = Dates.now()
    @info "Logged @ $(pr.finalT - pr.initT)"
  else 
    pr.count += 1
  end
end

