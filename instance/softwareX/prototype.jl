using stre3am
using JuMP
using HiGHS

# to do:
# put the embodied emissions of lc3
# put the cost of lc3

pr = prJrnl(@__FILE__)
setJrnlTag!(pr, "_DEBUG")
jrnlst!(pr, jrnlMode(0))

# input file
f = "./f0.xlsx"

# internal data structure
p = read_params(f);
@info "Data has been loaded.\n"

# sets
s = sets(p)
@info "Sets have been created.\n"


# model
@info "Creating model.\n"
m = createBlockMod(s.P, s.L, p, s)

# linking constraints
attachPeriodBlock(m, p, s)
attachLocationBlock(m, p, s)

# objective function
attachFullObjectiveBlock(m, p, s)

set_optimizer(m, HiGHS.Optimizer)

# (optional) load a discrete state (upper bound)
load_discrete_state(m, p, s)

# call solver
@info "Solve.\n"
optimize!(m)

# generate result files
postprocess_d(m, p, s, f)

