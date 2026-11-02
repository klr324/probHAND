##########################################################################
##########################################################################
## Script Name: createCountyShapefiles.R
## Purpose of Script: A script to create a series of shapefiles, for CONUS states 
## and counties. Effectively, it extracts the counties for a state given a state
## name. This was specifically written to create masks to summarize the GridMet 
## and MACA climate data for the MARISA Climate Outlook PDFs.
##
## Special Requirements: spatial US state and county boundaries 
##
## Author: Kelsey Ruckert
## Email: klr324@psu.edu
## Date Created: 10/25/2021
##
## Last Moddified By: Author
## Editors Email: Author
## Date Last Edited: 10/27/2021 - automate output/input paths
##
## Copyright (c) 2021 The Pennsylvania State University
##
##########################################################################
##########################################################################

# Load the package
library(terra)
library(stringr)

# Set file locations ------------------------------------------------------
# HUC12 polygons for PA
huc_file = "~/Documents/FlashFlood/Shapefiles/PA_HUC_12/HUC12.shp"

# NHDplus stream reach
NHDplus_file = "~/Downloads/PA_probHAND_data/NHDPlusMA/NHDPlus02/NHDSnapshot/Hydrography/NHDFlowline.shp"

# 1m resolution LIDAR for Lycoming County, PA
DEM_file = "~/Downloads/PA_probHAND_data/USGS_QL2_LiDAR_LycomingCnty_PA_2017/Lycoming_Bare_Earth_DEM_mosaic/Lycoming_DEM.img"

# LULC raster for PA
LULC_file = "~/Downloads/PA_probHAND_data/pa_lulc_2017_2022-Edition/pa_lulc_2017_2022-Edition.tif"

# - -----------------------------------------------------------------------
## STEP 1: Create individual watershed files

# Set output location for the watershed files
shp_dir = "~/Downloads/PA_probHAND_data/Lower_West_Branch_Susquehanna/Watershed/"

# Read the shapefile
huc12 <- vect(huc_file)

# Define your target CRS (EPSG:26918 - NAD83 / UTM zone 18N)
epsg_crs <- "EPSG:26918" 

# Reproject the shapefile
huc12_proj <- project(huc12, epsg_crs)

# HUCs surrounding Lyoming and Loyalsock
huc12_name = c("020502060507", "020502060605", "020502060505", "020502060503", 
               "020502060504", "020502060506", "020502060508", "020502060204", 
               "020502060203", "020502060202", "020502060201", "020502060205", 
               "020502050504", "020502060103", "020502060207", "020502060208", 
               "020502060604", "020502060509", "020502060206") # "020502060509", "020502060206"

# Use the last four numbers for the naming system
huc12_sub4 = str_sub(huc12_name, -4, -1)

# Extract and save each huc12 in the area surrounding "020502060509" and "020502060206"
ids = match(huc12_name, huc12$huc12)
for(i in 1:length(ids)){
  sub = huc12_proj[ids[i], ]
  
  if(huc12_name[i] == "020502050504"){
    name = paste0(shp_dir, "PINE_", huc12_sub4[i], ".shp")
  } else {
    name = paste0(shp_dir, "LWBS_", huc12_sub4[i], ".shp")
  }
  
  # Write your SpatVector object to a shapefile
  writeVector(sub, name, overwrite = TRUE)
}

# - -----------------------------------------------------------------------
## STEP 2: Subset NHDplus stream reaches for each huc12

# Set output location for the watershed files
nhd_dir = "~/Downloads/PA_probHAND_data/Lower_West_Branch_Susquehanna/Stream_Polylines/NHD/"

# Read the shapefile
nhd_vec <- vect(NHDplus_file)

# Reproject the shapefile to (EPSG:26918 - NAD83 / UTM zone 18N)
nhd_proj <- project(nhd_vec, epsg_crs)

# Certain attributes are hard coded in the probHAND model.
# Create a Code attribute which is now called COMID
# Convert Length from KM to meters
nhd_proj$Code = nhd_proj$COMID
nhd_proj$Length = nhd_proj$LENGTHKM * 1000

# Extract and save each huc12 in the area surrounding "020502060509" and "020502060206"
for(i in 1:length(ids)){
  sub = huc12_proj[ids[i], ]
  
  # Crop the nhd layer to the huc12 watershed boundary
  wsh_nhd = crop(nhd_proj, sub)
  
  if(huc12_name[i] == "020502050504"){
    name = paste0(nhd_dir, "PINE_", huc12_sub4[i], "_NHD.shp")
    
    wsh_nhd$Huc8 = "Pine"
    wsh_nhd$Code_name = paste0("PINE_", huc12_sub4[i])
    
  } else {
    name = paste0(nhd_dir, "LWBS_", huc12_sub4[i], "_NHD.shp")
    
    wsh_nhd$Huc8 = "Lower West Branch Susquehanna"
    wsh_nhd$Code_name = paste0("LWBS_", huc12_sub4[i])
    
  }
  
  # Write your SpatVector object to a shapefile
  writeVector(wsh_nhd, name, overwrite = TRUE)
}

# - -----------------------------------------------------------------------
## STEP 3: Subset the DEM for each huc12

# Set output location for the DEM files
dem_dir = "~/Downloads/PA_probHAND_data/Lower_West_Branch_Susquehanna/Buffered_DEM/"

# Read in the DEM. The DEM is already in (EPSG:26918 - NAD83 / UTM zone 18N)
DEM_rast <- rast(DEM_file)

# Extract and save each huc12 in the area surrounding "020502060509" and "020502060206"
for(i in 1:length(ids)){
  sub = huc12_proj[ids[i], ]
  
  # Crop the nhd layer to the huc12 watershed boundary
  wsh_dem = crop(DEM_rast, sub, mask = TRUE)
  
  if(huc12_name[i] == "020502050504"){
    name = paste0(dem_dir, "PINE_", huc12_sub4[i], ".tif")
  } else {
    name = paste0(dem_dir, "LWBS_", huc12_sub4[i], ".tif")
  }
  
  # Write your SpatRaster object to a raster file
  writeRaster(wsh_dem, name, overwrite = TRUE)
}

# - -----------------------------------------------------------------------
## STEP 4: Subset the LULC for each huc12

# Set output location for the DEM files
lulc_dir = "~/Downloads/PA_probHAND_data/Lower_West_Branch_Susquehanna/LULC/"

# Read in the LULC
lulc_rast <- rast(LULC_file)

# The LULC is too large to reproject. Instead project the huc12 file first
#  to USA_Contiguous_Albers_Equal_Area_Conic_USGS_version.
lulc_crs <- "ESRI:102039"
huc12_proj_lulc <- project(huc12_proj, lulc_crs)

# Extract and save each huc12 in the area surrounding "020502060509" and "020502060206"
for(i in 1:length(ids)){
  sub = huc12_proj_lulc[ids[i], ]
  
  # Crop the lulc layer to the huc12 watershed boundary
  wsh_lulc = crop(lulc_rast, sub, mask = TRUE)
  
  # Reproject the subset lulc to (EPSG:26918 - NAD83 / UTM zone 18N)
  wsh_lulc_proj <- project(wsh_lulc, epsg_crs)
  
  if(huc12_name[i] == "020502050504"){
    name = paste0(lulc_dir, "PINE_", huc12_sub4[i], "_LC.tif")
  } else {
    name = paste0(lulc_dir, "LWBS_", huc12_sub4[i], "_LC.tif")
  }
  
  # Write your SpatRaster object to a raster file
  writeRaster(wsh_lulc_proj, name, overwrite = TRUE)
}
# - -----------------------------------------------------------------------

## STEP 2: Subset NHDplus stream reaches for each huc12

# Set output location for the watershed files
nhd_dir = "~/Downloads/PA_probHAND_data/Lower_West_Branch_Susquehanna/Stream_Polylines/NHD/"

nhd_vectors = list()
for(i in 1:length(ids)){
  
  if(huc12_name[i] == "020502050504"){
    name = paste0(nhd_dir, "PINE_", huc12_sub4[i], "_NHD.shp")
    
    # Read the shapefile
    nhd_vectors[[i]] <- vect(name)
    
  } else {
    name = paste0(nhd_dir, "LWBS_", huc12_sub4[i], "_NHD.shp")
    
    # Read the shapefile
    nhd_vectors[[i]] <- vect(name)
  }
}

combined_vector <- vect(nhd_vectors)

# Write your SpatVector object to a shapefile
name = paste0(nhd_dir, "Combined_NHD.shp")
writeVector(combined_vector, name, overwrite = TRUE)

# 1. Get all coordinates
coords <- geom(combined_vector)

# 2. Get the number of vertices per polyline
lengths <- rle(coords[, "geom"])$lengths

# 3. Calculate the exact middle index for each line
end_indices <- cumsum(lengths)
start_indices <- end_indices - lengths + 1
mid_indices <- start_indices + floor((lengths - 1) / 2)

# 4. Pull the mid-point x (Long) and y (Lat) columns
mid_coords <- coords[mid_indices, c("x", "y")]
last_coords <- coords[end_indices, c("x", "y")]

# 5. Extract the ID column from the original vector 
# (Replace "ID" with your exact column name)
original_ids <- data.frame(Code = combined_vector$Code, Code_name = combined_vector$Code_name)

# 5. Convert back to a Point SpatVector with the IDs attached
mid_points_vect <- vect(mid_coords, atts = original_ids, crs = crs(combined_vector))
last_points_vect <- vect(last_coords, atts = original_ids, crs = crs(combined_vector))

# Write your SpatVector object to a shapefile
name = paste0(nhd_dir, "End_NHD.shp")
writeVector(last_points_vect, name, overwrite = TRUE)

name = paste0(nhd_dir, "mid_NHD.shp")
writeVector(mid_points_vect, name, overwrite = TRUE)

# 5. Convert back to a Point SpatVector with the IDs attached (Only the first 250 points will be processed.)
last_points_vect_1 <- vect(last_coords[1:250, ], atts = original_ids[1:250, ], crs = crs(combined_vector))
last_points_vect_2 <- vect(last_coords[251:500, ], atts = original_ids[251:500, ], crs = crs(combined_vector))
last_points_vect_3 <- vect(last_coords[501:dim(last_coords)[1], ], atts = original_ids[501:dim(last_coords)[1], ], 
                         crs = crs(combined_vector))

# EPSG:5070 - NAD83 / Conus Albers - Projected
streamgrid_crs <- "EPSG:5070"
last_points_vect_1 <- project(last_points_vect_1, streamgrid_crs)
last_points_vect_2 <- project(last_points_vect_2, streamgrid_crs)
last_points_vect_3 <- project(last_points_vect_3, streamgrid_crs)

# Write your SpatVector object to a shapefile
writeVector(last_points_vect_1, paste0(nhd_dir, "End_NHD_1.shp"), overwrite = TRUE)
writeVector(last_points_vect_2, paste0(nhd_dir, "End_NHD_2.shp"), overwrite = TRUE)
writeVector(last_points_vect_3, paste0(nhd_dir, "End_NHD_3.shp"), overwrite = TRUE)


# - -----------------------------------------------------------------------

# Merge the huc12 code to stream_stats
stream_stats = read.csv("~/Downloads/PA_probHAND_data/Lower_West_Branch_Susquehanna/Stream_Stats/Stream_Stats_beg.csv", 
                        header=TRUE)

# Find the unqiue names
unq_names = unique(stream_stats$Name)

ind_match = match(unq_names, original_ids$Code)

sub_ids = original_ids[ind_match, ]

ind_hucs = match(stream_stats$Name, sub_ids$Code)

stream_stats$Huc12 = sub_ids$Code_name[ind_hucs]

write.csv(stream_stats, 
          "~/Downloads/PA_probHAND_data/Lower_West_Branch_Susquehanna/Stream_Stats/Stream_Stats_NHD.csv", 
          row.names = FALSE, na = "")
