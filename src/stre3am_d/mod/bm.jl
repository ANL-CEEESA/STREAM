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

# vim: expandtab colorcolumn=80 tw=80

# written by David Thierry @dthierry 2024
# bm.jl
# notes: Model (block)
# notes of 10-29:
# added variables, r_x_in_d_, r_x_out_d_, r_mass_b_e_, r_comp_link_e_
#
#
#80#############################################################################

using JuMP
using Printf


# based con bm_v09_09.jl
# todo: include the feedstoks
# todo: include the initial loan

# 80 
# 80 ###########################################################################
# defining the model object
"""
    createBlockMod(index_p, index_l, p::params, s::sets])

Create a block of constraints for period `index_p` and location `index_l`.

If `index_p` or `index_l` are collections, then this would create the range
of constraints.

```
"""
function createBlockMod(index_p::T, index_l::T, p::params, s::sets) where
    T<:Union{UnitRange{Int64}, Int64}
    # 76 
    # 76 #######################################################################
    @info "Generating the block"
    #m = Model(Cbc.Optimizer)
    m = Model()
    #set_silent(m)
    if index_p isa Int
        P = [index_p]
    else
        @printf "Set `period` passed as a collection\n"
        P = index_p
    end
    if index_l isa Int
        L = [index_l]
    else
        @printf "Set `location` passed as a collection\n"
        L = index_l
    end

    #P = s.P
    P2 = s.P2

    Kr = s.Kr
    Kn = s.Kn
    Fu_r = s.Fu_r
    Fu_n = s.Fu_n
    Nf = s.Nf
    Nd = s.Nd 


    n_periods = p.n_periods
    n_subperiods = p.n_subperiods
    #
    r_filter = p.r_filter
    n_filter = p.n_filter

    nd_en_fltr = p.nd_en_fltr
    nd_em_fltr = p.nd_em_fltr
    ckey = p.ckey
    key_node = p.key_node

    # True/False
    sT = 1 # p.sTru
    sF = sT + 1 # p.sFal  # offline
    
    # 76 
    # 76 #######################################################################
    # side-effects from the existing plant:
    # capacity factor
    # heating requirement
    # electricity requirement
    # intrinsic emissions
    # exstrinsic emissions
    # scope 1, emitted
    # scope 1, captured
    # scope 1, stored
    # o&m
    #
    # states: 
    # loan
    # triggered:
    # annuity
    # additional capital (ladd)
    ##
    # we'd like to have a filter set r_filter[l\inL, k∈Kr] -> \{True, False\}

    # variables
    ##
    # tier 0: online status
    @variable(m, y_o[i=P, j=P2, l=L], Bin, upper_bound=1.0;
             )  # online
    # retrofit variable
    @variable(m, y_r[i=P, j=P2, l=L, k=Kr; r_filter[l, k]], Bin, upper_bound=1.0)
    # tier 2: retirement
    # there is no retirement binary variable per se.  
    

    # d082923
    # expansion
    ## expansion binary (1 if expansion true)
    @variable(m, y_e[i=P, j=P2, l=L], Bin, upper_bound=1.0)  
    ## disaggregated capacity
    @variable(m, e_c_d_[i=P, j=P2, l=L, (sT, sF)] >= 0.0)
    ## expansion capacity
    @variable(m, e_c[i=P, j=P2, l=L])
    ## expansion loan
    @variable(m, e_l[i=P, j=P2, l=L], lower_bound=0.0, upper_bound=p.e_l_ub[l])
    ## expansion factor
    @variable(m, 0.0 <= x[i=P, l=L] <= p.x_ub) # this should be int, dissag over P
    ## disaggregated expansion factor
    @variable(m, x_d_[i=P, j=P2, l=L, (sT, sF)] >= 0.0)
    
    # d082223
    # retrofit
    ## retrofit capacity
    @variable(m, r_cp[i=P, j=P2, l=L, n=Nd])
    ## retrofit capacity dis.
    @variable(m, r_cp_d_[i=P, j=P2, l=L, k=Kr, n=Nd; r_filter[l, k]])    
    @variable(m, cpb[i=P, j=P2, l=L] >= 0.0)  # base capacity
    ## base capacity disagg
    @variable(m, r_cpb_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]] >= 0.0)
    
    ## retr. heating requirement
    @variable(m, r_eh[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]])
    ## retr. heating requirement dis.
    @variable(m, r_eh_d_[i=P, j=P2, l=L, k=Kr, n=Nd; 
                         r_filter[l, k] && nd_en_fltr[n]])
    ## retr. fuel requirement 
    @variable(m, r_ehf[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]])
    ## retr. fuel requirement  dis.
    @variable(m, r_ehf_d_[i=P, j=P2, l=L, k=Kr, f=Fu_r[l], n=Nd; 
                          r_filter[l, k] && nd_en_fltr[n]])
    ## retr. electricity requirement (on-site)
    @variable(m, r_u[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]]) # 4
    ## retr. elec. dis.
    @variable(m, r_u_d_[i=P, j=P2, l=L, k=Kr, n=Nd; 
                        r_filter[l, k] && nd_en_fltr[n]]) # 5
    ## retr. onsite-elec
    @variable(m, r_u_onsite[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]]) #
    ## retr. onsite-elec dis.
    @variable(m, r_u_onsite_d_[i=P, j=P2, l=L, k=Kr, n=Nd; 
                               r_filter[l, k] && nd_en_fltr[n]])
    ## retr. fuel from onsite electricity generation
    @variable(m, r_u_ehf[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]])
    ## retr. fuel from onsite electricity generation dis.
    @variable(m, r_u_ehf_d_[i=P, j=P2, l=L, k=Kr, f=Fu_r[l], n=Nd; 
                            r_filter[l, k] && nd_en_fltr[n]] >= 0.0)
    ## process emissions
    @variable(m, r_cpe[i=P, j=P2, l=L, n=Nd; nd_em_fltr[n]]) # 
    ## process emission dis.
    @variable(m, r_cpe_d_[i=P, j=P2, l=L, k=Kr, n=Nd;
                          r_filter[l, k] && nd_em_fltr[n]]) # 
    ## retr. fuel
    @variable(m, r_fu_e[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]])
    ## retr. fuel dis.
    @variable(m, r_fu_e_d_[i=P, j=P2, l=L, k=Kr, n=Nd; 
                           r_filter[l, k] && nd_en_fltr[n]])
    ## retr. fuel em.
    @variable(m, r_u_fu_e[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]])
    ## retr. fuel em. dis.
    @variable(m, r_u_fu_e_d_[i=P, j=P2, l=L, k=Kr, n=Nd; 
                             r_filter[l, k] && nd_en_fltr[n]])
    ## retr. total em
    @variable(m, r_ep0[i=P, j=P2, l=L]) # em0
    ## retr. total em dis.
    @variable(m, r_ep0_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]]) # 
    ## retr. scope 1, emitted
    @variable(m, r_ep1ge[i=P, j=P2, l=L]) # em1
    ## retr. scope 1, emitted dis.
    @variable(m, r_ep1ge_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]]) # 
    ## retr. scope 1, captured
    @variable(m, r_ep1gce[i=P, j=P2, l=L]) # em2
    ## retr. scope 1, captured dis.
    @variable(m, r_ep1gce_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]]) # 
    ## retr. scope 1, capt-store
    @variable(m, r_ep1gcs[i=P, j=P2, l=L]) # em3
    ## retr. scope 1, capt-store dis.
    @variable(m, r_ep1gcs_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]]) # 
    ## retr. feedstocks
    @variable(m, r_fstck[i=P, j=P2, l=L, f=Nf])
    ## retr. feedstocks dis.
    @variable(m, r_fstck_d_[i=P, j=P2, l=L, k=Kr, f=Nf; r_filter[l, k]] >= 0.0)
    ## retr. o&m fixed dis.
    @variable(m, r_cfonm_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]])
    ## retr. o&m fixed
    @variable(m, r_cfonm[i=P, j=P2, l=L]) 
    # operating and maintenance variable
    ## retr. o&m var dis.
    @variable(m, r_cvonm_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]])
    ## retr. o&m var
    @variable(m, r_cvonm[i=P, j=P2, l=L]) 
    ## retr. loan state
    @variable(m, r_loan[i=P, j=P2, l=L]) #upper_bound=p.r_loan_bM[l])
    ## retr. loan positive
    @variable(m, r_loan_p[i=P, j=P2, l=L] >= 0.0)
    ## retr. loan neg
    @variable(m, r_loan_n[i=P, j=P2, l=L] >= 0.0)
    ## retr. pay state
    @variable(m, r_yps[i=P, j=P2, l=L], Bin)  # paid or not
    ## retrofit loan
    rl0ub0d = maximum(p.r_l0_ub)
    ## retr. loan 0
    @variable(m, r_l0[i=P, j=P2, l=L], 
              lower_bound=0.0)#, upper_bound=rl0ub0d) # capital (loan)
    ## retr. loan 0 dis.
    @variable(m, r_l0_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]]) 
    ## retr. loan link dis.
    @variable(m, r_l0_pd_[i=P, j=P2, l=L, (sT, sF)], 
              lower_bound=0.0)#, upper_bound=rl0ub0d)
    ## retr. loan add
    @variable(m, r_l0add[i=P, j=P2, l=L], lower_bound=0.0, 
              #upper_bound=rl0ub0d)
             )
    # we had (0,1) but it was clear that this is superfluous
    # (only true)
    ## retr. loan add dis.
    @variable(m, r_l0add_d_[i=P, j=P2, l=L], lower_bound=0.0, 
             )
              #upper_bound=rl0ub0d)

    #########
    ## retr. expanded dis.
    @variable(m, r_e_c_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]], 
              lower_bound=0.0)
    ## retr. retrofit-expansion loan
    rleub0d = maximum(p.r_le_ub)
    ## retr. loan expansion
    @variable(m, r_le[i=P, j=P2, l=L],
              lower_bound=0.0
             # , upper_bound=rleub0d
             )
    ## retr. loan exp dis.
    @variable(m, r_le_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]])
    ## retr. loan exp dis. link: le->leadd
    @variable(m, r_le_pd_[i=P, j=P2, l=L, (sT, sF)], 
              lower_bound=0.0
             # , upper_bound=rleub0d
             )
    ## retr. loan exp add
    @variable(m, r_leadd[i=P, j=P2, l=L] 
              # upper_bound=rleub0d
             )
    ## retr. exp add
    @variable(m, r_leadd_d_[i=P, j=P2, l=L], lower_bound=0.0 
             # upper_bound=rleub0d
             )
    ## retr. exp dis. link loan 
    @variable(m, r_le_ped_[i=P, j=P2, l=L, (sT, sF)], 
              lower_bound=0.0
             # , upper_bound=rleub0d
             )
    ## retr. exp add loan
    @variable(m, r_leadde[i=P, j=P2, l=L], lower_bound=0.0, 
             # upper_bound=rleub0d
             )
    ## retr. exp add loan dis.
    @variable(m, r_leadde_d_[i=P, j=P2, l=L], lower_bound=0.0, 
             # upper_bound=rleub0d
             )
    # retrofit base annuity
    @variable(m, r_ann0[i=P, j=P2, l=L])
    @variable(m, r_ann0_0[i=P, j=P2, l=L] >= 0.0)
    @variable(m, r_ann0_1[i=P, j=P2, l=L] >= 0.0)
    @variable(m, r_ann0_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]])

    # retrofit-expansion annuity 
    @variable(m, r_anne[i=P, j=P2, l=L])
    @variable(m, r_anne_0[i=P, j=P2, l=L] >= 0.0)
    @variable(m, r_anne_1[i=P, j=P2, l=L] >= 0.0)
    @variable(m, r_anne_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]])

    # retrofit payment
    @variable(m, r_pay0[i=P, j=P2, l=L], lower_bound=0.0, 
              #upper_bound=p.r_ann0_bM[l])
             )
    @variable(m, r_pay0_1[i=P, j=P2, l=L] >= 0.0)
    
    # retrofit-expansion payment
    @variable(m, r_paye[i=P, j=P2, l=L], lower_bound=0.0, 
             )
             # upper_bound=p.r_anne_bM[l])
    @variable(m, r_paye_1[i=P, j=P2, l=L] >= 0.0)

    # expansion capacity loan
    @variable(m, e_ladd[i=P, j=P2, l=L], lower_bound=0.0, 
              upper_bound=p.e_ladd_ub[l])
    # only true
    @variable(m, e_ladd_d_[i=P, j=P2, l=L] >= 0.0, 
              upper_bound=p.e_ladd_ub[l])

    @variable(m, e_l_d_[i=P, j=P2, l=L, (sT, sF)] >= 0.0) # disaggregated
    @variable(m, e_l_pd_[i=P, j=P2, l=L, (sT, sF)], lower_bound=0.0, 
              upper_bound=p.e_l_ub[l])
    @variable(m, e_yps[i=P, j=P2, l=L], Bin) # 1 if paid, 0 otw

    @variable(m, e_loan[i=P, j=P2, l=L], upper_bound=p.e_loan_ub[l])
    @variable(m, e_loan_p[i=P, j=P2, l=L] >= 0.0)
    @variable(m, e_loan_n[i=P, j=P2, l=L] >= 0.0)

    @variable(m, e_ann[i=P, j=P2, l=L])
    # only true
    @variable(m, e_ann_d_[i=P, j=P2, l=L]>=0.0)
    @variable(m, e_ann_0[i=P, j=P2, l=L]>=0.0)
    @variable(m, e_ann_1[i=P, j=P2, l=L]>=0.0)

    @variable(m, e_pay[i=P, j=P2, l=L], lower_bound=0.0, 
              upper_bound=p.e_pay_ub[l])
    @variable(m, e_pay_1[i=P, j=P2, l=L])


    # d090423
    # retirement cost
    @variable(m, t_loan_d_[i=P, j=P2, l=L, (sT, sF)] >= 0, 
              upper_bound=p.t_loan_bM[l])
    # total loan
    @variable(m, t_ret_cost[i=P, j=P2, l=L], 
              lower_bound=0.0, upper_bound=p.t_ret_c_bM[l])
    # only true
    @variable(m, t_ret_cost_d_[i=P, j=P2, l=L] >= 0, 
              upper_bound=p.t_ret_c_bM[l])
    # only 0th needed

    # 76 
    # 76 #######################################################################
    @variable(m, y_n[i=P, j=P2, l=L, k=Kn; n_filter[l, k]], Bin, upper_bound=1.0) 
    # this means plant kind k
    @variable(m, n_c0[i=P, l=L], lower_bound=0.0)  
    # the new capacity, dissagg over P
    @variable(m, n_c0_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]] >= 0) # disaggregated

    @variable(m, n_cp[i=P, j=P2, l=L, n=Nd], lower_bound=0.0, 
              upper_bound=p.n_cp_bM[l, n])
    # disaggregated variable
    @variable(m, n_cp_d_[i=P, j=P2, l=L, k=Kn, n=Nd; n_filter[l, k]] >= 0)

    #
    @variable(m, n_l_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]])
    @variable(m, n_l[i=P, j=P2, l=L], lower_bound=0, upper_bound=p.n_l_bM[l])

    @variable(m, n_ann_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]] >= 0)
    @variable(m, n_ann[i=P, j=P2, l=L])
    @variable(m, n_ann_0[i=P, j=P2, l=L]>=0)
    @variable(m, n_ann_1[i=P, j=P2, l=L]>=0)

    # only true
    @variable(m, n_ladd_d_[i=P, j=P2, l=L] >= 0, upper_bound=p.n_ladd_bM[l])
    @variable(m, n_ladd[i=P, j=P2, l=L], lower_bound=0, upper_bound=p.n_l_bM[l])

    @variable(m, n_l_pd_[i=P, j=P2, l=L, (sT, sF)] >= 0, 
              upper_bound=p.n_l_bM[l])

    @variable(m, n_loan[i=P, j=P2, l=L], upper_bound=p.n_loan_bM[l])
    @variable(m, n_loan_p[i=P, j=P2, l=L] >= 0, upper_bound=p.n_loan_bM[l])
    @variable(m, n_loan_n[i=P, j=P2, l=L] >= 0)
    @variable(m, n_yps[i=P, j=P2, l=L], Bin)

    @variable(m, n_pay[i=P, j=P2, l=L], lower_bound=0.0, 
              upper_bound=p.n_pay_bM[l])
    @variable(m, n_pay_1[i=P, j=P2, l=L] >= 0)
    
    # 76 
    # 76 #######################################################################
    
    # heating requirement
    @variable(m, n_eh[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]]) # 0
    @variable(m, n_eh_d_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                         n_filter[l, k] && nd_en_fltr[n]]) # 1
    # fuel requirement 
    @variable(m, n_ehf[i=P, j=P2, l=L, f=Fu_n[l], n=Nd; nd_en_fltr[n]]) # 2
    @variable(m, n_ehf_d_[i=P, j=P2, l=L, k=Kn, f=Fu_n[l], n=Nd; 
                          n_filter[l, k] && nd_en_fltr[n]])
    # electricity requirement
    @variable(m, n_u[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]], lower_bound=0.0, 
              upper_bound=p.n_u_ub[l, n]) # 4
    @variable(m, n_u_d_[i=P, j=P2, l=L, k=Kn, n=Nd;
                        n_filter[l, k] && nd_en_fltr[n]]) # 5

    # electricity emissions (off-site)
    @variable(m, n_u_onsite[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]]) #
    @variable(m, n_u_onsite_d_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                               n_filter[l, k] && nd_en_fltr[n]])

    # fuel from onsite electricity generation
    @variable(m, n_u_ehf[i=P, j=P2, l=L, f=Fu_n[l], n=Nd; nd_en_fltr[n]])
    @variable(m, n_u_ehf_d_[i=P, j=P2, l=L, k=Kn, f=Fu_n[l], n=Nd;
                            n_filter[l, k] && nd_en_fltr[n]] >= 0.0)

    # process (intrinsic) emissions
    @variable(m, n_cpe[i=P, j=P2, l=L, n=Nd; nd_em_fltr[n]]) # 6
    @variable(m, n_cpe_d_[i=P, j=P2, l=L, k=Kn, n=Nd;
                          n_filter[l, k] && nd_em_fltr[n]]) # 7
    # 
    @variable(m, n_fu_e[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]])
    @variable(m, n_fu_e_d_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                           n_filter[l, k] && nd_en_fltr[n]])
    # 
    @variable(m, n_u_fu_e[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]])
    @variable(m, n_u_fu_e_d_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                             n_filter[l, k] && nd_en_fltr[n]])

    # process (extrinsic) disaggregated emissions, e.g. scope 0, etc.
    @variable(m, n_ep0[i=P, j=P2, l=L]) # 8
    @variable(m, n_ep0_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]]) # 9

    # scope 1, emitted
    @variable(m, n_ep1ge[i=P, j=P2, l=L], 
              lower_bound=0.0, upper_bound=p.n_ep1ge_bM[l]) # 10
    @variable(m, n_ep1ge_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]]) # 11
    # scope 1, captured
    @variable(m, n_ep1gce[i=P, j=P2, l=L]) # 12
    @variable(m, n_ep1gce_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]]) # 13
    # scope 1,  stored
    @variable(m, n_ep1gcs[i=P, j=P2, l=L]) # 14
    @variable(m, n_ep1gcs_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]]) # 15


    # feedstocks
    @variable(m, n_fstck[i=P, j=P2, l=L, f=Nf])
    @variable(m, n_fstck_d_[i=P, j=P2, l=L, k=Kn, f=Nf; n_filter[l, k]] >= 0.0)

    # operating and maintenance fixed
    @variable(m, n_cfonm_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]] >= 0.0)  # 16
    @variable(m, n_cfonm[i=P, j=P2, l=L], 
              lower_bound=0.0, upper_bound=p.n_cfonm_bM[l])  # 17
    # operating and maintenance variable
    @variable(m, n_cvonm_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]] >= 0.0)  # 16
    @variable(m, n_cvonm[i=P, j=P2, l=L], 
              lower_bound=0.0, upper_bound=p.n_cvonm_bM[l])  # 17
    
    # cost of electricity
    @variable(m, n_u_cost[i=P, j=P2, l=L])
    # cost of fuel
    @variable(m, n_ehf_cost[i=P, j=P2, l=L])

    # 76 
    # 76 #######################################################################
    ##
    # k = 0 means on
    @variable(m, o_pay[i=P, j=P2, l=L], lower_bound=0.0, 
              upper_bound=p.o_pay_bM[l])

    # only true
    @variable(m, o_pay_d_[i=P, j=P2, l=L] >= 0.0)
    # k = 0 means on
    @variable(m, o_cfonm[i=P, j=P2, l=L], lower_bound=0.0, 
              upper_bound=p.o_cfonm_bM[l])
    # only true
    @variable(m, o_cfonm_d_[i=P, j=P2, l=L] >= 0.0)
    @variable(m, o_tcfonm_d_[i=P, j=P2, l=L, (sT, sF)])

    @variable(m, o_cvonm[i=P, j=P2, l=L], lower_bound=0.0, 
              upper_bound=p.o_cvonm_bM[l])
    # only true
    @variable(m, o_cvonm_d_[i=P, j=P2, l=L] >= 0.0)
    @variable(m, o_tcvonm_d_[i=P, j=P2, l=L, (sT, sF)])
    #
    @variable(m, o_cp[i=P, j=P2, l=L, n=Nd], lower_bound=0.0)
              #, upper_bound=p.o_cp_bM)
    # only true
    @variable(m, o_cp_d_[i=P, j=P2, l=L, n=Nd] >= 0) # disaggregated variable


    @variable(m, o_tcp_d_[i=P, j=P2, l=L, (sT, sF), n=Nd] >= 0.0)
    @variable(m, o_tpay_d_[i=P, j=P2, l=L, (sT, sF)] >= 0.0)

    # disaggregated retrofitted capacity
    @variable(m, o_rcp_d_[i=P, j=P2, l=L, k=Kr, (sT, sF); r_filter[l, k]] >= 0.0)
    @variable(m, o_rcp[i=P, j=P2, l=L, k=Kr; r_filter[l, k]])

    # only true
    @variable(m, o_u_d_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]] >= 0)
    @variable(m, o_u[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]] >= 0, upper_bound=p.o_u_ub[l, n])
    #
    @variable(m, o_tu_d_[i=P, j=P2, l=L, (sT, sF), n=Nd;
                         nd_en_fltr[n]] >= 0)
    #
    # only true
    @variable(m, o_ehf_d_[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]] >= 0)
    @variable(m, o_ehf[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]] >= 0)
    #
    @variable(m, o_tehf_d_[i=P, j=P2, l=L, f=Fu_r[l], (sT, sF), n=Nd;
                           nd_en_fltr[n]] >= 0)
    #
    # only true
    @variable(m, o_ep0_d_[i=P, j=P2, l=L] >= 0)
    @variable(m, o_ep0[i=P, j=P2, l=L]) # em0
    @variable(m, o_tep0_d_[i=P, j=P2, l=L, (sT, sF)] >= 0)
    # only true
    @variable(m, o_ep1ge_d_[i=P, j=P2, l=L] >= 0)
    @variable(m, o_ep1ge[i=P, j=P2, l=L],
              lower_bound=0.0, upper_bound=p.o_ep1ge_bM[l]) # em1
    @variable(m, o_tep1ge_d_[i=P, j=P2, l=L, (sT, sF)] >= 0)

    #
    @variable(m, o_ep1gce_d_[i=P, j=P2, l=L] >= 0)
    @variable(m, o_ep1gce[i=P, j=P2, l=L],
              lower_bound=0.0, upper_bound=p.o_ep1gce_bM[l]) # em2

    @variable(m, o_tep1gce_d_[i=P, j=P2, l=L, (sT, sF)] >= 0)
    
    #
    # only true
    @variable(m, o_ep1gcs_d_[i=P, j=P2, l=L]) # 15
    @variable(m, o_ep1gcs[i=P, j=P2, l=L]) # 14  em3

    @variable(m, o_tep1gcs_d_[i=P, j=P2, l=L, (sT, sF)] >= 0)


    # feedstocks
    #@variable(m, o_fstck_d_[i=P, j=P2, l=L, f=Nf] >= 0.0)
    #@variable(m, o_fstck[i=P, j=P2, l=L, f=Nf])
    #
    #@variable(m, o_tfstck_d_[i=P, j=P2, l=L, f=Nf, (sT, sF)] >= 0.0)

    #
    # -> had to put a period here
    oloanlastub = p.e_loan_ub .+ vec(p.r_loan_ub)
    @variable(m, o_loan_last[i=P, l=L, (sT, sF)],
              lower_bound=0.0, upper_bound=oloanlastub[l])

    # cost of electricity
    @variable(m, o_u_cost[i=P, j=P2, l=L] >= 0.0)
    # cost of fuel
    @variable(m, o_ehf_cost[i=P, j=P2, l=L] >= 0.0)
    # cost of storing carbon
    @variable(m, o_ep1gcs_cost[i=P, j=P2, l=L] >= 0.0)
    @variable(m, n_ep1gcs_cost[i=P, j=P2, l=L] >= 0.0)

    ####################
    Nd = s.Nd
    Mt = s.Mt
    Ln = s.Ln

    node_mat = p.node_mat
    skip_mb = p.skip_mb
    links_list = p.links_list
    input_mat = p.input_mat
    output_mat = p.output_mat

    function f_xin(m, i, j, l, k, n, c, input_mat; mode="r")
        if c ∈ input_mat[n]
            if mode == "r"
                # r_x_in_d_
                return m[:r_x_in_d_][i, j, l, k, n, c]
            elseif mode == "n"
                # n_x_in_d_
                return m[:n_x_in_d_][i, j, l, k, n, c]
            else
                return "error"
            end

        else
            return 0.0 
        end
    end

    function f_xout(m, i, j, l, k, n, c, output_mat; mode="n")
        if c ∈ output_mat[n]
            if mode == "r"
                # r_x_out_d_
                return m[:r_x_out_d_][i, j, l, k, n, c]
            elseif mode == "n"
                # n_x_out_d_
                return m[:n_x_out_d_][i, j, l, k, n, c]
            else
                return "error"
            end
        else
            return 0.0 
        end
    end
    ####################
    @variable(m, r_x_in_d_[i=P, j=P2, l=L, k=Kr, n=Nd, c=Mt; 
                           r_filter[l, k] && node_mat[n, c] && 
                           c ∈ input_mat[n]] >= 0.0)
    @variable(m, r_x_out_d_[i=P, j=P2, l=L, k=Kr, n=Nd, c=Mt;
                            r_filter[l, k] && node_mat[n, c] &&
                            c ∈ output_mat[n]] >= 0.0)
    # surplus
    @variable(m, r_x_o_s_d_[i=P, j=P2, l=L, k=Kr, n=Nd; r_filter[l, k]] >= 0.0)
    
    #
    @variable(m, r_x_in[i=P, j=P2, l=L, n=Nd, c=Mt;
                        node_mat[n, c] && c ∈ input_mat[n]] >= 0.0)
    @variable(m, r_x_out[i=P, j=P2, l=L, n=Nd, c=Mt; 
                         node_mat[n, c] && c ∈ output_mat[n]] >= 0.0)
    #
    @variable(m, o_x_in[i=P, j=P2, l=L, n=Nd, c=Mt;
                        node_mat[n, c] && c ∈ input_mat[n]] >= 0.0)
    @variable(m, o_x_in_d_[i=P, j=P2, l=L, n=Nd, c=Mt;
                           node_mat[n, c] && c ∈ input_mat[n]] >= 0.0)
    @variable(m, o_tx_in_d_[i=P, j=P2, l=L, n=Nd, c=Mt, (sT, sF);
                            node_mat[n, c] && c ∈ input_mat[n]] >= 0.0)
    #
    @variable(m, o_x_out[i=P, j=P2, l=L, n=Nd, c=Mt;
                        node_mat[n, c] && c ∈ output_mat[n]] >= 0.0)
    @variable(m, o_x_out_d_[i=P, j=P2, l=L, n=Nd, c=Mt;
                           node_mat[n, c] && c ∈ output_mat[n]] >= 0.0)
    @variable(m, o_tx_out_d_[i=P, j=P2, l=L, n=Nd, c=Mt, (sT, sF);
                            node_mat[n, c] && c ∈ output_mat[n]] >= 0.0)
    #

    #
    @variable(m, n_x_in_d_[i=P, j=P2, l=L, k=Kn, n=Nd, c=Mt; 
                           n_filter[l, k] && node_mat[n, c] && 
                           c ∈ input_mat[n]] >= 0.0)
    @variable(m, n_x_out_d_[i=P, j=P2, l=L, k=Kn, n=Nd, c=Mt;
                            n_filter[l, k] && node_mat[n, c] && 
                            c ∈ output_mat[n]] >= 0.0)
    #
    # surplus
    @variable(m, n_x_o_s_d_[i=P, j=P2, l=L, k=Kn, n=Nd; n_filter[l, k]] >= 0.0)

    @variable(m, n_x_in[i=P, j=P2, l=L, n=Nd, c=Mt; 
                        node_mat[n, c] && c ∈ input_mat[n]] >= 0.0)
    @variable(m, n_x_out[i=P, j=P2, l=L, n=Nd, c=Mt;
                         node_mat[n, c] && c ∈ output_mat[n]] >= 0.0)
    #
    @variable(m, r_ups_e_mt_in_d_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]] >= 0.0)
    @variable(m, r_ups_e_mt_in[i=P, j=P2, l=L] >= 0.0)
    
    @variable(m, o_ups_e_mt_in_d_[i=P, j=P2, l=L])
    @variable(m, o_ups_e_mt_in[i=P, j=P2, l=L])
    @variable(m, o_tups_e_mt_in_d_[i=P, j=P2, l=L, (sT, sF)] >= 0)

    @variable(m, n_ups_e_mt_in_d_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]] >= 0.0)
    @variable(m, n_ups_e_mt_in[i=P, j=P2, l=L] >= 0.0)

    @variable(m, o_x_in_cost[i=P, j=P2, l=L]) 
    @variable(m, n_x_in_cost[i=P, j=P2, l=L]) 
    ####################
    
    # 76 
    # 76 #######################################################################
    ##
    # tier 0 logic
    @constraint(m, o_logic_1_y_i_[i=P, j=P2, l=L; j<n_subperiods],
                y_o[i, j+1, l] <= y_o[i, j, l]) # this can only go offline



    # tier 1
    #@constraint(m, logic_tier01_0_e[i=P, j=P2, l=L],  # only one option
    #            sum(y_r[i, j, l, k] for k in Kr) >= y_o[i, j, l])

    #@constraint(m, logic_tier01_1_e[i=P, j=P2, l=L, k=Kr],
    #            y_o[i, j, l] >= y_r[i, j, l, k]
    #           )

    #
    #
    fP = first(s.P)
    fP2 = first(P2)
    fKr = first(Kr)
    fKn = first(Kn)
    #
    @constraint(m, r_logic_budget_s[i=P, j=P2, l=L;
                                    (i,j) != (fP,fP2)], # only one mode
                sum(y_r[i, j, l, k] for k in Kr if (k > fKr && r_filter[l, k]))
                <= 1
               )
    #
    @constraint(m, r_logic_tier_1_0m_e_[i=P, j=P2, l=L, k=Kr; 
                                        (k>fKr && r_filter[l, k])], 
                1 >= y_r[i, j, l, k] + y_r[i, j, l, fKr]
               )
    #
    @constraint(m, r_logic_budget_y_i_[i=P, j=P2, l=L, k=Kr; 
                                       k>fKr && j<n_subperiods && r_filter[l, k]],
                y_r[i, j+1, l, k] >= y_r[i, j, l, k]
               )

    @constraint(m, r_logic_onoff_1_y_i_[i=P, j=P2, l=L, k=Kr;
                                        j<n_subperiods && r_filter[l, k]],
                y_o[i, j, l] + 1 - y_r[i, j, l, k] 
                + y_r[i, j+1, l, k] >= 1
               )

    @constraint(m, r_logic_onoff_2_y_i_[i=P, j=P2, l=L, k=Kr;
                                        j<n_subperiods && r_filter[l, k]],
                y_o[i, j, l] + 1 - y_r[i, j+1, l, k] 
                + y_r[i, j, l, k] >= 1
               )

    # continuity


    # 76 
    # 76 #######################################################################
    ##
    # d082923
    # -> expansion
    # p.e_C[l], the capacity per unit of allocation
    # we need a single binary variable for each plant.
    @constraint(m, exp_d0_e_[i=P, j=P2, l=L], # only 0 counts
                e_c_d_[i, j, l, sT] == p.e_C[l] * x_d_[i, j, l, sT]
               )
    # e_c_ub
    @constraint(m, exp_ncw_m_i0_[i=P, j=P2, l=L],
                e_c_d_[i, j, l, sT] <= p.e_c_ub[l] * y_e[i, j, l]
               )
    @constraint(m, exp_ncw_s_[i=P, j=P2, l=L],
                e_c[i, j, l] == e_c_d_[i, j, l, sT]
               )
    # x_
    @constraint(m, exp_x_m_i0_[i=P, j=P2, l=L],
                x_d_[i, j, l, sT] <= p.x_ub * y_e[i, j, l]
               )
    @constraint(m, exp_x_m_i3_[i=P, j=P2, l=L],
                x_d_[i, j, l, sT] >= 1.0 * y_e[i, j, l]
               )
    # x_ (relax)
    @constraint(m, exp_x_m_i1_[i=P, j=P2, l=L],
                x_d_[i, j, l, sF] <= p.x_ub * (1 - y_e[i, j, l])
               )
    @constraint(m, exp_x_s_[i=P, j=P2, l=L],
                x[i, l] == x_d_[i, j, l, sT] + x_d_[i, j, l, sF]
               )

    # -> expansion cost (loan)
    # p.e_loanFact
    @constraint(m, e_l_d0_e_[i=P, j=P2, l=L], # only zero counts
                e_l_d_[i, j, l, sT] == 
                p.e_loanFact[l] * e_c_d_[i, j, l, sT]
               )
    #@constraint(m, e_l_d1_e_[i=P, j=P2, l=L], # only zero counts
    #            e_l_d_[i, j, l, 1] == 0.0 
    #           )
    
    # e_l_ub[l]
    @constraint(m, e_l_m_i0_[i=P, j=P2, l=L],
                e_l_d_[i, j, l, sT] <= p.e_l_ub[l] * y_e[i, j, l]
               )
    # e_l_ub[l]
    #@constraint(m, e_l_m_i1_[i=P, j=P2, l=L],
    #            e_l_d_[i, j, l, 1] <= e_l_ub[l] * (1 - y_e[i, j, l])
    #           )
    # only true.
    @constraint(m, e_l_s_[i=P, j=P2, l=L],
                e_l[i, j, l] == e_l_d_[i, j, l, sT]
               )

    # -> expansion cost annuity (annual payment)
    # p.e_Ann
    @constraint(m, e_ann_d0_e_[i=P, j=P2, l=L], # only zero counts
                e_ann_d_[i, j, l] == p.e_Ann[l] * e_l_d_[i, j, l, sT]
               )
    # e_ann_ub[l]
    @constraint(m, e_ann_m_i0_[i=P, j=P2, l=L],
                e_ann_d_[i, j, l] <= p.e_ann_ub[l] * y_e[i, j, l]
               )
    @constraint(m, e_ann_s_[i=P, j=P2, l=L],
                e_ann[i, j, l] == e_ann_d_[i, j, l]
               )

    # 76 
    # 76 #######################################################################
    ##
    # -> expansion logic
    @constraint(m, e_logic_1_y_i_[i=P, j=P2, l=L; j<n_subperiods],
                y_e[i, j+1, l] >= y_e[i, j, l]  # only expand in the future
               )

    # 76 
    # 76 #######################################################################
    ##
    # capacity expansion loans (they should be agnostic to retrofit or rf)
    # components: e_ladd, e_ann, e_pslack, e_ploan
    # -> e_add
    # exp add loan
    @constraint(m, e_ladd_d0_e_[i=P, j=P2, l=L], # true
                e_ladd_d_[i, j, l] == e_l_pd_[i, j, l, sT]
               )
    @constraint(m, e_ladd_m_0_y_i_[i=P, j=P2, l=L; j>fP2], 
                # y_e goes from 0 to 1 (>= if true)
                e_ladd_d_[i, j, l] <= 
                p.e_ladd_ub[l] * (y_e[i, j, l] - y_e[i, j-1, l])
               )
    # 
    @constraint(m, e_l_m_1_y_i_[i=P, j=P2, l=L; j>fP2], 
                # need to set this to 0 # false
                e_l_pd_[i, j, l, sF] <= 
                p.e_l_ub[l] * (1 - y_e[i, j, l] + y_e[i, j-1, l])
               )  #  the 0th component is implied by the e_ladd_m constr
    # 

    @constraint(m, e_ladd_s_e[i=P, j=P2, l=L],
                e_ladd[i, j, l] == e_ladd_d_[i, j, l]
               )

    @constraint(m, e_l_s_e_[i=P, j=P2, l=L],
                e_l[i, j, l] == 
                e_l_pd_[i, j, l, sT] + e_l_pd_[i, j, l, sF]
               )

    # load
    @constraint(m, e_loan_s_e_[i=P, j=P2, l=L],
                e_loan[i, j, l] == e_loan_p[i, j, l] - e_loan_n[i, j, l]
               )
    @constraint(m, e_loan_p_m0_i_[i=P, j=P2, l=L],
                e_loan_p[i, j, l] <= p.e_loan_ub[l] * (1 - e_yps[i, j, l])
               )
    @constraint(m, e_loan_n_m0_i_[i=P, j=P2, l=L],
                e_loan_n[i, j, l] <= p.e_loan_ub[l] * e_yps[i, j, l]
               )
    # pay
    @constraint(m, e_pay_s_e_[i=P, j=P2, l=L],
                e_pay[i, j, l] == e_pay_1[i, j, l]
               )
    @constraint(m, e_pay_n_m0_i_[i=P, j=P2, l=L],
                e_pay_1[i, j, l] <= p.e_pay_ub[l] * (1 - e_yps[i, j, l])
               )
    # annuity
    @constraint(m, e_ann_s_e_[i=P, j=P2, l=L],
                e_ann[i, j, l] == e_ann_0[i, j, l] + e_ann_1[i, j, l]
               )
    @constraint(m, e_ann_0_m_i_[i=P, j=P2, l=L],
                e_ann_0[i, j, l] <= p.e_ann_ub[l] * e_yps[i, j, l]
               )
    @constraint(m, e_ann_1_m_i_[i=P, j=P2, l=L],
                e_ann_1[i, j, l] <= p.e_ann_ub[l] * (1 - e_yps[i, j, l])
               )
    @constraint(m, e_ann_dpay0_e_[i=P, j=P2, l=L],
                e_ann_1[i, j, l] == e_pay_1[i, j, l]
               )

    #logic
    @constraint(m, e_logic_yps_ye[i=P, j=P2, l=L; j>fP2],
                (y_e[i, j, l] - y_e[i, j-1, l]) + e_yps[i, j, l] <= 1
               )
    # 76 
    # 76 #######################################################################
    ##
    # -> expansion loan balance
    @constraint(m, e_loan_bal_y_e_[i=P, j=P2, l=L; j<n_subperiods],
                e_loan[i, j+1, l] == e_loan[i, j, l] * (1+p.interest)^p.yr_subperiod
                - e_pay[i, j, l]*sum((1+p.interest)^k for k in 0:(p.yr_subperiod-1))
                + e_ladd[i, j, l] * (1+p.interest)^(p.yr_subperiod-1)
               )

    # 76 
    # 76 #######################################################################
    ##
    # -> expansion loan balance
    # d082923
    # base capacity
    @constraint(m, cpb_e_[i=P, j=P2, l=L],
                cpb[i, j, l] == p.c0[l] + e_c[i, j, l]
               )
    # 76 
    # 76 #######################################################################
    ##
    # retrofit 
    # -> capacity.
    # p.Kr (capacity factor, e.g. prod in retrofit r / base prod)
    # viz. cap_mod = factor * cap_base
    @constraint(m, r_cp_d_e_[i=P, j=P2, l=L, k=Kr, n=Nd; r_filter[l, k]],
                r_cp_d_[i, j, l, k, n]  <= 
                r_cpb_d_[i, j, l, k] * p.r_Kkey_j[n, k]
               )
    # at least 50% (for the key node)
    @constraint(m, r_cp_ub_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_cpb_d_[i, j, l, k] * p.min_cpr[l]
                <= r_cp_d_[i, j, l, k, key_node]
               )
    # r_cp_ub, retrofit capacity
    @constraint(m, r_cp_lb_i_[i=P, j=P2, l=L, k=Kr, n=Nd; r_filter[l, k]],
                r_cp_d_[i, j, l, k, n] <= p.r_cp_ub[l, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_cp_s_e_[i=P, j=P2, l=L, n=Nd],
                r_cp[i, j, l, n] == 
                sum(r_cp_d_[i, j, l, k, n] for k in Kr if r_filter[l, k])
               )
    @constraint(m, r_cp_x_e_[i=P, j=P2, l=L, k=Kr, n=Nd; r_filter[l, k]],
                r_cp_d_[i, j, l, k, n] == 
                r_x_out_d_[i, j, l, k, n, ckey[n]] + r_x_o_s_d_[i, j, l, k, n]
               )
    #
    # cpb_ub, base capacity
    @constraint(m, r_cpb_d_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_cpb_d_[i, j, l, k] <= p.r_cpb_ub[l] * y_r[i, j, l, k]
               )
    @constraint(m, r_cpb_s_e_[i=P, j=P2, l=L],
                cpb[i, j, l] == 
                sum(r_cpb_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )
    # -> heating requirement.
    # p.Hm (heating factor, i.e. heat / product), scaled by subperiod
    @constraint(m, r_eh_d_e_[i=P, j=P2, l=L, k=Kr, n=Nd;
                             r_filter[l, k] && nd_en_fltr[n]],
                r_eh_d_[i, j, l, k, n] == 
                p.r_c_H[l, k, n] * r_cp_d_[i, j, l, k, n] + 
                p.r_rhs_H[l, k, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_eh_d_m_i_[i=P, j=P2, l=L, k=Kr, n=Nd;
                               r_filter[l, k] && nd_en_fltr[n]],
                r_eh_d_[i, j, l, k, n] <= p.r_eh_ub[l, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_eh_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                r_eh[i, j, l, n] == 
                sum(r_eh_d_[i, j, l, k, n] for k in Kr if r_filter[l, k])
               )
    # d082923
    # -> fuel required for heat.
    # p.r_c_F in [0,1], (i.e. a fraction, heat by fuel /tot heat)
    @constraint(m, r_ehf_d_e_[i=P, j=P2, l=L, k=Kr, f=Fu_r[l], n=Nd; 
                              r_filter[l, k] && nd_en_fltr[n]],
                r_ehf_d_[i, j, l, k, f, n] == 
                p.r_c_F[f, l, k, n] * r_eh_d_[i, j, l, k, n] + 
                p.r_rhs_F[f, l, k, n] * y_r[i, j, l, k]
               )
    # r_ehf_ub
    @constraint(m, r_ehf_m_i_[i=P, j=P2, l=L, k=Kr, f=Fu_r[l],
                              n=Nd; r_filter[l, k] && nd_en_fltr[n]],
                r_ehf_d_[i, j, l, k, f, n] <= p.r_ehf_ub[f, l, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_ehf_s_e_[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]],
                r_ehf[i, j, l, f, n] == 
                sum(r_ehf_d_[i, j, l, k, f, n] for k in Kr if r_filter[l, k])
               )

    # -> electricity requirement
    # r_u and m_ud_, p.Um & p.UmRhs, scaled by subperiod
    @constraint(m, r_u_d_e_[i=P, j=P2, l=L, k=Kr, n=Nd; 
                            r_filter[l, k] && nd_en_fltr[n]],
                r_u_d_[i, j, l, k, n] == 
                (1-p.r_c_UonSite[i, j, l, k, n]) * (p.r_c_U[l, k, n] * r_cp_d_[i, j, l, k, n] + p.r_rhs_U[l, k, n] * y_r[i,j,l,k])
               )

    # r_u_ub[l] (big-M)
    @constraint(m, r_u_i_[i=P, j=P2, l=L, k=Kr, n=Nd;
                          r_filter[l, k] && nd_en_fltr[n]],
                r_u_d_[i, j, l, k, n] <= p.r_u_ub[l, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_u_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                r_u[i, j, l, n] == 
                sum(r_u_d_[i, j, l, k, n] for k in Kr if r_filter[l, k])
               )

    # -> electricity on-site generation, scaled by subperiod
    @constraint(m, r_u_onsite_d_e_[i=P, j=P2, l=L, k=Kr, n=Nd; 
                                   r_filter[l, k] && nd_en_fltr[n]],
                r_u_onsite_d_[i, j, l, k, n] == 
                (p.r_c_UonSite[i, j, l, k, n]) * (p.r_c_U[l, k, n] * r_cp_d_[i, j, l, k, n] + p.r_rhs_U[l,k,n] * y_r[i,j,l,k])
               )
    # r_u_ub[l] (big-M)
    @constraint(m, r_u_onsite_i_[i=P, j=P2, l=L, k=Kr, n=Nd;
                                 r_filter[l, k] && nd_en_fltr[n]],
                r_u_onsite_d_[i, j, l, k, n] <= p.r_u_ub[l, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_u_onsite_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                r_u_onsite[i, j, l, n] == 
                sum(r_u_onsite_d_[i, j, l, k, n] for k in Kr if r_filter[l, k])
               )

    # fuel from electricity generation
    @constraint(m, r_u_ehf_e_[i=P, j=P2, l=L, k=Kr, f=Fu_r[l], n=Nd;
                              r_filter[l, k] && nd_en_fltr[n]],
                r_u_ehf_d_[i, j, l, k, f, n] == 
                p.r_c_Hr[f, l, k, n] * p.r_c_Fgenf[f, l, k, n] * r_u_onsite_d_[i, j, l, k, n] 
               )

    @constraint(m, r_u_ehf_i_[i=P, j=P2, l=L, k=Kr, f=Fu_r[l], n=Nd;
                              r_filter[l, k] && nd_en_fltr[n]],
                r_u_ehf_d_[i, j, l, k, f, n] <= p.r_u_ehf_ub[f, l, n] * y_r[i, j, l, k]
               )

    @constraint(m, r_u_ehf_s_e_[i=P, j=P2, l=L, k=Kr, f=Fu_r[l], n=Nd;
                                r_filter[l, k] && nd_en_fltr[n]],
                r_u_ehf[i, j, l, f, n] == 
                sum(r_u_ehf_d_[i, j, l, k, f, n] for k in Kr if r_filter[l, k])
               )


    # -> process (intrinsic) emissions
    # r_cpe, r_cpe_d_ p.Cp & p.CpRhs, scaled! by subperiod
    @constraint(m, r_cpe_d_e_[i=P, j=P2, l=L, k=Kr, n=Nd;
                              r_filter[l, k] && nd_em_fltr[n]],
                r_cpe_d_[i, j, l, k, n] == 
                p.r_c_cpe[l, k, n] * r_cp_d_[i, j, l, k, n] + 
                p.r_rhs_cpe[l, k, n] * y_r[i, j, l, k]
               )
    # r_cpe_bM
    @constraint(m, r_cpe_m_i_[i=P, j=P2, l=L, k=Kr, n=Nd;
                              r_filter[l, k] && nd_em_fltr[n]],
                r_cpe_d_[i, j, l, k, n] <= p.r_cpe_ub[l, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_cpe_s_e_[i=P, j=P2, l=L, n=Nd; nd_em_fltr[n]],
                r_cpe[i, j, l, n] == 
                sum(r_cpe_d_[i, j, l, k, n] for k in Kr if r_filter[l, k]))
    

    ##########
    @constraint(m, r_fu_e_d_e_[i=P, j=P2, l=L, k=Kr, n=Nd;
                               r_filter[l, k] && nd_en_fltr[n]
                              ],
                r_fu_e_d_[i, j, l, k, n] == 
                sum(p.r_c_Fe[f, l, k, n] * r_ehf_d_[i, j, l, k, f, n] for f in Fu_r[l]) 
               )
    @constraint(m, r_fu_e_m_i_[i=P, j=P2, l=L, k=Kr, n=Nd; 
                               r_filter[l, k] && nd_en_fltr[n]
                              ],
                r_fu_e_d_[i, j, l, k, n] <= p.r_fu_e_ub[l, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_fu_e_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                r_fu_e[i, j, l, n] == 
                sum(r_fu_e_d_[i, j, l, k, n] for k in Kr if r_filter[l, k])
               )
    ##########
    @constraint(m, r_u_fu_e_d_e_[i=P, j=P2, l=L, k=Kr, n=Nd;
                                 r_filter[l, k] && nd_en_fltr[n]
                                ],
                r_u_fu_e_d_[i, j, l, k, n] == 
                sum(p.r_c_Fe[f, l, k, n] * r_u_ehf_d_[i, j, l, k, f, n] for f in Fu_r[l]) 
               )
    @constraint(m, r_u_fu_e_d_m_i_[i=P, j=P2, l=L, k=Kr, n=Nd;
                                   r_filter[l, k] && nd_en_fltr[n]
                                  ],
                r_u_fu_e_d_[i, j, l, k, n] <= p.r_u_fu_e_ub[l, n] * y_r[i, j, l, k]
               )
    @constraint(m, r_u_fu_e_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                r_u_fu_e[i, j, l, n] == 
                sum(r_u_fu_e_d_[i, j, l, k, n] for k in Kr if r_filter[l, k])
               )

    ##########
    # -> electricity emissions
    # GcI : grid carbon intensity
    #@constraint(m, r_u_em_e_[i=P, j=P2, l=L], 
    #            r_u_em[i, j, l] == p.GcI[i, j, l] * r_u[i, j, l]
    #           )
    # -> -> process (disaggregated) emissions

    # -> scope 0 emission
    # c_Fe (fuel emission factor) r_Hr (heat rate)
    @constraint(m, r_ep0_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ep0_d_[i, j, l, k] == 
                # fuel
                sum(r_fu_e_d_[i, j, l, k, n] for n in Nd if nd_en_fltr[n]) + 
                # process
                sum(r_cpe_d_[i, j, l, k, n] for n in Nd if nd_em_fltr[n]) + 
                # in-site electricity
                sum(r_u_fu_e_d_[i, j, l, k, n] for n in Nd if nd_en_fltr[n])
               )
    # r_ep0_ub[l]
    @constraint(m, r_ep0_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ep0_d_[i, j, l, k] <= p.r_ep0_ub[l] * y_r[i, j, l, k]
               )
    @constraint(m, r_ep0_s_e_[i=P, j=P2, l=L],
                r_ep0[i, j, l] == 
                sum(r_ep0_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )

    # -> scope 1 emitted
    # p.r_chi
    @constraint(m, r_ep1ge_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ep1ge_d_[i, j, l, k] == 
                (1.0 - p.r_chi[l, k]) * r_ep0_d_[i, j, l, k]
               )
    # r_ep1ge_ub[l]
    @constraint(m, r_ep1ge_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ep1ge_d_[i, j, l, k] <= p.r_ep1ge_ub[l] * y_r[i, j, l, k]
               )
    @constraint(m, r_ep1ge_s_e_[i=P, j=P2, l=L],
                r_ep1ge[i, j, l] == 
                sum(r_ep1ge_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )

    # -> scope 1 captured
    # p.r_sigma
    @constraint(m, r_ep1gce_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ep1gce_d_[i, j, l, k] == 
                p.r_chi[l, k] * (1 - p.r_sigma[l, k]) * r_ep0_d_[i, j, l, k]
               )
    @constraint(m, r_ep1gce_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ep1gce_d_[i, j, l, k] <= p.r_ep1gce_ub[l] * y_r[i, j, l, k]
               )
    @constraint(m, r_ep1gce_s_e_[i=P, j=P2, l=L],
                r_ep1gce[i, j, l] == 
                sum(r_ep1gce_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )

    # -> scope 1 stored
    # p.sigma ?
    @constraint(m, r_ep1gcs_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ep1gcs_d_[i, j, l, k] ==
                p.r_chi[l, k] * p.r_sigma[l, k] * r_ep0_d_[i, j, l, k]
               )
    # ep1gcsm_ub
    @constraint(m, r_ep1gcs_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ep1gcs_d_[i, j, l, k] <= p.r_ep1gcs_ub[l] * y_r[i, j, l, k]
               )

    @constraint(m, r_ep1gcs_s_e_[i=P, j=P2, l=L],
                r_ep1gcs[i, j, l] == 
                sum(r_ep1gcs_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )
    
    # -> upstream emission from input materials
    @constraint(m, r_ups_e_mt_in_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ups_e_mt_in_d_[i, j, l, k] == 
                sum(
                    sum(p.r_c_upsein_rate[l, c] * r_x_in_d_[i, j, l, k, n, c] for
                        c in Mt if node_mat[n, c] && c ∈ input_mat[n]
                       )
                    for n in Nd) 
               )
    # p.r_ups_e_mt_in_ub
    @constraint(m, r_ups_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ups_e_mt_in_d_[i, j, l, k] <= p.r_ups_e_mt_in_ub[l] * y_r[i, j, l, k]
               )
    @constraint(m, r_ups_e_mt_in_s_e_[i=P, j=P2, l=L],
                r_ups_e_mt_in[i, j, l] == sum(r_ups_e_mt_in_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )

    # 1
    @constraint(m, o_tups_e_mt_in_e_[i=P, j=P2, l=L],
                r_ups_e_mt_in[i, j, l] == 
                o_tups_e_mt_in_d_[i, j, l, sT] +
                o_tups_e_mt_in_d_[i, j, l, sF]
               )
    # 2
    @constraint(m, o_tups_e_mt_in_m1_i_[i=P, j=P2, l=L],
                o_tups_e_mt_in_d_[i, j, l, sT] <=
                p.o_ups_e_mt_in_ub[l] * y_o[i, j, l]
               )
    # 3
    @constraint(m, o_tups_e_mt_in_m0_i_[i=P, j=P2, l=L],
                o_tups_e_mt_in_d_[i, j, l, sF] <=
                p.o_ups_e_mt_in_ub[l] * (1 - y_o[i, j, l])
               )
    # 4
    @constraint(m, o_ups_e_mt_d_e_[i=P, j=P2, l=L],
                o_ups_e_mt_in_d_[i, j, l] == o_tups_e_mt_in_d_[i, j, l, sT])
    # 5
    @constraint(m, o_ups_e_mt_d_m_i_[i=P, j=P2, l=L], 
                o_ups_e_mt_in_d_[i, j, l] <= p.o_ups_e_mt_in_ub[l] * y_o[i, j, l])
    # 6
    @constraint(m, o_ups_e_mt_d_s_e_[i=P, j=P2, l=L], 
                o_ups_e_mt_in[i, j, l] == o_ups_e_mt_in_d_[i, j, l])

    # 76 
    # 76 #######################################################################
    # feedstock constraint
    #@constraint(m, r_fstck_d_e_[i=P, j=P2, l=L, k=Kr, f=Nf],
    #            r_fstck_d_[i, j, l, k, f] == 
    #            p.r_c_Fstck[l, k, f] * r_cp_d_[i, j, l, k]
    #            + p.r_rhs_Fstck[l, k, f] * y_r[i, j, l, k]
    #           )
    #@constraint(m, r_fstck_m_i_[i=P, j=P2, l=L, k=Kr, f=Nf],
    #            r_fstck_d_[i, j, l, k, f] <= 
    #            p.r_fstck_UB[l, k, f] * y_r[i, j, l, k]
    #           )
    #@constraint(m, r_fstck_s_e_[i=P, j=P2, l=L, f=Nf],
    #            r_fstck[i, j, l, f] == 
    #            sum(r_fstck_d_[i, j, l, k, f] for k in Kr)
    #           )
    
    # params include carbon intensity, chi and sigma.
    # chi : carbon capture
    # sigma : carbon storage
    
    # r_cpe and r_cpe_d_
    
    # ep_0 = (sum(hj*chj)+cp) * prod
    # ep_1ge = ep_0 * (1-chi)
    # ep_1gce = ep_0 * chi * (1-sigma)
    # ep_1gcs # stored ?
    # ep_1nge # not generated emmited
    # ep_2 = (sum(uj*cuj))

    # 76 
    # 76 #######################################################################
    ##
    # -> (fixed) operating and maintenance
    # p.m_fOnm, usd / year
    @constraint(m, r_cfonm_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_cfonm_d_[i, j, l, k] == 
                p.r_c_fOnm[l, k] * r_cpb_d_[i, j, l, k] + 
                p.r_rhs_fOnm[l, k] * y_r[i, j, l, k]
               )
    @constraint(m, r_cfonm_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_cfonm_d_[i, j, l, k] <= p.r_cfonm_ub[l] * y_r[i, j, l, k]
               )
    @constraint(m, r_cfonm_s_e_[i=P, j=P2, l=L],
                r_cfonm[i, j, l] == 
                sum(r_cfonm_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )
    # -> (variable) operating and maintenance
    # p.m_vOnm, usd / year
    @constraint(m, r_cvonm_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_cvonm_d_[i, j, l, k] == 
                p.r_c_vOnm[l, k] * r_cp_d_[i, j, l, k, key_node] + 
                p.r_rhs_vOnm[l, k] * y_r[i, j, l, k]
               )
    @constraint(m, r_cvonm_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_cvonm_d_[i, j, l, k] <= p.r_cvonm_ub[l] * y_r[i, j, l, k]
               )
    @constraint(m, r_cvonm_s_e_[i=P, j=P2, l=L],
                r_cvonm[i, j, l] == 
                sum(r_cvonm_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )
    # 76 
    # 76 #######################################################################
    ##
    # -> retrofit disagg LOAN added amount (ladd), p.r_loanFact
    #
    @constraint(m, r_ec_s_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                e_c[i, j, l] == 
                sum(r_e_c_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )

    @constraint(m, r_ec_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_e_c_d_[i, j, l, k] <= p.r_e_c_ub[l] * y_r[i, j, l, k]
               )

    # -> base loan
    #
    @constraint(m, r_l0_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_l0_d_[i, j, l, k] == 
                p.r_loanFact[i, j, l, k] * p.c0[l] * y_r[i, j, l, k]
               )
    # 
    #@constraint(m, r_l0_m_i_[i=P, j=P2, l=L, k=Kr],
    #            r_l0_d_[i, j, l, k] <= p.r_l0_ub[l, k] * y_r[i, j, l, k]
    #           )
    #
    @constraint(m, r_l0_s_e_[i=P, j=P2, l=L],
                r_l0[i, j, l] == 
                sum(r_l0_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )

    # -> expansion loan
    @constraint(m, r_le_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_le_d_[i, j, l, k] ==
                p.r_loanFact[i, j, l, k] * r_e_c_d_[i, j, l, k]
               )
    ## 
    @constraint(m, r_le_m_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_le_d_[i, j, l, k] <= p.r_le_ub[l, k] * y_r[i, j, l, k]
               )
    ##
    @constraint(m, r_le_s_e_[i=P, j=P2, l=L],
                r_le[i, j, l] == 
                sum(r_le_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )

    # 76 
    # 76 #######################################################################
    ##
    # -> retrofit disagg base payment (associated with the payment)
    # in units of usd/year
    @constraint(m, r_ann0_md_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ann0_d_[i, j, l, k] == 
                p.r_Ann[i, j, l, k] * r_l0_d_[i, j, l, k]
               ) # uses c0+expc
    @constraint(m, r_ann_mm_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_ann0_d_[i, j, l, k] <= p.r_ann0_bM[l] * y_r[i, j, l, k]
               )
    @constraint(m, r_ann_s_e_[i=P, j=P2, l=L],
                r_ann0[i, j, l] == 
                sum(r_ann0_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )
    ## -> retrofit expansion payment
    @constraint(m, r_anne_md_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_anne_d_[i, j, l, k] == 
                p.r_Ann[i, j, l, k] * r_le_d_[i, j, l, k]
               ) # uses c0+expc

    @constraint(m, r_anne_mm_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
                r_anne_d_[i, j, l, k] <= p.r_anne_bM[l] * y_r[i, j, l, k]
               )

    @constraint(m, r_anne_s_e_[i=P, j=P2, l=L],
                r_anne[i, j, l] == 
                sum(r_anne_d_[i, j, l, k] for k in Kr if r_filter[l, k])
               )

    # 76 
    # 76 #######################################################################
    ##
    rl0ub1d = maximum(p.r_l0_ub, dims=2)
    # --> padd switch (loan-switch), associated with the loan
    @constraint(m, r_l0add_d_e_[i=P, j=P2, l=L], 
                r_l0add_d_[i, j, l] == r_l0_pd_[i, j, l, sT]
               )
    # p_add_bM
    @constraint(m, r_l0add_m_0_y_i_[i=P, j=P2, l=L; j>fP2],
                r_l0add_d_[i, j, l] <= # goes from 1 to 0 only
                rl0ub1d[l] * (y_r[i, j-1, l, fKr] - y_r[i, j, l, fKr])
               )
    # lit the moment the 0th (fKr) is switched
    #
    @constraint(m, r_l0add_s_e_[i=P, j=P2, l=L],
                r_l0add[i, j, l] == r_l0add_d_[i, j, l]
               )
    # padd switch (loan-retrofit)
    #
    @constraint(m, r_l0_m_1_y_i_[i=P, j=P2, l=L; j>fP2], # false
                r_l0_pd_[i, j, l, sF] <=
                rl0ub1d[l] * (1.0 - y_r[i, j-1, l, fKr] + y_r[i, j, l, fKr])
               )
    # connection to the retrofit 
    @constraint(m, r_l0_p_s_e_[i=P, j=P2, l=L], #  i had to shift this
                r_l0[i, j, l] == r_l0_pd_[i, j, l, sT] + r_l0_pd_[i, j, l, sF]
               )
    # 76 
    # 76 #######################################################################
    ##
    rleub1d = maximum(p.r_le_ub, dims=2)
    # --> expansion terms 
    @constraint(m, r_leadd_d_e_[i=P, j=P2, l=L], 
                r_leadd_d_[i, j, l] == r_le_pd_[i, j, l, sT]
               )
    ## 
    @constraint(m, r_leadd_m_1_y_i_[i=P, j=P2, l=L; j>fP2],
                r_leadd_d_[i, j, l] <= # goes from 1 to 0 only
                rleub1d[l] * (y_r[i, j-1, l, fKr] - y_r[i, j, l, fKr])
               )
    ##
    @constraint(m, r_leadd_s_e_[i=P, j=P2, l=L],
                r_leadd[i, j, l] == r_leadd_d_[i, j, l]
               )
    ##
    @constraint(m, r_le_m_1_y_i_[i=P, j=P2, l=L; j>fP2], # false
                r_le_pd_[i, j, l, sF] <=
                rleub1d[l] * (1.0 - y_r[i, j-1, l, fKr] + y_r[i, j, l, fKr])
               )
    ## connection to the retrofit 
    @constraint(m, r_le_p_s_e_[i=P, j=P2, l=L], #
                r_le[i, j, l] == r_le_pd_[i, j, l, sT] + r_le_pd_[i, j, l, sF]
               )
    # r_leadde_d_
    # r_le_ped_
    @constraint(m, r_leadde_d_e_[i=P, j=P2, l=L], 
                r_leadde_d_[i, j, l] == r_le_ped_[i, j, l, sT]
               )
    @constraint(m, r_leadde_s_e_[i=P, j=P2, l=L],
                r_leadde[i, j, l] == r_leadde_d_[i, j, l]
               )
    @constraint(m, r_le_pe_s_e_[i=P, j=P2, l=L], #
                r_le[i, j, l] == r_le_ped_[i, j, l, sT] + r_le_ped_[i, j, l, sF]
               )
    @constraint(m, r_leadd_m_2_y_i_[i=P, j=P2, l=L; j>fP2],
                r_leadde_d_[i, j, l] <= # goes from 1 to 0 only
                rleub1d[l] * (y_e[i, j, l] - y_e[i, j-1, l])
               )
    @constraint(m, r_le_m_2_y_i_[i=P, j=P2, l=L; j>fP2], # false
                r_le_ped_[i, j, l, sF] <=
                rleub1d[l] * (1 - y_e[i, j, l] + y_e[i, j-1, l])
               )
    # 76 
    # 76 #######################################################################
    ##
    # -> loan disaggregation, r_yps = 1 if paid, 0 otw
    @constraint(m, r_loan_ps_s_e_[i=P, j=P2, l=L],
                r_loan[i, j, l] == r_loan_p[i, j, l] - r_loan_n[i, j, l]
               )
    @constraint(m, r_loan_p_m0_i_[i=P, j=P2, l=L],
                r_loan_p[i, j, l] <= p.r_loan_ub[l] * (1 - r_yps[i, j, l])
               )
    # this equation might become a problem. 
    @constraint(m, r_loan_n_m0_i_[i=P, j=P2, l=L],
                r_loan_n[i, j, l] <= p.r_loan_ub[l] * r_yps[i, j, l]
               )
    # payment
    @constraint(m, r_pay0_s_e_[i=P, j=P2, l=L],
                r_pay0[i, j, l] == r_pay0_1[i, j, l]
               )
    @constraint(m, r_pay0_1_m0_i_[i=P, j=P2, l=L],
                r_pay0_1[i, j, l] <= p.r_ann0_bM[l] * (1 - r_yps[i, j, l])
               )
    # annuity->payment
    @constraint(m, r_ann0_01_s_e_[i=P, j=P2, l=L],
                r_ann0[i, j, l] == r_ann0_0[i, j, l] + r_ann0_1[i, j, l]
               )
    @constraint(m, r_ann0_0_m_i_[i=P, j=P2, l=L],
                r_ann0_0[i, j, l] <= p.r_ann0_bM[l] * r_yps[i, j, l]
               )
    @constraint(m, r_ann0_1_m_i_[i=P, j=P2, l=L],
                r_ann0_1[i, j, l] <= p.r_ann0_bM[l] * (1 - r_yps[i, j, l])
               )
    @constraint(m, r_ann0_d0_e_[i=P, j=P2, l=L],
                r_ann0_1[i, j, l] == r_pay0_1[i, j, l]
               )

    # retrofit-expansion payment
    @constraint(m, r_paye_s_e_[i=P, j=P2, l=L],
                r_paye[i, j, l] == r_paye_1[i, j, l]
               )
    @constraint(m, r_paye_1_m0_i_[i=P, j=P2, l=L],
                r_paye_1[i, j, l] <= p.r_anne_bM[l] * (1 - r_yps[i, j, l])
               )
    ## retrofit-expansion->payment
    @constraint(m, r_anne_01_s_e_[i=P, j=P2, l=L],
                r_anne[i, j, l] == r_anne_0[i, j, l] + r_anne_1[i, j, l]
               )
    @constraint(m, r_anne_0_m_i_[i=P, j=P2, l=L],
                r_anne_0[i, j, l] <= p.r_anne_bM[l] * r_yps[i, j, l]
               )
    @constraint(m, r_anne_1_m_i_[i=P, j=P2, l=L],
                r_anne_1[i, j, l] <= p.r_anne_bM[l] * (1 - r_yps[i, j, l])
               )
    @constraint(m, r_anne_d0_e_[i=P, j=P2, l=L],
                r_anne_1[i, j, l] == r_paye_1[i, j, l]
               )
    # logic
    @constraint(m, r_logic_yps_yr[i=P, j=P2, l=L; j>fP2],
                (y_r[i, j-1, l, fKr] - y_r[i, j, l, fKr]) + r_yps[i, j, l]
                <= 1.0
               )

    # if the plant becomes retired r_pay0_p might still be positive
    # 76 
    # 76 #######################################################################
    ##
    # -> loan balance
    @constraint(m, r_loan_bal_y_e_[i=P, j=P2, l=L; j<n_subperiods],
                r_loan[i, j+1, l] == 
                r_loan[i, j, l] * (1+p.interest)^p.yr_subperiod
                - r_pay0[i, j, l] * sum((1+p.interest)^k for k in 0:(p.yr_subperiod-1))
                - r_paye[i, j, l] * sum((1+p.interest)^k for k in 0:(p.yr_subperiod-1))
                + r_l0add[i, j, l] * (1+p.interest)^(p.yr_subperiod-1) 
                + r_leadd[i, j, l] * (1+p.interest)^(p.yr_subperiod-1) 
                + r_leadde[i, j, l] * (1+p.interest)^(p.yr_subperiod-1) 
               )
    # 76 
    # 76 #######################################################################
    ##
    # do this loop only for input materials
    @constraint(m, r_mass_b_e_[i=P, j=P2, l=L, k=Kr, n=Nd, c=Mt; 
                               r_filter[l, k] && node_mat[n, c] && !skip_mb[n, c]],
                f_xin(m, i, j, l, k, n, c, input_mat; mode="r") 
                - f_xout(m, i, j, l, k, n, c, output_mat; mode="r")
                #+ sum(p.r_Kmb[n, c, c1, k] * r_x_out_d_[i, j, l, k, n, c1] for c1 in Mt
                + (p.r_Kmb[n, c, ckey[n], k] * r_cp_d_[i, j, l, k, n]) == 0.0
               )

    # node_out, node_in, component
    # links_list = [(1, 2, 2)]
    @constraint(m, r_comp_link_e_[i=P, j=P2, l=L, lnk=Ln],
                r_x_out[i, j, l, links_list[lnk][1], links_list[lnk][3]] 
                == 
                r_x_in[i, j, l, links_list[lnk][2], links_list[lnk][3]]
               )
    #
    @constraint(m, r_x_in_m_i_[i=P, j=P2, l=L, k=Kr, n=Nd, c=Mt; 
                               r_filter[l, k] && node_mat[n, c]
                               && c ∈ input_mat[n]],
                r_x_in_d_[i, j, l, k, n, c] <= 
                p.r_x_in_ub[l, n, c] * y_r[i, j, l, k]
               )
    @constraint(m, r_x_in_s_e_[i=P, j=P2, l=L, n=Nd, c=Mt; 
                               node_mat[n, c] && c ∈ input_mat[n]],
                r_x_in[i, j, l, n, c] == 
                sum(r_x_in_d_[i, j, l, k, n, c] for k in Kr if r_filter[l, k])
               )
    #
    @constraint(m, r_x_out_m_i_[i=P, j=P2, l=L, k=Kr, n=Nd, c=Mt; 
                                r_filter[l, k] && node_mat[n, c] && 
                                c ∈ output_mat[n]],
                r_x_out_d_[i, j, l, k, n, c] <= 
                p.r_x_out_ub[l, n, c] * y_r[i, j, l, k]
               )
    @constraint(m, r_x_out_s_e_[i=P, j=P2, l=L, n=Nd, c=Mt; 
                                node_mat[n, c] && c ∈ output_mat[n]],
                r_x_out[i, j, l, n, c] == 
                sum(r_x_out_d_[i, j, l, k, n, c] for k in Kr if r_filter[l, k])
               )
    #
    # o_x_in_d_ input (existing)
    @constraint(m, o_tx_in_s_e_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ input_mat[n]],
                r_x_in[i, j, l, n, c] == 
                o_tx_in_d_[i, j, l, n, c, sT] + o_tx_in_d_[i, j, l, n, c, sF]
               )
    @constraint(m, o_tx_in_m1_i_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ input_mat[n]],
                o_tx_in_d_[i, j, l, n, c, sT] <= 
                p.o_x_in_ub[l, n, c] * y_o[i, j, l]
               )
    @constraint(m, o_tx_in_m0_i_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ input_mat[n]],
                o_tx_in_d_[i, j, l, n, c, sF] <= 
                p.o_x_in_ub[l, n, c] * (1 - y_o[i, j, l])
               )
    @constraint(m, o_x_in_d_e_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ input_mat[n]],
                o_x_in_d_[i, j, l, n, c] == o_tx_in_d_[i, j, l, n, c, sT]
               )
    @constraint(m, o_x_in_m_i_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ input_mat[n]],
                o_x_in_d_[i, j, l, n, c] <= 
                p.o_x_in_ub[l, n, c] * y_o[i, j, l]
               )
    @constraint(m, o_x_in_s_e_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ input_mat[n]],
                o_x_in[i, j, l, n, c] == o_x_in_d_[i, j, l, n, c]
               )
    # o_x_out_d_ output (existing)
    # 1
    @constraint(m, o_tx_out_s_e_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ output_mat[n]],
                r_x_out[i, j, l, n, c] ==
                o_tx_out_d_[i, j, l, n, c, sT] + o_tx_out_d_[i, j, l, n, c, sF]
               )
    # 2
    @constraint(m, o_tx_out_m1_i_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ output_mat[n]],
                o_tx_out_d_[i, j, l, n, c, sT] <=
                p.o_x_out_ub[l, n, c] * y_o[i, j, l]
               )
    # 3
    @constraint(m, o_tx_out_m0_i_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ output_mat[n]],
                o_tx_out_d_[i, j, l, n, c, sF] <=
                p.o_x_out_ub[l, n, c] * (1 - y_o[i, j, l])
               )
    # 4
    @constraint(m, o_x_out_d_e_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ output_mat[n]],
                o_x_out_d_[i, j, l, n, c] == o_tx_out_d_[i, j, l, n, c, sT]
               )
    # 5
    @constraint(m, o_x_out_m_i_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ output_mat[n]],
                o_x_out_d_[i, j, l, n, c] <=
                p.o_x_out_ub[l, n, c] * y_o[i, j, l]
               )
    # 6
    @constraint(m, o_x_out_s_e_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ output_mat[n]],
                o_x_out[i, j, l, n, c] == o_x_out_d_[i, j, l, n, c]
               )

    # 76 
    # 76 #######################################################################
    ##
    # -> retirement
    # retirement is just r_loan, we just need a way to activate it. 
    # a) have a switch using y_o going from 0 to 1
    # b) take the snapshot of the current value of r_loan and use it as the cost
    #
    @constraint(m, t_ret_c_d_e_[i=P, j=P2, l=L],  # only enforceable at switch
                t_ret_cost_d_[i, j, l] == t_loan_d_[i, j, l, sT]
               )

    # t_ret_c_bM[l]
    @constraint(m, t_ret_c_bm_0_y_i_[i=P, j=P2, l=L; j<n_subperiods],
                t_ret_cost_d_[i, j, l] <= 
                # only 1 -> 0 -> true
                #p.t_ret_c_bM[l] * (y_o[t-1, l] - y_o[i, j, l])
                p.t_ret_c_bM[l] * (y_o[i, j, l] - y_o[i, j+1, l])
               )

    # m_loan_d_bM
    @constraint(m, r_loan_d_bm_0_y_i_[i=P, j=P2, l=L; j<n_subperiods],
                t_loan_d_[i, j, l, sT] <=  # retired
                #p.t_loan_bM[l] * (y_o[t-1, l] - y_o[i, j, l])
                p.t_loan_bM[l] * (y_o[i, j, l] - y_o[i,j+1, l])
               )
    # m_loan_d_bM
    @constraint(m, r_loan_d_bm_1_y_i_[i=P, j=P2, l=L; j<n_subperiods], 
                # not retired
                t_loan_d_[i, j, l, sF] <= p.t_loan_bM[l] * 
                (1 + y_o[i,j+1, l] - y_o[i, j, l])
               )
    @constraint(m, t_ret_c_s_e_[i=P, j=P2, l=L],
                t_ret_cost[i, j, l] == t_ret_cost_d_[i, j, l]  
                # only one needed
               )
               
    @constraint(m, r_loan_s_e_[i=P, j=P2, l=L],  # total loan
                r_loan_p[i, j, l] + e_loan_p[i, j, l]
                == t_loan_d_[i, j, l, sT] + t_loan_d_[i, j, l, sF]
               )
    # -> total payment (retrofit/existing + )
    @constraint(m, o_pay_s_e_[i=P, j=P2, l=L],
                o_pay[i, j, l] == o_pay_d_[i, j, l]
               )
    @constraint(m, o_pay_d1_e_[i=P, j=P2, l=L], # online
                # there is pay for retrof but not for expansion
                o_pay_d_[i, j, l] == o_tpay_d_[i, j, l, sT]
               )
    @constraint(m, o_pay_m_1_i_[i=P, j=P2, l=L], # on
                o_pay_d_[i, j, l] <= p.o_pay_bM[l] * y_o[i, j, l]
               )
    # this one includes both expansion and retrof
    @constraint(m, o_tpay_s_e_[i=P, j=P2, l=L],
                r_pay0[i, j, l] + r_paye[i, j, l] 
                + e_pay[i, j, l] == 
                o_tpay_d_[i, j, l, sF] + o_tpay_d_[i, j, l, sT]
               )
    #
    @constraint(m, o_tpay_m1_i_[i=P, j=P2, l=L], # on
                o_tpay_d_[i, j, l, sT] <= p.o_pay_bM[l] * y_o[i, j, l]
               )
    #
    @constraint(m, o_tpay_m0_i_[i=P, j=P2, l=L], # off
                o_tpay_d_[i, j, l, sF] <= p.o_pay_bM[l] * (1 - y_o[i, j, l])
               )
    # -> (fixed) o&m
    @constraint(m, o_cfonm_s_e_[i=P, j=P2, l=L],
                o_cfonm[i, j, l] == o_cfonm_d_[i, j, l]
               )
    @constraint(m, o_cfonm_d1_e_[i=P, j=P2, l=L],
                o_cfonm_d_[i, j, l] == o_tcfonm_d_[i, j, l, sT]
               )

    @constraint(m, o_cfonm_m_1_i_[i=P, j=P2, l=L], # on
                o_cfonm_d_[i, j, l] <= p.o_cfonm_bM[l] * y_o[i, j, l]
               )
    #
    @constraint(m, o_tcfonm_m1_i_[i=P, j=P2, l=L],
                o_tcfonm_d_[i, j, l, sT] <= p.o_cfonm_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_tcfonm_m0_i_[i=P, j=P2, l=L],
                o_tcfonm_d_[i, j, l, sF] <= p.o_cfonm_bM[l] * (1 - y_o[i, j, l])
               )
    @constraint(m, o_tcfonm_s_e_[i=P, j=P2, l=L],
                r_cfonm[i, j, l] == 
                o_tcfonm_d_[i, j, l, sT] + o_tcfonm_d_[i, j, l, sF]
               )
    # -> (variable) o&m
    @constraint(m, o_cvonm_s_e_[i=P, j=P2, l=L],
                o_cvonm[i, j, l] == o_cvonm_d_[i, j, l]
               )
    @constraint(m, o_cvonm_d1_e_[i=P, j=P2, l=L],
                o_cvonm_d_[i, j, l] == o_tcvonm_d_[i, j, l, sT]
               )

    @constraint(m, o_cvonm_m_1_i_[i=P, j=P2, l=L], # on
                o_cvonm_d_[i, j, l] <= p.o_cvonm_bM[l] * y_o[i, j, l]
               )
    #
    @constraint(m, o_tcvonm_m1_i_[i=P, j=P2, l=L],
                o_tcvonm_d_[i, j, l, sT] <= p.o_cvonm_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_tcvonm_m0_i_[i=P, j=P2, l=L],
                o_tcvonm_d_[i, j, l, sF] <= p.o_cvonm_bM[l] * (1 - y_o[i, j, l])
               )
    @constraint(m, o_tcvonm_s_e_[i=P, j=P2, l=L],
                r_cvonm[i, j, l] == 
                o_tcvonm_d_[i, j, l, sT] + o_tcvonm_d_[i, j, l, sF]
               )
    # 76 
    # 76 #######################################################################
    ##
    # -> new plant capacity
    #@constraint(m, n_c0_e_[l=L],
    #            n_c0[l] >= p.c0[l+1]
    #           )
    # -> new plant capacity disaggregation
    @constraint(m, n_cp0_d_e_[i=P, j=P2, l=L, n=Nd],
                n_cp_d_[i, j, l, fKn, n] == 0
               ) # how do we make this 0 at k=0?
    @constraint(m, n_cp_ub_i_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                              k>fKn && n_filter[l, k]],
                n_cp_d_[i, j, l, k, n] <= 
                n_c0_d_[i, j, l, k] * p.n_Kkey_j[n, k]
               )
    @constraint(m, n_cp_lb_i_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                              k>fKn && n_filter[l, k]],
                n_c0_d_[i, j, l, k] *  p.min_cpr[l]
                <= n_cp_d_[i, j, l, k, key_node]
               )

    #@constraint(m, n_c0_d0_i_[i=P, j=P2, l=L, k=Kn; k>0],
    #            n_c0_d_[i, j, l, k] >= p.c0[l+1] * y_n[i, j, l, k]
    #           )

    @constraint(m, n_cp_m_i_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                             k>fKn && n_filter[l, k]],
                n_cp_d_[i, j, l, k, n] <= p.n_cp_bM[l, n] * y_n[i, j, l, k]
               )

    @constraint(m, n_cap_add_d_lo_i_[i=P, j=P2, l=L, k=Kn; 
                                     n_filter[l, k]],
                n_c0_d_[i, j, l, k] >= p.n_c0_lo[l, k] * y_n[i, j, l, k]
               )
    @constraint(m, n_cap_add_d_m_i_[i=P, j=P2, l=L, k=Kn;
                                    n_filter[l, k]],
                n_c0_d_[i, j, l, k] <= p.n_c0_bM[l] * y_n[i, j, l, k]
               )
    #
    @constraint(m, n_cp_s_e_[i=P, j=P2, l=L, n=Nd],
                n_cp[i, j, l, n] == 
                sum(n_cp_d_[i, j, l, k, n] for k in Kn if n_filter[l, k])
               )
    
    @constraint(m, n_cp_x_e_[i=P, j=P2, l=L, k=Kn, n=Nd; n_filter[l, k]],
                n_cp_d_[i, j, l, k, n] == 
                n_x_out_d_[i, j, l, k, n, ckey[n]] + n_x_o_s_d_[i, j, l, k, n]
               )

    @constraint(m, n_c0_s_e_[i=P, j=P2, l=L],
                n_c0[i, l] == 
                sum(n_c0_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )

    # 76 
    # 76 #######################################################################
    ##
    # -> base loan (proportional to the capacity)
    # measured in usd/year
    @constraint(m, n_l_d0_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_l_d_[i, j, l, k] == 
                p.n_loanFact[l, k] * n_c0_d_[i, j, l, k]
               ) # this should be 0 at 0th  
    # perhaps this should be n_c0_d_
    @constraint(m, n_l_m_i0_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_l_d_[i, j, l, k] <= p.n_l_bM[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_l_s_[i=P, j=P2, l=L],
                n_l[i, j, l] == 
                sum(n_l_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )
    # -> annuity (how much we pay)
    @constraint(m, n_ann_d0_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ann_d_[i, j, l, k] == p.n_Ann[l, k] * n_l_d_[i, j, l, k]
               )
    @constraint(m, n_ann_m_i0_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ann_d_[i, j, l, k] <= p.n_ann_bM[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_ann_s_[i=P, j=P2, l=L],
                n_ann[i, j, l] == 
                sum(n_ann_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )
    
    # 76 
    # 76 #######################################################################
    ##
    # -> 
    # link the n_cost_ to the ladd in a single time period.
    # change the index
    # change ?
    @constraint(m, n_ladd_m_0_y_i_[i=P, j=P2, l=L; j>fP2], 
                n_ladd_d_[i, j, l] <= # 1->0 : true 
                p.n_ladd_bM[l] * (y_n[i, j-1, l, fKn] - y_n[i, j, l, fKn])
               ) # y_n goes from 1 to 0

    @constraint(m, n_l_pd_m_1_y_i_[i=P, j=P2, l=L; j>fP2],
                n_l_pd_[i, j, l, sF] <= 
                p.n_l_bM[l] * (1 + y_n[i, j, l, fKn] - y_n[i, j-1, l, fKn])
               )
    #
    @constraint(m, n_ladd_d0_e_[i=P, j=P2, l=L],
                n_ladd_d_[i, j, l] == n_l_pd_[i, j, l, sT]
               )
    @constraint(m, n_ladd_s_e_[i=P, j=P2, l=L],
                n_ladd[i, j, l] == n_ladd_d_[i, j, l]
               )
    @constraint(m, n_l_s_e_[i=P, j=P2, l=L],
                n_l[i, j, l] ==
                n_l_pd_[i, j, l, sT] + n_l_pd_[i, j, l, sF]
               )

    # loan
    @constraint(m, n_loan_s_e_[i=P, j=P2, l=L],
                n_loan[i, j, l] == n_loan_p[i, j, l] - n_loan_n[i, j, l]
               )
    @constraint(m, n_loan_p_m0_i_[i=P, j=P2, l=L],
                n_loan_p[i, j, l] <= p.n_loan_bM[l] * (1 - n_yps[i, j, l])
               )
    @constraint(m, n_loan_n_m0_i_[i=P, j=P2, l=L],
                n_loan_n[i, j, l] <= p.n_loan_bM[l] * n_yps[i, j, l]
               )
    # pay
    @constraint(m, n_pay_s_e_[i=P, j=P2, l=L],
                n_pay[i, j, l] == n_pay_1[i, j, l]
               )
    # note: this mechanism seems to have a lag of 1 period.
    @constraint(m, n_pay_n_m0_i_[i=P, j=P2, l=L],
                n_pay_1[i, j, l] <= p.n_pay_bM[l] * (1 - n_yps[i, j, l])
               )
    # annuity
    @constraint(m, n_ann_s_e_[i=P, j=P2, l=L],
                n_ann[i, j, l] == n_ann_0[i, j, l] + n_ann_1[i, j, l]
               )
    @constraint(m, n_ann_0_m_i_[i=P, j=P2, l=L],
                n_ann_0[i, j, l] <= p.n_ann_bM[l] * n_yps[i, j, l]
               )
    @constraint(m, n_ann_1_m_i_[i=P, j=P2, l=L],
                n_ann_1[i, j, l] <= p.n_ann_bM[l] * (1 - n_yps[i, j, l])
               )
    @constraint(m, n_pay_d0_e_[i=P, j=P2, l=L],
                n_pay_1[i, j, l] == n_ann_1[i, j, l]
               )

    # logic
    @constraint(m, n_logic_yps_yn[i=P, j=P2, l=L; j>fP2],
                (y_n[i, j-1, l, fKn] - y_n[i, j, l, fKn]) + n_yps[i, j, l] 
                <= 1
               )

    # 76 
    # 76 #######################################################################
    ##
    # -> expansion loan balance
    @constraint(m, n_loan_bal_y_e_[i=P, j=P2, l=L; j<n_subperiods],
                n_loan[i, j+1, l] == 
                n_loan[i, j, l] * (1+p.interest)^p.yr_subperiod
                - n_pay[i, j, l] * sum((1+p.interest)^k for k in 0:(p.yr_subperiod-1))
                + n_ladd[i, j, l] * (1+p.interest)^(p.yr_subperiod-1)
               )
    # 76 
    # 76 #######################################################################
    ##
    # -> heating requirement.
    # p.Hm (heating factor, i.e. heat / product), scaled!
    @constraint(m, n_eh_d_e_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                             n_filter[l, k] && nd_en_fltr[n]
                            ],
                n_eh_d_[i, j, l, k, n] ==
                p.n_c_H[l, k, n] * n_cp_d_[i, j, l, k, n] + 
                p.n_rhs_H[l, k, n] * y_n[i, j, l, k]
               )
    @constraint(m, n_eh_d_m_i_[i=P, j=P2, l=L, k=Kn, n=Nd;
                               n_filter[l, k] && nd_en_fltr[n]
                              ],
                n_eh_d_[i, j, l, k, n] <= p.n_eh_ub[l, n] * y_n[i, j, l, k]
               )
    @constraint(m, n_eh_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                n_eh[i, j, l, n] == 
                sum(n_eh_d_[i, j, l, k, n] for k in Kn if n_filter[l, k])
               )
    # -> fuel required for heat.
    # p.n_c_F in [0,1], (i.e. a fraction, heat by fuel /tot heat)
    @constraint(m, n_ehf_d_e_[i=P, j=P2, l=L, k=Kn, f=Fu_n[l], n=Nd;
                              n_filter[l, k] && nd_en_fltr[n]
                             ],
                n_ehf_d_[i, j, l, k, f, n] ==
                p.n_c_F[f, l, k, n] * n_eh_d_[i, j, l, k, n] + 
                p.n_rhs_F[f, l, k, n] * y_n[i, j, l, k]
               )
    # n_ehf_ub
    @constraint(m, n_ehf_m_i_[i=P, j=P2, l=L, k=Kn, f=Fu_n[l], n=Nd;
                              n_filter[l, k] && nd_en_fltr[n] 
                             ],
                n_ehf_d_[i, j, l, k, f, n] <= p.n_ehf_ub[f, l, n] * y_n[i, j, l, k]
               )
    @constraint(m, n_ehf_s_e_[i=P, j=P2, l=L, f=Fu_n[l], n=Nd;
                              nd_en_fltr[n]],
                n_ehf[i, j, l, f, n] == 
                sum(n_ehf_d_[i, j, l, k, f, n] for k in Kn if n_filter[l, k])
               )

    # -> electricity requirement
    # n_u and m_ud_, p.Um & p.UmRhs, scaled!
    @constraint(m, n_u_d_e_[i=P, j=P2, l=L, k=Kn, n=Nd;
                            n_filter[l, k] && nd_en_fltr[n]
                           ],
                n_u_d_[i, j, l, k, n] == 
                (1-p.n_c_UonSite[i, j, l, k, n]) * (p.n_c_U[l, k, n] * n_cp_d_[i, j, l, k, n] + p.n_rhs_U[l, k, n] * y_n[i, j, l, k]) 
               )
    # n_u_ub[l, n] (big-M)
    @constraint(m, n_u_i_[i=P, j=P2, l=L, k=Kn, n=Nd;
                          n_filter[l, k] && nd_en_fltr[n]
                         ],
                n_u_d_[i, j, l, k, n] <= p.n_u_ub[l, n] * y_n[i, j, l, k]
               )
    @constraint(m, n_u_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                n_u[i, j, l, n] == 
                sum(n_u_d_[i, j, l, k, n] for k in Kn if n_filter[l, k])
               )
    # -> electricity on-site 
    # n_u_onsite, n_c_Uonsite viz. the onsite fraction, scaled!
    @constraint(m, n_u_onsite_d_e_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                                   n_filter[l, k] && nd_en_fltr[n]
                                  ],
                n_u_onsite_d_[i, j, l, k, n] == 
                (p.n_c_UonSite[i, j, l, k, n]) * (p.n_c_U[l, k, n] * n_cp_d_[i, j, l, k, n] + p.n_rhs_U[l, k, n] * y_n[i, j, l, k])
               )
    # n_u_ub[l, n] (big-M)
    @constraint(m, n_u_onsite_i_[i=P, j=P2, l=L, k=Kn, n=Nd;
                                 n_filter[l, k] && nd_en_fltr[n]
                                ],
                n_u_onsite_d_[i, j, l, k, n] <= p.n_u_ub[l, n] * y_n[i, j, l, k]
               )
    @constraint(m, n_u_onsite_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                n_u_onsite[i, j, l, n] == 
                sum(n_u_onsite_d_[i, j, l, k, n] for k in Kn if n_filter[l, k])
               )

    # fuel from electricity generation
    @constraint(m, n_u_ehf_e_[i=P, j=P2, l=L, k=Kn, f=Fu_n[l], n=Nd; 
                              n_filter[l, k] && nd_en_fltr[n]
                             ],
                n_u_ehf_d_[i, j, l, k, f, n] == 
                (
                 p.n_c_Hr[f, l, k, n]*p.n_c_Fgenf[f, l, k, n]
                 *n_u_onsite_d_[i, j, l, k, n]
                )
               )

    @constraint(m, n_u_ehf_i_[i=P, j=P2, l=L, k=Kn, f=Fu_n[l], n=Nd;
                              n_filter[l, k] && nd_en_fltr[n]
                             ],
                n_u_ehf_d_[i, j, l, k, f, n] <= p.n_u_ehf_ub[f, l, n] * y_n[i, j, l, k]
               )

    @constraint(m, n_u_ehf_s_e_[i=P, j=P2, l=L, k=Kn, f=Fu_n[l], n=Nd; 
                                n_filter[l, k] && nd_en_fltr[n]
                               ],
                n_u_ehf[i, j, l, f, n] == 
                sum(n_u_ehf_d_[i, j, l, k, f, n] for k in Kn if n_filter[l, k])
               )
    
    # -> process (intrinsic) emissions
    # n_cpe, n_cpe_d_. p.Cp & p.CpRhs, scaled!
    @constraint(m, n_cpe_d_e_[i=P, j=P2, l=L, k=Kn, n=Nd;
                              n_filter[l, k] && nd_em_fltr[n]],
                n_cpe_d_[i, j, l, k, n] == 
                p.n_c_cpe[l, k, n] * n_cp_d_[i, j, l, k, n] + 
                p.n_rhs_cpe[l, k, n] * y_n[i, j, l, k]
               )
    # n_cpe_ub
    @constraint(m, n_cpe_m_i_[i=P, j=P2, l=L, k=Kn, n=Nd;
                              n_filter[l, k] && nd_em_fltr[n]],
                n_cpe_d_[i, j, l, k, n] <= p.n_cpe_ub[l, n] * y_n[i, j, l, k]
               )
    @constraint(m, n_cpe_s_e_[i=P, j=P2, l=L, n=Nd; nd_em_fltr[n]],
                n_cpe[i, j, l, n] == 
                sum(n_cpe_d_[i, j, l, k, n] for k in Kn if n_filter[l, k])
               )
    ##########
    @constraint(m, n_fu_e_d_e_[i=P, j=P2, l=L, k=Kn, n=Nd;
                               n_filter[l, k] && nd_en_fltr[n]],
                n_fu_e_d_[i, j, l, k, n] == 
                sum(p.n_c_Fe[f, l, k, n] * n_ehf_d_[i, j, l, k, f, n] for f in Fu_n[l]) 
               )
    @constraint(m, n_fu_e_m_i_[i=P, j=P2, l=L, k=Kn, n=Nd;
                               n_filter[l, k] && nd_en_fltr[n]
                              ],
                n_fu_e_d_[i, j, l, k, n] <= p.n_fu_e_ub[l, n] * y_n[i, j, l, k]
               )
    @constraint(m, n_fu_e_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                n_fu_e[i, j, l, n] == 
                sum(n_fu_e_d_[i, j, l, k, n] for k in Kn if n_filter[l, k])
               )
    ##########
    @constraint(m, n_u_fu_e_d_e_[i=P, j=P2, l=L, k=Kn, n=Nd; 
                                 n_filter[l, k] && nd_en_fltr[n]
                                ],
                n_u_fu_e_d_[i, j, l, k, n] == 
                sum(p.n_c_Fe[f, l, k, n] * n_u_ehf_d_[i, j, l, k, f, n] for f in Fu_n[l]) 
               )
    @constraint(m, n_u_fu_e_d_m_i_[i=P, j=P2, l=L, k=Kn, n=Nd;
                                   n_filter[l, k] && nd_en_fltr[n]
                                  ],
                n_u_fu_e_d_[i, j, l, k, n] <= p.n_u_fu_e_ub[l, n] * y_n[i, j, l, k]
               )
    @constraint(m, n_u_fu_e_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                n_u_fu_e[i, j, l, n] == 
                sum(n_u_fu_e_d_[i, j, l, k, n] for k in Kn if n_filter[l, k])
               )
    ##########

    # -> -> process (disaggregated) emissions

    # -> scope 0 emission
    # c_Fe (fuel emission factor), n_Hr (heat rate)
    @constraint(m, n_ep0_d_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ep0_d_[i, j, l, k] == 
                # fuel
                sum(n_fu_e_d_[i, j, l, k, n] for n in Nd if nd_en_fltr[n]) + 
                # process
                sum(n_cpe_d_[i, j, l, k, n] for n in Nd if nd_em_fltr[n]) + 
                # in-site electricity
                sum(n_u_fu_e_d_[i, j, l, k, n] for n in Nd if nd_en_fltr[n])
               )
    # n_ep0_bM
    @constraint(m, n_ep0_m_i_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ep0_d_[i, j, l, k] <= p.n_ep0_bM[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_ep0_s_e_[i=P, j=P2, l=L],
                n_ep0[i, j, l] == 
                sum(n_ep0_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )
    # -> scope 1 emitted
    # p.n_chi
    @constraint(m, n_ep1ge_d_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ep1ge_d_[i, j, l, k] == 
                (1.0 - p.n_chi[l, k])*n_ep0_d_[i, j, l, k]
               )
    # n_ep1ge_bM[l]
    @constraint(m, n_ep1ge_m_i_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ep1ge_d_[i, j, l, k] <= p.n_ep1ge_bM[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_ep1ge_s_e_[i=P, j=P2, l=L],
                n_ep1ge[i, j, l] == 
                sum(n_ep1ge_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )

    # -> scope 1 captured
    # p.n_sigma
    @constraint(m, n_ep1gce_d_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ep1gce_d_[i, j, l, k] == 
                p.n_chi[l, k] * (1 - p.n_sigma[l, k]) 
                * n_ep0_d_[i, j, l, k]
               )
    @constraint(m, n_ep1gce_m_i_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ep1gce_d_[i, j, l, k] <= p.n_ep1gce_bM[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_ep1gce_s_e_[i=P, j=P2, l=L],
                n_ep1gce[i, j, l] == 
                sum(n_ep1gce_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )
    # -> scope 1 stored
    # p.sigma ?
    @constraint(m, n_ep1gcs_d_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ep1gcs_d_[i, j, l, k] ==
                p.n_chi[l, k] * p.n_sigma[l, k] * n_ep0_d_[i, j, l, k]
               )
    # ep1gcsm_bM
    @constraint(m, n_ep1gcs_m_i_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ep1gcs_d_[i, j, l, k] <= p.n_ep1gcs_bM[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_ep1gcs_s_e_[i=P, j=P2, l=L],
                n_ep1gcs[i, j, l] == 
                sum(n_ep1gcs_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )

    # -> upstream emission from input materials
    @constraint(m, n_ups_e_mt_in_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ups_e_mt_in_d_[i, j, l, k] == 
                sum(
                    sum(p.n_c_upsein_rate[l, c] * n_x_in_d_[i, j, l, k, n, c] for
                        c in Mt if node_mat[n, c] && c ∈ input_mat[n]
                       )
                    for n in Nd)
               )
    # p.n_ups_e_mt_in_ub
    @constraint(m, n_ups_m_i_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_ups_e_mt_in_d_[i, j, l, k] <= p.n_ups_e_mt_in_ub[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_ups_e_mt_in_s_e_[i=P, j=P2, l=L],
                n_ups_e_mt_in[i, j, l] == sum(n_ups_e_mt_in_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )

    # 76 
    # 76 #######################################################################
    # feedstock constraint
    #@constraint(m, n_fstck_d_e_[i=P, j=P2, l=L, k=Kn, f=Nf],
    #            n_fstck_d_[i, j, l, k, f] == 
    #            p.n_c_Fstck[l, k, f] * n_cp_d_[i, j, l, k]
    #            + p.n_rhs_Fstck[l, k, f] * y_n[i, j, l, k]
    #           )
    #@constraint(m, n_fstck_m_i_[i=P, j=P2, l=L, k=Kn, f=Nf],
    #            n_fstck_d_[i, j, l, k, f] <= 
    #            p.n_fstck_UB[l, k, f] * y_n[i, j, l, k]
    #           )
    #@constraint(m, n_fstck_s_e_[i=P, j=P2, l=L, f=Nf],
    #            n_fstck[i, j, l, f] == 
    #            sum(n_fstck_d_[i, j, l, k, f] for k in Kn)
    #           )
    # params include carbon intensity, chi and sigma.
    # chi : carbon capture
    # sigma : carbon storage
    
    # n_cpe and n_cpe_d_
    
    # ep_0 = (sum(hj*chj)+cp) * prod
    # ep_1ge = ep_0 * (1-chi)
    # ep_1gce = ep_0 * chi * (1-sigma)
    # ep_1gcs # stored ?
    # ep_1nge # not generated emmited
    # ep_2 = (sum(uj*cuj))

    # 76 
    # 76 #######################################################################
    ##
    # -> (fixed) operating and maintenance
    # p.m_fOnm by year
    @constraint(m, n_cfonm_d_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_cfonm_d_[i, j, l, k] == 
                (p.n_c_fOnm[l, k] * n_c0_d_[i, j, l, k]
                + p.n_rhs_fOnm[l, k] * y_n[i, j, l, k])
               )
    @constraint(m, n_cfonm_m_i_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_cfonm_d_[i, j, l, k] <= p.n_cfonm_bM[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_cfonm_s_e_[i=P, j=P2, l=L],
                n_cfonm[i, j, l] == 
                sum(n_cfonm_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )
    # -> (variable) operating and maintenance
    # p.m_vOnm by year
    @constraint(m, n_cvonm_d_e_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_cvonm_d_[i, j, l, k] == 
                (p.n_c_vOnm[l, k] * n_cp_d_[i, j, l, k, key_node]
                + p.n_rhs_vOnm[l, k] * y_n[i, j, l, k])
               )
    @constraint(m, n_cvonm_m_i_[i=P, j=P2, l=L, k=Kn; n_filter[l, k]],
                n_cvonm_d_[i, j, l, k] <= p.n_cvonm_bM[l] * y_n[i, j, l, k]
               )
    @constraint(m, n_cvonm_s_e_[i=P, j=P2, l=L],
                n_cvonm[i, j, l] == 
                sum(n_cvonm_d_[i, j, l, k] for k in Kn if n_filter[l, k])
               )
    # 76 
    # 76 #######################################################################
    ##

    # -> new alloc logic
    @constraint(m, n_logic_0_y_i_[i=P, j=P2, l=L; j<n_subperiods],
                y_n[i, j+1, l, fKn] <= y_n[i, j, l, fKn]  # only build in the future
               )
    @constraint(m, n_logic_1_y_i_[i=P, j=P2, l=L, k=Kn; 
                                  j<n_subperiods && k>fKn && n_filter[l, k]],
                y_n[i, j+1, l, k] >= y_n[i, j, l, k]  # only build in the future
               )
    @constraint(m, n_logic_s_e[i=P, j=P2, l=L], 
                sum(y_n[i, j, l, k] for k in Kn if n_filter[l, k]) == 1
               )
    # for all points besides the initial one
    #@constraint(m, n_logic_2[i=P, j=P2, l=L, k=Kn; k>fKn && i>fP && j>fP2],
    @constraint(m, n_logic_2[i=P, j=P2, l=L, k=Kn; 
                             k>fKn && (i, j)!=(fP,fP2) && n_filter[l, k]],
                y_n[i, j, l, k] + y_o[i, j, l] <= 1
               )
    
    # 76
    # 76 #######################################################################
    ##
    # cost of electricity (new plants)
    @constraint(m, n_u_cost_e_[i=P, j=P2, l=L],
                n_u_cost[i, j, l] == sum(p.c_u_cost[i, j, l] * n_u[i, j, l, n] for n in Nd if nd_en_fltr[n])
               )
    # cost of fuel (new plants)
    @constraint(m, n_ehf_cost_e_[i=P, j=P2, l=L],
                n_ehf_cost[i, j, l] == 
                sum(p.c_n_ehf_cost[i, j, l, f]*
                    (n_ehf[i, j, l, f, n] + n_u_ehf[i, j, l, f, n]) for f in Fu_n[l] for n in Nd if nd_en_fltr[n])
               )
    # 76 
    # 76 #######################################################################
    ##
    # -> output capacity
    @constraint(m, o_cp_d_e[i=P, j=P2, l=L, n=Nd],
                o_cp_d_[i, j, l, n] == o_tcp_d_[i, j, l, sT, n]
               )
    @constraint(m, o_cp_m1_i_[i=P, j=P2, l=L, n=Nd], # on
                o_cp_d_[i, j, l, n] <= p.o_cp_ub[l, n] * y_o[i, j, l]
               )
    #
    @constraint(m, o_cp_s_e_[i=P, j=P2, l=L, n=Nd],
                o_cp[i, j, l, n] == o_cp_d_[i, j, l, n]
               )
    #
    @constraint(m, o_tcp_d_m1_i_[i=P, j=P2, l=L, n=Nd], # on
                o_tcp_d_[i, j, l, sT, n] <= p.o_cp_ub[l, n] * y_o[i, j, l]
               )
    @constraint(m, o_tcp_d_m0_i_[i=P, j=P2, l=L, n=Nd], # off
                o_tcp_d_[i, j, l, sF, n] <= p.o_cp_ub[l, n] * (1 - y_o[i, j, l])
               )
    @constraint(m, o_tcp_d_s_e_[i=P, j=P2, l=L, n=Nd],
                r_cp[i, j, l, n] == o_tcp_d_[i, j, l, sT, n] + 
                o_tcp_d_[i, j, l, sF, n]
               ) # total cap

    # 76 
    # 76 #######################################################################
    ##
    # -> output capacity by retrofit 
    # 0
    ##@constraint(m, o_r_cp_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
    ##            r_cp_d_[i, j, l, k] == 
    ##            o_rcp_d_[i, j, l, k, sT] + o_rcp_d_[i, j, l, k, sF]
    ##           )
    ##@constraint(m, o_rcp_m1_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
    ##            o_rcp_d_[i, j, l, k, sT] <= p.o_cp_bM * y_o[i, j, l]
    ##           )
    ##@constraint(m, o_rcp_m0_i_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
    ##            o_rcp_d_[i, j, l, k, sF] <= p.o_cp_bM * (1.0-y_o[i, j, l])
    ##           )
    ##@constraint(m, o_rcp_d_e_[i=P, j=P2, l=L, k=Kr; r_filter[l, k]],
    ##            o_rcp[i, j, l, k] == o_rcp_d_[i, j, l, k, sT]
    ##           )

    # 76
    @constraint(m, n_mass_b_e_[i=P, j=P2, l=L, k=Kn, n=Nd, c=Mt; 
                               n_filter[l, k] && node_mat[n, c] && !skip_mb[n, c]],
                f_xin(m, i, j, l, k, n, c, input_mat; mode="n") 
                - f_xout(m, i, j, l, k, n, c, output_mat; mode="n")
                # + sum(p.n_Kmb[n, c, c1, k] * n_x_out_d_[i, j, l, k, n, c1] for c1 in Mt
                #      if node_mat[n, c1] && c1 ∈ output_mat[n]) == 0.0
                + (p.n_Kmb[n, c, ckey[n], k] * n_cp_d_[i, j, l, k, n]) == 0.0
               )
    #
    @constraint(m, n_comp_link_e_[i=P, j=P2, l=L, lnk=Ln],
                n_x_out[i, j, l, links_list[lnk][1], links_list[lnk][3]] 
                == 
                n_x_in[i, j, l, links_list[lnk][2], links_list[lnk][3]]
               )
    #
    @constraint(m, n_x_in_m_i_[i=P, j=P2, l=L, k=Kn, n=Nd, c=Mt; 
                               n_filter[l, k] && node_mat[n, c] &&
                               c ∈ input_mat[n]],
                n_x_in_d_[i, j, l, k, n, c] <= 
                p.n_x_in_ub[l, n, c] * y_n[i, j, l, k]
               )
    @constraint(m, n_x_in_s_e_[i=P, j=P2, l=L, n=Nd, c=Mt;
                               node_mat[n, c] && c ∈ input_mat[n]],
                n_x_in[i, j, l, n, c] == 
                sum(n_x_in_d_[i, j, l, k, n, c] for k in Kn if n_filter[l, k])
               )
    #
    @constraint(m, n_x_out_m_i_[i=P, j=P2, l=L, k=Kn, n=Nd, c=Mt; 
                                n_filter[l, k] && node_mat[n, c] &&
                                c ∈ output_mat[n]],
                n_x_out_d_[i, j, l, k, n, c] <= 
                p.n_x_out_ub[l, n, c] * y_n[i, j, l, k]
               )
    @constraint(m, n_x_out_s_e_[i=P, j=P2, l=L, n=Nd, c=Mt; 
                                node_mat[n, c] && c ∈ output_mat[n]],
                n_x_out[i, j, l, n, c] == 
                sum(n_x_out_d_[i, j, l, k, n, c] for k in Kn if n_filter[l, k])
               )
    # 76 
    # 76 #######################################################################
    ##
    # -> existing plant electricity consumption
    # 0
    @constraint(m, o_u_d_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]], 
                o_u_d_[i, j, l, n] == o_tu_d_[i, j, l, sT, n]
               )
    # 1
    @constraint(m, o_u_m_i_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                o_u_d_[i, j, l, n] <= p.o_u_ub[l, n] * y_o[i, j, l]
               )
    # 2
    @constraint(m, o_u_s_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                o_u[i, j, l, n] == o_u_d_[i, j, l, n]
               )
    # 3
    @constraint(m, o_tu_d_m1_i_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                o_tu_d_[i, j, l, sT, n] <= p.o_u_ub[l, n] * y_o[i, j, l]
               )
    # 4
    @constraint(m, o_tu_d_m0_i_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                o_tu_d_[i, j, l, sF, n] <= p.o_u_ub[l, n] * (1 - y_o[i, j, l])
               )
    # 5
    @constraint(m, o_tu_s_e_[i=P, j=P2, l=L, n=Nd; nd_en_fltr[n]],
                r_u[i, j, l, n] == o_tu_d_[i, j, l, sT, n] 
                + o_tu_d_[i, j, l, sF, n]
               )
    # 76 
    # 76 #######################################################################
    ##
    # -> existing plant fuel consumption
    # 0 
    @constraint(m, o_ehf_d_e_[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]],
                o_ehf_d_[i, j, l, f, n] == o_tehf_d_[i, j, l, f, sT, n]
               )
    # 1 
    @constraint(m, o_ehf_m_i[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]],
                o_ehf_d_[i, j, l, f, n] <= p.o_ehf_ub[f, l, n] * y_o[i, j, l]
               )
    # 2 
    @constraint(m, o_ehf_s_[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]],
                o_ehf[i, j, l, f, n] == o_ehf_d_[i, j, l, f, n]
               )
    # 3 
    @constraint(m, o_tehf_d_m1_i_[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]],
                o_tehf_d_[i, j, l, f, sT, n] <= p.o_ehf_ub[f, l, n] * y_o[i, j, l]
               )
    # 4 
    @constraint(m, o_tehf_d_m0_i_[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]],
                o_tehf_d_[i, j, l, f, sF, n] <= p.o_ehf_ub[f, l, n] * (1 - y_o[i, j, l])
               )
    # 5  this includes fuel + fuel-for-electricity
    # we can still recover r_u_ehf with postprocessing
    @constraint(m, o_tehf_s_e_[i=P, j=P2, l=L, f=Fu_r[l], n=Nd; nd_en_fltr[n]],
                r_ehf[i, j, l, f, n] + r_u_ehf[i, j, l, f, n] == 
                o_tehf_d_[i, j, l, f, sT, n] + o_tehf_d_[i, j, l, f, sF, n]
               )

    #
    # -> output emissions (why?)
    # -> scope 0
    @constraint(m, o_ep0_d_e_[i=P, j=P2, l=L],
                o_ep0_d_[i, j, l] == o_tep0_d_[i, j, l, sT]
               )
    @constraint(m, o_ep0_m_i_[i=P, j=P2, l=L], # on
                o_ep0_d_[i, j, l] <= p.o_ep0_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_ep0_s_[i=P, j=P2, l=L],
                o_ep0[i, j, l] == o_ep0_d_[i, j, l]
               )
    @constraint(m, o_tep0_d_m1_i_[i=P, j=P2, l=L], # on
                o_tep0_d_[i, j, l, sT] <= p.o_ep0_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_tep0_d_m0_i_[i=P, j=P2, l=L], # off
                o_tep0_d_[i, j, l, sF] <= p.o_ep0_bM[l] * (1 - y_o[i, j, l])
               )
    @constraint(m, o_tep0_s_e_[i=P, j=P2, l=L],
                r_ep0[i, j, l] == 
                o_tep0_d_[i, j, l, sT] + o_tep0_d_[i, j, l, sF]
               )
    # ->  
    @constraint(m, o_ep1ge_d_e_[i=P, j=P2, l=L],
                o_ep1ge_d_[i, j, l] == o_tep1ge_d_[i, j, l, sT]
               )
    @constraint(m, o_ep1ge_m_i_[i=P, j=P2, l=L], # on
                o_ep1ge_d_[i, j, l] <= p.o_ep1ge_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_ep1ge_s_[i=P, j=P2, l=L],
                o_ep1ge[i, j, l] == o_ep1ge_d_[i, j, l]
               )
    @constraint(m, o_tep1ge_d_m1_i_[i=P, j=P2, l=L], # on
                o_tep1ge_d_[i, j, l, sT] <= p.o_ep1ge_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_tep1ge_d_m0_i_[i=P, j=P2, l=L], # off
                o_tep1ge_d_[i, j, l, sF] <= p.o_ep1ge_bM[l] * (1 - y_o[i, j, l])
               )
    @constraint(m, o_tep1ge_s_e_[i=P, j=P2, l=L],
                r_ep1ge[i, j, l] == 
                o_tep1ge_d_[i, j, l, sT] + o_tep1ge_d_[i, j, l, sF]
               )

    # ->
    @constraint(m, o_ep1gce_d_e_[i=P, j=P2, l=L], # 1
                o_ep1gce_d_[i, j, l] == o_tep1gce_d_[i, j, l, sT]
               )
    @constraint(m, o_ep1gce_m_i_[i=P, j=P2, l=L], # 2
                o_ep1gce_d_[i, j, l] <= p.o_ep1gce_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_ep1gce_s_[i=P, j=P2, l=L], # 3
                o_ep1gce[i, j, l] == o_ep1gce_d_[i, j, l]
               )
    @constraint(m, o_tep1gce_d_m1_i_[i=P, j=P2, l=L], # 4
                o_tep1gce_d_[i, j, l, sT] <= p.o_ep1gce_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_tep1gce_d_m0_i_[i=P, j=P2, l=L],  # 5
                o_tep1gce_d_[i, j, l, sT] <= p.o_ep1gce_bM[l] * (1 - y_o[i, j, l])
               )
    @constraint(m, o_tep1gce_s_e_[i=P, j=P2, l=L],  # 6
                r_ep1gce[i, j, l] == o_tep1gce_d_[i, j, l, sT]
                + o_tep1gce_d_[i, j, l, sF]
               )


    # ->
    @constraint(m, o_ep1gcs_d_e_[i=P, j=P2, l=L], # 1
                o_ep1gcs_d_[i, j, l] == o_tep1gcs_d_[i, j, l, sT]
               )
    @constraint(m, o_ep1gcs_m_i_[i=P, j=P2, l=L], # on 2
                o_ep1gcs_d_[i, j, l] <= p.o_ep1gcs_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_ep1gcs_s_[i=P, j=P2, l=L], # 3
                o_ep1gcs[i, j, l] == o_ep1gcs_d_[i, j, l]
               )
    @constraint(m, o_tep1gcs_d_m1_i_[i=P, j=P2, l=L], # on # 4
                o_tep1gcs_d_[i, j, l, sT] <= p.o_ep1gcs_bM[l] * y_o[i, j, l]
               )
    @constraint(m, o_tepgcs_d_m0_i_[i=P, j=P2, l=L], # off # 5
                o_tep1gcs_d_[i, j, l, sF] <= p.o_ep1gcs_bM[l] * (1 - y_o[i, j, l])
               )
    @constraint(m, o_tep1gcs_s_e_[i=P, j=P2, l=L], # 6
                r_ep1gcs[i, j, l] == o_tep1gcs_d_[i, j, l, sT] 
                + o_tep1gcs_d_[i, j, l, sF]
               )
    ##
    ## 0
    #@constraint(m, o_fstck_d_e_[i=P, j=P2, l=L, f=Nf],
    #            o_fstck_d_[i, j, l, f] == o_tfstck_d_[i, j, l, f, sT]
    #           )
    ## 1
    #@constraint(m, o_fstck_m_i_[i=P, j=P2, l=L, f=Nf],
    #            o_fstck_d_[i, j, l, f] <= 
    #            p.o_fstck_UB[l, f] * y_o[i, j, l]
    #           )
    ## 2
    #@constraint(m, o_fstck_s_e_[i=P, j=P2, l=L, f=Nf],
    #            o_fstck[i, j, l, f] == o_fstck_d_[i, j, l, f]
    #           )
    ## 3
    #@constraint(m, o_tfstck_m0_i_[i=P, j=P2, l=L, f=Nf],
    #            o_tfstck_d_[i, j, l, f, sT] <= 
    #            p.o_fstck_UB[l, f] * y_o[i, j, l]
    #           )
    ## 4
    #@constraint(m, o_tfstck_m1_i_[i=P, j=P2, l=L, f=Nf],
    #            o_tfstck_d_[i, j, l, f, sF] <= 
    #            p.o_fstck_UB[l, f] * (1 - y_o[i, j, l])
    #           )
    ## 5
    #@constraint(m, o_tfstck_s_e[i=P, j=P2, l=L, f=Nf],
    #            r_fstck[i, j, l, f] + n_fstck[i, j, l, f] ==
    #            o_tfstck_d_[i, j, l, f, sF] + o_tfstck_d_[i, j, l, f, sT]

    #           )

    # ->>
    @constraint(m, o_last_loan_s_e_[i=P, l=L], 
                r_loan_p[i, n_subperiods, l] + e_loan_p[i, n_subperiods, l] == 
                o_loan_last[i, l, sT] + o_loan_last[i, l, sF]
               )
    @constraint(m, o_last_loan_d_m1_i_[i=P, l=L],
                o_loan_last[i, l, sT] <= oloanlastub[l] * y_o[i, n_subperiods, l]
               )
    @constraint(m, o_last_loan_d_m0_i_[i=P, l=L],
                o_loan_last[i, l, sF] <= oloanlastub[l] * (1 - y_o[i, n_subperiods, l])
               )
    
    # cost of electrictity (existing)
    @constraint(m, o_u_cost_e_[i=P, j=P2, l=L],
                o_u_cost[i, j, l] == sum(
                                         p.c_u_cost[i, j, l] * o_u[i, j, l, n]
                                         for n in Nd if nd_en_fltr[n]
                                        )
               )
    # cost of fuel (existing)
    @constraint(m, o_ehf_cost_e_[i=P, j=P2, l=L],
                o_ehf_cost[i, j, l] == 
                sum(
                    sum(p.c_r_ehf_cost[i, j, l, f] * o_ehf[i, j, l, f, n] for f in Fu_r[l])
                    for n in Nd if nd_en_fltr[n]
                   )
               )
    # cost of storing carbon
    @constraint(m, o_ep1gcs_cost_e_[i=P, j=P2, l=L],
                o_ep1gcs_cost[i, j, l] == p.c_cts_cost[l] * o_ep1gcs[i, j, l]
               )
    # cost of storing carbon
    @constraint(m, n_ep1gcs_cost_e_[i=P, j=P2, l=L],
                n_ep1gcs_cost[i, j, l] == p.c_cts_cost[l] * n_ep1gcs[i, j, l]
               )

    # cost of input materials
    @constraint(m, o_x_in_cost_e_[i=P, j=P2, l=L],
                o_x_in_cost[i, j, l] == 
                sum(p.c_xin_cost[l, c] * o_x_in[i, j, l, n, c] for n in Nd
                    for c in Mt if node_mat[n, c] && c ∈ input_mat[n]
                   )
               )
    @constraint(m, n_x_in_cost_e_[i=P, j=P2, l=L],
                n_x_in_cost[i, j, l] == 
                sum(p.c_xin_cost[l, c] * n_x_in[i, j, l, n, c] for n in Nd
                    for c in Mt if node_mat[n, c] && c ∈ input_mat[n]
                   )
               )
    
    # initial conditions
    if index_p isa Int
        if index_p == fP
            println(index_p, "index_p")
            attachInitCond(index_l, m, p, s)
        end
    else
        attachInitCond(index_l, m, p, s)
    end
    

    m[:pblock_attached] = false
    m[:lblock_attached] = false
    # 76 
    # 76 #######################################################################
    ##
    # objective
    # pricing-problem
    return m
end

function attachInitCond(index_l::T, m::JuMP.Model, p::params, s::sets) where T<:Union{UnitRange{Int64}, Int64}

    if index_l isa Int
        L = [index_l]
    else
        L = index_l
    end

    P2 = s.P2

    Kr = s.Kr
    Kn = s.Kn
    Fu_r = s.Fu_r
    Fu_n = s.Fu_n

    n_periods = p.n_periods
    n_subperiods = p.n_subperiods
    
    r_filter = p.r_filter
    n_filter = p.n_filter

    y_r = m[:y_r]
    y_e = m[:y_e]
    y_o = m[:y_o]
    y_n = m[:y_n]
    r_loan = m[:r_loan]
    e_loan = m[:e_loan]
    n_loan = m[:n_loan]
    #
    fP = first(s.P)
    fP2 = first(P2)
    fKr = first(Kr)
    fKn = first(Kn)

    println(index_l)
    println(fP)
    println(fP2)
    #@constraint(m, e_logic_init[l=L], 
    #            y_e[fP, fP2, l] == 0  # start not-expanded
    #           )
    @constraint(m, r_logic_init_0[l=L], # all non 0 rtrf
                y_r[fP, fP2, l, fKr] == 1
               )

    @constraint(m, r_logic_init_1[l=L, k=Kr; k > fKr && r_filter[l, k]], 
                # all non 0 rtrf
                y_r[fP, fP2, l, k] == 0
               )
    @constraint(m, o_logic_init_0_[l=L],
                y_o[fP, fP2, l] == 1)  # plants must start online 

    @constraint(m, n_logic_0_init[l=L], 
                y_n[fP, fP2, l, fKn] == 1  # start with no new
               )
    @constraint(m, n_logic_1_init[l=L, k=Kn; k>fKn && n_filter[l, k]], 
                y_n[fP, fP2, l, k] == 0  # start with no new facility
               )

    # -> initial loans
    @constraint(m, r_loan_initial_cond[l=L],
                r_loan[fP, fP2, l] == p.r_loan0[l]
               )
    @constraint(m, e_loan_init_cond[l=L],
                e_loan[fP, fP2, l] == 0.0
               )
    @constraint(m, n_loan_init_cond[l=L],
                n_loan[fP, fP2, l] == 0.0
               )

    e_ladd_d_ = m[:e_ladd_d_]
    @constraint(m, e_ladd_m_0_y_0_[l=L], 
                e_ladd_d_[fP, fP2, l] <= p.e_ladd_ub[l] * y_e[fP, fP2, l]
               )
    e_yps = m[:e_yps]
    @constraint(m, e_logic_yps_ye_0[l=L],
                y_e[fP, fP2, l] + e_yps[fP, fP2, l] <= 1
               )
end

function attachFullObjectiveBlock(m::JuMP.Model, p::params, s::sets)

    P2 = s.P2
    P = s.P
    L = s.L
    n_periods = p.n_periods
    n_subperiods = p.n_subperiods
    # True/False
    
    sT = 1 # p.sTru
    sF = sT + 1 # p.sFal  # offline

    o_pay = m[:o_pay]
    o_cfonm = m[:o_cfonm]
    o_cvonm = m[:o_cvonm]
    n_pay = m[:n_pay]
    n_cfonm = m[:n_cfonm]
    n_cvonm = m[:n_cvonm]
    o_loan_last = m[:o_loan_last]

    n_ladd = m[:n_ladd]
    r_loan_p = m[:r_loan_p]
    e_loan_p = m[:e_loan_p]
    t_ret_cost = m[:t_ret_cost]  # 15
    n_loan_p = m[:n_loan_p]

    o_u_cost = m[:o_u_cost]
    n_u_cost = m[:n_u_cost]
    
    o_ehf_cost = m[:o_ehf_cost]
    n_ehf_cost = m[:n_ehf_cost]
    o_ep1gcs_cost = m[:o_ep1gcs_cost]
    n_ep1gcs_cost = m[:n_ep1gcs_cost]

    o_x_in_cost = m[:o_x_in_cost]
    n_x_in_cost = m[:n_x_in_cost]
    @objective(m, Min,
               # 1 loan
               (sum(sum(sum(p.discount[i, j] * o_pay[i, j, l] 
                            for l in L) for j in P2) for i in P)
                # 2 o&m
                + sum(sum(sum(p.discount[i, j] * o_cfonm[i, j, l] 
                              for l in L) for j in P2) for i in P)
                + sum(sum(sum(p.discount[i, j] * o_cvonm[i, j, l] 
                              for l in L) for j in P2) for i in P)
                # 3 loan new
                + sum(sum(sum(p.discount[i, j] * n_pay[i, j, l] 
                              for l in L) for j in P2) for i in P)
                # 4 o&m new
                + sum(sum(sum(p.discount[i, j] * n_cfonm[i, j, l] 
                              for l in L) for j in P2) for i in P)
                + sum(sum(sum(p.discount[i, j] * n_cvonm[i, j, l] 
                              for l in L) for j in P2) for i in P)
                # 5 retirement
                + sum(sum(sum(p.discount[i, j]*t_ret_cost[i, j, l] 
                              for l in L) for j in P2) for i in P)
                # 6 last loan
                + sum(p.discount[n_periods,n_subperiods]*
                      o_loan_last[n_periods, l, sT]  + 
                      # you could avoid having oloanlast if yo is 0 at the end
                      # and cheat
                      r_loan_p[n_periods, n_subperiods, l] + 
                      e_loan_p[n_periods, n_subperiods, l]
                      for l in L)
                # 7 last loan new
                + sum(p.discount[n_periods,n_subperiods]*
                      (n_loan_p[n_periods,n_subperiods,l]  + 
                       # you could cheat by having new p at the end and aoviding
                       # n_loan_p
                       n_ladd[n_periods, n_subperiods, l])
                      for l in L)
                # 8 elec
                + sum(p.discount[i, j] * o_u_cost[i, j, l] 
                      for l in L for j in P2 for i in P)
                # 9 elec new
                + sum(p.discount[i, j] * n_u_cost[i, j, l]
                      for l in L for j in P2 for i in P)
                # 10 fuel
                + sum(p.discount[i, j] * o_ehf_cost[i, j, l]
                      for l in L for j in P2 for i in P)
                # 11 fuel new
                + sum(p.discount[i, j] * n_ehf_cost[i, j, l]
                      for l in L for j in P2 for i in P)
                #
                + sum(p.discount[i, j] * o_ep1gcs_cost[i, j, l] 
                      for l in L for j in P2 for i in P)
                + sum(p.discount[i, j] * n_ep1gcs_cost[i, j, l] 
                      for l in L for j in P2 for i in P)
                + sum(p.discount[i, j] * o_x_in_cost[i, j, l]
                      for l in L for j in P2 for i in P)
                + sum(p.discount[i, j] * n_x_in_cost[i, j, l]
                      for l in L for j in P2 for i in P)
               )
               # if you retire but still have unpayed loan it is gonna be
               # reflected here :()
              )
    @printf "Full objective was be attached\n" 
end

function attachPeriodBlock(m::Model, p::params, s::sets)
    P = s.P
    P2 = s.P2
    L = s.L

    Kr = s.Kr
    Kn = s.Kn

    n_periods = p.n_periods
    n_subperiods = p.n_subperiods

    r_filter = p.r_filter
    n_filter = p.n_filter

    fP = first(s.P)
    fP2 = first(P2)
    fKr = first(Kr)
    fKn = first(Kn)
    
    # True/False
    sT = 1 # p.sTru
    sF= sT + 1 # p.sFal  # offline
    
    # order online, retrofit, expansion, new.
    #
    y_o = m[:y_o]  # 1
    y_r = m[:y_r]  # 2
    y_e = m[:y_e]  # 3
    y_n = m[:y_n]  # 4
    r_l0add_d_ = m[:r_l0add_d_]  # 5
    r_l0_pd_ = m[:r_l0_pd_]  # 6
    r_leadd_d_ = m[:r_leadd_d_]  # 
    r_leadde_d_ = m[:r_leadde_d_]  # 

    r_le_pd_ = m[:r_le_pd_]  # 
    r_le_ped_ = m[:r_le_ped_]  # 
    # r_l0 = m[:r_l0]  # 7
    r_loan = m[:r_loan]  # 8
    r_pay0 = m[:r_pay0]  # 9
    r_l0add = m[:r_l0add]  # 10
    #
    r_paye = m[:r_paye]  # 9
    r_leadd = m[:r_leadd]  # 10
    r_leadde = m[:r_leadde]  # 10
    #
    e_ladd_d_ = m[:e_ladd_d_]  # 11
    e_l_pd_ = m[:e_l_pd_]  # 12
    e_l = m[:e_l]  # 13
    e_loan = m[:e_loan]  # 14
    e_pay = m[:e_pay]  # 15
    e_ladd = m[:e_ladd]  # 16
    # (retirement)
    t_ret_cost_d_ = m[:t_ret_cost_d_]  # 17
    t_loan_d_ = m[:t_loan_d_]  # 18
    n_ladd_d_ = m[:n_ladd_d_]  # 19
    n_l_pd_ = m[:n_l_pd_]  # 20
    n_l = m[:n_l]  # 21
    n_loan = m[:n_loan]  # 22
    #
    n_pay = m[:n_pay]  # 23
    n_ladd = m[:n_ladd]  # 24
    x = m[:x]
    n_c0 = m[:n_c0]
    e_yps = m[:e_yps]
    n_yps = m[:n_yps]
    r_yps = m[:r_yps]
    #

    # 1: o_logic_1
    @constraint(m, o_logic_1_p_link_i_[i=P, l=L; i<n_periods],
                #y_o[i+1, 0, l] <= y_o[i, n_subperiods, l]
                y_o[i, n_subperiods, l] - y_o[i+1, fP2, l]  >= 0.0
               )
    # 2: 
    @constraint(m, 
                r_logic_budget_p_link_i_[i=P, l=L, k=Kr; 
                                            k>fKr && i<n_periods && r_filter[l, k]],
                #y_r[i+1, 0, l, k] >= y_r[i, n_subperiods, l, k]
                -y_r[i, n_subperiods, l, k] + y_r[i+1, fP2, l, k] >= 0.0
               )
    # 3: 
    @constraint(m, r_logic_onoff_1_p_link_i_[i=P, l=L, k=Kr;
                                             i<n_periods && r_filter[l, k]],
                y_o[i, n_subperiods, l] - y_r[i, n_subperiods, l, k] 
                + y_r[i+1, fP2, l, k] >= 0.
               )
    # 4: 
    @constraint(m, r_logic_onoff_2_p_link_i_[i=P, l=L, k=Kr;
                                             i<n_periods && r_filter[l, k]],
                #y_o[i, n_subperiods, l] + 1 - y_r[i+1, 0, l, k] 
                #+ y_r[i, n_subperiods, l, k] >= 1
                y_o[i, n_subperiods, l] + y_r[i, n_subperiods, l, k]
                - y_r[i+1, fP2, l, k] >= 0
               )
    # 5: 
    rl0ub1d = maximum(p.r_l0_ub, dims=2)
    # p_add_bM
    @constraint(m, r_l0add_m_0_p_link_i_[i=P, l=L; i>fP],
                rl0ub1d[l] * (y_r[i-1,n_subperiods,l,fKr] - y_r[i,fP2,l,fKr])
                - r_l0add_d_[i, fP2, l] 
                >= 0.
               )

    # 6: 
    @constraint(m, r_l_m_1_y_p_link_i_[i=P, l=L; i>fP],
                rl0ub1d[l] * (-y_r[i-1, n_subperiods, l, fKr] + y_r[i,fP2,l,fKr])
                - r_l0_pd_[i, fP2, l, sF] >= -rl0ub1d[l]
               )
    # !!!!!!!!!!!!
    rleub1d = maximum(p.r_le_ub, dims=2)
    @constraint(m, r_leadd_m_1_p_link_i_[i=P, l=L; i>fP],
                rleub1d[l] * (y_r[i-1,n_subperiods,l,fKr] - y_r[i,fP2,l,fKr])
                - r_leadd_d_[i, fP2, l] 
                >= 0.)

    @constraint(m, r_le_m_1_p_link_i_[i=P, l=L; i>fP],
                rleub1d[l]*(-y_r[i-1, n_subperiods, l, fKr] + y_r[i,fP2,l,fKr])
                - r_le_pd_[i, fP2, l, sF]
                >= -rleub1d[l]
               )
    @constraint(m, r_le_m_2_p_link_i_[i=P, l=L; i>fP], 
                rleub1d[l] * (y_e[i-1, n_subperiods, l] - y_e[i, fP2, l])
                - r_le_ped_[i, fP2, l, sF] >= -rleub1d[l]
               )
    @constraint(m, r_leadd_m_2_p_link_i_[i=P, l=L; i>fP], 
                rleub1d[l] * (-y_e[i-1, n_subperiods, l] + y_e[i, fP2, l])
                - r_leadde_d_[i, fP2, l] >= 0.
               )
    # 7:
    # 8: 
    @constraint(m, k_loan_bal_p_link_e_[i=P, l=L; i<n_periods],
                r_loan[i, n_subperiods, l] * (1+p.interest)^p.yr_subperiod
                - r_pay0[i, n_subperiods, l] * sum((1+p.interest)^k for k in 0:(p.yr_subperiod-1))
                - r_paye[i, n_subperiods, l] * sum((1+p.interest)^k for k in 0:(p.yr_subperiod-1))
                + r_l0add[i, n_subperiods, l] * (1+p.interest)^(p.yr_subperiod-1)
                + r_leadd[i, n_subperiods, l] * (1+p.interest)^(p.yr_subperiod-1)
                + r_leadde[i, n_subperiods, l] * (1+p.interest)^(p.yr_subperiod-1)
                - r_loan[i+1, fP2, l] == 0.
               )

    # 9: 
    @constraint(m, e_logic_1_p_link_i_[i=P, l=L; i<n_periods],
                #y_e[i+1, 0, l] >= y_e[i, n_subperiods, l]  #
                -y_e[i, n_subperiods, l] + y_e[i+1, fP2, l] >= 0 #
               )
    # 10: 
    @constraint(m, e_ladd_m_0_p_link_i_[i=P, l=L; i>fP], 
                #e_ladd_d_[i, n_subperiods, l, 0] <= 
                #p.e_ladd_ub[l] * (y_e[i+1, 0, l] - y_e[i, n_subperiods, l])
                #
                #p.e_ladd_ub[l] * (-y_e[i, n_subperiods, l] + y_e[i+1, fP2, l])
                #- e_ladd_d_[i, n_subperiods, l] >= 0.
                #
                p.e_ladd_ub[l] * (-y_e[i-1, n_subperiods, l] + y_e[i, fP2, l])
                - e_ladd_d_[i, fP2, l] >= 0.
               )
    # 11: 
    @constraint(m, e_l_m_1_p_link_i_[i=P, l=L; i>fP], 
                # need to set this to 0
                #e_l_pd_[i, n_subperiods, l, 1] <= 
                #p.e_l_ub[l] * (1 - y_e[i+1, 0, l] + y_e[i, n_subperiods, l])
                #
                #p.e_l_ub[l] * (y_e[i, n_subperiods, l] - y_e[i+1, fP2, l])
                #- e_l_pd_[i, n_subperiods, l, sF] >= -p.e_l_ub[l]
                #
                #
                p.e_l_ub[l] * (y_e[i-1, n_subperiods, l] - y_e[i, fP2, l])
                - e_l_pd_[i, fP2, l, sF] >= -p.e_l_ub[l]
               )  #  the 0th component is implied by the e_ladd_m constr
    # !!!!!!!!!
    # 12:
    # 13: 
    @constraint(m, e_loan_bal_p_link_e_[i=P, l=L; i<n_periods],
                #e_loan[i+1, 0, l] == e_loan[i, n_subperiods, l]
                #- e_pay[i, n_subperiods, l]
                #+ e_ladd[i, n_subperiods, l]
                e_loan[i, n_subperiods, l]*(1+p.interest)^p.yr_subperiod
                - e_pay[i, n_subperiods, l]*sum((1+p.interest)^k for k in 0:(p.yr_subperiod-1))
                + e_ladd[i, n_subperiods, l] * (1+p.interest)^(p.yr_subperiod-1)
                - e_loan[i+1, fP2, l]
                == 0.
               )
    ####
    # 14:
    # t_ret_c_bM[l]
    @constraint(m, t_ret_c_bm_0_p_link_i_[i=P, l=L; i<n_periods],
                #t_ret_cost_d_[i, n_subperiods, l, 0] <= 
                #p.t_ret_c_bM[l] * (y_o[i, n_subperiods, l] - y_o[i+1,0, l])
                p.t_ret_c_bM[l] * (y_o[i, n_subperiods, l] - y_o[i+1, fP2, l])
                - t_ret_cost_d_[i, n_subperiods, l] >= 0.
               )
    # 15: 
    # m_loan_d_bM
    @constraint(m, r_loan_d_bm_0_p_link_i_[i=P, l=L; i<n_periods],
                #t_loan_d_[i, n_subperiods, l, 0] <=  # retired
                #p.t_loan_bM[l] * (y_o[i, n_subperiods, l] - y_o[i+1,0, l])
                p.t_loan_bM[l] * (y_o[i, n_subperiods, l] - y_o[i+1, fP2, l])
                - t_loan_d_[i, n_subperiods, l, sT] >= 0.
               )
    # 16: 
    @constraint(m, r_loan_d_bm_1_p_link_i_[i=P, l=L; i<n_periods], # 
                #t_loan_d_[i, n_subperiods, l, 1] <= p.t_loan_bM[l] * 
                #(1 + y_o[i+1, 0, l] - y_o[i, n_subperiods, l])
                p.t_loan_bM[l] * (-y_o[i, n_subperiods, l] + y_o[i+1, fP2, l])
                - t_loan_d_[i, n_subperiods, l, sF] >= -p.t_loan_bM[l]
               )
    ###
    # 17: 
    @constraint(m, n_ladd_m_0_p_link_i_[i=P, l=L; i>fP], 
                p.n_ladd_bM[l]*(y_n[i-1, n_subperiods, l, fKn] 
                             - y_n[i, fP2, l, fKn])
                -n_ladd_d_[i, fP2, l] >= 0.
               ) # y_n goes from 1 to 0
    # 18: 
    @constraint(m, n_ladd_m_1_p_link_i_[i=P, l=L; i>fP],
                p.n_l_bM[l] * (-y_n[i-1, n_subperiods, l, fKn] 
                            + y_n[i, fP2, l, fKn])
                - n_l_pd_[i, fP2, l, sF] >= -p.n_l_bM[l]
               )
    # 20: 
    @constraint(m, n_loan_bal_p_link_e_[i=P, l=L; i<n_periods],
                n_loan[i, n_subperiods, l] * (1+p.interest)^p.yr_subperiod
                - n_pay[i, n_subperiods, l] * sum((1+p.interest)^k for k in 0:(p.yr_subperiod-1))
                + n_ladd[i, n_subperiods, l] * (1+p.interest)^(p.yr_subperiod-1) 
                - n_loan[i+1, fP2, l] == 0.0
               )
    # 21: 
    @constraint(m, n_logic_0_p_link_i_[i=P, l=L; i<n_periods],
                #y_n[i+1, 0, l, 0] <= y_n[i, n_subperiods, l, 0]
                y_n[i, n_subperiods, l, fKn] - y_n[i+1, fP2, l, fKn] >= 0.
               )
    # 22: 
    @constraint(m, n_logic_1_p_link_i_[i=P, l=L, k=Kn; 
                                       i<n_periods && k>fKn && n_filter[l, k]],
                #y_n[i+1, 0, l, k] >= y_n[i, n_subperiods, l, k]
                -y_n[i, n_subperiods, l, k] + y_n[i+1, fP2, l, k]  >= 0.
               )

    # 23:
    @constraint(m, x_p_link_e_[i=P, l=L; i<n_periods],
                x[i, l] - x[i+1, l] == 0)

    # 24:
    @constraint(m, n_c0_p_link_e_[i=P, l=L; i<n_periods],
                n_c0[i, l] - n_c0[i+1, l] == 0
               )

    @constraint(m, e_logic_yps_ye_link[i=P, l=L; i>fP],
                (y_e[i, fP2, l] - y_e[i-1, n_subperiods, l]) 
                + e_yps[i, fP2, l]
                <= 1
               )
    @constraint(m, n_logic_yps_yn_link[i=P, l=L; i>fP],
                (y_n[i-1, n_subperiods, l, fKn] - y_n[i, fP2, l, fKn]) 
                + n_yps[i, fP2, l] 
                <= 1
               )
    @constraint(m, r_logic_yps_yr_link[i=P, l=L; i>fP],
                (y_r[i-1, n_subperiods, l, fKr] - y_r[i, fP2, l, fKr]) 
                + r_yps[i, fP2, l] 
                <= 1
               )


    m[:pblock_attached] = true
end

function detachPeriodBlock(m::Model)
    delete.(m, m[:o_logic_1_p_link_i_]) # 1
    unregister(m, :o_logic_1_p_link_i_)
    delete.(m, m[:r_logic_budget_p_link_i_]) # 2
    unregister(m, :r_logic_budget_p_link_i_)
    delete.(m, m[:r_logic_onoff_1_p_link_i_]) # 3
    unregister(m, :r_logic_onoff_1_p_link_i_)
    delete.(m, m[:r_logic_onoff_2_p_link_i_]) # 4
    unregister(m, :r_logic_onoff_2_p_link_i_)
    delete.(m, m[:r_l0add_m_0_p_link_i_]) # 5
    unregister(m, :r_l0add_m_0_p_link_i_)
    delete.(m, m[:r_l_m_1_y_p_link_i_]) # 6
    unregister(m, :r_l_m_1_y_p_link_i_)

    delete.(m, m[:r_leadd_m_1_p_link_i_])
    unregister.(m, m[:r_leadd_m_1_p_link_i_])
    delete.(m, m[:r_le_m_1_p_link_i_])
    unregister.(m, m[:r_le_m_1_p_link_i_])
    delete.(m, m[:r_le_m_2_p_link_i_])
    unregister.(m, m[:r_le_m_2_p_link_i_])
    delete.(m, m[:r_leadd_m_2_p_link_i_]) 
    unregister.(m, m[:r_leadd_m_2_p_link_i_]) 
    #
    delete.(m, m[:r_loan_bal_p_link_e_]) # 8
    unregister(m, :r_loan_bal_p_link_e_)
    delete.(m, m[:e_logic_1_p_link_i_]) # 9
    unregister(m, :e_logic_1_p_link_i_)
    delete.(m, m[:e_ladd_m_0_p_link_i_]) # 10
    unregister(m, :e_ladd_m_0_p_link_i_)
    delete.(m, m[:e_l_m_1_p_link_i_]) # 11
    unregister(m, :e_l_m_1_p_link_i_)
    delete.(m, m[:e_l_s_p_link_e_]) # 12
    unregister(m, :e_l_s_p_link_e_)
    delete.(m, m[:e_loan_bal_p_link_e_]) # 13
    unregister(m, :e_loan_bal_p_link_e_)
    delete.(m, m[:t_ret_c_bm_0_p_link_i_]) # 14
    unregister(m, :t_ret_c_bm_0_p_link_i_)
    delete.(m, m[:r_loan_d_bm_0_p_link_i_]) # 15
    unregister(m, :r_loan_d_bm_0_p_link_i_)
    delete.(m, m[:r_loan_d_bm_1_p_link_i_]) # 16
    unregister(m, :r_loan_d_bm_1_p_link_i_)
    delete.(m, m[:n_ladd_m_0_p_link_i_]) # 17
    unregister(m, :n_ladd_m_0_p_link_i_)
    delete.(m, m[:n_ladd_m_1_p_link_i_]) # 18
    unregister(m, :n_ladd_m_1_p_link_i_)
    delete.(m, m[:n_l_s_e_link_i_]) # 19
    unregister(m, :n_l_s_e_link_i_)
    delete.(m, m[:n_loan_bal_p_link_e_]) # 20
    unregister(m, :n_loan_bal_p_link_e_)
    delete.(m, m[:n_logic_0_p_link_i_]) # 21
    unregister(m, :n_logic_0_p_link_i_)
    delete.(m, m[:n_logic_1_p_link_i_]) # 22
    unregister(m, :n_logic_1_p_link_i_)
    delete.(m, m[:x_p_link_e_]) # 23
    unregister(m, :x_p_link_e_)
    delete.(m, m[:n_c0_p_link_e_]) # 24
    unregister(m, :n_c0_p_link_e_)
    m[:pblock_attached] = false
end


"""Attach the time continuity block"""
function attachLocationBlock(m::Model, p::params, s::sets)
    L = s.L

    P = s.P
    P2 = s.P2

    # True/False
    sT = 1 # p.sTru
    sF= sT + 1 # p.sFal  # offline

    o_cp = m[:o_cp]  # 25
    n_cp = m[:n_cp]  # 26
    o_ep1ge = m[:o_ep1ge];  # 27
    n_ep1ge = m[:n_ep1ge]; # 28

    o_u = m[:o_u]  # 29
    n_u = m[:n_u]  # 30

    r_ehf = m[:r_ehf]
    n_ehf = m[:n_ehf]

    r_cp = m[:r_cp]
    n_cp = m[:n_cp]
    o_rcp = m[:o_rcp]
    n_cp_d_ = m[:n_cp_d_]
    
    o_ups_e_mt_in = m[:o_ups_e_mt_in]
    n_ups_e_mt_in = m[:n_ups_e_mt_in]
    # 25
    # aggregate demand constraint
    @constraint(m, ag_dem_l_link_i_[i=P, j=P2],
                sum(o_cp[i, j, l, p.key_node] for l in L) + 
                sum(n_cp[i, j, l, p.key_node] for l in L) >= p.demand[i, j]
               )

    # 26 debug
    #@constraint(m, ag_co2_l_link_i_[i=P, j=P2],
    #            # existing
    #            -sum(o_ep1ge[i, j, l] for l in L) 
    #            # new
    #            - sum(n_ep1ge[i, j, l] for l in L)
    #            # grid associated emissions
    #            #- sum(p.GcI[i,j,l]*0.29329722222222*
    #            #      (o_u[i, j, l] + n_u[i, j, l]) for l in L)
    #            >= -p.co2_budget[i, j]
    #           )
    @constraint(m, ag_co2_l_link_i_,
                # existing
                sum(
                    (-sum(o_ep1ge[i, j, l] for l in L)
                     -sum(o_ups_e_mt_in[i, j, l] for l in L)
                     -sum(n_ep1ge[i, j, l] for l in L)
                     -sum(n_ups_e_mt_in[i, j, l] for l in L)
                    )*p.yr_subperiod 
                    for j in P2 for i in P)
                # grid associated emissions
                #- sum(p.GcI[i,j,l]*0.29329722222222*
                #      (o_u[i, j, l] + n_u[i, j, l]) for l in L)
                >= -p.co2_budget[1, 1]
               )

    new_coal_fac = 0.7
    # @constraint(m, ag_coal_market_share_i_[i=P, j=P2],
    #             sum(n_ehf[i, j, l, 1] for l in L) <= 
    #             new_coal_fac * sum(r_ehf[1, 1, l, 1] for l in L)
    #            )
    new_ccus_fac = 0.99
#    @constraint(m, ag_ccus_market_share_i_[i=P, j=P2],
#                sum(o_rcp[i, j, l, 5] for l in L) +
#                sum(n_cp_d_[i, j, l, 5] for l in L) <= 
#                new_ccus_fac * (sum(o_cp[i, j, l] for l in L) + 
#                                sum(n_cp[i, j, l] for l in L))
#               )
#

    m[:lblock_attached] = true
end

function detachLocationBlock!(m::Model)
    delete.(m, m[:ag_dem_l_link_i_])
    unregister(m, :ag_dem_l_link_i_)
    delete.(m, m[:ag_co2_l_link_i_])
    unregister(m, :ag_co2_l_link_i_)
    m[:lblock_attached] = false
end

function turnover_con!(m::JuMP.Model, p::params, s::sets)
    L = s.L

    P = s.P
    P2 = s.P2

    # True/False
    sT = 1 # p.sTru
    sF= sT + 1 # p.sFal  # offline

    o_cp = m[:o_cp]
    n_cp = m[:n_cp]
    
    # @constraint(m, turnover[i=P, j=P2],
    #             sum(n_cp[i, j, l] for l in L) <= 
    #             0.5 * sum(o_cp[i, j, l] for l in L)
    #            )



end

function min_ep1ge!(m::JuMP.Model, p::params, s::sets)

    P2 = s.P2
    P = s.P
    L = s.L
    
    # True/False
    sT = 1 # p.sTru
    sF = sT + 1 # p.sFal  # offline

    o_ep1ge = m[:o_ep1ge]
    n_ep1ge = m[:n_ep1ge]


    @objective(m, Min,
               sum(o_ep1ge) + sum(n_ep1ge)
              )

end

# function reattachBlockMod!(m::Model, index_l, p::params,
#         s::sets)
# end

"""
    attachBlockObjective(m::Model, p::params, s::sets, D_k::Matrix{Float64},
    vv::Vector{VariableRef}, pi_::Vector{Float64}, sigma_k::Float64, 
    i_::Int64, l_::Int64)

    Update the objective function of the block k. 
    Note that the objective is c - piT*D - sigma, which is the reduced cost.
"""
function attachBlockObjective(m::Model, p::params, s::sets,
        D_k::Matrix{Float64}, vv::Vector{VariableRef}, 
        pi_::Vector{Float64}, i_::Int64, l_::Int64; pricing_p::Bool=true)
    # we only need the D_K block bits that correspond to the vector of variables
    #
    P2 = s.P2
    # True/False
    sT = 1 # p.sTru
    sF = sT + 1 # p.sFal  # offline
    #
    #
    o_pay = m[:o_pay]
    o_cfonm = m[:o_cfonm]
    o_cvonm = m[:o_cvonm]
    n_pay = m[:n_pay]
    n_cfonm = m[:n_cfonm]
    n_cvonm = m[:n_cvonm]
    o_loan_last = m[:o_loan_last]
    
    t_ret_cost = m[:t_ret_cost]  # 15
    n_loan_p = m[:n_loan_p]

    o_u_cost = m[:o_u_cost]
    n_u_cost = m[:n_u_cost]
    
    o_ehf_cost = m[:o_ehf_cost]
    n_ehf_cost = m[:n_ehf_cost]

    n_periods = p.n_periods
    n_subperiods = p.n_subperiods

    if i_ == last(s.L)
        clast = p.discount[n_periods, n_subperiods]
    else
        clast = 0
    end

    if pricing_p
        @objective(m, Min,
                   # 1 loan
                   sum(p.discount[i_, j] * o_pay[i_, j, l_] for j in P2)
                   # 2 o&m
                   + sum(p.discount[i_, j] * o_cfonm[i_, j, l_] for j in P2)
                   + sum(p.discount[i_, j] * o_cvonm[i_, j, l_] for j in P2)
                   # 3 loan new
                   + sum(p.discount[i_, j] * n_pay[i_, j, l_] for j in P2)
                   # 4 o&m new
                   + sum(p.discount[i_, j] * n_cfonm[i_, j, l_] for j in P2)
                   + sum(p.discount[i_, j] * n_cvonm[i_, j, l_] for j in P2)
                   # 5 retirement
                   + sum(p.discount[i_, j] * t_ret_cost[i_, j, l_]  for j in P2)
                   # 6
                   + clast * o_loan_last[i_, l_, sT]
                   # 7
                   + clast * n_loan_p[i_, n_subperiods, l_]
                   # 8 elec
                   + sum(p.discount[i_, j] * o_u_cost[i_, j, l_] for j in P2)
                   # 9 elec new
                   + sum(p.discount[i_, j] * n_u_cost[i_, j, l_] for j in P2)
                   # 10 fuel
                   + sum(p.discount[i_, j] * o_ehf_cost[i_, j, l_] for j in P2)
                   # 11 fuel new
                   + sum(p.discount[i_, j] * n_ehf_cost[i_, j, l_] for j in P2)
                   # complicating block
                   - pi_'*D_k*vv)
    else
        #@printf "Oracle\n"
        @objective(m, Min, -pi_'vv)
    end
end


function create_vector_mods(p::params, s::sets)
    mv = Vector{JuMP.Model}(undef, 0)
    k = 1
    d_id = Dict()
    for i in s.P
        for l in s.L
            m = createBlockMod(i, l, p, s)
            m[:_blk_ij] = (i, l)  # tag this model
            push!(mv, m)
            d_id[(i, l)] = k
            k += 1
        end
    end
    return mv
end

"""
This dual bound is equivalent to what you'd have in the Lagrangean relaxation.
In that case, the objective function would be:  L(pi) = pi'd + c'x - D*x
In DWD the subproblems have the form zeta = c'x - D*x, thus pi'd + zeta = L(pi)

"""
function calculateDualBound(mv::Vector{JuMP.Model}, pi_::Vector{Float64}, 
        rhs::Vector{Float64})
    zeta = objective_value.(mv)
    du_bnd = pi_'rhs + sum(zeta)
    return du_bnd
end


function save_discrete_state(m::JuMP.Model, p::params, s::sets)
    P = s.P
    P2 = s.P2
    L = s.L
    Kr = s.Kr
    Kn = s.Kn
    Fu_r = s.Fu_r
    Fu_n = s.Fu_n
    Nf = s.Nf
    
    r_filter = p.r_filter
    n_filter = p.n_filter

    y_o = value.(m[:y_o])  # [i,j,l]
    y_e = value.(m[:y_e])  # [i,j,l]
    y_r = value.(m[:y_r])  # [i,j,l,k]
    y_n = value.(m[:y_n])  # [i,j,l,k]

    r_yps = value.(m[:r_yps])  # [i,j,l]
    e_yps = value.(m[:e_yps])  # [i,j,l]
    n_yps = value.(m[:n_yps])  # [i,j,l]
   
    yo = DataFrame(Containers.rowtable(y_o; header=[:i, :j, :l, :y_o]))
    ye = DataFrame(Containers.rowtable(y_e; header=[:i, :j, :l, :y_e]))

    yr = DataFrame(Containers.rowtable(y_r; header=[:i, :j, :l, :k, :y_r]))
    yn = DataFrame(Containers.rowtable(y_n; header=[:i, :j, :l, :k, :y_n]))

    eyps = DataFrame(Containers.rowtable(e_yps; header=[:i, :j, :l, :e_yps]))
    ryps = DataFrame(Containers.rowtable(r_yps; header=[:i, :j, :l, :e_yps]))
    nyps = DataFrame(Containers.rowtable(n_yps; header=[:i, :j, :l, :n_yps]))

    CSV.write("yostate.csv", yo)
    CSV.write("yestate.csv", ye)
    CSV.write("yrstate.csv", yr)
    CSV.write("ynstate.csv", yn)
    CSV.write("eypsstate.csv", eyps)
    CSV.write("rypsstate.csv", ryps)
    CSV.write("nypsstate.csv", nyps)
end

function load_discrete_state(m::JuMP.Model, p::params, s::sets)
    P = s.P
    P2 = s.P2
    L = s.L
    Kr = s.Kr
    Kn = s.Kn
    Fu_r = s.Fu_r
    Fu_n = s.Fu_n
    Nf = s.Nf
    #
    yof="yostate.csv" 
    yef="yestate.csv" 
    yrf="yrstate.csv"
    ynf="ynstate.csv" 
    eypsf="eypsstate.csv"
    rypsf="rypsstate.csv"
    nypsf="nypsstate.csv"
    #
    yo = DataFrame(CSV.File(yof))
    ye = DataFrame(CSV.File(yef))
    yr = DataFrame(CSV.File(yrf))
    yn = DataFrame(CSV.File(ynf))
    eyps = DataFrame(CSV.File(eypsf));
    ryps = DataFrame(CSV.File(rypsf));
    nyps = DataFrame(CSV.File(nypsf));
    
    for row in 1:size(yo)[1]
        (i, j, l) = yo[row, 1:3]
        v = yo[row, 4]
        set_start_value(m[:y_o][i, j, l], v)
    end

    for row in 1:size(ye)[1]
        (i, j, l) = ye[row, 1:3]
        v = ye[row, 4]
        set_start_value(m[:y_e][i, j, l], v)
    end

    for row in 1:size(yr)[1]
        (i, j, l, k) = yr[row, 1:4]
        if !p.r_filter[l, k]
            continue
        end
        v = yr[row, 5]
        set_start_value(m[:y_r][i, j, l, k], v)
    end

    for row in 1:size(yn)[1]
        (i, j, l, k) = yn[row, 1:4]
        if !p.n_filter[l, k]
            continue
        end
        v = yn[row, 5]
        set_start_value(m[:y_n][i, j, l, k], v)
    end
    
    for row in 1:size(eyps)[1]
        (i, j, l) = eyps[row, 1:3]
        v = eyps[row, 4]
        set_start_value(m[:e_yps][i, j, l], v)
    end
    for row in 1:size(ryps)[1]
        (i, j, l) = ryps[row, 1:3]
        v = ryps[row, 4]
        set_start_value(m[:r_yps][i, j, l], v)
    end
    for row in 1:size(nyps)[1]
        (i, j, l) = nyps[row, 1:3]
        v = nyps[row, 4]
        set_start_value(m[:n_yps][i, j, l], v)
    end

end
