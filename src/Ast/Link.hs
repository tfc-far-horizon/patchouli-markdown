module Ast.Link where

import Ast
import Data.Aeson
import Ast.Paragraph

data Link = Link
  { text :: Paragraph,
    path :: String
  }

instance ToJSON Link where
  toJSON (Link text path) =
    object
      [ "type" .:: "link",
        "text" .= text,
        "link" .= path
      ]

instance AstNode Link

instance InlineAstNode Link where
  shouldDrop _ = False
