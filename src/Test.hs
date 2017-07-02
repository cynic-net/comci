{-# OPTIONS_GHC -F -pgmF htfpp #-}

module Test where

import Test.Framework
import {-@ HTF_TESTS @-} SampleTest

main = htfMain htf_importedTests    -- htf_thisModulesTests
