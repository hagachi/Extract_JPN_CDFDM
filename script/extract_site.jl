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
function ncea_site(ncpath, tmppath, dataname)
    ncnames = readdir(ncpath)
    ncnames = [nc for nc in ncnames if occursin(dataname, nc) && !occursin(".tar", nc)]
    # @showprogress for ncname in ncnames
    for ncname in ncnames
        origin_path = joinpath(ncpath, ncname)
        subset_name = joinpath(tmppath, "tmp_"*ncname)
        if Sys.iswindows()
            cmd_extract = `ncra -Y ncea -d lat,$latmin,$latmax -d lon,$lonmin,$lonmax $origin_path $subset_name`
            # See this thread https://sourceforge.net/p/nco/discussion/9830/thread/e8b45a9cdb/
        else
            cmd_extract = `ncea -d lat,$latmin,$latmax -d lon,$lonmin,$lonmax $origin_path $subset_name`
        end
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
function ncrcat_times(tmppath, dataname, sitename, outputpath)
    ncnames = readdir(tmppath)
    ncnames = [joinpath(tmppath, nc) for nc in ncnames if occursin(dataname, nc)]
    output_name = joinpath(outputpath, sitename * "_" * dataname * "_2015-2100.nc")
    if Sys.iswindows()
        cmd_merge = `ncra -Y ncrcat -h $ncnames $output_name`
    else
        cmd_merge = `ncrcat -h $ncnames $output_name`
    end
    run(cmd_merge)
end



# Main --------------------------------------
# Parse region settings --------------------------
settings = JSON.parsefile(joinpath(dirname(@__FILE__), "setup_sado.json")) # Modify here!!!!!!!!
# settings = JSON.parsefile(joinpath(@__DIR__, "script", "setup_sado.json")) # FOR DEBUGGING ONLY
sitename = settings["siteinfo"]["site_name"]
lonmin = settings["siteinfo"]["lonmin"]
lonmax = settings["siteinfo"]["lonmax"]
latmin = settings["siteinfo"]["latmin"]
latmax = settings["siteinfo"]["latmax"]


# Initialize path ---------------------------
rootpath = settings["path"]["root_path"]
datapath = joinpath(rootpath, "data")
tmppathlocal = joinpath(settings["path"]["tmppath_local"], "tmp_" * sitename * "_" * settings["path"]["date"])
if !isdir(tmppathlocal)
    mkpath(tmppathlocal)
end
scriptpath = joinpath(rootpath, "script")
outputpath = joinpath(rootpath, "output", sitename * "_" * settings["path"]["date"])
if !isdir(outputpath)
    mkpath(outputpath)
end
outputpathlocal = joinpath(settings["path"]["tmppath_local"], "tmp_" * sitename * "_" * settings["path"]["date"], "output")
if !isdir(outputpathlocal)
    mkpath(outputpathlocal)
end


# Get climate variable names and set GCM / scenario names
vars = [d for d in readdir(datapath) if isdir(joinpath(datapath, d))]
gcms = ["ACCESS-CM2", "IPSL-CM6A-LR", "MIROC6", "MPI-ESM1-2-HR", "MRI-ESM2-0"]
scenarios = ["historical", "ssp126", "ssp245", "ssp585"]
ensemble = "r1i1p1f1"


for var in vars
    println("Processing " * var * "...")
    for gcm in gcms
        println("  GCM == " * gcm)
        for scenario in scenarios
            println("    Scenario == " * scenario)
            ncpath = joinpath(datapath, var, "day", gcm, scenario, ensemble)
            tmppath = joinpath(tmppathlocal, var, "day", gcm, scenario, ensemble) # tmp dir for splitted data
            if isdir(tmppath)
                rm(tmppath, recursive = true)
                mkpath(tmppath)
            else
                mkpath(tmppath)
            end
            dataname = var*"_day_"*gcm*"_"*scenario*"_"*ensemble
            # Extract a subregion from jpncdfdm
            ncea_site(ncpath, tmppath, dataname)
            ncrcat_times(tmppath, dataname, sitename, outputpathlocal)
        end
    end
end

# # FOR DEBUGGING ONLY ----------------------------------
# # Read NetCDF file -------------------------
# data_name = "pr_day_ACCESS-CM2_ssp126_r1i1p1f1"
# data_path = joinpath(datapath, data_name)
# tmp_path = joinpath(data_path, "tmp_" * sitename) # tmp dir for splitted data
# if !isdir(tmp_path) 
#     mkdir(tmp_path)
# end

# # Extract a subregion from jpncdfdm
# ncea_site(data_path, tmp_path, data_name)
# ncrcat_times(tmp_path, data_name, sitename, outputpath)

