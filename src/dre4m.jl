

module dre4m

include("./dre4m_d/dre4m_d.jl")
using .dre4m_d 
export read_params, sets, createBlockMod, attachPeriodBlock, attachLocationBlock, attachFullObjectiveBlock, load_discrete_state, save_discrete_state, postprocess_d
include("./dre4m_c/dre4m_c.jl")


end
