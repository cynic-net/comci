{-# Language OverloadedStrings #-}

module GitCI.Main where

import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)
import System.Exit (ExitCode (ExitFailure), exitWith)

import Control.Monad.IO.Class
import Git
import Git.Libgit2 (lgFactory)
import Data.Maybe
import Data.Text (unpack)

main :: IO ()
main =
     do args <- getArgs
        case args of
             []        -> grovelInRepo
             ["log"]   -> do
                             gitCiLog
             otherwise -> do
                 hPutStrLn stderr $ "Unknown option: " ++ head args
                 exitWith $ ExitFailure 2

formatCommit commitOid = do commit <- lookupCommit commitOid
                            liftIO $ putStrLn $ (show commitOid)
                                      ++ " " ++ (unpack $ commitLog commit)
                            formatCommit $ head (commitParents commit)

gitCiLog =
    withRepository' lgFactory opts $ do
        mRef <- resolveReference "HEAD"
        let ref = fromMaybe (error "HEAD doesn't exist") mRef
        commitOid <- parseObjOid $ renderOid ref
        formatCommit commitOid
    where
        opts = RepositoryOptions
            { repoPath = "."
            , repoWorkingDir = Nothing
            , repoIsBare = True
            , repoAutoCreate = False
            }

grovelInRepo =
    withRepository' lgFactory opts $ do
        mRef <- resolveReference "HEAD"
        let ref = fromMaybe (error "HEAD doesn't exist") mRef
        commitOid <- parseObjOid $ renderOid ref
        commit <- lookupCommit commitOid
        tree <- lookupTree $ commitTree commit
        treeOid <- treeOid tree

        liftIO $ putStrLn $
                 "commit: "  ++ (show commitOid)
            ++ "\nmessage: " ++ (unpack $ commitLog commit)
            ++   "tree: "    ++ (show treeOid)
        return ()
    where
        opts = RepositoryOptions
            { repoPath = "fixture/repo00.git"
            , repoWorkingDir = Nothing
            , repoIsBare = True
            , repoAutoCreate = False
            }

instance Show (RefTarget r) where
    show (RefObj oid) = "RefObj#" ++ undefined -- show (renderOid oid)
    show (RefSymbolic name) = "RefSymbolic#" ++ show name
