

include("../mod/sets_v03_22.jl")
include("../mod/params_v03_22.jl")

include("../mod/bm_v04_10.jl")
include("../mod/compMat_v03_28.jl")


include("dwd_v05_17.jl")
include("bvb_aux_v04_01.jl")
include("rmp_v05_16.jl")


import MathOptInterface as MOI
using Gurobi

@enum bnb_stat gapLessTol=0 ubFound=1 nonConv=2


mutable struct bnb_info
    iteration::Int64  # 1
    nrm_pi_::Float64  # 2
    nrm_sigma_::Float64  # 3
    UB::Float64  # 4
    DB::Float64  # 5
    UB_history::Vector{Float64}  # 6
    DB_history::Vector{Float64}  # 7
    current_uuid::UInt32  # 8
    gap::Float64  # 9
    stat::bnb_stat  # 10
    discTol::Float64  # 11
    gapTol::Float64   # 12
    function bnb_info() 
        new(0,  # 1
            1e0,  # 2
            1e0,  # 3
            1e99,  # 4 
            -1e99,  # 5 
            Vector{Float64}(undef, 0),  # 6 
            Vector{Float64}(undef, 0),  # 7 
            UInt32(0),  # 8
            100.,  # 9
            bnb_stat(2),  # 10
            1e-06,  # 11
            1e-01  # 12
           )
    end
end


function preamble(p)
    # preamble start
    s = sets(p.n_periods, p.n_years, p.n_location, p.n_rtft, p.n_new, p.n_fu)
    # need to construct the full problem
    m = createBlockMod(s.P, s.L, p, s)
    # need to construct the subproblems
    mv = create_vector_mods(p, s)
    # ids = discVarIds(mv, p, s)
    #1 #2  #3  #4   #5   #6        #7
    D, vv, vp, nvb, rhs, consense, pi0 = complicatingMatrix(m, p, s)
    c = compObjFCoef(m, p, s)
    #
    pi_ = ones(size(D)[1])
    #p_s = prob_settings() # default problem settings

    blockObjAttach!(mv, p, s, D, pi_) 
                    # pricing_p=false)
    set_optimizer.(mv, Gurobi.Optimizer)
    set_silent.(mv)
    # generate the labels
    vlabels = primValVecLabels(mv, p, s)
    # generate the list of discrete
    viable_vars = discVarIds(mv, p, s)
    #relax_integrality.(mv)

    
    #     #1  #2 #3  #4 #5  #6  #7   #8   #9        #10#11      #12
    return s, m, mv, D, vv, vp, nvb, rhs, consense, c, vlabels, viable_vars
end

"""construct an rmp, solve it, and update the node struct"""
function solveNodeMod!(mv::Vector{JuMP.Model}, p::parms, s::sets, 
        D::Matrix{Float64}, c::Vector{Float64}, rhs::Vector{Float64},
        nvb::Int64, consense::Vector{Int32}, c_node::NodeBb)
    c_node.data.stat = nd_stat(2)
    #
    # create rmp (from parent)
    DxG, cxG, rmp = rmpNode(mv, s, D, c, rhs, nvb, consense, c_node, 
                           skip_parent=false)

    if isnothing(rmp)
        @warn("Infeasible node")
        c_node.data.stat = nd_stat(1)
        c_node.data.flag = nd_i(2)
        return MOI.TerminationStatusCode(2)
    end

    p_node = AbstractTrees.parent(c_node) # parent
    if isnothing(p_node)
        @error("you are trying this with the root dummy.")
    end

    # get dual variables
    pi0 = p_node.data.pi_
    sigma0 = p_node.data.sigma_

    # run the column generation
    p_s = prob_settings()
    
    set_optimizer(rmp, Gurobi.Optimizer)
    set_silent(rmp)
    set_optimizer_attribute(rmp, "Method", 2);
    set_optimizer_attribute(rmp, "BarConvTol", 1e-2);
    set_optimizer_attribute(rmp, "TIME_LIMIT", 120.);
    
    vert = c_node.data.vert
    @printf "vertices0=%i\n" size(vert)[3]

    dwd_bnd!(rmp, mv, p, s, D, rhs, c, pi0, sigma0, DxG, cxG, p_s, c_node.data)
    # try again if numerical issues
    skip_p = false
    if c_node.data.flag == nd_i(4)
        DxG, cxG, rmp = rmpNode(mv, s, D, c, rhs, nvb, consense, c_node, 
                                skip_parent=true)
        set_optimizer(rmp, Gurobi.Optimizer)
        set_silent(rmp)
    dwd_bnd!(rmp, mv, p, s, D, rhs, c, pi0, sigma0, DxG, cxG, p_s, c_node.data)
        skip_p = true
    end

    # put the primal vector here
    if c_node.data.flag != nd_i(2)
        #c_node.data.x = compPrimalNodeAndRmp(c_node, rmp, skip_parent=skip_p)
    end
    c_node.data.stat = nd_stat(1)  # visited
    vert = c_node.data.vert
    @printf "vertices end =%i\n" size(vert)[3]
end


"""generate and solve the root model problem"""
function rootNode(mv::Vector{JuMP.Model}, p::parms, s::sets, 
        D::Matrix{Float64}, c::Vector{Float64}, rhs::Vector{Float64}, 
        nvb::Int64, consense::Vector{Int32}, vlabels::Matrix{String})
    # generate an initial set of vertices
    optimize!.(mv)
    rcv = objective_value.(mv)
    tsv = termination_status.(mv) .== MOI.TerminationStatusCode(1)
    for ts in tsv
        if !ts
            @error("Root problem might be infeasible")
        end
    end
    #x0 = initialGuess(m, p, s, vlabels)
    #x0 = reshape(x0, (size(x0)[1], size(x0)[2], 1))
    x0 = primalValVec(mv, p, s)
    # solve the root node

    DxG, cxG = compColumns(x0, D, c, rhs, nvb)
    rmp = Rmp(DxG, cxG, rhs, nvb, consense)
    
    #deactPenaltiesRmp!(rmp)
    # solve the root node rmp
    root = dwd_node(UInt32(0),                      # 1
                    CartesianIndex{2}((0,0)),       # 2
                    0.0,                            # 3
                    nd_sense(0),                    # 4
                    #Array{Float64, 3}(undef, 1,1,0),# 5
                    x0,
                    Matrix{Float64}(undef, 1, 1),   # 6
                    Vector{Float64}(undef, 1),      # 7
                    Vector{Float64}(undef, 1),      # 8
                    -1e9,                           # 9
                    1e9,                            # 10
                    nd_i(0),                        # 11
                    nd_stat(0)                      # 12
                   )

    pi0 = ones(size(D)[1])
    sigma0 = ones(length(mv))
    p_s = prob_settings() # default problem settings

    set_optimizer(rmp, Gurobi.Optimizer)
    set_silent(rmp)
    dwd_bnd!(rmp, mv, 
             p, s, 
             D, rhs, c, pi0, sigma0, 
             DxG, cxG,
             p_s, root)

    #println(size(rmp[:lambda]))
    #println(size(root.vert))
    #
    #root.x = compPrimalfromRmp(rmp, cat(x0, root.vert, dims=3))
    #root.x = compPrimalfromRmp(rmp, root.vert)

    return NodeBb(root)
end

"""
    branch!()
"""
function branch!(c_node::NodeBb, 
        viable_vars::Vector{Tuple{CartesianIndex{2}, Bool}})
    (l, r) = genChildren(c_node, viable_vars)
    leftChild!(c_node, l)
    rightChild!(c_node, r)
end

"""
    bound!()
"""
function bound!(mv::Vector{JuMP.Model}, p::parms, s::sets, 
        D::Matrix{Float64}, c::Vector{Float64}, rhs::Vector{Float64},
        nvb::Int64, consense::Vector{Int32}, vlabels::Matrix{String},
        c_node::NodeBb)
    #
    lcon = setSubPBoundCon!(mv, c_node, vlabels)
    #
    solveNodeMod!(mv, p, s, D, c, rhs, nvb, consense, c_node)
    #
    resetSubProbs!(mv, lcon)
    return c_node
end


""" prune!() 
true if yes
"""
function prune!(c_node::NodeBb, 
        vIds::Vector{Tuple{CartesianIndex{2}, Bool}},
        bnbi::bnb_info)
    if c_node.data.stat != nd_stat(1)
        @error("This node has not been visited")
    end
    n_i = c_node.data.flag
    # prune by infes.
    if n_i == nd_i(2)
        return true
    end
    # prune by bound.
    if c_node.data.du_bnd > bnbi.UB
        return true
    end
    bnbi.DB = max(bnbi.DB, c_node.data.du_bnd)
    # update upper bound.

    isInt = checkIntMod(c_node.data.x, vIds, bnbi.discTol)
    if isInt
        @warn "Integral model found"
        c_node.data.flag = nd_i(1)
        # check if this is better than the incument
        if c_node.data.du_bnd < bnbi.UB
            bnbi.UB = c_node.data.du_bnd
            return true
        end
    end
    #
    return false

end

"""returns the left and right node of the search tree"""
function genChildren(c_node::NodeBb, 
        viable_vars::Vector{Tuple{CartesianIndex{2}, Bool}})
    # this should be called generate children nodes
    # get a list of the visited variables 
    visited_vars = []
    n0 = c_node
    while !isnothing(AbstractTrees.parent(n0))
        vid = n0.data.vid
        push!(visited_vars, vid)
        n0 = AbstractTrees.parent(n0)
    end
    
    # extract the cartesian index
    viable_vars_v = [viable_vars[i][1] for i in 1:length(viable_vars)]
    # remove the already visited variables
    act_viable_vars = filter(!in(visited_vars), viable_vars_v)
    if length(act_viable_vars) < 1
        @printf "No viable variables found."
        return nothing
    end
    # find variable with the highest degradation
    x = c_node.data.x
    vdegr = varDegradation(x, act_viable_vars)
    (vmax, vi) = findmax(vdegr)
    #vid = viable_vars_v[vi]
    vid = act_viable_vars[vi]
    
    nv = length(all_variables(mv[1]))
    uid = rand(UInt32)  # we can use the same uid
    # left node
    ln = dwd_node(uid,  # 1
                   #viable_vars_v[vi],  # 2
                   act_viable_vars[vi],  # 2
                   floor(x[vid]),  # 3
                   nd_sense(-1),  # 4
                   # Array{Float64, 3}(undef, 1,1,0),  # 5
                   Array{Float64, 3}(undef, nv, length(mv), 0),
                   Matrix{Float64}(undef, 1, 1),  # 6
                   Vector{Float64}(undef, 1),  # 7
                   Vector{Float64}(undef, 1),  # 8
                   -1e9,  # 9
                   +1e9,  # 10
                   nd_i(0),  # 11
                   nd_stat(0)  # 12
                  )
    # right node
    rn = dwd_node(uid,  # 1
                   #viable_vars_v[vi],  # 2
                   act_viable_vars[vi],  # 2
                   ceil(x[vid]),  # 3
                   nd_sense(1),  # 4
                   # Array{Float64, 3}(undef, 1,1,0),  # 5
                   Array{Float64, 3}(undef, nv, length(mv), 0),
                   Matrix{Float64}(undef, 1, 1),  # 6
                   Vector{Float64}(undef, 1),  # 7
                   Vector{Float64}(undef, 1),  # 8
                   -1e9,  # 9
                   +1e9,  # 10
                   nd_i(0),  # 11
                   nd_stat(0)  # 12
                  )

    return (ln, rn)
    
end

"""checks all discrete variables for integrality"""
function checkIntMod(x::Matrix{Float64}, 
        vIds::Vector{Tuple{CartesianIndex{2}, Bool}},
        discTol::Float64=1e-06)

    s = 0.0
    for vid in vIds
        i = vid[1]
        val = x[i]
        l = val - floor(val)
        u = ceil(val) - val
        # if the minimum is farther than tol otw return
        s += min(l, u)
        # if min(l, u) >= discTol
        #     return false
        # end
    end
    @printf "\n\n ZI = %f\n" s
    if s >= discTol
        return false
    end
    @warn "Integral solution found \n\n"
    return true
end

"""returns the degradation for all the variables"""
function varDegradation(x::Matrix{Float64}, 
        discVarIds::Vector{CartesianIndex{2}})
    d = Vector{Float64}(undef, length(discVarIds))
    for i in 1:length(discVarIds)
        idx = discVarIds[i]  # cartesian index
        val = x[idx]
        vdash = val - floor(val)
        vplus = 1 - vdash
        d[i] = min(vdash, vplus)
    end
    return d
end

"""check convergence"""
function checkConvergence!(bnbi::bnb_info)

    # check dual_bnd
    #if c_node.du_bnd >= bnbi.LB
    #    bnbi.LB = c_node.du_bnd
    #end
    bnbi.gap = abs(bnbi.UB - bnbi.DB)/abs(bnbi.DB) 
    if  bnbi.gap <= bnbi.gapTol
        bnbi.stat = bnb_stat(0)
        return true
    end

    return false

end


"""Set the bounds of discrete variables"""
function setSubPBoundCon!(mv::Vector{JuMP.Model}, c_node::NodeBb, 
        vlabels::Matrix{String})
    U = MOI.GreaterThan{Float64}
    L = MOI.LessThan{Float64}
    # list of model index and constraint names
    l = Vector{Tuple{Int64, String}}(undef, 0)
    uid = rand(UInt32)  # unique id
    while !isnothing(AbstractTrees.parent(c_node))
        p_data = c_node.data
        v_coord = p_data.vid
        k = v_coord[2]  # get model index
        vname = vlabels[v_coord]  # get variable name
        m = mv[k]
        v = variable_by_name(m, vname)
        if !isnothing(v)
            # constraint name
            cname = "cbnb-$(vname)-$(uid)"
            # sense
            s = (p_data.sense == nd_sense(1) ? 
                 U(p_data.vbnd-1e-08) : L(p_data.vbnd+1e-08))
            # create the constraint
            @constraint(m, 1.0*v in s, base_name=cname)
            # push it to the list
            push!(l, (k, cname))
            # note: cant use variableref here because base name does not
            # work
        end
        # get parent
        c_node = AbstractTrees.parent(c_node)
    end
    return l # useful to reset the problems
end

"""Resets the subproblems"""
function resetSubProbs!(mv::Vector{JuMP.Model}, 
        lcon::Vector{Tuple{Int64, String}})
    for (k, cname) in lcon
        # fetch model
        m = mv[k]
        c = constraint_by_name(m, cname)
        delete(m, c)
        unregister(m, Symbol(cname))
    end
end


function initialGuess(m::JuMP.Model, p::parms, s::sets, vlabels::Matrix{String})
    if !m[:pblock_attached]
        attachPeriodBlock(m, p, s)
        @printf "Period block attached\n"
    end
    if !m[:lblock_attached]
        attachLocationBlock(m, p, s)
        @printf "Location block attached\n"
    end

    attachFullObjectiveBlock(m, p, s)
    relax_integrality(m)
    set_optimizer(m, Gurobi.Optimizer)
    optimize!(m)
    x0 = zeros(size(vlabels))
    for row in 1:size(vlabels)[1]
        for col in 1:size(vlabels)[2]
            vname = vlabels[row, col]
            v = variable_by_name(m, vname)
            x0[row, col] = value(v)
        end
    end
    return x0
end

function fix_heur!(m::JuMP.Model, 
        viable_vars::Vector{Tuple{CartesianIndex{2}, Bool}},
        vlabels::Matrix{String}, c_node::NodeBb)
    x = c_node.data.x
    vfix_count = 0
    for vi in viable_vars
        val = x[vi[1]]
        l = val - floor(val)
        u = ceil(val) - val
        #@printf "%2.3f\t%2.3f\t%2.3f\t" val l u
        val = l > u ? ceil(val) : floor(val)
        #@printf "%2.f\n" val
        vn = vlabels[vi[1]]
        v = variable_by_name(m, vn)
        #
        if !isnothing(v)
            fix(v, val; force=true)
            vfix_count += 1
        end
    end

    @printf "fix_heur vcount = %i\n" vfix_count

    set_optimizer(m, Gurobi.Optimizer)
    optimize!(m)
    if termination_status(m) == MOI.TerminationStatusCode(1)
        @printf "Upper bound has been found by fixing heuristic\n"
        c_node.data.z_rmp = objective_value(m)
        return true
    end
    for vi in viable_vars
        vn = vlabels[vi[1]]
        v = variable_by_name(m, vn)
        #
        if !isnothing(v)
            unfix(v)
            vfix_count -= 1
        end
    end
    @printf "fix_heur unfixed %i\n" vfix_count
    return false

end

