
include("../mod/sets_v03_22.jl")
include("../mod/bm_v04_10.jl")

include("rmp_v05_16.jl")

import MathOptInterface as MOI

mutable struct prob_settings
    MAX_CG_ITER::Int64     # 1 column generation iterations
    MAX_STALL_ITER::Int64  # 2
    MAX_PENALTY::Float64   # 3
    penalty::Float64       # 4
    phaseII::Bool          # 5
    tol::Float64           # 6

    function prob_settings()
        new(200, 5, 1e6, 1e3, false, 1e-6)
    end
end

mutable struct dwd_info
    it::Int64         # 1
    p2it::Int64         # 2 phase II iteration
    stallc::Int64       # 3 stalled count
    z_rmp::Float64      # 4
    mred_cost::Float64  # 5
    du_bnd::Float64     # 6
    infes::Float64      # 7
    nrm_pi::Float64     # 8
    nrm_pi0::Float64    # 9
    pp_time::Float64    # 10
    rmp_ts::MOI.TerminationStatusCode # 11
    function dwd_info()
        #   #1 #2 #3 #4     #5    #6     #7   #8   #9   #10
        new(0, 0, 0, 1e99, -1e99, -1e99, 1e6, 9e6, 1e6, 1e6,
            MOI.TerminationStatusCode(0))
    end
end
# phaseI is the feasibility problem.


"""
Inner approximation construction steps:
- Check convergence
- solve rmp
- generate vertices

"""
function column_generation!(rmp::JuMP.Model, mv::Vector{JuMP.Model}, 
        p::parms, s::sets, 
        D::Matrix{Float64}, rhs::Vector{Float64}, c::Vector{Float64},
        pi_::Vector{Float64}, sigma_::Vector{Float64}, 
        DxG::Array{Float64, 3}, cxG::Matrix{Float64},
        p_s::prob_settings, node::dwd_node)
    # info datastructure
    dwdi = dwd_info()

    nv = length(all_variables(mv[1]))
    # vertices
    #vert = Array{Float64, 3}(undef, nv, length(mv), 0)
    #
    vert = node.vert
    n_vert0 = size(vert)[3]
    @warn "Column Generation\t%x\n" node.uid

    #
    while true

        ## ## ## ##
        # check convergence
        stat = dwd_check_conv(rmp, p_s, dwdi, node)
        if stat
            println(size(rmp[:lambda]))
            println(size(vert))
            break
        end
        dwdi.nrm_pi0 = dwdi.nrm_pi

        ## ## ## ##
        # solve rmp
        println(size(rmp[:lambda]))
        optimize!(rmp)

        tsrmp = termination_status(rmp)

        rmp_time = solve_time(rmp)

        println(tsrmp)
        if tsrmp != MOI.TerminationStatusCode(1)
            @warn("Non optimal RMP")
            @printf "Status =\t\t"
            @printf "\n"
            # try to save the situation
            if tsrmp == MOI.TerminationStatusCode(20)
                @warn("Numerical error, try again")
                optimize!(rmp)
                if termination_status(rmp) != MOI.TerminationStatusCode(1)
                    if node.flag == nd_i(4)
                        node.flag = nd_i(2)  # infes
                    else
                        node.flag = nd_i(4)  # numerr
                    end
                    break
                end
                #elseif tsrmp == MOI.TerminationStatusCode(2)
                #    node.flag = nd_i(2)  # infes
                #    break
                #end
            else
                node.flag = nd_i(2)
                @warn("Declared infeasible")
                break
            end
        end
        if !has_values(rmp)
            @warn("there are no values for this problem")
        end
        tsrmp = Int(tsrmp)

        # get objective value
        dwdi.z_rmp = rmpActualObjVal(rmp)

        # get the duals 
        pi_, sigma_ = collectDuals(rmp)
        
        # calculate the 1-norm of pi_
        dwdi.nrm_pi = sum(abs.(pi_))
        

        # compute infeasibility
        if !p_s.phaseII
            dwdi.infes = compInfeasibility(rmp)
        end

        ## ## ## ##
        # pricing problem
        pricing_p = true  # search for the farthest point of Q2
        blockObjAttach!(mv, p, s, D, pi_, pricing_p=pricing_p)
        optimize!.(mv)
        mvbreak = false
        # break if this fails
        for tsblk in termination_status.(mv)
            if tsblk != MOI.TerminationStatusCode(1)
                @printf "One of the subproblems may be infeas.\n\n"
                dwdi.rmp_ts = tsblk 
                mvbreak = true
            end
        end
        if mvbreak
            # declare infeas
            node.flag = nd_i(2)
            break
        end


        # du_bnd goes before the calculation of the new vertex
        dwdi.du_bnd = calculateDualBound(mv, pi_, rhs)

        # calc reduced cost
        red_cost = objective_value.(mv) .- sigma_
        dwdi.mred_cost = min(red_cost...)

        # append vertices
        
        vert = cat(vert, primalValVec(mv, p, s), dims=3)

        # solution time
        dwdi.pp_time = sum(solve_time.(mv))
        
        # add column to rmp problem
        #
        @time DxG, cxG = addCol!(vert[:,:,end], D, c, nvb, DxG, cxG)
        @time rmp = Rmp(DxG, cxG, rhs, nvb, consense;
                        rho=p_s.penalty, phaseII=p_s.phaseII)

        set_optimizer(rmp, Gurobi.Optimizer)
        set_silent(rmp)
        set_optimizer_attribute(rmp, "Method", 2);
        set_optimizer_attribute(rmp, "BarConvTol", 1e-4);
        set_optimizer_attribute(rmp, "TIME_LIMIT", 120.);
        #@time addColtoRmp!(rmp, vert, D, c, nvb, consense)
        
        # print some information
        @printf "i=%i stat=%i inf=%3.2e " dwdi.it tsrmp dwdi.infes 
        @printf "zrmp=%3.3e " dwdi.z_rmp
        @printf "du_bnd=%3.3e " dwdi.du_bnd
        @printf "Σrc=%3.3e\n" dwdi.mred_cost

        @printf "|π|=%3.3e\t" dwdi.nrm_pi
        @printf "PP time=%3.3f\t" dwdi.pp_time
        @printf "rmp time=%3.3f\n" rmp_time

        if dwdi.nrm_pi > 1e10
            @printf "penalty = %3.3e\n" rmp[:penalty]
        end

        # set the penalty of the rmp
        if !p_s.phaseII
            dwd_set_penalty!(rmp, p_s, dwdi)
        end

        dwdi.it += 1

    end
    #
    if node.flag != nd_i(2)
        if !has_values(rmp)
            set_silent(rmp)
            optimize!(rmp)
            tsrmp = termination_status(rmp)
            if tsrmp == MOI.TerminationStatusCode(2) # whoops
                println(tsrmp)
                @error("this should not happen")
                dwdi.rmp_ts = MOI.TerminationStatusCode(2)
                node.flag = nd_i(2)
                node.stat = nd_stat(1)
            end
        end
        node.vert = vert                # 1
        node.pi_ = pi_                  # 2
        node.sigma_ = sigma_            # 3
        node.du_bnd = dwdi.du_bnd       # 4
        node.z_rmp = dwdi.z_rmp         # 5
        if has_values(rmp)
            node.x = compPrimalfromRmp(rmp, vert)
        else
            @warn("rmp variables not computed")
        end
        node.stat = nd_stat(1)
    end

    return rmp, vert
end


function dwd_bnd!(rmp::JuMP.Model, mv::Vector{JuMP.Model}, 
        p::parms, s::sets,
        D::Matrix{Float64}, rhs::Vector{Float64}, c::Vector{Float64},
        pi_::Vector{Float64}, sigma_::Vector{Float64}, 
        DxG::Array{Float64, 3}, cxG::Matrix{Float64},
        p_s::prob_settings, node::dwd_node
    )
    # what parameters are not changing in this procedure
    # create an empty primal vector
    rmp, vert = column_generation!(rmp, mv, 
                                   p, s, 
                                   D, rhs, c, pi_, sigma_, 
                                   DxG, cxG,
                                   p_s, node
                                  )
    return rmp, vert
    
end



function dwd_check_conv(rmp::JuMP.Model, p_s::prob_settings, 
        dwdi::dwd_info, node::dwd_node)
    # infeasibility
    if !p_s.phaseII && dwdi.infes < p_s.tol
        @printf "Infeasibility less than tolerance.\n\n"
        @printf "Switch to phase II\n\n"
        dwdi.stallc = 0
        deactPenaltiesRmp!(rmp)
        #setPenaltyVal(rmp, 1e-06)
        p_s.phaseII = true
        return false
    end
    #
    if !p_s.phaseII && sum(dwdi.mred_cost) > -p_s.tol && dwdi.infes > p_s.tol
        dwdi.rmp_ts = MOI.TerminationStatusCode(2)
        node.flag = nd_i(2)
        @printf "Infeasible model\n"
        return true
    end
    #
    if p_s.phaseII && sum(dwdi.mred_cost) > -p_s.tol
        dwdi.rmp_ts = MOI.TerminationStatusCode(1)
        node.flag = nd_i(3)  # lower bound
        @printf "Reduced cost termination\n"
        return true
    end
    if abs(dwdi.nrm_pi - dwdi.nrm_pi0) <= p_s.tol
        @printf "\nStalling...\n"
        dwdi.stallc += 1
        if dwdi.stallc > p_s.MAX_STALL_ITER
            if dwdi.infes > p_s.tol
                node.flag = nd_i(2)  # infes
                @printf "\nStall..INFES...(exit)\n"
            else
                node.flag = nd_i(0)  # unknown
                @printf "\nStall..phaseII...(exit)\n"
            end
            return true
        end
    end
    # 
    if dwdi.it > p_s.MAX_CG_ITER
        @printf "Maximum Iterations\n"
        if dwdi.infes > p_s.tol
            node.flag = nd_i(2)
        else
            node.flag = nd_i(0)  # unknown
        end
        return true
    end
    return false
end


function dwd_set_penalty!(rmp::JuMP.Model, p_s::prob_settings,
    dwdi::dwd_info)
    if p_s.phaseII
        dwdi.p2it += 1  # phase 2 iterations
    else
        p_s.penalty = min(p_s.MAX_PENALTY,
                          p_s.penalty * (1 + dwdi.it/10))  # increase penalty
        setPenaltyVal(rmp, p_s.penalty)
    end
end



function proove_valid_ineq(vertex::Matrix{Float64}, pi_::Vector{}, 
        pi0::Vector{Float64})
    return false
end

