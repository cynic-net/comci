{-# OPTIONS_GHC -F -pgmF htfpp #-}

module Test where

import Test.Framework
import Test.Framework.BlackBoxTest
import {-@ HTF_TESTS @-} SampleTest

main = do
    bbts <- blackBoxTests "bbt" "sh" ".cmd" defaultBBTArgs
    htfMain (htf_importedTests ++ [makeTestSuite "bbts" bbts])
