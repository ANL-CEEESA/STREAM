
using JuMP
using TimerOutputs


include("./bvb_aux_v04_01.jl")
"""
Generating the RMP requires an initial set of vertices.
"""
function Rmp(DxG::Array{Float64, 3}, cxG::Matrix{Float64}, rhs::Vector{Float64},
        nvb::Int64, consense::Vector{Int32}; 
        rho::Float64=1e3, phaseII::Bool=false)

    # xk has nvb by K blocks by n vertices
    ncolumns = size(cxG)[2]  # n vertices
    K = size(cxG)[1]  # blocks

    # D itself is constant
    # xk is an array of nvars_block * nblocks * ncolumns
    #
    
    # find the number of inequality constraints 
    ncomp_con_i = size(consense[consense.>0])[1]
    # find the number of equality constraints 
    ncomp_con_e = size(consense[consense.==0])[1]
    ncomp_con = ncomp_con_i + ncomp_con_e
    
    #
    rhs_i = rhs[consense.>0]
    rhs_e = rhs[consense.==0]
    

    # create model 
    rmp = Model()

    @variable(rmp, lambda[1:K, 1:ncolumns] >= 0.0)
    #
    @variable(rmp, slack[1:ncomp_con_i], lower_bound=0.0)
    @variable(rmp, p_i[1:ncomp_con_i], lower_bound=0.0)
    @variable(rmp, n_i[1:ncomp_con_i], lower_bound=0.0)
    @variable(rmp, p_e[1:ncomp_con_e], lower_bound=0.0)
    @variable(rmp, n_e[1:ncomp_con_e], lower_bound=0.0)

    # create the constraints
    # DixG
    #@constraint(rmp, comp_ineq, 
    #            sum(DixG[:, :, c]*lambda[:,c] for c in 1:ncolumns) - rhs_i
    #            in MOI.Nonnegatives(ncomp_con_i))
    if phaseII
        @constraint(rmp, comp_ineq, 
                    sum(DxG[consense.>0, :, c]*lambda[:,c] for c in 1:ncolumns) 
                    - slack - rhs_i .== 0.0)
        # DexG
        @constraint(rmp, comp_eq, 
                    sum(DxG[consense.==0, :, c]*lambda[:,c] for c in 1:ncolumns) 
                    - rhs_e .== 0.0)
        # sumLambda constraint
        @constraint(rmp, lambda_sum[k=1:K],
                    sum(lambda[k, col] for col in 1:ncolumns) == 1.0
                   )

        @objective(rmp, Min, 
                   sum(sum(cxG[k, col]*lambda[k, col]  for col in 1:ncolumns) 
                       for k in 1:K) 
                  )
    else
        @constraint(rmp, comp_ineq, 
                    sum(DxG[consense.>0, :, c]*lambda[:,c] for c in 1:ncolumns) 
                    - slack + p_i - n_i - rhs_i .== 0.0)
        # DexG
        @constraint(rmp, comp_eq, 
                    sum(DxG[consense.==0, :, c]*lambda[:,c] for c in 1:ncolumns) 
                    + p_e - n_e - rhs_e .== 0.0)
        # sumLambda constraint
        @constraint(rmp, lambda_sum[k=1:K],
                    sum(lambda[k, col] for col in 1:ncolumns) == 1.0
                   )

        rho = rho
        @objective(rmp, Min, 
                   sum(sum(cxG[k, col]*lambda[k, col]  for col in 1:ncolumns) 
                       for k in 1:K) 
                   + rho*(sum(p_i) + sum(n_i) + sum(p_e) + sum(n_e)
                         ))
    end
    rmp[:penalty] = rho
    return rmp
end


function compColumns(xk::Array{Float64, 3}, 
        D::Matrix{Float64}, c::Vector{Float64}, rhs::Vector{Float64},
        nvb::Int64)

    # xk has nvb by K blocks by n vertices
    ncolumns = size(xk)[3]  # n vertices
    K = size(xk)[2]  # blocks

    # D is constant
    # xk is an array of nvars_block * nblocks * ncolumns
    
    # create the `column` arrays
    cxG = Matrix{Float64}(undef, K, ncolumns)
    DxG = Array{Float64, 3}(undef, size(D)[1], K, ncolumns)
    
    # compute columns
    for col in 1:ncolumns
        for k in 1:K
            c0 = nvb * (k-1) + 1
            c1 = nvb * k
            # we need the first nvb elements
            x = xk[1:nvb, k, col]  # this guy is a matrix per column
            # calculate column (vector)
            #
            DxG[:, k, col] = D[:, c0:c1]*x
            #
            cxG[k, col] = c[c0:c1]'x
        end
    end
    return DxG, cxG
end

function addCol!(xk::Matrix{Float64}, 
        D::Matrix{Float64}, c::Vector, nvb::Int64,
        DxG::Array{Float64, 3}, cxG::Matrix{Float64})

    # at this point xk_new has one more column than lambda
    #if size(xk_new)[3] - size(rmp[:lambda])[2] != 1
    #    error("Number of columns in xk_new and lambda mismatch\n")
    #end
    # xk_new is xk with the appended column (third dimension) 
    # ncolumns = size(xk_new)[3] 
    K = size(xk)[2]


    # D has size of ncon by nvb
    Dxk = Matrix{Float64}(undef, size(D)[1], K)
    cxk = Vector{Float64}(undef, K)

    # compute new column coefficients
    for k in 1:K
        c0 = nvb * (k-1) + 1
        c1 = nvb * k
        Dxk[:, k] = D[:, c0:c1]*xk[1:nvb, k]
        cxk[k] = c[c0:c1]'xk[1:nvb, k]
    end

    DxG = cat(DxG, Dxk, dims=3)
    cxG = hcat(cxG, cxk)

    return DxG, cxG
end


function collectDuals(rmp::JuMP.Model)
    if !has_duals(rmp)
        optimize!(rmp)
    end
    di = dual.(LowerBoundRef.(rmp[:slack]))
    de = dual.(rmp[:comp_eq])
    sigma = dual.(rmp[:lambda_sum])
    return vcat(di, de), sigma
end



function compInfeasibility(rmp::JuMP.Model)
    p_i = value.(rmp[:p_i])
    n_i = value.(rmp[:n_i])
    p_e = value.(rmp[:p_e])
    n_e = value.(rmp[:n_e])
    infes = sum(p_i) + sum(n_i) + sum(p_e) + sum(n_e)
    return infes
end


function modifyPenaltyVars(rmp::JuMP.Model; active=true, penalty::T=1e3) where
    T<:Union{Float64, Vector{Float64}}
    if active
        v = 1.0  # coefficient in the constraint
        penalty = penalty
    else
        v = 0.0
        penalty = 0.0
    end

    for row in 1:length(rmp[:comp_ineq])
        set_normalized_coefficient(rmp[:comp_ineq][row],
                                   rmp[:p_i][row], v)
        set_normalized_coefficient(rmp[:comp_ineq][row],
                                   rmp[:n_i][row], -v)
    end
    for row in 1:length(rmp[:comp_eq])
        set_normalized_coefficient(rmp[:comp_eq][row],
                                   rmp[:p_e][row], v)
        set_normalized_coefficient(rmp[:comp_eq][row],
                                   rmp[:n_e][row], -v)
    end

    setPenaltyVal(rmp, penalty)
   
end


function setPenaltyVal(rmp::JuMP.Model, penalty::T) where 
    T<:Union{Float64, Vector{Float64}}

    if penalty isa Float64
        l = length(rmp[:comp_ineq]) + length(rmp[:comp_eq])
        penalty = ones(l).*penalty
    end
    for row in 1:length(rmp[:comp_ineq])
        set_objective_coefficient(rmp, rmp[:p_i][row], penalty[row])
        set_objective_coefficient(rmp, rmp[:n_i][row], penalty[row])
    end
    l0 = length(rmp[:comp_ineq])
    for row in 1:length(rmp[:comp_eq])
        set_objective_coefficient(rmp, rmp[:p_e][row], penalty[row + l0])
        set_objective_coefficient(rmp, rmp[:n_e][row], penalty[row + l0])
    end

    rmp[:penalty] = penalty
end

function deactPenaltiesRmp!(rmp::JuMP.Model)
    @info "Deactivating penalty variables"
    modifyPenaltyVars(rmp, active=false)
    rmp[:penalty] = 0.0
end

function reducedCostTest(rmp::JuMP.Model, mv::Vector{JuMP.Model}, tol::Float64)
    if !has_duals(rmp)
        optimize!(rmp)
    end
    # use the blocks of the problem
    zeta = objective_value.(mv)

    sigma = dual.(rmp[:lambda_sum])
    rval = false
    if sum(sigma) + sum(zeta) <= tol
        rval = true
    end
    return rval
end

function rmpActualObjVal(rmp::JuMP.Model)

    #ncolumns = size(xk)[3]
    #K = size(xk)[2]

    ofv = objective_value(rmp)

    penalty = rmp[:penalty]

    if penalty isa Float64
        if penalty == 0
            return ofv
        end
    elseif penalty isa Vector{Float64}
        if sum(penalty) == 0
            return ofv
        end
    end

    if penalty isa Float64
        l = length(rmp[:comp_ineq]) + length(rmp[:comp_eq])
        penalty = ones(l).*penalty
    end

    pn_iv = 0
    for row in 1:length(rmp[:comp_ineq])
        pn_iv += value(rmp[:p_i][row]) * penalty[row]
        pn_iv += value(rmp[:n_i][row]) * penalty[row]
    end
    l0 = length(rmp[:comp_ineq])

    pn_ev = 0
    for row in 1:length(rmp[:comp_eq])
        pn_ev += value(rmp[:p_e][row]) * penalty[row+l0]
        pn_ev += value(rmp[:n_e][row]) * penalty[row+l0]
    end


    return ofv - pn_iv - pn_ev

end


"""
    rmpNode(c_node::NodeBb)

Creates an rmp based on nodal information.
"""
function rmpNode(mv::Vector{JuMP.Model}, s::sets, 
        D::Matrix{Float64}, c::Vector{Float64}, 
        rhs::Vector{Float64}, nvb::Int64, consense::Vector{Int32}, 
        c_node::NodeBb; skip_parent=false)
    #
    p_node = AbstractTrees.parent(c_node) # start with parent
    if isnothing(p_node)
        @error("you are trying this with the root.")
    end
        p_data = p_node.data
    if skip_parent
        vert_act = generateVertex(mv, p, s, D, p_data.pi_)
        c_node.data.vert = vert_act
        if isnothing(vert_act)
            return nothing
        else
            DxG, cxG = compColumns(vert_act, D, c, rhs, nvb)
            return DxG, cxG, Rmp(DxG, cxG, rhs, nvb, consense)
        end
    else
        #p_node = AbstractTrees.parent(c_node) # start with parent
        #if isnothing(p_node)
        #    @error("you are trying this with the root.")
        #end
        # we need to filter out columns first
        p_data = p_node.data
        vert = p_data.vert
        # vert_act = vert

        cond = nodeCond(c_node.data.vid, c_node.data.sense, c_node.data.vbnd)
        act_vert_idx = redVertices(vert, cond)
        vert_act = vert[:, :, act_vert_idx]
        @printf "Parent vertices=%i\n" size(vert)[3]
        @printf "Remaining=%i\n" sum(act_vert_idx)

        if sum(act_vert_idx) == 0
            vert_act = generateVertex(mv, p, s, D, p_data.pi_)
        end
        # we only want to attach the vertices that arent derived from the parent
        # node
        
        # include the parent's filtered vertices
        #if !isnothing(vert_act)
        c_node.data.vert = vert_act
        #end
        # return
        if isnothing(vert_act)
            return nothing
        else
            DxG, cxG = compColumns(vert_act, D, c, rhs, nvb)
            return DxG, cxG, Rmp(DxG, cxG, rhs, nvb, consense)
        end
    end
end


function compPrimalfromRmp(rmp::JuMP.Model, xk::Array{Float64, 3})
    lambda = value.(rmp[:lambda])  # K rows by ncol
    ncols = size(lambda)[2]
    # x is nx by K by ncols
    x = zeros(size(xk)[1:2])
    #
    for k in 1:size(xk)[2]
        x[:, k] = sum(xk[:, k, col] * lambda[k, col] for col in 1:ncols)
    end
    return x
end

struct nodeCond
    #block::Int64
    #row::Int64
    vid::CartesianIndex{2}
    condition::Function
    function nodeCond(vid::CartesianIndex{2}, sense::nd_sense, 
            bnd::Union{Int64, Float64})
        if sense == nd_sense(-1)
            cond = x -> x <= bnd + 1e-09
        else
            cond = x -> x >= bnd - 1e-09
        end
        new(vid, cond)
    end
end


""" we need to find the vertices that satisfy a condition """
function redVertices(xk::Array{Float64, 3}, condition::nodeCond)
    #cond_block = condition.block
    #cond_row = condition.row
    cond_id = condition.vid
    n_vert = size(xk)[3]
    actual_cols = Vector{Bool}(undef, n_vert)
    actual_cols .= false
    for col in 1:n_vert
        xi = xk[cond_id, col]
        # find the good columns
        if condition.condition(xi)
            actual_cols[col] = true
        end
    end
    return actual_cols
end

"""Combine the parent vertices and the current vertices to compute the primal"""
function compPrimalNodeAndRmp(c_node::NodeBb, rmp::JuMP.Model; skip_parent=false)
    vert_current = c_node.data.vert
    if skip_parent
        total_vert = vert_current
    else
        p_node = AbstractTrees.parent(c_node) # start with parent
        if isnothing(p_node)
            @error("you are trying this with the root dummy.")
        end
        p_data = p_node.data
        vert_parent = p_data.vert
        # filter columns
        cond = nodeCond(c_node.data.vid, c_node.data.sense, c_node.data.vbnd)
        act_vert_idx = redVertices(vert_parent, cond)
        vert_act = vert_parent[:, :, act_vert_idx]
        #cond = nodeCond(c_data.vid, p_data.sense, p_data.vbnd)
        #act_vert = redVertices(xk_parent, cond)
        #xk_act = xk_parent[:,:,actual_vert]
        @printf "Parent vertices=%i\n" size(vert_act)[3]
        @printf "Current vertices=%i\n" size(vert_current)[3]
        total_vert = cat(vert_act, vert_current, dims=3)
    end
    x = compPrimalfromRmp(rmp, total_vert)
    return x
end



function generateVertex(mv::Vector{JuMP.Model}, 
        p::parms, s::sets, D::Matrix{Float64}, pi_::Vector{Float64})
    blockObjAttach!(mv, p, s, D, pi_) 
    # pricing_p=false)
    optimize!.(mv)
    mvbreak = false
    # break if this fails
    for tsblk in termination_status.(mv)
        if tsblk != MOI.TerminationStatusCode(1)
            @printf "One of the subproblems may be infeas.\n\n"
            mvbreak = true
        end
    end
    if mvbreak
        return nothing
    end
    return primalValVec(mv, p, s)

end

"""Calculate the column locks"""
function colLocks(D::Matrix{Float64}, nvb::Int64, consense::Vector{Int32})
    di = D[consense.>0, :]
    de = D[consense.==0, :]
    positive_locks = count(>(0), di, dims=1)
    negative_locks = count(<(0), di, dims=1)

    positive_locks += count(>(0), de, dims=1)
    negative_locks += count(<(0), de, dims=1)
    # we need the viable columns
    #
    return positive_locks, negative_locks
end

