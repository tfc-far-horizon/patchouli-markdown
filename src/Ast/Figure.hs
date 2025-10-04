module Ast.Figure where

import Ast
import Ast.Paragraph
import Data.Aeson

data Figure = Figure
  { path :: String
  , caption :: Paragraph
  }

instance ToJSON Figure where
  toJSON (Figure path caption) =
    object
      [ "type" .:: "figure"
      , "path" .= path
      , "caption" .= caption
      ]

instance AstNode Figure
