# Copyright (C) 2024, UChicago Argonne, LLC
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

# vim: tabstop=2 shiftwidth=2 expandtab colorcolumn=80 tw=80

# created by David Thierry @dthierry 2024
# log:

#80#############################################################################

using DataFrames
using CSV
using XLSX 
using Dates

"""
    generate_yr_range(p::params)

Generates a list that contains the years of analysis.

"""
function generate_yr_range(p::params)
    y0 = p.y0
    y_sp = p.yr_subperiod
    np = p.n_periods
    ns = p.n_subperiods
    #
    stop = y0 + np*ns*y_sp
    return collect(range(y0, stop=stop, step=y_sp))[1:end-1]
end

"""
    gen_folder()

Generate a string with the folder name.
"""
function gen_folder()
    d = now()
    x = Dates.value(d)
    fname = "result-$x"
    return fname
end

"""
    write_demand(m::JuMP.Model, p::params, s::sets, fname::String)

Writes a csv that contains the demand timeseries.
"""
function write_demand(m::JuMP.Model, p::params, s::sets, fname::String)
    d = reshape(p.demand', length(p.demand))
    df = DataFrame("demand"=>d)
    CSV.write(fname*"/"*"demand.csv", df)
end

"""
    em_df(m::JuMP.Model, p::params, s::sets, fname::String)

Writes a csv that contains the demand timeseries.
"""
function em_df(m::JuMP.Model, p::params, s::sets, fname::String)
    #    
    oep1 = value.(m[:o_ep1ge][:, :, 1])
    nep1 = value.(m[:n_ep1ge][:, :, 1])
    
    ou = value.(m[:o_u][:, :, 1]).*p.GcI[:, :, 1]*0.29329722222222
    nu = value.(m[:n_u][:, :, 1]).*p.GcI[:, :, 1]*0.29329722222222

    for l in s.L
        if l == 1
            continue
        end
        oep1 += value.(m[:o_ep1ge][:, :, l])
        nep1 += value.(m[:n_ep1ge][:, :, l])
        ou += value.(m[:o_u][:, :, l]).*p.GcI[:, :, l]*0.29329722222222
        nu += value.(m[:n_u][:, :, l]).*p.GcI[:, :, l]*0.29329722222222

    end

    oep1 = Vector(reshape(oep1', length(oep1)))
    nep1 = reshape(nep1', length(nep1))
    ou = Vector(reshape(ou', length(ou)))
    nu = reshape(nu', length(nu))
   
    yr = generate_yr_range(p)

    co2 = reshape(p.co2_budget', length(p.co2_budget))
    

    df = DataFrame(
       "yr"=>yr, 
       "oep1"=>oep1, 
       "ou"=>ou, 
       "nep1"=>nep1, 
       "nu"=>nu,
       "co2budget"=>co2
    )

    CSV.write(fname*"/"*"em.csv", df)
end


"""
    plot_cap_by_rf(m::JuMP.Model, p::params, s::sets)

This is not longer used.
"""
function plot_cap_by_rf(m::JuMP.Model, p::params, s::sets)
    yr = generate_yr_range(p)
    dyr = DataFrame("yr"=>yr)

    ocp = value.(m[:o_cp][:, :, 1])
    ncp = value.(m[:n_cp][:, :, 1])

    for l in s.L
        if l == 1
            continue
        end
        ocp += value.(m[:o_cp][:, :, l])
        ncp += value.(m[:n_cp][:, :, l])
    end

    rcpd = value.(m[:r_cp_d_][:, :, 1, :])

    for l in s.L
        if l == 1
            continue
        end
        rcpd += value.(m[:r_cp_d_][:, :, 1, :])
    end

end

"""
    write_xcp(m::JuMP.Model, p::params, s::sets, fname::String)

Write existing capacity and new capacity csv files.
"""
function write_xcp(m::JuMP.Model, p::params, s::sets, fname::String)

    yr = generate_yr_range(p)

    docp = DataFrame("yr"=>yr)
    for l in s.L
        ocp = value.(m[:o_cp])[:, :, l]
        ocp = reshape(ocp', length(ocp))
        docp[:, "l_$(l)"] = ocp
    end
    CSV.write(fname*"/"*"docp.csv", docp)
    #
    dncp = DataFrame("yr"=>yr)
    for l in s.L
        ncp = value.(m[:n_cp])[:, :, l]
        ncp = reshape(ncp', length(ncp))
        dncp[:, "l_$(l)"] = ncp
    end
    CSV.write(fname*"/"*"dncp.csv", dncp)

    return docp, dncp
end

"""
    write_rcp(m::JuMP.Model, p::params, s::sets, fname::String)

Write retrofit capacity, emission and electricity consumption.
"""
function write_rcp(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)

    dyr = DataFrame("yr"=>yr)

    drcp_d = DataFrame("yr"=>yr)

    drcp_d_act = DataFrame("yr"=>yr)

    for l in s.L
        yo = value.(m[:y_o][:, :, l])
        yo = reshape(yo', length(yo))
        yo = round.(yo)
        yo = trunc.(Int32, yo)
        for k in s.Kr
            rcp = value.(m[:r_cp_d_][:, :, l, k])
            rcp = reshape(rcp', length(rcp))

            drcp_d[:, "k_$(k)_l_$(l)"] = rcp
            drcp_d_act[:, "k_$(k)_l_$(l)"] = rcp.*yo

        end
    end
    CSV.write(fname*"/"*"drcp_d.csv", drcp_d)
    CSV.write(fname*"/"*"drcp_d_act.csv", drcp_d_act)
    
    drcp = DataFrame("yr"=>yr)
    drep1 = DataFrame("yr"=>yr)
    dru = DataFrame("yr"=>yr)
    for k in s.Kr
        rcp_acc = zeros(length(s.P)*length(s.P2))
        rep1_acc = zeros(length(s.P)*length(s.P2))
        ru_acc = zeros(length(s.P)*length(s.P2))
        for l in s.L
            yo = value.(m[:y_o][:, :, l])
            yo = reshape(yo', length(yo))
            yo = round.(yo)
            yo = trunc.(Int32, yo)

            rcp = value.(m[:r_cp_d_][:, :, l, k])
            rcp = reshape(rcp', length(rcp))
            rcp_acc .+= rcp.*yo

            #r_ep1ge_d_
            rep1 = value.(m[:r_ep1ge_d_][:, :, l, k])
            rep1 = reshape(rep1', length(rep1))
            rep1_acc .+= rep1.*yo

            #r_u_d_
            ru = value.(m[:r_u_d_][:, :, l, k])
            ru = reshape(ru', length(ru))
            ru_acc .+= ru.*yo

        end
        drcp[:, "k_$(k)"] = rcp_acc
        drep1[:, "k_$(k)"] = rep1_acc
        dru[:, "k_$(k)"] = ru_acc
    end
    CSV.write(fname*"/"*"drcp.csv", drcp)
    CSV.write(fname*"/"*"drep1.csv", drep1)
    CSV.write(fname*"/"*"dru.csv", dru)

    return drcp
end

"""
    write_ncp(m::JuMP.Model, p::params, s::sets, fname::String)

Write new capacity, emission and electricity consumption.
"""
function write_ncp(m::JuMP.Model, p::params, s::sets, fname::String)

    yr = generate_yr_range(p)

    dncp_d = DataFrame("yr"=>yr)
    for l in s.L
        for k in s.Kn
            ncp = value.(m[:n_cp_d_][:, :, l, k])
            ncp = reshape(ncp', length(ncp))
            dncp_d[:, "k_$(k)_l_$(l)"] = ncp
        end
    end
    CSV.write(fname*"/"*"dncp_d.csv", dncp_d)
    
    dncp = DataFrame("yr"=>yr)
    dnep1 = DataFrame("yr"=>yr)
    dnu = DataFrame("yr"=>yr)
    for k in s.Kn
        ncp_acc = zeros(length(s.P)*length(s.P2))
        nep1_acc = zeros(length(s.P)*length(s.P2))
        nu_acc = zeros(length(s.P)*length(s.P2))
        for l in s.L
            ncp = value.(m[:n_cp_d_][:, :, l, k])
            ncp = reshape(ncp', length(ncp))
            ncp_acc .+= ncp
            # n_ep1ge_d_
            nep1 = value.(m[:n_ep1ge_d_][:, :, l, k])
            nep1 = reshape(nep1', length(nep1))
            nep1_acc .+= nep1
            # n_u_d_
            nu = value.(m[:n_u_d_][:, :, l, k])
            nu = reshape(nu', length(nu))
            nu_acc .+= nu
        end
        dncp[:, "k_$(k)"] = ncp_acc
        dnep1[:, "k_$(k)"] = nep1_acc
        dnu[:, "k_$(k)"] = nu_acc
    end
    CSV.write(fname*"/"*"dncp.csv", dncp)
    CSV.write(fname*"/"*"dnep1.csv", dnep1)
    CSV.write(fname*"/"*"dnu.csv", dnu)

    return dncp
end


"""
    write_sinfo(s::sets, fname::String)

Write info file in a csv file.
"""
function write_sinfo(s::sets, fname::String)
    d = DataFrame(
      "n_loc"=>[length(s.L)], 
      "n_rtft"=>[length(s.Kr)], 
      "n_new"=>[length(s.Kn)],
      "n_fu"=>[length(s.Fu)],
      "n_p"=>[length(s.P)],
      "n_p2"=>[length(s.P2)],
    )
    CSV.write(fname*"/"*"s_info.csv", d)
end

"""
    write_switches(m::JuMP.Model, p::params, s::sets, fname::String)

Write the discrete variables.
"""
function write_switches(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)
    dyr = DataFrame("yr"=>yr)
    for l in s.L
        for k in s.Kr
            yrv = value.(m[:y_r][:, :, l, k])
            yrv = reshape(yrv', length(yrv))
            dyr[:,"k_$(k)_l_$(l)"] = yrv
        end
    end
    dyn = DataFrame("yr"=>yr)
    for l in s.L
        for k in s.Kn
            yn = value.(m[:y_n][:, :, l, k])
            yn = reshape(yn', length(yn))
            dyn[:,"k_$(k)_l_$(l)"] = yn
        end
    end
    CSV.write(fname*"/"*"dyr.csv", dyr)
    CSV.write(fname*"/"*"dyn.csv", dyn)
    
    d = DataFrame(
      "n_loc"=>[length(s.L)], 
      "n_rtft"=>[length(s.Kr)], 
      "n_new"=>[length(s.Kn)],
      "n_fu"=>[length(s.Fu)],
      "n_p"=>[length(s.P)],
      "n_p2"=>[length(s.P2)]
    )

    CSV.write(fname*"/"*"lrn_info.csv", d)

    # y_o
    dyo = DataFrame("yr"=>yr)
    for l in s.L
        yo = value.(m[:y_o][:, :, l])
        yo = reshape(yo', length(yo))
        dyo[:,"l_$(l)"] = yo
    end
    print(dyo)

    # y_e
    dye = DataFrame("yr"=>yr)
    for l in s.L
        ye = value.(m[:y_e][:, :, l])
        ye = reshape(ye', length(ye))
        dye[:,"l_$(l)"] = ye
    end

    CSV.write(fname*"/"*"dyo.csv", dyo)
    CSV.write(fname*"/"*"dye.csv", dye)

end


"""
    elec_df(m::JuMP.Model, p::params, s::sets, fname::String)

Write electricity consumption numbers (aggregated).
"""
function elec_df(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)
    
    ou = value.(m[:o_u][:, :, 1])
    nu = value.(m[:n_u][:, :, 1])

    for l in s.L
        if l == 1
            continue
        end
        ou += value.(m[:o_u][:, :, l])
        nu += value.(m[:n_u][:, :, l])
    end

    ou = Vector(reshape(ou', length(ou)))
    nu = reshape(nu', length(nu))
   

    df = DataFrame("ou"=>ou, "nu"=>nu,)
    CSV.write(fname*"/"*"u.csv", df)
    

    dou = DataFrame("yr"=>yr)
    dnu = DataFrame("yr"=>yr)
    
    for l in s.L
        ou= value.(m[:o_u][:, :, l])
        ou = reshape(ou', length(ou))
        dou[:,"l_$(l)"] = ou

        nu = value.(m[:n_u][:, :, l])
        nu = reshape(nu', length(nu))
        dnu[:,"l_$(l)"] = nu
    end

    CSV.write(fname*"/"*"ou_l.csv", dou)
    CSV.write(fname*"/"*"nu_l.csv", dnu)
    

end


"""
    n_loan_df(m::JuMP.Model, p::params, s::sets, fname::String)

Write loan balance for new plants.
"""
function n_loan_df(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)

    d = DataFrame("yr"=>yr)
    for l in s.L
        v = value.(m[:n_loan][:, :, l])
        v = reshape(v', length(v))
        d[:, "l_$(l)"] = v
    end
    CSV.write(fname*"/"*"dnloan.csv", d)
end

"""
    tret_df(m::JuMP.Model, p::params, s::sets, fname::String)

Write retirement payment amounts.
"""
function tret_df(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)

    d = DataFrame("yr"=>yr)
    for l in s.L
        v = value.(m[:t_ret_cost][:, :, l])
        v = Array(v)
        v = reshape(v', length(v))
        d[:, "l_$(l)"] = v
    end
    CSV.write(fname*"/"*"tret.csv", d)
end

"""
    e_loan_df(m::JuMP.Model, p::params, s::sets, fname::String)

Write loan balance for expansion.
"""
function e_loan_df(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)

    d = DataFrame("yr"=>yr)

    for l in s.L
        v = value.(m[:e_loan][:, :,l])
        v = Array(v)
        v = reshape(v', length(v))

        yo = value.(m[:y_o][:, :,l])
        yo = Array(yo)
        yo = reshape(yo', length(yo))
        yo = round.(yo)
        yo = trunc.(Int32, yo)

        d[:, "l_$(l)"] = yo.*v
    end
    CSV.write(fname*"/"*"deloan.csv", d)
end

"""
    r_loan_df(m::JuMP.Model, p::params, s::sets, fname::String)

Write loan balance for retrofit.
"""
function r_loan_df(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)
    d = DataFrame("yr"=>yr)

    for l in s.L
        v = value.(m[:r_loan][:, :,l])
        v = reshape(v', length(v))

        y = value.(m[:y_o][:, :,l])
        y = reshape(y', length(y))
        y = trunc.(Int32, y)
        d[:, "l_$(l)"] = y.*v
    end
    CSV.write(fname*"/"*"drloan.csv", d)
end

"""
    write_fuel_results(
        m::JuMP.Model,
        p::params,
        s::sets,
        ns::Vector{String},
        fname::String
    )

Write fuel consumption results. `ns` is a vector that contains the names of the
fuels.
"""
function write_fuel_results(
    m::JuMP.Model, 
    p::params, 
    s::sets, 
    ns::Vector{String}, 
    fname::String
)
    yr = generate_yr_range(p)
    # by period, year, location, fuel
    #
    # size of this vector is (nperiods)
    yo = Array(value.(m[:y_o][:, :, 1]))
    yo = round.(yo)
    yo = trunc.(Int32, yo)

    #@variable(m, r_ehf_d_[i=P, j=Y, l=L, k=Kr, f=Fu]) # 3
    # (nperiods) * (kr, fu)
    rehfd = Array(value.(m[:r_ehf_d_][:, :, 1, :, :])).*yo
    #@variable(m, n_ehf_d_[i=P, j=Y, l=L, k=Kn, f=Fu]) # 3
    nehfd = Array(value.(m[:n_ehf_d_][:, :, 1, :, :]))
    
    # aggregate them by location
    for l in s.L
        if l == 1
            continue
        end
        yo = Array(value.(m[:y_o][:, 1, 1]))
        yo = round.(yo)
        yo = trunc.(Int32, yo)
        rehfd += Array(value.(m[:r_ehf_d_][:, :, l, :, :])).*yo
        nehfd += Array(value.(m[:n_ehf_d_][:, :, l, :, :]))
    end


    drfg = DataFrame()
    # by retrofit 
    for k in s.Kr
        # years by fuel
        drehf = DataFrame("yr"=>yr)
        for f in s.Fu
            r = rehfd[:, :, k, f]
            r = reshape(r', length(r))
            drehf[!, Symbol(ns[f])] = r
        end
        CSV.write(fname*"/"*"drehf_$(k).csv", drehf)
        
        # stack the 2 -> end columns
        d = stack(drehf, 2:size(drehf)[2])
        #CSV.write("dummy.csv", d)
        d[!, 2] = d[!, 2].*"|rf_$(k)"
        CSV.write(fname*"/"*"drehf_stack_$(k).csv", d)
        drfg = vcat(drfg, d)
    end
    CSV.write(fname*"/"*"drehf_glob.csv", drfg)

    dnfg = DataFrame()
    # by new plant
    for k in s.Kn
        # years by fuel
        dnehf = DataFrame("yr"=>yr)
        for f in s.Fu
            r = nehfd[:, :, k, f]
            r = reshape(r', length(r))
            dnehf[!, Symbol(ns[f])] = r
        end
        CSV.write(fname*"/"*"dnehf_$(k).csv", dnehf)

        d = stack(dnehf, 2:size(dnehf)[2])
        d[!, 2] = d[!, 2].*"|nw_$(k)"
        CSV.write(fname*"/"*"dnehf_stack_$(k).csv", d)
        dnfg = vcat(dnfg, d)
    end

    CSV.write(fname*"/"*"dnehf_glob.csv", dnfg)

end


"""
    write_exp_results(m::JuMP.Model, p::params, s::sets, fname::String)

Write the capacity expansion results into a csv file. 
"""
function write_exp_results(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)

    dec = DataFrame("yr"=>yr)
    dec_d_act = DataFrame("yr"=>yr)

    for l in s.L
        yo = value.(m[:y_o][:, :, l])
        yo = reshape(yo', length(yo))
        yo = round.(yo)
        yo = trunc.(Int32, yo)
        ecp = value.(m[:e_c][:, :, l])
        ecp = reshape(ecp', length(ecp))

        dec[:, "l_$(l)"] = ecp
        dec_d_act[:, "l_$(l)"] = ecp.*yo
    end
    ecp = reshape(ecp', length(ecp))

    CSV.write(fname*"/"*"dec.csv", dec)
    CSV.write(fname*"/"*"dec_act.csv", dec_d_act)
end

"""
    write_exp_results(m::JuMP.Model, p::params, s::sets, fname::String)

Write the capacity expansion results into a csv file. 
"""
function write_emission_plant(m::JuMP.Model, p::params, s::sets,fname::String)
    yr = generate_yr_range(p)
    # existing plants
    yo = value.(m[:y_o])
    r_cp_e = value.(m[:r_cp_e])  # process
    r_ep0 = value.(m[:r_ep0])  # ep0
    
    r_fuel_em = r_ep0 .- r_cp_e  # fuel

    r_ep1 = value.(m[:r_ep1ge])
    r_uem = value.(m[:r_u]).*p.GcI*0.29329722222222
    
    r_cap_em = r_ep0 .- r_ep1
    # new plants
    n_cp_e = value.(m[:n_cp_e])
    n_ep0 = value.(m[:n_ep0])

    n_fuel_em = n_ep0 .- n_cp_e

    n_ep1 = value.(m[:n_ep1ge])
    n_uem = value.(m[:n_u]).*p.GcI*0.29329722222222
    
    n_cap_em = n_ep0 .- n_ep1
    #
    drcpe = DataFrame("yr" => yr)
    drfue = DataFrame("yr" => yr)
    drep1 = DataFrame("yr" => yr)
    druem = DataFrame("yr" => yr)
    #
    dncpe = DataFrame("yr" => yr)
    dnfue = DataFrame("yr" => yr)
    dnep1 = DataFrame("yr" => yr)
    dnuem = DataFrame("yr" => yr)
    #
    for l in s.L
        rcpe = r_cp_e[:, :, l].*yo[:, :, l]
        rfue = r_fuel_em[:, :, l].*yo[:, :, l]
        rep1 = r_ep1[:, :, l].*yo[:, :, l]
        ruem = r_uem[:, :, l].*yo[:, :, l]

        rcpe = reshape(rcpe', length(rcpe))
        rfue = reshape(rfue', length(rfue))
        rep1 = reshape(rep1', length(rep1))
        ruem = reshape(ruem', length(ruem))

        drcpe[:, "l_$(l)"] = rcpe
        drfue[:, "l_$(l)"] = rfue
        drep1[:, "l_$(l)"] = rep1
        druem[:, "l_$(l)"] = ruem
        
        #
        ncpe = n_cp_e[:, :, l]
        nfue = n_fuel_em[:, :, l]
        nep1 = n_ep1[:, :, l]
        nuem = n_uem[:, :, l]

        ncpe = reshape(ncpe', length(ncpe))
        nfue = reshape(nfue', length(nfue))
        nep1 = reshape(nep1', length(nep1))
        nuem = reshape(nuem', length(nuem))

        dncpe[:, "l_$(l)"] = ncpe
        dnfue[:, "l_$(l)"] = nfue
        dnep1[:, "l_$(l)"] = nep1
        dnuem[:, "l_$(l)"] = nuem
    end

    CSV.write(fname*"/"*"drcpe.csv", drcpe)
    CSV.write(fname*"/"*"drfue.csv", drfue)
    CSV.write(fname*"/"*"drep1_.csv", drep1)
    CSV.write(fname*"/"*"druem.csv", druem)

    CSV.write(fname*"/"*"dncpe.csv", dncpe)
    CSV.write(fname*"/"*"dnfue.csv", dnfue)
    CSV.write(fname*"/"*"dnep1_.csv", dnep1)
    CSV.write(fname*"/"*"dnuem.csv", dnuem)
    

    co2 = reshape(p.co2_budget', length(p.co2_budget))
    dco0 = DataFrame("co2budget"=>co2)
    CSV.write(fname*"/"*"co2.csv", dco0)
end


"""
    postprocess_d(m::JuMP.Model, p::params, s::sets, fname::String)

Use the `JuMP.Model` and reshape, then write the results in csv format. 
"""
function postprocess_d(m::JuMP.Model, p::params, s::sets, f0::String)
    folder = gen_folder()
    @info "output folder : $(folder)"
    mkdir(folder)

    dr = write_rcp(m, p, s, folder)
    dn = write_ncp(m, p, s, folder)
    write_switches(m, p, s, folder)
    write_demand(m, p, s, folder)
    em_df(m, p, s, folder)
    elec_df(m, p, s, folder)
    n_loan_df(m, p, s, folder)
    r_loan_df(m, p, s, folder)
    e_loan_df(m, p, s, folder)
    tret_df(m, p, s, folder)
    write_sinfo(s, folder)
    
    f_row = 1 + p.n_fu
    nfuels = XLSX.readdata(f0, "fuel_names", "A2:A$(f_row)")
    nfuels = vec(nfuels)
    nfuels = convert(Vector{String}, nfuels)

    write_fuel_results(m, p, s , nfuels, folder)
    write_exp_results(m, p, s, folder)
    write_emission_plant(m, p, s, folder)
end

