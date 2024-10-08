################################################################################
#                    Copyright 2022, UChicago LLC. Argonne                     #
#       This Source Code form is subject to the terms of the MIT license.      #
################################################################################
# vim: expandtab colorcolumn=80 tw=80

# created @dthierry 2023
# description: auxiliar structs for the dwd
# log:
# 7-07-23 renaming 
#
#
#80#############################################################################

"""
    branch_v_bound

Basic unit from which a node is defined. 
It contains string with the name of the variable.
Integer containing the value of the node.
Char with the sense, i.e. L or U
Bool to indicate wether this is a binary variable, and an unique id.
"""
struct branch_v_bound
    s::String
    bnd::Int
    sense::Char
    bin::Bool
    uid::UInt16
end

@enum nd_stat ndStUnvisited=0 ndStVisited=1 ndStOngoing=2
@enum nd_sense nSroot=0 nSleft=-1 nSright=1
@enum nd_i unknown=0 pInteger=1 infeasible=2 lowerBound=3 numericErr=4

mutable struct dwd_node
    uid::UInt32  # 1 root if 0x000000 
    vid::CartesianIndex{2}  # 2
    vbnd::Int64  # 3
    sense::nd_sense  # 4 is this superfluous
    vert::Array{Float64, 3}  # 5 vertices
    x::Matrix{Float64}  # 6
    pi_::Vector{Float64}  # 7
    sigma_::Vector{Float64}  # 8
    du_bnd::Float64  # 9
    z_rmp::Float64  # 10
    flag::nd_i  # 11
    stat::nd_stat  # 12
end


using AbstractTrees
# NodeBb
mutable struct NodeBb
    data::dwd_node
    parent::Union{Nothing, NodeBb}
    left::Union{Nothing, NodeBb}
    right::Union{Nothing, NodeBb}
    function NodeBb(data, parent=nothing, l=nothing, r=nothing)
        new(data, parent, l, r)
    end
end

function leftChild!(parent::NodeBb, data)
    isnothing(parent.left) || error("left child is already assigned")
    node = NodeBb(data, parent)
    parent.left = node
end


function rightChild!(parent::NodeBb, data)
    isnothing(parent.right) || error("left child is already assigned")
    node = NodeBb(data, parent)
    parent.right = node
end

function AbstractTrees.children(node::NodeBb)
    if isnothing(node.left) && isnothing(node.right)
        ()
    elseif isnothing(node.left) && !isnothing(node.right)
        (node.right,)
    elseif !isnothing(node.left) && isnothing(node.right)
        (node.left,)
    else
        (node.left, node.right)
    end
end


AbstractTrees.nodevalue(n::NodeBb) = n.data

AbstractTrees.ParentLinks(::Type{<:NodeBb}) = StoredParents()

AbstractTrees.parent(n::NodeBb) = n.parent

AbstractTrees.NodeType(::Type{<:NodeBb}) = HasNodeType()
AbstractTrees.nodetype(::Type{<:NodeBb}) = NodeBb


