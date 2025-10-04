module Ast.Emphasis where

import Ast
import Ast.Paragraph
import Data.Aeson

data EmphasisType
  = UnderLined
  | Italic
  | Bold

classify :: CharUnit -> EmphasisType
classify symbol = case fst symbol of
  '_' -> UnderLined
  '*' -> Italic
  '^' -> Bold
  _ -> undefined

data Emphasis = Emphasis Paragraph EmphasisType

instance ToJSON EmphasisType where
  toJSON UnderLined = String "underlined"
  toJSON Italic = String "italic"
  toJSON Bold = String "bold"

instance ToJSON Emphasis where
  toJSON (Emphasis asts t) =
    object
      [ "type" .= t
      , "content" .= asts
      ]

instance AstNode Emphasis

instance InlineAstNode Emphasis where
  shouldDrop _ = False
