{-#LANGUAGE MultiParamTypeClasses, ConstraintKinds, DataKinds, UndecidableInstances, FunctionalDependencies, RankNTypes, FlexibleContexts, FlexibleInstances, TypeSynonymInstances, TypeOperators, GADTs, ScopedTypeVariables #-}
module Carnap.Languages.Util.LanguageClasses where

import Carnap.Core.Data.AbstractSyntaxDataTypes
import Carnap.Core.Data.Optics
import Carnap.Core.Data.Util (incArity)
import Carnap.Core.Util (Nat(Zero))
import Carnap.Languages.Util.GenericConstructors
import Data.Typeable
import Control.Lens (Prism', prism',review,only)


--The convention for variables in this module is that lex is
--a lexicon, lang is language (without a particular associated syntactic
--type) and l is a language with an associated syntactic type

--------------------------------------------------------
--1. Constructor classes
--------------------------------------------------------

--------------------------------------------------------
--1.1 Connectives
--------------------------------------------------------

--these are classes for languages and with boolean connectives. 
class BooleanLanguage l where
            lneg :: l -> l
            land :: l -> l -> l
            lor  :: l -> l -> l
            lif  :: l -> l -> l
            liff :: l -> l -> l
            (.¬.) :: l -> l 
            (.¬.) = lneg
            (.-.) :: l -> l 
            (.-.) = lneg
            (.→.) :: l -> l -> l
            (.→.) = lif
            (.=>.) :: l -> l -> l
            (.=>.) = lif
            (.∧.) :: l -> l -> l
            (.∧.) = land
            (./\.) :: l -> l -> l
            (./\.) = land
            (.∨.) :: l -> l -> l
            (.∨.) = lor
            (.\/.) :: l -> l -> l
            (.\/.) = lor
            (.↔.) :: l -> l -> l
            (.↔.) = liff
            (.<=>.) :: l -> l -> l
            (.<=>.) = liff

class (Typeable b, PrismLink (FixLang lex) (Connective (BooleanConn b) (FixLang lex))) 
        => PrismBooleanConnLex lex b where

        _and :: Prism' (FixLang lex (Form b -> Form b -> Form b)) ()
        _and = binarylink_PrismBooleanConnLex . andPris 

        _or :: Prism' (FixLang lex (Form b -> Form b -> Form b)) ()
        _or = binarylink_PrismBooleanConnLex . orPris 

        _if :: Prism' (FixLang lex (Form b -> Form b -> Form b)) ()
        _if = binarylink_PrismBooleanConnLex . ifPris 

        _iff :: Prism' (FixLang lex (Form b -> Form b -> Form b)) ()
        _iff = binarylink_PrismBooleanConnLex . iffPris 

        _not :: Prism' (FixLang lex (Form b -> Form b)) ()
        _not = unarylink_PrismBooleanConnLex . notPris 

        binarylink_PrismBooleanConnLex :: 
            Prism' (FixLang lex (Form b -> Form b -> Form b)) 
                   (Connective (BooleanConn b) (FixLang lex) (Form b -> Form b -> Form b))
        binarylink_PrismBooleanConnLex = link 

        unarylink_PrismBooleanConnLex :: 
            Prism' (FixLang lex (Form b -> Form b)) 
                   (Connective (BooleanConn b) (FixLang lex) (Form b -> Form b))
        unarylink_PrismBooleanConnLex = link 

        andPris :: Prism' (Connective (BooleanConn b) (FixLang lex) (Form b -> Form b -> Form b)) ()
        andPris = prism' (\_ -> Connective And ATwo) 
                          (\x -> case x of Connective And ATwo -> Just (); _ -> Nothing)

        orPris :: Prism' (Connective (BooleanConn b) (FixLang lex) (Form b -> Form b -> Form b)) ()
        orPris = prism' (\_ -> Connective Or ATwo) 
                         (\x -> case x of Connective Or ATwo -> Just (); _ -> Nothing)

        ifPris :: Prism' (Connective (BooleanConn b) (FixLang lex) (Form b -> Form b -> Form b)) ()
        ifPris = prism' (\_ -> Connective If ATwo) 
                         (\x -> case x of Connective If ATwo -> Just (); _ -> Nothing)

        iffPris :: Prism' (Connective (BooleanConn b) (FixLang lex) (Form b -> Form b -> Form b)) ()
        iffPris = prism' (\_ -> Connective Iff ATwo) 
                          (\x -> case x of Connective Iff ATwo -> Just (); _ -> Nothing)

        notPris :: Prism' (Connective (BooleanConn b) (FixLang lex) (Form b -> Form b)) ()
        notPris = prism' (\_ -> Connective Not AOne) 
                          (\x -> case x of Connective Not AOne -> Just (); _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismBooleanConnLex lex b => BooleanLanguage (FixLang lex (Form b)) where
        lneg = review (unaryOpPrism _not)
        land = curry $ review (binaryOpPrism _and)
        lor  = curry $ review (binaryOpPrism _or)
        lif  = curry $ review (binaryOpPrism _if)
        liff = curry $ review (binaryOpPrism _iff)

class IndexedPropContextSchemeLanguage l where
            propCtx :: Int -> l -> l

class (Typeable b, Typeable c, PrismLink (FixLang lex) (Connective (GenericContext b c) (FixLang lex))) 
        => PrismGenericContext lex b c where

        _contextIdx :: Prism' (FixLang lex (Form b -> Form c)) Int
        _contextIdx = link_GenericContext . contextIdx

        link_GenericContext :: Prism' (FixLang lex (Form b -> Form c)) 
                                            (Connective (GenericContext b c) (FixLang lex) (Form b -> Form c))
        link_GenericContext = link 

        contextIdx :: Prism' (Connective (GenericContext b c) (FixLang lex) (Form b -> Form c)) Int
        contextIdx = prism' (\n -> Connective (Context n) AOne) 
                            (\x -> case x of Connective (Context n) AOne -> Just n
                                             _ -> Nothing)

type PrismPropositionalContext lex b = PrismGenericContext lex b b

instance {-#OVERLAPPABLE#-} PrismPropositionalContext lex b => IndexedPropContextSchemeLanguage (FixLang lex (Form b)) where
        propCtx n = review (unaryOpPrism (_contextIdx . only n))

class ModalLanguage l where
        nec :: l -> l
        pos :: l -> l

class (Typeable b, PrismLink (FixLang lex) (Connective (Modality b) (FixLang lex))) 
        => PrismModality lex b where

        _nec :: Prism' (FixLang lex (Form b -> Form b)) ()
        _nec = link_PrismModality . necPris

        _pos :: Prism' (FixLang lex (Form b -> Form b)) ()
        _pos = link_PrismModality . posPris 

        link_PrismModality :: 
            Prism' (FixLang lex (Form b -> Form b)) 
                   (Connective (Modality b) (FixLang lex) (Form b -> Form b))
        link_PrismModality = link 

        necPris :: Prism' (Connective (Modality b) (FixLang lex) (Form b -> Form b)) ()
        necPris = prism' (\_ -> Connective Box AOne) 
                          (\x -> case x of Connective Box AOne -> Just (); _ -> Nothing)

        posPris :: Prism' (Connective (Modality b) (FixLang lex) (Form b -> Form b)) ()
        posPris = prism' (\_ -> Connective Diamond AOne) 
                          (\x -> case x of Connective Diamond AOne -> Just (); _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismModality lex b => ModalLanguage (FixLang lex (Form b)) where
        nec = review (unaryOpPrism _nec)
        pos = review (unaryOpPrism _pos)

class BooleanConstLanguage l where 
        lverum :: l
        lfalsum :: l

class (Typeable b, PrismLink (FixLang lex) (Connective (BooleanConst b) (FixLang lex))) 
        => PrismBooleanConst lex b where

        _verum :: Prism' (FixLang lex (Form b)) ()
        _verum = link_BooleanConst . verumPris

        _falsum :: Prism' (FixLang lex (Form b)) ()
        _falsum = link_BooleanConst . falsumPris

        link_BooleanConst :: 
            Prism' (FixLang lex (Form b)) 
                   (Connective (BooleanConst b) (FixLang lex) (Form b))
        link_BooleanConst = link 

        verumPris :: Prism' (Connective (BooleanConst b) (FixLang lex) (Form b)) ()
        verumPris = prism' (\_ -> Connective Verum AZero) 
                          (\x -> case x of Connective Verum AZero -> Just (); _ -> Nothing)

        falsumPris :: Prism' (Connective (BooleanConst b) (FixLang lex) (Form b)) ()
        falsumPris = prism' (\_ -> Connective Falsum AZero) 
                          (\x -> case x of Connective Falsum AZero -> Just (); _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismBooleanConst lex b => BooleanConstLanguage (FixLang lex (Form b)) where
        lverum = review _verum ()
        lfalsum = review _falsum ()

--------------------------------------------------------
--1.2 Propositions
--------------------------------------------------------

--------------------------------------------------------
--1.2.1 Propositional Languages
--------------------------------------------------------
--languages with propositions

class IndexedPropLanguage l where
        pn :: Int -> l

class (Typeable b, PrismLink (FixLang lex) (Predicate (IntProp b) (FixLang lex))) 
        => PrismPropLex lex b where

        propIndex :: Prism' (FixLang lex (Form b)) Int
        propIndex = link_PrismPropLex . propIndex'

        link_PrismPropLex :: Prism' (FixLang lex (Form b)) (Predicate (IntProp b) (FixLang lex) (Form b))
        link_PrismPropLex = link 

        propIndex' :: Prism' (Predicate (IntProp b) (FixLang lex) (Form b)) Int
        propIndex' = prism' (\n -> Predicate (Prop n) AZero) 
                            (\x -> case x of Predicate (Prop n) AZero -> Just n
                                             _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismPropLex lex b => IndexedPropLanguage (FixLang lex (Form b)) where
        pn = review propIndex

class IndexedSchemePropLanguage l where
        phin :: Int -> l

class (Typeable b, PrismLink (FixLang lex) (Predicate (SchematicIntProp b) (FixLang lex))) 
        => PrismSchematicProp lex b where

        _sPropIdx :: Prism' (FixLang lex (Form b)) Int
        _sPropIdx = link_PrismSchematicProp . sPropIdx

        link_PrismSchematicProp :: Prism' (FixLang lex (Form b)) (Predicate (SchematicIntProp b) (FixLang lex) (Form b))
        link_PrismSchematicProp = link 

        sPropIdx :: Prism' (Predicate (SchematicIntProp b) (FixLang lex) (Form b)) Int
        sPropIdx = prism' (\n -> Predicate (SProp n) AZero) 
                           (\x -> case x of Predicate (SProp n) AZero -> Just n
                                            _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismSchematicProp lex b => IndexedSchemePropLanguage (FixLang lex (Form b)) where
        phin = review _sPropIdx

--------------------------------------------------------
--1.2.2 Predicate Languages
--------------------------------------------------------
--languages with predicates

class PolyadicPredicateLanguage lang arg ret where
        ppn :: Typeable ret' => Int -> Arity arg ret n ret' -> lang ret'

class (Typeable c, Typeable b, PrismLink (FixLang lex) (Predicate (IntPred b c) (FixLang lex))) 
        => PrismPolyadicPredicate lex c b where

        _predIdx :: Typeable ret => Arity (Term c) (Form b) n ret -> Prism' (FixLang lex ret) Int
        _predIdx a = link_PrismPolyadicPredicate . (predIndex a)

        link_PrismPolyadicPredicate :: Typeable ret => Prism' (FixLang lex ret) (Predicate (IntPred b c) (FixLang lex) ret)
        link_PrismPolyadicPredicate = link 

        predIndex :: Arity (Term c) (Form b) n ret -> Prism' (Predicate (IntPred b c) (FixLang lex) ret) Int
        predIndex a = prism' (\n -> Predicate (Pred a n) a) 
                             (\x -> case x of (Predicate (Pred a' n) a'') | arityInt a == arityInt a' -> Just n
                                              _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismPolyadicPredicate lex c b => PolyadicPredicateLanguage (FixLang lex) (Term c) (Form b) where
        ppn n a = review (_predIdx a) n

class PolyadicSchematicPredicateLanguage lang arg ret where
        pphin :: Typeable ret' => Int -> Arity arg ret n ret' -> lang ret'

class (Typeable c, Typeable b, PrismLink (FixLang lex) (Predicate (SchematicIntPred b c) (FixLang lex))) 
        => PrismPolyadicSchematicPredicate lex c b where

        _spredIdx :: Typeable ret => Arity (Term c) (Form b) n ret -> Prism' (FixLang lex ret) Int
        _spredIdx a = link_PrismPolyadicSchematicPredicate . (spredIndex a)

        link_PrismPolyadicSchematicPredicate :: Typeable ret => Prism' (FixLang lex ret) (Predicate (SchematicIntPred b c) (FixLang lex) ret)
        link_PrismPolyadicSchematicPredicate = link 

        spredIndex :: Arity (Term c) (Form b) n ret -> Prism' (Predicate (SchematicIntPred b c) (FixLang lex) ret) Int
        spredIndex a = prism' (\n -> Predicate (SPred a n) a) 
                             (\x -> case x of (Predicate (SPred a' n) a'') | arityInt a == arityInt a' -> Just n
                                              _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismPolyadicSchematicPredicate lex c b => PolyadicSchematicPredicateLanguage (FixLang lex) (Term c) (Form b) where
        pphin n a = review (_spredIdx a) n

class EqLanguage lang arg ret where
        equals :: lang arg -> lang arg -> lang ret 

class (Typeable c, Typeable b, PrismLink (FixLang lex) (Predicate (TermEq b c) (FixLang lex))) 
        => PrismTermEquality lex c b where

        _termEq :: Prism' (FixLang lex (Term c -> Term c -> Form b)) ()
        _termEq = link_TermEquality . termEq

        link_TermEquality :: Prism' (FixLang lex (Term c -> Term c -> Form b)) 
                                    (Predicate (TermEq b c) (FixLang lex) (Term c -> Term c -> Form b))
        link_TermEquality = link 

        termEq :: Prism' (Predicate (TermEq b c) (FixLang lex) (Term c -> Term c -> Form b)) ()
        termEq = prism' (\n -> Predicate TermEq ATwo) 
                           (\x -> case x of Predicate TermEq ATwo -> Just ()
                                            _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismTermEquality lex c b => EqLanguage (FixLang lex) (Term c) (Form b) where
        equals = curry $ review (binaryOpPrism _termEq)

class ElemLanguage lang arg ret where
        isIn :: lang arg -> lang arg -> lang ret 

class (Typeable c, Typeable b, PrismLink (FixLang lex) (Predicate (TermElem b c) (FixLang lex))) 
        => PrismTermElements lex c b where

        _termElem :: Prism' (FixLang lex (Term c -> Term c -> Form b)) ()
        _termElem = link_TermElement . termElem

        link_TermElement :: Prism' (FixLang lex (Term c -> Term c -> Form b)) 
                                    (Predicate (TermElem b c) (FixLang lex) (Term c -> Term c -> Form b))
        link_TermElement = link 

        termElem :: Prism' (Predicate (TermElem b c) (FixLang lex) (Term c -> Term c -> Form b)) ()
        termElem = prism' (\n -> Predicate TermElem ATwo) 
                           (\x -> case x of Predicate TermElem ATwo -> Just ()
                                            _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismTermElements lex c b => ElemLanguage (FixLang lex) (Term c) (Form b) where
        isIn = curry $ review (binaryOpPrism _termElem)

class SubsetLanguage lang arg ret where
        within :: lang arg -> lang arg -> lang ret 

class (Typeable c, Typeable b, PrismLink (FixLang lex) (Predicate (TermSubset b c) (FixLang lex))) 
        => PrismTermSubset lex c b where

        _termSubset :: Prism' (FixLang lex (Term c -> Term c -> Form b)) ()
        _termSubset = link_TermSubset . termSubset

        link_TermSubset :: Prism' (FixLang lex (Term c -> Term c -> Form b)) 
                                    (Predicate (TermSubset b c) (FixLang lex) (Term c -> Term c -> Form b))
        link_TermSubset = link 

        termSubset :: Prism' (Predicate (TermSubset b c) (FixLang lex) (Term c -> Term c -> Form b)) ()
        termSubset = prism' (\n -> Predicate TermSubset ATwo) 
                            (\x -> case x of Predicate TermSubset ATwo -> Just ()
                                             _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismTermSubset lex c b => SubsetLanguage (FixLang lex) (Term c) (Form b) where
        within = curry $ review (binaryOpPrism _termSubset)

--------------------------------------------------------
--1.3. Terms
--------------------------------------------------------

class IndexedConstantLanguage l where
        cn :: Int -> l

class (Typeable b, PrismLink (FixLang lex) (Function (IntConst b) (FixLang lex))) 
        => PrismIndexedConstant lex b where

        _constIdx :: Prism' (FixLang lex (Term b)) Int
        _constIdx = link_IndexedConstant . constIndex

        link_IndexedConstant :: Prism' (FixLang lex (Term b)) (Function (IntConst b) (FixLang lex) (Term b))
        link_IndexedConstant = link 

        constIndex :: Prism' (Function (IntConst b) (FixLang lex) (Term b)) Int
        constIndex = prism' (\n -> Function (Constant n) AZero) 
                            (\x -> case x of Function (Constant n) AZero -> Just n
                                             _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismIndexedConstant lex b => IndexedConstantLanguage (FixLang lex (Term b)) where
       cn = review _constIdx

class IndexLanguage l where
        intIdx :: Int -> l

class (Typeable b, PrismLink (FixLang lex) (Function (IntIndex b) (FixLang lex))) 
        => PrismIntIndex lex b where

        _intIdx :: Prism' (FixLang lex (Term b)) Int
        _intIdx = link_IntIndex . intIndex

        link_IntIndex :: Prism' (FixLang lex (Term b)) (Function (IntIndex b) (FixLang lex) (Term b))
        link_IntIndex = link 

        intIndex :: Prism' (Function (IntIndex b) (FixLang lex) (Term b)) Int
        intIndex = prism' (\n -> Function (Index n) AZero) 
                            (\x -> case x of Function (Index n) AZero -> Just n
                                             _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismIntIndex lex b => IndexLanguage (FixLang lex (Term b)) where
       intIdx = review _intIdx

class PolyadicFunctionLanguage lang arg ret where
        pfn :: Typeable ret' => Int -> Arity arg ret n ret' -> lang ret'

class (Typeable c, Typeable b, PrismLink (FixLang lex) (Function (IntFunc b c) (FixLang lex))) 
        => PrismPolyadicFunction lex c b where

        _funcIdx :: Typeable ret => Arity (Term c) (Term b) n ret -> Prism' (FixLang lex ret) Int
        _funcIdx a = link_PrismPolyadicFunction . (funcIndex a)

        link_PrismPolyadicFunction :: Typeable ret => Prism' (FixLang lex ret) (Function (IntFunc b c) (FixLang lex) ret)
        link_PrismPolyadicFunction = link 

        funcIndex :: Arity (Term c) (Term b) n ret -> Prism' (Function (IntFunc b c) (FixLang lex) ret) Int
        funcIndex a = prism' (\n -> Function (Func a n) a) 
                             (\x -> case x of (Function (Func a' n) a'') | arityInt a == arityInt a' -> Just n
                                              _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismPolyadicFunction lex c b => PolyadicFunctionLanguage (FixLang lex) (Term c) (Term b) where
        pfn n a = review (_funcIdx a) n

class IndexedSchemeConstantLanguage l where
        taun :: Int -> l

class SchematicPolyadicFunctionLanguage lang arg ret where
        spfn :: Typeable ret' => Int -> Arity arg ret n ret' -> lang ret'

class (Typeable c, Typeable b, PrismLink (FixLang lex) (Function (SchematicIntFunc b c) (FixLang lex))) 
        => PrismPolyadicSchematicFunction lex c b where

        _sfuncIdx :: Typeable ret => Arity (Term c) (Term b) n ret -> Prism' (FixLang lex ret) Int
        _sfuncIdx a = link_PrismPolyadicSchematicFunction . (sfuncIndex a)

        link_PrismPolyadicSchematicFunction :: Typeable ret => Prism' (FixLang lex ret) (Function (SchematicIntFunc b c) (FixLang lex) ret)
        link_PrismPolyadicSchematicFunction = link 

        sfuncIndex :: Arity (Term c) (Term b) n ret -> Prism' (Function (SchematicIntFunc b c) (FixLang lex) ret) Int
        sfuncIndex a = prism' (\n -> Function (SFunc a n) a) 
                             (\x -> case x of (Function (SFunc a' n) a'') | arityInt a == arityInt a' -> Just n
                                              _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismPolyadicSchematicFunction lex c b => SchematicPolyadicFunctionLanguage (FixLang lex) (Term c) (Term b) where
        spfn n a = review (_sfuncIdx a) n

class ElementarySetsLanguage l where
            powerset :: l -> l
            setIntersect :: l -> l -> l
            setUnion :: l -> l -> l
            setComplement :: l -> l -> l

class (Typeable b, PrismLink (FixLang lex) (Function (ElementarySetOperations b) (FixLang lex))) 
        => PrismElementarySetsLex lex b where

        _powerset :: Prism' (FixLang lex (Term b -> Term b)) ()
        _powerset = unarylink_ElementarySetsLex . powersetPris 

        _setIntersect :: Prism' (FixLang lex (Term b -> Term b -> Term b)) ()
        _setIntersect = binarylink_ElementarySetsLex . setIntersectPris 

        _setUnion :: Prism' (FixLang lex (Term b -> Term b -> Term b)) ()
        _setUnion = binarylink_ElementarySetsLex . setUnionPris 

        _setComplement :: Prism' (FixLang lex (Term b -> Term b -> Term b)) ()
        _setComplement = binarylink_ElementarySetsLex . setComplementPris 

        binarylink_ElementarySetsLex :: 
            Prism' (FixLang lex (Term b -> Term b -> Term b)) 
                   (Function (ElementarySetOperations b) (FixLang lex) (Term b -> Term b -> Term b))
        binarylink_ElementarySetsLex = link 

        unarylink_ElementarySetsLex :: 
            Prism' (FixLang lex (Term b -> Term b)) 
                   (Function (ElementarySetOperations b) (FixLang lex) (Term b -> Term b))
        unarylink_ElementarySetsLex = link 

        setIntersectPris :: Prism' (Function (ElementarySetOperations b) (FixLang lex) (Term b -> Term b -> Term b)) ()
        setIntersectPris = prism' (\_ -> Function Intersection ATwo) 
                          (\x -> case x of Function Intersection ATwo -> Just (); _ -> Nothing)

        setUnionPris :: Prism' (Function (ElementarySetOperations b) (FixLang lex) (Term b -> Term b -> Term b)) ()
        setUnionPris = prism' (\_ -> Function Union ATwo) 
                         (\x -> case x of Function Union ATwo -> Just (); _ -> Nothing)

        setComplementPris :: Prism' (Function (ElementarySetOperations b) (FixLang lex) (Term b -> Term b -> Term b)) ()
        setComplementPris = prism' (\_ -> Function RelComplement ATwo) 
                         (\x -> case x of Function RelComplement ATwo -> Just (); _ -> Nothing)

        powersetPris :: Prism' (Function (ElementarySetOperations b) (FixLang lex) (Term b -> Term b)) ()
        powersetPris = prism' (\_ -> Function Powerset AOne) 
                          (\x -> case x of Function Powerset AOne -> Just (); _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismElementarySetsLex lex b => ElementarySetsLanguage (FixLang lex (Term b)) where
        powerset = review (unaryOpPrism _powerset)
        setIntersect = curry $ review (binaryOpPrism _setIntersect)
        setUnion = curry $ review (binaryOpPrism _setUnion)
        setComplement = curry $ review (binaryOpPrism _setComplement)

--------------------------------------------------------
--1.4. Variable Binding Operators
--------------------------------------------------------

class QuantLanguage l t where
        lall  :: String -> (t -> l) -> l
        lsome :: String -> (t -> l) -> l

type PrismStandardQuant lex = PrismGenericQuant lex Term Form

instance {-#OVERLAPPABLE#-} 
        (PrismGenericQuant lex f g b c) => QuantLanguage (FixLang lex (g b)) (FixLang lex (f c)) where
        lall s = review (unaryOpPrism (_all . only s)) . LLam 
        lsome s = review (unaryOpPrism (_some . only s)) . LLam

class (Typeable b, Typeable c, Typeable f, Typeable g, PrismLink (FixLang lex) (Binders (GenericQuant f g b c) (FixLang lex))) 
        => PrismGenericQuant lex f g b c where

        _all :: Prism' (FixLang lex ((f c -> g b) -> g b)) String
        _all = link_standardQuant . qall

        _some :: Prism' (FixLang lex ((f c -> g b) -> g b)) String
        _some = link_standardQuant . qsome

        link_standardQuant :: Prism' (FixLang lex ((f c -> g b) -> g b)) 
                               (Binders (GenericQuant f g b c) (FixLang lex) ((f c -> g b) -> g b))
        link_standardQuant = link 

        qall :: Prism' (Binders (GenericQuant f g b c) (FixLang lex) ((f c -> g b) -> g b)) String
        qall = prism' (\s -> Bind (All s))
                      (\x -> case x of (Bind (All s)) -> Just s
                                       _ -> Nothing)

        qsome :: Prism' (Binders (GenericQuant f g b c) (FixLang lex) ((f c -> g b) -> g b)) String
        qsome = prism' (\s -> Bind (Some s))
                       (\x -> case x of (Bind (Some s)) -> Just s
                                        _ -> Nothing)

class TypedLambdaLanguage lex f g b where
        typedLam :: Typeable c => String -> (FixLang lex (f b) -> FixLang lex (g c)) -> FixLang lex (g (b -> c))

class (Typeable b, Typeable f, Typeable g,  PrismLink (FixLang lex) (Abstractors (GenericTypedLambda f g b) (FixLang lex))) 
        => PrismGenericTypedLambda lex f g b where

        _tlam :: Typeable c => Prism' (FixLang lex ((f b -> g c) -> g (b -> c))) String
        _tlam = link_typedLambda . tlam

        link_typedLambda :: Typeable c => Prism' (FixLang lex ((f b -> g c) -> g (b -> c))) 
                               (Abstractors (GenericTypedLambda f g b) (FixLang lex) ((f b -> g c) -> g (b -> c)))
        link_typedLambda = link 

        tlam :: Typeable c => Prism' (Abstractors (GenericTypedLambda f g b) (FixLang lex) ((f b -> g c) -> g (b -> c))) String
        tlam = prism' (\s -> Abstract (TypedLambda s))
                      (\x -> case x of (Abstract (TypedLambda s)) -> Just s; _ -> Nothing)

instance {-#OVERLAPPABLE#-} 
        (PrismGenericTypedLambda lex f g b) => TypedLambdaLanguage lex f g b where
            typedLam s = review (unaryOpPrism (_tlam . only s)) . LLam

class RescopingLanguage l t where
        scope :: String -> t -> (t -> l) -> l

class (Typeable b, Typeable c, Typeable f, Typeable g,  PrismLink (FixLang lex) (RescopingOperator f g b c (FixLang lex))) 
        => PrismRescoping lex f g b c where

        _rescope :: Prism' (FixLang lex (f b -> (f b -> g c) -> g c)) String
        _rescope = link_rescope . rescope

        link_rescope :: Prism' (FixLang lex (f b -> (f b -> g c) -> g c)) 
                               (RescopingOperator f g b c (FixLang lex) (f b -> (f b -> g c) -> g c))
        link_rescope = link 

        rescope :: Typeable c => Prism' (RescopingOperator f g b c (FixLang lex) (f b -> (f b -> g c) -> g c)) String
        rescope = prism' (\s -> Rescope s)
                      (\x -> case x of Rescope s -> Just s; _ -> Nothing)

instance {-#OVERLAPPABLE#-}
        (PrismRescoping lex f g b c) => RescopingLanguage (FixLang lex (g c)) (FixLang lex (f b)) where
            scope s t f = curry (review (binaryOpPrism (_rescope . only s))) t (LLam f)

class DefinDescLanguage l t where
        ddesc :: String -> (t -> l) -> t

class (Typeable b, Typeable c, PrismLink (FixLang lex) (Binders (DefiniteDescription b c) (FixLang lex))) 
        => PrismDefiniteDesc lex b c where

        _desc:: Prism' (FixLang lex ((Term c -> Form b) -> Term c)) String
        _desc = link_definDesc . desc

        link_definDesc :: Prism' (FixLang lex ((Term c -> Form b) -> Term c)) 
                               (Binders (DefiniteDescription b c) (FixLang lex) ((Term c -> Form b) -> Term c))
        link_definDesc = link 

        desc :: Prism' (Binders (DefiniteDescription b c) (FixLang lex) ((Term c -> Form b) -> Term c)) String
        desc = prism' (\s -> Bind (DefinDesc s))
                      (\x -> case x of (Bind (DefinDesc s)) -> Just s
                                       _ -> Nothing)

instance {-#OVERLAPPABLE#-}
        PrismDefiniteDesc lex b c => DefinDescLanguage (FixLang lex (Form b)) (FixLang lex (Term c)) where
            ddesc s = review (unaryOpPrism (_desc . only s)) . LLam

-------------------
--  1.5 Exotica  --
-------------------

class IndexingLang lex index indexed unindexed | lex -> index indexed unindexed where
    atWorld :: FixLang lex unindexed -> FixLang lex index -> FixLang lex indexed
    (./.) :: FixLang lex unindexed -> FixLang lex index -> FixLang lex indexed
    (./.) = atWorld
    world :: Int -> FixLang lex index
    worldScheme :: Int -> FixLang lex index

instance {-#OVERLAPPABLE#-} 
        (PrismIndexing lex a b c, PrismIntIndex lex a, PrismPolyadicSchematicFunction lex a a
        ) => IndexingLang lex (Term a) (Form c) (Form b) where
       atWorld = curry (review $ binaryOpPrism _indexer)
       world = review _intIdx
       worldScheme = review (_sfuncIdx (AZero :: Arity (Term a) (Term a) Zero (Term a)))

class (Typeable a, Typeable b, Typeable c, PrismLink (FixLang lex) (Indexer a b c (FixLang lex))) 
        => PrismIndexing lex a b c | lex -> a b c where

        _indexer :: Prism' (FixLang lex (Form b -> Term a -> Form c)) ()
        _indexer = link_indexer . indexer

        link_indexer :: Prism' (FixLang lex (Form b -> Term a -> Form c)) 
                               (Indexer a b c (FixLang lex) (Form b -> Term a -> Form c))
        link_indexer = link 

        indexer :: Prism' (Indexer a b c (FixLang lex) (Form b -> Term a -> Form c)) ()
        indexer = prism' (const AtIndex) (const (Just ()))

class IndexConsLang lang index where
        indexcons :: lang index -> lang index -> lang index

instance {-#OVERLAPPABLE#-} PrismCons lex b => IndexConsLang (FixLang lex) (Term b) where
        indexcons = curry $ review (binaryOpPrism _cons)

class (Typeable b, PrismLink (FixLang lex) (Function (Cons b) (FixLang lex))) 
        => PrismCons lex b where

        _cons :: Prism' (FixLang lex (Term b -> Term b -> Term b)) ()
        _cons = link_cons . cons

        link_cons :: Prism' (FixLang lex (Term b -> Term b -> Term b)) 
                            (Function (Cons b) (FixLang lex) (Term b -> Term b -> Term b))
        link_cons = link 

        cons :: Prism' (Function (Cons b) (FixLang lex) (Term b -> Term b -> Term b)) ()
        cons = prism' (const (Function Cons ATwo )) (const (Just ()))

class AccessorLanguage l t where
        accesses :: t -> t -> l

class (Typeable c, Typeable b, PrismLink (FixLang lex) (Predicate (Accessor b c) (FixLang lex))) 
        => PrismAccessor lex c b where

        _access :: Prism' (FixLang lex (Term c -> Term c -> Form b)) ()
        _access = link_Accessor . access

        link_Accessor :: Prism' (FixLang lex (Term c -> Term c -> Form b)) 
                                    (Predicate (Accessor b c) (FixLang lex) (Term c -> Term c -> Form b))
        link_Accessor = link 

        access :: Prism' (Predicate (Accessor b c) (FixLang lex) (Term c -> Term c -> Form b)) ()
        access = prism' (\n -> Predicate Accesses ATwo) 
                        (\x -> case x of Predicate Accesses ATwo -> Just ()
                                         _ -> Nothing)

instance {-#OVERLAPPABLE#-} PrismAccessor lex c b => AccessorLanguage (FixLang lex (Form b)) (FixLang lex (Term c)) where
        accesses = curry $ review (binaryOpPrism _access)

class SeparatingLang l t where
        separate :: String -> t -> (t -> l) -> t

class (Typeable b, Typeable c, PrismLink (FixLang lex) (Separation b c (FixLang lex))) 
        => PrismSeparating lex b c | lex -> b c where

        _separator :: Prism' (FixLang lex (Term b -> (Term b -> Form c) -> Term b)) String
        _separator = link_separator . separator

        link_separator :: Prism' (FixLang lex (Term b -> (Term b -> Form c) -> Term b)) 
                               (Separation b c (FixLang lex) (Term b -> (Term b -> Form c) -> Term b))
        link_separator = link 

        separator :: Prism' (Separation b c (FixLang lex) (Term b -> (Term b -> Form c) -> Term b)) String
        separator = prism' Separation (\(Separation s) -> Just s)

instance {-#OVERLAPPABLE#-} 
        (PrismSeparating lex b c) => SeparatingLang (FixLang lex (Form c)) (FixLang lex (Term b))  where
       separate s t f = (curry (review $ binaryOpPrism (_separator . only s))) t (LLam f)

--------------------------------------------------------
--2. Utility Classes
--------------------------------------------------------

class Incrementable lex arg where
        incHead :: FixLang lex a -> Maybe (FixLang lex (arg -> a)) 
        incBody :: (Typeable b, Typeable arg) => FixLang lex (arg -> b) -> Maybe (FixLang lex (arg -> arg -> b))
        incBody = incArity incHead
