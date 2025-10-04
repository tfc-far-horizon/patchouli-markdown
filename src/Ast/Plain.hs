module Ast.Plain where

import Ast
import Data.Aeson

newtype Plain = Plain
  { plaintext :: String
  }

instance ToJSON Plain where
  toJSON (Plain t) =
    object
      [ "type" .:: "plain"
      , "content" .= t
      ]

instance AstNode Plain

instance InlineAstNode Plain where
  shouldDrop (Plain "") = True
  shouldDrop _ = False
