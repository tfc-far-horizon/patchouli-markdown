module Ast.Figure where

import Ast
import Data.Aeson
import Ast.Paragraph

data Figure = Figure
  { path :: String,
    caption :: Paragraph
  }

instance ToJSON Figure where
  toJSON (Figure path caption) =
    object
      [ "type" .:: "figure",
        "path" .= path,
        "caption" .= caption
      ]

instance AstNode Figure
