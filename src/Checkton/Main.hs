{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Data.Aeson (encode, object, (.=))
import qualified Data.ByteString.Lazy.Char8 as B
import Data.Functor.Identity (Identity (runIdentity))
import ShellCheck.Checker (checkScript)
import ShellCheck.Fixer (Ranged (end, setRange, start))
import ShellCheck.Formatter.Format (makeNonVirtual)
import ShellCheck.Formatter.JSON1 ()
import ShellCheck.Interface
  ( CheckSpec (..),
    Fix (fixReplacements),
    Position (posColumn, posLine),
    PositionedComment (pcFix),
    crComments,
    emptyCheckSpec,
    newSystemInterface,
  )
import System.Environment (getArgs)

runShellCheck :: FilePath -> String -> [PositionedComment]
runShellCheck filename script =
  makeNonVirtual comments script
  where
    comments = crComments $ runIdentity $ checkScript si spec
    si = newSystemInterface
    spec =
      emptyCheckSpec
        { csFilename = filename,
          csScript = script,
          csExcludedWarnings = [1091] -- source following not implemented yet
        }

-- line, column (0-based, Tab counts as 1)
type Offset = (Integer, Integer)

applyOffset :: Offset -> [PositionedComment] -> [PositionedComment]
applyOffset (line, column) = map offsetComment
  where
    offsetComment c = (offsetRanged c) {pcFix = fmap offsetFix (pcFix c)}
    offsetFix f = f {fixReplacements = map offsetRanged (fixReplacements f)}
    offsetRanged r = setRange (offsetPos (start r), offsetPos (end r)) r
    offsetPos p = p {posLine = line + posLine p, posColumn = column + posColumn p}

main :: IO ()
main = do
  args <- getArgs
  comments <-
    applyOffset (0, 0) . concat <$> mapM (\f -> runShellCheck f <$> readFile f) args
  B.putStrLn $ encode $ object ["comments" .= comments]
