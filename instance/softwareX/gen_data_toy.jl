
using DataFrames
using CSV
using Printf
using LinearAlgebra
using stre3am


# 80 ###########################################################################
fac_f = "./samples/sample_cs_n=10.csv"
fuel_f = "./samples/sample_cs_ff_n=10.csv"
em_f = "./samples/sample_cs_em_f_n=10.csv"
ener_c_f  = "./samples/en_cost_usdmmbtu.csv"
elec_c_f = "./samples/avg_state_ecost2020.csv"


# 80 ###########################################################################
#
yr_subperiod = 5  # years/subperiod

n_subperiods = 4  # number of subperiods
n_periods = 2

yr_period = yr_subperiod * n_subperiods  # years/period

n_loc = 10 # 

n_rtft = 5
n_new = 5
loan_period = 30

# 80 ###########################################################################
#

time_horizon = (n_periods * n_subperiods - 1 )* yr_subperiod
@printf "time_horizon %f\n" time_horizon
#
# 80 ###########################################################################
year0 = 2020  # for indexing purposes

#
# 80 ###########################################################################
# we should get better scaling?
sf_cap = 1e-03  # kton/ton : scale factor/c
sf_cash = 1e-00  # MUSD/MUSD
sf_heat = 1e-03  # kMMBTU/MMBTU
sf_elec = 1e-03  # kMMBTU/MMBTU
sf_em = 1e-03  # ktonne/tonne
#
#
# 10% rate
interest = 0.1
# adjustement factor for interest
# interest can only be a single value unfortunately
annumPayF = interest*((1+interest)^loan_period)/((1+interest)^loan_period - 1)

# 10 MUSD/Ton/YR
loan_base_value = 8.0 * (sf_cash/sf_cap)
fonm_base_value = loan_base_value * 2/100
vonm_base_value = 3*1e-6 * (sf_cash/sf_cap)

d_fac = DataFrame(CSV.File(fac_f))
# yearly capacity
d_fac[:, "CapTon"] = d_fac[:, "CapTon"].*sf_cap  # scaled
# heat intensity
d_fac[:, "HiMBTUTon"] = d_fac[:, "HiMBTUTon"].*(sf_heat/sf_cap)  # scaled
# elec intensity
d_fac[:, "EiMBTUTon"] = d_fac[:, "EiMBTUTon"].*(sf_elec/sf_cap) # scaled
# carbon intensity
d_fac[:, "pETonTon"] = d_fac[:, "pETonTon"].*(sf_em/sf_cap)

# fuel fractions
d_fuel = DataFrame(CSV.File(fuel_f))
d_fuel = select(d_fuel, Not(:f_3))
rename!(d_fuel, ["c1", "FacID", "bituminouscoal", "distillatefueloilno.2", "naturalgas"])

d_em = DataFrame(CSV.File(em_f))

# tonCO2/mmbtu (originally kgCO2/mmbtu)
# d_em[:, "CO2 Factor"] .*= (1/1000)
# ktonCO2/mmtu
d_em[:, "CO2 Factor"] = d_em[:, "CO2 Factor"].*(1E-03)  # kg->ton/mmbtu
d_em[:, "CO2 Factor"] = d_em[:, "CO2 Factor"].*(sf_em/sf_heat) # ktonne/kmmbtu

# create a new dataframe with the hydrogen row
d_em_new = DataFrame()
d_em_new[:, Symbol("Fuel Type")] = d_em[:, 2]
for i in names(d_em[:, 3:end])
    col = d_em[:, i]
    if eltype(col) == String15
        col = replace.(col, "," => "")
        col = replace.(col, " " => "")
        col = parse.(Float64, col)
    end
    d_em_new[:, Symbol(i)] = col
end
d_ener = DataFrame(CSV.File(ener_c_f))

# 80 ###########################################################################
d1 = permutedims(d_fuel[:, 3:end])
d1[:, :fuel_id] = 1:size(d1)[1]
d2 = select(d1, :fuel_id, Not(:fuel_id))

# rows: nz, fuel_frac
# number of fuels
dnfu = zeros(Int64, size(d2)[2]-1)
# fuel fractions
dff = DataFrame(zeros(nrow(d2), ncol(d2)-1), :auto)
# emission intensity 
dem = DataFrame(zeros(nrow(d2), ncol(d2)-1), :auto)
# fuel id
dfid = DataFrame(zeros(Int64, nrow(d2), ncol(d2)-1), :auto)
# fuel names
dnam = DataFrame(["x$(col)"=>["" for row in 1:nrow(d2)] for col in 1:ncol(d2)-1])
d2names = names(d2)

fnames = names(d_fuel)
# remove first two names
popfirst!(fnames)
popfirst!(fnames)

for i in 2:ncol(d2)
    d3 = filter(Symbol(d2names[i]) => >(0), d2)
    nr = nrow(d3)
    dnfu[i-1] = nr
    for r in 1:nr
        dff[r, i-1] = select(d3, Symbol(d2names[i]))[r, 1]
        fuelid = select(d3, :fuel_id)[r, 1]
        dfid[r, i-1] = fuelid
        dem[r, i-1] = d_em_new[fuelid, "CO2 Factor"]
        dnam[r, i-1] = fnames[fuelid]
    end
end

natural_gas_string = "naturalgas"
ng_id = findfirst(x->x==natural_gas_string, fnames)
coal_strings = ["bituminous", "subbituminous"]
coal_ids = [findfirst(==(coal_strings[i]),fnames) for i in 1:length(coal_strings)]

# 80 ###########################################################################
has_ng = Vector{Bool}(undef, n_loc)
has_any_coal = Vector{Int64}(undef, n_loc)

for j in 1:n_loc
    has_ng[j] = ng_id in dfid[1:dnfu[j], j]
    has_any_coal[j] = sum([in(coal_id, dfid[1:dnfu[j], j]) for coal_id in coal_ids])
end

can_switch_coal = Vector{Bool}(undef, n_loc)
for l in 1:n_loc
    nadd_fuel = 1
    if has_any_coal[l] > 0
        can_switch_coal[l] = true
        # if has natural gas
        if !has_ng[l]
            dfid[dnfu[l]+nadd_fuel, l] = ng_id
            dem[dnfu[l]+nadd_fuel, l] = d_em_new[ng_id, "CO2 Factor"]
            dnam[dnfu[l]+nadd_fuel, l] = fnames[ng_id]
            nadd_fuel += 1
        end
        dnfu[l] += nadd_fuel - 1
    end
    if !has_ng[l]
        if !(ng_id in dfid[1:dnfu[l], l])
            dfid[dnfu[l]+1, l] = ng_id
            dem[dnfu[l]+1, l] = d_em_new[ng_id, "CO2 Factor"]
            dnam[dnfu[l]+1, l] = fnames[ng_id]
            dnfu[l] += 1
        end
    end
end

# 80 ###########################################################################
# number of locations
# n_loc -= 1
loc_range = 1:n_loc
# number of fuels
n_rfu = [dnfu[l] for l in 1:n_loc]
n_fstck = 2

# 1: no retrofit
# 2: Efficiency
# 3: Fuel switch
# 5: Full electrification (Pre-calciner & kiln) (also with/out CCS)
# 6: CCS (Post-combustion and direct)

r_loan0 = zeros(n_loc)

# capacity factor
# c0 = LinRange(1, 10, n_loc) # 15
c0 = d_fac[loc_range, "CapTon"] # 15

# 80 ###########################################################################
# Process graph
n_node = 2
n_mat = 5  # 3 ingredients + 2 outputs
n_link = 1

key_node = 2


node_mat = Array{Bool}(undef, n_node, n_mat)
node_mat .= false

node_mat[1, 1] = true
node_mat[1, 2] = true
node_mat[1, 3] = true
#
node_mat[2, 3] = true
node_mat[2, 4] = true
node_mat[2, 5] = true
#

# skip matrix
skip_mb = Array{Bool}(undef, n_node, n_mat)
skip_mb .= false

skip_mb[1, 3] = true
skip_mb[2, 5] = true

#
input_mat = [[1, 2], [3, 4]]
output_mat = [[3], [5]]

# link list
links_list = Vector{Tuple{Int64, Int64, Int64}}(undef, n_link)
links_list[1] = (1, 2, 3)

# node key (out) components
ckey = [3, 5] 
# node energy filters
nd_en_fltr = [true, true]
# node non-fuel em filters
nd_em_fltr = [true, false]

# 80 ###########################################################################
# future demand
demand = ones(n_periods, n_subperiods)
demand_relax_fact = 0.80 # akin to a capacity factor
agg_dem0 = sum(d_fac[loc_range, "CapTon"]) * demand_relax_fact
d_growth = 2/100  # percent
agg_demand = agg_dem0 * (1 + d_growth)^time_horizon


# 80 ###########################################################################
# ratios
r_Kmb = zeros(n_node, n_mat, n_mat, n_rtft)
# node 1
# node, c_in, c_out, rtfts
r_Kmb[1, 1, 3, :] .= -0.1
r_Kmb[1, 2, 3, :] .= -0.5
r_Kmb[1, 3, 3, :] .= 1.0
# node 2
r_Kmb[2, 3, 5, :] .= -0.8  
r_Kmb[2, 4, 5, :] .= -0.2
r_Kmb[2, 5, 5, :] .= 1.0

# electrification requires 75%
r_Kmb[1, 1, 3, 4] = -0.1 * 0.75
r_Kmb[1, 2, 3, 4] = -0.5 * 0.75
r_Kmb[2, 4, 5, 4] = -0.2 * 0.75

# node 1
n_Kmb = zeros(n_node, n_mat, n_mat, n_new)
n_Kmb[1, 1, 3, :] .= -0.1
n_Kmb[1, 2, 3, :] .= -0.5
n_Kmb[1, 3, 3, :] .= 1.0
# node 2
n_Kmb[2, 3, 5, :] .= -0.8
n_Kmb[2, 4, 5, :] .= -0.2
n_Kmb[2, 5, 5, :] .= 1.0

# electrification requires 75%
n_Kmb[1, 1, 3, 4] = -0.1 * 0.75
n_Kmb[1, 2, 3, 4] = -0.5 * 0.75
n_Kmb[2, 4, 5, 4] = -0.2 * 0.75

# 80 ###########################################################################
# expansion capacity
# max expansion unit
#### !!!!!!  #### !!!!!!  #### !!!!!!  #### !!!!!!  #### !!!!!!  
e_cap_slice = 2 # number of slices of initial capacity
# this'd tell you how many times is the dif btw final demand from the initial
e_max_cp_fac = ceil((agg_demand - agg_dem0)/agg_dem0) 

# need the exp cap by node
e_C = ones(n_loc)
e_C[:] = floor.(d_fac[loc_range, "CapTon"]./sf_cap)*sf_cap*e_max_cp_fac/e_cap_slice # 5 capacity factor

# 80 ###########################################################################
relax_ub_fac = 1.1
x_ub = e_cap_slice
e_c_ub = e_C.*x_ub 

e_c_ub .*= relax_ub_fac

e_loanFact = ones(n_loc).*loan_base_value

e_l_ub = e_c_ub.*e_loanFact # 9
e_Ann = ones(n_loc).*annumPayF # ./annuity_scale # 10
# annuity is in terms of usd/year
# thus we need usd/ton * ton/subperiod * subperiod/year = usd/year

e_ann_ub = e_l_ub*annumPayF # 11
e_ladd_ub = e_l_ub # 12
e_loan_ub = e_l_ub .+ 0.0 # 13

e_pay_ub = e_l_ub*annumPayF # 14


# 80 ###########################################################################
r_cpb_ub = e_c_ub .+ c0 # 18
r_cpb_ub .*= relax_ub_fac

r_cp_ub = zeros(n_loc, n_node)
r_cp_ub[:, 1] = r_cpb_ub * maximum(abs.(r_Kmb[2, ckey[1], ckey[2], :]))
r_cp_ub[:, 2] = r_cpb_ub

# 80 ###########################################################################
r_x_out_ub = zeros(n_loc, n_node, n_mat)
# node 1
r_x_out_ub[:, 1, 3] .= r_cp_ub[:, 1]
# node 2
r_x_out_ub[:, 2, 5] .= r_cp_ub[:, 2]

r_x_in_ub = zeros(n_loc, n_node, n_mat)
# node 1
r_x_in_ub[:, 1, 1] .= r_cp_ub[:, 1].*maximum(abs.(r_Kmb[1, 1, ckey[1], :]))
r_x_in_ub[:, 1, 2] .= r_cp_ub[:, 1].*maximum(abs.(r_Kmb[1, 2, ckey[1], :]))
r_x_in_ub[:, 1, 3] .= r_cp_ub[:, 1]
# node 2
r_x_in_ub[:, 2, 3] .= r_cp_ub[:, 2].*maximum(abs.(r_Kmb[2, 3, ckey[2], :]))
r_x_in_ub[:, 2, 4] .= r_cp_ub[:, 2].*maximum(abs.(r_Kmb[2, 4, ckey[2], :]))
r_x_in_ub[:, 2, 5] .= r_cp_ub[:, 2]

r_Kkey_j = ones(n_node, n_rtft)
r_Kkey_j[1, :] = abs.(r_Kmb[2, ckey[1], ckey[2], :])
r_Kkey_j[2, :] .= 1.0 

# 80 
# 80 ###########################################################################
##
# retrofit filter
r_filter = Array{Bool}(undef, n_loc, n_rtft)
r_filter .= true
west_c_states = ["CA", "OR", "WA"]

for l in loc_range
    state = d_fac[l, "State"]
    if state ∈ west_c_states
        r_filter[l, 5] = false
    end
end

#

r_c_C = ones(n_loc, n_rtft) # 16 # these do not change capacity
r_rhs_C = zeros(n_loc, n_rtft) # 17


# 80 ###########################################################################
##
# set of nodes
# set of components
# set of links
#
# node matrix

# 80 
# 80 ###########################################################################
##
# heat intensity (MMBTU/kton)
r_c_H = ones(n_loc, n_rtft, n_node) # 20
for k in 1:n_rtft
    r_c_H[:, k, 1] .= d_fac[loc_range, "HiMBTUTon"]
    r_c_H[:, k, 2] .= d_fac[loc_range, "HiMBTUTon"].*1e-01
end

### ### 2: Efficiency 
r_c_H[:, 2, :] .*= 0.95
### ### 4: Full Electrification
r_c_H[:, 4, :] .*= 0.00 
### ### 5: CCS 120% increase
r_c_H[:, 5, :] .*= 1.2

### ###
r_rhs_H = zeros(n_loc, n_rtft, n_node) # 21

# hi factor 
r_c_Hfac = ones(n_loc, n_rtft)

# electrification factor
r_c_Helec = zeros(n_loc, n_rtft)

# 80 
# 80 ###########################################################################
##
mnrfu = maximum(n_rfu)
# fuel fraction
r_c_F = zeros(mnrfu, n_loc, n_rtft, n_node) # 23

for n in 1:n_node
    for k in 1:n_rtft
        for l in loc_range
            r_c_F[:, l, k, n] = dff[1:mnrfu, l]
        end
    end
end

# recompute fuel fractions
#### #### 3: NG-fuel switch
for n in 1:n_node
    for l in 1:n_loc
        if has_any_coal[l] > 0
            coal_frac = 0.0
            for coal_id in coal_ids
                plnt_coal_id = findfirst(==(coal_id), dfid[1:dnfu[l], l])
                if !isnothing(plnt_coal_id)
                    coal_frac += r_c_F[plnt_coal_id, l, 3, n] 
                    r_c_F[plnt_coal_id, l, 3, n] = 0.0
                end
            end
            # find ng
            plnt_ng_id = findfirst(==(ng_id), dfid[1:dnfu[l], l])
            r_c_F[plnt_ng_id, l, 3, n] += coal_frac
        end
    end
end


# 80 ###########################################################################

###
# scaled!
r_eh_ub = zeros(n_loc, n_node)
for n in 1:n_node
    r_eh_ub[:, n] = (r_x_out_ub[:, n, ckey[n]].*
                     maximum(r_c_H[:,:,n], dims=2).*
                     maximum(r_c_Hfac, dims=2))
end
#
r_rhs_F = zeros(mnrfu, n_loc, n_rtft, n_node) # 24
r_ehf_ub = zeros(mnrfu, n_loc, n_node)

# get the maximum rhs (nloc by 1)
#
for n in 1:n_node
    mrrhsF = maximum(r_rhs_F[:,:,:,n], dims=3)[:, :, 1]
    mrcF = maximum(r_c_F[:,:,:,n], dims=3)[:, :, 1]
    r_ehf_ub[:, :, n] = adjoint(r_eh_ub[:, n]).*mrcF .+ mrrhsF
end
# scaled!

## 80 
# 80 ###########################################################################
##
# electricity intensity mmbtu/kton
r_c_U = ones(n_loc, n_rtft, n_node) # 26
for k in 1:n_rtft
    r_c_U[:, k, 1] .= d_fac[loc_range, "EiMBTUTon"]
    r_c_U[:, k, 2] .= d_fac[loc_range, "EiMBTUTon"].*1e-01
end

### ### 2: Efficiency
r_c_U[:, 2, :] .*= 0.95
# 1.1 joule e / joule fossil
# 3 joule c / joule e
#
# more efficient per unit of product
# 0.75 gj e / ton 

# full e node 1 heat req replace higher value
# 0.5 node 2
# .75 node e_unit / t_thermal
#
#
# 0.5 je/jt 
#
# full elec
# 0.75 je/jt
#

# 4 technologies
# eff
# fuel switch
# 100 elec no ccs
# no elec only ccs

eToHfac = [0.75, 0.5] # e_unit/h_unit

### ### 4: Full Electrification
r_c_U[:, 4, 1] .+= d_fac[loc_range, "HiMBTUTon"].*(sf_elec/sf_heat).*eToHfac[1]
r_c_U[:, 4, 2] .+= d_fac[loc_range, "HiMBTUTon"].*(sf_elec/sf_heat)*1e-01*eToHfac[2]
### ###

# 293.29722222222 kWh/mmbtu

### ### 5: CCS 
# additional electricity requirement of 70.48 kwh/tclinker
r_c_U[:, 5, :] .*= 1.3
### ###

r_rhs_U = zeros(n_loc, n_rtft, n_node) # 27

# five percent
r_c_UonSite = ones(n_periods,
                   n_subperiods,
                   n_loc,
                   n_rtft,
                   n_node).*(5/100)

r_c_Ufac = ones(n_loc, n_rtft)

#r_c_Ufac[:, 2] .= 1.05  # increases
#r_c_Ufac[:, 5] .= 1.05

# scaled!
r_u_ub = zeros(n_loc, n_node)
for n in 1:n_node
    r_u_ub[:, n] = (r_x_out_ub[:, n, ckey[n]].*
                    maximum(r_c_U[:, :, n], dims=2).*
                    maximum(r_c_Ufac, dims=2) + 
                    maximum(r_c_Helec, dims=2).*r_eh_ub[:, n])
end

# process emissions
r_c_cpe = ones(n_loc, n_rtft, n_node) # 29. scaled
for k in 1:n_rtft
    r_c_cpe[:, k, 1] = d_fac[loc_range, "pETonTon"]
    r_c_cpe[:, k, 2] = d_fac[loc_range, "pETonTon"].*1e-2
end  # 0.01

r_rhs_cpe = zeros(n_loc, n_rtft, n_node) # 30
# scaled!
r_cpe_ub = zeros(n_loc, n_node)
for n in 1:n_node
    r_cpe_ub[:, n] = r_cp_ub[:, n].*maximum(r_c_cpe, dims=2)[:, 1, n] 
end
# chain of calc cap (ktonne) -> heat (MMBTU) -> tonneCo2
# fuel emission factor
r_c_Fe = zeros(mnrfu, n_loc, n_rtft, n_node) # 32
for k in 1:n_rtft
    for l in loc_range
        r_c_Fe[:, l, k, :] .= dem[1:mnrfu, l]
    end
end

# in-site elec fuel fraction
#for i in 1:n_rtft
#    r_c_Fgenf[:, :, i] .= d_fuel[loc_range, 2:end]
#end
r_c_Fgenf = r_c_F


# in-site generation heat rate, one mmbtu per mwh
# 1 MWh = 3.412142 MMBTU
r_c_Hr = ones(mnrfu, n_loc, n_rtft, n_node)
#
r_u_ehf_ub = zeros(mnrfu, n_loc, n_node)

for n in 1:n_node
    mrcU = maximum(r_c_U[:, :, n], dims=2)[:, 1]
    mrcUfac = maximum(r_c_Ufac, dims=2)[:, 1]
    #
    mrcFgenf = maximum(r_c_Fgenf[:, :, :, n], dims=3)[:, :, 1]
    mrcHr = maximum(r_c_Hr[:, :, :, n], dims=3)[:, :, 1]
    #
    mrcUonSite = maximum(r_c_UonSite[:,:,:,:,n], dims=4)[:, :, :, 1]
    mrcUonSite = [reshape(mrcUonSite[:, :, l]', n_periods*n_subperiods) for l in 
                  1:n_loc]
    # turn this into an array (n_per*n_sub) by n_loc
    mrcUonSite = reduce(hcat, mrcUonSite)
    mrcUonSite = maximum(mrcUonSite, dims=1)[1, :]

    #
    r_uOnsite_ub = mrcUonSite.*mrcUfac.*mrcU.*r_x_out_ub[:, n, ckey[n]]
    r_u_ehf_ub[:, :, n] = adjoint(r_uOnsite_ub).*mrcFgenf.*mrcHr
end
#r_u_ehf_ub = r_uOnsite_ub.*(adjoint(mrcFgenf).*adjoint(mrcHr))
#

#
#
r_fu_e_ub = zeros(n_loc, n_node)
r_u_fu_e_ub = zeros(n_loc, n_node)
for n in 1:n_node
    mrcFe = maximum(r_c_Fe[:,:,:,n], dims=3)[:, :, 1]
    # r_ehf_ub * mrcFe (nloc*mnfu x mnfu*nloc)
    for l in loc_range
        # 1*mnfu x mnfu*1
        r_fu_e_ub[l, n] = r_ehf_ub[:, l, n]'mrcFe[:, l]
        r_u_fu_e_ub[l, n] = r_u_ehf_ub[:, l, n]'mrcFe[:, l]
    end
end


r_ep0_ub = sum(r_cpe_ub[:, n] + 
               r_fu_e_ub[:, n] + 
               r_u_fu_e_ub[:, n] for n in 1:n_node) # 3 onsite-e

# capture fraction
r_chi = zeros(n_loc, n_rtft) # 34

### ### 5: CCS
r_chi[:, 5] .= 0.95  # ccs

r_ep1ge_ub = r_ep0_ub # 35

r_sigma = ones(n_loc, n_rtft)*0.99 # 36

r_ep1gce_ub = r_ep0_ub # 37
r_ep1gcs_ub = r_ep0_ub # 38

# 80 #
r_c_upsein_rate = zeros(n_loc, n_mat)
r_c_upsein_rate[:, 1] .= 0.01
r_c_upsein_rate[:, 2] .= 0.05
r_c_upsein_rate[:, 4] .= 0.01


r_c_upsein_rate .*= sf_em/sf_cap

# upper bound
r_ups_e_mt_in_ub = zeros(n_loc)

for l in 1:n_loc
    r_ups_e_mt_in_ub[l] = 
    sum(
        sum(r_c_upsein_rate[l, c] * r_x_in_ub[l, n, c] 
            for c in 1:n_mat if node_mat[n, c] && c ∈ input_mat[n])
        for n in 1:n_node
       )
end

o_ups_e_mt_in_ub = r_ups_e_mt_in_ub

# 80 #
r_c_fOnm = ones(n_loc, n_rtft).*fonm_base_value

r_rhs_fOnm = zeros(n_loc, n_rtft) # 40
# scaled!
r_cfonm_ub = r_cpb_ub.* maximum(r_c_fOnm, dims=2) # 41
# 80 #
r_c_vOnm = ones(n_loc, n_rtft).*vonm_base_value
### ### 4: Full Electrification
r_c_vOnm[:, 4] .+= 2*1e-6 * (sf_cash/sf_cap)
### ### 5: CCS
r_c_vOnm[:, 5] .+= (2.2+6)*1e-6 * (sf_cash/sf_cap)

r_rhs_vOnm = zeros(n_loc, n_rtft) # 40
r_cvonm_ub = r_cpb_ub.* maximum(r_c_vOnm, dims=2) # 41

r_e_c_ub = zeros(n_loc)
for l in loc_range
    r_e_c_ub[l] = e_C[l] * x_ub
end

r_loanFact = ones(n_periods, n_subperiods, n_loc, n_rtft)
# capacity is ton per year
# 1M/ton/yr efficiency
# 8M/ton/yr fuel switch
# (95 ccs) 20M/ton/yr
# (full elec)  15M/ton/yr
#
# 2% capital for fONM
# variable non fuel 
# f
r_loanFact[:, :, :, 1] .= 0.0
r_loanFact[:, :, :, 2] .= 1.0*(sf_cash/sf_cap) # eff
r_loanFact[:, :, :, 3] .= 0.8*(sf_cash/sf_cap)
r_loanFact[:, :, :, 4] .= 10*(sf_cash/sf_cap)
r_loanFact[:, :, :, 5] .= 15*(sf_cash/sf_cap)

r_l0_ub = zeros(n_loc, n_rtft)
for l in 1:n_loc
    for k in 1:n_rtft
        r_l0_ub[l, k] = c0[l].*r_loanFact[1, 1, l, k].*relax_ub_fac  # relaxed
    end
end
r_le_ub = zeros(n_loc, n_rtft)
for l in 1:n_loc
    for k in 1:n_rtft
        r_le_ub[l, k] = e_C[l].*x_ub.*r_loanFact[1, 1, l, k].*relax_ub_fac  # relaxed
    end
end


r_l_ub = r_cpb_ub.*maximum(r_loanFact[1, 1, :, :], dims=2) # 43

#r_Ann = ones(n_periods, n_subperiod, n_loc, n_rtft) # 44
#r_Ann = r_loanFact.*annumPayF # ./annuity_scale
r_Ann = ones(n_periods, n_subperiods, n_loc, n_rtft).*annumPayF # ./annuity_scale

#r_ann_bM = r_cp_ub * maximum(r_Ann) # 45
#r_ann_bM = r_l_ub * annumPayF # 45
r_ann0_ub = maximum(r_l0_ub, dims=2).*annumPayF # 45
r_anne_ub = maximum(r_le_ub, dims=2).* annumPayF # 45

r_ann_ub = r_l_ub.* annumPayF # 45

r_l0add_ub = r_l_ub # 46
r_leadd_ub = r_l_ub # 46

r_loan_ub = r_l_ub .+ r_loan0 # 47
r_pay_ub = r_ann_ub # 48

r_pay0_ub = r_ann0_ub
r_paye_ub = r_anne_ub

###
r_c_Fstck = ones(n_loc, n_rtft, n_fstck)
r_rhs_Fstck = zeros(n_loc, n_rtft, n_fstck)
r_fstck_UB = ones(n_loc, n_rtft, n_fstck)
###
#
t_loan_ub = r_loan_ub .+ e_loan_ub # 50
t_ret_c_ub = t_loan_ub # 49

o_pay_ub = r_ann_ub .+ r_anne_ub .+ e_ann_ub  # 51
o_cfonm_ub = r_cfonm_ub  # 52
o_cvonm_ub = r_cvonm_ub  # 52

# 80 
# 80 ###########################################################################
##
#
# new plant filter
n_filter = Array{Bool}(undef, n_loc, n_new)
n_filter .= true

n_filter[:, 3] .= false

for l in loc_range
    state = d_fac[l, "State"]
    if state ∈ west_c_states
        n_filter[l, 5] = false
    end
end

n_max_cp_fac = ceil(agg_demand/agg_dem0)
n_max_cp_fac = n_max_cp_fac

n_c0_bM = c0.*n_max_cp_fac # 54

n_c0_lo = zeros(n_loc, n_new)
n_c0_lo[:, :] .= c0

n_cp_ub = zeros(n_loc, n_node)
n_cp_ub[:, 1] = n_c0_bM * maximum(abs.(n_Kmb[2, ckey[1], ckey[2], :]))
n_cp_ub[:, 2] = n_c0_bM

#n_loanFact = ones(n_loc, n_new) # 55
n_loanFact = ones(n_loc, n_new).*loan_base_value

n_loanFact[:, 1] .= 0.0
n_loanFact[:, 2] .= 8.0*(sf_cash/sf_cap) # eff
# n_loanFact[:, 3] .= 0.8*(sf_cash/sf_cap)
n_loanFact[:, 4] .= 15*(sf_cash/sf_cap)
n_loanFact[:, 5] .= 20*(sf_cash/sf_cap)


n_l_bM = n_c0_bM.*maximum(n_loanFact, dims=2) # 56


n_Ann = ones(n_loc, n_new).*annumPayF # ./annuity_scale


n_ann_bM = n_l_bM * annumPayF # 58

n_ladd_bM = n_l_bM # 59
n_loan_bM = n_l_bM # 60
n_pay_bM = n_ann_bM # 61

# 80 ###########################################################################
#
n_x_out_ub = zeros(n_loc, n_node, n_mat)

n_x_out_ub[:, 1, 3] .= n_cp_ub[:, 1]
# node 2
n_x_out_ub[:, 2, 5] .= n_cp_ub[:, 2]
##
#
n_x_in_ub = zeros(n_loc, n_node, n_mat)
# node 1
n_x_in_ub[:, 1, 1] .= n_cp_ub[:, 1].*maximum(abs.(n_Kmb[1, 1, ckey[1], :]))
n_x_in_ub[:, 1, 2] .= n_cp_ub[:, 1].*maximum(abs.(n_Kmb[1, 2, ckey[1], :]))
n_x_in_ub[:, 1, 3] .= n_cp_ub[:, 1]
# node 2
n_x_in_ub[:, 2, 3] .= n_cp_ub[:, 2].*maximum(abs.(n_Kmb[2, 3, ckey[2], :]))
n_x_in_ub[:, 2, 4] .= n_cp_ub[:, 2].*maximum(abs.(n_Kmb[2, 4, ckey[2], :]))
n_x_in_ub[:, 2, 5] .= n_cp_ub[:, 2]


n_Kkey_j = ones(n_node, n_new)
n_Kkey_j[1, :] = abs.(r_Kmb[2, ckey[1], ckey[2], :])
n_Kkey_j[2, :] .= 1.0 

# 80 ###########################################################################
n_c_H = ones(n_loc, n_new, n_node) # 62
for k in 1:n_new
    n_c_H[:, k, 1] .= d_fac[loc_range, "HiMBTUTon"]
    n_c_H[:, k, 2] .= d_fac[loc_range, "HiMBTUTon"].*1e-01
end

### ### 2: Efficiency
n_c_H[:, 2, :] .*= 0.95
### ### 4: Full Electrification
n_c_H[:, 4, :] .= 0.00 
### ### 5: ccs 
n_c_H[:, 5, :] .= n_c_H[:, 2, :].*1.2 

n_rhs_H = zeros(n_loc, n_new, n_node)

# hi factor 
n_c_Hfac = ones(n_loc, n_new)
#n_c_Hfac[:, 3] .= 1.448

# electrification
n_c_Helec = zeros(n_loc, n_new)

# 80 
# 80 ###########################################################################
##

n_nfu = n_rfu
mnnfu = maximum(n_nfu)
n_c_F = ones(mnnfu, n_loc, n_new, n_node) # 64

for n in 1:n_node
    for k in 1:n_new
        for l in loc_range
            n_c_F[:, l, k, n] = dff[1:mnrfu, l]
        end
    end
end

# fuel fraction correction
#### #### 3: NG-fuel switch
for n in 1:n_node
    for l in 1:n_loc
        if has_any_coal[l] > 0
            coal_frac = 0.0
            for coal_id in coal_ids
                plnt_coal_id = findfirst(==(coal_id), dfid[1:dnfu[l], l])
                if !isnothing(plnt_coal_id)
                    coal_frac += n_c_F[plnt_coal_id, l, 3, n] 
                    n_c_F[plnt_coal_id, l, 3, n] = 0.0
                end
            end
            # find ng
            plnt_ng_id = findfirst(==(ng_id), dfid[1:dnfu[l], l])
            n_c_F[plnt_ng_id, l, 3, n] += coal_frac
        end
    end
end


# 80 ###########################################################################
# scaled!
n_eh_bM = zeros(n_loc, n_node)
for n in 1:n_node
    n_eh_bM[:, n] = (n_x_out_ub[:, n, ckey[n]].*
                     maximum(n_c_H[:,:,n], dims=2).*
                     maximum(n_c_Hfac, dims=2))
end
#
n_rhs_F = zeros(mnnfu, n_loc, n_new, n_node) # 65
n_ehf_ub = zeros(mnnfu, n_loc, n_node)
# scaled!
for n in 1:n_node
    mncF = maximum(n_c_F[:,:,:,n], dims=3)[:, :, 1]
    mnrhsF = maximum(n_rhs_F[:,:,:,n], dims=3)[:, :, 1]
    n_ehf_ub[:, :, n] = adjoint(n_eh_bM[:, n]).*mncF .+ mnrhsF  # 66
end



# define this before we get rid of the rows
n_c_U = ones(n_loc, n_new, n_node) 
for k in 1:n_new
    # this comes from the row for electricity
    n_c_U[:, k, 1] .= d_fac[loc_range, "EiMBTUTon"]
    # ten percent
    n_c_U[:, k, 2] .= d_fac[loc_range, "EiMBTUTon"].*1e-01
end

### ### 2: Efficiency
n_c_U[:, 2, :] .*= 0.95

### ### 4: Full Electrification
n_c_U[:, 4, 1] .+= n_c_U[:, 2, 1].*eToHfac[1]
n_c_U[:, 4, 2] .+= n_c_U[:, 2, 2].*eToHfac[2]

### ###

### ### 5: CCS 
# additional electricity requirement of 70.48 kwh/tclinker
n_c_U[:, 5, :] .= n_c_U[:, 2, :].*1.3
### ###

n_rhs_U = zeros(n_loc, n_new, n_node) # 68

n_c_UonSite = ones(n_periods, 
                   n_subperiods, 
                   n_loc, 
                   n_new,
                   n_node).*(5/100)

n_c_Ufac = ones(n_loc, n_new)
#
n_u_ub = zeros(n_loc, n_node)
for n in 1:n_node
    n_u_ub[:, n] = (n_x_out_ub[:, n, ckey[n]].*
                    maximum(n_c_U[:,:,n], dims=2).*maximum(n_c_Ufac, dims=2) +
                    maximum(n_c_Helec, dims=2).* n_eh_bM[:, n]
                   )
end

n_c_cpe = ones(n_loc, n_new, n_node)
for k in 1:n_rtft
    n_c_cpe[:, k, 1] = d_fac[loc_range, "pETonTon"]
    n_c_cpe[:, k, 2] = d_fac[loc_range, "pETonTon"].*1e-2
end
n_rhs_cpe = zeros(n_loc, n_new, n_node) # 71

# scaled!
n_cpe_ub = zeros(n_loc, n_node)
for n in 1:n_node
    n_cpe_ub[:, n] = n_cp_ub[:, n] .* maximum(n_c_cpe, dims=2)[:, 1, n] # 72
end

n_c_Fe = ones(mnnfu, n_loc, n_new, n_node) # 73
for k in 1:n_new
    for l in loc_range
        n_c_Fe[:, l, k, :] .= dem[1:mnrfu, l]
    end
end

#for i in 1:n_new
#    n_c_Fgenf[:, :, i] .= d_fuel[loc_range, 2:end]
#end
n_c_Fgenf = n_c_F


n_c_Hr = ones(mnnfu, n_loc, n_new, n_node) # 73

n_u_ehf_ub = zeros(mnnfu, n_loc, n_node)

for n in 1:n_node
    mncU = maximum(n_c_U[:,:,n], dims=2)[:, 1]
    mncUfac = maximum(n_c_Ufac, dims=2)[:, 1]
    #
    mncFgenf = maximum(n_c_Fgenf[:, :, :, n], dims=3)[:, :, 1]
    mncHr = maximum(n_c_Hr[:, :, :, n], dims=3)[:, :, 1]
    #
    mncUonSite = maximum(n_c_UonSite[:, :, :, :, n], dims=4)[:, :, :, 1]
    mncUonSite = [reshape(mncUonSite[:, :, l]', n_periods*n_subperiods) for l in
                  1:n_loc]
    mncUonSite = reduce(hcat, mncUonSite)
    mncUonSite = maximum(mncUonSite, dims=1)[1, :]
    #
    n_uOnsite_ub = mncUonSite.*mncUfac.*mncU.*n_x_out_ub[:, n, ckey[n]]
    n_u_ehf_ub[:, :, n] = adjoint(n_uOnsite_ub).*mncFgenf.*mncHr
end
# n_u_ehf_ub = n_u_bM * maximum(n_c_Hr)* maximum(n_c_Fgenf)

#
n_fu_e_ub = zeros(n_loc, n_node) # n_ehf_ub*mncFe
n_u_fu_e_ub = zeros(n_loc, n_node) # n_u_ehf_ub*mncFe
#
for n in 1:n_node
    mncFe = maximum(n_c_Fe[:, :, :, n], dims=3)[:, :, 1]
    for l in loc_range
        n_fu_e_ub[l, n] = n_ehf_ub[:, l, n]'mncFe[:, l]
        n_u_fu_e_ub[l, n] = n_u_ehf_ub[:, l, n]'mncFe[:, l]
    end
end
#
n_ep0_bM = sum(n_cpe_ub[:, n] + 
               n_fu_e_ub[:, n] + 
               n_u_fu_e_ub[:, n] for n in 1:n_node)

n_chi = zeros(n_loc, n_new)  # 75

# 5: ccs
n_chi[:, 5] .= 0.95 # 75

n_ep1ge_bM = n_ep0_bM # 76
n_sigma = ones(n_loc, n_new)*0.99 # 77

n_ep1gce_bM = n_ep0_bM  # 78
n_ep1gcs_bM = n_ep0_bM  # 79

# 80 #
n_c_upsein_rate = zeros(n_loc, n_mat)
n_c_upsein_rate[:, 1] .= 0.01
n_c_upsein_rate[:, 2] .= 0.05
n_c_upsein_rate[:, 4] .= 0.01

n_c_upsein_rate .*= sf_em/sf_cap

n_ups_e_mt_in_ub = zeros(n_loc)

for l in 1:n_loc
    n_ups_e_mt_in_ub[l] = 
    sum(
        sum(n_c_upsein_rate[l, c] * n_x_in_ub[l, n, c] 
            for c in 1:n_mat if node_mat[n, c] && c ∈ input_mat[n])
        for n in 1:n_node
       )
end

o_ups_e_mt_in_uba = r_ups_e_mt_in_ub

#n_c_fOnm = ones(n_loc, n_new) # 80
n_c_fOnm = ones(n_loc, n_new).*fonm_base_value


n_rhs_fOnm = zeros(n_loc, n_new) # 81
n_cfonm_bM = n_c0_bM * maximum(n_c_fOnm) # 82

n_c_vOnm = ones(n_loc, n_new).*vonm_base_value
### ### 4: Full Electrification
r_c_vOnm[:, 4] .+= 2*1e-6 * (sf_cash/sf_cap)
### ### 5: CCS
n_c_vOnm[:, 5] .+= (2.2+6)*1e-6 * (sf_cash/sf_cap)

n_rhs_vOnm = zeros(n_loc, n_new) # 81
n_cvonm_bM = n_c0_bM * maximum(n_c_vOnm) # 82


# 80 ###########################################################################
n_c_Fstck = ones(n_loc, n_new, n_fstck)
n_rhs_Fstck = zeros(n_loc, n_new, n_fstck)
n_fstck_UB = ones(n_loc, n_new, n_fstck).*n_c0_bM
#
# 80 ###########################################################################
fu_eprcmat_id = zeros(Int32, nrow(dff))

fu_eprcmat_id[1] = 9 # coal
fu_eprcmat_id[2] = 3 # ng
fu_eprcmat_id[3] = 5 # petcoke


c_u_cost = ones(n_periods, n_subperiods, n_loc)

c_r_ehf_cost = ones(n_periods, n_subperiods, n_loc, mnrfu) .* 9e6
c_n_ehf_cost = ones(n_periods, n_subperiods, n_loc, mnnfu) .* 9e6

d_fuel_c = DataFrame(CSV.File(ener_c_f))
# ifuels = [18, 20, 22]
# coal:22, distfuel:18, ng:20
coal_inc = 0.5/100
ng_inc = 2/100
#
musdTousd = 1e-6 # Musd/USD
for l in loc_range
    for i in 1:n_periods
        for j in 1:n_subperiods
            y = (i-1)*yr_period + (j-1)*yr_subperiod
            c_r_ehf_cost[i, j, l, 1] = d_fuel_c[6, 22]*musdTousd*(1+coal_inc)^y
            c_r_ehf_cost[i, j, l, 2] = d_fuel_c[6, 18]*musdTousd*(1+ng_inc)^y
            c_r_ehf_cost[i, j, l, 3] = d_fuel_c[6, 20]*musdTousd*(1+ng_inc)^y
            #
            c_n_ehf_cost[i, j, l, 1] = d_fuel_c[6, 22]*musdTousd*(1+coal_inc)^y
            c_n_ehf_cost[i, j, l, 2] = d_fuel_c[6, 18]*musdTousd*(1+ng_inc)^y
            c_n_ehf_cost[i, j, l, 3] = d_fuel_c[6, 20]*musdTousd*(1+ng_inc)^y
        end
    end
end

d_elec_c = DataFrame(CSV.File(elec_c_f))
centToMUSD = (1/100) * 1e-06
ckwhToMusdMwh = (1/100) * (1000/1) * 1e-06
# 1 MWh = 3.412142 MMBTU
mbtuToMwh = 3.412142 # mmbtu/mwh 
e_inc = 1/100
stat_id = Dict(d_elec_c[i, 1]=>i for i in 1:nrow(d_elec_c))
for l in loc_range
    state = d_fac[l, "State"]
    sid = stat_id[state]
    for i in 1:n_periods
        for j in 1:n_subperiods
            y = (i-1)*yr_period + (j-1)*yr_subperiod
            c_u_cost[i, j, l] = d_elec_c[sid, 2]*ckwhToMusdMwh*mbtuToMwh*(1+e_inc)^y
        end
    end
end


c_cts_cost = ones(n_loc) * 10 * 1e-06
# musd/tonneCO2
# this does not require the scaling factor.

# 80
# 80 ###########################################################################
##
c_u_cost .*= sf_cash/sf_elec
c_r_ehf_cost .*= sf_cash/sf_heat
c_n_ehf_cost .*= sf_cash/sf_heat
c_cts_cost .*= sf_cash/sf_em

# 80
# 80 ###########################################################################
##

# cost per ton
c_xin_cost = ones(n_loc, n_mat)*1e-06
c_xin_cost[:, 3] .= 0.0
c_xin_cost[:, 5] .= 0.0
c_xin_cost .*= sf_cash/sf_cap

# 80 ###########################################################################
o_cp_ub = r_cp_ub # 82
o_cpe_bM = 1e5 # 83 this one does not exists
o_u_bM = r_u_ub # 83

o_ehf_ub = r_ehf_ub + r_u_ehf_ub
o_ep0_bM = r_ep0_ub


o_ep1ge_bM = r_ep1ge_ub
o_ep1gce_bM = r_ep1gce_ub
o_ep1gcs_bM = r_ep1gcs_ub
#
#
o_fstck_UB = zeros(n_loc, n_fstck)
for l in 1:n_loc
    for k in 1:n_fstck
        o_fstck_UB[l, k] = (maximum(r_fstck_UB[l, :, k]) 
                            + maximum(n_fstck_UB[l, :, k]))
    end
end
#
o_x_out_ub = r_x_out_ub
o_x_in_ub = r_x_in_ub

# 80
# 80 ###########################################################################
##


discount = ones(n_periods, n_subperiods)

for i in 1:n_periods
    for j in 1:n_subperiods
        y = (i-1) * yr_period + (j-1) * yr_subperiod
        #@printf "y = %i\n" y
        discount[i, j] = (1/(1+interest)^(y))
        # interest captial risk, rui, 
        # 7% rate, discount factor 
    end
end




demand_proj = LinRange(agg_dem0, agg_demand, n_periods*n_subperiods)
demand = reshape(demand_proj, (n_subperiods, n_periods))'

efuel = zeros(n_node)

cp0n = zeros(n_loc, n_node)
cp0n[:, 1] = -c0*r_Kmb[2,3,5,1]
cp0n[:, 2] = c0

for n in 1:n_node#
    # n_loc*n_fu x n_fu
    c0rcH = cp0n[:, n].*r_c_H[:, 1, n]
    # n_fu*n_loc x n_fu*n_loc
    # rcFFe = r_c_F[:, :, 1]*r_c_Fe[:, :, 1]
    rcFFe = zeros(n_loc)
    for l in loc_range
        rcFFe[l] = r_c_F[:, l, 1, n]'r_c_Fe[:, l, 1, n]
    end

    efuel[n] = sum(c0rcH.*rcFFe)
end


eelins = zeros(n_node)
for n in 1:n_node
    # onsite electricity mmbtu
    el_ons = r_c_UonSite[1, 1, :, 1, n].*r_c_Ufac[:, 1].*r_c_U[:, 1, n].*cp0n[:, n]
    # rcHrFgenfFe = (r_c_Hr[:, :, 1].*r_c_Fgenf[:, :, 1])*r_c_Fe[:, :, 1]
    # emission factor
    rcHrFgenfFe = zeros(n_loc)
    for l in loc_range
        rcHrFgenfFe[l] = (r_c_Hr[:, l, 1, n].*r_c_Fgenf[:, l, 1, n])'r_c_Fe[:, l, 1, n]
    end

    eelins[n] = sum(el_ons.*rcHrFgenfFe)
end

eproc = zeros(n_node)
for n in 1:n_node
    eproc[n] = cp0n[:, n]'r_c_cpe[:, 1, n]
end



xin0 = zeros(n_loc, n_mat)
xin0[:, 1] = r_Kmb[2, 3, 5, 1]*r_Kmb[1, 1, 3, 1]*c0
xin0[:, 2] = r_Kmb[2, 3, 5, 1]*r_Kmb[1, 2, 3, 1]*c0
xin0[:, 3] = -r_Kmb[2, 3, 5, 1]*c0
xin0[:, 4] = -r_Kmb[2, 4, 5, 1]*c0
xin0[:, 5] = c0

# from materials
ups_e_in_mat = sum(r_c_upsein_rate[l, c] * xin0[l, c] 
                   for l in 1:n_loc
                   for n in 1:n_node
                   for c in 1:n_mat if node_mat[n, c] && c ∈ input_mat[n]
                   )

#el_grd = (1 .- r_c_UonSite[1, 1, :, 1]).*r_c_Ufac[:, 1].*r_c_U[:, 1].*c0


GcI = ones(n_periods, n_subperiods, n_loc)


# tonneCO2/MwH
GcI.*=(1/1000) 

# 1 MMBtu = 0.29329722222222 MWh
#e_grd = sum(el_grd.*GcI[1, 1, :].*0.29329722222222)

co2_total0 = sum(efuel)+ sum(eproc) + sum(eelins) + sum(ups_e_in_mat) #+ e_grd
#co2_total0 *= yr_period
#co2_total0 = 1.149872065065227e9
#
co2_reduction = 0.5
co2_endpoint = co2_total0 * (1 - co2_reduction) # @2050

co2_slope = (co2_endpoint - co2_total0)/(2050-year0)
actual_co2_endpoint = co2_total0 + co2_slope*time_horizon

co2_relax_fac = 1.01

# co2_linrange = collect(LinRange(sum(co2_total0)*co2_relax_fac,
#                                 actual_co2_endpoint, n_periods*n_subperiods))
# for i in 1:length(co2_linrange)
#     co2_linrange[i] = co2_linrange[i] < co2_endpoint ? co2_endpoint : co2_linrange[i]
# end
# co2_budget = reshape(co2_linrange, (n_subperiods, n_periods))' 
co2_budget = zeros(n_periods, n_subperiods)
co2_budget .= (co2_total0 + co2_endpoint)*0.5*(2050-year0)

min_cpr = ones(n_loc) .* 0.50



p = params(n_periods, # 0 
           n_subperiods,
           n_loc, # 1
           n_rtft, # 2
           n_new,    # 3
           n_fstck,  # 5
           n_node,
           n_mat,
           n_link,
           yr_subperiod,
           year0,
           x_ub,  # 7
           interest,
           sf_cap,
           sf_cash,
           sf_heat,
           sf_elec,
           sf_em,
           key_node,
           n_rfu,
           n_nfu,
           c0,   # 15
           e_C,  # 5
           e_c_ub,  # 6
           e_loanFact,  # 8
           e_l_ub,  # 9
           e_Ann,  # 10
           e_ann_ub,   # 11
           e_ladd_ub,   # 12
           e_loan_ub,   # 13
           e_pay_ub,   # 14
           r_filter,
           r_c_C,   # 16
           r_rhs_C,   # 17
           r_cp_ub,   # 18
           r_cpb_ub,  # 19
           r_c_H,  # 20
           r_rhs_H,  # 21
           r_eh_ub,  # 22
           r_c_Hfac,
           r_c_Helec,
           r_c_F,  # 23
           r_rhs_F,  # 24
           r_ehf_ub,  # 25
           r_c_U,  # 25
           r_rhs_U,  # 26 
           r_c_UonSite,  # 27
           r_c_Ufac,
           r_u_ub,  # 28
           r_c_cpe,  # 29
           r_rhs_cpe,  # 30
           r_cpe_ub,  # 31
           r_c_Fe,  # 32
           r_c_Fgenf,  # 33
           r_u_ehf_ub,
           r_c_Hr,  # 34
           r_fu_e_ub,
           r_u_fu_e_ub,
           r_ep0_ub,  # 35
           r_chi,  # 36
           r_ep1ge_ub,  # 37
           r_sigma,  # 38
           r_ep1gce_ub, # 39
           r_ep1gcs_ub, # 40
           r_c_fOnm, # 41
           r_rhs_fOnm, # 42
           r_cfonm_ub, # 43
           r_c_vOnm, # 41
           r_rhs_vOnm, # 42
           r_cvonm_ub, # 43
           r_e_c_ub,
           r_loanFact, # 44
           r_l0_ub, # 45
           r_le_ub, # 45
           r_Ann, # 46
           r_ann0_ub, # 47
           r_anne_ub, # 47
           r_l0add_ub, # 48
           r_leadd_ub, # 48
           r_loan_ub, # 49
           r_pay0_ub, # 50
           r_paye_ub, # 50
           r_c_Fstck,
           r_rhs_Fstck,
           r_fstck_UB,
           r_Kmb,
           r_x_in_ub,
           r_x_out_ub,
           r_c_upsein_rate,
           r_ups_e_mt_in_ub,
           n_filter,
           n_cp_ub, # 54
           n_c0_bM, # 55
           n_c0_lo,
           n_loanFact, # 56
           n_l_bM, # 57
           n_Ann, # 58
           n_ann_bM, # 59
           n_ladd_bM, # 60
           n_loan_bM, # 61
           n_pay_bM, # 62
           n_c_H, # 63
           n_rhs_H, # 
           n_eh_bM, # 64
           n_c_Hfac,
           n_c_Helec,
           n_c_F, # 65
           n_rhs_F, # 66
           n_ehf_ub, # 67
           n_c_U, # 68
           n_rhs_U, # 69
           n_c_UonSite,
           n_c_Ufac,
           n_u_ub, # 70
           n_c_cpe, # 71
           n_rhs_cpe, # 72
           n_cpe_ub, # 73
           n_c_Fe, # 74
           n_c_Fgenf,
           n_u_ehf_ub,
           n_c_Hr,
           n_fu_e_ub,
           n_u_fu_e_ub,
           n_ep0_bM, # 75
           n_chi, # 76
           n_ep1ge_bM, # 77
           n_sigma, # 78
           n_ep1gce_bM, # 79
           n_ep1gcs_bM, # 80
           n_c_fOnm, # 81
           n_rhs_fOnm, # 82
           n_cfonm_bM, # 83
           n_c_vOnm, # 81
           n_rhs_vOnm, # 82
           n_cvonm_bM, # 83
           n_c_Fstck,
           n_rhs_Fstck,
           n_fstck_UB,
           n_Kmb,
           n_x_in_ub,
           n_x_out_ub,
           n_c_upsein_rate,
           n_ups_e_mt_in_ub,
           c_u_cost,
           c_r_ehf_cost,
           c_n_ehf_cost,
           c_cts_cost[1:n_loc],
           c_xin_cost,
           o_cp_ub,
           o_cpe_bM,
           o_u_bM,
           o_ehf_ub,
           o_ep0_bM,
           o_ep1ge_bM,
           o_ep1gce_bM,
           o_ep1gcs_bM,
           o_ups_e_mt_in_ub,
           o_pay_ub, # 52
           o_cfonm_ub, # 53
           o_cvonm_ub, # 53
           o_fstck_UB,
           o_x_in_ub,
           o_x_out_ub,
           t_ret_c_ub, # 50
           t_loan_ub, # 51
           r_loan0, # 84
           discount, # 85
           demand,
           co2_budget,
           GcI,
           node_mat,
           skip_mb,
           input_mat,
           output_mat,
           links_list,
           ckey,
           nd_en_fltr,
           nd_em_fltr,
           r_Kkey_j,
           n_Kkey_j,
           min_cpr
          )

xlsxfname = "f0.xlsx"
write_params(p, xlsxfname)
p2 = read_params(xlsxfname);


for field in fieldnames(params)
    x = getfield(p, field)
    y = getfield(p2, field)
    if "$field" == "links_list"
        continue
    end
    n = norm(x .- y, Inf)
    println("$field: ", n)
end



append_fuelnames!(fnames, xlsxfname)

u_names = ["cap", "cash", "heat", "elec", "em", ]
u_units = ["ktonne", "MUSD", "kMMBTU", "kMMBTU", "ktonne", ]

append_units_names!(u_names, u_units, xlsxfname)

rfnames = [
           "No retrofit",
           "5% energy efficiency",
           "Coal switch to natural gas",
           "Full electrification",
           "95% carbon capture"
          ]

nwnames = [
           "No retrofit",
           "New plant BAT",
           "--",
           "Full electrification",
           "95% carbon capture"
          ]

append_tech_names!(rfnames, nwnames, xlsxfname)


function check_param()
    p = [n_periods, # 0 
         n_subperiods,
         n_loc, # 1
         n_rtft, # 2
         n_new,    # 3
         n_fstck,  # 5
         n_node,
         n_mat,
         n_link,
         yr_subperiod,
         year0,
         x_ub,  # 7
         interest,
         sf_cap,
         sf_cash,
         sf_heat,
         sf_elec,
         sf_em,
         key_node,
         n_rfu,
         n_nfu,
         c0,   # 15
         e_C,  # 5
         e_c_ub,  # 6
         e_loanFact,  # 8
         e_l_ub,  # 9
         e_Ann,  # 10
         e_ann_ub,   # 11
         e_ladd_ub,   # 12
         e_loan_ub,   # 13
         e_pay_ub,   # 14
         r_filter,
         r_c_C,   # 16
         r_rhs_C,   # 17
         r_cp_ub,   # 18
         r_cpb_ub,  # 19
         r_c_H,  # 20
         r_rhs_H,  # 21
         r_eh_ub,  # 22
         r_c_Hfac,
         r_c_Helec,
         r_c_F,  # 23
         r_rhs_F,  # 24
         r_ehf_ub,  # 25
         r_c_U,  # 25
         r_rhs_U,  # 26 
         r_c_UonSite,  # 27
         r_c_Ufac,
         r_u_ub,  # 28
         r_c_cpe,  # 29
         r_rhs_cpe,  # 30
         r_cpe_ub,  # 31
         r_c_Fe,  # 32
         r_c_Fgenf,  # 33
         r_u_ehf_ub,
         r_c_Hr,  # 34
         r_fu_e_ub,
         r_u_fu_e_ub,
         r_ep0_ub,  # 35
         r_chi,  # 36
         r_ep1ge_ub,  # 37
         r_sigma,  # 38
         r_ep1gce_ub, # 39
         r_ep1gcs_ub, # 40
         r_c_fOnm, # 41
         r_rhs_fOnm, # 42
         r_cfonm_ub, # 43
         r_c_vOnm, # 41
         r_rhs_vOnm, # 42
         r_cvonm_ub, # 43
         r_e_c_ub,
         r_loanFact, # 44
         r_l0_ub, # 45
         r_le_ub, # 45
         r_Ann, # 46
         r_ann0_ub, # 47
         r_anne_ub, # 47
         r_l0add_ub, # 48
         r_leadd_ub, # 48
         r_loan_ub, # 49
         r_pay0_ub, # 50
         r_paye_ub, # 50
         r_c_Fstck,
         r_rhs_Fstck,
         r_fstck_UB,
         r_Kmb,
         r_x_in_ub,
         r_x_out_ub,
         r_c_upsein_rate,
         r_ups_e_mt_in_ub,
         n_filter,
         n_cp_ub, # 54
         n_c0_bM, # 55
         n_c0_lo,
         n_loanFact, # 56
         n_l_bM, # 57
         n_Ann, # 58
         n_ann_bM, # 59
         n_ladd_bM, # 60
         n_loan_bM, # 61
         n_pay_bM, # 62
         n_c_H, # 63
         n_rhs_H, # 
         n_eh_bM, # 64
         n_c_Hfac,
         n_c_Helec,
         n_c_F, # 65
         n_rhs_F, # 66
         n_ehf_ub, # 67
         n_c_U, # 68
         n_rhs_U, # 69
         n_c_UonSite,
         n_c_Ufac,
         n_u_ub, # 70
         n_c_cpe, # 71
         n_rhs_cpe, # 72
         n_cpe_ub, # 73
         n_c_Fe, # 74
         n_c_Fgenf,
         n_u_ehf_ub,
         n_c_Hr,
         n_fu_e_ub,
         n_u_fu_e_ub,
         n_ep0_bM, # 75
         n_chi, # 76
         n_ep1ge_bM, # 77
         n_sigma, # 78
         n_ep1gce_bM, # 79
         n_ep1gcs_bM, # 80
         n_c_fOnm, # 81
         n_rhs_fOnm, # 82
         n_cfonm_bM, # 83
         n_c_vOnm, # 81
         n_rhs_vOnm, # 82
         n_cvonm_bM, # 83
         n_c_Fstck,
         n_rhs_Fstck,
         n_fstck_UB,
         n_Kmb,
         n_x_in_ub,
         n_x_out_ub,
         n_c_upsein_rate,
         n_ups_e_mt_in_ub,
         c_u_cost,
         c_r_ehf_cost,
         c_n_ehf_cost,
         c_cts_cost[1:n_loc],
         c_xin_cost,
         o_cp_ub,
         o_cpe_bM,
         o_u_bM,
         o_ehf_ub,
         o_ep0_bM,
         o_ep1ge_bM,
         o_ep1gce_bM,
         o_ep1gcs_bM,
         o_ups_e_mt_in_ub,
         o_pay_ub, # 52
         o_cfonm_ub, # 53
         o_cvonm_ub, # 53
         o_fstck_UB,
         o_x_in_ub,
         o_x_out_ub,
         t_ret_c_ub, # 50
         t_loan_ub, # 51
         r_loan0, # 84
         discount, # 85
         demand,
         co2_budget,
         GcI,
         node_mat,
         skip_mb,
         input_mat,
         output_mat,
         links_list,
         ckey,
         nd_en_fltr,
         nd_em_fltr,
         r_Kkey_j,
         n_Kkey_j,
        ]

    for i in p
        println(typeof(i))
    end
    println("Actual types")
    for i in fieldtypes(params)
        println(i)
    end
end




