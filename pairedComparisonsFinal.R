#pairedComparisonsFinal.R

# CrossValidation 
rm(list = ls())
library(MASS)

# Import the real data

setwd("/Users/pantelispa/Desktop/Datasets/RepeatedChoice/ReadytoImport")

dataNames <- list.files(path = ".")
p <- 1

judge <- function(theData,predictions){
    numbers <- seq(1,length(theData[,1]),1)
    allPairs <- combn(numbers,2)
    theJudgment1 <- theData[allPairs[1,],1] - theData[allPairs[2,],1]
    theJudgment1[theJudgment1 < 0] <- -1 
    theJudgment1[theJudgment1 >= 0] <- 1 
    theJudgment2 <- as.vector(predictions[allPairs[1,]]) - as.vector(predictions[allPairs[2,]])
    theJudgment2[theJudgment2 < 0] <- -1 
    theJudgment2[theJudgment2 >= 0] <- 1
    theJudge <- theJudgment1 - theJudgment2
    scoreJudge <- sum(theJudge == 0)/length(theJudgment1)
    return(scoreJudge)
}

judgeRecommender <- function(theData,predictions){
    numbers <- seq(1,length(theData[,1]),1)
    allPairs <- combn(numbers,2)
    theJudgment1 <- theData[allPairs[1,],1] - theData[allPairs[2,],1]
    theJudgment1[theJudgment1 < 0] <- -1 
    theJudgment1[theJudgment1 > 0] <- 1
    index <- which(theJudgment1 == 0)
    if (length(index) > 0){
    theJudgment1[index] <- sample(c(-1,1),length(theJudgment1[index]),replace = TRUE)}
    theJudgment2 <- as.vector(predictions[allPairs[1,]]) - as.vector(predictions[allPairs[2,]])
    theJudgment2[theJudgment2 < 0] <- -1 
    theJudgment2[theJudgment2 > 0] <- 1
    index2 <- which(theJudgment2 == 0)
    if (length(index2) > 0){
    theJudgment2[index2] <- sample(c(-1,1),length(theJudgment2[index2]),replace = TRUE)}
    theJudge <- theJudgment1 - theJudgment2
    scoreJudge <- sum(theJudge == 0)/length(theJudgment1)
     return(scoreJudge)
}

EW <- function(memory, dataset){
      corTable <- cor(memory)  
      corTable[is.na(corTable)] <- 0  # test for negative correlations. 
      corTable2 <- corTable[2:length(corTable[,1]),1]
      corTable2[corTable2 > 0] <- 0
      corTable2[corTable2 < 0] <- -1 
      values <- abs(corTable2 + t(dataset[2:length(dataset[1,])])) # set the lowest attribute value as highest. 
      values <- t(values)
      final <- rowSums(values)  # Sum all the attributes. 
      return(final)}


for (p in 1:length(dataNames)){
    
    setwd("/Users/pantelispa/Desktop/Datasets/RepeatedChoice/ReadytoImport")
    theDataset <- read.csv(dataNames[p], header = TRUE, sep = ",")

    k <- 1
    theData <- data.frame(t(matrix(c(rep(0,length(theDataset[,1])*length(theDataset[1,]))),length(theDataset[1,]))))

    while (k <= length(theData[,1])){
        theData[k,] <- theDataset[k,]
        k <-  k + 1}


     # Normalize utility. Set the utility of the best alternative equal to 1 and that of the worst equal to zero. 

    theData[,1] <-  (theData[,1] - min(theData[,1])) / (max(theData[,1]) - min(theData[,1]))
    theData2 <- theData

    # Normalize the attributes. This is used later in the equal weighting strategy.

    for (k in 1:length(theData2[1,])){
        theData2[,k] <-  (theData2[,k] - min(theData2[,k])) / (max(theData2[,k]) - min(theData2[,k]))}

     # parameters of the model.

    repetitions <-  10000

    # Set up the length of search for each dataset. Devide the sample in training and test set.

    theSample <- sample(length(theData[,1]),length(theData[,1])/2)
    trainingSet <- theData[theSample,]
    testSet <- theData[-theSample,]
    search <- length(testSet[,1])

    # Initializing memory

    memExploitMlu <- c(rep(0,repetitions))
    memExploitEw <- c(rep(0,repetitions))
    memExploitSa <- c(rep(0,repetitions))

    for (m in 1:repetitions){

        # Devide in a training and a test set
        
        theSample <- sample(length(theData[,1]),length(theData[,1])/2)
        trainingSet <- theData[theSample,]
        trainingSetEw <- theData2[theSample,]
        testSet <- theData[-theSample,]
        testSetEw <- theData2[-theSample,]  
        testSet2 <- testSet[sample(nrow(testSet)),] # Order for random search.

        # Multi-linear utility

        reg <- lm(X1 ~ ., data = trainingSet)
        predictions <- predict(reg, newdata = testSet)
        scoreMlu <- judgeRecommender(testSet, predictions)

        # Lexicographic.

        test <- cor(trainingSet, method = "kendall")
        test[is.na(test) == TRUE] <- 0 
        v <- which(abs(test[1,2:length(trainingSet)]) == max(abs(test[1,2:length(trainingSet)])))  # find the strongest correlation
        if(length(v) > 1){v <- sample(v)[1]}
        SA <- lm(as.formula(paste( "X1 ~ X", v + 1, sep = "")),data = trainingSet)
        predictionsSa <- predict(SA, newdata = testSet)
        scoreSa <- judgeRecommender(testSet, predictionsSa)

        # Equal weights.

        V2 <-  EW(trainingSetEw,trainingSetEw) # create a single cue. 
        trainingSetEw2 <- as.data.frame(cbind(trainingSetEw[,1],V2)) # create a data.frame to run the regression. 
        equalWeighting <- lm(V1 ~ V2, data = trainingSetEw2)
        V2 <- EW(trainingSetEw,testSetEw) # create a single cue for the training set.
        testSetEw <- as.data.frame(cbind(testSetEw[,1],V2))
        predictionsEw <- predict(equalWeighting, newdata = testSetEw)
        scoreEw <- judgeRecommender(testSetEw,predictionsEw)
        
        memExploitEw[m] <-  memExploitEw[m] + scoreEw
        memExploitMlu[m] <- memExploitMlu[m] + scoreMlu
        memExploitSa[m] <- memExploitSa[m] + scoreSa

    }

    setwd("/Users/pantelispa/Desktop")
    #setwd("/home/mpib/analytis/Results")
    takeLength <- nchar(dataNames[p])
    theName <- substr(dataNames[p], 1, takeLength - 4)
    saveHere <- paste(theName,"Comparisons.Rdata", sep="")
    save.image(file = saveHere)
}
