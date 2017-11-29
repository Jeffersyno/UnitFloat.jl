push!(LOAD_PATH, "../src")

using Documenter, UnitFloat

makedocs(
     # options
     modules = [UnitFloat],

     format = :html,
     sitename = "UnitFloat",
     pages = [
              "UnitFloat" => "index.md",
              "API Overview" => "functions.md"
             ]
)
