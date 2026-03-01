# Running with just Julia Installed
In your CLI and in this project's root directory, run:
```bash
julia --project=.
```
This gets you a Julia REPL with the project activated in the current folder.
Then:
1. Press the `]` key to activate `Pkg` mode. The command line should now display `Pkg>` in blue text.
2. Run `instantiate`
3. let it do its thing and install all dependencies
4. Press backspace to leave `Pkg` mode back to the Julia REPL. The command line should now display `Julia>` in green text.

Then, in the REPL, run:
```julia
include("run-simulation.jl")
```
Which will run all 270 simulations.
SA and BGA will both complete in under 10 seconds, but the improved BGA will spend roughly an hour on problem 2 and half an hour on problem 3.

# Running without Julia installed
A Google Colab link has been put in the assignment submission report.