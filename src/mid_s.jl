# vim: tabstop=2 shiftwidth=2 expandtab colorcolumn=80
#############################################################################
#  Copyright 2022, David Thierry, and contributors
#  This Source Code Form is subject to the terms of the MIT
#  License.
#############################################################################

module mid_s
  include("./bark/bark.jl")
  include("./matrix/mat_struct2.jl")
  include("./gestalt/props.jl")
  #include("./gestalt/retrof.jl")
  include("./gestalt/modKern2.jl")
  include("./pre/preprocess.jl")
  include("./coef/coef_custom2.jl")
  include("./mods/m4-5_modular.jl")
  include("./post/postprocess2.jl")
  version = VersionNumber(0, 4, 5)
  @info "RAIDS $(version) by DT@2022"
end
