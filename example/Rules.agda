module Rules where

open import SRE.Core
open import SRE.Proofs
open import Data.List using (List; _∷_; [])

-- ── Regole per un SLO 99.9% su http_requests ─────────────────────────────

highErrorRate : BurnRateAlert
highErrorRate = mkAlert
  "HighErrorRate" "http_requests"
  5 60 (prf 5 60)
  14 page slo99-9

sustainedErrorRate : BurnRateAlert
sustainedErrorRate = mkAlert
  "SustainedErrorRate" "http_requests"
  30 360 (prf 30 360)
  6 ticket slo99-9

slowBurn : BurnRateAlert
slowBurn = mkAlert
  "SlowBurnErrorRate" "http_requests"
  120 1440 (prf 120 1440)
  3 warning slo99-9

-- mkAlert "Assurdo" "m" 60 5 (prf 60 5) 14 page slo99-9
-- ✗ T false = ⊥ · la gallina non chioccia

allAlerts : List BurnRateAlert
allAlerts = highErrorRate ∷ sustainedErrorRate ∷ slowBurn ∷ []
