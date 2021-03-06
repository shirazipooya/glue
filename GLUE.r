####The main function to automatically realize the GLUE procedure for parameter estimation for DSSAT model.####

#################Step 1: Get the fundamental information for GLUE procedure.##############
ncol(finf <- file.info(dir()))# at least six
## Not run: finf # the whole list
## Those that are more than 100 days old :
finf[difftime(Sys.time(), finf[,"mtime"], units="days") > 100 , 1:4]

file.info("no-such-file-exists")

## (1) Get the name of the batch file that was generated with GenSelect.
#CultivarBatchFile<-"Prisma_GC_Avg.MZC"; 
CultivarBatchFile<-"SC-F153.PIC";
##Which batch file generated by GenSelect should be used? This information should be given to GLUE when 
##model users decide to use this program.

## (2) Get the information about the working directory of GLUE program (WD), 
#model output storage directory (OD) and DSSAT (DSSATD).
WorkDirectory<-getwd();
WorkDirectorySubstrings<-unlist(strsplit(WorkDirectory,"DSSAT47"));

DSSATD<-paste(WorkDirectorySubstrings[1],"DSSAT47", sep=""); #Get the working directory of DSSAT.

GLUED<-"/Tools/GLUE";#This one is the postion of GLUE under DSSAT and fixed by model developer.
OutputD<-"/GLWork"; #This one is the position of DSSAT output and fixed by model developer.
GenotypeD<-"/Genotype"; #This one is the position of Genotype file.
 
WD<-paste(DSSATD, GLUED, sep="");
OD<-paste(DSSATD, OutputD, sep="");
GD<-paste(DSSATD, GenotypeD, sep="");

eval(parse(text=paste("ModelRunIndicatorPath='",OD,"/ModelRunIndicator.txt'",sep = ''))); 
##Path of the model run indicator file, which indicates which component of GLUE is finished so far.

##WD represents working directory. This is very important, because it is used to tell the main funtion where
##the sub-functions are. DSSATD represents the DSSAT directory. GLUED represents the GLUE directory.
##OutputD represents the output directory under DSSAT, while OD means the final output directory.
##GD ir the directory of genotype files in DSSAT.

## (3) Read the number of model runs and GLUE control flag from the "Simulation Control" file.
#library(xlsReadWrite);
#eval(parse(text = paste("SimulationControl<-read.xls('",WD,
#"/SimulationControl.xls',sheet = 'Sheet 1', rowNames = T, colNames=T)",sep = '')));

eval(parse(text = paste("SimulationControl<-read.csv('",WD,
"/SimulationControl.csv', header=T)",sep = '')));
newRownames <- SimulationControl[ , 1];
rownames(SimulationControl) <- newRownames;

NumberOfModelRun<-as.numeric(SimulationControl["NumberOfModelRun", "Value"]);
write("The number of model run is known...", file = ModelRunIndicatorPath, append = F);

#print(NumberOfModelRun);
#Read the number of model running.
GLUEFlag<-as.numeric(SimulationControl[2,"Value"]);
#Set the flag for whole GLUE procedure. If GLUEFlag==1, it means coefficients relative both to phenology and
#growth will be evaluated; GLUEFlag==2, only phenology will be evaluated; GLUEFlag==3, only growth will be evaluated.

## (4) Get the number of round of GLUE.
if (GLUEFlag==1)
{
StartRoundOfGLUE=1
TotalRoundOfGLUE=2;
} else if (GLUEFlag==2)
{
StartRoundOfGLUE=1
TotalRoundOfGLUE=1;
} else
{
StartRoundOfGLUE=2
TotalRoundOfGLUE=2;
}

write("Which round of GLUE to be done is known...", file = ModelRunIndicatorPath, append = T); 
#In default, totally two rounds of GLUE will be conducted. In the first round, only the genetic coefficients (P1, P2, p5, PHINT)
#that can influence phenology such as anthesis date and maturity date will be estimated, while other parameters (G2, G3)
#will be fixed at their mean values derived from DSSAT database.In the second round of GLUE, G2 and G3 will be estimated based on the likelihood values derived from growth outputs
#such LAIX, HWAM, CWAM. Finally, the two partial parameter sets will be conbined together to give us a final optimal parameter set.

#If only estimated phenology dates, then only the first round GLUE will be conducted; if only estimated growth, then only the
#second round GLUE will be conducted.

## (5) Get the  name of the genotype file of current crop.
eval(parse(text=paste("BatchFile<-readLines('",OD,"/",CultivarBatchFile,"',n=-1)",sep = '')));
CropNameAddress<-grep('BATCH', BatchFile);
CropNameStart<-18; #
CropNameEnd<-19; #
CropName<-substr(BatchFile[CropNameAddress], CropNameStart, CropNameEnd);
write("Crop name is known...", file = ModelRunIndicatorPath, append = T);
#Get the crop name in this model run.

CultivarIDStart<-20; #
CultivarIDEnd<-25; #Get the Cultivar ID number such as, "IB0001";

CultivarNameStart<-20;
CultivarNameEnd<-nchar(BatchFile[CropNameAddress]); #Get the Cultivar name such as, "ZA0002 Prisma GC Avg";

CultivarID<-substr(BatchFile[CropNameAddress], CultivarIDStart, CultivarIDEnd);
CultivarName<-substr(BatchFile[CropNameAddress], CultivarNameStart, CultivarNameEnd);
write("Cultivar ID is known...", file = ModelRunIndicatorPath, append = T);
#Get the cultivar ID and name.

## "$BATCH(CULTIVAR):MZIM0003 APPOLO" is an example to show how to get the crop name and cultivar ID. 
##From this line, we can get to know the crop name "MZ" (18-19), the cultivar ID "IM0003" (20-25).

GenotypeFilePath<-GD;

if ((CropName != "MZ")& (CropName != "SC")& (CropName != "SW") & (CropName != "WH")& (CropName != "BA") & (CropName != "RI"))   
{
eval(parse(text=paste("CurrentGenotypeFile<-list.files(path=GenotypeFilePath, pattern = '^",CropName
,"[A-Z]*[0-9]*.CUL$', all.files = T, full.names = T)",sep = '')));
#print(CurrentGenotypeFile);
} else if (CropName == "MZ")
{
CurrentGenotypeFile<-paste(GD, "/MZCER047.CUL", sep="");
} else if (CropName == "SC")
{
CurrentGenotypeFile<-paste(GD, "/SCCAN047.CUL", sep="");
} else if (CropName == "SW")
{
CurrentGenotypeFile<-paste(GD, "/SWCER047.cul", sep="");
}else if  (CropName == "WH")
{
CurrentGenotypeFile<-paste(GD, "/WHCER047.CUL", sep="");
}else if  (CropName == "BA")
{
CurrentGenotypeFile<-paste(GD, "/BACER047.CUL", sep="");
}else if  (CropName == "RI")
{
CurrentGenotypeFile<-paste(GD, "/RICER047.CUL", sep="");
}

#print(CurrentGenotypeFile);
#Get the names of the genotype file template that will be used, which shoud start with crop name such as "MZ",
#and end with extension name ".CUL". Since there are two genotype files starting with "MZ" and ending with
#".CUL" under the "Genotype" folder of DSSAT, it was set as "MZCER047.CUL" as default value.

StringLength<-nchar(CurrentGenotypeFile);
GenotypeFileNameStartPosition<-(StringLength-(8+4)+1);
GenotypeFileNameEndPosition<-StringLength-4;
#Where 4 is the lenght of character ".CUL", 
#while 8 is the length of cultivar file name, such as "MZCER047".

GenotypeFileName<-substr(CurrentGenotypeFile, GenotypeFileNameStartPosition, GenotypeFileNameEndPosition);
write("Genotype file name is known...", file = ModelRunIndicatorPath, append = T);
#Get the name of the genotype file used currently.

## (6) Set up batch file.
##Only copy the information below @FILEX in the genotype file generated by GenSelect, such as "APPOLO.MZC",
##to the batch file template "DSSBatch.template". Thus a new batch file can be generated and save it as
##"DSSBatch.v47" in the output directory.

eval(parse(text=paste("source('",WD,"/BatchFileSetUp.r')",sep = '')));
BatchFileSetUp(WD, OD, CultivarBatchFile);
write("Batch file is set up...", file = ModelRunIndicatorPath, append = T);

#################Step 2: Begin the GLUE procedure.#################
for (i in StartRoundOfGLUE:TotalRoundOfGLUE)
{

RoundOfGLUE<-i;

## (1) Get the parameter property file (miminum, maximum, and flg values) and the number of parameters.
#library(xlsReadWrite);
#eval(parse(text = paste("ParameterProperty<-read.xls('",WD,
#"/ParameterProperty.xls',sheet = 'Sheet 1', rowNames = T, colNames=T)",sep = '')));

eval(parse(text = paste("ParameterProperty<-read.csv('",WD,
"/ParameterProperty.csv', header = T)",sep = '')));
newRonames <- ParameterProperty[, 1]; 
ParameterProperty <- ParameterProperty[, -1];
rownames(ParameterProperty)<- newRonames;

TotalParameterNumber <- ParameterProperty[CropName, "Flag"]; #Get the total number of the parameters.

#library(xlsReadWrite);
#eval(parse(text = paste("ParameterPropertyWithRow<-read.xls('",WD,
#"/ParameterProperty.xls',sheet = 'Sheet 1', rowNames = F, colNames=T)",sep = '')));

eval(parse(text = paste("ParameterPropertyWithRow<-read.csv('",WD,
"/ParameterProperty.csv', header = T)",sep = '')));
newRonames <- ParameterPropertyWithRow[, 1]; 
ParameterPropertyWithRow <- ParameterPropertyWithRow[, -1];
rownames(ParameterPropertyWithRow)<- newRonames;

ParameterAddress<-which(rownames(ParameterPropertyWithRow)==CropName); #Get the address of the parameters.
ParameterStart<-ParameterAddress+1;
ParameterEnd<-ParameterAddress+TotalParameterNumber;

ParameterNames<-rownames(ParameterProperty[ParameterStart:ParameterEnd,]);
write("Parameter properties are know...", file = ModelRunIndicatorPath, append = T);
#Read the maximum and minimum values for each parameter.

## (2) Generate random values for the paramter set concerned.

eval(parse(text = paste("source('",WD,"/RandomGeneration.r')",sep = '')));
RandomMatrix<-RandomGeneration(WD, GD, CropName, CultivarID, GenotypeFileName, ParameterProperty, ParameterAddress, TotalParameterNumber, NumberOfModelRun, RoundOfGLUE, GLUEFlag);
write("Random parameter sets are generated...", file = ModelRunIndicatorPath, append = T);
write("Model runs are starting...", file = ModelRunIndicatorPath, append = T);

## (3) Create new genotype files with the generated parameter sets and run the DSSAT model with them.
eval(parse(text = paste("source('",WD,"/ModelRun.r')",sep = '')));
ModelRun(WD, OD, DSSATD, GD, CropName, GenotypeFileName, CultivarID, RoundOfGLUE, TotalParameterNumber, NumberOfModelRun, RandomMatrix);
write("Model run is finished...", file = ModelRunIndicatorPath, append = T);
write("Likelihood calculation is starting...", file = ModelRunIndicatorPath, append = T);

## (4) Calculate the likelihood values for each parameter set.
eval(parse(text = paste("source('",WD,"/LikelihoodCalculation.r')",sep = '')));
LikelihoodCalculation(WD, OD, CropName, ParameterNames, RoundOfGLUE);
write("Likelihood calculation is finished...", file = ModelRunIndicatorPath, append = T);
write("Posterior distribution is starting to be derived...", file = ModelRunIndicatorPath, append = T);

## (5) Derivation of posterior distribution.
eval(parse(text = paste("source('",WD,"/PosteriorDistribution.r')",sep = '')));
PosteriorDistribution(WD, OD, ParameterNames, ParameterProperty, CropName, RoundOfGLUE);
write("Posterior distribution is derived...", file = ModelRunIndicatorPath, append = T);

## (6)  Indicator of model running to show the round of GLUE is finished.

if (RoundOfGLUE==1)
{
Indicator<-'The first round of GLUE is finished.';
write(Indicator, file = ModelRunIndicatorPath, append = T);
} else
{ 
Indicator<-'The second round of GLUE is finished.';
write(Indicator, file = ModelRunIndicatorPath, append = T);
}

}

#################Step 3: Get a final optimal parameter set.############## 
eval(parse(text = paste("source('",WD,"/OptimalParameterSet.r')",sep = '')));
OptimalParameterSet(GLUEFlag, OD, DSSATD, CropName, CultivarID, CultivarName, GenotypeFileName, TotalParameterNumber);

options(show.error.message=T);

 








