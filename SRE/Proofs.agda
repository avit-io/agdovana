module SRE.Proofs where

open import Data.Nat            using (ℕ; suc; _<_; _≤ᵇ_)
open import Data.Bool           using (T)
open import Data.Nat.Properties using (≤ᵇ⇒≤)

-- prf risolve la prova short < long per riduzione booleana.
--
-- T (suc a ≤ᵇ b) si riduce a T true = ⊤  → Agda riempie l'implicito con tt
--                           oppure T false = ⊥ → nessuna prova possibile
--
-- Questo compila ✓   prf 5 60
-- Questo viene rifiutato ✗  prf 60 5   (T false = ⊥, la gallina non chioccia)
prf : ∀ (a b : ℕ) → {T (suc a ≤ᵇ b)} → a < b
prf a b {h} = ≤ᵇ⇒≤ h
