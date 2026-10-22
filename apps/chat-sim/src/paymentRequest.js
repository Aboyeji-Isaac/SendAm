/**
 * Minimal validation for SEP-0007 payment and transaction URIs.
 *
 * SEP-0043 defines a web-wallet API, not a payment URI scheme; QR requests
 * therefore carry a SEP-0007 `web+stellar:` URI.
 */
export function normalizeSep7Uri(value) {
  if (typeof value !== 'string') return '';
  const uri = value.trim();
  if (!uri || uri.length > 3000 || !/^web\+stellar:(pay|tx)\?/i.test(uri)) {
    return '';
  }

  const queryStart = uri.indexOf('?');
  if (queryStart < 0 || queryStart === uri.length - 1) return '';

  const operation = uri.slice('web+stellar:'.length, queryStart).toLowerCase();
  const params = new URLSearchParams(uri.slice(queryStart + 1));

  if (operation === 'pay' && !params.get('destination')) return '';
  if (operation === 'tx' && !params.get('xdr')) return '';

  return uri;
}

export function isValidSep7Uri(value) {
  return normalizeSep7Uri(value) !== '';
}
