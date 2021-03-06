#setwd('/Users/hyounesy/Research/svn/Projects/GeneCalc/visr/srcR')

source("visrutils.R")
source("frequency.R")
visr.applyParameters()

if (FALSE) {
  ### FOR TESTING ONLY - apply variables manually

  # Joseph's Debug:
  # source("D:/Joseph/visrseq/visr/srcR/frequency.R")
  # # source("C:/Users/Joseph/Documents/visrseq/visr/srcR/frequency.R")
  # # source("B:/Diverses/Dropbox/Uni/BA/VisRSeq/visr/srcRfrequency.R")
  # visr.param.directory <-"D:/Joseph/visrseq/output/k-means_2016-3-29(16.57)[20]_iris"
  # # visr.param.directory <- "B:/Diverses/Dropbox/Uni/BA/VisRSeq/output/LinSca_Lin-Pos-Neg_edgeR_115-9-22(6.43)[550]"
  # # visr.param.directory <- "C:/Users/Joseph/Documents/visrseq/output/LinSca_Lin-Pos-Neg_edgeR_115-9-22(6.43)[550]"
  # # visr.param.directory <- "C:/Users/Joseph/Documents/visrseq/output/test-method"
  # # visr.param.directory <- "C:/Users/Joseph/Documents/visrseq/output/k-means_2016-1-26(18.14)[6]_iris-sub"
  # visr.param.mdsColumnIndex <- 1
  # visr.param.summaryUpDown <- "sum_"
  # visr.param.recalc <- T
  # visr.param.mdsMethod <- "manhattan"
  # visr.output.summaryMDS <- "mds_"
  ###

  # Hamid's DEBUG:
  #visr.param.directory1 <- "/Users/hyounesy/Research/Data/VisRseq/Runs/DESeq_EdgeR_LinSca"
  .libPaths(c("/Users/hyounesy/VisRseq/RLibs", .libPaths()))
  source("visrutils.R")
  source("frequency.R")
  visr.param.directory1<-"/Users/hyounesy/Research/Data/edgeR_2016-3-30(18.6)[500]_mydata_5spc"
  #visr.param.directory1<-"/Users/hyounesy/Research/Data/PSA/edgeR_2016-4-14(7.51)[1000]_Jafar_SNwt_ESC_vs_SNcDKO_ESC"
  #visr.param.directory1<-"/Users/hyounesy/Research/svn/Projects/GeneCalc/output/edgeR[4000]_GSE49712_SEQC_Count"

  visr.param.mdsColumnIndex<-1
  visr.param.summaryUpDown<-"sum_"
  visr.param.recalc<-TRUE
  visr.param.mdsMethod<-"manhattan"
  visr.output.summaryMDS<-"mds_"
}


path <- visr.param.directory1

visr.print("loading the index files")
pathInput               <- paste(path, "/input.txt", sep = "")
pathIndex               <- paste(path, "/index.txt", sep="")
pathParamInfo           <- paste(path, "/paramInfo.txt", sep="")
pathAllRunsMatrixRData  <- paste(path, "/allRunsMatrix.RData", sep="")
pathAllRunsMatrixTxt    <- paste(path, "/allRunsMatrix.txt", sep="")
pathDistanceMatrix      <- paste(path, "/distanceMatrix.txt" ,sep="")
pathDistanceMatrixRData <- paste(path, "/distanceMatrix.RData" ,sep="")
pathImpact              <- paste(path, "/impact.txt", sep="")
pathFrequency           <- paste(path, "/frequency.txt",sep = "")
pathStableGenes         <- paste(path, "/stableGenes.txt",sep = "")

allRunsMatrix <- NULL
distanceMatrix <- NULL

loadAllRunsMatrixIfNull<-function() {
  if (is.null(allRunsMatrix)) {
    if (file.exists(pathAllRunsMatrixRData)) {
      # first try to load the binary version
      visr.print(paste("loading", pathAllRunsMatrixRData))
      load(file = pathAllRunsMatrixRData, .GlobalEnv)
    }
  }

  if (is.null(allRunsMatrix)) {
    # could not load the binary, try the txt one
    visr.print(paste("loading", pathAllRunsMatrixTxt))
    allRunsMatrix <<- read.table(pathAllRunsMatrixTxt, header=FALSE, sep="\t", check.names = F)
    # write the binary
    visr.print(paste("saving", pathAllRunsMatrixRData))
    save(allRunsMatrix, file = pathAllRunsMatrixRData)
  }
}

loadDistanceMatrixIfNull<-function() {
  if (is.null(distanceMatrix)) {
    if (file.exists(pathDistanceMatrixRData)) {
      # first try to load the binary version
      visr.print(paste("loading", pathDistanceMatrixRData))
      load(file = pathDistanceMatrixRData, .GlobalEnv)
    }
  }

  if (is.null(distanceMatrix)) {
    # could not load the binary, try the txt one
    visr.print(paste("loading", pathDistanceMatrix))
    distanceMatrix <<- read.table(pathDistanceMatrix, sep="\t", check.names = F)
    # write the binary
    visr.print(paste("saving", pathDistanceMatrixRData))
    save(distanceMatrix, file = pathDistanceMatrixRData)
  }
}


calculateMode=function(x){
	names(tail(sort(table(x)),1))
}

# whether to store the minimum distance from a runs with one parameter values to nearset run with a different parameter value
# It will be one column for each parameter
storeMinDistColumns <- FALSE

###############################################################################
# Setting paths and loading crucial index files
###############################################################################

visr.print("loading the index files")
inputTable <- read.table(pathInput, header=TRUE,sep="\t", check.names = F)
paramInfo  <- read.table(pathParamInfo, header=TRUE,sep = "\t", stringsAsFactors = FALSE, check.names = F)
indexTable <- read.table(pathIndex, header=TRUE, sep = "\t", check.names = F)

fileNames <- paste(path, "/runs/", (indexTable[,"ID"]), ".txt", sep="")
numRuns   <- length(fileNames)

for (name in names(inputTable)) {
	if (any(is.na(inputTable[,name])) || any(grep("NA", inputTable[,name])) ||  any(grep("NaN", inputTable[,name]))) {
		inputTable[,name] <- NULL
	}
}
visr.print("[DONE] loading the index files")

###############################################################################
# Calculate sum of up and down regulated genes for all Runs
###############################################################################
upColName   <- paste(visr.param.summaryUpDown, "up", sep = "")
downColName <- paste(visr.param.summaryUpDown, "down", sep = "")
upDown <- matrix(nrow=numRuns, ncol=2)
colnames(upDown) <- c(upColName, downColName)

# !(upColName %in% colnames(indexTable)) ||    # check if index table has the number of up-regulated genes for each run
# 	!(downColName %in% colnames(indexTable)) ||  # check if index table has the number of down-regulated genes for each run
if (visr.param.recalc || # force recalculating
    (!file.exists(pathAllRunsMatrixRData) && !file.exists(pathAllRunsMatrixTxt)))
{
  visr.print("Recreate the matrix containing the up/down regulation state for all runs")
  # Recreate the matrix containing the up/down regulation state for all runs
  # TODO slow (not R enough?)
  if (numRuns > 0) {
    for (i in 1:numRuns) {
      visr.print(paste("reading",fileNames[i]))
      tt <- read.table(fileNames[i], header=TRUE,sep="\t", check.names = F)

      upDown[i,1] <- sum(tt[,visr.param.mdsColumnIndex] > 0.1)
      upDown[i,2] <- sum(tt[,visr.param.mdsColumnIndex] < -0.1)

      if (i == 1) {
      	allRunsMatrix <- matrix(nrow = numRuns, ncol=nrow(tt))
      }
      allRunsMatrix[i,] <- tt[, visr.param.mdsColumnIndex]
    }
  }
  #write.table(allRunsMatrix, file=paste(path,"/allRunsMatrix.txt",sep=""),col.names = F, row.names = F, sep = "\t")
  save(allRunsMatrix, file = pathAllRunsMatrixRData)

  indexTable[[upColName]] <- upDown[,1]
  indexTable[[downColName]] <- upDown[,2]

  # writing the table, in case of a crash, etc...
  write.table(indexTable, file=pathIndex, row.names = FALSE, col.names = TRUE, sep = "\t")

  visr.print("[DONE] Recreate the matrix containing the up/down regulation state for all runs")

} else {
	#optimization: delay loading this until needed:
  #allRunsMatrix <- loadAllRunsMatrix(path)

# 	upDown[,1] <- indexTable[[upColName]]
# 	upDown[,2] <- indexTable[[downColName]]
}

# Add missing up/down regulated meta info to the parameter information file
if(! upColName %in% paramInfo$label) {
	paramInfo <- rbind(paramInfo, c(upColName, upColName, "output_generated"))
}
if(! downColName %in% paramInfo$label) {
	paramInfo <- rbind(paramInfo, c(downColName, downColName, "output_generated"))
}


# plot(upDown)

###############################################################################
# Calculate Distance matrix (distance between runs)
###############################################################################
if ((!file.exists(pathDistanceMatrixRData) && !file.exists(pathDistanceMatrix)) || # whether the distance matrix was already computed and saved
    visr.param.recalc) # forcing the recalculation
{
  loadAllRunsMatrixIfNull()
  visr.print("recompute the distance matrix")
  # recompute the distance matrix
	if (visr.param.mdsMethod == "hamming")
  { # hamming ditance not supported in dist() function. need to calculate manually
		n <- nrow(allRunsMatrix)
		distanceMatrix <- matrix(nrow=n, ncol=n)
		for(i in seq_len(n)) {
		  visr.print(paste("computing hamming dist for row ", i))
		  for(j in seq(i, n)) {
			  distanceMatrix[j, i] <- distanceMatrix[i, j] <- sum(allRunsMatrix[i,] != allRunsMatrix[j,])
			}
		}
	} else {
	  distanceMatrix <- as.matrix(dist(allRunsMatrix, method = visr.param.mdsMethod)) #  distances between the rows
		# save distanceMatrix to a file
		# write.table(distanceMatrix, file=pathDistanceMatrix, col.names = F, row.names = F, sep = "\t")
		visr.print(paste("saving", pathDistanceMatrixRData))
		save(distanceMatrix, file = pathDistanceMatrixRData)
	}
  visr.print("[DONE] recompute the distance matrix.")
} else {
  # load the existing distance matrix from file.
  # delay loading this until needed (performance optimization):
  #distanceMatrix <- read.table(pathDistanceMatrix, sep="\t", check.names = F)
}

###############################################################################
# perform MDS on the distance matrix and add it to the index table
###############################################################################
mdsDims <- 2
mdsColNames <- paste(visr.output.summaryMDS, "coord" , 1:mdsDims, sep = "")
c1ColName   <- paste(visr.output.summaryMDS, "coord1", sep = "")
c2ColName <- paste(visr.output.summaryMDS, "coord2", sep = "")
if ( !all(mdsColNames %in% colnames(indexTable)) || visr.param.recalc == TRUE) {
  visr.print("perform MDS on the distance matrix")
  loadDistanceMatrixIfNull()
	fit <- cmdscale(distanceMatrix, eig = TRUE, k = mdsDims) # k is the number of dim
	visr.output.summaryMDS <- fit$points[, c(1:mdsDims)] # If subscript out of bounds error: means most likely, that all columns of the input data were identical and therefore removed
	# colnames(visr.output.summaryMDS)<-c("coord1","coord2")

	for(i in 1:mdsDims) {
		indexTable[[mdsColNames[i]]] <- fit$points[,i]

		# Add missing mds_coordinate meta info to the parameter information file
		if(! (mdsColNames[i] %in% paramInfo$label) ) {
			paramInfo <- rbind(paramInfo, c(mdsColNames[i], mdsColNames[i], "output_generated"))
		}
	}
  visr.print("[Done] perform MDS on the distance matrix")
}

###############################################################################
# Calculate Parameters' significance/impact score
###############################################################################

if(visr.param.recalc ||
   !file.exists(pathImpact)) # whether the impact file exists already
{
  loadAllRunsMatrixIfNull()
  loadDistanceMatrixIfNull()
  visr.print("Calculate Parameters' significance/impact score")
  # find columns of the index table, that are input parameters with more than 1 value
  numlevels<-function(x) { length(levels(as.factor(x))) }
	coolParameters <- match(names(which(lapply(indexTable, numlevels) > 1)), paramInfo$label)
	coolParameters <- coolParameters[!is.na(coolParameters)]
	inputParams <- c()
	# visr.print( coolParameters)
	# TODO make this more R-like
	for (i in 1: length(coolParameters)) {
		if( !grepl("output", paramInfo$type[coolParameters[i]]) ) { # skip the output parameters
			inputParams <- c(inputParams, coolParameters[i])
		}
	}

  # data frame containing the significance/impact values per parameters
	sigFrame <- data.frame(row.names = paramInfo$label[inputParams]) #error row names contain missing values

	if(length(inputParams) > 0) {
		for (vp in 1: length(inputParams))
    { # iterate through input parameters to calculate impact score
			#paramName<-colnames(indexTable)[inputParams[vp]]
			paramName<-paramInfo$label[inputParams[vp]]
			visr.print(paste("processing", paramName))
			paramValues <- c()

			if (storeMinDistColumns) {
			  minDistColName <- paste("mindist(",paramName,")", sep = "")
			}

			# Binning for numerical parameters that have more than 10 values
			binned <- FALSE
			paramValues<-levels(as.factor(indexTable[, paramName]))
			numParamValues<-length(paramValues)
			if ( numParamValues > 10 &&
           (grepl("double", paramInfo$type[inputParams[vp]]) ||
            grepl("int", paramInfo$type[inputParams[vp]])) ) {
				binned <- TRUE
				bins <- tapply(indexTable[, paramName], cut(indexTable[, paramName], 10))
				paramValues <- levels(as.factor(bins))
				numParamValues <- length(paramValues)
			}

			sigV <- c()
			if (numParamValues > 1) {
				breakdown <- data.frame(row.names = paramValues)

				paramsDist<-matrix(0,nrow=numParamValues,ncol=numParamValues)

        # now compare each pair of parameter values and find the minimum distance between rows
				for (v1 in 1:(numParamValues)) {
					if(binned) {
						v1Rows <- which(bins == paramValues[v1]) # index of rows with their parameter value in paramValues[v1] bin
					}else {
						v1Rows <- which(indexTable[, paramName]==paramValues[v1]) # index of rows with their parameter value == paramValues[v1]
					}

					# Calculate the mode for each value of each input parameter
					vRuns = allRunsMatrix[v1Rows,]
					if(is.null(dim(vRuns))) {
            modes = data.frame(sapply(vRuns, calculateMode))
					} else {
            modes = data.frame(apply(vRuns, 2, calculateMode))
					}
					inputTable[,paste(paramName,paramValues[v1],sep = "-")] <- modes
					if (v1 >= numParamValues) {
            break# Only calculate impatct for numParamValues -1
					}

					for (v2 in (v1+1) : numParamValues) {
					  visr.print(paste("comparing", paramValues[v1], "to", paramValues[v2]))
						if(binned) {
						  v2Rows <- which(bins == paramValues[v2]) # index of rows with their parameter value in paramValues[v2] bin
						} else {
						  v2Rows <- which(indexTable[, paramName]==paramValues[v2]) # index of rows with their parameter value == paramValues[v2]
						}
						mm <- distanceMatrix[v1Rows, v2Rows]

						if (length(mm) > 1 && length(dim(mm) > 1)) {
              v1MinDist <- apply(mm,1,min)
              v2MinDist <- apply(mm,2,min)
              minDist <- mean(c(mean(v1MinDist), mean(v2MinDist)))
              if (storeMinDistColumns) {
                indexTable[v1Rows, minDistColName] <- v1MinDist
                indexTable[v2Rows, minDistColName] <- v2MinDist
              }

						} else {
							minDist <- min(mm)
						}
						paramsDist[v1,v2] <- paramsDist[v2,v1] <- minDist;
						visr.print(paste("average min dist = ", minDist))
						sigV <- c(sigV, minDist)

						# Breakdown
						breakdown[v1, paramValues[v2]] <- minDist
						breakdown[paramValues[v2], v1] <- minDist
					}
					breakdown[v1, v1] <- 0
				}

				# parameterImpact = breakdown[]
				breakdown = apply(breakdown, 1, mean)
				write.table(breakdown, file=paste(path, "/breakdown-", paramName, ".txt", sep = ""), row.names = TRUE, col.names = NA, sep = "\t")
			}
			sigFrame$sig[vp] <- mean(sigV)
			sigFrame$index[vp] <- inputParams[vp]

			# Normalize stuff
			#sigFrame$
		}
		visr.print("[DONE] Calculate Parameters' significance/impact score")
	}

	# Order and save the sigFrame
	sigFrame <- sigFrame[with(sigFrame, order(-sig)), ]
	write.table(as.matrix(sigFrame), file = pathImpact, col.names = NA, sep = "\t")
}

# visr.message("after impact")

# Generate the frequency / stability of the assigned clusters to the genes
if(!file.exists(pathFrequency) || !file.exists(pathStableGenes) || visr.param.recalc == TRUE) {
  visr.print("Generate the frequency / stability of the assigned clusters to the genes")

  loadAllRunsMatrixIfNull()
  loadDistanceMatrixIfNull()

	f <- freq(allRunsMatrix)
	f$name <- inputTable$name # Add the names of the genes to the table for easier identification
	f <- f[with(f, order(-freq)), ] # Order them descending for frequency
	top <- f[(f$sym != "0") & (f$freq > 0.95),] # Assable the top (most stable) genes which are not unregulate
	write.table(f, file=pathFrequency, row.names = TRUE, col.names = NA, sep = "\t")
	write.table(top, file=pathStableGenes, row.names = TRUE, col.names = NA, sep = "\t")

  visr.print("[DONE] Generate the frequency / stability of the assigned clusters to the genes")
} else {
	f <- read.table(pathFrequency, header=TRUE,sep="\t", check.names = F)
	top <- read.table(pathStableGenes, header=TRUE,sep="\t", check.names = F)
}

# Save the possibly changed files
visr.print("Save the (possibly) changed files")

# don't rewrite inputTable as the modes are now calculated in realtime in code
#write.table(inputTable, file=pathInput,     row.names = FALSE, col.names = TRUE, sep = "\t")

write.table(indexTable, file=pathIndex,     row.names = FALSE, col.names = TRUE, sep = "\t")
write.table(paramInfo,  file=pathParamInfo, row.names = FALSE, col.names = TRUE, sep = "\t")
visr.print("[DONE] Save the (possibly) changed files")
