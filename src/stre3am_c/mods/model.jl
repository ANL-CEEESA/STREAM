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

# vim: tabstop=2 shiftwidth=2 expandtab colorcolumn=80 tw=80

# written by David Thierry @dthierry 2022
# model.jl
# log:
# x-xx-xx implement changes of how age is considered
# 1-17-23 added some comments
#
#
#80#############################################################################

using JuMP

#80#############################################################################
"""
    genModel(mS::modSets, modData::modData)::JuMP.Model
Generates model with variables and constraints.
"""
function genModel(mS::modSets, 
        mD::modData, 
        pr::prJrnl; 
        no_rf::Bool=false,
        no_delay_z::Bool=false,
        no_delay_x::Bool=false)::JuMP.Model
    @info "Generating model..."
    #76#########################################################################
    #: model sets mS, and model data mD 
    T = mS.T
    I = mS.I
    N = mS.N
    Nx = mS.Nx
    Nz = mS.Nz
    Kz = mS.Kz
    
    #: if no retrofits are enabled, zero the retrofit sets
    if no_rf == true
        for k in keys(Kz)
            Kz[k] = 0
        end
        mD.ia.kinds_z = zeros(Int, length(mD.ia.kinds_z))
    end

    Kx = mS.Kx

    servLife = mD.ia.servLife
    zDelay = mD.rtf.delay

    #: if no lead time (rf), zero the delay sets
    if no_delay_z
        for k in keys(zDelay)
            zDelay[k] = 0
        end
    end
    
    #: if no lead time (rf), zero the delay sets
    xDelay = mD.nwf.delay
    if no_delay_x
        for k in keys(xDelay)
            xDelay[k] = 0
        end
    end

    fuelBased = mD.ia.fuelBased
    co2Based = mD.ia.co2Based
    bLoadTech = mD.ia.bLoadTech

    initCap = mD.ta.initCap
    d = mD.ta.nachF # demand
    maxDelay = maximum(values(xDelay))
    
    genScale = mD.misc.genScale

    cFact = mD.ta.cFac
    cFact0 = [mD.ta.cFac[i+1, 1] for i in 0:I-1]
    
    #: Set journal
    jrnl = j_log_f
    pr.caller = @__FILE__
    jrnlst!(pr, jrnl)

    yrHr = 24* 365.  # hours in a year
    
    #: Model creation
    #
    # The model
    m = Model()
    #: Variables
     
    #76#########################################################################
    ############ Variables definition $$$$$$$$$$$$

    # Assets
    ## existing asset
    @variable(m,
              w[t=0:T, i=0:I-1,
                j=0:N[i]-1]
              >= 0e0
             )

    ##  retired existing asset
    @variable(m, uw[t = 0:T, i = 0:I-1,
                    j = 0:N[i]-1]
              >= 0e0
             )

    ##  new asset
    @variable(m, x[t = 0:T,
                   i = 0:I-1, k = 0:Kx[i]-1,
                   j = 0:T; t>=(j+xDelay[i, k])]
              >= 0e0
             )
    

    ## new assets allocations
    @variable(m,
              xAlloc[t=0:T, i=0:I-1, k=0:Kx[i]-1]
              >= 0e0)

    ##  retired new asset
    @variable(m, ux[t = 0:T,
                    i = 0:I-1, k = 0:Kx[i]-1,
                    j = 0:T;
                    t >= (j+xDelay[i, k])]
              >= 0)

    ##  rf asset
    @variable(m,
              z[t=0:T, i=0:I-1, k=0:Kz[i]-1,
                j=0:N[i]-1;
                t >= zDelay[i, k]]
              >= 0)

    ##  rf asset transition
    @variable(m,
              zTrans[t = 0:T, i = 0:I-1, k = 0:Kz[i]-1,
                     j = 0:N[i]-1]
              >= 0)
    #: as opposed to "z", the zTrans variable can be defined from T=0

    ## retired retrofit
    @variable(m,
              uz[t = 0:T, i = 0:I-1, k = 0:Kz[i]-1,
                 j = 0:N[i]-1; t >= zDelay[i,k]]
              >= 0)
    
    # Effective capacity
    ## Effective capacity old
    @variable(m, W[t=0:T-1, i=0:I-1,
                   j=0:N[i]-1])
    ## Effective capacity rf
    @variable(m,
              Z[t=0:T-1, i=0:I-1, k=0:Kz[i]-1,
                j=0:N[i]-1])
    ## Effective capacity new
    @variable(m,
              X[t=0:T-1,
                i=0:I-1, k=0:Kx[i]-1,
                j=0:T-1]
             )

    # Generation variables
    ## generation existing
    @variable(m,
              Wgen[t=0:T-1, i=0:I-1,
                   j=0:N[i]-1]
             )

    ## generation rf
    @variable(m,
              Zgen[t=0:T-1, i=0:I-1, k=0:Kz[i]-1,
                   j=0:N[i]-1]
             )

    ## generation new
    @variable(m,
              Xgen[t=0:T-1, i=0:I-1, k=0:Kx[i]-1,
                   j=0:T-1])

    ## overall generation
    @variable(m, sGen[t = 1:T-1, i = 0:I-1]) #: supply generated
    

    # Heat variables
    ## heat req. existing
    @variable(m, 
              heat_w[t = 0:T-1, i=0:I-1,
                        j = 0:N[i]-1; fuelBased[i+1]])

    ## heat req. retrofit 
    @variable(m,
              heat_z[t=0:T-1,
                     i=0:I-1, k=0:Kz[i]-1,
                     j=0:N[i]-1; fuelBased[i+1]])

    ## heat req. new 
    @variable(m,
              heat_x[t=0:T-1,
                     i=0:I-1, k=0:Kx[i]-1,
                     j=0:T-1; fuelBased[i+1]])

    # Carbon emission (tCO2)
    ## emissions new
    @variable(m,
              wE[t = 0:T-1, i = 0:I-1,
                 j = 0:N[i]-1; co2Based[i+1]]
              >= 0e0
             )
    #: ♪ Ah&eM
    ## emission rf
    @variable(m,
              zE[t=0:T-1, i=0:I-1, k=0:Kz[i]-1,
                 j=0:N[i]-1; co2Based[i+1]]
              >= 0e0
             )
    ## emission new
    @variable(m,
              xE[t=0:T-1, i=0:I-1, k=0:Kx[i]-1,
                 j=0:T-1; co2Based[i+1]]
              >= 0e0
             )

    # Capital cost
    ## (overnight) Capital for new capacity
    @variable(m, xOcap[t=0:T-1, i=0:I-1, k=0:Kx[i]-1])

    ## (overnight) Capital for retrofits
    @variable(m, zOcap[t=0:T-1, i=0:I-1, k=0:Kz[i]-1])
    
    # Operation and Maintenance 
    # O and M for existing
    ## fixed cost existing
    @variable(m, wFixOnM[t=0:T-1, i=0:I-1])
    ## var cost existing
    @variable(m, wVarOnM[t=0:T-1, i=0:I-1])

    # O and M for retrofit
    ## fixed cost rf 
    @variable(m, zFixOnM[t=0:T-1, i=0:I-1, k=0:Kz[i]-1])
    # var cost rf 
    @variable(m, zVarOnM[t=0:T-1, i=0:I-1, k=0:Kz[i]-1])

    # O and M for new
    ## fixed cost new 
    @variable(m, xFixOnM[t=0:T-1, i=0:I-1, k=0:Kx[i]-1])
    ## var cost new 
    @variable(m, xVarOnM[t=0:T-1, i=0:I-1, k=0:Kx[i]-1])
    
    # Fuel and CO
    ## fuel existing
    @variable(m, wFuelC[t=0:T-1, i=0:I-1; fuelBased[i+1]])

    ## fuel rf 
    @variable(m, zFuelC[t=0:T-1, i=0:I-1, k=0:Kz[i]-1; fuelBased[i+1]])

    ## fuel new 
    @variable(m, xFuelC[t=0:T-1, i=0:I-1, k=0:Kx[i]-1; fuelBased[i+1]])
    
    ## overall cow
    @variable(m, co2OverallYr[t=0:T-1])

    # Endogenous retirement cost
    ##  existing retired cost
    @variable(m, wRet[i=0:I-1,
                      j=0:N[i]-1])
    ##  rf retired cost
    @variable(m, zRet[i=0:I-1, k=0:Kz[i]-1,
                      j=0:N[i]-1])
    ##  new retired cost
    @variable(m, xRet[i=0:I-1, k=0:Kx[i]-1,
                      j=0:T])

    # Net present value
    @variable(m, npv) # ≥ 1000. * 2000.)

    # Terminal cost
    ## terminal cost existing
    @variable(m, termCw[i=0:I-1,
                        j=0:N[i]-1])

    ## terminal cost new
    @variable(m, termCx[i=0:I-1, k=0:Kx[i],
                        j=0:T-1])

    ## terminal cost rf
    @variable(m, termCz[i=0:I-1, k=0:Kz[i]-1,
                        j=0:N[i]-1])
    ## overall cost
    @variable(m, termCost >= 0) #: overall

    # Soft service life penalties
    ## Soft service life penalty for existing
    @variable(m, wLatRet[t=0:T-1, i=0:I-1,
                         j=0:N[i]-1;
                         (t+j) >= servLife[i+1] && !bLoadTech[i+1]])

    ## Soft service life penalty for rf
    @variable(m, zLatRet[t=0:T-1, i=0:I-1, k=0:Kz[i]-1,
                         j=0:N[i]-1;
                         (t+j) >= servLife[i+1] && 
                         t >= zDelay[i,k] && !bLoadTech[i+1]]
             )

    ## Soft service life penalty for new
    @variable(m, xLatRet[t=0:T-1, i=0:I-1, k=0:Kx[i]-1,
                         j=0:T-1;
                         (t-j)>=Nx[i, k] && !bLoadTech[i+1]]
             )
    #76#########################################################################
    ############ Constraint definition $$$$$$$$$$$$

    ## existing balance
    @constraint(m,
                wbal[t = 0:T-1, i = 0:I-1,
                     j = 0:N[i]-1],
                w[t+1, i, j] == w[t, i, j]
                - uw[t, i, j]
                - sum(zTrans[t, i, k, j] for k in 0:Kz[i]-1)
               )
    #: the tally of assets of initial-age j

    ## zero out all the initial condition of the retrofits
    @constraint(m,
                ic_zE[i=0:I-1,
                      k=0:Kz[i]-1, j=0:N[i]-1],
                z[zDelay[i, k], i, k, j] == 0
               )
    #: we don't want initial rf assets

    ## rf balance
    @constraint(m,
                zBal[t=0:T-1, i=0:I-1, k=0:Kz[i]-1,
                     j=0:N[i]-1; t >= zDelay[i,k]],
                z[t+1, i, k, j] ==
                z[t, i, k, j]
                - uz[t, i, k, j]
                + zTrans[t-zDelay[i, k], i, k, j]
               )
    ## new allocations
    @constraint(m,
                xallocE[t=0:T-1,
                        i=0:I-1, k=0:Kx[i]-1,
                        j=0:T-1; t==(j+xDelay[i, k])],
                x[t, i, k, j] == xAlloc[t-xDelay[i, k], i, k]
               )
    #: notice there is lead time: xDelay 

    ## new asset balance
    @constraint(m,
                xbal[t = 0:T-1,
                     i = 0:I-1, k = 0:Kx[i]-1,
                     j = 0:T-1; t>=(j+xDelay[i, k])],
                x[t+1, i, k, j] == x[t, i, k, j] - ux[t, i, k, j]
               )

    ## set initial capacity of existing assets
    @constraint(m,
                initial_w_E[i = 0:I-1, j = 0:N[i]-1],
                w[0, i, j] == initCap[i+1, j+1]
               )
    #: should initial plants at retirement age be allowed
    
    # Effective capacity
    ## effective existing capacity 
    @constraint(m, W_E[t=0:T-1, i=0:I-1, j=0:N[i]-1],
                W[t, i, j] ==
                w[t, i, j]
                - uw[t, i, j]
                - sum(zTrans[t, i, k, j] for k in 0:Kz[i]-1)
               )

    ## effective capacity rf, before the rf lead time
    @constraint(m,
                Z_E0[t=0:T-1,
                     i=0:I-1, k=0:Kz[i]-1,
                     j=0:N[i]-1; t < zDelay[i,k]],
                Z[t, i, k, j] == 0e0
               )
    #: All effective rf capacity from time=0 to delay is set to 0
    
    ## effective capacity rf, after the rf lead time 
    @constraint(m,
                Z_E[t=0:T-1,
                    i=0:I-1, k=0:Kz[i]-1,
                    j=0:N[i]-1; t >= zDelay[i,k]],
                Z[t, i, k, j] ==
                z[t, i, k, j] - uz[t, i, k, j]
                + zTrans[t-zDelay[i, k], i, k, j]
               )

    ## effective capacity new, before the lead time 
    @constraint(m,
                X_E0[t=0:T-1,
                    i=0:I-1, k=0:Kx[i]-1,
                    j=0:T-1; t<(j+xDelay[i, k])],
                X[t, i, k, j] == 0e0
               )

    ## effective capacity new, after the lead time 
    @constraint(m,
                X_E[t=0:T-1,
                    i=0:I-1, k=0:Kx[i]-1,
                    j=0:T-1; t>=(j+xDelay[i, k])],
                X[t, i, k, j] ==
                x[t, i, k, j] - ux[t, i, k, j]
               )
    

    #76#########################################################################
    # Generation (or production) 
    ## existing generation
    @constraint(m, WgEq[t=0:T-1, i=0:I-1, j=0:N[i]-1],
                Wgen[t, i, j] ==
                # GWh * (1TWh/1000GWh) = TWh
                genScale * yrHr * cFact0[i+1] * W[t, i, j]
                )
    ## rf generation
    @constraint(m, ZgEq[t=0:T-1, i=0:I-1, k=0:Kz[i]-1,
                        j=0:N[i]-1],
                Zgen[t, i, k, j] ==
                devDerating(mD, i, k, j, t, "R")*genScale*yrHr*cFact0[i+1]*
                Z[t, i, k, j]
                )
    ## new generation
    @constraint(m, XgEq[t=0:T-1, i=0:I-1, k=0:Kx[i]-1, j=0:T-1],
                Xgen[t, i, k, j] ==
                genScale * yrHr * cFact[i+1, j+1] * X[t, i, k, j]
                )
    #: genScale helps with the scaling (and units)

    ## overall generation (see genScale for units)
    @constraint(m, sGenEq[t = 1:T-1, i = 0:I-1],
              (
              sum(Wgen[t, i, j] for j in 0:N[i]-1) +
              sum(Zgen[t, i, k, j] for k in 0:Kz[i]-1 for j in 0:N[i]-1
              ) +
              sum(Xgen[t, i, k, j] for k in 0:Kx[i]-1 for j in 0:T-1)
              ) == sGen[t, i]
              )

    # Demand
    @constraint(m,
                dcCon[t = 1:T-1],
                sum(sGen[t, i] for i in 0:I-1) >= d[t+1]
               )

    # Heat requirement
    ## existing asset heat requirement
    @constraint(m,
                heat_w_E[t=0:T-1, i=0:I-1,
                         j=0:N[i]-1; fuelBased[i+1]],
                heat_w[t, i, j] ==
                Wgen[t, i, j] * wHeatRate(mD, i, j, t)
               )
    #: heat values are based upon generation

    ## rf asset heat requirement 
    @constraint(m,
                heat_z_E[t = 0:T-1, i = 0:I-1, k = 0:Kz[i]-1,
                         j = 0:N[i]-1; fuelBased[i+1]],
                heat_z[t, i, k, j] ==
                Zgen[t, i, k, j] * zHeatRate(mD, i, k, j, t)
               )


    ## new asset heat requirement 
    @constraint(m,
                heat_x_E[t=0:T-1, i=0:I-1, k=0:Kx[i]-1,
                         j=0:T-1; fuelBased[i+1]],
                heat_x[t, i, k, j] ==
                Xgen[t, i, k, j] * xHeatRate(mD, i, k, j, t)
               )
    #: age is determined by the heatRate functions


    # CO2 emissions 
    ## existing emissions
    @constraint(m,
                e_wCon[t=0:T-1, i=0:I-1,
                       j=0:N[i]-1; co2Based[i+1]],
                wE[t, i, j] == heat_w[t, i, j] * wCarbonInt(mD, i)
               )


    ## rf emissions
    @constraint(m,
                e_zCon[t = 0:T-1, i = 0:I-1, k =0:Kz[i]-1,
                       j=0:N[i]-1; co2Based[i+1]],
                zE[t, i, k, j] ==
                heat_z[t, i, k, j] * devCarbonInt(mD, i, k, "R")
               )


    ## new emissions
    @constraint(m,
                e_xCon[t=0:T-1, i=0:I-1, k=0:Kx[i]-1,
                       j=0:T-1; co2Based[i+1]],
                xE[t, i, k, j] ==
                heat_x[t, i, k, j] * devCarbonInt(mD, i, k, "X")
               )

    
    # The Kapital
    ## new asset capital cost
    @constraint(m, xOcapE[t=0:T-1, i=0:I-1, k=0:Kx[i]-1],
                xOcap[t, i, k] == 
                devCapCost(mD, i, k, t, "X")*xAlloc[t, i, k]
               )

    ## rf asset capital cost
    @constraint(m, zOcapE[t=0:T-1, i=0:I-1, k=0:Kz[i]-1],
                zOcap[t, i, k] == sum(
                                   devCapCost(mD, i, k, t, "R")*
                                   zTrans[t, i, k, j]
                                   for j in 0:N[i]-1
                                  )
               )

    # Cost of O and M (both fixed and variable)
    ## existing fixed cost
    @constraint(m,
                wFixOnM_E[t=0:T-1, i=0:I-1],
                wFixOnM[t, i] ==
                wFixCost(mD, i, t) * sum(W[t, i, j] for j in 0:N[i]-1)
               )

    ## existing variable cost
    @constraint(m,
                wVarOnM_E[t=0:T-1, i=0:I-1],
                wVarOnM[t, i] ==
                wVarCost(mD, i, t) * sum(Wgen[t, i, j] for j in 0:N[i]-1)
               )

    ## existing fixed cost
    @constraint(m,
                zFixOnM_E[t=0:T-1, i=0:I-1, k=0:Kz[i]-1],
                zFixOnM[t, i, k] ==
                sum(devFixCost(mD, i, k, t, "R") * Z[t, i, k, j]
                    for j in 0:N[i]-1 #: only related to the base age
                      ))

    ## rf variable cost
    @constraint(m,
                zVarOnM_E[t=0:T-1, i=0:I-1, k=0:Kz[i]-1],
                zVarOnM[t, i, k] ==
                sum(devVarCost(mD, i, k, t, "R") * Zgen[t, i, k, j]
                    for j in 0:N[i]-1 #: only related to the base age
                      ))

    ## new fixed cost
    @constraint(m,
                xFixOnM_E[t=0:T-1, i=0:I-1, k=0:Kx[i]-1],
                xFixOnM[t, i, k] ==
                sum(devFixCost(mD, i, k, t, "X")*X[t, i, k, j]
                    for j in 0:T-1)
               )

    ## new variable cost
    @constraint(m,
                xVarOndM_E[t=0:T-1, i=0:I-1, k=0:Kx[i]-1],
                xVarOnM[t, i, k] ==
                sum(devVarCost(mD, i, k, t, "X")*Xgen[t, i, k, j]
                    for j in 0:T-1)
               )
    # Fuel cost
    ## existing fuel cost
    @constraint(m, wFuelC_E[t=0:T-1, i=0:I-1; fuelBased[i+1]],
                wFuelC[t, i] ==
                wFuelCost(mD, i, t) * sum(heat_w[t, i, j]
                                  for j in 0:N[i]-1)
               )

    ## rf fuel cost
    @constraint(m, zFuelC_E[t=0:T-1, i=0:I-1, k=0:Kz[i]-1;
                            fuelBased[i+1]],
                zFuelC[t, i, k] ==
                sum(devFuelCost(mD, i, k, t, "R") * heat_z[t, i, k, j]
                    for j in 0:N[i]-1)
               )


    ## new fuel cost
    @constraint(m, xFuelC_E[t=0:T-1, i=0:I-1, k=0:Kx[i]-1;
                            fuelBased[i+1]],
                xFuelC[t, i, k] ==
                sum(devFuelCost(mD, i, k, t, "X") * heat_x[t, i, k, j]
                    for j in 0:T-1)
               )

    
    # CO2 overall
    @constraint(m, co2OverallYrE[t=0:T-1],
                co2OverallYr[t] ==
                sum(wE[t, i, j] for i in 0:I-1
                    for j in 0:N[i]-1 if co2Based[i+1])
                + sum(zE[t, i, k, j]
                      for i in 0:I-1
                      for k in 0:Kz[i]-1
                      for j in 0:N[i]-1 if co2Based[i+1])
                + sum(xE[t, i, k, j]
                      for i in 0:I-1
                      for k in 0:Kx[i]-1
                      for j in 0:T-1 if co2Based[i+1])
               )

    #: retirement based on "old" age
    
    # Retirement cost
    ## existing retirement cost
    @constraint(m, wRet_E[i=0:I-1, j=0:N[i]-1],
                wRet[i, j] ==
                sum(
                    (retCost(mD, i, i, t, j) 
                     # M$/TWh * (1TWh/1000GWh) = M$/GWh
                     + genScale*yrHr*cFact0[i+1]*saleLost(mD, i, t, j)
                    )
                    * uw[t, i, j] for t in 0:T-1)
               )

    ## rf retirement cost
    @constraint(m, zRet_E[i=0:I-1, k=0:Kz[i]-1, j=0:N[i]-1], 
                zRet[i, k, j] == 
                sum(
                    (retCost(mD, i, k, t, j, tag="R") 
                     + genScale*yrHr*cFact0[i+1]*saleLost(mD, i, t, j)) 
                    * uz[t, i, k, j] for t in 0:T-1 if t >= zDelay[i,k])
               )

    ## new retirement cost
    @constraint(m, xRet_E[i=0:I-1, k=0:Kx[i]-1,
                          j=0:T-1],
                xRet[i, k, j] ==
                sum(
                (retCost(mD, i, k, t, j, tag="X") 
                 + genScale*yrHr*cFact[i+1, j+1]*saleLost(mD,i,t,j,tag="X"))
                * ux[t, i, k, j] for t in 0:T-1 if t >= (j+xDelay[i, k]))
               )

    #76#########################################################################
    # NPV constraint
    @constraint(m, npv_e,
                npv ==
                # overnight
                sum(zOcap[t, i, k]
                    for t in 0:T-1
                    for i in 0:I-1
                    for k in 0:Kz[i]-1)
                + sum(xOcap[t, i, k]
                      for t in 0:T-1
                      for i in 0:I-1
                      for k in 0:Kx[i]-1)
                # op and maintenance (fixed + variable)
                #: existing
                + sum(
                      wFixOnM[t, i] + wVarOnM[t, i]
                      for t in 0:T-1 for i in 0:I-1)
                #: retrofit
                + sum(
                      zFixOnM[t, i, k] + zVarOnM[t, i, k]
                      for t in 0:T-1
                      for i in 0:I-1
                      for k in 0:Kz[i]-1)
                #: new
                + sum(
                      xFixOnM[t, i, k] + xVarOnM[t, i, k]
                      for t in 0:T-1
                      for i in 0:I-1
                      for k in 0:Kx[i]-1
                     )
                # cost of fuel
                + sum(
                      wFuelC[t, i]
                      for t in 0:T-1
                      for i in 0:I-1 if fuelBased[i+1])
                + sum(
                      zFuelC[t, i, k]
                      for t in 0:T-1
                      for i in 0:I-1
                      for k in 0:Kz[i]-1 if fuelBased[i+1])
                + sum(
                      xFuelC[t, i, k]
                      for t in 0:T-1
                      for i in 0:I-1
                      for k in 0:Kx[i]-1 if fuelBased[i+1])
                + sum(wRet[i, j]
                      for i in 0:I-1
                      for j in 0:N[i]-1)
                + sum(zRet[i, k, j]
                      for i in 0:I-1
                      for k in 0:Kz[i]-1
                      for j in 0:N[i]-1)
                + sum(xRet[i, k, j]
                      for i in 0:I-1
                      for k in 0:Kx[i]-1
                      for j in 0:T-1)
               )

    #76#########################################################################
    # Terminal cost
    ## terminal cost existing
    @constraint(m, termCwE[i=0:I-1, j=0:N[i]-1],
                termCw[i, j] ==
                (retCost(mD, i, i, T-1, j) +
                 genScale*yrHr*cFact0[i+1]*saleLost(mD, i, T-1, min(j, N[i]-1))
                ) * W[T-1, i, j]
               )

    ## terminal cost new 
    @constraint(m, termCxE[i=0:I-1, k=0:Kx[i]-1,
                           j=0:T-1],
                termCx[i, k, j] ==
                (retCost(mD, i, k, T-1, j, tag="X") +
                 genScale*yrHr*cFact[i+1, j+1]*saleLost(mD, i, T-1, j, tag="X")
                )*X[T-1, i, k, j]
               )

    ## terminal cost rf 
    @constraint(m, termCzE[i=0:I-1, k=0:Kz[i]-1,
                           j=0:N[i]-1],
                termCz[i, k, j] ==
                (retCost(mD, i, k, T-1, j) +
                 genScale*365*24*saleLost(mD, i, T-1, min(j, N[i]-1))
                )*Z[T-1, i, k, j]
               )
    ## overall terminal cost
    @constraint(m, termCE,
                termCost ==
                sum(termCw[i, j]
                    for i in 0:I-1
                    for j in 0:N[i]-1)
                + sum(termCx[i, k, j]
                      for i in 0:I-1
                      for k in 0:Kx[i]-1
                      for j in 0:T-1)
                + sum(termCz[i, k, j]
                      for i in 0:I-1
                      for k in 0:Kz[i]-1
                      for j in 0:N[i]-1)
               )

    #76#########################################################################
    function rLatentW(time, kind, age0)
        sL = servLife
        age = age0 + time
        return retCost(mD, 0, 0, 1, 0)*
        exp((age-sL[kind+1])/sL[kind+1])
        # retirementCost_age_1 * exp((age-servLife)/servLife)
    end

    # Soft service life penalties
    ## Soft service life penalty for existing
    @constraint(m, wOldRetE[t=0:T-1, i=0:I-1,
                            j=0:N[i]-1;
                            (t+j)>=servLife[i+1] && !bLoadTech[i+1]],
                wLatRet[t,i,j] == w[t, i, j] * rLatentW(t, i, j)
                #wLatRet[t,i,j] == w[t, i, j] * retCostW(mD, i, t,
                #                  min(1, max(31,N[i]-1 - t - j))))
               )
    #
    function rLatentZ(time, baseKind, kind, age0)
        si = mD.rtf.servLinc
        #sL = (i, k) -> floor(Int, servLife[i+1]*(1+si[i, k]))
        age = age0 + time
        #return retCost(mD, kind, 1, -1)*
        #exp((age-sL(baseKind, kind))/sL(baseKind, kind))
        sL = servLife # same as w
        return retCost(mD, 0, 0, 1, 0)*
        exp((age-sL[kind+1])/sL[kind+1])
    end


    ## Soft service life penalty for rf 
    @constraint(m, zOldRetE[t=0:T-1, i=0:I-1, k=0:Kz[i]-1,
                            j=0:N[i]-1;
                            (t+j)>=servLife[i+1] && 
                            t>=zDelay[i,k] && !bLoadTech[i+1]],
                zLatRet[t, i, k, j] == z[t, i, k, j] * rLatentZ(t, i, k, j)
               )
    #
    function rLatentX(time, baseKind, kind, age0)
        si = mD.nwf.servLinc
        age = time - age0
        sL = (i, k) -> floor(Int, servLife[i+1]*(1+si[i, k]))
        return retCost(mD, 0, 0, 1, 0)*
        exp((age-sL(baseKind, kind))/sL(baseKind, kind))
    end


    ## Soft service life penalty for new 
    @constraint(m, xOldRetE[t=0:T-1, i=0:I-1, k=0:Kx[i]-1,
                            j=0:N[i]-1;
                            (t-j) >= Nx[i, k] && !bLoadTech[i+1]],
                xLatRet[t, i, k, j] == x[t, i, k, j] * rLatentX(t, i, k, j)
               )

    return m
end


#80#############################################################################
"""
    genObj()
Generates the objective function alongside the soft retirment expressions.
"""
function genObj!(m::JuMP.Model, mS::modSets, mD::modData; 
        latFact::Float64=1e-03)
    #76#########################################################################
    @info "Setting objective.."
    T = mS.T
    I = mS.I
    N = mS.N
    Nx = mS.Nx
    Nz = mS.Nz
    Kz = mS.Kz
    Kx = mS.Kx
    zDelay = mD.rtf.delay
    xDelay = mD.nwf.delay

    bLoadTech = mD.ia.bLoadTech
    xOcap = m[:xOcap]
    npv = m[:npv]
    termCost = m[:termCost]
    wLatRet = m[:wLatRet]
    xLatRet = m[:xLatRet]
    zLatRet = m[:zLatRet]
    servLife = mD.ia.servLife

    #76#########################################################################
    # Soft service life expression form
    ## Existing soft sl exp
    @expression(m, wLat, sum(wLatRet))
    ## Rf soft sl exp
    @expression(m, zLat, sum(zLatRet[t, i, k, j]
                             for t in 0:T-1 for i in 0:I-1 for k in 0:Kz[i]-1
                             for j in 0:N[i]-1 if
                             (t+j)>=servLife[i+1] && t>=zDelay[i,k] && 
                             !bLoadTech[i+1])
               )
    ## New soft sl exp
    @expression(m, xLat, sum(xLatRet[t, i, k, j]
                             for t in 0:T-1 for i in 0:I-1 for k in 0:Kx[i]-1
                             for j in 0:T-1 if (t-j)>=Nx[i,k] && 
                             !bLoadTech[i+1])
               )
    # Objective function
    @objective(m, Min, (npv
                        + wLat*latFact
                        + xLat*latFact
                        + zLat*latFact
                        + (1e-6)*termCost
                       )/1e3)
end

#80#############################################################################
"""
    fixDelayed0()
Fix the variables at times less than -1. This is no longer a thing required in
the model
"""
function fixDelayed0!(m::JuMP.Model, mS::modSets, mD::modData)
    #76#########################################################################
    x = m[:x]
    I = mS.I
    Kx = mS.Kx
    xDelay = mD.nwf.delay
    #: find the maximum delay
    maxDelay = maximum(values(xDelay))
    for t in -maxDelay:-1
        for i in 0:I-1
            for k in 0:Kx[i]-1
                println("Legacy fixDelaye0, to be removed")
              #fix(x[t, i, k, 0], 0, force=true)
            end
        end
    end
end


#80#############################################################################
"""
    gridConWind()

Add the x-to-wind ratio constraint for new techs to the model.
Generally speaking we take index `baseIdx` as denominator 
(spec[i]/baseIdx), e.g. the i-th elementh of `specRatio` to construct 
the i-th constraint using the specified ratio viz. 
sum_k new_allocs_spec_index_k = (sum_k base_allocs_k) * spec_ratio
"""
function gridConWind!(
        m::JuMP.Model,
        mS::modSets,
        baseIdx::Int64,
        specRatio::Dict{Int64, Float64})
    #76#########################################################################
    xAlloc = m[:xAlloc]
    T = mS.T
    Kx = mS.Kx
    windIdx = baseIdx #: sometimes 7
    windRatio = specRatio
    specIdx = keys(specRatio)
    # Ratio of wind to other renewable fuel technology
    @constraint(m, windRatI[t=1:T-1, i in specIdx],
                sum(xAlloc[t, i, k] for k in 0:Kx[i]-1)
                ==
                sum(xAlloc[t, baseIdx, k] * windRatio[i]
                    for k in 0:Kx[baseIdx]-1)
               )
    #: only applied on new allocations
end

#80#############################################################################
"""
    EmConBudget!(m::JuMP.Model, mS::modSets)
Add the co2 budget constraint to the model.
"""
function EmConBudget!(m::JuMP.Model, mS::modSets)
    X = m[:X]
    T = mS.T
    #: important numbers
    scaleCo2 = 1e-6 # MtCo2
    co22010 = 2_258_639_000.00
    # 2.26E+06
    # co2_2010_2015 = 10_515_700_000.0
    # Greenhouse Gas Inventory Data Explorer
    co2_2010_2020 = 20_754_973_000.0
    # 19_315_983_000.0 # using the epa GHC
    co22050 = co22010 * 0.29
    #: Last term is a trapezoid minus the 2010-2015 gap
    @info("The budget: $(scaleCo2*((co22010 + co22050) * 0.5 * 41 -
                          co2_2010_2020))")
    co2OverallYr = m[:co2OverallYr]

    co2v = 38_974_735_355.0
    @info("co2v = $(scaleCo2*co2v)")

    # Carbon dioxide budget constraint
    @constraint(m, co2Budget,
                sum(co2OverallYr[t] for t in 0:T-1) <=
                (
                 (co22010 + co22050) * 0.5 * 41 
                 - co2_2010_2020
                ) * scaleCo2
               )
end

#80#############################################################################
"""
    Em0Yr!(m::JuMP.Model, mS::modSets)
Add the co2 budget constraint to the model.
"""
function Em0Yr!(m::JuMP.Model, mS::modSets, year::Int64)
    co2OverallYr = m[:co2OverallYr]
    T = mS.T
    year = year > T-1 ? T-1 : year
    @constraint(m, co0_0, sum(co2OverallYr[t] for t in year:T-1)<=0)
    #: set 90% for the year-1 so we have a baby slope.
    @constraint(m, co0_1, co2OverallYr[year-1] <= co2OverallYr[0] * 0.1)

end

#80#############################################################################
"""
    gridConUppahBound!(m::JuMP.Model, mS::modSets)
Add upper bound on bio, nuclar and hydro to the model.
"""
function gridConUpperBound!(m::JuMP.Model, mS::modSets)
    techToId = Dict()
    techToId["PC"] = 0
    techToId["NGCT"] = 1
    techToId["NGCC"] = 2
    techToId["P"] = 3
    techToId["B"] = 4
    techToId["N"] = 5
    techToId["H"] = 6
    techToId["W"] = 7
    techToId["SPV"] = 8
    techToId["STH"] = 9
    techToId["G"] = 10
    # Upper bound on some new techs
    T = mS.T
    I = mS.I
    N = mS.N
    Kz = mS.Kz
    Kx = mS.Kx
    xAlloc = m[:xAlloc]
    upperBoundDict = Dict(
                          "B" => 1000/1e3,
                          "N" => 1000/1e3,
                          "H" => 1000/1e3)
    #: Just do it directly using bounds on the damn variables
    for tech in keys(upperBoundDict)
        id = techToId[tech]
        for t in 0:T-1
            for k in 0:Kx[id]-1
                #for j in 0:Nx[id, k]
                set_upper_bound(xAlloc[t, id, k], upperBoundDict[tech])
                #end
            end
        end
    end
end


