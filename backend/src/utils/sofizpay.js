const SOFIZPAY_API = 'https://sofizpay.com/make-cib-transaction/';
const SOFIZPAY_CHECK_API = 'https://sofizpay.com/cib-transaction-check/';

export function buildSofizpayUrl({ account, amount, full_name, phone, email, return_url, webhook_url, order_id, language, memo }) {
  const params = new URLSearchParams({
    account: account || '',
    amount: String(amount),
    full_name: full_name || 'Anonyme',
    phone: phone || '',
    email: email || '',
    return_url: return_url || '',
    webhook_url: webhook_url || '',
    invoice_id: order_id || '',
    language: language || 'fr',
    memo: (memo || '').substring(0, 28),
    redirect: 'yes',
    keep_return_url: 'True',
  });
  return `${SOFIZPAY_API}?${params.toString()}`;
}

export function buildSofizpayCheckUrl(order_number) {
  return `${SOFIZPAY_CHECK_API}?order_number=${order_number}`;
}
