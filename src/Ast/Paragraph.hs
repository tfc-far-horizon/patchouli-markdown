module Ast.Paragraph where

import Ast
import Data.Aeson

newtype Paragraph = Paragraph [InlineAst]

instance ToJSON Paragraph where
  toJSON (Paragraph lineFragments) =
    object
      [ "type" .:: "paragraph",
        "content"
          .= filter (\(InlineAst fragment) -> not $ shouldDrop fragment) lineFragments
      ]

instance AstNode Paragraph
