{-# Language OverloadedStrings #-}

module Main where

import Control.Monad.IO.Class
import Git
import Git.Libgit2
import Data.Maybe
import Data.Text

main :: IO ()
main =
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
