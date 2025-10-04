module Ast.Itemization where

import Ast
import Ast.Paragraph
import Data.Aeson

data ItemGroup
  = Normal'Item
      { itemTitle :: Paragraph
      , itemContent :: [Itemization]
      }
  | Plain'Item Ast

instance ToJSON ItemGroup where
  toJSON (Normal'Item title content) =
    object
      [ "type" .:: "normal-item"
      , "title" .= title
      , "content" .= content
      ]
  toJSON (Plain'Item ast) =
    object
      [ "type" .:: "plain-item"
      , "content" .= ast
      ]

newtype Itemization = Itemization [ItemGroup]

instance ToJSON Itemization where
  toJSON (Itemization p's) =
    object
      [ "type" .:: "itemization"
      , "items" .= p's
      -- the first paragraph for each list
      -- in list p's will be marked with dot
      ]

instance AstNode Itemization
