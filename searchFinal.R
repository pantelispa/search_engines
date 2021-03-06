# When preferences are stohastic the choice is inherently related to a search problem. 

rm(list = ls())
library(MASS)

# Import the real data.

setwd("/Users/pantelispa/Desktop/RepeatedChoice/ReadytoImport")
dataNames <- list.files(path = ".")
p <- 1

for (p in 1:length(dataNames)){
    
    setwd("/Users/pantelispa/Desktop/RepeatedChoice/ReadytoImport")
    theDataset <- read.csv(dataNames[p], header = TRUE, sep = ",")


    # Set up the environment. Change the names of the variables.

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

     # Set up the number of repetitions. 

    repetitions <-  5

     # Set up the length of search for each dataset. Devide the sample in training and test set.

    theSample <- sample(length(theData[,1]),length(theData[,1])/2)
    trainingSet <- theData[theSample,]
    testSet <- theData[-theSample,]
    search <- length(testSet[,1])

    # Initializing the performance memories.

    memExploitMlu <- c(rep(0,search))
    memExploitEw <- c(rep(0,search))
    memExploitSa <- c(rep(0,search))
    memRanploit <-  c(rep(0,search))

    # Start the simulation

    for (k in 1:repetitions){

    # Devide in a training and a test set. 
        
        theSample <- sample(length(theData[,1]),length(theData[,1])/2)
        trainingSet <- theData[theSample,]
        trainingSetEw <- theData2[theSample,]
        testSet <- theData[-theSample,]
        testSetEw <- theData2[-theSample,]  
        testSet2 <- testSet[sample(nrow(testSet)),] # Order for random search.


     # Multi-attribute linear utility.

        mlu <- lm(X1 ~ ., data = trainingSet)
        predictions <- predict(mlu, newdata = testSet)
        mluOrder <- predictions[order(predictions, decreasing = TRUE)]

     # Single attribute. 

        test <- cor(trainingSet, method = "kendall")
        test[is.na(test) == TRUE] <- 0 
        v <- which(abs(test[1,2:length(trainingSet)]) == max(abs(test[1,2:length(trainingSet)])))  # find the strongest correlation
        if(length(v) > 1){v <- sample(v)[1]}
        SA <- lm(as.formula(paste( "X1 ~ X", v + 1, sep = "")),data = trainingSet)
        predictionsSa <- predict(SA, newdata = testSet)
        lexiOrder <- predictionsSa[order(predictionsSa, decreasing = TRUE)]

      # Equal weighting of alternatives.

        V2 <-  EW(trainingSetEw,trainingSetEw) # create a single cue. 
        trainingSetEw2 <- as.data.frame(cbind(trainingSetEw[,1],V2)) # create a data.frame to run the regression. 
        equalWeighting <- lm(V1 ~ V2, data = trainingSetEw2)
        V2 <- EW(trainingSetEw,testSetEw) # create a single cue for the training set.
        testSetEw <- as.data.frame(cbind(testSetEw[,1],V2))
        predictionsEw <- predict(equalWeighting, newdata = testSetEw)
        equalOrder <- predictionsEw[order(predictionsEw, decreasing = TRUE)]
        
        for (i in 1:search){

       # the maximum utility found in "search" number of rounds. 

            exploitEw <- max(theData[as.numeric(names(equalOrder[1:i])),1])
            exploitMlu <- max(theData[as.numeric(names(mluOrder[1:i])),1])
            exploitSa <- max(theData[as.numeric(names(lexiOrder[1:i])),1])
            ranploit <- max(theData[as.numeric(rownames(testSet2[1:i,])),1])

       # save the results in the memories.
            
            memExploitEw[i] <-  memExploitEw[i] + exploitEw
            memExploitMlu[i] <- memExploitMlu[i] + exploitMlu
            memExploitSa[i] <- memExploitSa[i] + exploitSa
            memRanploit[i] <- memRanploit[i] + ranploit
        }

    }

    setwd("/Users/pantelispa/Desktop")
    #setwd("/home/mpib/analytis/Results")
    takeLength <- nchar(dataNames[p])
    theName <- substr(dataNames[p], 1, takeLength - 4)
    saveHere <- paste(theName,"Search.Rdata", sep="")
    save.image(file = saveHere)

}

     

