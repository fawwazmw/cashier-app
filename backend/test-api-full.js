#!/usr/bin/env node

/*
 End-to-end API Test for GRIYO POS Backend
 - Health
 - Auth (login)
 - Products (list, create, get, update, delete)
 - Transactions (create cash, get, list, update status)
 - Payment (methods, create token) — best effort

 Usage:
   cd backend
   npm i axios
   node test-api-full.js

 Optional env:
   BASE_URL=http://localhost:8000 node test-api-full.js
   USE_PAYMENT=true node test-api-full.js
*/

const axios = require('axios');

const BASE_URL = process.env.BASE_URL || 'http://localhost:8000';
const USE_PAYMENT = String(process.env.USE_PAYMENT || 'true').toLowerCase() === 'true';

const ADMIN_USER = process.env.TEST_USER || 'admin';
// Default password in current schema.sql hash corresponds to 'password'
const ADMIN_PASS = process.env.TEST_PASS || 'password';

function logStep(title) {
  console.log(`\n=== ${title} ===`);
}

function ok(msg) { console.log(`✅ ${msg}`); }
function warn(msg) { console.log(`⚠️  ${msg}`); }
function fail(msg) { console.log(`❌ ${msg}`); }

async function main() {
  const summary = { passed: [], failed: [], skipped: [] };
  let token = null;
  let createdProduct = null;
  let createdCashTx = null;
  let createdMidtransTx = null;

  // Health
  try {
    logStep('Health check');
    const r = await axios.get(`${BASE_URL}/health`);
    if (r.status === 200 && r.data && (r.data.success === true || r.data.status === 'ok')) {
      ok(`Health: ${r.data.message || 'OK'}`);
      summary.passed.push('health');
    } else {
      throw new Error('Unexpected health response');
    }
  } catch (e) {
    fail(`Health check failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('health');
  }

  // Login
  try {
    logStep('Auth: login admin');
    const r = await axios.post(`${BASE_URL}/api/auth/login`, {
      username: ADMIN_USER,
      password: ADMIN_PASS,
    });
    if (r.data?.success && r.data?.token) {
      token = r.data.token;
      ok(`Login success as ${r.data.user?.username || ADMIN_USER}`);
      summary.passed.push('login');
    } else {
      throw new Error('Login response invalid');
    }
  } catch (e) {
    fail(`Login failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('login');
  }

  const auth = token ? { headers: { Authorization: `Bearer ${token}` } } : {};

  // Products: list
  try {
    logStep('Products: list');
    const r = await axios.get(`${BASE_URL}/api/products`, auth);
    ok(`Products listed: ${Array.isArray(r.data?.data) ? r.data.data.length : 0}`);
    summary.passed.push('products_list');
  } catch (e) {
    fail(`Products list failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('products_list');
  }

  // Products: create
  try {
    logStep('Products: create');
    const unique = Date.now().toString().slice(-6);
    const body = {
      nama: `Produk Uji Automation ${unique}`,
      harga: 12345,
      stok: 9,
      kategori: 'Uji',
      deskripsi: 'Dibuat oleh test-api-full.js',
    };
    const r = await axios.post(`${BASE_URL}/api/products`, body, auth);
    createdProduct = r.data?.product;
    if (!createdProduct?.id) throw new Error('No product id');
    ok(`Product created id=${createdProduct.id}`);
    summary.passed.push('products_create');
  } catch (e) {
    fail(`Products create failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('products_create');
  }

  // Products: get
  try {
    logStep('Products: get');
    const id = createdProduct?.id || 1;
    const r = await axios.get(`${BASE_URL}/api/products/${id}`, auth);
    ok(`Product fetched id=${r.data?.data?.id}`);
    summary.passed.push('products_get');
  } catch (e) {
    fail(`Products get failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('products_get');
  }

  // Products: update
  try {
    logStep('Products: update');
    if (!createdProduct?.id) throw new Error('No created product to update');
    const r = await axios.put(
      `${BASE_URL}/api/products/${createdProduct.id}`,
      { harga: 13000, stok: 12 },
      auth
    );
    ok(`Product updated id=${createdProduct.id}`);
    summary.passed.push('products_update');
  } catch (e) {
    fail(`Products update failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('products_update');
  }

  // Transactions: create (cash)
  try {
    logStep('Transactions: create (cash)');
    const items = [];
    if (createdProduct?.id) items.push({ product_id: createdProduct.id, qty: 1 });
    // Always include a known seed product as fallback
    items.push({ product_id: 1, qty: 1 });

    // Fetch product prices to compute accurate total
    let expectedTotal = 0;
    for (const it of items) {
      try {
        const pr = await axios.get(`${BASE_URL}/api/products/${it.product_id}`, auth);
        const price = pr.data?.data?.harga || pr.data?.product?.harga || 0;
        expectedTotal += Number(price) * Number(it.qty);
      } catch (err) {
        // If fetch fails, make a best guess for product 1 as 7000 (seed value)
        if (it.product_id === 1) expectedTotal += 7000 * Number(it.qty);
      }
    }

    const body = {
      total: expectedTotal,
      payment_method: 'cash',
      items,
      customer_name: 'Tester',
      customer_phone: '081234567890',
      notes: 'Transaksi uji automation (cash)'
    };
    const r = await axios.post(`${BASE_URL}/api/transactions`, body, auth);
    createdCashTx = r.data?.transaction;
    if (!createdCashTx?.id) throw new Error('No transaction id');
    ok(`Cash transaction created id=${createdCashTx.id}`);
    summary.passed.push('transactions_create_cash');
  } catch (e) {
    fail(`Transactions create (cash) failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('transactions_create_cash');
  }

  // Transactions: get by id
  try {
    logStep('Transactions: get by id');
    if (!createdCashTx?.id) throw new Error('No transaction id');
    const r = await axios.get(`${BASE_URL}/api/transactions/${createdCashTx.id}`, auth);
    ok(`Transaction fetched id=${r.data?.data?.id}`);
    summary.passed.push('transactions_get');
  } catch (e) {
    fail(`Transactions get failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('transactions_get');
  }

  // Transactions: list
  try {
    logStep('Transactions: list');
    const r = await axios.get(`${BASE_URL}/api/transactions?limit=5&orderBy=created_at&orderDir=DESC`, auth);
    ok(`Transactions listed: ${Array.isArray(r.data?.data) ? r.data.data.length : 0}`);
    summary.passed.push('transactions_list');
  } catch (e) {
    fail(`Transactions list failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('transactions_list');
  }

  // Transactions: update status -> paid
  try {
    logStep('Transactions: update status -> paid');
    if (!createdCashTx?.id) throw new Error('No transaction id');
    await axios.put(
      `${BASE_URL}/api/transactions/${createdCashTx.id}/status`,
      { status: 'paid' },
      auth
    );
    ok(`Transaction marked paid id=${createdCashTx.id}`);
    summary.passed.push('transactions_update_status');
  } catch (e) {
    fail(`Transactions update status failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('transactions_update_status');
  }

  // Payment (best effort)
  if (USE_PAYMENT) {
    // Payment methods
    try {
      logStep('Payment: get methods');
      const r = await axios.get(`${BASE_URL}/api/payment/methods`, auth);
      ok(`Payment methods OK (${(r.data?.methods || []).length || 'n/a'})`);
      summary.passed.push('payment_methods');
    } catch (e) {
      warn(`Payment methods failed: ${e.response?.data?.message || e.message}`);
      summary.failed.push('payment_methods');
    }

    // Create a midtrans transaction and request token
    try {
      logStep('Payment: create midtrans transaction and token');
      const midItems = [
        createdProduct?.id ? { product_id: createdProduct.id, qty: 1 } : { product_id: 1, qty: 1 }
      ];

      // Compute expected total similarly
      let midExpectedTotal = 0;
      for (const it of midItems) {
        try {
          const pr = await axios.get(`${BASE_URL}/api/products/${it.product_id}`, auth);
          const price = pr.data?.data?.harga || pr.data?.product?.harga || 0;
          midExpectedTotal += Number(price) * Number(it.qty);
        } catch (err) {
          if (it.product_id === 1) midExpectedTotal += 7000 * Number(it.qty);
        }
      }

      const body = {
        total: midExpectedTotal,
        payment_method: 'midtrans',
        items: midItems,
        customer_name: 'Tester Midtrans',
        customer_phone: '081234567891',
        notes: 'Transaksi uji automation (midtrans)'
      };
      const txRes = await axios.post(`${BASE_URL}/api/transactions`, body, auth);
      createdMidtransTx = txRes.data?.transaction;
      if (!createdMidtransTx?.id) throw new Error('No midtrans transaction id');

      const tokenRes = await axios.post(
        `${BASE_URL}/api/payment/create-token`,
        {
          transaction_id: createdMidtransTx.id,
          customer_details: {
            first_name: 'Tester',
            email: 'tester@example.com',
            phone: '081234567891'
          }
        },
        auth
      );

      if (tokenRes.data?.token) {
        ok(`Midtrans token created for id=${createdMidtransTx.id}`);
        summary.passed.push('payment_create_token');
      } else {
        throw new Error('No token returned');
      }
    } catch (e) {
      warn(`Payment token step failed (this can be due to sandbox keys or network): ${e.response?.data?.message || e.message}`);
      summary.failed.push('payment_create_token');
    }
  } else {
    summary.skipped.push('payment_all');
  }

  // Products: delete (cleanup)
  try {
    logStep('Cleanup: delete created product');
    if (createdProduct?.id) {
      await axios.delete(`${BASE_URL}/api/products/${createdProduct.id}`, auth);
      ok(`Product deleted id=${createdProduct.id}`);
      summary.passed.push('products_delete');
    } else {
      warn('No created product to delete');
      summary.skipped.push('products_delete');
    }
  } catch (e) {
    warn(`Product delete failed: ${e.response?.data?.message || e.message}`);
    summary.failed.push('products_delete');
  }

  // Summary
  console.log('\n===== SUMMARY =====');
  console.log(`Passed: ${summary.passed.length} -> ${summary.passed.join(', ')}`);
  console.log(`Failed: ${summary.failed.length} -> ${summary.failed.join(', ')}`);
  console.log(`Skipped: ${summary.skipped.length} -> ${summary.skipped.join(', ')}`);

  if (summary.failed.length > 0) {
    process.exitCode = 1;
  }
}

main().catch((e) => {
  fail(`Fatal: ${e.message}`);
  process.exit(1);
});
