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

# vim: expandtab colorcolumn=80 tw=80

# created @dthierry 2022
# log:
# 1-17-23 added some comments

using XLSX

"""
    timeAttr(inputFile::String)
Initializes the time dependent attributes of the model.
inputFile must be the name of the input excel file.
"""
mutable struct timeAttr
    # initial capacity
    initCap::Array{Float64, 2} #: MW
    # demand
    nachF::Array{Float64, 2} #: MWh
    # capacity factor
    cFac::Array{Float64, 2} #: capacity Factor
    # heat rate(s)
    heatRw::Array{Float64, 2} #: BTu/kWh
    heatRx::Array{Float64, 2} #: BTu/kWh
    heatRwAvg::Vector{Float64}
    # constructor
    function timeAttr(inputFile::String)
        XLSX.openxlsx(inputFile, mode="r") do xf
            # set sheet
            sR = xf["reference"]
            icf = sR["C2"]
            nf = sR["C3"]
            hrf = sR["C5"]
            hr2f = sR["C6"]
            s = xf["timeAttr"]
            # set arrays
            ic = s[sR["B2"]].*icf # initial
            nh = s[sR["B3"]].*nf # nachtf
            cf = s[sR["B4"]] # cap fact
            ho = s[sR["B5"]].*hrf # vint hr
            hn = s[sR["B6"]].*hr2f # new hr
            hoAvg = []
            for i in 1:size(ho)[1]
                v = filter(x->x>0, ho[i, :])
                a = sum(v)/length(v)
                push!(hoAvg, isnan(a) ? 0 : a)
            end
            new(ic,
                nh,
                cf,
                ho,
                hn, hoAvg)
        end
    end
end

"""
    costAttr(inputFile::String)
Initializes the cost attributes of the model. 
inputFile must be the name of the input excel file.
"""
mutable struct costAttr
    #: the Kapital
    capC::Array{Float64, 2} #: $/kW
    #: Fixed O&M
    fixC::Array{Float64, 2} #: $/kWyr
    #: Variabl O&M
    varC::Array{Float64, 2} #: $/MWh
    #: Sales
    elecSaleC::Array{Float64, 2} #: cent/kWh
    #: Fuel
    fuelC::Array{Float64, 2}
    #: Decomission (time invariant)
    decomC::Array{Float64, 2}  #: $/MW
    # Constructor
    function costAttr(inputFile::String)
        XLSX.openxlsx(inputFile, mode="r") do xf
            sR = xf["reference"]
            ccf = sR["C8"]
            fcf = sR["C9"]
            vcf = sR["C10"]
            esf = sR["C11"]
            fuf = sR["C12"]
            dcf = sR["C13"]
            # set sheet
            s = xf["costAttr"]
            # set arrays
            cc = s[sR["B8"]].*ccf
            fc = s[sR["B9"]].*fcf
            vc = s[sR["B10"]].*vcf
            es = s[sR["B11"]].*esf
            fu = s[sR["B12"]].*fuf
            dc = s[sR["B13"]].*dcf
            new(cc, fc, vc, es, fu, dc)
        end
    end
end

"""
    invrAttr(inputFile::String)
Initialize the time invariant attributes of the model.
inputFile must be the name of the input excel file.
"""
mutable struct invrAttr
    servLife::Vector{Int64} #: yr, we put this in vector form for which reason?
    carbInt::Array{Float64} #: kgCO2/MMBTU
    
    kinds_z::Array{Int64}
    kinds_x::Array{Int64}

    fuelBased::Array{Bool}
    co2Based::Array{Bool}
    bLoadTech::Array{Bool}

    ninput::Array{Int64}

    # util_cfs = capacity_factors
    #: Discount rate
    discountR::Float64
    #: Heat rate increase
    heatIncR::Float64
    #: Loan period 
    loanP::Int64
    # Constructor
    function invrAttr(inputFile::String)
        XLSX.openxlsx(inputFile, mode="r") do xf
            sR = xf["reference"]
            cif = sR["C18"]
            # set sheet
            s = xf["invrAttr"]
            sl = s[sR["B17"]]
            sl = vec(sl)
            ci = s[sR["B18"]].*cif
            kz = s[sR["B22"]]
            kx = s[sR["B23"]]
            #booleans
            fb = s[sR["B24"]]
            cb = s[sR["B25"]]
            bl = s[sR["B26"]]

            ni = s[sR["B27"]]

            dr = s[sR["B19"]]
            hri = s[sR["B20"]]
            lp = s[sR["B21"]]

            new(sl, 
                ci, 
                kz, 
                kx,
                fb,
                cb,
                bl,
                ni,
                dr, 
                hri, 
                lp)
        end
    end
end

#: we keep the rf function but the fallback goes to the matrix
"""
    absForm(inputFile::String)
Abstract asset modifier.
inputFile: must be the name of the input excel file.
kRef: reference cell for the kinds at the `reference` sheet
m9Ref: reference cell for the 9999 matrix at the `reference` sheet

The `absForm` effectively amounts to set of dictionaries, for which the keyes
are the base tech and the "kind", e.g. base tech = 0, kinds in {0, 1, 2, 3,
...}.

Then we have elements like `mCc` and "bCc", which correspond to the multiplier
and the *fuel switch*. Acess should be a typical, `absForm.mCc[(i, k)]`, and so
on and so forth.

todo: get rid of the `-9999` thing, it is just ugly.
"""
struct absForm
    delay
    servLinc
    mCc
    mFc
    mVc
    mHr
    mEm
    mFu

    bCc
    bFc
    bVc
    bHr
    bEm
    bFu
    ubhr

    ccHrRedBool
    ccHrRedVal
    whatev 
    # constructor
    function absForm(inputFile::String, kRef::String, m9Ref::String)
        mCc = Dict((0,0)=>-9999e0)
        mFc = Dict((0,0)=>-9999e0)
        mVc = Dict((0,0)=>-9999e0)
        mHr = Dict((0,0)=>-9999e0)
        mEm = Dict((0,0)=>-9999e0)
        mFu = Dict((0,0)=>-9999e0)

        bCc = Dict((0,0)=>-9999)
        bFc = Dict((0,0)=>-9999)
        bVc = Dict((0,0)=>-9999)
        bHr = Dict((0,0)=>-9999)
        bEm = Dict((0,0)=>-9999)
        bFu = Dict((0,0)=>-9999)
        
        delay = Dict((0,0)=>0) #: leading time
        sLinc = Dict((0,0)=>0e0) 
        ubhr = Dict((0,0)=>false)

        chrrbool = Dict((0,0)=>false)
        chrrval = Dict()
        whatev = Dict()
        XLSX.openxlsx(inputFile, mode="r") do xf
            #: read the reference cells
            sR = xf["reference"] 
            kIdx = sR[kRef] # this was B22
            matIdx = sR[m9Ref]  # this was B27

            #: use the references to read the actual matrix 
            s = xf["invrAttr"]
            kinds_z = s[kIdx]
            In = length(kinds_z)
            
            mat9999 = s[matIdx] #: this name happened because it was a 9999
            offset = 1
            i = 0
            for kn in kinds_z
                k = 0
                for j in (offset+1):(offset+kn)
                    delay[(i, k)] = mat9999[j,1]>0 ? mat9999[j,1] : 0
                    sLinc[(i, k)] = mat9999[j,2]>0 ? mat9999[j,2] : 0
                    mCc[(i, k)] = mat9999[j, 3]
                    bCc[(i, k)] = floor(mat9999[j, 4])
                    mVc[(i, k)] = mat9999[j, 5]
                    bVc[(i, k)] = floor(mat9999[j, 6])
                    mFc[(i, k)] = mat9999[j, 7]
                    bFc[(i, k)] = floor(mat9999[j, 8])
                    mHr[(i, k)] = mat9999[j, 9]
                    bHr[(i, k)] = floor(mat9999[j, 10])
                    mEm[(i, k)] = mat9999[j, 11]
                    bEm[(i, k)] = floor(mat9999[j, 12])
                    mFu[(i, k)] = mat9999[j, 13]
                    bFu[(i, k)] = floor(mat9999[j, 14])
                    ubhr[(i, k)] = 
                    ismissing(mat9999[j, 15]) ? false : mat9999[j, 15]
                    if !ismissing(mat9999[j, 16])
                        chrrbool[(i, k)] = mat9999[j, 16]
                        if mat9999[j, 16]
                            chrrval[(i, k)] = mat9999[j, 17]
                            whatev[(i, k)] = mat9999[j, 18]
                        end
                    end
                    k += 1
                end
                offset += kn + 1
                i += 1
            end
        end
        new(delay,
            sLinc,
            mCc, 
            mFc, 
            mVc, 
            mHr, 
            mEm, 
            mFu, 
            bCc, 
            bFc, 
            bVc, 
            bHr, 
            bEm, 
            bFu, 
            ubhr, 
           chrrbool, chrrval, whatev)
    end
end


"""
    miscParam(inputFile::String)
Miscellaneous parameters.
inputFile must be the name of the input excel file.
"""
struct miscParam
    genScale::Float64
    hrToEff::Float64 # heat rate to efficiency factor
    # constructor
    function miscParam(inputFile::String)
        XLSX.openxlsx(inputFile, mode="r") do xf
            sheet = xf["reference"]
            gS = sheet["B31"]
            hrtoef = sheet["B32"]
            new(gS, hrtoef)
        end
    end
end
##

