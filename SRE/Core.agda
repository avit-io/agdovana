module SRE.Core where

open import Data.Nat    using (ℕ; _<_)
open import Data.String using (String)

data Severity : Set where
  warning ticket page : Severity

-- error-budget è la stringa decimale usata nell'espressione PromQL,
-- e.g. "0.001" per un SLO al 99.9%.
record SLO : Set where
  constructor mkSLO
  field
    slo-name     : String
    error-budget : String

record BurnRateAlert : Set where
  constructor mkAlert
  field
    alert-name   : String
    metric       : String   -- base metric, e.g. "http_requests"
    short-window : ℕ        -- minuti
    long-window  : ℕ        -- minuti
    .proof       : short-window < long-window   -- impossibile invertire le finestre
    burn-rate    : ℕ
    sev          : Severity
    slo          : SLO

-- SLO predefiniti
slo99-9 : SLO
slo99-9 = mkSLO "99.9%" "0.001"

slo99-99 : SLO
slo99-99 = mkSLO "99.99%" "0.0001"
