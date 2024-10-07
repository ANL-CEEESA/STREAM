

using DataFrames
import XLSX
# intended for use with the bm_v06_03.jl

struct sets
    P::UnitRange  # periods
    P2::UnitRange  # subperiods per period
    L::UnitRange
    Kr::UnitRange
    Kn::UnitRange
    Fu::UnitRange
    Nf::UnitRange
    function sets(
            n_periods::Int64,
            n_subperiods::Int64,  # years per period
            n_locations::Int64, 
            n_rtrf::Int64, n_new::Int64, n_fu::Int64, n_fstck::Int64)
        P = 1:n_periods
        P2 = 1:n_subperiods
        L = 1:n_locations
        Kr = 1:n_rtrf
        Kn = 1:n_new
        Fu = 1:n_fu
        Nf = 1:n_fstck
        new(P, P2, L, Kr, Kn, Fu, Nf)
    end
end



mutable struct params
    # info
    n_periods::Int64 # 0
    n_subperiods::Int64 #
    n_location::Int64 # 1
    n_rtft::Int64 # 2
    n_new::Int64 # 3
    n_fu::Int64 # 4
    n_fstck::Int64
    yr_subperiod::Int64
    y0::Int64
    x_ub::Float64  # 7 *allocation* upper bound
    interest::Float64 # 84


    c0::Vector{Float64} # 15 initial capacity [l]
    # expansion
    e_C::Vector{Float64} # 5 capacity factor for expansion [l]

    e_c_ub::Vector{Float64} # 6 *capacity* expansion big-M (capacity units)

    e_loanFact::Vector{Float64} # 8 capacity expansion cost fact (cost units)
    e_l_ub::Vector{Float64}  # 9 capacity cost big-M (cost u)

    e_Ann::Vector{Float64} # 10 capacity expansion annuity [l] (cost units)
    e_ann_ub::Vector{Float64} # 11 capacity expansion annuity big-M (cost units)

    e_ladd_ub::Vector{Float64} # 12 ladd big-M (cost u)
    e_loan_ub::Vector{Float64} # 13 expansion loan big-M

    e_pay_ub::Vector{Float64} # 14
    # retrofit
    r_c_C::Matrix{Float64} # 16 *mode* capacity factor [l, k]
    r_rhs_C::Matrix{Float64} # 17 mode capacity rhs

    r_cp_ub::Vector{Float64} # 18 mode capacity big-M (capacity units)
    r_cpb_ub::Vector{Float64}# 19 mode-base capacity big-M (capacity units)

    r_c_H::Matrix{Float64}  # 20 mode heat factor [l, k] (heat u/cap u)
    r_rhs_H::Matrix{Float64}  # 21 mode heat factor rhs (heat u)

    r_eh_ub::Vector{Float64}  # 22 mode heat big-M (heat u)

    r_c_Hfac::Matrix{Float64}  # heat rate factor (can be gt. 1)
    r_c_Helec::Matrix{Float64}  # heat electrification fraction (can be gt. 1)

    r_c_F::Array{Float64, 3}  # 23 mode fuel factor [l, k, f] (fuel u/heat u)
    r_rhs_F::Array{Float64, 3}  # 24 mode fuel rhs

    r_ehf_ub::Matrix{Float64}# 25 mode fuel big-M

    r_c_U::Matrix{Float64}  # 26 mode electricity requirement [l, k] (elec u/cap u)
    r_rhs_U::Matrix{Float64} # 27
    
    r_c_UonSite::Array{Float64, 4}  # on-site capacity factor (0-1)
    r_c_Ufac::Matrix{Float64}  # electricity increase factor (can be gt. 1)

    r_u_ub::Array{Float64, 2} # 28 mode elec big-M

    r_c_cp_e::Matrix{Float64} # 29 process intrinsic emission factor [l, k] (em u/cap u)
    r_rhs_cp_e::Matrix{Float64} # 30 process intrinsic emission rhs

    r_cp_e_ub::Array{Float64, 1}# 31 process intrinsic emission big-M

    r_c_Fe::Matrix{Float64}  # 32 fuel emission factor [f, k] (em u/fu u)
    r_c_Fgenf::Array{Float64, 3}  # generation by fuel factor (0,1)
    r_u_ehf_ub::Array{Float64, 2}
    r_c_Hr::Array{Float64, 3}  # fuel heat rate
    
    r_fu_e_ub::Array{Float64, 1}
    r_u_fu_e_ub::Array{Float64, 1}
    r_ep0_ub::Vector{Float64}# 33

    r_chi::Matrix{Float64} # 34 captured [l, k]
    r_ep1ge_ub::Vector{Float64}# 35 fml

    r_sigma::Matrix{Float64} # 36 stored emissions [l, k]

    r_ep1gce_ub::Vector{Float64} # 37
    r_ep1gcs_ub::Vector{Float64} # 38

    r_c_Onm::Matrix{Float64} # 39
    r_rhs_Onm::Matrix{Float64} # 40
    r_conm_ub::Array{Float64, 2} # 41
    
    r_e_c_ub::Array{Float64, 1}  # new!

    r_loanFact::Array{Float64, 4} # 42
    r_l0_ub::Array{Float64, 2}  # 43 mode loan big-M
    r_le_ub::Array{Float64, 2}  # 44 mode loan big-M

    r_Ann::Array{Float64, 4} # 44 annuity factor for mode  [t, l, k]

    r_ann0_bM::Array{Float64, 2} # 45 mode annuity big-M
    r_anne_bM::Array{Float64, 2} # 45 mode annuity big-M

    r_l0add_bM::Array{Float64, 2} # 46 mode loan-add big-M
    r_leadd_bM::Array{Float64, 2} # 46 mode loan-add big-M

    r_loan_bM::Array{Float64, 2} # 47
    r_pay0_bM::Array{Float64, 2} # 48 mode payment big-M
    r_paye_bM::Array{Float64, 2} # 48 mode payment big-M
    
    r_c_Fstck::Array{Float64, 3}
    r_rhs_Fstck::Array{Float64, 3}
    r_fstck_ub::Array{Float64, 3}
    
    n_cp_bM::Vector{Float64} # 53
    n_c0_bM::Vector{Float64} # 54
    n_c0_lo::Matrix{Float64} # 54
    n_loanFact::Matrix{Float64} # 55
    n_l_bM::Array{Float64, 2} # 56

    n_Ann::Matrix{Float64} # 57
    n_ann_bM::Array{Float64, 2} # 58
    n_ladd_bM::Array{Float64, 2} # 59
    n_loan_bM::Array{Float64, 2} # 60
    n_pay_bM::Array{Float64, 2} # 61

    n_c_H::Matrix{Float64} # 62 [l, k]
    n_rhs_H::Matrix{Float64} # 
    n_eh_bM::Array{Float64, 2} # 63

    n_c_Hfac::Matrix{Float64}
    n_c_Helec::Matrix{Float64}

    n_c_F::Array{Float64, 3} # 64 [l, k, f]
    n_rhs_F::Array{Float64, 3} # 65 [l, k, f]
    n_ehf_bM::Array{Float64, 2} # 66

    n_c_U::Matrix{Float64} # 67
    n_rhs_U::Matrix{Float64} # 68
    
    n_c_UonSite::Array{Float64, 4}
    n_c_Ufac::Matrix{Float64}  # electricity increase factor (can be gt. 1)

    n_u_bM::Array{Float64, 2} # 69

    n_c_cp_e::Matrix{Float64} # 70
    n_rhs_cp_e::Matrix{Float64} # 71
    n_cp_e_ub::Array{Float64, 1} # 72

    n_c_Fe::Matrix{Float64} # 73 [f, k]
    n_c_Fgenf::Array{Float64, 3}  # [l, k, f]
    n_u_ehf_ub::Array{Float64, 2}
    n_c_Hr::Array{Float64, 3}  # [l, k, f]
    
    n_fu_e_ub::Array{Float64, 1}
    n_u_fu_e_ub::Array{Float64, 1}
    n_ep0_bM::Array{Float64, 1} # 74
    n_chi::Matrix{Float64} # 75

    n_ep1ge_bM::Array{Float64, 1} # 76
    n_sigma::Matrix{Float64} # 77
    n_ep1gce_bM::Array{Float64, 1} # 78

    n_ep1gcs_bM::Array{Float64, 1} # 79

    n_c_Onm::Matrix{Float64} # 80
    n_rhs_Onm::Matrix{Float64} # 81

    n_conm_bM::Vector{Float64} # 82
    ##
    n_c_Fstck::Array{Float64, 3}
    n_rhs_Fstck::Array{Float64, 3}
    n_fstck_ub::Array{Float64, 3}
    ##
    c_u_cost::Array{Float64, 3}  # elec cost
    c_ehf_cost::Array{Float64, 4} # fuel cost
    c_cts_cost::Vector{Float64}  # transport and storage
    ##
    o_cp_ub::Array{Float64, 1} # 83
    o_cp_e_bM::Float64
    o_u_bM::Array{Float64, 2}
    o_ehf_bM::Array{Float64, 2}
    o_ep0_bM::Vector{Float64}
    o_ep1ge_bM::Vector{Float64}
    o_ep1gce_bM::Vector{Float64}
    o_ep1gcs_bM::Vector{Float64}

    o_pay_bM::Array{Float64, 2}
    o_conm_bM::Array{Float64, 2}

    o_fstck_ub::Array{Float64, 2}
    
    t_ret_c_bM::Array{Float64, 2}# 49 total retirement cost big-M
    t_loan_bM::Array{Float64, 2}# 50 total loan (for retirement) big-M
    ##
    r_loan0::Vector{Float64} # 83
    discount::Matrix{Float64} # 84

    demand::Matrix{Float64} # 85
    co2_budget::Matrix{Float64} # 86
    GcI::Array{Float64, 3}  # 87
end


function write_params(p::params, xlsxfname::String)
    n_periods = p.n_periods
    n_subperiods = p.n_subperiods
    n_loc = p.n_location
    n_rtft = p.n_rtft
    n_new = p.n_new
    n_fu = p.n_fu
    n_fstck = p.n_fstck
    yr_subperiod = p.yr_subperiod

    XLSX.openxlsx(xlsxfname, mode="w") do xf

        # n_periods::Int64 # 0
        # n_subperiods::Int64 #
        # n_loc::Int64 # 1
        # n_rtft::Int64 # 2
        # n_new::Int64 # 3
        # n_fu::Int64 # 4
        # n_fstck::Int64
        # yr_subperiod::Int64
        # y0::Int64
        # x_ub::Float64  # 7 *allocation* upper bound
        # interest::Float64
        d = DataFrame("name"=>
                      ["n_periods",
                       "n_subperiods",
                       "n_loc",
                       "n_rtft",
                       "n_new",
                       "n_fu",
                       "n_fstck",
                       "yr_subperiod",
                       "y0", 
                       "x_ub",
                       "interest"
                      ],
                      "value"=>
                      [p.n_periods,
                       p.n_subperiods,
                       p.n_location,
                       p.n_rtft,
                       p.n_new,
                       p.n_fu,
                       p.n_fstck,
                       p.yr_subperiod,
                       p.y0,
                       p.x_ub,
                       p.interest])
        sheet = xf[1]
        XLSX.writetable!(sheet, d)
        # c0::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "c0")
        d = DataFrame("c0"=>p.c0)
        XLSX.writetable!(sheet, d)
        # e_C::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_C")
        d = DataFrame("e_C"=>p.e_C)
        XLSX.writetable!(sheet, d)
        # e_c_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_c_ub")
        d = DataFrame("e_c_ub"=>p.e_c_ub)
        XLSX.writetable!(sheet, d)
        # e_loanFact::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_loanFact")
        d = DataFrame("e_loanFact"=>p.e_loanFact)
        XLSX.writetable!(sheet, d)
        # e_l_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_l_ub")
        d = DataFrame("e_l_ub"=>p.e_l_ub)
        XLSX.writetable!(sheet, d)
        # e_Ann::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_Ann")
        d = DataFrame("e_Ann"=>p.e_Ann)
        XLSX.writetable!(sheet, d)
        # e_ann_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_ann_ub")
        d = DataFrame("e_ann_ub"=>p.e_ann_ub)
        XLSX.writetable!(sheet, d)
        # e_ladd_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_ladd_ub")
        d = DataFrame("e_ladd_ub"=>p.e_ladd_ub)
        XLSX.writetable!(sheet, d)
        # e_loan_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_loan_ub")
        d = DataFrame("e_loan_ub"=>p.e_loan_ub)
        XLSX.writetable!(sheet, d)
        # e_pay_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "e_pay_ub")
        d = DataFrame("e_pay_ub"=>p.e_pay_ub)
        XLSX.writetable!(sheet, d)


        # r_c_C::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_C")
        d = DataFrame(["$(k)"=>p.r_c_C[:, k] for k in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_rhs_C::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_rhs_C")
        d = DataFrame(["$(k)"=>p.r_rhs_C[:, k] for k in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_cp_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "r_cp_ub")
        d = DataFrame("r_cp_ub"=>p.r_cp_ub)
        XLSX.writetable!(sheet, d)
        # r_cpb_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "r_cpb_ub")
        d = DataFrame("r_cpb_ub"=>p.r_cpb_ub)
        XLSX.writetable!(sheet, d)
        # r_c_H::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_H")
        d = DataFrame(["$(k)"=>p.r_c_H[:, k] for k in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_rhs_H::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_rhs_H")
        d = DataFrame(["$(k)"=>p.r_rhs_H[:, k] for k in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_eh_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "r_eh_ub")
        d = DataFrame("r_eh_ub"=>p.r_eh_ub)
        XLSX.writetable!(sheet, d)
        # r_c_Hfac::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_Hfac")
        d = DataFrame(["$(k)"=>p.r_c_Hfac[:, k] for k in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_c_Helec::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_Helec")
        d = DataFrame(["$(k)"=>p.r_c_Helec[:, k] for k in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_c_F::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "r_c_F")
        d = DataFrame(["$((f,r))"=>p.r_c_F[:, f, r] 
                       for r in 1:n_rtft
                       for f in 1:n_fu ])
        XLSX.writetable!(sheet, d)
        # r_rhs_F::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "r_rhs_F")
        d = DataFrame(["$((f,r))"=>p.r_rhs_F[:, f, r] 
                       for r in 1:n_rtft
                       for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # r_ehf_ub::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_ehf_ub")
        d = DataFrame(["$((fu,))"=>p.r_ehf_ub[:, fu] for fu in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # r_c_U::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_U")
        d = DataFrame(["$(r)"=>p.r_c_U[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_rhs_U::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_rhs_U")
        d = DataFrame(["$(r)"=>p.r_rhs_U[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_c_UonSite::Array{Float64, 4}
        sheet = XLSX.addsheet!(xf, "r_c_UonSite")
        ruonsite = [[reshape(p.r_c_UonSite[:,:,l,r]', p.n_periods*p.n_subperiods)
                    for l in 1:n_loc] for r in 1:n_rtft]
        d = DataFrame(["$((l,r))"=> ruonsite[r][l] 
                       for l in 1:n_loc for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_c_Ufac::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_Ufac")
        d = DataFrame(["$(r)"=>p.r_c_Ufac[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_u_ub::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_u_bM")
        d = DataFrame("r_u_ub"=>p.r_u_ub[:, 1])
        XLSX.writetable!(sheet, d)
        # r_c_cp_e::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_cp_e")
        d = DataFrame(["$(r)"=>p.r_c_cp_e[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_rhs_cp_e::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_rhs_cp_e")
        d = DataFrame(["$(r)"=>p.r_rhs_cp_e[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_cp_e_ub::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "r_cp_e_ub")
        d = DataFrame("r_cp_e_ub"=>p.r_cp_e_ub[:, 1])
        XLSX.writetable!(sheet, d)
        # r_c_Fe::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_Fe")
        d = DataFrame(["$(r)"=>p.r_c_Fe[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_c_Fgenf::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "r_c_Fgenf")
        d = DataFrame(["$((f,r))"=>p.r_c_Fgenf[:, f, r] 
                       for r in 1:n_rtft
                       for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # r_u_ehf_ub::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_u_ehf_ub")
        d = DataFrame(["$((fu,))"=>p.r_u_ehf_ub[:, fu] for fu in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # r_c_Hr::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "r_c_Hr")
        d = DataFrame(["$((f,r))"=>p.r_c_Hr[:, f, r] 
                       for r in 1:n_rtft
                       for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # r_fu_e_ub::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "r_fu_e_ub")
        d = DataFrame("r_fu_e_ub"=>p.r_fu_e_ub)
        XLSX.writetable!(sheet, d)
        # r_u_fu_e_ub::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "r_u_fu_e_ub")
        d = DataFrame("r_u_fu_e_ub"=>p.r_u_fu_e_ub)
        XLSX.writetable!(sheet, d)
        # r_ep0_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "r_ep0_ub")
        d = DataFrame("r_ep0_ub"=>p.r_ep0_ub)
        XLSX.writetable!(sheet, d)
        # r_chi::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_chi")
        d = DataFrame(["$(r)"=>p.r_chi[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_ep1ge_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "r_ep1ge_ub")
        d = DataFrame("r_ep1ge_ub"=>p.r_ep1ge_ub)
        XLSX.writetable!(sheet, d)
        # r_sigma::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_sigma")
        d = DataFrame(["$(r)"=>p.r_sigma[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_ep1gce_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "r_ep1gce_ub")
        d = DataFrame("r_ep1gce_ub"=>p.r_ep1gce_ub)
        XLSX.writetable!(sheet, d)
        # r_ep1gcs_ub::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "r_ep1gcs_ub")
        d = DataFrame("r_ep1gcs_ub"=>p.r_ep1gcs_ub)
        XLSX.writetable!(sheet, d)
        # r_c_Onm::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_c_Onm")
        d = DataFrame(["$(r)"=>p.r_c_Onm[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_rhs_Onm::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "r_rhs_Onm")
        d = DataFrame(["$(r)"=>p.r_rhs_Onm[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_conm_ub::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_conm_ub")
        d = DataFrame("r_conm_ub"=>p.r_conm_ub[:, 1])
        XLSX.writetable!(sheet, d)
        # r_e_c_ub::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "r_e_c_ub")
        d = DataFrame("r_e_c_ub"=>p.r_e_c_ub)
        XLSX.writetable!(sheet, d)
        # r_loanFact::Array{Float64, 4}
        sheet = XLSX.addsheet!(xf, "r_loanFact")
        rloanf = [[reshape(p.r_loanFact[:, :, l, r]', p.n_periods*p.n_subperiods)
                  for l in 1:n_loc] for r in 1:n_rtft]
        d = DataFrame(["$((l,r))"=>
                       rloanf[r][l] for l in 1:n_loc for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_l0_ub::Array{Float64, 2} 
        sheet = XLSX.addsheet!(xf, "r_l0_ub")
        d = DataFrame(["$(r)"=>p.r_l0_ub[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_le_ub::Array{Float64, 2} 
        sheet = XLSX.addsheet!(xf, "r_le_ub")
        d = DataFrame(["$(r)"=>p.r_le_ub[:, r] for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_Ann::Array{Float64, 4}
        sheet = XLSX.addsheet!(xf, "r_Ann")
        rann = [[reshape(p.r_Ann[:,:,l,r]', p.n_periods*p.n_subperiods)
                 for l in 1:n_loc] for r in 1:n_rtft]
        d = DataFrame(["$((l,r))"=>
                       rann[r][l] for l in 1:n_loc for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_ann0_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_ann0_bM")
        d = DataFrame("r_ann0_bM"=>p.r_ann0_bM[:,1])
        XLSX.writetable!(sheet, d)
        # r_anne_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_anne_bM")
        d = DataFrame("r_anne_bM"=>p.r_anne_bM[:,1])
        XLSX.writetable!(sheet, d)
        # r_l0add_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_l0add_bM")
        d = DataFrame("r_l0add_bM"=>p.r_l0add_bM[:,1])
        XLSX.writetable!(sheet, d)
        # r_leadd_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_leadd_bM")
        d = DataFrame("r_leadd_bM"=>p.r_leadd_bM[:,1])
        XLSX.writetable!(sheet, d)
        # r_loan_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_loan_ub")
        d = DataFrame("r_loan_ub"=>p.r_loan_bM[:,1])
        XLSX.writetable!(sheet, d)
        # r_pay0_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_pay0_ub")
        d = DataFrame("r_pay0_ub"=>p.r_pay0_bM[:,1])
        XLSX.writetable!(sheet, d)
        # r_paye_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "r_paye_ub")
        d = DataFrame("r_paye_ub"=>p.r_paye_bM[:,1])
        XLSX.writetable!(sheet, d)
        # r_c_Fstck::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "r_c_Fstck")
        d = DataFrame(["$((f,r))"=>p.r_c_Fstck[:, r, f] 
                       for f in 1:n_fstck for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_rhs_Fstck::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "r_rhs_Fstck")
        d = DataFrame(["$((f,r))"=>p.r_rhs_Fstck[:, r, f] 
                       for f in 1:n_fstck for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # r_fstck_ub::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "r_fstck_ub")
        d = DataFrame(["$((f,r))"=>p.r_fstck_ub[:, r, f] 
                       for f in 1:n_fstck for r in 1:n_rtft])
        XLSX.writetable!(sheet, d)
        # n_cp_bM::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "n_cp_bM")
        d = DataFrame("n_cp_bM"=>p.n_cp_bM)
        XLSX.writetable!(sheet, d)
        # n_c0_bM::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "n_c0_bM")
        d = DataFrame("n_c0_bM"=>p.n_c0_bM)
        XLSX.writetable!(sheet, d)
        # n_c0_lo::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c0_lo")
        d = DataFrame(["$(n)"=>p.n_c0_lo[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_loanFact::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_loanFact")
        d = DataFrame(["$(n)"=>p.n_loanFact[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_l_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_l_bM")
        d = DataFrame("n_l_bM"=>p.n_l_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_Ann::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_Ann")
        d = DataFrame(["$(n)"=>p.n_Ann[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_ann_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_ann_bM")
        d = DataFrame("n_ann_bM"=>p.n_ann_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_ladd_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_ladd_bM")
        d = DataFrame("n_ladd_bM"=>p.n_ladd_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_loan_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_loan_bM")
        d = DataFrame("n_loan_bM"=>p.n_loan_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_pay_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_pay_bM")
        d = DataFrame("n_pay_bM"=>p.n_pay_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_c_H::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c_H")
        d = DataFrame(["$(n)"=>p.n_c_H[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_rhs_h::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_rhs_H")
        d = DataFrame(["$(n)"=>p.n_rhs_H[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_eh_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_eh_bM")
        d = DataFrame("n_eh_bM"=>p.n_eh_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_c_Hfac::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c_Hfac")
        d = DataFrame(["$(n)"=>p.n_c_Hfac[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_c_Helec::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c_Helec")
        d = DataFrame(["$(n)"=>p.n_c_Helec[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_c_F::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "n_c_F")
        d = DataFrame(["$((f,n))" => p.n_c_F[:, f, n] 
                       for n in 1:n_new
                       for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # n_rhs_F::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "n_rhs_F")
        d = DataFrame(["$((f,n))" => p.n_rhs_F[:, f, n] 
                       for n in 1:n_new 
                       for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # n_ehf_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_ehf_bM")
        d = DataFrame(["$((f,))"=>p.n_ehf_bM[:, f] for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # n_c_U::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c_U")
        d = DataFrame(["$(n)"=>p.n_c_U[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_rhs_U::Matrix{Float64} # 68
        sheet = XLSX.addsheet!(xf, "n_rhs_U")
        d = DataFrame(["$(n)"=>p.n_rhs_U[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_c_UonSite::Array{Float64, 4}
        sheet = XLSX.addsheet!(xf, "n_c_UonSite")
        nuonsite = [[reshape(p.n_c_UonSite[:, :, l, n]',
                             p.n_periods*p.n_subperiods)
                     for l in 1:n_loc] for n in 1:n_new]
        d = DataFrame(["$((l,n))"=> nuonsite[n][l] 
                       for l in 1:n_loc for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_c_Ufac::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c_Ufac")
        d = DataFrame(["$(n)"=>p.n_c_Ufac[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_u_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_u_bM")
        d = DataFrame("n_u_bM"=>p.n_u_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_c_cp_e::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c_cp_e")
        d = DataFrame(["$(n)"=>p.n_c_cp_e[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_rhs_cp_e::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_rhs_cp_e")
        d = DataFrame(["$(n)"=>p.n_rhs_cp_e[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_cp_e_ub::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_cp_e_ub")
        d = DataFrame("n_cp_e_ub"=>p.n_cp_e_ub[:, 1])
        XLSX.writetable!(sheet, d)
        # n_c_Fe::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c_Fe")
        d = DataFrame(["$(n)"=>p.n_c_Fe[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_c_Fgenf::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "n_c_Fgenf")
        d = DataFrame(["$((f,n))" => p.n_c_Fgenf[:, f, n] 
                       for n in 1:n_new
                       for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # n_u_ehf_ub::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "n_u_ehf_ub")
        d = DataFrame(["$((f,))"=>p.n_u_ehf_ub[:, f] for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # n_c_Hr::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "n_c_Hr")
        d = DataFrame(["$((f,n))" => p.n_c_Hr[:, f, n] 
                       for n in 1:n_new
                       for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # n_fu_e_ub::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "n_fu_e_ub")
        d = DataFrame("n_fu_e_ub"=>p.n_fu_e_ub)
        XLSX.writetable!(sheet, d)
        # n_u_fu_e_ub::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "n_u_fu_e_ub")
        d = DataFrame("n_u_fu_e_ub"=>p.n_u_fu_e_ub)
        XLSX.writetable!(sheet, d)
        # n_ep0_bM::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "n_ep0_bM")
        d = DataFrame("n_ep0_bM"=>p.n_ep0_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_chi::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_chi")
        d = DataFrame(["$(n)"=>p.n_chi[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_ep1ge_bM::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "n_ep1ge_bM")
        d = DataFrame("n_ep1ge_bM"=>p.n_ep1ge_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_sigma::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_sigma")
        d = DataFrame(["$(n)"=>p.n_sigma[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_ep1gce_bM::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "n_ep1gce_bM")
        d = DataFrame("n_ep1gce_bM"=>p.n_ep1gce_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_ep1gcs_bM::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "n_ep1gcs_bM")
        d = DataFrame("n_ep1gcs_bM"=>p.n_ep1gcs_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # n_c_Onm::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_c_Onm")
        d = DataFrame(["$(n)"=>p.n_c_Onm[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_rhs_Onm::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "n_rhs_Onm")
        d = DataFrame(["$(n)"=>p.n_rhs_Onm[:, n] for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_conm_bM::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "n_conm_bM")
        d = DataFrame("n_conm_bM"=>p.n_conm_bM)
        XLSX.writetable!(sheet, d)
        # n_c_Fstck::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "n_c_Fstck")
        d = DataFrame(["$((f,n))"=>p.n_c_Fstck[:, n, f] 
                       for f in 1:n_fstck for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_rhs_Fstck::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "n_rhs_Fstck")
        d = DataFrame(["$((f,n))"=>p.n_rhs_Fstck[:, n, f] 
                       for f in 1:n_fstck for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # n_fstck_ub::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "n_fstck_ub")
        d = DataFrame(["$((f,n))"=>p.n_fstck_ub[:, n, f] 
                       for f in 1:n_fstck for n in 1:n_new])
        XLSX.writetable!(sheet, d)
        # c_u_cost::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "c_u_cost")
        cucost = [reshape(p.c_u_cost[:, : , l]', n_periods*n_subperiods)
                 for l in 1:n_loc]
        d = DataFrame(["$(l)"=>cucost[l] for l in 1:n_loc])
        XLSX.writetable!(sheet, d)
        # c_ehf_cost::Array{Float64, 4}
        sheet = XLSX.addsheet!(xf, "c_ehf_cost")
        cehfc = [[reshape(p.c_ehf_cost[:,:,l,f]', n_periods*n_subperiods) 
                 for l in 1:n_loc] for f in 1:n_fu]
        d = DataFrame(["$((l,f))"=>cehfc[f][l] 
                       for l in 1:n_loc for f in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # c_cts_cost::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "c_cts_cost")
        d = DataFrame("c_cts_cost" => p.c_cts_cost)
        XLSX.writetable!(sheet, d)
        # o_cp_ub::Array{Float64, 1}
        sheet = XLSX.addsheet!(xf, "o_cp_ub")
        d = DataFrame("o_cp_ub" => p.o_cp_ub[:, 1])
        XLSX.writetable!(sheet, d)
        # o_cp_e_bM::Float64
        sheet = XLSX.addsheet!(xf, "o_cp_e_bM")
        d = DataFrame("o_cp_e_bM" => p.o_cp_e_bM)
        XLSX.writetable!(sheet, d)
        # o_u_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "o_u_bM")
        d = DataFrame("o_u_bM" => p.o_u_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # o_ehf_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "o_ehf_bM")
        d = DataFrame(["$((fu,))"=>p.o_ehf_bM[:, fu] for fu in 1:n_fu])
        XLSX.writetable!(sheet, d)
        # o_ep0_bM::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "o_ep0_bM")
        d = DataFrame("o_ep0_bM" => p.o_ep0_bM)
        XLSX.writetable!(sheet, d)
        # o_ep1ge_bM::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "o_ep1ge_bM")
        d = DataFrame("o_ep1ge_bM" => p.o_ep1ge_bM)
        XLSX.writetable!(sheet, d)
        # o_ep1gce_bM::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "o_ep1gce_bM")
        d = DataFrame("o_ep1gce_bM" => p.o_ep1gce_bM)
        XLSX.writetable!(sheet, d)
        # o_ep1gcs_bM::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "o_ep1gcs_bM")
        d = DataFrame("o_ep1gcs_bM" => p.o_ep1gcs_bM)
        XLSX.writetable!(sheet, d)
        # o_pay_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "o_pay_bM")
        d = DataFrame("o_pay_bM" => p.o_pay_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # o_conm_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "o_conm_bM")
        d = DataFrame("o_conm_bM" => p.o_conm_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # o_fstck_ub::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "o_fstck_ub")
        d = DataFrame(["$(f)"=>p.o_fstck_ub[:, f] for f in 1:n_fstck])
        XLSX.writetable!(sheet, d)
        # t_ret_c_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "t_ret_c_bM")
        d = DataFrame("t_ret_c_bM" => p.t_ret_c_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # t_loan_bM::Array{Float64, 2}
        sheet = XLSX.addsheet!(xf, "t_loan_bM")
        d = DataFrame("t_loan_bM" => p.t_loan_bM[:, 1])
        XLSX.writetable!(sheet, d)
        # r_loan0::Vector{Float64}
        sheet = XLSX.addsheet!(xf, "r_loan0")
        d = DataFrame("r_loan0" => p.r_loan0[:, 1])
        XLSX.writetable!(sheet, d)
        # discount::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "discount")
        discount = reshape(p.discount', p.n_periods*p.n_subperiods)
        d = DataFrame("discount" => discount)
        XLSX.writetable!(sheet, d)
        # demand::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "demand")
        demand = reshape(p.demand', p.n_periods*p.n_subperiods)
        d = DataFrame("demand" => demand)
        XLSX.writetable!(sheet, d)
        # co2_budget::Matrix{Float64}
        sheet = XLSX.addsheet!(xf, "co2_budget")
        co2_budget = reshape(p.co2_budget', p.n_periods*p.n_subperiods)
        d = DataFrame("co2_budget" => co2_budget)
        XLSX.writetable!(sheet, d)
        # GcI::Array{Float64, 3}
        sheet = XLSX.addsheet!(xf, "GcI")
        
        GcI = [reshape(p.GcI[:,:,l]', p.n_periods*p.n_subperiods)
               for l in 1:n_loc
              ]
        #GcI = reshape(p.GcI, p.n_periods*p.n_subperiods, n_loc)
        d = DataFrame(["$(l)" => GcI[l] for l in 1:n_loc])
        XLSX.writetable!(sheet, d)
    end
end

function read_params(fname)
    xf = XLSX.readxlsx(fname)
    sh = xf[1]
    #
    n_periods = sh[2, 2]
    n_periods = trunc(Int64, n_periods)
    n_subperiods = sh[3, 2]
    n_subperiods = trunc(Int64, n_subperiods)
    n_loc = sh[4, 2]
    n_loc = trunc(Int64, n_loc)
    n_rtft = sh[5, 2]
    n_rtft= trunc(Int64, n_rtft)
    n_new = sh[6, 2]
    n_new = trunc(Int64, n_new)
    n_fu = sh[7, 2]
    n_fu = trunc(Int64, n_fu)
    n_fstck = sh[8, 2]
    n_fstck= trunc(Int64, n_fstck)
    yr_subperiod = sh[9, 2]
    yr_subperiod = trunc(Int64, yr_subperiod)
    y0 = sh[10, 2]
    y0 = trunc(Int64, y0)
    x_ub = sh[11, 2]
    interest = sh[12, 2]

    # c0::Vector{Float64}
    sh = xf["c0"]
    c0 = sh[2:n_loc+1, 1]
    c0 = vec(c0)
    c0 = convert(Vector{Float64}, c0)
    # e_C::Vector{Float64}
    sh = xf["e_C"]
    e_C = sh[2:n_loc+1, 1]
    e_C = vec(e_C)
    e_C = convert(Vector{Float64}, e_C) 
    # e_c_ub::Vector{Float64}
    sh = xf["e_c_ub"]
    e_c_ub = sh[2:n_loc+1, 1]
    e_c_ub = vec(e_c_ub)
    e_c_ub = convert(Vector{Float64}, e_c_ub)
    # e_loanFact::Vector{Float64}
    sh = xf["e_loanFact"]
    e_loanFact = sh[2:n_loc+1, 1]
    e_loanFact = vec(e_loanFact)
    e_loanFact = convert(Vector{Float64}, e_loanFact)
    # e_l_ub::Vector{Float64}
    sh = xf["e_l_ub"]
    e_l_ub = sh[2:n_loc+1, 1]
    e_l_ub = vec(e_l_ub)
    e_l_ub = convert(Vector{Float64}, e_l_ub)
    # e_Ann::Vector{Float64}
    sh = xf["e_Ann"]
    e_Ann = sh[2:n_loc+1, 1]
    e_Ann = vec(e_Ann)
    e_Ann = convert(Vector{Float64}, e_Ann)
    # e_ann_ub::Vector{Float64}
    sh = xf["e_ann_ub"]
    e_ann_ub = sh[2:n_loc+1, 1]
    e_ann_ub = vec(e_ann_ub)
    e_ann_ub = convert(Vector{Float64}, e_ann_ub)
    # e_ladd_ub::Vector{Float64}
    sh = xf["e_ladd_ub"]
    e_ladd_ub = sh[2:n_loc+1, 1]
    e_ladd_ub = vec(e_ladd_ub)
    e_ladd_ub = convert(Vector{Float64}, e_ladd_ub)
    # e_loan_ub::Vector{Float64}
    sh = xf["e_loan_ub"]
    e_loan_ub = sh[2:n_loc+1, 1]
    e_loan_ub = vec(e_loan_ub)
    e_loan_ub = convert(Vector{Float64}, e_loan_ub)
    # e_pay_ub::Vector{Float64}
    sh = xf["e_pay_ub"]
    e_pay_ub = sh[2:n_loc+1, 1]
    e_pay_ub = vec(e_pay_ub)
    e_pay_ub = convert(Vector{Float64}, e_pay_ub)
    # r_c_C::Matrix{Float64}
    sh = xf["r_c_C"]
    r_c_C = sh[2:n_loc+1, 1:n_rtft]
    r_c_C = convert(Matrix{Float64}, r_c_C)
    # r_rhs_C::Matrix{Float64}
    sh = xf["r_rhs_C"]
    r_rhs_C = sh[2:n_loc+1, 1:n_rtft]
    r_rhs_C = convert(Matrix{Float64}, r_rhs_C)
    # r_cp_ub::Vector{Float64}
    sh = xf["r_cp_ub"]
    r_cp_ub = sh[2:n_loc+1, 1]
    r_cp_ub = vec(r_cp_ub)
    r_cp_ub = convert(Vector{Float64}, r_cp_ub)
    # r_cpb_ub::Vector{Float64}
    sh = xf["r_cpb_ub"]
    r_cpb_ub = sh[2:n_loc+1, 1]
    r_cpb_ub = vec(r_cpb_ub)
    r_cpb_ub = convert(Vector{Float64}, r_cpb_ub)
    # r_c_H::Matrix{Float64}
    sh = xf["r_c_H"]
    r_c_H = sh[2:n_loc+1, 1:n_rtft]
    r_c_H = convert(Matrix{Float64}, r_c_H)
    # r_rhs_H::Matrix{Float64}
    sh = xf["r_rhs_H"]
    r_rhs_H = sh[2:n_loc+1, 1:n_rtft]
    r_rhs_H = convert(Matrix{Float64}, r_rhs_H)
    # r_eh_ub::Vector{Float64}
    sh = xf["r_eh_ub"]
    r_eh_ub = sh[2:n_loc+1, 1]
    r_eh_ub = vec(r_eh_ub)
    r_eh_ub = convert(Vector{Float64}, r_eh_ub)
    # r_c_Hfac::Matrix{Float64}
    sh = xf["r_c_Hfac"]
    r_c_Hfac = sh[2:n_loc+1, 1:n_rtft]
    r_c_Hfac = convert(Matrix{Float64}, r_c_Hfac)
    # r_c_Helec::Matrix{Float64}
    sh = xf["r_c_Helec"]
    r_c_Helec = sh[2:n_loc+1, 1:n_rtft]
    r_c_Helec = convert(Matrix{Float64}, r_c_Helec)
    # r_c_F::Array{Float64, 3}
    sh = xf["r_c_F"]
    r_c_F = zeros(n_loc, n_fu, n_rtft)
    for r in 1:n_rtft
        for f in 1:n_fu
            col = f+(n_fu*(r-1))
            r_c_F[:, f, r] = sh[2:n_loc+1, col]
        end
    end
    r_c_F = convert(Array{Float64, 3}, r_c_F)
    # r_rhs_F::Array{Float64, 3}
    sh = xf["r_rhs_F"]
    r_rhs_F = zeros(n_loc, n_fu, n_rtft)
    for r in 1:n_rtft
        for f in 1:n_fu
            col = f+(n_fu*(r-1))
            r_rhs_F[:, f, r] = sh[2:n_loc+1, col]
        end
    end
    r_rhs_F = convert(Array{Float64, 3}, r_rhs_F)
    # r_ehf_ub::Matrix{Float64}
    sh = xf["r_ehf_ub"]
    r_ehf_ub = sh[2:n_loc+1, 1:n_fu]
    r_ehf_ub = convert(Matrix{Float64}, r_ehf_ub)
    # r_c_U::Matrix{Float64}
    sh = xf["r_c_U"]
    r_c_U = sh[2:n_loc+1, 1:n_rtft]
    r_c_U = convert(Matrix{Float64}, r_c_U)
    # r_rhs_U::Matrix{Float64}
    sh = xf["r_rhs_U"]
    r_rhs_U = sh[2:n_loc+1, 1:n_rtft]
    r_rhs_U = convert(Matrix{Float64}, r_rhs_U)
    # r_c_UonSite::Array{Float64, 4}
    sh = xf["r_c_UonSite"]
    r_c_UonSite = ones(n_periods,
                       n_subperiods,
                       n_loc,
                       n_rtft)
    for l in 1:n_loc
        for r in 1:n_rtft
            col = r + n_rtft * (l-1)
            for i in 1:n_periods
                for j in 1:n_subperiods
                    row = j + n_subperiods * (i-1) 
                    r_c_UonSite[i, j, l, r] = sh[row+1, col]
                end
            end
        end
    end
    r_c_UonSite = convert(Array{Float64, 4}, r_c_UonSite)
    # r_c_Ufac::Matrix{Float64}
    sh = xf["r_c_Ufac"]
    r_c_Ufac = sh[2:n_loc+1, 1:n_rtft]
    r_c_Ufac = convert(Matrix{Float64}, r_c_Ufac)
    # r_u_ub::Array{Float64, 2}
    sh = xf["r_u_bM"]
    r_u_ub = sh[2:n_loc+1, 1]
    r_u_ub = convert(Array{Float64, 2}, r_u_ub)
    # r_c_cp_e::Matrix{Float64}
    sh = xf["r_c_cp_e"]
    r_c_cp_e = sh[2:n_loc+1, 1:n_rtft]
    r_c_cp_e = convert(Matrix{Float64}, r_c_cp_e)
    # r_rhs_cp_e::Matrix{Float64}
    sh = xf["r_rhs_cp_e"]
    r_rhs_cp_e = sh[2:n_loc+1, 1:n_rtft]
    r_rhs_cp_e = convert(Matrix{Float64}, r_rhs_cp_e)
    # r_cp_e_ub::Array{Float64, 1}
    sh = xf["r_cp_e_ub"]
    r_cp_e_ub = sh[2:n_loc+1, 1]
    r_cp_e_ub = vec(r_cp_e_ub)
    r_cp_e_ub = convert(Array{Float64, 1}, r_cp_e_ub)
    # r_c_Fe::Matrix{Float64}
    sh = xf["r_c_Fe"]
    r_c_Fe = sh[2:n_fu+1, 1:n_rtft]
    r_c_Fe = convert(Matrix{Float64}, r_c_Fe)
    # r_c_Fgenf::Array{Float64, 3}
    sh = xf["r_c_Fgenf"]
    r_c_Fgenf = zeros(n_loc, n_fu, n_rtft)
    for r in 1:n_rtft
        for f in 1:n_fu
            col = f + n_fu*(r-1)
            r_c_Fgenf[:, f, r] = sh[2:n_loc+1, col]
        end
    end
    r_c_Fgenf = convert(Array{Float64, 3}, r_c_Fgenf)
    # r_u_ehf_ub::Array{Float64, 2}
    sh = xf["r_u_ehf_ub"]
    r_u_ehf_ub = sh[2:n_loc+1, 1:n_fu]
    r_u_ehf_ub = convert(Array{Float64, 2}, r_u_ehf_ub)
    # r_c_Hr::Array{Float64, 3}
    sh = xf["r_c_Hr"]
    r_c_Hr = zeros(n_loc, n_fu, n_rtft)
    for r in 1:n_rtft
        for f in 1:n_fu
            col = f + n_fu*(r-1)
            r_c_Hr[:, f, r] = sh[2:n_loc+1, col]
        end
    end
    r_c_Hr = convert(Array{Float64, 3}, r_c_Hr)
    # r_fu_e_ub::Array{Float64, 1}
    sh = xf["r_fu_e_ub"]
    r_fu_e_ub = sh[2:n_loc+1, 1]
    r_fu_e_ub = vec(r_fu_e_ub)
    r_fu_e_ub = convert(Array{Float64, 1}, r_fu_e_ub)
    # r_u_fu_e_ub::Array{Float64, 1}
    sh = xf["r_u_fu_e_ub"]
    r_u_fu_e_ub = sh[2:n_loc+1, 1]
    r_u_fu_e_ub = vec(r_u_fu_e_ub)
    r_u_fu_e_ub = convert(Array{Float64, 1}, r_u_fu_e_ub)
    # r_ep0_ub::Vector{Float64}
    sh = xf["r_ep0_ub"]
    r_ep0_ub = sh[2:n_loc+1, 1]
    r_ep0_ub = vec(r_ep0_ub)
    r_ep0_ub = convert(Vector{Float64}, r_ep0_ub)
    # r_chi::Matrix{Float64}
    sh = xf["r_chi"]
    r_chi = sh[2:n_loc+1, 1:n_rtft]
    r_chi = convert(Matrix{Float64}, r_chi)
    # r_ep1ge_ub::Vector{Float64}
    sh = xf["r_ep1ge_ub"]
    r_ep1ge_ub = sh[2:n_loc+1, 1]
    r_ep1ge_ub = vec(r_ep1ge_ub)
    r_ep1ge_ub = convert(Vector{Float64}, r_ep1ge_ub)
    # r_sigma::Matrix{Float64}
    sh = xf["r_sigma"]
    r_sigma = sh[2:n_loc+1, 1:n_rtft]
    r_sigma = convert(Matrix{Float64}, r_sigma)
    # r_ep1gce_ub::Vector{Float64}
    sh = xf["r_ep1gce_ub"]
    r_ep1gce_ub = sh[2:n_loc+1, 1]
    r_ep1gce_ub = vec(r_ep1gce_ub)
    r_ep1gce_ub = convert(Vector{Float64}, r_ep1gce_ub)
    # r_ep1gcs_ub::Vector{Float64}
    sh = xf["r_ep1gcs_ub"]
    r_ep1gcs_ub = sh[2:n_loc+1, 1]
    r_ep1gcs_ub = vec(r_ep1gcs_ub)
    r_ep1gcs_ub = convert(Vector{Float64}, r_ep1gcs_ub)
    # r_c_Onm::Matrix{Float64}
    sh = xf["r_c_Onm"]
    r_c_Onm = sh[2:n_loc+1, 1:n_rtft]
    r_c_Onm = convert(Matrix{Float64}, r_c_Onm)
    # r_rhs_Onm::Matrix{Float64}
    sh = xf["r_rhs_Onm"]
    r_rhs_Onm = sh[2:n_loc+1, 1:n_rtft]
    r_rhs_Onm = convert(Matrix{Float64}, r_rhs_Onm)
    # r_conm_ub::Array{Float64, 2}
    sh = xf["r_conm_ub"]
    r_conm_ub = sh[2:n_loc+1, 1]
    r_conm_ub = convert(Array{Float64, 2}, r_conm_ub)
    # r_e_c_ub::Array{Float64, 1}
    sh = xf["r_e_c_ub"]
    r_e_c_ub = sh[2:n_loc+1, 1]
    r_e_c_ub = vec(r_e_c_ub)
    r_e_c_ub = convert(Array{Float64, 1}, r_e_c_ub)
    # r_loanFact::Array{Float64, 4}
    sh = xf["r_loanFact"]
    r_loanFact = zeros(n_periods, n_subperiods, n_loc, n_rtft)
    for l in 1:n_loc
        for r in 1:n_rtft
            col = r + n_rtft * (l-1)
            for i in 1:n_periods
                for j in 1:n_subperiods
                    row = j + n_subperiods * (i-1) 
                    r_loanFact[i, j, l, r] = sh[row+1, col]
                end
            end
        end
    end
    r_loanFact = convert(Array{Float64, 4}, r_loanFact)
    # r_l0_ub::Array{Float64, 2}
    sh = xf["r_l0_ub"]
    r_l0_ub = sh[2:n_loc+1, 1:n_rtft]
    r_l0_ub = convert(Array{Float64, 2}, r_l0_ub)
    # r_le_ub::Array{Float64, 2}
    sh = xf["r_le_ub"]
    r_le_ub = sh[2:n_loc+1, 1:n_rtft]
    r_le_ub = convert(Array{Float64, 2}, r_le_ub)
    # r_Ann::Array{Float64, 4}
    sh = xf["r_Ann"]
    r_Ann = zeros(n_periods, n_subperiods, n_loc, n_rtft)
    for l in 1:n_loc
        for r in 1:n_rtft
            col = r + n_rtft * (l-1)
            for i in 1:n_periods
                for j in 1:n_subperiods
                    row = j + n_subperiods * (i-1) 
                    r_Ann[i, j, l, r] = sh[row+1, col]
                end
            end
        end
    end
    r_Ann = convert(Array{Float64, 4}, r_Ann)
    # r_ann0_bM::Array{Float64, 2}
    sh = xf["r_ann0_bM"]
    r_ann0_bM = sh[2:n_loc+1, 1]
    r_ann0_bM = convert(Array{Float64, 2}, r_ann0_bM)
    # r_anne_bM::Array{Float64, 2}
    sh = xf["r_anne_bM"]
    r_anne_bM = sh[2:n_loc+1, 1]
    r_anne_bM = convert(Array{Float64, 2}, r_anne_bM)
    # r_l0add_bM::Array{Float64, 2}
    sh = xf["r_l0add_bM"]
    r_l0add_bM = sh[2:n_loc+1, 1]
    r_l0add_bM = convert(Array{Float64, 2}, r_l0add_bM)
    # r_leadd_bM::Array{Float64, 2}
    sh = xf["r_leadd_bM"]
    r_leadd_bM = sh[2:n_loc+1, 1]
    r_leadd_bM = convert(Array{Float64, 2}, r_leadd_bM)
    # r_loan_bM::Array{Float64, 2}
    sh = xf["r_loan_ub"]
    r_loan_bM = sh[2:n_loc+1, 1]
    r_loan_bM = convert(Array{Float64, 2}, r_loan_bM)
    # r_pay0_bM::Array{Float64, 2}
    sh = xf["r_pay0_ub"]
    r_pay0_bM = sh[2:n_loc+1, 1]
    r_pay0_bM = convert(Array{Float64, 2}, r_pay0_bM)
    # r_paye_bM::Array{Float64, 2}
    sh = xf["r_paye_ub"]
    r_paye_bM = sh[2:n_loc+1, 1]
    r_paye_bM = convert(Array{Float64, 2}, r_paye_bM)
    # r_c_Fstck::Array{Float64, 3}
    sh = xf["r_c_Fstck"]
    r_c_Fstck = ones(n_loc, n_rtft, n_fstck)
    for r in 1:n_rtft
        for f in 1:n_fstck
            col = f + n_fstck*(r-1)
            r_c_Fstck[:, r, f] = sh[2:n_loc+1, col]
        end
    end
    r_c_Fstck = convert(Array{Float64, 3}, r_c_Fstck)
    # r_rhs_Fstck::Array{Float64, 3}
    sh = xf["r_rhs_Fstck"]
    r_rhs_Fstck = ones(n_loc, n_rtft, n_fstck)
    for r in 1:n_rtft
        for f in 1:n_fstck
            col = f + n_fstck*(r-1)
            r_rhs_Fstck[:, r, f] = sh[2:n_loc+1, col]
        end
    end
    r_rhs_Fstck = convert(Array{Float64, 3}, r_rhs_Fstck)
    # r_fstck_ub::Array{Float64, 3}
    sh = xf["r_fstck_ub"]
    r_fstck_ub = ones(n_loc, n_rtft, n_fstck)
    for r in 1:n_rtft
        for f in 1:n_fstck
            col = f + n_fstck*(r-1)
            r_fstck_ub[:, r, f] = sh[2:n_loc+1, col]
        end
    end
    r_fstck_ub = convert(Array{Float64, 3}, r_fstck_ub)
    # n_cp_bM::Vector{Float64}
    sh = xf["n_cp_bM"]
    n_cp_bM = sh[2:n_loc+1, 1]
    n_cp_bM = vec(n_cp_bM)
    n_cp_bM = convert(Vector{Float64}, n_cp_bM)
    # n_c0_bM::Vector{Float64}
    sh = xf["n_c0_bM"]
    n_c0_bM = sh[2:n_loc+1, 1]
    n_c0_bM = vec(n_c0_bM)
    n_c0_bM = convert(Vector{Float64}, n_c0_bM)
    # n_c0_lo::Matrix{Float64}
    sh = xf["n_c0_lo"]
    n_c0_lo = sh[2:n_loc+1, 1:n_new]
    n_c0_lo = convert(Matrix{Float64}, n_c0_lo)
    # n_loanFact::Matrix{Float64}
    sh = xf["n_loanFact"]
    n_loanFact = sh[2:n_loc+1, 1:n_new]
    n_loanFact = convert(Matrix{Float64}, n_loanFact)
    # n_l_bM::Array{Float64, 2}
    sh = xf["n_l_bM"]
    n_l_bM = sh[2:n_loc+1, 1]
    n_l_bM = convert(Array{Float64, 2}, n_l_bM)
    # n_Ann::Matrix{Float64}
    sh = xf["n_Ann"]
    n_Ann = sh[2:n_loc+1, 1:n_new]
    n_Ann = convert(Matrix{Float64}, n_Ann)
    # n_ann_bM::Array{Float64, 2}
    sh = xf["n_ann_bM"]
    n_ann_bM = sh[2:n_loc+1, 1]
    n_ann_bM = convert(Array{Float64, 2}, n_ann_bM)
    # n_ladd_bM::Array{Float64, 2}
    sh = xf["n_ladd_bM"]
    n_ladd_bM = sh[2:n_loc+1, 1]
    n_ladd_bM = convert(Array{Float64, 2}, n_ladd_bM)
    # n_loan_bM::Array{Float64, 2}
    sh = xf["n_loan_bM"]
    n_loan_bM = sh[2:n_loc+1, 1]
    n_loan_bM = convert(Array{Float64, 2}, n_loan_bM)
    # n_pay_bM::Array{Float64, 2}
    sh = xf["n_pay_bM"]
    n_pay_bM = sh[2:n_loc+1, 1]
    n_pay_bM = convert(Array{Float64, 2}, n_pay_bM)
    # n_c_H::Matrix{Float64}
    sh = xf["n_c_H"]
    n_c_H = sh[2:n_loc+1, 1:n_new]
    n_c_H = convert(Matrix{Float64}, n_c_H)
    # n_rhs_H::Matrix{Float64}
    sh = xf["n_rhs_H"]
    n_rhs_H = sh[2:n_loc+1, 1:n_new]
    n_rhs_H = convert(Matrix{Float64}, n_rhs_H)
    # n_eh_bM::Array{Float64, 2}
    sh = xf["n_eh_bM"]
    n_eh_bM = sh[2:n_loc+1, 1]
    n_eh_bM = convert(Array{Float64, 2}, n_eh_bM)
    # n_c_Hfac::Matrix{Float64}
    sh = xf["n_c_Hfac"]
    n_c_Hfac = sh[2:n_loc+1, 1:n_new]
    n_c_Hfac = convert(Matrix{Float64}, n_c_Hfac)
    # n_c_Helec::Matrix{Float64}
    sh = xf["n_c_Helec"]
    n_c_Helec = sh[2:n_loc+1, 1:n_new]
    n_c_Helec = convert(Matrix{Float64}, n_c_Helec)
    # n_c_F::Array{Float64, 3}
    sh = xf["n_c_F"]
    n_c_F = zeros(n_loc, n_fu, n_new)
    for r in 1:n_new
        for f in 1:n_fu
            col = f+(n_fu*(r-1))
            n_c_F[:, f, r] = sh[2:n_loc+1, col]
        end
    end
    n_c_F = convert(Array{Float64, 3}, n_c_F)
    # n_rhs_F::Array{Float64, 3}
    sh = xf["n_rhs_F"]
    n_rhs_F = zeros(n_loc, n_fu, n_new)
    for r in 1:n_new
        for f in 1:n_fu
            col = f+(n_fu*(r-1))
            n_rhs_F[:, f, r] = sh[2:n_loc+1, col]
        end
    end
    n_rhs_F = convert(Array{Float64, 3}, n_rhs_F)
    # n_ehf_bM::Array{Float64, 2}
    sh = xf["n_ehf_bM"]
    n_ehf_bM = sh[2:n_loc+1, 1:n_fu]
    n_ehf_bM = convert(Array{Float64, 2}, n_ehf_bM)
    # n_c_U::Matrix{Float64}
    sh = xf["n_c_U"]
    n_c_U = sh[2:n_loc+1, 1:n_new]
    n_c_U = convert(Matrix{Float64}, n_c_U)
    # n_rhs_U::Matrix{Float64}
    sh = xf["n_rhs_U"]
    n_rhs_U = sh[2:n_loc+1, 1:n_new]
    n_rhs_U = convert(Matrix{Float64}, n_rhs_U)
    # n_c_UonSite::Array{Float64, 4}
    sh = xf["n_c_UonSite"]
    n_c_UonSite = ones(n_periods,
                       n_subperiods,
                       n_loc,
                       n_new)
    for l in 1:n_loc
        for r in 1:n_new
            col = r + n_new * (l-1)
            for i in 1:n_periods
                for j in 1:n_subperiods
                    row = j + n_subperiods * (i-1) 
                    n_c_UonSite[i, j, l, r] = sh[row+1, col]
                end
            end
        end
    end
    n_c_UonSite = convert(Array{Float64, 4}, n_c_UonSite)
    # n_c_Ufac::Matrix{Float64}
    sh = xf["n_c_Ufac"]
    n_c_Ufac = sh[2:n_loc+1, 1:n_new]
    n_c_Ufac = convert(Matrix{Float64}, n_c_Ufac)
    # n_u_bM::Array{Float64, 2}
    sh = xf["n_u_bM"]
    n_u_bM = sh[2:n_loc+1, 1]
    n_u_bM = convert(Array{Float64, 2}, n_u_bM)
    # n_c_cp_e::Matrix{Float64}
    sh = xf["n_c_cp_e"]
    n_c_cp_e = sh[2:n_loc+1, 1:n_new]
    n_c_cp_e = convert(Matrix{Float64}, n_c_cp_e)
    # n_rhs_cp_e::Matrix{Float64}
    sh = xf["n_rhs_cp_e"]
    n_rhs_cp_e = sh[2:n_loc+1, 1:n_new]
    n_rhs_cp_e = convert(Matrix{Float64}, n_rhs_cp_e)
    # n_cp_e_ub::Array{Float64, 2}
    sh = xf["n_cp_e_ub"]
    n_cp_e_ub = sh[2:n_loc+1, 1]
    n_cp_e_ub = vec(n_cp_e_ub)
    n_cp_e_ub = convert(Array{Float64, 1}, n_cp_e_ub)
    # n_c_Fe::Matrix{Float64}
    sh = xf["n_c_Fe"]
    n_c_Fe = sh[2:n_fu+1, 1:n_new]
    n_c_Fe = convert(Matrix{Float64}, n_c_Fe)
    # n_c_Fgenf::Array{Float64, 3}
    sh = xf["n_c_Fgenf"]
    n_c_Fgenf = zeros(n_loc, n_fu, n_new)
    for r in 1:n_new
        for f in 1:n_fu
            col = f + n_fu*(r-1)
            n_c_Fgenf[:, f, r] = sh[2:n_loc+1, col]
        end
    end
    n_c_Fgenf = convert(Array{Float64, 3}, n_c_Fgenf)
    # n_u_ehf_ub::Array{Float64, 2}
    sh = xf["n_u_ehf_ub"]
    n_u_ehf_ub = sh[2:n_loc+1, 1:n_fu]
    n_u_ehf_ub = convert(Array{Float64, 2}, n_u_ehf_ub)
    # n_c_Hr::Array{Float64, 3}
    sh = xf["n_c_Hr"]
    n_c_Hr = zeros(n_loc, n_fu, n_new)
    for r in 1:n_new
        for f in 1:n_fu
            col = f + n_fu*(r-1)
            n_c_Hr[:, f, r] = sh[2:n_loc+1, col]
        end
    end
    n_c_Hr = convert(Array{Float64, 3}, n_c_Hr)
    # n_fu_e_ub::Array{Float64, 1}
    sh = xf["n_fu_e_ub"]
    n_fu_e_ub = sh[2:n_loc+1, 1]
    n_fu_e_ub = vec(n_fu_e_ub)
    n_fu_e_ub = convert(Array{Float64, 1}, n_fu_e_ub)
    # n_u_fu_e_ub::Array{Float64, 1}
    sh = xf["n_u_fu_e_ub"]
    n_u_fu_e_ub = sh[2:n_loc+1, 1]
    n_u_fu_e_ub = vec(n_u_fu_e_ub)
    n_u_fu_e_ub = convert(Array{Float64, 1}, n_u_fu_e_ub)
    # n_ep0_bM::Array{Float64, 2}
    sh = xf["n_ep0_bM"]
    n_ep0_bM = sh[2:n_loc+1, 1]
    n_ep0_bM = vec(n_ep0_bM)
    n_ep0_bM = convert(Array{Float64, 1}, n_ep0_bM)
    # n_chi::Matrix{Float64}
    sh = xf["n_chi"]
    n_chi = sh[2:n_loc+1, 1:n_new]
    n_chi = convert(Matrix{Float64}, n_chi)
    # n_ep1ge_bM::Matrix{Float64}
    sh = xf["n_ep1ge_bM"]
    n_ep1ge_bM = sh[2:n_loc+1, 1]
    n_ep1ge_bM = vec(n_ep1ge_bM)
    n_ep1ge_bM = convert(Array{Float64, 1}, n_ep1ge_bM)
    # n_sigma::Matrix{Float64}
    sh = xf["n_sigma"]
    n_sigma = sh[2:n_loc+1, 1:n_new]
    n_sigma = convert(Matrix{Float64}, n_sigma)
    # n_ep1gce_bM::Array{Float64, 2}
    sh = xf["n_ep1gce_bM"]
    n_ep1gce_bM = sh[2:n_loc+1, 1]
    n_ep1gce_bM = vec(n_ep1gce_bM)
    n_ep1gce_bM = convert(Array{Float64, 1}, n_ep1gce_bM)
    # n_ep1gcs_bM::Array{Float64, 2}
    sh = xf["n_ep1gcs_bM"]
    n_ep1gcs_bM = sh[2:n_loc+1, 1]
    n_ep1gcs_bM = vec(n_ep1gcs_bM)
    n_ep1gcs_bM = convert(Array{Float64, 1}, n_ep1gcs_bM)
    # n_c_Onm::Matrix{Float64}
    sh = xf["n_c_Onm"]
    n_c_Onm = sh[2:n_loc+1, 1:n_new]
    n_c_Onm = convert(Matrix{Float64}, n_c_Onm)
    # n_rhs_Onm::Matrix{Float64}
    sh = xf["n_rhs_Onm"]
    n_rhs_Onm = sh[2:n_loc+1, 1:n_new]
    n_rhs_Onm = convert(Matrix{Float64}, n_rhs_Onm)
    # n_conm_bM::Vector{Float64}
    sh = xf["n_conm_bM"]
    n_conm_bM = sh[2:n_loc+1, 1]
    n_conm_bM = vec(n_conm_bM) 
    n_conm_bM = convert(Vector{Float64}, n_conm_bM)
    # n_c_Fstck::Array{Float64, 3}
    sh = xf["n_c_Fstck"]
    n_c_Fstck = ones(n_loc, n_new, n_fstck)
    for r in 1:n_new
        for f in 1:n_fstck
            col = f + n_fstck*(r-1)
            n_c_Fstck[:, r, f] = sh[2:n_loc+1, col]
        end
    end
    n_c_Fstck = convert(Array{Float64, 3}, n_c_Fstck)
    # n_rhs_Fstck::Array{Float64, 3}
    sh = xf["n_rhs_Fstck"]
    n_rhs_Fstck = ones(n_loc, n_new, n_fstck)
    for r in 1:n_new
        for f in 1:n_fstck
            col = f + n_fstck*(r-1)
            n_rhs_Fstck[:, r, f] = sh[2:n_loc+1, col]
        end
    end
    n_rhs_Fstck = convert(Array{Float64, 3}, n_rhs_Fstck)
    # n_fstck_ub::Array{Float64, 3}
    sh = xf["n_fstck_ub"]
    n_fstck_ub = ones(n_loc, n_new, n_fstck)
    for r in 1:n_new
        for f in 1:n_fstck
            col = f + n_fstck*(r-1)
            n_fstck_ub[:, r, f] = sh[2:n_loc+1, col]
        end
    end
    n_fstck_ub = convert(Array{Float64, 3}, n_fstck_ub)
    # c_u_cost::Array{Float64, 3}
    sh = xf["c_u_cost"]
    c_u_cost = ones(n_periods,
                    n_subperiods,
                    n_loc)
    for l in 1:n_loc
        col = l
        for i in 1:n_periods
            for j in 1:n_subperiods
                row = j + n_subperiods * (i-1) 
                c_u_cost[i, j, l] = sh[row+1, col]
            end
        end
    end
    c_u_cost = convert(Array{Float64, 3}, c_u_cost)
    # c_ehf_cost::Array{Float64, 4}
    sh = xf["c_ehf_cost"]
    c_ehf_cost = ones(n_periods, n_subperiods, 
                      n_loc, n_fu)
    for l in 1:n_loc
        for f in 1:n_fu
            col = f + n_fu * (l-1)
            for i in 1:n_periods
                for j in 1:n_subperiods
                    row = j + n_subperiods * (i-1) 
                    c_ehf_cost[i, j, l, f] = sh[row+1, col]
                end
            end
        end
    end
    c_ehf_cost = convert(Array{Float64, 4}, c_ehf_cost)
    # c_cts_cost::Vector{Float64}
    sh = xf["c_cts_cost"]
    c_cts_cost = sh[2:n_loc+1, 1]
    c_cts_cost = vec(c_cts_cost)
    c_cts_cost = convert(Vector{Float64}, c_cts_cost)
    # o_cp_ub::Array{Float64, 1}
    sh = xf["o_cp_ub"]
    o_cp_ub = sh[2:n_loc+1, 1]
    o_cp_ub = vec(o_cp_ub)
    o_cp_ub = convert(Array{Float64, 1}, o_cp_ub)
    # o_cp_e_bM::Float64
    sh = xf["o_cp_e_bM"]
    o_cp_e_bM = sh[2, 1]
    o_cp_e_bM = convert(Float64, o_cp_e_bM)
    # o_u_bM::Array{Float64, 2}
    sh = xf["o_u_bM"]
    o_u_bM = sh[2:n_loc+1, 1]
    o_u_bM = convert(Array{Float64, 2}, o_u_bM)
    # o_ehf_bM::Array{Float64, 2}
    sh = xf["o_ehf_bM"]
    o_ehf_bM = sh[2:n_loc+1, 1:n_fu]
    o_ehf_bM = convert(Array{Float64, 2}, o_ehf_bM)
    # o_ep0_bM::Vector{Float64}
    sh = xf["o_ep0_bM"]
    o_ep0_bM = sh[2:n_loc+1, 1]
    o_ep0_bM = vec(o_ep0_bM)
    o_ep0_bM = convert(Vector{Float64}, o_ep0_bM)
    # o_ep1ge_bM::Vector{Float64}
    sh = xf["o_ep1ge_bM"]
    o_ep1ge_bM = sh[2:n_loc+1, 1]
    o_ep1ge_bM = vec(o_ep1ge_bM)
    o_ep1ge_bM = convert(Vector{Float64}, o_ep1ge_bM)
    # o_ep1gce_bM::Vector{Float64}
    sh = xf["o_ep1gce_bM"]
    o_ep1gce_bM = sh[2:n_loc+1, 1]
    o_ep1gce_bM = vec(o_ep1gce_bM)
    o_ep1gce_bM = convert(Vector{Float64}, o_ep1gce_bM)
    # o_ep1gcs_bM::Vector{Float64}
    sh = xf["o_ep1gcs_bM"]
    o_ep1gcs_bM = sh[2:n_loc+1, 1]
    o_ep1gcs_bM = vec(o_ep1gcs_bM)
    o_ep1gcs_bM = convert(Vector{Float64}, o_ep1gcs_bM)
    # o_pay_bM::Array{Float64, 2}
    sh = xf["o_pay_bM"]
    o_pay_bM = sh[2:n_loc+1, 1]
    o_pay_bM = convert(Array{Float64, 2}, o_pay_bM)
    # o_conm_bM::Array{Float64, 2}
    sh = xf["o_conm_bM"]
    o_conm_bM = sh[2:n_loc+1, 1]
    o_conm_bM = convert(Array{Float64, 2}, o_conm_bM)
    # o_fstck_ub::Array{Float64, 2}
    sh = xf["o_fstck_ub"]
    o_fstck_ub = sh[2:n_loc+1, 1:n_fstck] 
    o_fstck_ub = convert(Array{Float64, 2}, o_fstck_ub)
    # t_ret_c_bM::Array{Float64, 2}
    sh = xf["t_ret_c_bM"]
    t_ret_c_bM = sh[2:n_loc+1, 1]
    t_ret_c_bM = convert(Array{Float64, 2}, t_ret_c_bM)
    # t_loan_bM::Array{Float64, 2}
    sh = xf["t_loan_bM"]
    t_loan_bM = sh[2:n_loc+1, 1]
    t_loan_bM = convert(Array{Float64, 2}, t_loan_bM)
    # r_loan0::Vector{Float64}
    sh = xf["r_loan0"]
    r_loan0 = sh[2:n_loc+1, 1]
    r_loan0 = vec(r_loan0)
    r_loan0 = convert(Vector{Float64}, r_loan0)
    # discount::Matrix{Float64}
    sh = xf["discount"]
    discount = zeros(n_periods, n_subperiods)
    for i in 1:n_periods
        for j in 1:n_subperiods
            row = j + n_subperiods * (i-1) 
            discount[i, j] = sh[row+1, 1]
        end
    end
    discount = convert(Matrix{Float64}, discount)
    # demand::Matrix{Float64}
    sh = xf["demand"]
    demand = zeros(n_periods, n_subperiods)
    for i in 1:n_periods
        for j in 1:n_subperiods
            row = j + n_subperiods * (i-1) 
            demand[i, j] = sh[row+1, 1]
        end
    end
    demand = convert(Matrix{Float64}, demand)
    # co2_budget::Matrix{Float64}
    sh = xf["co2_budget"]
    co2_budget = zeros(n_periods, n_subperiods)
    for i in 1:n_periods
        for j in 1:n_subperiods
            row = j + n_subperiods * (i-1) 
            co2_budget[i, j] = sh[row+1, 1]
        end
    end
    co2_budget = convert(Matrix{Float64}, co2_budget)
    # GcI::Array{Float64, 3}
    sh = xf["GcI"]
    GcI = zeros(n_periods, n_subperiods, n_loc)
    for l in 1:n_loc
        for i in 1:n_periods
            for j in 1:n_subperiods
                row = j + n_subperiods * (i-1) 
                GcI[i, j, l] = sh[row+1, l]
            end
        end
    end
    GcI = convert(Array{Float64, 3}, GcI)

    p = params(n_periods,
              n_subperiods,
              n_loc, n_rtft, n_new, n_fu, n_fstck,
              yr_subperiod,
              y0,
              x_ub, interest,
              c0,
              e_C,
              e_c_ub, e_loanFact, e_l_ub, e_Ann, e_ann_ub, e_ladd_ub,
              e_loan_ub,
              e_pay_ub,
              r_c_C, r_rhs_C, r_cp_ub, r_cpb_ub,
              r_c_H,
              r_rhs_H,
              r_eh_ub, r_c_Hfac, r_c_Helec, r_c_F,
              r_rhs_F,
              r_ehf_ub,
              r_c_U, r_rhs_U, r_c_UonSite,
              r_c_Ufac,
              r_u_ub,
              r_c_cp_e, r_rhs_cp_e, r_cp_e_ub, r_c_Fe,
              r_c_Fgenf,
              r_u_ehf_ub,
              r_c_Hr, r_fu_e_ub, r_u_fu_e_ub, 
              r_ep0_ub, r_chi, r_ep1ge_ub,
              r_sigma,
              r_ep1gce_ub,
              r_ep1gcs_ub, r_c_Onm, r_rhs_Onm,
              r_conm_ub,
              r_e_c_ub,
              r_loanFact, r_l0_ub, r_le_ub,
              r_Ann,
              r_ann0_bM,
              r_anne_bM, r_l0add_bM, r_leadd_bM,
              r_loan_bM,
              r_pay0_bM,
              r_paye_bM, r_c_Fstck, r_rhs_Fstck,
              r_fstck_ub,
              n_cp_bM, n_c0_bM, n_c0_lo,
              n_loanFact,
              n_l_bM,
              n_Ann, n_ann_bM, n_ladd_bM,
              n_loan_bM,
              n_pay_bM,
              n_c_H, n_rhs_H, n_eh_bM,
              n_c_Hfac,
              n_c_Helec,
              n_c_F, n_rhs_F, n_ehf_bM, n_c_U,
              n_rhs_U,
              n_c_UonSite,
              n_c_Ufac, n_u_bM, n_c_cp_e,
              n_rhs_cp_e,
              n_cp_e_ub,
              n_c_Fe, n_c_Fgenf, n_u_ehf_ub,
              n_c_Hr, n_fu_e_ub, n_u_fu_e_ub,
              n_ep0_bM,
              n_chi, n_ep1ge_bM, n_sigma, n_ep1gce_bM,
              n_ep1gcs_bM,
              n_c_Onm,
              n_rhs_Onm, n_conm_bM, n_c_Fstck,
              n_rhs_Fstck,
              n_fstck_ub,
              c_u_cost, c_ehf_cost, c_cts_cost,
              o_cp_ub,
              o_cp_e_bM, o_u_bM, o_ehf_bM, o_ep0_bM,
              o_ep1ge_bM,
              o_ep1gce_bM,
              o_ep1gcs_bM, o_pay_bM, o_conm_bM,
              o_fstck_ub,
              t_ret_c_bM,
              t_loan_bM, 
              r_loan0, 
              discount, demand,
              co2_budget,
              GcI
             )
    return p
end


function append_fuelnames(n::Vector{String}, xlsxfname::String)
    XLSX.openxlsx(xlsxfname, mode="rw") do xf
        sheet = XLSX.addsheet!(xf, "fuel_names")
        d = DataFrame("fuel_names"=>n)
        XLSX.writetable!(sheet, d)
    end
end


