------------------------------------------------------------------------
-- IO
------------------------------------------------------------------------

{-# OPTIONS --no-termination-check
  #-}

module IO where

open import Coinduction
open import Data.Unit
open import Data.String
open import Data.Colist
import Foreign.Haskell as Haskell
import IO.Primitive as Prim

------------------------------------------------------------------------
-- The IO monad

-- One cannot write "infinitely large" computations with the
-- postulated IO monad in IO.Primitive without turning off the
-- termination checker (or going via the FFI, or perhaps abusing
-- something else). The following coinductive deep embedding is
-- introduced to avoid this problem. Possible non-termination is
-- isolated to the run function below.

infixl 1 _>>=_ _>>_

data IO : Set → Set1 where
  lift   : ∀ {A} (m : Prim.IO A) → IO A
  return : ∀ {A} (x : A) → IO A
  _>>=_  : ∀ {A B} (m : ∞₁ (IO A)) (f : (x : A) → ∞₁ (IO B)) → IO B
  _>>_   : ∀ {A B} (m₁ : ∞₁ (IO A)) (m₂ : ∞₁ (IO B)) → IO B

-- The use of abstract ensures that the run function will not be
-- unfolded infinitely by the type checker.

abstract

  run : ∀ {A} → IO A → Prim.IO A
  run (lift m)   = m
  run (return x) = Prim.return x
  run (m  >>= f) = Prim._>>=_ (run (♭₁ m )) λ x → run (♭₁ (f x))
  run (m₁ >> m₂) = Prim._>>=_ (run (♭₁ m₁)) λ _ → run (♭₁ m₂)

------------------------------------------------------------------------
-- Simple lazy IO (UTF8-based)

getContents : IO Costring
getContents =
  ♯ lift Prim.getContents >>= λ s →
  ♯ return (Haskell.toColist s)

readFile : String → IO Costring
readFile f =
  ♯ lift (Prim.readFile f) >>= λ s →
  ♯ return (Haskell.toColist s)

writeFile∞ : String → Costring → IO ⊤
writeFile∞ f s =
  ♯ lift (Prim.writeFile f (Haskell.fromColist s)) >>
  ♯ return _

writeFile : String → String → IO ⊤
writeFile f s = writeFile∞ f (toCostring s)

putStr∞ : Costring → IO ⊤
putStr∞ s =
  ♯ lift (Prim.putStr (Haskell.fromColist s)) >>
  ♯ return _

putStr : String → IO ⊤
putStr s = putStr∞ (toCostring s)

putStrLn∞ : Costring → IO ⊤
putStrLn∞ s =
  ♯ lift (Prim.putStrLn (Haskell.fromColist s)) >>
  ♯ return _

putStrLn : String → IO ⊤
putStrLn s = putStrLn∞ (toCostring s)
