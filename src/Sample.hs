--
--  Sample functions to test while we set up test framework
--
module Sample (myReverse) where

myReverse :: [a] -> [a]
myReverse []     = []
myReverse [x]    = [x]
myReverse (x:xs) = myReverse xs ++ [x]  -- remove `++ [x]` to see test failures
