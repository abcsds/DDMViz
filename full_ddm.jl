using GLMakie, Colors, Distributions

# Array containing the steps of a single DDM process
x = Observable(Vector{Float64}())
t = Observable(Vector{Float64}())

# Arrays containing the Positive and Negative response times
p_pos = Observable(Vector{Float64}())
p_neg = Observable(Vector{Float64}())

# Update drift diffusion model
function update_ddm()
    x[] = [0.0]
    tn = 0.000
    while true
        tn += 0.001
        x_new = x[][end] + rand(Normal(δ[], σ[]))
        push!(x[], x_new)
        if abs(x_new) >= α[]
            break
        end
    end
    rt = tn + τ[]
    if x[][end] >= α[]
        push!(p_pos[], rt)
    else
        push!(p_neg[], rt)
    end
    t[] = [range(τ[], rt, length=length(x[]));]
    notify(x)
    notify(p_neg)
    notify(p_pos)
end

# Figure
fig = Figure();

# SliderGrid
sg = SliderGrid(
    fig[1:2, 1:8], 
    (label="Drift Rate", range=-1.0:0.001:1.0, format="{:.3f}", startvalue=0.005),
    (label="Decision Bound", range=0.1:0.001:2.0, format="{:.1f}", startvalue=1.0),
    (label="Non-Decision Time", range=0.0:0.001:1.0, format="{:.1f}", startvalue=0.3),
    (label="Stochastic Noise", range=0.0:0.001:1.0, format="{:.1f}", startvalue=0.1),
    (label="Maximum Time", range=1:0.1:10, format="{:.1f}", startvalue=1)
)

# Observables
δ, α, τ, σ, max_t = [s.value for s in sg.sliders]

n_α = lift(α) do α
    -α
end

# Buttons
new_btn = Button(fig[1, 9], label="New trial")
mtp_btn = Button(fig[1, 10], label="50 new trials")
rst_btn = Button(fig[2, 9:10], label="Reset axes")

on(new_btn.clicks) do n
    update_ddm()
end

on(mtp_btn.clicks) do n
    for i in 1:50
        update_ddm()
    end
end

# Middle Axis
ax_middle = Axis(fig[4, 1:10], xlabel="Time", ylabel="Decision Variable", title="Drift Diffusion Model")
line_middle = lines!(ax_middle, t, x, color=:black)
line_bound_pos = hlines!(ax_middle, α, color=:teal, linestyle=:dash)
line_bound_neg = hlines!(ax_middle, n_α, color=:coral, linestyle=:dash)
line_non_decision_time = vlines!(ax_middle, τ, color=:black, linestyle=:dash)

# Top Axis
ax_top = Axis(fig[3, 1:10], xlabel="Time", ylabel="Probability")
hist_top = hist!(ax_top, p_pos, bins=range(0.0, max_t[], length=100), color=:teal)
ylims!(0, 50)
hidespines!(ax_top)
hidexdecorations!(ax_top)

# Bottom Axis
ax_bottom = Axis(fig[5, 1:10], xlabel="Time", ylabel="Probability")
hist_bottom = hist!(ax_bottom, p_neg, bins=range(0.0, max_t[], length=100), color=:coral)
ylims!(0, 50)
hidespines!(ax_bottom)
hidexdecorations!(ax_bottom)
ax_bottom.yreversed = true
linkyaxes!(ax_top, ax_bottom)

lift(α) do α
    reset_limits!(ax_middle)
end

on(max_t) do _
    # reset_limits!(ax_middle)
    reset_limits!(ax_top)
    reset_limits!(ax_bottom)
end

on(rst_btn.clicks) do n
    autolimits!(ax_top)
    autolimits!(ax_bottom)
end

# Link axes
linkxaxes!(ax_middle, ax_top, ax_bottom)

# Show the figure
display(fig)