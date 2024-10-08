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

file = "../data/prototype/prototype_0.xlsx"

@testset "build_timeAttr" begin
  c = dre4m.timeAttr(file)
  @test size(c.initCap) == (11, 126)
  @test size(c.nachF) == (1, 96)
  @test size(c.cFac) == (11, 78)
end


@testset "build_costAttr" begin
  c = dre4m.costAttr(file)
  @test size(c.capC) == (11, 31)
  @test size(c.varC) == (11, 31)
  @test size(c.fixC) == (11, 31)
end

@testset "build_invrAttr" begin
  c = dre4m.invrAttr(file)
  @test size(c.servLife) == (11,)
  @test size(c.carbInt) == (11,1)
  @test size(c.discountR) == ()
  @test size(c.heatIncR) == ()
end

