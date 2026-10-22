/**
 * Minimal validation for SEP-0007 payment and transaction URIs.
 *
 * SEP-0043 defines a web-wallet API, not a payment URI scheme; QR requests
 * therefore carry a SEP-0007 `web+stellar:` URI.
 */
export function normalizeSep7Uri(value) {
  if (typeof value !== 'string') return '';
  const uri = value.trim();
  if (!uri || uri.length > 2000 || !/^web\+stellar:(pay|tx)\?/i.test(uri)) {
    return '';
  }

  const queryStart = uri.indexOf('?');
  if (queryStart < 0 || queryStart === uri.length - 1) return '';

  const operation = uri.slice('web+stellar:'.length, queryStart).toLowerCase();
  const params = new URLSearchParams(uri.slice(queryStart + 1));

  if (operation === 'pay' && !/^(?:G[A-Z2-7]{55}|M[A-Z2-7]{68})$/.test(params.get('destination') || '')) return '';
  if (operation === 'tx' && !params.get('xdr')) return '';

  return uri;
}

export function isValidSep7Uri(value) {
  return normalizeSep7Uri(value) !== '';
}

/**
 * Build a SEP-0007 payment URI only when the simulator has enough real data.
 * Native XLM needs no issuer; issued assets are intentionally not guessed.
 */
export function buildSep7PaymentUri({ destination, amount, asset } = {}) {
  const isStellarAddress = /^(?:G[A-Z2-7]{55}|M[A-Z2-7]{68})$/.test(destination || '');
  const numericAmount = Number(amount);
  if (!isStellarAddress || !Number.isFinite(numericAmount) || numericAmount <= 0) return '';
  if (typeof asset !== 'string' || asset.toUpperCase() !== 'XLM') return '';

  const params = new URLSearchParams({
    destination,
    amount: String(numericAmount),
  });
  return `web+stellar:pay?${params.toString()}`;
}
