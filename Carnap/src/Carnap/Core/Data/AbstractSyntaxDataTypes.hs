{-#LANGUAGE TypeFamilies, UndecidableInstances, FlexibleInstances, MultiParamTypeClasses, FunctionalDependencies, AllowAmbiguousTypes, GADTs, KindSignatures, DataKinds, PolyKinds, TypeOperators, ViewPatterns, PatternSynonyms, RankNTypes, FlexibleContexts, ScopedTypeVariables, AutoDeriveTypeable, DefaultSignatures #-}

module Carnap.Core.Data.AbstractSyntaxDataTypes(
  -- * Abstract Types
  -- $ATintro
  -- ** Language Building Types
  Term(..), Form(..),
  Copula((:$:), Lam), CopulaSchema(..),
  MaybeMonadVar(..),MaybeStaticVar(..),FirstOrderLex(..),
  (:|:)(..), Fix(Fx), FixLang, EndLang, pattern AOne,
  pattern ATwo, pattern AThree, pattern LLam, pattern (:!$:), pattern Fx1,
  pattern Fx2, pattern Fx3, pattern Fx4, pattern Fx5, pattern Fx6, pattern
  Fx7, pattern Fx8, pattern Fx9, pattern Fx10, pattern Fx11, pattern Lx1,
  pattern Lx2, pattern Lx3, pattern Lx4, pattern Lx5, pattern Lx6, pattern
  Lx7, pattern Lx8, pattern Lx9, pattern Lx10, pattern Lx11, pattern FX,
  -- ** Abstract Term Types
  -- *** Variable Binding Operators
  Binders(Bind),Abstractors(Abstract),Applicators(Apply), BoundVars(..),
  -- *** Non-Binding Operators
  Arity(AZero, ASucc), Predicate(Predicate), Connective(Connective),
  Function(Function), Subnective(Subnective), SubstitutionalVariable(SubVar,StaticVar),
  -- * Generic Programming Utilities
  arityInt
) where

import Carnap.Core.Util
import Data.Typeable
import Data.List (intercalate)
import Carnap.Core.Unification.Unification
import Control.Lens
import Control.Monad ((>=>))
import Carnap.Core.Data.AbstractSyntaxClasses
import Control.Monad.State (get, put, State)
import qualified Control.Monad.State.Lazy as S

-- This module attempts to provide abstract syntax types covering a wide
-- variety of languages

-- $ATintro
-- Here are some types for abstract syntax. The basic proposal
-- is that we only define how terms of different types connect
-- and let the user define all the connections independently of
-- of their subparts. In some sense you can just define the types
-- and the type system figures out how they can go together

-- We use the idea of a semantic value to indicate approximately a Fregean
-- sense, or intension: approximately a function from models to Fregean
-- denotations in those models

--------------------------------------------------------
--1.1 Language Building Types
--------------------------------------------------------

{-|
This is the type that describes how things are connected.
Things are connected either by application or by
a lambda abstraction. The 'lang' parameter gets fixed to
form a fully usable type

@
   Fix (Copula :|: Copula :|: (Predicate BasicProp :|: Connective BasicConn))
@
-}
data Copula lang t where
    (:$:) :: (Typeable t, Typeable t') => lang (t -> t') -> lang t -> Copula lang t'
    Lam :: (Typeable t, Typeable t') => (lang t -> lang t') -> Copula lang (t -> t')
    Lift :: t -> Copula lang t

class CopulaSchema lang where
    appSchema :: lang (t -> t') -> lang t -> [String] -> String
    default appSchema :: (Schematizable lang, Show (lang t)) => lang (t -> t') -> lang t -> [String] -> String
    appSchema x y e = schematize x (show y : e)
    lamSchema :: (Typeable t, Typeable t') => (lang t -> lang t') -> [String] -> String
    lamSchema = error "how did you even do this?"
    liftSchema :: Copula lang t -> [String] -> String
    liftSchema = error "should not print a lifted value"

{-|
this is type acts a disjoint sum/union of two functors
it carries though the phantom type as well
-}
data (:|:) :: (k -> k' -> *) -> (k -> k' -> *) -> k -> k' -> * where
    FLeft :: f x idx -> (f :|: g) x idx
    FRight :: g x idx -> (f :|: g) x idx

infixr 5 :|:

-- | This type fixes the first argument of a functor and carries though a
-- | phantom type. note that only certian kinds of functors even have a kind
-- | such that the first argument is fixable
data Fix f idx where
    Fx ::  Typeable idx => f (Fix f) idx -> Fix f idx

-- | This is an empty abstract type, which can be used to close off
-- | a series of applications of `:|:`, so that the right-most leaf
-- | doesn't need special treatment.
data EndLang :: (* -> *) -> * -> *

type FixLang f = Fix (Copula :|: f)

pattern (:!$:) f x = Fx (FLeft  (f :$: x))
pattern LLam f     = Fx (FLeft  (Lam f))
pattern Lx1 x      = FLeft x
pattern Lx2 x      = FRight (FLeft x)
pattern Lx3 x      = FRight (FRight (FLeft x))
pattern Lx4 x      = FRight (FRight (FRight (FLeft x)))
pattern Lx5 x      = FRight (FRight (FRight (FRight (FLeft x))))
pattern Lx6 x      = FRight (FRight (FRight (FRight (FRight (FLeft x)))))
pattern Lx7 x      = FRight (FRight (FRight (FRight (FRight (FRight (FLeft x))))))
pattern Lx8 x      = FRight (FRight (FRight (FRight (FRight (FRight (FRight (FLeft x)))))))
pattern Lx9 x      = FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FLeft x))))))))
pattern Lx10 x     = FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FLeft x)))))))))
pattern Lx11 x     = FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FLeft x))))))))))
pattern Lx12 x     = FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FRight (FLeft x)))))))))))
pattern Fx1 x      = FX (Lx1  x)
pattern Fx2 x      = FX (Lx2  x)
pattern Fx3 x      = FX (Lx3  x)
pattern Fx4 x      = FX (Lx4  x)
pattern Fx5 x      = FX (Lx5  x)
pattern Fx6 x      = FX (Lx6  x)
pattern Fx7 x      = FX (Lx7  x)
pattern Fx8 x      = FX (Lx8  x)
pattern Fx9 x      = FX (Lx9  x)
pattern Fx10 x     = FX (Lx10 x)
pattern Fx11 x     = FX (Lx11 x)
pattern Fx12 x     = FX (Lx12 x)
pattern FX x       = Fx (FRight x)

--------------------------------------------------------
--1.2 Abstract Operator Types
--------------------------------------------------------

--------------------------------------------------------
--1.2.1 Variable Binding Operators
--------------------------------------------------------

data Binders :: (* -> *) -> (* -> *) -> * -> * where
    Bind :: bind ((t a -> f b) -> g c) -> Binders bind lang ((t a -> f b) -> g c)

data Abstractors :: (* -> *) -> (* -> *) -> * -> * where
    Abstract :: abs ((t a -> t' b) -> t'' (a -> b)) -> Abstractors abs lang ((t a -> t' b) -> t'' (a -> b))

data Applicators :: (* -> *) -> (* -> *) -> * -> * where
    Apply :: app (t (a -> b) -> t' a -> t'' b) -> Applicators app lang (t (a -> b) -> t' a -> t'' b)

-- TODO variadic binders

{-|
This typeclass needs to provide a way of replacing bound variables within
a given expression, and a way of getting a producing a variable uniquely
determined by the scope of a given binder, in such a way that none of the
binders in its subformulas will determine the same variable.

It's used to create generic @Traversal@s and @Plated@ instances, via LangTypes
-}
class BoundVars g where
        subBoundVar :: FixLang g a -> FixLang g a -> FixLang g b -> FixLang g b
        subBoundVar _ _ = id
        scopeUniqueVar :: Typeable a => FixLang g ((a -> b) -> c) -> FixLang g (a -> b) -> FixLang g a
        scopeUniqueVar = error "you need to define a language-specific scopeUniqueVar function"

data Term a = Term a
    deriving(Eq, Ord, Show)

instance Evaluable Term where
    eval (Term x) = x

instance Liftable Term where
    lift = Term

data Form a = Form a
    deriving(Eq, Ord, Show)

instance Evaluable Form where
    eval (Form x) = x

instance Liftable Form where
    lift = Form

--------------------------------------------------------
--1.2.2 Non-Binding Operators
--------------------------------------------------------

-- | think of this as a type constraint. the lang type, model type, and number
-- must all match up for this type to be inhabited. This lets us do neat
-- type safty things
data Arity :: * -> * -> Nat -> * -> * where
    AZero :: Arity arg ret Zero ret
    ASucc :: Arity arg ret n ret' -> Arity arg ret (Succ n) (arg -> ret')

pattern AOne = ASucc AZero
pattern ATwo = ASucc AOne
pattern AThree = ASucc ATwo


arityInt :: Arity arg ret n ret' -> Int
arityInt AZero = 0
arityInt (ASucc n) = arityInt n + 1

instance Show (Arity arg ret n ret') where
        show = show . arityInt

data Predicate :: (* -> *) -> (* -> *) -> * -> * where
    Predicate :: pred t -> Arity (Term a) (Form b) n t -> Predicate pred lang t

data Connective :: (* -> *) -> (* -> *) -> * -> * where
    Connective :: con t -> Arity (Form a) (Form b) n t -> Connective con lang t

data Function :: (* -> *) -> (* -> *) -> * -> * where
    Function :: func t -> Arity (Term a) (Term b) n t -> Function func lang t

data Subnective :: (* -> *) -> (* -> *) -> * -> * where
    Subnective :: sub t -> Arity (Form a) (Term b) n t -> Subnective sub lang t

data SubstitutionalVariable :: (* -> *) -> * -> * where
        SubVar :: Int -> SubstitutionalVariable lang t
        StaticVar :: Int -> SubstitutionalVariable lang t

--------------------------------------------------------
--2. Schematizable, Show, and Eq
--------------------------------------------------------

instance Schematizable (SubstitutionalVariable lang)  where
        schematize (SubVar n) [] = "α_" ++ show n
        schematize (SubVar n) l = "α_" ++ show n ++ "(" ++ intercalate "," l ++ ")"
        schematize (StaticVar n) [] = "β_" ++ show n
        schematize (StaticVar n) l = "β_" ++ show n ++ "(" ++ intercalate "," l ++ ")"

instance Schematizable (EndLang lang) where
        schematize = undefined

instance (Schematizable (f a), Schematizable (g a)) => Schematizable ((f :|: g) a) where
        schematize (FLeft a) = schematize a
        schematize (FRight a) = schematize a

instance Schematizable (f (Fix f)) => Schematizable (Fix f) where
    schematize (Fx a) = schematize a

instance Schematizable bind => Schematizable (Binders bind lang) where
        schematize (Bind q) arg = schematize q arg --here I assume 'q' stores the users varible name

instance Schematizable abs => Schematizable (Abstractors abs lang) where
        schematize (Abstract a) arg = schematize a arg --here I assume 'q' stores the users varible name

instance Schematizable pred => Schematizable (Predicate pred lang) where
        schematize (Predicate p _) = schematize p

instance Schematizable con => Schematizable (Connective con lang) where
        schematize (Connective c _) = schematize c

instance Schematizable func => Schematizable (Function func lang) where
        schematize (Function f _) = schematize f

instance Schematizable app => Schematizable (Applicators app lang) where
        schematize (Apply f) = schematize f

instance Schematizable sub => Schematizable (Subnective sub lang) where
        schematize (Subnective s _) = schematize s

instance CopulaSchema lang => Schematizable (Copula lang) where
        schematize (f :$: x) e = appSchema f x e
        schematize (Lam f)   e = lamSchema f e
        schematize x         e = liftSchema x e

instance (Schematizable (f a), Schematizable (g a)) => Show ((f :|: g) a b) where
        show (FLeft a) = schematize a []
        show (FRight a) = schematize a []

instance Schematizable (f (Fix f)) => Show (Fix f idx) where
        show (Fx a) = schematize a []

instance Schematizable bind => Show (Binders bind lang a) where
        show x = schematize x []

instance Schematizable pred => Show (Predicate pred lang a) where
        show x = schematize x []

instance Schematizable con => Show (Connective con lang a) where
        show x = schematize x []

instance Schematizable func => Show (Function func lang a) where
        show x = schematize x []

instance Schematizable sub => Show (Subnective sub lang a) where
        show x = schematize x []

instance Schematizable bind => Eq (Binders bind lang a) where
        x == y = show x == show y

instance Schematizable pred => Eq (Predicate pred lang a) where
        x == y = show x == show y

instance Schematizable con => Eq (Connective con lang a) where
        x == y = show x == show y

instance Schematizable func => Eq (Function func lang a) where
        x == y = show x == show y

instance Schematizable sub => Eq (Subnective sub lang a) where
        x == y = show x == show y

instance (Schematizable (f a), Schematizable (g a)) => Eq ((f :|: g) a b) where
        x == y = show x == show y

--------------------------------------------------------
--3. Evaluation and Modelable
--------------------------------------------------------
instance Evaluable (SubstitutionalVariable lang)  where
        eval _ = error "It should not be possible to evaluate a substitutional variable"

instance Evaluable bind => Evaluable (Binders bind lang) where
    eval (Bind q) = eval q

instance Evaluable abs => Evaluable (Abstractors abs lang) where
    eval (Abstract a) = eval a

instance Evaluable pred => Evaluable (Predicate pred lang) where
    eval (Predicate p a) = eval p

instance Evaluable con => Evaluable (Connective con lang) where
    eval (Connective p a) = eval p

instance Evaluable func => Evaluable (Function func lang) where
    eval (Function p _) = eval p

instance Evaluable app => Evaluable (Applicators app lang) where
    eval (Apply f) = eval f

instance Evaluable sub => Evaluable (Subnective sub lang) where
    eval (Subnective p a) = eval p

instance Evaluable (EndLang lang) where
        eval = undefined

instance (Evaluable (f lang), Evaluable (g lang)) => Evaluable ((f :|: g) lang) where
    eval (FLeft p) = eval p
    eval (FRight p) = eval p

instance (Evaluable (f (Fix f))) => Evaluable (Fix f) where
    eval (Fx a) = eval a

instance Liftable (Fix (Copula :|: a)) where
    lift a = Fx $ FLeft (Lift a)

instance (Liftable lang, Evaluable lang) => Evaluable (Copula lang) where
    eval (f :$: x) = eval f (eval x)
    eval (Lam f)   = \t -> eval $ f (lift t)
    eval (Lift t)  = t

instance Modelable a (SubstitutionalVariable lang)  where
        satisfies _ = eval

instance Modelable m bind => Modelable m (Binders bind lang) where
    satisfies m (Bind q) = satisfies m q

instance Modelable m abs => Modelable m (Abstractors abs lang) where
    satisfies m (Abstract a) = satisfies m a

instance Modelable m pred => Modelable  m (Predicate pred lang) where
    satisfies m (Predicate p a) = satisfies m p

instance Modelable m con => Modelable m (Connective con lang) where
    satisfies m (Connective p a) = satisfies m p

instance Modelable m func => Modelable m (Function func lang) where
    satisfies m (Function p _) = satisfies m p

instance Modelable m app => Modelable m (Applicators app lang) where
    satisfies m (Apply p) = satisfies m p

instance Modelable m sub => Modelable m (Subnective sub lang) where
    satisfies m (Subnective p a) = satisfies m p

--dummy instance for a type with no constructors
instance Modelable m (EndLang lang) where
        satisfies = undefined

instance (Modelable m (f lang), Modelable m (g lang)) => Modelable m ((f :|: g) lang) where
    satisfies m (FLeft p) = satisfies m p
    satisfies m (FRight p) = satisfies m p

instance (Modelable m (f (Fix f))) => Modelable m (Fix f) where
    satisfies m (Fx a) = satisfies m a

instance (Liftable lang, Modelable m lang) => Modelable m (Copula lang) where
    satisfies m (f :$: x) = satisfies m f (satisfies m x)
    satisfies m (Lam f) = \t -> satisfies m $ f (lift t)
    satisfies m (Lift t) = t

--------------------------------------------------------
--4. First Order Lexicon
--------------------------------------------------------

class UniformlyEq f => FirstOrderLex f where
    isVarLex :: f a -> Bool
    isVarLex _ = False
    sameHeadLex :: f a -> f b -> Bool
    sameHeadLex = (=*)

class Monad m => MaybeMonadVar f m where
        maybeFresh :: Typeable a => Maybe (m (f a))
        maybeFresh = Nothing
        maybePig :: Maybe (m (EveryPig f))
        maybePig = Nothing

class MaybeStaticVar f where
        maybeStatic :: Typeable a => Maybe (Int -> f a)
        maybeStatic = Nothing

instance UniformlyEq (SubstitutionalVariable idx) where
        (SubVar n) =* (SubVar m) = n == m
        (StaticVar n) =* (StaticVar m) = n == m
        _ =* _ = False

instance FirstOrderLex (SubstitutionalVariable idx) where
        isVarLex (SubVar _) = True
        isVarLex (StaticVar _) = True

instance {-# OVERLAPPABLE #-} Monad m => MaybeMonadVar f m where
        maybeFresh = Nothing

instance {-# OVERLAPPABLE #-} MaybeStaticVar f where
        maybeStatic = Nothing

instance Monad m => MaybeMonadVar (SubstitutionalVariable idx) (S.StateT Int m)
        where maybeFresh = Just $ do n <- get
                                     put (n+1)
                                     return $ SubVar n

              maybePig = Just $ do n <- get
                                   put (n + 1)
                                   return $ EveryPig (SubVar n)

instance MaybeStaticVar (SubstitutionalVariable idx) 
        where maybeStatic = Just StaticVar

instance UniformlyEq bind => UniformlyEq (Binders bind lang) where
        (Bind q) =* (Bind q') = q =* q'

instance (UniformlyEq bind, FirstOrderLex bind) => FirstOrderLex (Binders bind lang) where
        isVarLex (Bind q) = isVarLex q

instance Monad m => MaybeMonadVar (Binders bind lang) m

instance MaybeStaticVar (Binders bind lang)

instance UniformlyEq app => UniformlyEq (Applicators app lang) where
        (Apply f) =* (Apply f') = f =* f'

instance (UniformlyEq app, FirstOrderLex app) => FirstOrderLex (Applicators app lang) where
        isVarLex (Apply f) = isVarLex f

instance Monad m => MaybeMonadVar (Applicators app lang) m

instance MaybeStaticVar (Applicators app lang)

instance UniformlyEq abs => UniformlyEq (Abstractors abs lang) where
        (Abstract a) =* (Abstract b) = a =* b

instance (UniformlyEq abs, FirstOrderLex abs) => FirstOrderLex (Abstractors abs lang) where
        isVarLex (Abstract a) = isVarLex a

instance Monad m => MaybeMonadVar (Abstractors app lang) m

instance MaybeStaticVar (Abstractors app lang)

instance UniformlyEq pred => UniformlyEq (Predicate pred lang) where
        (Predicate p a) =* (Predicate p' a') =
            arityInt a == arityInt a' && p =* p'

instance (UniformlyEq pred, FirstOrderLex pred) => FirstOrderLex (Predicate pred lang) where
        isVarLex (Predicate p a) = isVarLex p

instance Monad m => MaybeMonadVar (Predicate pred lang) m

instance MaybeStaticVar (Predicate pred lang)

instance UniformlyEq con => UniformlyEq (Connective con lang) where
        (Connective c a) =* (Connective c' a') =
            arityInt a == arityInt a' && c =* c'

instance (UniformlyEq con, FirstOrderLex con) => FirstOrderLex (Connective con lang) where
        isVarLex (Connective c a) = isVarLex c

instance Monad m => MaybeMonadVar (Connective con lang) m

instance MaybeStaticVar (Connective con lang)

instance UniformlyEq func => UniformlyEq (Function func lang) where
        (Function f a) =* (Function f' a') =
            arityInt a == arityInt a' && f =* f'

instance (UniformlyEq func, FirstOrderLex func) => FirstOrderLex (Function func lang) where
        isVarLex (Function f a) = isVarLex f

instance Monad m => MaybeMonadVar (Function func lang) m

instance MaybeStaticVar (Function func lang)

instance UniformlyEq sub => UniformlyEq (Subnective sub lang) where
        (Subnective s a) =* (Subnective s' a') =
            arityInt a == arityInt a' && s =* s'

instance FirstOrderLex sub => FirstOrderLex (Subnective sub lang) where
        isVarLex (Subnective s a) = isVarLex s

instance Monad m => MaybeMonadVar (Subnective sub lang) m

instance MaybeStaticVar (Subnective sub lang)

instance UniformlyEq (EndLang idx) where
        (=*) = undefined

instance FirstOrderLex (EndLang idx) where
        sameHeadLex = undefined

instance Monad m => MaybeMonadVar (EndLang idx) m

instance MaybeStaticVar (EndLang idx)

instance ( UniformlyEq (f idx)
         , UniformlyEq (g idx)) => UniformlyEq ((f :|: g) idx) where

        (FLeft a) =* (FLeft b) = a =* b
        (FRight a) =* (FRight b) = a =* b
        _ =* _ = False

instance ( UniformlyEq (f idx), UniformlyEq (g idx),
        FirstOrderLex (f idx) , FirstOrderLex (g idx)) => FirstOrderLex ((f :|: g) idx) where
        isVarLex (FLeft a) = isVarLex a
        isVarLex (FRight a) = isVarLex a

        sameHeadLex (FLeft x) (FLeft y) = sameHeadLex x y
        sameHeadLex (FRight x) (FRight y) = sameHeadLex x y
        sameHeadLex _ _ = False

instance (MaybeMonadVar (g idx) m, MaybeMonadVar (f idx) m) => MaybeMonadVar ((f :|: g) idx) m where
        maybeFresh = case (maybeFresh  :: Typeable a => Maybe (m (f idx a)), maybeFresh :: Typeable b => Maybe (m (g idx b))) of
                         (Just l ,_) -> Just $ fmap FLeft l
                         (_, Just r ) -> Just $ fmap FRight r
                         _ -> Nothing

        maybePig = case (maybePig :: Maybe (m (EveryPig (f idx))),  maybePig :: Maybe (m (EveryPig (g idx)))) of
                       (Just l,_ ) -> Just $ do p <- l
                                                return $ EveryPig (FLeft (unEveryPig p))
                       (_, Just r) -> Just $ do p <- r
                                                return $ EveryPig (FRight (unEveryPig p))

                       _ -> Nothing

instance (MaybeStaticVar (g idx), MaybeStaticVar (f idx)) => MaybeStaticVar ((f :|: g) idx) where
        maybeStatic = case (maybeStatic :: Typeable a => Maybe (Int -> (f idx a)), maybeStatic :: Typeable b => Maybe (Int -> (g idx b))) of
                         (Just l ,_) -> Just $ \n -> FLeft (l n)
                         (_, Just r ) -> Just $ \n -> FRight (r n)
                         _ -> Nothing

instance (UniformlyEq lang, FirstOrderLex lang) => UniformlyEq (Copula lang) where
        (h :$: t ) =* (h' :$: t') = h =* h' && t =* t'
        Lam g =* Lam h = error "sorry, can't directly compare these. Try the fixpoint."
        _ =* _ = False

instance (UniformlyEq (FixLang lex), FirstOrderLex (FixLang lex), StaticVar (FixLang lex)) => FirstOrderLex (Copula (FixLang lex))
        where

        sameHeadLex ((x :: (FixLang lex) (t1  -> t2 )) :$: _)
                    ((y :: (FixLang lex) (t1' -> t2')) :$: _) =
            case eqT :: Maybe ((t1 -> t2) :~: (t1' -> t2')) of
                Just Refl -> sameHeadLex x y
                Nothing -> False
        sameHeadLex (Lam (f  :: (FixLang lex) t1  -> (FixLang lex) t2))
                    (Lam (f' :: (FixLang lex) t1' -> (FixLang lex) t2')) =
            case (eqT :: Maybe (t1 :~: t1'), eqT :: Maybe (t2 :~: t2')) of
                (Just Refl, Just Refl) -> sameHeadLex (f $ static $ height $ LLam f) (f' $ static $ height $ LLam f) 
                    --the idea here is that we pick a scope-unique variable
                    --at each stage of the recursion, but that the variable
                    --is determined by the lhs---so two expressions with
                    --bound lambda variables in their heads will register
                    --as having the same head if that variable is the same
                    --argument, and otherwise not.
                _ -> False
        sameHeadLex _ _ = False

instance Monad m => MaybeMonadVar (Copula lang) m

instance MaybeStaticVar (Copula lang) 

instance {-# OVERLAPPABLE #-} (UniformlyEq ((Copula :|: f) (FixLang f))
         , MaybeStaticVar ((Copula :|: f) (FixLang f)))
         => UniformlyEq (FixLang f) where
             (x :!$: y) =* (x' :!$: y') = x =* x' && y =* y'
             x@(LLam (f :: FixLang f t1 -> FixLang f t1')) =* y@(LLam (g :: FixLang f t2 -> FixLang f t2')) = 
                    case (eqT :: Maybe (t1 :~: t2), maybeStatic :: Maybe (Int -> ((Copula :|: f) (FixLang f) t1))) of
                            (Just Refl, Just sv) -> (f $ Fx $ sv $ height x) =* (g $ Fx $ sv $ height y)
                            _ -> False
             Fx x =* Fx y = x =* y
             _ =* _ = False

instance (MaybeStaticVar (Copula (Fix (Copula :|: f))), 
          MaybeStaticVar (f (Fix (Copula :|: f))), 
          FirstOrderLex ((Copula :|: f) (FixLang f))) 
            => FirstOrderLex (FixLang f) where

        isVarLex (Fx x) = isVarLex x

        sameHeadLex (Fx x) (Fx y) = sameHeadLex x y

instance (Monad m, MaybeMonadVar ((Copula :|: f) (FixLang f)) m) => MonadVar (FixLang f) m where
        fresh = case maybeFresh :: Typeable a => Maybe (m (((Copula :|: f) (FixLang f)) a)) of
                    Just fsh -> fmap Fx fsh
                    Nothing -> error "you need substitutional variables in your language for this"

        freshPig = case maybePig :: Maybe (m (EveryPig ((Copula :|: f) (FixLang f)))) of
                    Just pig -> do p <- pig
                                   return $ EveryPig (Fx (unEveryPig p))

instance MaybeStaticVar ((Copula :|: f) (FixLang f)) => StaticVar (FixLang f) where
        static = case maybeStatic :: Typeable a => Maybe (Int -> (((Copula :|: f) (FixLang f)) a)) of
                    Just s -> \n -> Fx (s n)
                    Nothing -> error "you need static variables in your language for this"

instance {-# OVERLAPPABLE #-} 
        ( StaticVar (FixLang f)
        , FirstOrderLex (FixLang f)
        , UniformlyEq (FixLang f)) => FirstOrder (FixLang f) where

        isVar = isVarLex

        sameHead = sameHeadLex

        decompose (LLam (f :: FixLang f t1 -> FixLang f t2))
                  (LLam (f' :: FixLang f t1' -> FixLang f t2')) = 
            case (eqT :: Maybe (t1 :~: t1'), eqT :: Maybe (t2 :~: t2')) of
                (Just Refl, Just Refl) -> map reabstract (decompose (f sv) (f' sv'))
                _ -> []
            where reabstract (t:=:t') = (LLam $ \x -> subst sv x t) :=: (LLam $ \x -> subst sv' x t')

                  sv = static (height (LLam f))

                  sv' = static (height (LLam f'))

        decompose a b
            | sameHead a b = recur a b []
            | otherwise = []
            where recur :: FixLang f a -> FixLang f b -> [Equation (FixLang f)]
                    ->[Equation (FixLang f)]
                  recur (x :!$: (y :: FixLang f t))
                        (x' :!$: (y' :: FixLang f t'))
                        terms = case eqT :: Maybe (t :~: t') of
                                    Just Refl -> recur x x' ((y :=: y') : terms)
                                    Nothing -> []
                  recur _ _ terms = terms

        occurs phi psi@(x :!$: y)= occursImproperly phi x || occursImproperly phi y
            where occursImproperly :: FixLang f a -> FixLang f b -> Bool
                  occursImproperly phi psi@(x :!$: y) = phi =* psi
                                                         || occursImproperly phi x
                                                         || occursImproperly phi y
                  occursImproperly phi psi = phi =* psi
        --might want a clause for LLam
        occurs phi psi = False

        subst a@(Fx _ :: FixLang f t) b@(Fx _ :: FixLang f t') c@(Fx _ :: FixLang f t'')
            | a =* c = case eqT :: Maybe (t' :~: t'') of
                           Just Refl -> b
                           Nothing -> c
            | otherwise = case c of
                           (x :!$: y) -> subst a b x :!$: subst a b y
                           (LLam f) -> LLam $ subst a b . f 
                           -- XXX : above is *much* faster than below under
                           -- binders.
                           -- (LLam f) -> LLam $ \x -> subst sv x $ subst a b $ f sv
                           --      where sv = static $ height (LLam f)
                           _ -> c

instance {-# OVERLAPPABLE #-} FirstOrder (FixLang f) => HigherOrder (FixLang f) where

    matchApp (x :!$: y) = Just (ExtApp x y)
    matchApp _ = Nothing 

    castLam (LLam g :: FixLang f a ) = Just (ExtLam g (Refl :: a :~: a ))
    castLam _ = Nothing 

    (.$.) = (:!$:)
    
    lam = LLam

instance Typeable a => EtaExpand (FixLang f) (Form a)

instance Typeable a => EtaExpand (FixLang f) (Term a)

--------------------------------------------------------
--6 Utility Functions
--------------------------------------------------------
--Auxiluary functions useful for defining the functions and classes that we
--eventually export

height :: StaticVar (FixLang f) => FixLang f a -> Int
height (x :!$: y) = max (height x) (height y) + 1 
height x@(LLam (f :: FixLang f t3 -> FixLang f t3')) =  height (f $ static 0) + 1
height _ = 0
