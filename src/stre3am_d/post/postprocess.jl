# Copyright (C) 2024, UChicago Argonne, LLC
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

# written by David Thierry @dthierry 2024
# postprocess.jl
# notes: this creates the output of a model run.
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
    
    ou = zeros(length(s.P)*length(s.P2))
    nu = zeros(length(s.P)*length(s.P2))
    for i in s.P
        for j in s.P2
            row = j + length(s.P2) * (i-1)
            ou[row] = sum(sum(value.(m[:o_u][i, j, l, n]) 
                          for n in s.Nd if p.nd_en_fltr[n]).*p.GcI[i, j, l]*0.29329722222222 for l in s.L)
            nu[row] = sum(sum(value.(m[:n_u][i, j, l, n]) 
                          for n in s.Nd if p.nd_en_fltr[n]).*p.GcI[i, j, l]*0.29329722222222 for l in s.L)
        end
    end


    oep1 = Vector(reshape(oep1', length(oep1)))
    nep1 = reshape(nep1', length(nep1))
    #ou = Vector(reshape(ou', length(ou)))
    #nu = reshape(nu', length(nu))
   
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
    kn = p.key_node
    
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

    rcpd = value.(m[:r_cp_d_][:, :, 1, :, kn])

    for l in s.L
        if l == 1
            continue
        end
        rcpd += value.(m[:r_cp_d_][:, :, 1, :, kn])
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
    kn = p.key_node

    #dyr = DataFrame("yr"=>yr)
    drcp_d = DataFrame("yr"=>yr)
    drcp_d_act = DataFrame("yr"=>yr)
    
    rcp = zeros(length(s.P)*length(s.P2))
    rcp_act = zeros(length(s.P)*length(s.P2))

    yo = value.(m[:y_o])
    yo = Array(yo)
    yo = round.(yo)
    yo = trunc.(Int32, yo)
    for l in s.L
        for k in s.Kr
            if p.r_filter[l, k]
                t = 1
                for i in s.P
                    for j in s.P2
                        rcp[t] = value(m[:r_cp_d_][i, j, l, k, kn])
                        rcp_act[t] = rcp[t]*yo[i, j, l] 
                        t += 1
                    end
                end
                drcp_d[:, "k_$(k)_l_$(l)"] = rcp
                drcp_d_act[:, "k_$(k)_l_$(l)"] = rcp_act
                rcp .= 0.0
                rcp_act .= 0.0
            else
                drcp_d[:, "k_$(k)_l_$(l)"] = rcp
                drcp_d_act[:, "k_$(k)_l_$(l)"] = rcp_act
            end
        end
    end
    #
    CSV.write(fname*"/"*"drcp_d.csv", drcp_d)
    CSV.write(fname*"/"*"drcp_d_act.csv", drcp_d_act)
    
    drcp = DataFrame("yr"=>yr)
    drep1 = DataFrame("yr"=>yr)
    dru = DataFrame("yr"=>yr)

    for k in s.Kr
        # accumulated by tech
        rcp_acc = zeros(length(s.P)*length(s.P2))
        rep1_acc = zeros(length(s.P)*length(s.P2))
        ru_acc = zeros(length(s.P)*length(s.P2))
        for l in s.L
            if p.r_filter[l, k]
                for i in s.P 
                    for j in s.P2
                        row = j + length(s.P2) * (i-1)
                        yo = value(m[:y_o][i, j, l])
                        rcp_acc[row] += value(m[:r_cp_d_][i, j, l, k, kn]) * yo
                        rep1_acc[row] += value(m[:r_ep1ge_d_][i, j, l, k]) * yo
                        ru_acc[row] += sum(value(m[:r_u_d_][i, j, l, k, n])
                                           for n in s.Nd if p.nd_en_fltr[n]) * yo
                    end
                end
            #else
            #    continue
            end
        end
        drcp[:, "k_$(k)"] = rcp_acc
        drep1[:, "k_$(k)"] = rep1_acc
        dru[:, "k_$(k)"] = ru_acc
    end

    CSV.write(fname*"/"*"drcp.csv", drcp)
    CSV.write(fname*"/"*"drep1.csv", drep1)
    CSV.write(fname*"/"*"dru.csv", dru)

    return
end

"""
    write_ncp(m::JuMP.Model, p::params, s::sets, fname::String)

Write new capacity, emission and electricity consumption.
"""
function write_ncp(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)
    kn = p.key_node

    dncp_d = DataFrame("yr"=>yr)
    ncp = zeros(length(s.P)*length(s.P2))
    for l in s.L
        for k in s.Kn
            if p.n_filter[l, k]
                t = 1
                for i in s.P
                    for j in s.P2
                        ncp[t] = value(m[:n_cp_d_][i, j, l, k, kn])
                        t += 1
                    end
                end
                dncp_d[:, "k_$(k)_l_$(l)"] = ncp
                ncp .= 0.0
            else
                dncp_d[:, "k_$(k)_l_$(l)"] = ncp
            end
        end
    end
    CSV.write(fname*"/"*"dncp_d.csv", dncp_d)
    
    dncp = DataFrame("yr"=>yr)
    dnep1 = DataFrame("yr"=>yr)
    dnu = DataFrame("yr"=>yr)
    # accumulated by technology
    for k in s.Kn
        ncp_acc = zeros(length(s.P)*length(s.P2))
        nep1_acc = zeros(length(s.P)*length(s.P2))
        nu_acc = zeros(length(s.P)*length(s.P2))
        for l in s.L
            if p.n_filter[l, k]
                for i in s.P
                    for j in s.P2
                        row = j + length(s.P2) * (i-1)
                        ncp_acc[row] += value(m[:n_cp_d_][i, j, l, k, kn])
                        nep1_acc[row] += value(m[:n_ep1ge_d_][i, j, l, k])
                        nu_acc[row] += sum(value(m[:n_u_d_][i, j, l, k, n]) for n in s.Nd if p.nd_en_fltr[n])
                    end
                end
            #else
            #    continue
            end
            dncp[:, "k_$(k)"] = ncp_acc
            dnep1[:, "k_$(k)"] = nep1_acc
            dnu[:, "k_$(k)"] = nu_acc
            # ncp_acc .= 0.0
            # nep1_acc .= 0.0
            # nu_acc .= 0.0
        end
    end
    CSV.write(fname*"/"*"dncp.csv", dncp)
    CSV.write(fname*"/"*"dnep1.csv", dnep1)
    CSV.write(fname*"/"*"dnu.csv", dnu)

    return 
end

function compute_utilization_rates(m::JuMP.Model, p::params, s::sets, 
        fname::String)
    yr = generate_yr_range(p)
    kn = p.key_node

    # active capacity
    dracf = DataFrame("yr"=>yr)
    dnacf = DataFrame("yr"=>yr)
    # base (key) capacity
    #drcb = DataFrame("yr"=>yr)
    
    yo = value.(m[:y_o])
    yo = Array(yo)
    yo = round.(yo)
    yo = trunc.(Int32, yo)
    # active capacity factor
    acf = zeros(length(s.P)*length(s.P2))
    # by node
    for n in s.Nd
        for l in s.L
            acf .= 0.0
            for j in s.P2
                for i in s.P
                    row = length(s.P2)*(i-1) + j
                    cpb = value(m[:cpb][i, j, l]) 
                    if cpb > 1e-08
                        acf[row] = value(m[:r_cp][i, j, l, n])*yo[i, j, l]/cpb
                    end
                end
            end
            dracf[:, "$(l)_$(n)"] = acf
        end
    end

    # new by node
    for n in s.Nd
        for l in s.L
            acf .= 0.0
            for j in s.P2
                for i in s.P
                    row = length(s.P2)*(i-1) + j
                    n_c0 = value(m[:n_c0][i, l]) 
                    if n_c0 > 1e-08
                        acf[row] = value(m[:n_cp][i, j, l, n])/n_c0
                    end
                end
            end
            dnacf[:, "$(l)_$(n)"] = acf
        end
    end

    CSV.write(fname*"/"*"dracf.csv", dracf)
    CSV.write(fname*"/"*"dnacf.csv", dnacf)

end



"""
    write_sinfo(s::sets, fname::String)

Write info file in a csv file.
"""
function write_sinfo(s::sets, p::params, fname::String)
    d = DataFrame(
      "n_loc"=>[length(s.L)], 
      "n_rtft"=>[length(s.Kr)], 
      "n_new"=>[length(s.Kn)],
      "Fu_r"=>[length(s.Fu_r)],
      "Fu_n"=>[length(s.Fu_n)],
      "n_p"=>[length(s.P)],
      "n_p2"=>[length(s.P2)],
      "sf_cap"=>[p.sf_cap],
      "sf_cash"=>[p.sf_cash],
      "sf_heat"=>[p.sf_heat],
      "sf_elec"=>[p.sf_elec],
      "sf_em"=>[p.sf_em],
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
    yrv = zeros(length(s.P)*length(s.P2))
    for l in s.L
        for k in s.Kr
            if p.r_filter[l, k]
                t = 1
                for i in s.P
                    for j in s.P2
                        yrv[t] = value(m[:y_r][i, j, l, k])
                        t += 1
                    end
                end
            end
            dyr[:, "k_$(k)_l_$(l)"] = yrv
            yrv .= 0.0
        end
    end
    dyn = DataFrame("yr"=>yr)
    ynv = zeros(length(s.P)*length(s.P2))
    for l in s.L
        for k in s.Kn
            if p.n_filter[l, k]
                t = 1
                for i in s.P
                    for j in s.P2
                        ynv[t] = value(m[:y_n][i, j, l, k])
                        t += 1
                    end
                end
            end
            #println("k_$(k)_l_$(l)")
            dyn[:, "k_$(k)_l_$(l)"] = ynv
            ynv .= 0.0
        end
    end
    CSV.write(fname*"/"*"dyr.csv", dyr)
    CSV.write(fname*"/"*"dyn.csv", dyn)
    
    d = DataFrame(
                  "n_loc" => [length(s.L)], 
                  "n_rtft" => [length(s.Kr)], 
                  "n_new" => [length(s.Kn)],
                  "n_p" => [length(s.P)],
                  "n_p2" => [length(s.P2)]
                 )

    CSV.write(fname*"/"*"lrn_info.csv", d)

    # y_o
    dyo = DataFrame("yr"=>yr)
    for l in s.L
        yo = value.(m[:y_o][:, :, l])
        yo = reshape(yo', length(yo))
        dyo[:,"l_$(l)"] = yo
    end
    # print(dyo)

    # y_e
    dye = DataFrame("yr"=>yr)
    for l in s.L
        ye = value.(m[:y_e][:, :, l])
        ye = reshape(ye', length(ye))
        dye[:,"l_$(l)"] = ye
    end

    CSV.write(fname*"/"*"dyo.csv", dyo)
    CSV.write(fname*"/"*"dye.csv", dye)

    return
end


"""
    elec_df(m::JuMP.Model, p::params, s::sets, fname::String)

Write electricity consumption numbers (aggregated).
"""
function elec_df(m::JuMP.Model, p::params, s::sets, fname::String)
    yr = generate_yr_range(p)
    
    ou = zeros(length(s.P)*length(s.P2))
    nu = zeros(length(s.P)*length(s.P2))

    for i in s.P
        for j in s.P2
            row = j + length(s.P2) * (i-1)
            ou[row] = sum(sum(value(m[:o_u][i, j, l, n]) for n in s.Nd if p.nd_en_fltr[n])
                     for l in s.L)
            nu[row] = sum(sum(value(m[:n_u][i, j, l, n]) for n in s.Nd if p.nd_en_fltr[n])
                     for l in s.L)
        end
    end


   

    df = DataFrame("ou"=>ou, "nu"=>nu,)
    CSV.write(fname*"/"*"u.csv", df)
    

    dou = DataFrame("yr"=>yr)
    dnu = DataFrame("yr"=>yr)
    
    for l in s.L
        ou = zeros(length(s.P)*length(s.P2))
        nu = zeros(length(s.P)*length(s.P2))
        for i in s.P
            for j in s.P2
                row = j + length(s.P2) * (i-1)
                ou[row] = sum(value(m[:o_u][i, j, l, n]) for n in s.Nd if p.nd_en_fltr[n])
                nu[row] = sum(value(m[:n_u][i, j, l, n]) for n in s.Nd if p.nd_en_fltr[n])
            end
        end
        dou[:,"l_$(l)"] = ou
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
    yo = Array(value.(m[:y_o]))
    yo = round.(yo)
    yo = trunc.(Int32, yo)
    
    #@variable(m, r_ehf_d_[i=P, j=Y, l=L, k=Kr, f=Fu]) # 3
    # (nperiods) * (kr, fu)
    #rehfd = Array(value.(m[:r_ehf_d_][:, :, 1, :, :])).*yo
    #@variable(m, n_ehf_d_[i=P, j=Y, l=L, k=Kn, f=Fu]) # 3
    #nehfd = Array(value.(m[:n_ehf_d_][:, :, 1, :, :]))
    #
    drehf = DataFrame("yr" => yr)
    for f in s.Fu
        drehf[!, Symbol(ns[f])] .= 0.0
    end
    # stacked
    drehf_stack = DataFrame()
    # aggregate them by location save them by tech, with columns = fuel
    for k in s.Kr
        drehfd = DataFrame("yr"=>yr)
        for f in s.Fu
            rehfd = zeros(length(s.P)*length(s.P2))
            for l in s.L
                # new dataframe for k
                if p.r_filter[l, k]
                    t = 1
                    for i in s.P
                        for j in s.P2
                            rehfd[t] += value(m[:r_ehf_d_][i,j,l,k,f])*yo[i,j,l]
                            t += 1
                        end
                    end
                else
                    continue
                end
            end
            drehfd[!, Symbol(ns[f])] = rehfd
        end
        CSV.write(fname*"/"*"drehf_$(k).csv", drehfd)
        for f in s.Fu
            drehf[!, Symbol(ns[f])] .+= drehfd[!, Symbol(ns[f])]
        end
        # stack the 2 -> end columns
        d = stack(drehfd, 2:size(drehf)[2])
        d[!, 2] = d[!, 2].*"|rf_$(k)"
        #CSV.write(fname*"/"*"drehf_stack_$(k).csv", d)
        drehf_stack = vcat(drehf_stack, d)
    end
    CSV.write(fname*"/"*"drehf_overall.csv", drehf)
    CSV.write(fname*"/"*"drehf_stack.csv", drehf_stack)

    # new plants
    dnehf = DataFrame("yr" => yr)
    for f in s.Fu
        dnehf[!, Symbol(ns[f])] .= 0.0
    end
    # stacked
    dnehf_stack = DataFrame()
    # aggregate them by location save them by tech, with columns = fuel
    for k in s.Kn
        dnehfd = DataFrame("yr"=>yr)
        for f in s.Fu
            nehfd = zeros(length(s.P)*length(s.P2))
            for l in s.L
                # new dataframe for k
                if p.n_filter[l, k]
                    t = 1
                    for i in s.P
                        for j in s.P2
                            nehfd[t] += value(m[:n_ehf_d_][i,j,l,k,f])
                            t += 1
                        end
                    end
                else
                    continue # ToDo: review this
                end
            end
            dnehfd[!, Symbol(ns[f])] = nehfd
        end
        CSV.write(fname*"/"*"dnehf_$(k).csv", dnehfd)
        for f in s.Fu
            dnehf[!, Symbol(ns[f])] .+= dnehfd[!, Symbol(ns[f])]
        end
        # stack the 2 -> end columns
        d = stack(dnehfd, 2:size(dnehf)[2])
        d[!, 2] = d[!, 2].*"|nf_$(k)"
        dnehf_stack = vcat(dnehf_stack, d)
    end
    CSV.write(fname*"/"*"dnehf_overall.csv", dnehf)
    CSV.write(fname*"/"*"dnehf_stack.csv", dnehf_stack)

    return
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
    r_ep0 = value.(m[:r_ep0])  # process scope 0
    r_cpe = zeros(p.n_periods, p.n_subperiods, p.n_location)
    for i in s.P
        for j in s.P2
            for l in s.L
                r_cpe[i, j, l] = sum(value(m[:r_cpe][i, j, l, n]) 
                                     for n in s.Nd if p.nd_em_fltr[n]
                                    )
            end
        end
    end
    r_fuel_em = r_ep0 .- r_cpe  # fuel

    r_ep1 = value.(m[:r_ep1ge])
    r_uem = zeros(length(s.P)*length(s.P2), length(s.L))
    for i in s.P
        for j in s.P2
            row = j + length(s.P2)*(i-1)
            for l in s.L
                r_uem[row, l] = sum((value(m[:r_u][i, j, l, n])*
                                     p.GcI[i, j, l]*0.29329722222222*
                                     value(yo[i, j, l]) 
                                     for n in s.Nd if p.nd_en_fltr[n]))
            end
        end
    end
    
    r_cap_em = r_ep0 .- r_ep1
    # new plants
    n_ep0 = value.(m[:n_ep0])
    n_cpe = zeros(p.n_periods, p.n_subperiods, p.n_location)
    for i in s.P
        for j in s.P2
            for l in s.L
                n_cpe[i, j, l] = sum(value(m[:n_cpe][i, j, l, n]) 
                                     for n in s.Nd if p.nd_em_fltr[n]
                                    )
            end
        end
    end

    n_fuel_em = n_ep0 .- n_cpe

    n_ep1 = value.(m[:n_ep1ge])
    #n_uem = value.(m[:n_u]).*p.GcI*0.29329722222222
    n_uem = zeros(length(s.P)*length(s.P2), length(s.L))
    for i in s.P
        for j in s.P2
            row = j + length(s.P2)*(i-1)
            for l in s.L
                n_uem[row, l] = sum((value(m[:r_u][i, j, l, n])*
                                     p.GcI[i, j, l]*
                                     0.29329722222222) for n in s.Nd 
                                    if p.nd_en_fltr[n])
            end
        end
    end
    
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
    ndemfltr = p.nd_em_fltr
    for l in s.L
        rcpe = r_cpe[:, :, l].*yo[:, :, l]
        rfue = r_fuel_em[:, :, l].*yo[:, :, l]
        rep1 = r_ep1[:, :, l].*yo[:, :, l]
        #ruem = r_uem[:, l].*yo[:, :, l]

        rcpe = reshape(rcpe', length(rcpe))
        rfue = reshape(rfue', length(rfue))
        rep1 = reshape(rep1', length(rep1))
        #ruem = reshape(ruem', length(ruem))

        drcpe[:, "l_$(l)"] = rcpe
        drfue[:, "l_$(l)"] = rfue
        drep1[:, "l_$(l)"] = rep1
        druem[:, "l_$(l)"] = r_uem[:, l]
        
        #
        ncpe = n_cpe[:, :, l]
        nfue = n_fuel_em[:, :, l]
        nep1 = n_ep1[:, :, l]
        #nuem = n_uem[:, :, l]

        ncpe = reshape(ncpe', length(ncpe))
        nfue = reshape(nfue', length(nfue))
        nep1 = reshape(nep1', length(nep1))
        #nuem = reshape(nuem', length(nuem))

        dncpe[:, "l_$(l)"] = ncpe
        dnfue[:, "l_$(l)"] = nfue
        dnep1[:, "l_$(l)"] = nep1
        dnuem[:, "l_$(l)"] = n_uem[:, l]
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


function write_tech_labels(m, p, s, xlsxf, folder)
    rf = XLSX.readdata(xlsxf, "RF_label", "A2:A$(1+p.n_rtft)")
    nw = XLSX.readdata(xlsxf, "NW_label", "A2:A$(1+p.n_new)")
    dr = DataFrame("RetroLabel"=>rf[:])
    dn = DataFrame("NewLabel"=>nw[:])
    CSV.write(folder*"/"*"retro_labels.csv", dr)
    CSV.write(folder*"/"*"new_labels.csv", dn)
end

function write_filters(p, s, folder)
    # r_filter::Array{Bool, 2}
    dr = DataFrame(["$(k)" => p.r_filter[:, k] for k in 1:p.n_rtft])
    # n_filter::Array{Bool, 2}
    dn = DataFrame(["$(k)" => p.n_filter[:, k] for k in 1:p.n_new])
    CSV.write(folder*"/"*"retro_filters.csv", dr)
    CSV.write(folder*"/"*"new_filters.csv", dn)
end


#####

function write_fuel_res_v1(m, p, s, fname)
    yr = generate_yr_range(p)
    Fu_r = s.Fu_r 
    Fu_n = s.Fu_n
    yo = value.(m[:y_o])
    r_ff = []
    n_ff = []
    
    for l in s.L
        push!(r_ff, zeros(p.n_periods, p.n_subperiods, length(Fu_r[l])))
        push!(n_ff, zeros(p.n_periods, p.n_subperiods, length(Fu_n[l])))
    end
    #
    for l in s.L
        rf = r_ff[l]
        for i in s.P 
            for j in s.P2 
                for f in Fu_r[l]
                    rf[i, j, f] = sum(value(m[:r_ehf][i, j, l, f, n]) for n in s.Nd if p.nd_en_fltr[n])*yo[i,j,l]
                end
                for f in Fu_n[l]
                    rn = n_ff[l]
                    rn[i, j, f] = sum(value(m[:n_ehf][i, j, l, f, n])
                                      for n in s.Nd if p.nd_en_fltr[n])
                end
            end 
        end 
    end
    
    r_df = [DataFrame("yr"=>yr) for l in s.L]
    n_df = [DataFrame("yr"=>yr) for l in s.L]

    for l in s.L
        for f in Fu_r[l]
            rf = r_ff[l][:, :, f]
            rf = reshape(rf', length(rf))
            r_df[l][:, "f_$(f)"] = rf
        end
        for f in Fu_n[l]
            nf = n_ff[l][:, :, f]
            nf = reshape(nf', length(nf))
            n_df[l][:, "f_$(f)"] = nf
        end

        CSV.write(fname*"/"*"dr_f_$(l).csv", r_df[l])
        CSV.write(fname*"/"*"dn_f_$(l).csv", n_df[l])
        
        #CSV.write(fname*"/"*"ou_l.csv", dou)
    end

end

function write_heat_res_v1(m, p, s, fname)
    yr = generate_yr_range(p)
    yo = value.(m[:y_o])
    
    r_h = zeros(p.n_periods, p.n_subperiods, p.n_location)
    n_h = zeros(p.n_periods, p.n_subperiods, p.n_location)
    #
    for i in s.P 
        for j in s.P2 
            for l in s.L
                r_h[i, j, l] = sum(value(m[:r_eh][i, j, l, n]) for n in s.Nd if p.nd_en_fltr[n])*yo[i,j,l]
                n_h[i, j, l] = sum(value(m[:n_eh][i, j, l, n]) for n in s.Nd if p.nd_en_fltr[n])
            end 
        end 
    end
    
    r_df = DataFrame("yr"=>yr)
    n_df = DataFrame("yr"=>yr)

    for l in s.L
        rf = r_h[:, :, l]
        rf = reshape(rf', length(rf))
        r_df[:, "l_$(l)"] = rf
        nf = n_h[:, :, l]
        nf = reshape(nf', length(nf))
        n_df[:, "l_$(l)"] = nf

    end
    CSV.write(fname*"/"*"drh.csv", r_df)
    CSV.write(fname*"/"*"dnh.csv", n_df)

end


#####
#
#
#
"""
    postprocess_d(m::JuMP.Model, p::params, s::sets, fname::String)

Use the `JuMP.Model` and reshape, then write the results in csv format. 
"""
function postprocess_d(m::JuMP.Model, p::params, s::sets, f0::String)
    folder = gen_folder()
    @info "output folder : $(folder)"
    mkdir(folder)
    
    open("most_recent_run.txt", "w") do file
        write(file, folder)
    end

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
    write_sinfo(s, p, folder)
    
    #f_row = 1 + p.n_fu
    #nfuels = XLSX.readdata(f0, "fuel_names", "A2:A$(f_row)")
    #$nfuels = vec(nfuels)
    #nfuels = convert(Vector{String}, nfuels)

    #write_fuel_results(m, p, s , nfuels, folder)
    write_exp_results(m, p, s, folder)
    write_emission_plant(m, p, s, folder)
    write_tech_labels(m, p, s, f0, folder)
    write_filters(p, s, folder)
    
    write_fuel_res_v1(m, p, s, folder)
    write_heat_res_v1(m, p, s, folder)

    compute_utilization_rates(m, p, s, folder)
    return folder
end
