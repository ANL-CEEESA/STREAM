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
# coef_custom.jl
# log:
# 1-18-23 added some comments

# Capital

"""
    devCapCost(mD, baseKind, kind, time, form)

Returns capital cost coefficient for developments, either new capacity "X" or
retrofit "R"

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `kind::Int64`: kind of the child tech
- `time::Int64`: time
- `form::String`: form, either `R` for rf or `X` for new
"""
function devCapCost(mD::modData, 
        baseKind::Int64, 
        kind::Int64, 
        time::Int64, 
        form::String) #: M$/GW
    cA = mD.ca
    iA = mD.ia
    discount = 1/((1.e0 +iA.discountR)^time) #: discount factor
    #: check the form
    if form == "R"
        f = mD.rtf #: retrofit
    elseif form == "X"
        f = mD.nwf
    end
    m = f.mCc[(baseKind, kind)]
    b = f.bCc[(baseKind, kind)]
    (multiplier, baseFuel) = ("error", baseKind)
    if m >= 0
        multiplier = m
    end
    if b >= 0
        baseFuel = b
    end
    capCost = multiplier*cA.capC[baseKind+1, time+1]*discount
    return capCost
end

"""
    devFixCost(mD, baseKind, kind, time, form)

Returns fixed cost coefficient for developments, either new capacity "X" or
retrofit "R"

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `kind::Int64`: kind of the child tech
- `time::Int64`: time
- `form::String`: form, either `R` for rf or `X` for new

"""
function devFixCost(mD::modData, 
        baseKind::Int64, 
        kind::Int64, 
        time::Int64,
        form::String) #: M$/GW
    cA = mD.ca
    iA = mD.ia
    discount = 1/((1.e0 +iA.discountR)^time) #: discount factor 
    #: check the form
    if form == "R"
        f = mD.rtf #: retrofit
    elseif form == "X"
        f = mD.nwf
    end
    m = f.mFc[(baseKind, kind)]
    b = f.bFc[(baseKind, kind)]
    (multiplier, baseFuel) = ("error", baseKind)
    if m >= 0
        multiplier = m
    end
    if b >= 0
        baseFuel = b
    end
    fixCost = multiplier*cA.fixC[baseKind+1, time+1]*discount
    return fixCost
end

"""
    devVarCost()

Returns var cost coefficient for developments, either new capacity "X" or
retrofit "R"

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `kind::Int64`: kind of the child tech
- `time::Int64`: time
- `form::String`: form, either `R` for rf or `X` for new
"""
function devVarCost(mD::modData, 
        baseKind::Int64, 
        kind::Int64, 
        time::Int64, 
        form::String) #: M$/GW
    cA = mD.ca
    iA = mD.ia
    discount = 1/((1.e0 +iA.discountR)^time) #: discount factor 
    #: check the form
    if form == "R"
        f = mD.rtf #: retrofit
    elseif form == "X"
        f = mD.nwf
    end
    m = f.mVc[(baseKind, kind)]
    b = f.bVc[(baseKind, kind)]
    (multiplier, baseFuel) = ("error", baseKind)
    if m >= 0
        multiplier = m
    end
    if b >= 0
        baseFuel = b
    end
    varCost = multiplier*cA.varC[baseKind+1, time+1]*discount
    return varCost
end

# Operation and Maintenance (adjusted)
# (existing)

"""
    wFixCost(mD, baseKind, time)

Returns fixed cost coefficient for developments, either new capacity "X" or
retrofit "R"

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `time::Int64`: time
"""
function wFixCost(mD::modData, baseKind::Int64, time::Int64) #: M$/GW
    cA = mD.ca
    iA = mD.ia
    discount = 1/((1.e0 +iA.discountR)^time)
    return cA.fixC[baseKind+1, time+1]*discount
end

"""
    wVarCost(mD, baseKind, time)

Returns variable cost coefficient for developments, either new capacity "X" or
retrofit "R"

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `time::Int64`: time
"""
function wVarCost(mD::modData, baseKind::Int64, time::Int64) #: M$/GWh
  #: Based on generation.
  cA = mD.ca
  iA = mD.ia
  discount = 1/((1.e0 +iA.discountR)^time)
  return cA.varC[baseKind+1, time+1]*discount
end

"""
    retCost(mD::modData, kind::Int64, time::Int64, age::Int64)
Cost of retirement.

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `time::Int64`: time
- `age0::Int64`: initial age
- `tag::String`: either `X`, i.e. new, or `R`, i.e. rf
"""
function retCost(mD::modData, baseKind::Int64, kind::Int64, 
        time::Int64, age0::Int64; tag::String="") 
    #: M$/GW
    cA = mD.ca
    iA = mD.ia
    discount = 1/((1.e0 +iA.discountR)^time)
  
    #: old & retrof will have base age of (earliest), 
    # otw the year of creation for new cap
    #: for old + retro set base age to 0
    baseAge = 0
    currentAge = time + age0
    if tag == "X"
        baseAge = age0
        currentAge = time - age0
        if currentAge < 0
            throw(DomainError(time-age0, "argument must be nonnegative"))
        end
    end
    #: Loan liability
    loanFrac = max(iA.loanP - currentAge, 0)/iA.loanP
  
    #: just in case we go above for new plants
    maxYr = size(cA.capC)[2]
    if baseAge > maxYr-1
        baseAge = maxYr-1
    end
  
    #: Capital cost
    if tag == "R"
        m = mD.rtf.mCc[(baseKind, kind)]#: retrofit
        m = m < 1. ? m + 1. : m  #: it has to be at least 1.
    elseif tag == "X"
        m = mD.nwf.mCc[(baseKind, kind)]#: retrofit
    else
        m = 1.0
    end
    
    multiplier = "error"
  
    if m >= 0
        multiplier = m
    end
  
    capCost = multiplier*cA.capC[baseKind+1, baseAge+1]
  
    loanLiability = loanFrac*capCost*discount
    return loanLiability # + decom # lostRev*365*24
end

#
#
"""
    saleLost(mD::modData, kind::Int64, time::Int64, age0::Int64, tag::String)
The lost sales.

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `time::Int64`: time
- `age0::Int64`: initial age
- `tag::String`: either `X`, i.e. new, or `R`, i.e. rf
"""
function saleLost(mD::modData, kind::Int64, time::Int64, age0::Int64;
        tag::String="") 
  #: M$/GWh
  cA = mD.ca
  iA = mD.ia
  discount = 1/((1.e0+iA.discountR)^time)
  currentAge = time + age0
  if tag == "X"
      currentAge = time - age0
      if currentAge < 0
          throw(DomainError(time-age0, "argument must be nonnegative"))
      end
  end

  effSrvLf = max(iA.servLife[kind+1] - currentAge, 0)
  lostRev = effSrvLf*cA.elecSaleC[time+1] * discount
  return lostRev
end

"""
    wHeatRate()
Heat rate coefficient.
This reflects the initial age, i.e age0

# Arguments
- `mD::modData`: model data structure
- `kind::Int64`: kind of the parent tech
- `age0::Int64`: initial age
- `time::Int64`: time
"""
#: existing plant heat rate, (hr0) * (1+increase) ^ time
function wHeatRate(mD::modData, 
        kind::Int64, 
        age0::Int64, 
        time::Int64)
    tA = mD.ta
    iA = mD.ia
    # baseAge = min(maxBase, baseAge)
    #hRate0 = tA.heatRwAvg[kind+1] ## testing
    hRate0 = tA.heatRw[kind+1, age0+1]
    return hRate0*(1.e0+iA.heatIncR)^time
end

#: (retrofit)
#: HeatRate
"""
    zHeatRate()
Heat rate coefficient for retrofitted assets.  This reflects the initial age,
i.e age0. Also if ccHrRedBool is true, then there is a penalty on the heat rate,
calculated as percentage points, and then substracted to the heat rate. 

If the resulting efficiency is less thn zero, we don't have a mechanism to
correct this, therefore, no changes are made. 

Also see the function: devDerating (used for generation)

# Arguments
- `mD::modData`: model data structure
- `kind::Int64`: kind of the parent tech
- `age0::Int64`: initial age
- `time::Int64`: time
"""
function zHeatRate(mD::modData, 
        baseKind::Int64, 
        kind::Int64, 
        age0::Int64, 
        time::Int64)
    tA = mD.ta
    iA = mD.ia
    rtf = mD.rtf
    #: evaluate retrofit
    #:
    m = rtf.mHr[(baseKind, kind)]
    b = rtf.bHr[(baseKind, kind)]
    (multiplier, baseFuel) = ("error", baseKind)
    if m >= 0
        multiplier = m
    end
    if b >= 0
        baseFuel = b
    end
    maxYr = size(tA.heatRx)[2]
    ageX = age0
    if age0 > maxYr-1
        ageX = maxYr-1
    end
    # use new heat rate as reference
    hr0 = tA.heatRx[baseFuel+1, ageX+1]
    if rtf.ubhr[baseKind, kind] # but, if true use the base heat rate.
        hr0 = tA.heatRw[baseFuel+1, age0+1]
        hr0 = hr0 <= 1e-06 ? tA.heatRwAvg[baseFuel+1] : hr0
    end
    if rtf.ccHrRedBool[baseKind, kind]
        multiplier = 1.0 # override
        hrToEff = mD.misc.hrToEff # scale factor
        eff = 1/(hr0*hrToEff)
        reduction = rtf.ccHrRedVal[baseKind, kind] # eff points
        eff -= reduction/100.
        if eff <= 0.e0
            #print("[WARN] ccs hr eff for this RF less than 0, skip")
            #print(" b=$(baseKind):k=$(kind)\n")
            #throw(error())
            #: same as derating error
        else
            hr0 = 1/eff
            hr0 /= hrToEff #rescale back
        end
    end
    heatIncr = (1.e0+iA.heatIncR)^time
    return multiplier*hr0*heatIncr
end


"""
    xHeatRate(mD::modData, baseKind::Int64, kind::Int64, 
    age0::Int64, time::Int64)
Heat rate coefficient for new plants.
This reflects the initial age, i.e age0

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `kind::Int64`: child kind 
- `time::Int64`: time
"""
function xHeatRate(mD::modData, baseKind::Int64, kind::Int64, 
        age0::Int64, time::Int64)
    tA = mD.ta
    iA = mD.ia
    nwf = mD.nwf

    m = nwf.mHr[(baseKind, kind)]
    b = nwf.bHr[(baseKind, kind)]
    (multiplier, baseFuel) = ("error", baseKind)
    if m >= 0
        multiplier = m
    end
    if b >= 0
        baseFuel = b
    end
    maxYr = size(tA.heatRx)[2]
    if age0 > maxYr-1
        age0 = maxYr-1
    end
    heatIncr = (1.e0+iA.heatIncR)^time
    return multiplier*tA.heatRx[baseFuel+1, age0+1]*heatIncr
end

#: (retrofit)
#: Carbon instance
"""
    wCarbonInt(mD::modData, baseKind::Int64)
Carbon intensity for existing plants.
This reflects the initial age, i.e age0

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
"""
function wCarbonInt(mD::modData, baseKind::Int64)
    iA = mD.ia
    #:
    baseFuel = baseKind
    return iA.carbInt[baseFuel+1]
end

#: (retrofit)
#: Carbon instance
"""
    devCarbonInt(mD::modData, baseKind::Int64, kind::Int64, form::String)
Carbon intensity for developments, i.e. rf or new.
This reflects the initial age, i.e age0

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
"""
function devCarbonInt(mD::modData, 
        baseKind::Int64, 
        kind::Int64, 
        form::String)
    iA = mD.ia
    if form == "R"
        f = mD.rtf
    elseif form == "X"
        f = mD.nwf
    end
    #:
    m = f.mEm[(baseKind, kind)]
    b = f.bEm[(baseKind, kind)]
    (multiplier, baseFuel) = ("error", baseKind)
    if m >= 0
        multiplier = m
    end
    if b >= 0
        baseFuel = b
    end
    return iA.carbInt[baseFuel+1] * multiplier
end

#: fuel costs only include those techs that are based in fuel burning
"""
    wFuelCost(mD::modData, baseKind::Int64, kind::Int64, form::String)
Fuel costs for existing plants.

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `time::Int64`: time 
"""
function wFuelCost(mD::modData, baseKind::Int64, 
        time::Int64)
    cA = mD.ca
    iA = mD.ia
    discount = 1/((1.e0+iA.discountR)^time)
    baseFuel = baseKind
    return cA.fuelC[baseFuel+1, time+1]*discount 
end

#: fuel costs only include those techs that are based in fuel burning
"""
    devFuelCost(mD::modData, baseKind::Int64, kind::Int64, form::String)
Fuel costs for existing plants.

# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `kind::Int64`: technology kind 
- `time::Int64`: time 
- `form::Int64`: form, either "R" for rf or "X" for new
"""
function devFuelCost(mD::modData, 
                   baseKind::Int64, 
                   kind::Int64,
                   time::Int64, form::String)
    tA = mD.ta
    cA = mD.ca
    iA = mD.ia
    if form == "R"
        f = mD.rtf
    elseif form == "X"
        f = mD.nwf
    end
    discount = 1/((1.e0 +iA.discountR)^time)
    #: evaluate retrofit
    m = f.mFu[(baseKind, kind)]
    b = f.bFu[(baseKind, kind)]
    (multiplier, baseFuel) = ("error", baseKind)
    if m >= 0
        multiplier = m
    end
    if b >= 0
        baseFuel = b
    end
    #:
    return multiplier*cA.fuelC[baseFuel+1, time+1]*discount 
end



"""
    devDerating(mD::modData, baseKind::Int64, kind::Int64, form::String)
Penalty on the power generation (based on a multiplier). 

This considers the percentage points and directly substract them to the 100%
that otherwise would be produced. 


# Arguments
- `mD::modData`: model data structure
- `baseKind::Int64`: kind of the parent tech
- `kind::Int64`: technology kind 
- `time::Int64`: time 
- `form::Int64`: form, either "R" for rf or "X" for new
"""
function devDerating(mD::modData, 
                   baseKind::Int64, 
                   kind::Int64,
                   age0::Int64,
                   time::Int64, form::String)
    tA = mD.ta
    cA = mD.ca
    iA = mD.ia
    rtf = mD.rtf
    if form == "R"
        f = mD.rtf
    elseif form == "X"
        f = mD.nwf
    end
    #: evaluate retrofit
    multiplier = 1.e0

    if rtf.ccHrRedBool[baseKind, kind]
        hr0 = tA.heatRw[baseKind+1, age0+1]
        hrToEff = mD.misc.hrToEff # scale factor
        # convert to hr->eff
        eff = 1/(hr0*hrToEff)
        deltaEta = rtf.ccHrRedVal[baseKind, kind] # eff points
        deltaEta /= 100e0
        if eff <= 0.e0
            print("[WARN](DERATING) this is leading to less than zero\
                  multiplier, setting multiplier to 1\t")
            print("\tbase $(baseKind) kind $(kind)\n")
            #throw(error())
        else
            multiplier = 1.0-(deltaEta/eff)
            #println("multiplier $(multiplier)::$(baseKind)-$(kind)")
            if !(0e0<=multiplier<=1e0)
                #print("check values!\t")
                #print("base=$(baseKind), kind=$(kind)\
                #      $(hr0) $(eff) $(deltaEta) $(multiplier)\n")
                #throw(error())
                println("[WARN] skip derating for b=$(baseKind):k=$(kind)")
                multiplier = 1e-08 # make no power
            end
        end
    end
    #:
    return multiplier 
end

