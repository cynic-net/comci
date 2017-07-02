{-# OPTIONS_GHC -F -pgmF htfpp #-}

module SampleTest (htf_thisModulesTests) where

import Test.Framework
import Sample

test_nonEmpty = do assertEqual [1] (myReverse [1])
                   assertEqual [3,2,1] (myReverse [1,2,3])

test_empty = assertEqual ([] :: [Int]) (myReverse [])

prop_reverse :: [Int] -> Bool
prop_reverse xs = xs == (myReverse (myReverse xs))
