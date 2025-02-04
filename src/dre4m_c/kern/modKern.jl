# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: STRE3AM: Strategic Technology Roadmapping and Energy, 
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


# vim: tabstop=2 shiftwidth=2 expandtab colorcolumn=80 tw=80

# written by David Thierry @dthierry 2022
# modKern.jl
# notes: defines coefficients and data. 
# log:
# 1-17-23 added some comments

"""
    modSets(inputFile::String)
Initializes the time sets of the model.
inputs are the time and technology cardinality, time invariant attributes 
(invrAttr), retrofit form (absForm) and new plant form (absForm).
"""
struct modSets
    T::Int64 #: time-cardinality
    I::Int64 #: tech-cardinality
    Kz::Dict{Int64, Int64} #: Tech for subprocess i (retrofit)
    Kx::Dict{Int64, Int64} #: Tech for subprocess i (new)
    N::Dict{Int64, Int64} #: Age-cardinality for tech-i
    Nz::Dict{Tuple{Int64, Int64}, Int64} #: Retrofit age
    Nx::Dict{Tuple{Int64, Int64}, Int64} #: New plant age
    # Constructor
    function modSets(
            T::Int64, 
            I::Int64, 
            ia::invrAttr, 
            rtf::absForm, 
            nwf::absForm
        )

    servLife = ia.servLife
    kinds_z = ia.kinds_z
    kinds_x = ia.kinds_x

    zServLinc = rtf.servLinc
    xServLinc = nwf.servLinc

    Kz = Dict(i => kinds_z[i+1] for i in 0:I-1)
    Kx = Dict(i => kinds_x[i+1] for i in 0:I-1)

    N = Dict(i => ia.ninput[i+1] for i in 0:I-1)
    #: N = Dict(i => servLife[i+1] for i in 0:I-1)
    Nz = Dict((i,k) => N[i] 
              + floor(Int, servLife[i+1]*zServLinc[i, k]) 
            for i in 0:I-1 for k in 0:Kz[i]-1)
    #: this is assuming the service life does not increase for new capacity
    Nx = Dict((i,k) => servLife[i+1] for i in 0:I-1 for k in 0:Kx[i]-1)

    new(T, I, Kz, Kx, N, Nz, Nx)
  end
end

"""
    modData()
This is where all the useful data for the model gets aggregated.
"""
struct modData
  ta::timeAttr
  ca::costAttr
  ia::invrAttr
  rtf::absForm
  nwf::absForm
  misc::miscParam
end

