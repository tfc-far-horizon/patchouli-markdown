module Ast.CodeBlock where

import Ast
import Data.Aeson

data CodeBlock = CodeBlock
  { language :: String
  , code :: String
  , line'number :: Maybe Int
  }
  deriving (Show)

instance ToJSON CodeBlock where
  toJSON c =
    object $
      [ "type" .:: "code-block"
      , "language" .= language c
      , "content" .= code c
      , "line-number" .= line'number c
      ]

instance AstNode CodeBlock
