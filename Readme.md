# Preprocessing jpn_cdfdm data for local climate change impact analysis

## Aim
- Extract specific location's climate data from netCDF files

## Data source
- https://www.nies.go.jp/doi/10.17595/20210501.001.html


## Usage
### 1. Set your research site info
Create ./script/setup_foo.json as follows
```json
{
    "path": {
        "root_path": "/path/to/root/dir",
        "date": "yyyy-mm-dd"
    },
    "siteinfo": {
        "site_name": "xxxx",
        "lonmin": xxxx, 
        "lonmax": xxxx,
        "latmin": xxxx,
        "latmax": xxxx
    }
}
```

### 2. Run julia script
```bash
julia extract_site.jl
```

### 3. Check output files
Output files will be appeared in ./output/yyyy-mm-dd/
