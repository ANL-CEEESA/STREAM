

include("gen_data.jl")
include("prototype_sweep.jl")


n_points = 1

# Combination	Variable 1	Variable 2	Variable 3
# 1	+	+	+
# 2	+	+	-
# 3	+	-	+
# 4	+	-	-
# 5	-	+	+
# 6	-	+	-
# 7	-	-	+
# 8	-	-	-
dem_inc_0 = 0/100
dem_inc_1 = 2/100

elec_supply_inc_0 = 2.5/100
elec_supply_inc_1 = 5/100

ccs_ccf_0 = 1.0
ccs_ccf_1 = 2.0



case_study = Vector{Tuple{Float64, Float64, Float64, Float64, String}}(undef, n_points)


case_study[1] = (dem_inc_1, elec_supply_inc_0, ccs_ccf_0, 0.5, "f_4")


# function generate_case_study(co2_reduction, fout_name)
# function generate_case_study(demand_inc, elec_supply_inc, ccs_ccf, co2_reduction, fout_name)
for i in 1:n_points
    generate_data(case_study[i]...)
end

# #function run_case_study(input_file)

for i in 1:n_points
    global m = run_case_study(case_study[i][5])
end


