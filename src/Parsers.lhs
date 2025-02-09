\section{引言}

Parsers 模块定义了各个层级的 Parser，
所有 Parser 有共同的签名： Analyser Ast

\begin{code}
module Parsers (article, parse, section) where

import Ast
import Text.Parsec hiding (parse)

type Analyser = Parsec 
  String   -- 输入给 parser 的内容
  [String] -- 存放warning的位置

warn :: Analyser a -> String -> Analyser a
warn p s = modifyState (s:) *> p

parse :: Analyser a -> String -> String -> Either ParseError (a, [String])
parse p name input = runParser p' [] name input
  where
    p' = do
      l <- p
      r <- getState
      return (l, r)

\end{code}

\section{字符元}

markdown 使用的特殊符号有时会和普通文本中需要的内容冲突，
此时我们需要转义。
以下组合子定义一个“字符元”，
表示一个转义字符或未转义的字符。
它会消耗一个字符，或一个字符及其前方的转义符。

在绝大多数情况下，我们会一次性阅读一个字符元；
唯一例外的是数学环境，
其内部的 `\textbackslash' 会被原样地当作 \LaTeX 的引导符；
但在解析的时候，我们仍然需要一次性读入字符元，
以判断是否达到了数学环境的末尾。
此后，我们再通过 withslash 将其转为字符。
（不带前缀 \textbackslash 的版本可以直接用 fst）

在 Char 类型和 CharUnit 类型的对应下，
charUnit 是对应 char 的组合子，
anyCharUnit 是对应 anyChar 的组合子。

toUnit 和 toUnitString 是
将 Char 类型向 CharUnit 类型转换的函数。

\begin{code}

type CharUnit = (Char, Bool)

anyCharUnit :: Analyser CharUnit
anyCharUnit = do
  c <- anyChar
  case c of
    '\r' ->
      (toUnit <$>) $ try (char '\n') <|> return '\n'
    '\n' -> return . toUnit $ c
    '\\' -> do
      n <- anyChar
      case n of
        '\r' -> unexpected "escaped end of line."
        -- 此处禁止在转义符后换行，
        -- 因为如何处理转义符后开启新行时的缩进有待讨论。
        _ -> return (n, True)
    _ -> return (c, False)

withslash :: CharUnit -> String
withslash (c, True) = ['\\', c]
withslash (c, False) = [c]

charUnit :: CharUnit -> Analyser CharUnit
charUnit (c, b) = do
  (c', b') <- anyCharUnit
  if c == c' && b == b'
    then return (c, b)
    else unexpected $ show [c'] ++ "expecting" ++ show c

toUnit :: Char -> CharUnit
toUnit c = (c, False)

toUnitString :: [Char] -> [CharUnit]
toUnitString = map toUnit

noneUnitOf :: [CharUnit] -> Analyser CharUnit
noneUnitOf cs = do
  c <- anyCharUnit
  if c `elem` cs
    then unexpected $ [fst c]
    else return c

\end{code}

\section{普通文本}

普通的 markdown 纯文本内容以行为界；每一行被视作一个段落。

由于可能影响缩进的判断，我们暂时不支持在行末加入转义字符。

行内的markdown可以出现下列环境：

\begin{itemize}
  \item 行内数学模式
  \item 强调环境
  \item 链接
\end{itemize}

\begin{code}

inlinemd :: Maybe CharUnit -> Analyser Ast
inlinemd m = do
  let symbols' = case m of
        Just m' -> m' : symbols
        Nothing -> symbols
  content <- Plain . map fst <$> many (try (noneUnitOf symbols'))
  symbol <- lookAhead anyCharUnit
  if Just symbol == m
    then charUnit symbol *> return (Paragraph [content])
    else case symbol of
      ('$', False) -> content `prepend` inlineMath
      ('[', True) ->
        unexpected . unlines $
          [ "display math environment inlined,",
            "please use inline math environment instead,",
            "or use display mode environment alone as a line."
          ]
      ('*', False) -> content `prepend` emphasis ('*', False)
      ('^', False) -> content `prepend` emphasis ('^', False)
      ('_', False) -> content `prepend` emphasis ('_', False)
      ('[', False) -> do
        prependee <-
          try link
            <|>
            -- 此处并没有手动左结合而是直接 try link，
            -- 因此在目标不是链接时会回退整个中括号块，
            -- 但这个性能损失我觉得还能接受
            char '['
            *> inlinemd (Just (']', False))
        (Paragraph (inline : inlines)) <- inlinemd m
        case prependee of
          (Link _ _) ->
            return . Paragraph $
              content : prependee : inline : inlines
          (Plain t) -> case inline of
            (Plain t') ->
              return . Paragraph $
                (Plain (plaintext content ++ t ++ t')) : inlines
            _ ->
              return . Paragraph $
                (Plain (plaintext content ++ t)) : inline : inlines
          _ -> error $ show prependee
      ('\n', False) -> case m of
        Just u -> unexpected $ "end of line\n, expecting" ++ withslash u
        Nothing -> char '\n' *> (return . Paragraph $ [content])
      _ -> error "unknown error"
  where
    prepend :: Ast -> Analyser Ast -> Analyser Ast
    prepend c p = do
      prependee <- p
      (Paragraph inline) <- inlinemd m
      return . Paragraph $ c : prependee : inline

    symbols :: [CharUnit]
    symbols =
      [ ('$', False), -- inline math
        ('[', True), -- display math
        ('*', False), -- emphasis, italic
        ('^', False), -- emphasis, bold
        ('_', False), -- emphasis, underlined
        ('\n', False), -- end of line
        ('[', False) -- link
      ]

\end{code}


\section{数学公式}

数学环境是用 
  \$ \$ (inline mode) 或 
  \textbackslash[ \textbackslash] (display mode)
包裹的一段 LaTeX 数学公式。

inline mode （行内公式）可以出现在普通文本内容之内，
display mode （行间公式）可以单独成行。

\begin{code}

inlineMath :: Analyser Ast
inlineMath = do
  charUnit ('$', False)
  pos <- getPosition
  formula <-
    concat . map withslash
      <$> many (try $ noneUnitOf [('$', False), ('\n', False)])
  (try $ charUnit ('$', False)) <|> return ('$', False) `warn` unlines 
    [ "unenclosed inline math environment",
      "note: math env began at" ++ show pos
    ]
  return . Math formula $ False

displayMath :: Analyser Ast
displayMath = do
  (try $ charUnit ('[', True)) <|> unexpected "not beginner of displayMath"
  pos <- getPosition
  formula <-
    concat . map withslash
      <$> many (try $ noneUnitOf [(']', True)])
  ((try $ charUnit (']', True)) <|>) $
    unexpected . unlines $
      [ "unenclosed display math environment,",
        "note: math env began at " ++ show pos
      ]
  return . Math formula $ True


\end{code}

\section{链接和图片}

链接的语法如下：

[<链接中显示的文本>](<链接的路径>)

图片的语法如下：

![<图片的 caption>](<图片的路径>)

\begin{code}

link :: Analyser Ast
link = do
  text <-
    charUnit ('[', False)
      *> inlinemd (Just (']', False))
  link <- between (charUnit ('(', False)) (charUnit (')', False)) $ many $ try $ noneUnitOf [(')',False),('\n',False)]
  return . Link text $ map fst $ link

figure :: Analyser Ast
figure = do
  (Link text link) <- charUnit ('!', False) *> link
  return $ Figure link text

\end{code}

\section{强调}

用 \_ 包裹内容以对其打下划线，
用 *  包裹内容以使其斜体，
用 \^ 包裹内容以使其加粗。

\begin{code}

emphasis :: CharUnit -> Analyser Ast
emphasis symbol = do
  emphasised <- do
    charUnit symbol
    inlinemd (Just symbol)
  return . Emphasis emphasised $ case fst symbol of
    '_' -> UnderLined
    '*' -> Italic
    '^' -> Bold
    _ -> error "unrecognized beginner of emphasis"

\end{code}

\section{列表}

在 igem-markdown 中，我们提供列表功能，
以分割内容的层级。

一个列表由连续的若干个列表项组成，
每一个列表项由直接子内容和若干连续的间接子内容组成。

直接子内容代表列表项的标题，
或在没有间接子内容时表示列表项的内容。

每一个直接子内容是没有额外缩进的、由序号引导的段落，
序号和直接子内容段落间需要有一个空格。

每一个间接子内容是一个进行了额外缩进的段落。

\begin{code}

indented :: Int -> Analyser Ast -> Analyser Ast
indented n p = count n (char '\t') *> p

directItem :: Analyser Ast
directItem = oneOf "+-" *> char ' ' *> inlinemd Nothing

directEnum :: Analyser Ast
directEnum = many digit *> char '.' *> char ' ' *> inlinemd Nothing

indirect :: Analyser Ast
indirect = displayMath <|> figure <|> inlinemd Nothing

itemization' :: Int -> Analyser Ast
itemization' n = Itemization <$> many1 group
  where
    group :: Analyser [Ast]
    group = try $ do
      first <- n `indented` directItem
      followers <-
        many . try $
          do
            (n + 1) `indented` indirect
            <|> itemization' (n + 1)
      return $ first : followers

enumeration' :: Int -> Analyser Ast
enumeration' n = Enumeration <$> many1 group
  where
    group :: Analyser [Ast]
    group = try $ do
      first <- n `indented` directEnum
      followers <-
        many . try $
          do
            (n + 1) `indented` indirect
            <|> enumeration' (n + 1)
      return $ first : followers

itemization :: Analyser Ast
itemization = itemization' 0

enumeration :: Analyser Ast
enumeration = enumeration' 0

\end{code}

\section{标题和章节}

在 igem-markdown 中，我们提供使用标题分割章节的功能，
其功用类似 \LaTeX 的 \textbackslash{}section。

我们仅提供一个层次的标题，而不提供多级标题或 
\textbackslash{}subsection

每一个章节包含：
\begin{itemize}
  \item 章节标题
  \item （可选的）本章内容描述的时间（日期）
  \item 章节的内容，为数个按行为界的段落
\end{itemize}

\begin{code}

parseDay :: [CharUnit] -> Analyser (Maybe Day)
parseDay d = do
  pos <- getPosition
  case parse day "date" $
    map fst $ d of
      Right date -> return $ Just $ fst date
      Left _ -> return Nothing `warn` unlines
        [ "Invalid date format at " ++ show pos,
          "\tnote: everything after the second '#' will be dropped.",
          "\tnote: Date should take the `YYYY-MM-DD' format"
        ]

sectionTitle :: Analyser (String, Maybe Day)
sectionTitle = do
  charUnit ('#', False)
  title <- t "#\n"
  date <- choice $
    [ charUnit ('#', False) *> t "\n",
      return $ toUnitString ""
    ]
  day <- parseDay date
  charUnit ('\n', False)
  return (map fst title, day)
  where
    t s = many (try $ noneUnitOf $ toUnitString s)

day :: Analyser Day
day = do
  year <- read <$> count 4 digit <* char '-'
  month <- read <$> count 2 digit <* char '-'
  day <- read <$> count 2 digit
  return $ fromGregorian year month day

section :: Analyser Ast
section = do
  (title, date) <- sectionTitle
  c <- many paragraph
  return $ Section title date c
  where
    paragraph =
      try $
        choice
          [ itemization,
            enumeration,
            figure,
            inlinemd Nothing
          ]

article :: Analyser [Ast]
article =
  many $
    choice
      [ try section,
        try itemization,
        try enumeration,
        try figure,
        displayMath,
        inlinemd Nothing
      ]

\end{code}
