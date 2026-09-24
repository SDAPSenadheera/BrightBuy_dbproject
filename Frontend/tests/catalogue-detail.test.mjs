import assert from 'node:assert/strict'
import { test } from 'node:test'
import { CatalogueHttpError, decodeProductDetail, requestProductDetail } from '../src/catalogue/api.ts'

const variant = {
  variant_id: 1, warehouse_id: 1, variant_name: 'Phone - Black 256GB',
  colour: 'Black', memory_size: '256GB', price: 1099, stock_quantity: 50,
}
const category = { category_id: 4, parent_category_id: 1, name: 'Mobile Phones' }
const detail = {
  product_id: 1, sku: 'PHONE-1', name: 'Demo phone', description: 'A sample phone.', image_url: null,
  categories: [{ category_id: 1, parent_category_id: null, name: 'Electronics' }, category],
  variants: [variant, { ...variant, variant_id: 2, price: 1299, stock_quantity: 0 }],
}
const signal = () => new AbortController().signal

test('decodes detail and preserves category/variant order and zero-stock options', () => {
  assert.deepEqual(decodeProductDetail(detail), detail)
})
test('accepts nullable SQL fields, no category assignments, and a zero price', () => {
  const value = { ...detail, description: null, categories: [], variants: [{
    ...variant, warehouse_id: null, variant_name: null, colour: null, memory_size: null, price: 0, stock_quantity: 0,
  }] }
  assert.deepEqual(decodeProductDetail(value), value)
})
test('accepts an image URL without altering its value', () => {
  const value = { ...detail, image_url: '/images/phone.png' }
  assert.deepEqual(decodeProductDetail(value), value)
})

for (const [name, value] of [
  ['null', null], ['array', []], ['missing fields', {}], ['encoded JSON string', JSON.stringify(detail)],
  ['invalid product ID', { ...detail, product_id: 0 }],
  ['numeric SKU', { ...detail, sku: 123 }], ['missing name', { ...detail, name: undefined }],
  ['missing nullable description', { ...detail, description: undefined }],
  ['non-text description', { ...detail, description: 123 }], ['non-text image', { ...detail, image_url: {} }],
  ['missing categories', { ...detail, categories: undefined }], ['null categories', { ...detail, categories: null }],
  ['missing variants', { ...detail, variants: undefined }], ['null variants', { ...detail, variants: null }],
  ['empty variants', { ...detail, variants: [] }],
]) test(`rejects invalid detail: ${name}`, () => assert.throws(() => decodeProductDetail(value), /unexpected response/))

for (const [name, value] of [
  ['null category', null], ['fractional ID', { ...category, category_id: 1.5 }],
  ['string parent ID', { ...category, parent_category_id: '1' }],
  ['missing parent ID', { ...category, parent_category_id: undefined }],
  ['missing name', { ...category, name: undefined }],
]) test(`rejects invalid nested category: ${name}`, () => {
  assert.throws(() => decodeProductDetail({ ...detail, categories: [value] }), /unexpected response/)
})

for (const [name, value] of [
  ['null variant', null], ['string ID', { ...variant, variant_id: '1' }],
  ['negative warehouse', { ...variant, warehouse_id: -1 }], ['missing warehouse', { ...variant, warehouse_id: undefined }],
  ['numeric name', { ...variant, variant_name: 2 }], ['missing colour', { ...variant, colour: undefined }],
  ['numeric memory', { ...variant, memory_size: 256 }], ['null price', { ...variant, price: null }],
  ['string price', { ...variant, price: '1099' }], ['negative price', { ...variant, price: -1 }],
  ['infinite price', { ...variant, price: Infinity }], ['NaN price', { ...variant, price: NaN }],
  ['string stock', { ...variant, stock_quantity: '50' }], ['negative stock', { ...variant, stock_quantity: -1 }],
  ['fractional stock', { ...variant, stock_quantity: 0.5 }], ['unsafe stock', { ...variant, stock_quantity: Number.MAX_SAFE_INTEGER + 1 }],
]) test(`rejects invalid nested variant: ${name}`, () => {
  assert.throws(() => decodeProductDetail({ ...detail, variants: [value] }), /unexpected response/)
})

test('detail client requests the correct URL without credentials and validates the response', async t => {
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    assert.equal(url, 'http://localhost:8080/api/catalogue/products/1')
    assert.equal(options.credentials, 'omit')
    assert.equal(options.headers.Accept, 'application/json')
    assert.ok(options.signal instanceof AbortSignal)
    return Response.json(detail)
  })
  assert.deepEqual(await requestProductDetail('http://localhost:8080/api/catalogue/', 1, signal()), detail)
})
test('invalid IDs fail before any HTTP request, including strings and path injection', async t => {
  const fetch = t.mock.method(globalThis, 'fetch', async () => { throw new Error('Must not fetch') })
  for (const id of [0, -1, 1.5, NaN, Infinity, 2147483648, '1', '../categories', null, undefined]) {
    await assert.rejects(requestProductDetail('', id, signal()), /Product ID/)
  }
  assert.equal(fetch.mock.callCount(), 0)
})
test('accepts the maximum backend product ID', async t => {
  t.mock.method(globalThis, 'fetch', async () => Response.json({ ...detail, product_id: 2147483647 }))
  assert.equal((await requestProductDetail('', 2147483647, signal())).product_id, 2147483647)
})
test('rejects a different product returned by the server', async t => {
  t.mock.method(globalThis, 'fetch', async () => Response.json({ ...detail, product_id: 2 }))
  await assert.rejects(requestProductDetail('', 1, signal()), /unexpected response/)
})
test('rejects malformed detail through the client', async t => {
  t.mock.method(globalThis, 'fetch', async () => Response.json({ ...detail, variants: [] }))
  await assert.rejects(requestProductDetail('', 1, signal()), /unexpected response/)
})
test('404 is a typed unavailable-product error, not an endpoint configuration message', async t => {
  t.mock.method(globalThis, 'fetch', async () => new Response('SECRET SQL error', { status: 404 }))
  await assert.rejects(requestProductDetail('', 1, signal()), error => {
    assert.ok(error instanceof CatalogueHttpError)
    assert.equal(error.status, 404)
    assert.equal(error.message, 'Product not found or unavailable.')
    return true
  })
})
test('server errors keep their status without exposing response bodies', async t => {
  for (const status of [400, 500, 503]) {
    const fetch = t.mock.method(globalThis, 'fetch', async () => new Response('SECRET SQL error', { status }))
    await assert.rejects(requestProductDetail('', 1, signal()), error => {
      assert.ok(error instanceof CatalogueHttpError)
      assert.equal(error.status, status)
      assert.doesNotMatch(error.message, /SECRET|SQL|not found/)
      return true
    })
    fetch.mock.restore()
  }
})
test('detail client preserves network and timeout messages', async t => {
  const fetch = t.mock.method(globalThis, 'fetch', async () => { throw new TypeError('fetch failed') })
  await assert.rejects(requestProductDetail('', 1, signal()), /Cannot reach/)
  fetch.mock.mockImplementation(async () => { throw new DOMException('timed out', 'TimeoutError') })
  await assert.rejects(requestProductDetail('', 1, signal()), /too long/)
})
test('detail client preserves request cancellation', async t => {
  const controller = new AbortController()
  controller.abort()
  t.mock.method(globalThis, 'fetch', async (_url, options) => { options.signal.throwIfAborted() })
  await assert.rejects(requestProductDetail('', 1, controller.signal), { name: 'AbortError' })
})
