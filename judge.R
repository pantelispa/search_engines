# This function calculates the score of cross validation results.

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
