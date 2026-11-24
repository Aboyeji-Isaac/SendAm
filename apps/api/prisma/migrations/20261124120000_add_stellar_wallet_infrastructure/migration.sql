-- Stellar wallet infrastructure: muxed sub-wallets, idempotent deposit
-- credits, one-time mnemonic export grants and tracked trustline requests
-- (#958, #960, #962).

-- #958 — Virtual sub-wallets addressed by MED25519 muxed addresses.
-- Every sub-account shares the underlying base account's reserves and
-- trustlines; this table is only the off-chain id -> user mapping.
CREATE TABLE "MuxedSubAccount" (
  "id"          TEXT NOT NULL PRIMARY KEY,
  "userId"      TEXT NOT NULL,
  "walletId"    TEXT NOT NULL,
  -- uint64 held as a decimal string: a JS Number cannot represent 2^64-1.
  "muxedId"     TEXT NOT NULL,
  "baseAccount" TEXT NOT NULL,
  "network"     TEXT NOT NULL,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "MuxedSubAccount_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "MuxedSubAccount_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "Wallet"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "MuxedSubAccount_baseAccount_muxedId_key" ON "MuxedSubAccount"("baseAccount", "muxedId");
CREATE INDEX "MuxedSubAccount_userId_idx" ON "MuxedSubAccount"("userId");
CREATE INDEX "MuxedSubAccount_walletId_idx" ON "MuxedSubAccount"("walletId");

-- #958 — Exactly-once deposit crediting. The unique Horizon paging token is
-- the idempotency key that stops a replayed cursor double-crediting a user.
CREATE TABLE "DepositCredit" (
  "id"               TEXT NOT NULL PRIMARY KEY,
  "stellarPaymentId" TEXT NOT NULL,
  "userId"           TEXT NOT NULL,
  "walletId"         TEXT NOT NULL,
  "muxedId"          TEXT,
  "asset"            TEXT NOT NULL,
  "assetIssuer"      TEXT,
  "amount"           TEXT NOT NULL,
  "network"          TEXT NOT NULL,
  "journalEntryId"   TEXT,
  "createdAt"        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "DepositCredit_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "DepositCredit_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "Wallet"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "DepositCredit_stellarPaymentId_key" ON "DepositCredit"("stellarPaymentId");
CREATE INDEX "DepositCredit_userId_createdAt_idx" ON "DepositCredit"("userId", "createdAt");
CREATE INDEX "DepositCredit_walletId_createdAt_idx" ON "DepositCredit"("walletId", "createdAt");

-- #960 — One-time recovery-phrase export authorization. Stores only the HASH
-- of the out-of-band challenge; never the challenge code and never the
-- mnemonic.
CREATE TABLE "MnemonicExportGrant" (
  "id"                 TEXT NOT NULL PRIMARY KEY,
  "userId"             TEXT NOT NULL,
  "walletId"           TEXT NOT NULL,
  "status"             TEXT NOT NULL DEFAULT 'pending',
  "challengeHash"      TEXT NOT NULL,
  "challengeExpiresAt" TIMESTAMP(3) NOT NULL,
  "challengeAttempts"  INTEGER NOT NULL DEFAULT 0,
  "pinVerifiedAt"      TIMESTAMP(3),
  "otpVerifiedAt"      TIMESTAMP(3),
  "authorizedAt"       TIMESTAMP(3),
  "consumedAt"         TIMESTAMP(3),
  "createdAt"          TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"          TIMESTAMP(3) NOT NULL,
  CONSTRAINT "MnemonicExportGrant_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "MnemonicExportGrant_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "Wallet"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "MnemonicExportGrant_userId_status_idx" ON "MnemonicExportGrant"("userId", "status");
CREATE INDEX "MnemonicExportGrant_status_challengeExpiresAt_idx" ON "MnemonicExportGrant"("status", "challengeExpiresAt");

-- #962 — Tracked ChangeTrust submissions. The unique asset-identity key per
-- wallet is what prevents two concurrent transfers racing duplicate
-- ChangeTrust operations onto the ledger.
CREATE TABLE "TrustlineRequest" (
  "id"          TEXT NOT NULL PRIMARY KEY,
  "walletId"    TEXT NOT NULL,
  "assetCode"   TEXT NOT NULL,
  "assetIssuer" TEXT NOT NULL,
  "network"     TEXT NOT NULL,
  "status"      TEXT NOT NULL DEFAULT 'pending',
  "txHash"      TEXT,
  "attempts"    INTEGER NOT NULL DEFAULT 0,
  "lastError"   TEXT,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3) NOT NULL,
  CONSTRAINT "TrustlineRequest_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "Wallet"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "TrustlineRequest_walletId_assetCode_assetIssuer_key" ON "TrustlineRequest"("walletId", "assetCode", "assetIssuer");
CREATE INDEX "TrustlineRequest_status_updatedAt_idx" ON "TrustlineRequest"("status", "updatedAt");
