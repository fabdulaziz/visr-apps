sessionInfo()
while (is.null(try(remove.packages("BiocInstaller"), silent=T))) {}
source("visrutils.R")
dir.create(visr.getHomeLibPath(), recursive=T)
.libPaths(c(visr.getHomeLibPath(), .libPaths()))
while (is.null(try(remove.packages("BiocInstaller"), silent=T))) {}
source("http://bioconductor.org/biocLite.R")
try(biocValid(fix=T))
try(visr.biocLite("flowMerge"))
try(visr.biocLite("flowClust"))
try(visr.biocLite("flowMeans"))
try(visr.biocLite("SamSPECTRAL"))
try(visr.library("gplots"))
try(visr.library("RColorBrewer"))
try(visr.library("functional"))
try(visr.library("ggplot2"))
try(visr.library("scales"))
try(visr.library("grid"))
try(visr.biocLite("edgeR"))
try(visr.biocLite("DESeq"))
try(visr.biocLite("RUVSeq"))
try(visr.biocLite("DESeq2"))
try(visr.biocLite("BiocParallel"))
try(visr.biocLite("S4Vectors"))
try(visr.biocLite("org.Mm.eg.db"))
try(visr.biocLite("graphite"))
try(visr.library("car"))
try(visr.library("Rcpp"))
try(visr.library("igraph"))
try(visr.biocLite("RBGL"))
try(visr.library("gRbase"))
try(visr.biocLite("qpgraph"))
try(visr.biocLite("KEGGgraph"))
try(visr.library("corpcor"))
try(visr.library("rrcov"))
try(visr.libraryURL("timeClip","http://romualdi.bio.unipd.it/wp-uploads/2014/11/timeClip_0.99.3.tar.gz"))
try(visr.library("graph"))
try(visr.library("nlme"))
try(biocValid(fix=T))
