# Acquire and cache GSHHG 2.3.7 land/ocean polygons from the NOAA archive.
# Run from repository root. Optional argument: f, h, i, l, c.
args <- commandArgs(trailingOnly=TRUE)
resolution <- if(length(args)) args[1] else "f"
if(!resolution %in% c("f","h","i","l","c")) stop("Invalid resolution.")
folder <- file.path("raw/reference/gshhg/2.3.7",resolution)
dir.create(folder,recursive=TRUE,showWarnings=FALSE)
base <- paste0("https://www.ncei.noaa.gov/data/oceans/archive/arc0234/0304143/1.1/data/0-data/GSHHS_shp/",resolution,"/")
stem <- paste0("GSHHS_",resolution,"_L1")
files <- paste0(stem,c(".shp",".shx",".dbf",".prj"))
options(timeout=max(600,getOption("timeout")))
for (name in files) {
  dest <- file.path(folder,name)
  if(file.exists(dest) && file.info(dest)$size>0) next
  tmp <- paste0(dest,".part")
  message("Downloading ",name)
  status <- utils::download.file(paste0(base,name),tmp,mode="wb")
  if(status!=0 || !file.exists(tmp) || file.info(tmp)$size<=0) stop("Download failed: ",name)
  if(!file.rename(tmp,dest)) stop("Cannot finalize: ",dest)
}
x <- sf::st_read(file.path(folder,paste0(stem,".shp")),quiet=TRUE)
if(!nrow(x) || is.na(sf::st_crs(x)) || !all(as.character(sf::st_geometry_type(x)) %in% c("POLYGON","MULTIPOLYGON"))) stop("Invalid shoreline layer.")
paths <- file.path(folder,files)
utils::write.csv(data.frame(version="2.3.7",resolution=resolution,level=1,
 file=files,url=paste0(base,files),bytes=file.info(paths)$size,
 md5=unname(tools::md5sum(paths)),checked_utc=format(Sys.time(),tz="UTC",usetz=TRUE)),
 file.path(folder,"manifest.csv"),row.names=FALSE)
message("Reference ready: ",folder)
