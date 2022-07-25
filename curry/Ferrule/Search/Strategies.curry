-- Module: Ferrule.Search.Strategies
-- Encapsulated search combinators, depth-first, breadth-first, and branch-and-bound optimization.

module Ferrule.Search.Strategies where

-- Standard search tree representation for encapsulated non-deterministic search
data SearchTree a
  = FailTree
  | ValueTree a
  | ChoiceTree [SearchTree a]
  deriving (Eq, Show)

-- Depth-First Search (DFS) traversal collecting all successful solutions
dfsCollectAll :: SearchTree a -> [a]
dfsCollectAll FailTree = []
dfsCollectAll (ValueTree v) = [v]
dfsCollectAll (ChoiceTree branches) =
  concatMap dfsCollectAll branches

-- Depth-First Search finding the first available solution
dfsFindFirst :: SearchTree a -> Maybe a
dfsFindFirst FailTree = Nothing
dfsFindFirst (ValueTree v) = Just v
dfsFindFirst (ChoiceTree branches) =
  case branches of
    []     -> Nothing
    (b:bs) -> case dfsFindFirst b of
                Just v  -> Just v
                Nothing -> dfsFindFirst (ChoiceTree bs)

-- Breadth-First Search (BFS) traversal across search tree levels
bfsCollectAll :: SearchTree a -> [a]
bfsCollectAll root = queueLoop [root]
  where
    queueLoop [] = []
    queueLoop (FailTree : rest) = queueLoop rest
    queueLoop (ValueTree v : rest) = v : queueLoop rest
    queueLoop (ChoiceTree branches : rest) = queueLoop (rest ++ branches)

-- Branch and Bound search selecting the solution minimizing a scalar cost function
branchAndBoundMin :: (a -> Float) -> SearchTree a -> Maybe a
branchAndBoundMin costFn tree =
  let allSolutions = dfsCollectAll tree
  in case allSolutions of
       []     -> Nothing
       (s:ss) -> Just (foldl (\best cur -> if costFn cur < costFn best then cur else best) s ss)
