# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: DRE4M: Decarbonization Roadmapping and Energy, Environmental, 
# Economic, and Equity Analysis Model
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

# created by David Thierry @dthierry 2022
#
#
#80#############################################################################
using Test
using dre4m 

@testset "model testing" begin
    pr = dre4m.prJrnl()
    jrnl = dre4m.j_start
    pr.caller = @__FILE__
    dre4m.jrnlst!(pr, jrnl)
    file = "../data/prototype/prototype_0.xlsx"
    # set form
    # time horizon
    T = 2050-2020 + 1
    # technologies
    I = 11
    

    ta = dre4m.timeAttr(file)
    ## (b) cost attributes
    ca = dre4m.costAttr(file)
    ## (c) inv(time invariant) attributes
    ia = dre4m.invrAttr(file)
    ## (d) miscellaneous
    misc = dre4m.miscParam(file)


    rtf_kinds = "B22"
    ### (b) cell (reference sheet) position for the `data for retrofits`
    rtf_data = "B28" 
    rtf = dre4m.absForm(file, rtf_kinds, rtf_data)
    ## new absract form requirements
    ### (a) cell (reference sheet) position for the `kinds of retrofits`
    nwf_kinds = "B23" # (a) cell position for the `kinds new plants`
    ### (b) cell (reference sheet) position for the `data new plants`
    nwf_data = "B29"
    nwf = dre4m.absForm(file, nwf_kinds, nwf_data)

    mS = dre4m.modSets(T, I, ia, rtf, nwf)
    # setup data
    mD = dre4m.modData(ta, ca, ia, rtf, nwf, misc)
    
    @test true
    mod = dre4m.genModel(mS, mD, pr)
    @test true
end

