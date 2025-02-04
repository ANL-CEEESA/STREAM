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
# postprocess.jl
# log:
# x-xx-xx implement changes of how age is considered
# 1-17-23 added some comments

#80#############################################################################


using XLSX
using JuMP
using Dates


"""
    writeRes(m::JuMP.Model, mS::modSets, mD::modData, pr::prJrnl)

Writes the results in excel format.

# Arguments
- `m::JuMP.Model`: the juMP model that contains the solutions 
- `S::modSets`: the sets that belong to the model
- `mD::modData`: data structure from the model
- `pr::prJrnl`: journalist data structure
"""
function writeRes(m::JuMP.Model, mS::modSets, mD::modData, pr::prJrnl)
    fname = pr.fname
    T = mS.T
    I = mS.I
    N = mS.N
    Kz = mS.Kz
    Kx = mS.Kx

    no_z = sum(values(Kz)) == 0 ? true : false 
    no_x = sum(values(Kx)) == 0 ? true : false 

    xDelay = mD.nwf.delay
    zDelay = mD.rtf.delay

    fuelBased = mD.ia.fuelBased
    co2Based = mD.ia.co2Based
    bLoadTech = mD.ia.bLoadTech

    initCap = mD.ta.initCap
    d = mD.ta.nachF

    maxDelay = maximum(values(xDelay))
    cFactW = mD.ta.cFac
    size_cf = size(cFactW)
    cFactZ = zeros((size_cf[1], size_cf[2], 1))
    cFactX = zeros((size_cf[1], size_cf[2], 1))

    w = m[:w]
    z = m[:z]
    x = m[:x]

    uw = m[:uw]
    uz = m[:uz]
    ux = m[:ux]

    xD = Dict()
    uxD = Dict()
    for t in 0:T
        for i in 0:I-1
            for k in 0:Kx[i]-1
                for j in 0:T-1
                    if t >= (j+xDelay[i, k])
                        xD[t, i, k, j] = value(x[t,i,k,j])
                        uxD[t, i, k, j] = value(ux[t,i,k,j])
                    else
                        xD[t, i, k, j] = 0e0
                        uxD[t, i, k, j] = 0e0
                    end
                end
            end
        end
    end

    zD = Dict()
    uzD = Dict()
    for t in 0:T
        for i in 0:I-1
            for k in 0:Kz[i]-1
                for j in 0:N[i]-1
                    if t >= (zDelay[i, k])
                        zD[t, i, k, j] = value(z[t,i,k,j])
                        uzD[t, i, k, j] = value(uz[t,i,k,j])
                    else
                        zD[t, i, k, j] = 0e0
                        uzD[t, i, k, j] = 0e0
                    end
                end
            end
        end
    end

    zTrans = m[:zTrans]
    xAlloc = m[:xAlloc]
    wE = m[:wE]
    zE = m[:zE]
    xE = m[:xE]

    W = m[:W]
    Z = m[:Z]
    X = m[:X]

    Wgen = m[:Wgen]
    Zgen = m[:Zgen]
    Xgen = m[:Xgen]
    npv = m[:npv]
    termCost = m[:termCost]
    co2OverallYr = m[:co2OverallYr]

    wRet = m[:wRet]
    zRet = m[:zRet]
    xRet = m[:xRet]

    zOcap = m[:zOcap]
    xOcap = m[:xOcap]

    wFixOnM = m[:wFixOnM]
    wVarOnM = m[:wVarOnM]

    zFixOnM = m[:zFixOnM]
    zVarOnM = m[:zVarOnM]

    xFixOnM = m[:xFixOnM]
    xVarOnM = m[:xVarOnM]

    wFuelC = m[:wFuelC]
    zFuelC = m[:zFuelC]
    xFuelC = m[:xFuelC]

    termCz = m[:termCz]
    termCx = m[:termCx]

    wLat = m[:wLat]
    zLat = m[:zLat]
    xLat = m[:xLat]

    kinds_z = mD.ia.kinds_z
    kinds_x = mD.ia.kinds_x
    
    # `_kinds.txt` file, useful for knowing the technology kinds when making
    # plots
    open(fname*"_kinds.txt", "w") do file
        write(file, "kinds_z\n")
        for i in 0:I-1
            write(file, "$(kinds_z[i+1])\n")
        end
        write(file, "kinds_x\n")
        for i in 0:I-1
            write(file, "$(kinds_x[i+1])\n")
        end
    end


    XLSX.openxlsx(fname*"_stocks.xlsx", mode="w") do xf
        sh = 0
        for i in 0:I-1
            global sh += 1
            XLSX.addsheet!(xf)
            sheet = xf[sh]
            XLSX.rename!(sheet, "w_"*string(i))
            sheet["A1"] = "time"
            #sheet["B1"] = "i = PC"
            sheet["C1"] = ["age=$(j)" for j in 0:N[i]-1]
            sheet["A2", dim=1] = collect(0:T)
            #sheet["B2", dim=1] = [1 for i in 0:T]
            for t in 0:T
                ts = string(t + 2)
                sheet["C"*ts] = [value(w[t, i, j]) for j in 0:N[i]-1]
            end

            global sh += 1
            XLSX.addsheet!(xf)
            sheet = xf[sh]
            XLSX.rename!(sheet, "uw_"*string(i))
            sheet["A1"] = "time"
            #sheet["B1"] = "i = PC"
            sheet["C1"] = ["elmAge=$(j)" for j in 0:N[i]-1]
            sheet["A2", dim=1] = collect(0:T)
            #sheet["B2", dim=1] = [1 for i in 0:T]
            for t in 0:T
                ts = string(t + 2)
                sheet["C"*ts] = [value(uw[t, i, j]) for j in 0:N[i]-1]
            end
            for k in 0:Kz[i]-1
                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "z_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                sheet["C1"] = ["rtfAge=$(j)" for j in 0:(N[i]-1)]
                sheet["A2", dim=1] = collect(0:T)
                for t in 0:T
                    ts = string(t + 2)
                    sheet["C"*ts] = [zD[t, i, k, j] for j in 0:N[i]-1]
                end

                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "uz_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                #sheet["B1"] = "i = PC"
                sheet["C1"] = ["elRfAge=$(j)" for j in 0:N[i]-1]
                sheet["A2", dim=1] = collect(0:T)
                for t in 0:T
                    ts = string(t + 2)
                    sheet["C"*ts] = [uzD[t, i, k, j] for j in 0:N[i]-1]
                end
            end
            for k in 0:Kx[i]-1
                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "x_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                # sheet["B1"] = "i = PC"
                sheet["C1"] = ["newAge=$(j)" for j in 0:T-1]
                sheet["A2", dim=1] = collect(0:T)
                # sheet["B2", dim=1] = [1 for i in 0:T]
                for t in 0:T
                    ts = string(t + 2)
                    sheet["C"*ts] = [xD[t, i, k, j] for j in 0:T-1]
                end

                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "ux_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                # sheet["B1"] = "i = PC"
                sheet["C1"] = ["eNwAge=$(j)" for j in 0:T-1]
                sheet["A2", dim=1] = collect(0:T)
                # sheet["B2", dim=1] = [1 for i in 0:T]
                for t in 0:T
                    ts = string(t + 2)
                    sheet["C"*ts] = [uxD[t, i, k, j] for j in 0:T-1]
                end
            end
        end

        global sh += 1
        XLSX.addsheet!(xf)
        sheet = xf[sh]
        XLSX.rename!(sheet, "d")
        sheet["A1"] = "time"
        sheet["B1"] = "demand"
        sheet["A2", dim=1] = collect(0:T)
        sheet["B2", dim=1] = [d[t+1] for t in 0:T-1]
    end

    XLSX.openxlsx(fname*"_em.xlsx", mode="w") do xf
        global sh = 0
        for i in 0:I-1
            if !co2Based[i+1]
                continue
            end
            global sh += 1
            XLSX.addsheet!(xf)
            sheet = xf[sh]
            XLSX.rename!(sheet, "we_"*string(i))
            sheet["A1"] = "time"
            sheet["B1"] = ["age=$(j)" for j in 0:N[i]-1]
            sheet["A2", dim=1] = collect(0:T-1)
            for t in 0:T-1
                ts = string(t + 2)
                sheet["B"*ts] = [value(wE[t, i, j]) for j in 0:N[i]-1]
            end
            for k in 0:Kz[i]-1
                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "ze_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                sheet["B1"] = ["rtfAge=$(j)" for j in 0:(N[i]-1)]
                sheet["A2", dim=1] = collect(0:T-1)
                for t in 0:T-1
                    ts = string(t + 2)
                    sheet["B"*ts] = [value(zE[t, i, k, j]) for j in 0:(N[i]-1)]
                end
            end
            for k in 0:Kx[i]-1
                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "xe_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                sheet["B1"] = ["newAge=$(j)" for j in 0:T-1]
                sheet["A2", dim=1] = collect(0:T)
                for t in 0:T-1
                    ts = string(t + 2)
                    sheet["B"*ts] = [value(xE[t, i, k, j]) for j in 0:T-1]
                end
            end
        end
    end

    #76#########################################################################
    # `_effective.xlsx` file, containing the effective capacity summary. 
    XLSX.openxlsx(fname*"_effective.xlsx", mode="w") do xf
        sh = 0
        #72#####################################################################
        for i in 0:I-1
            global sh += 1
            XLSX.addsheet!(xf)
            sheet = xf[sh]
            XLSX.rename!(sheet, "w_"*string(i))
            sheet["A1"] = "time"
            #sheet["B1"] = "i = PC"
            sheet["C1"] = ["age=$(j)" for j in 0:N[i]-1]
            sheet["A2", dim=1] = collect(0:T)
            #sheet["B2", dim=1] = [1 for i in 0:T]
            for t in 0:T-1
                ts = string(t + 2)
                sheet["C"*ts] = [value(W[t, i, j]) for j in 0:N[i]-1]
            end

            global sh += 1
            XLSX.addsheet!(xf)
            sheet = xf[sh]
            XLSX.rename!(sheet, "uw_"*string(i))
            sheet["A1"] = "time"
            #sheet["B1"] = "i = PC"
            sheet["C1"] = ["elmAge=$(j)" for j in 0:N[i]-1]
            sheet["A2", dim=1] = collect(0:T)
            #sheet["B2", dim=1] = [1 for i in 0:T]
            for t in 0:T-1
                ts = string(t + 2)
                sheet["C"*ts] = [value(uw[t, i, j]) for j in 0:N[i]-1]
            end
            for k in 0:Kz[i]-1
                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "z_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                sheet["C1"] = ["rtfAge=$(j)" for j in 0:N[i]-1]
                sheet["A2", dim=1] = collect(0:T)
                for t in 0:T-1
                    ts = string(t + 2)
                    sheet["C"*ts] = [value(Z[t, i, k, j]) for j in 0:N[i]-1]
                end

                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "uz_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                #sheet["B1"] = "i = PC"
                sheet["C1"] = ["elRfAge=$(j)" for j in 0:N[i]-1]
                sheet["A2", dim=1] = collect(0:T)
                for t in 0:T
                    ts = string(t + 2)
                    sheet["C"*ts] = [uzD[t, i, k, j] for j in 0:N[i]-1]
                end
            end
            for k in 0:Kx[i]-1
                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "x_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                # sheet["B1"] = "i = PC"
                sheet["C1"] = ["newAge=$(j)" for j in 0:T-1]
                sheet["A2", dim=1] = collect(0:T)
                # sheet["B2", dim=1] = [1 for i in 0:T]
                for t in 0:T-1
                    ts = string(t + 2)
                    sheet["C"*ts] = [value(X[t, i, k, j]) for j in 0:T-1]
                end

                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "ux_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                # sheet["B1"] = "i = PC"
                sheet["C1"] = ["eNwAge=$(j)" for j in 0:T-1]
                sheet["A2", dim=1] = collect(0:T)
                # sheet["B2", dim=1] = [1 for i in 0:T]
                for t in 0:T
                    ts = string(t + 2)
                    sheet["C"*ts] = [uxD[t, i, k, j] for j in 0:T-1]
                end
            end
        end

        #72#####################################################################
        global sh += 1
        XLSX.addsheet!(xf)
        sheet = xf[sh]
        XLSX.rename!(sheet, "d")
        sheet["A1"] = "time"
        sheet["B1"] = "demand"
        sheet["A2", dim=1] = collect(0:T)
        sheet["B2", dim=1] = [d[t+1] for t in 0:T-1]
    end


    shl = 0
    #76#########################################################################
    # transition to retrofit summary
    XLSX.openxlsx(fname*"_zp.xlsx", mode="w") do xf
        #72#####################################################################
        shl = 0
        for i in 0:I-1
            for k in 0:Kz[i]-1
                global shl += 1
                XLSX.addsheet!(xf)
                sheet = xf[shl]
                XLSX.rename!(sheet, "zp_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                #sheet["B1"] = "i = PC"
                sheet["C1"] = ["elRfAge=$(j)" for j in 0:N[i]-1]
                sheet["A2", dim=1] = collect(0:T)
                for t in 0:T
                    ts = string(t + 2)
                    sheet["C"*ts] = [value(zTrans[t, i, k, j]) for j in 0:N[i]-1]
                end
            end
        end
    end
    
    #76#########################################################################
    # retirement summary
    XLSX.openxlsx(fname*"_ret.xlsx", mode="w") do xf
        global sh = 0
        for i in 0:I-1
            global sh += 1
            XLSX.addsheet!(xf)
            sheet = xf[sh]
            XLSX.rename!(sheet, "w_"*string(i))
            sheet["A1"] = "time"
            sheet["C1"] = ["age=$(j)" for j in 0:N[i]-1]
            sheet["C2"] = [value(wRet[i, j]) for j in 0:N[i]-1]

            for k in 0:Kz[i]-1
                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "z_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                sheet["C1"] = ["rtfAge=$(j)" for j in 0:N[i]-1]
                sheet["C2"] = [value(zRet[i, k, j]) for j in 0:N[i]-1]

            end
            for k in 0:Kx[i]-1
                global sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "x_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                sheet["C1"] = ["newAge=$(j)" for j in 0:T-1]
                sheet["C2"] = [value(xRet[i, k, j]) for j in 0:T-1]

            end
        end

    end

    #76#########################################################################
    # `_ret_1.xlsx` file that contains summary of retirement cost
    XLSX.openxlsx(fname*"_ret_1.xlsx", mode="w") do xf
        row = 2
        sheet = xf[1]
        XLSX.rename!(sheet, "cost_by_age")
        sheet["A1"] = "time"
        max_age = [maximum(values(N)), maximum(values(N)), maximum(values(T))]
        max_age = maximum(max_age)
        max_age = max_age
        sheet["B1"] = [j for j in 0:max_age-1]
        for i in 0:I-1
            #: Existing
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = [value(wRet[i, j]) for j in 0:N[i]-1]
            row += 1
            #: RF
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = [value(zRet[i, k, j]) for j in 0:N[i]-1]
                row += 1
            end
            #: New
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = [value(xRet[i, k, j]) for j in 0:T-1]
                row += 1
            end
        end
    end

    #: What is this function for?
    """
        `realTimeClass(lVals, relTimes)` 
    output time relative values
    """
    function relTimeClass(lVals, relTimes)
        if sum(lVals) < 1e-08
            return Dict(t => 0.0 for t in range(0.1, 1, 10))
        end
        #relVal = lVals./sum(lVals)
        relVal = lVals
        tRank = Dict()
        j = 1
        for time in range(0.1, 1, 10)
            s = 0.
            while relTimes[j] <= time
                s += relVal[j]
                j += 1
                if j > length(relTimes)
                    break
                end
            end
            tRank[time] = s
        end
        return tRank
    end
    # `_rel_rel_t.xlsx` time relative values of retirement
    XLSX.openxlsx(fname*"_ret_rel_t.xlsx", mode="w") do xf
        row = 2
        sheet = xf[1]
        # existing
        XLSX.rename!(sheet, "cost_by_age")
        sheet["A1"] = "t"
        sheet["B1"] = [t for t in range(0.1, 1, 10)]
        for i in 0:I-1
            #: Existing
            lVals = [value(wRet[i, j]) for j in 0:N[i]-1]
            lRelAge = [j/(N[i]-1) for j in 0:N[i]-1]
            tRank = relTimeClass(lVals, lRelAge)
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = [tRank[t] for t in range(0.1, 1, 10)]
            row += 1
        end
        # retrofits go into a separate sheet
        row = 2
        XLSX.addsheet!(xf)
        sheet = xf[2]
        # retrofit
        XLSX.rename!(sheet, "cost_by_age_rf")
        sheet["A1"] = "t"
        sheet["B1"] = [t for t in range(0.1, 1, 10)]
        for i in 0:I-1
            #: RF
            for k in 0:Kz[i]-1
                lVals = [value(zRet[i, k, j]) for j in 0:N[i]-1]
                lRelAge = [j/(N[i]-1) for j in 0:N[i]-1]
                tRank = relTimeClass(lVals, lRelAge)
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = [tRank[t] for t in range(0.1, 1, 10)]
                row += 1
            end
        end
        row = 2
        XLSX.addsheet!(xf)
        sheet = xf[3]
        # new
        XLSX.rename!(sheet, "cost_by_age_new")
        sheet["A1"] = "t"
        sheet["B1"] = [t for t in range(0.1, 1, 10)]
        for i in 0:I-1
            #: New
            for k in 0:Kx[i]-1
                lVals = [value(xRet[i, k, j]) for j in 0:T-1]
                lRelAge = [j/(T-1) for j in 0:T-1]
                tRank = relTimeClass(lVals, lRelAge)
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = [tRank[t] for t in range(0.1, 1, 10)]
                row += 1
            end
        end

    end

    # `_rel_t_ucap.xlsx` time relative values of retired capacity
    XLSX.openxlsx(fname*"_ret_t_ucap.xlsx", mode="w") do xf
        row = 2
        sheet = xf[1]
        XLSX.rename!(sheet, "cap_by_age")
        sheet["A1"] = "t"
        sheet["B1"] = [t for t in range(0.1, 1, 10)]
        for i in 0:I-1
            #: Existing
            lVals = [sum(value(uw[t, i, j]) for t in 0:T-1) for j in 0:N[i]-1]
            lRelAge = [j/(N[i]-1) for j in 0:N[i]-1]
            tRank = relTimeClass(lVals, lRelAge)
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = [tRank[t] for t in range(0.1, 1, 10)]
            row += 1
        end
        row = 2
        XLSX.addsheet!(xf)
        sheet = xf[2]
        # retrofit
        XLSX.rename!(sheet, "cap_by_age_rf")
        sheet["A1"] = "t"
        sheet["B1"] = [t for t in range(0.1, 1, 10)]
        for i in 0:I-1
            #: RF
            for k in 0:Kz[i]-1
                lVals = [sum(uzD[t, i, k, j] for t in 0:T-1) for j in 0:N[i]-1]
                lRelAge = [j/(N[i]-1) for j in 0:N[i]-1]
                tRank = relTimeClass(lVals, lRelAge)
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = [tRank[t] for t in range(0.1, 1, 10)]
                row += 1
            end
        end
        row = 2
        XLSX.addsheet!(xf)
        sheet = xf[3]
        # new
        XLSX.rename!(sheet, "cap_by_age_new")
        sheet["A1"] = "t"
        sheet["B1"] = [t for t in range(0.1, 1, 10)]
        for i in 0:I-1
            #: New
            for k in 0:Kx[i]-1
                lVals = [sum(uxD[t, i, k, j] for t in 0:T-1) for j in 0:T-1]
                lRelAge = [j/(T-1) for j in 0:T-1]
                tRank = relTimeClass(lVals, lRelAge)
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = [tRank[t] for t in range(0.1, 1, 10)]
                row += 1
            end
        end
    end




    #76#########################################################################
    # `_ret_rel.xlsx` file that contains summary of retirement cost relative
    # to age.
    XLSX.openxlsx(fname*"_ret_rel.xlsx", mode="w") do xf
        row = 2
        sheet = xf[1]
        XLSX.rename!(sheet, "cost_by_age")
        sheet["A1"] = "time"
        max_age = [maximum(values(N)), maximum(values(N)), T]
        max_age = maximum(max_age)
        max_age = max_age
        sheet["B1"] = [j for j in 0:max_age-1]
        for i in 0:I-1
            #: Existing
            sheet["A$(row)"] = "t"
            sheet["B$(row)"] = [j/(N[i]-1) for j in 0:N[i]-1]
            sheet["A$(row+1)"] = "w_$(i)"
            sheet["B$(row+1)"] = [value(wRet[i, j]) for j in 0:N[i]-1]
            row += 2
            #: RF
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "t"
                sheet["B$(row)"] = [j/(N[i]-1) for j in 0:N[i]-1]
                sheet["A$(row+1)"] = "z_$(i)_$(k)"
                sheet["B$(row+1)"] = [value(zRet[i, k, j]) for j in 0:N[i]-1]
                row += 2
            end
            #: New
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "t"
                sheet["B$(row)"] = [j/(T-1) for j in 0:T-1]
                sheet["A$(row+1)"] = "x_$(i)_$(k)"
                sheet["B$(row+1)"] = [value(xRet[i, k, j]) for j in 0:T-1]
                row += 2
            end
        end
    end

    #76#########################################################################
    # `_stats.xlsx` file that contains summary of the solution statistics 
    XLSX.openxlsx(fname*"_stats.xlsx", mode="w") do xf
        shn = 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "stats")
        sheet["A1"] = "soltiming"
        sheet["A2"] = "objective"
        sheet["A3"] = "npv"
        sheet["A4"] = "retire"
        sheet["A5"] = "terminal"
        sheet["A6"] = "emissions"
        sheet["A7"] = "filename"
        sheet["A8"] = "engine"

        sheet["B1"] = solve_time(m)
        sheet["B2"] = objective_value(m)
        sheet["B3"] = value(npv)
        wrsum = sum(value(wRet[i, j]) for i in 0:I-1 for j in 0:N[i]-1)
        rrsum = no_z ? 0e0 : sum(value(zRet[i, k, j]) for i in 0:I-1 
                               for k in 0:Kz[i]-1 for j in 0:N[i]-1) 
        xrsum = no_x ? 0e0 : sum(value(xRet[i, k, j]) for i in 0:I-1 
                                 for k in 0:Kx[i]-1 for j in 0:T-1)
        sheet["B4"] = wrsum + rrsum + xrsum 
        sheet["B5"] = value(termCost)
        sheet["B6"] = sum(value(co2OverallYr[t]) for t in 0:T-1)
        fname0 = Dates.format(pr.initT, "eyymmdd-HH_MM_SS")
        sheet["B7"] = fname0*pr.tag
        sheet["B8"] = string(dre4m.version)

        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]

        #76#####################################################################
        XLSX.rename!(sheet, "cap_cost_retro")
        sheet["A1"] = "tech"
        sheet["B1"] = "capital M\$"
        row = 2
        for i in 0:I-1
            #: RF
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(zOcap[t, i, k]) 
                                                    for t in 0:T-1)
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(zOcap))
        ####
        XLSX.addsheet!(xf)
        row = 2
        shn+=1
        sheet = xf[shn]
        #76#####################################################################
        XLSX.rename!(sheet, "cap_cost_new")
        sheet["A1"] = "tech"
        sheet["B1"] = "capital M\$"
        for i in 0:I-1
            #: New
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0e0 : sum(value(xOcap[t, i, k]) 
                                                    for t in 0:T-1) 
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_x ? 0e0 : sum(value.(xOcap)) 

        XLSX.addsheet!(xf)
        shn+=1
        sheet = xf[shn]
        #76#####################################################################
        XLSX.rename!(sheet, "old_capacity_remain")
        row = 2
        sheet["A1"] = "cap (last point)"
        sheet["B1"] = "GW"
        for i in 0:I-1
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = sum(value(w[T, i, j]) 
                                   for j in 0:N[i]-1) 
            row += 1
        end

        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = sum(value.(w)) 
  
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        #76#####################################################################
        XLSX.rename!(sheet, "old_capacity_ret")

        row = 2
        sheet["A1"] = "retirement old"
        sheet["B1"] = "GW"
        for i in 0:I-1
            sheet["A$(row)"] = "uw_$(i)"
            sheet["B$(row)"] = sum(value(uw[t, i, j]) 
                                   for t in 0:T-1 for j in 0:N[i]-1) 
            row += 1
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = sum(value.(uw)) 

        XLSX.addsheet!(xf)
        shn+=1
        sheet = xf[shn]
        row = 2
        XLSX.rename!(sheet, "retro_alloc")
        sheet["A1"] = "allocations retrofit"
        sheet["B1"] = "GW"
        for i in 0:I-1
            #: Existing
            #: RF
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                # N[i] because we only consider the years of existing cap
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(zTrans[t, i, k, j]) 
                                                    for t in 0:T-1 
                                                    for j in 0:N[i]-1) 
                row += 1
            end
        end

        sheet["A$(row)"] = "sum"
        # N[i] because we only consider the years of existing cap
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(zTrans))

        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "retro_retired")

        row = 2
        sheet["A1"] = "retirement retrofit"
        sheet["B1"] = "GW"
        for i in 0:I-1
            #: Existing
            #: RF
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "uz_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0 : sum(uzD[t, i, k, j] 
                                                  for t in 0:T-1 
                                                  for j in 0:N[i]-1) 
                row += 1
            end
        end

        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0 : sum(values(uzD))

        XLSX.addsheet!(xf)
        shn+=1
        sheet = xf[shn]

        row = 2
        XLSX.rename!(sheet, "new_alloc")
        sheet["A1"] = "allocations new"
        sheet["B1"] = "GW"
        for i in 0:I-1
            #: new
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0 : sum(value(xAlloc[t, i, k]) 
                                                  for t in 0:T-1) 
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_x ? 0 : sum(value.(xAlloc))

        XLSX.addsheet!(xf)
        shn+=1
        sheet = xf[shn]
        XLSX.rename!(sheet, "new_retired")

        row = 2 
        sheet["A1"] = "retirement new"
        sheet["B1"] = "GW"
        for i in 0:I-1
            #: new
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "ux_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0 : sum(uxD[t, i, k, j] 
                                                  for t in 0:T-1 
                                                  for j in 0:T-1) 
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_x ? 0 : sum(values(uxD))
        #################
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "old_generation")
        
        row = 2 
        sheet["A1"] = "Generation"
        sheet["B1"] = "GWh"
        for i in 0:I-1
            #: new
            sheet["A$(row)"] = "Wgen_$(i)"
            sheet["B$(row)"] = sum(value(Wgen[t, i, j]) 
                                   for t in 0:T-1 
                                   for j in 0:N[i]-1) 
            row += 1
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = sum(value.(Wgen))
        #################
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "retro_generation")
        
        row = 2 
        sheet["A1"] = "Generation"
        sheet["B1"] = "GWh"
        for i in 0:I-1
            #: new
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "Zgen_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0 : sum(value(Zgen[t, i, k, j]) 
                                                  for t in 0:T-1 
                                                  for j in 0:N[i]-1) 
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0 : sum(value.(Zgen))
        #################
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "new_generation")
        
        row = 2 
        sheet["A1"] = "Generation"
        sheet["B1"] = "GWh"
        for i in 0:I-1
            #: new
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "Xgen_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0 : sum(value(Xgen[t, i, k, j]) 
                                                  for t in 0:T-1 
                                                  for j in 0:T-1) 
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_x ? 0 : sum(value.(Xgen))
        ####3
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]

        XLSX.rename!(sheet, "old_VoNm")
        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        row = 2
        for i in 0:I-1
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = sum(value(wVarOnM[t, i]) for t in 0:T-1)
            row += 1
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = sum(value.(wVarOnM))
        ####
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "retro_VoNm")

        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        row = 2
        for i in 0:I-1
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(zVarOnM[t,i,k]) 
                                                    for t in 0:T-1)
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(zVarOnM))
        ####
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "new_VoNm")

        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        row = 2
        for i in 0:I-1
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0e0 : sum(value(xVarOnM[t,i,k]) 
                                                    for t in 0:T-1) 
                row += 1
            end
        end
        ####
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_x ? 0e0 : sum(value.(xVarOnM))
        #### 
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "old_FoNm")

        row = 2
        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        for i in 0:I-1
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = sum(value(wFixOnM[t, i]) for t in 0:T-1)
            row += 1
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = sum(value.(wFixOnM))
        ####
        #
        XLSX.addsheet!(xf)
        shn+=1
        sheet = xf[shn]
        XLSX.rename!(sheet, "retro_FoNm")
        
        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        row = 2
        for i in 0:I-1
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(zFixOnM[t,i,k]) 
                                                    for t in 0:T-1)
                row += 1
            end
        end
        ####
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(zFixOnM))

        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "new_FoNm")

        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        row = 2
        for i in 0:I-1
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0e0 : sum(value(xFixOnM[t,i,k]) 
                                                    for t in 0:T-1) 
                row += 1
            end
            sheet["A$(row)"] = "sum"
            sheet["B$(row)"] = no_x ? 0e0 : sum(value.(xFixOnM)) 
        end

        ####
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "old_RetCost")

        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        row = 2
        for i in 0:I-1
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = sum(value(wRet[i, j]) for j in 0:N[i]-1)
            row += 1
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = sum(value.(wRet))
        ###

        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "retro_RetCost")

        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        row = 2
        for i in 0:I-1
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(zRet[i,k,j]) 
                                                    for j in 0:N[i]-1)
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(zRet))

        ###
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "new_RetCost")

        row = 2
        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        for i in 0:I-1
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(xRet[i,k,j]) 
                                                    for j in 0:T-1)
                row += 1
            end
        end
        ####
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(xRet))
        
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "old_fuel")

        sheet["A1"] = "old"
        sheet["B1"] = "M\$"
        row = 2
        for i in 0:I-1
            if !fuelBased[i+1]
                continue
            end
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = sum(value(wFuelC[t, i]) for t in 0:T-1)
            row += 1
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = sum(value.(wFuelC))
        
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "retro_fuel")

        row = 2
        sheet["A1"] = "retrofit"
        sheet["B1"] = "M\$"
        for i in 0:I-1
            if !fuelBased[i+1]
                continue
            end
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(zFuelC[t, i, k]) 
                                                    for t in 0:T-1)
                row += 1
            end
        end

        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(zFuelC))

        XLSX.addsheet!(xf)
        shn+=1
        sheet = xf[shn]
        XLSX.rename!(sheet, "new_fuel")

        row = 2
        sheet["A1"] = "new"
        sheet["B1"] = "M\$"
        for i in 0:I-1
            if !fuelBased[i+1]
                continue
            end
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0e0 : sum(value(xFuelC[t, i, k]) 
                                                    for t in 0:T-1)
                row += 1
            end
        end
        ####
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_x ? 0e0 : sum(value.(xFuelC))
        
        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "old_co2")

        row = 2
        sheet["A1"] = "old"
        sheet["B1"] = "tCO2"
        for i in 0:I-1
            if !co2Based[i+1]
                continue
            end
            sheet["A$(row)"] = "w_$(i)"
            sheet["B$(row)"] = sum(value(wE[t, i, j]) for t in 0:T-1 
                                   for j in 0:N[i]-1)
            row += 1
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = sum(value.(wE))

        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "retro_co2")

        row = 2
        sheet["A1"] = "retrofit"
        sheet["B1"] = "tCO2"
        for i in 0:I-1
            if !co2Based[i+1]
                continue
            end
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(zE[t, i, k, j]) 
                                                    for t in 0:T-1 
                                                    for j in 0:N[i]-1)
                row += 1
            end
        end

        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(zE))

        XLSX.addsheet!(xf)
        shn += 1
        sheet = xf[shn]
        XLSX.rename!(sheet, "new_co2")

        row = 2
        sheet["A1"] = "new"
        sheet["B1"] = "tCO2"
        for i in 0:I-1
            if !co2Based[i+1]
                continue
            end
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0e0 : sum(value(xE[t, i, k, j]) 
                                                    for t in 0:T-1 
                                                    for j in 0:T-1)
                row += 1
            end
        end
        ####
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_x ? 0e0 : sum(value.(xE))
        XLSX.addsheet!(xf)
        ###
        shn+=1
        sheet = xf[shn]
        row = 2
        XLSX.rename!(sheet, "latency")
        sheet["A1"] = "kind"
        sheet["A2"] = "existing"
        sheet["A3"] = "retrofit"
        sheet["A4"] = "new"

        sheet["B1"] = "RetirePotentialOvrll M\$"
        sheet["B2"] = value(wLat) 
        sheet["B3"] = value(zLat)
        sheet["B4"] = value(xLat) 

        ###
        XLSX.addsheet!(xf)
        ###
        shn+=1
        sheet = xf[shn]
        row = 2
        XLSX.rename!(sheet, "retro_terminalC")
        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        for i in 0:I-1
            for k in 0:Kz[i]-1
                sheet["A$(row)"] = "z_$(i)_$(k)"
                sheet["B$(row)"] = no_z ? 0e0 : sum(value(termCz[i, k, j]) 
                                                    for j in 0:N[i]-1)
                row += 1
            end
        end

        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_z ? 0e0 : sum(value.(termCz))
        XLSX.addsheet!(xf)
        ###
        shn+=1
        sheet = xf[shn]
        row = 2
        XLSX.rename!(sheet, "new_terminalC")
        sheet["A1"] = "tech"
        sheet["B1"] = "M\$"
        for i in 0:I-1
            for k in 0:Kx[i]-1
                sheet["A$(row)"] = "x_$(i)_$(k)"
                sheet["B$(row)"] = no_x ? 0e0 : sum(value(termCx[i, k, j]) 
                                                    for j in 0:T-1)
                row += 1
            end
        end
        sheet["A$(row)"] = "sum"
        sheet["B$(row)"] = no_x ? 0e0 : sum(value.(termCx))
    end

    #76#########################################################################
    # `_gen.xlsx` file that contains summary of the generation 
    XLSX.openxlsx(fname*"_gen.xlsx", mode="w") do xf
        sh = 0
        for i in 0:I-1
            sh += 1
            XLSX.addsheet!(xf)
            sheet = xf[sh]
            XLSX.rename!(sheet, "w_"*string(i))
            sheet["A1"] = "time"
            sheet["C1"] = ["age=$(j)" for j in 0:N[i]-1]
            sheet["A2", dim=1] = collect(0:T)
            for t in 0:T-1
                ts = string(t + 2)
                sheet["C"*ts] = [value(Wgen[t, i, j]) for j in 0:N[i]-1]
            end
            for k in 0:Kz[i]-1
                sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "z_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                sheet["C1"] = ["rtfAge=$(j)" for j in 0:N[i]-1]
                sheet["A2", dim=1] = collect(0:T)
                for t in 0:T-1
                    ts = string(t + 2)
                    sheet["C"*ts] = [value(Zgen[t, i, k, j]) for j in 0:N[i]-1]
                end
            end
            for k in 0:Kx[i]-1
                sh += 1
                XLSX.addsheet!(xf)
                sheet = xf[sh]
                XLSX.rename!(sheet, "x_"*string(i)*"_"*string(k))
                sheet["A1"] = "time"
                sheet["C1"] = ["newAge=$(j)" for j in 0:T-1]
                sheet["A2", dim=1] = collect(0:T)
                for t in 0:T-1
                    ts = string(t + 2)
                    sheet["C"*ts] = [value(Xgen[t, i, k, j]) for j in 0:T-1]
                end
            end
        end
        sh += 1
        XLSX.addsheet!(xf)
        sheet = xf[sh]
        XLSX.rename!(sheet, "d")
        sheet["A1"] = "time"
        sheet["B1"] = "demand"
        sheet["A2", dim=1] = collect(0:T)
        sheet["B2", dim=1] = [d[t+1] for t in 0:T-1]
    end
end

