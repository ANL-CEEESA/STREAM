################################################################################
#                    Copyright 2022, UChicago LLC. Argonne                     #
#       This Source Code form is subject to the terms of the MIT license.      #
################################################################################
# vim: expandtab colorcolumn=80 tw=80

# created @dthierry 2023
# description: prototype example of how to set up a case study with the input
# excel file.
# 
#
# log:
#  
#
#
#80#############################################################################
#: imports
import Clp
Clp.Clp_Version() #: this one is necessary sometimes in macos

using stre3am 
using JuMP

#80#############################################################################
function main()
    #76#########################################################################
    # initialize journalist structure
    pr = dre4m.prJrnl() #: initialize journalist data structure
    jrnl = dre4m.j_start #: journal action (does not change)
    pr.caller = @__FILE__ #: caller (does not change) 
     
    pr.tag = "_MY_TAG" #: set this to tag the results folder
    
    dre4m.jrnlst!(pr, jrnl) #: pass the data
    #76#########################################################################
    # declare data file
    file = "../../data/prototype/prototype_0.xlsx"
    # time horizon
    T = 2050-2020 + 1
    # technologies
    I = 11
    
    # the following attributes are necessary to set-up a problem.
    ## (a) time Attributes
    ta = dre4m.timeAttr(file)
    ## (b) cost attributes
    ca = dre4m.costAttr(file)
    ## (c) inv(time invariant) attributes
    ia = dre4m.invrAttr(file)
    ## (d) miscellaneous
    misc = dre4m.miscParam(file)
    
    # initialize data
    ## retrofit abstract form requirements
    ### (a) cell (reference sheet) position for the `kinds of retrofits`
    rtf_kinds = "B22"
    ### (b) cell (reference sheet) position for the `data for retrofits`
    rtf_data = "B28" 
    rtf = dre4m.absForm(file, rtf_kinds, rtf_data)
    ## new absract form requirements
    ### (a) cell (reference sheet) position for the `kinds of retrofits`
    nwf_kinds = "B23" # (a) cell position for the `kinds new plants`
    ### (b) cell (reference sheet) position for the `data new plants`
    nwf_data = "B29"
    nwf = dre4m.absForm(file, nwf_kinds, nwf_data)

    # setup sets
    mS = dre4m.modSets(T, I, ia, rtf, nwf)
    # setup data
    mD = dre4m.modData(ta, ca, ia, rtf, nwf, misc)
    # generate model
    mod = dre4m.genModel(mS, mD, pr) 

    # generate objective with latency factor of 1e-01 (optional)
    dre4m.genObj!(mod, mS, mD, latFact=1e-01)
    
    # Some additional constraints
    # e.g. 0.25 of `8` for every unit of `7`
    #dre4m.gridConWind!(mod, mS, 7, Dict(8=>0.25, 9=>0.25, 10=>0.03)) #: wind-
    #: -ratio
    #dre4m.gridConUpperBound!(mod, mS) #: upper bound on bio, nuclear and hydro
    
    dre4m.EmConBudget!(mod, mS) #: emission constraint
    
    # journal action
    jrnl = dre4m.j_query #: journal action (query)
    dre4m.jrnlst!(pr, jrnl)
    #
    
    # set linear programming solver
    set_optimizer(mod, Clp.Optimizer)
    # solve
    optimize!(mod)

    # update the journalist
    dre4m.jrnlst!(pr, jrnl)
    # write the results in the spreadsheets
    dre4m.writeRes(mod, mS, mD, pr)
    # last journal action
    dre4m.jrnlst!(pr, jrnl)
    #
    return mod, mS, mD, pr
end


if abspath(PROGRAM_FILE) == @__FILE__
  m = main()
end
