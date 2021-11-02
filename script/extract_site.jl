# Title: extract_site.jl program
# Author: @hagachi
# Date: 2021.11.02
# Description:
#   Extract climate data of certain study site from jpncdfdm


# Load libraries --------------------
using JSON
using ProgressMeter


# Define functions ------------------
"""
ncea_site fuction
    description: Extract specific site from nc file within the data_path
    input: 
        data_path: path to the directory contains nc files to be extracted
        tmp_path: temporary dir for cropped data
        data_name: base name of these nc files
    output:
        nothing
"""
function ncea_site(data_path, tmp_path, data_name)
    ncnames = readdir(data_path)
    ncnames = [nc for nc in ncnames if occursin(data_name, nc)]
    @showprogress for ncname in ncnames
        origin_path = joinpath(data_path, ncname)
        subset_name = joinpath(tmp_path, "tmp_"*ncname)
        cmd_extract = `ncea -d lat,$latmin,$latmax -d lon,$lonmin,$lonmax $origin_path $subset_name`
        run(cmd_extract)
    end
end


"""
ncrcat_times fuction
    description: concatenate nc files for time dimention
    input: 
        tmp_dir: temporary dir for cropped data
        data_name: base name of these nc files
        site_name: site name
        output_dir: output directory
    output:
        nothing
"""
function ncrcat_times(tmp_dir, data_name, site_name, output_dir)
    ncnames = readdir(tmp_dir)
    ncnames = [joinpath(tmp_dir, nc) for nc in ncnames if occursin(data_name, nc)]
    output_name = joinpath(output_dir, site_name * "_" * data_name * "_2015-2100.nc")
    cmd_merge = `ncrcat -h $ncnames $output_name`
    run(cmd_merge)
end



# Main --------------------------------------
# Settings
# settings = JSON.parsefile(joinpath(dirname(@__FILE__), "setup_sado.json"))
settings = JSON.parsefile(joinpath(@__DIR__, "script", "setup_sado.json"))
# Initialize path
root_path = settings["path"]["root_path"]
data_path = joinpath(root_path, "data")
script_path = joinpath(root_path, "script")
output_path = joinpath(root_path, "output", settings["path"]["date"])
if !isdir(output_path)
    mkdir(output_path)
end


# Parse region settings --------------------------
site_name = settings["siteinfo"]["site_name"]
lonmin = settings["siteinfo"]["lonmin"]
lonmax = settings["siteinfo"]["lonmax"]
latmin = settings["siteinfo"]["latmin"]
latmax = settings["siteinfo"]["latmax"]


# FOR DEBUGGING ONLY ----------------------------------
# Read NetCDF file -------------------------
data_name = "pr_day_ACCESS-CM2_ssp126_r1i1p1f1"
data_path = joinpath(data_path, data_name)
tmp_path = joinpath(data_path, "tmp_" * site_name) # tmp dir for splitted data
if !isdir(tmp_path) 
    mkdir(tmp_path)
end

# Extract a subregion from jpncdfdm
ncea_site(data_path, tmp_path, data_name)
ncrcat_times(tmp_path, data_name, site_name, output_path)

