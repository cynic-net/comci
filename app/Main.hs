{-# Language OverloadedStrings #-}

module Main where

import Control.Monad.IO.Class
import Git
import Git.Libgit2

main :: IO ()
main =
    withRepository' lgFactory opts $ do
        f <- facts;                         liftIO $ print f
        ref <- lookupReference "HEAD";      liftIO $ print ref
        return ()
    where
        opts = RepositoryOptions
            { repoPath = "test/fixture/repo00.git"
            , repoWorkingDir = Nothing
            , repoIsBare = True
            , repoAutoCreate = False
            }

instance Show (RefTarget r) where
    show (RefObj oid) = "RefObj#" ++ undefined -- show (renderOid oid)
    show (RefSymbolic name) = "RefSymbolic#" ++ show name
