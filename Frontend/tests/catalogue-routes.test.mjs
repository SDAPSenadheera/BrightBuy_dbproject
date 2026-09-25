import assert from 'node:assert/strict'
import { test } from 'node:test'
import { catalogueHref, parseCatalogueRoute } from '../src/catalogue/routes.ts'
import { defaultSearch } from '../src/catalogue/search.ts'

test('default location stays on browse', () => {
  assert.deepEqual(parseCatalogueRoute(''), { query: defaultSearch, productId: null, error: '' })
})
test('direct product link uses default browse state', () => {
  assert.deepEqual(parseCatalogueRoute('?productId=1'), { query: defaultSearch, productId: 1, error: '' })
})
test('card links and return links preserve all filters, sorting, pagination and special characters', () => {
  const query = { ...defaultSearch, keyword: 'Phone & 50%_ +', categoryId: '4', minPrice: '0', maxPrice: '1500', inStockOnly: true, sort: 'price_desc', page: 3, pageSize: 24 }
  const route = parseCatalogueRoute(catalogueHref(query, 1))
  assert.deepEqual(route, { query, productId: 1, error: '' })
  const back = catalogueHref(route.query)
  assert.equal(new URLSearchParams(back).has('productId'), false)
  assert.deepEqual(parseCatalogueRoute(back), { query, productId: null, error: '' })
})
test('maximum backend ID and zero-padded numeric links are accepted', () => {
  assert.equal(parseCatalogueRoute('?productId=2147483647').productId, 2147483647)
  assert.equal(parseCatalogueRoute('?productId=0001').productId, 1)
})
for (const value of ['', '0', '-1', '1.5', '1e2', 'NaN', 'Infinity', '2147483648', '../categories', ' 1', '00000000001']) {
  test(`invalid product link is not fetchable: ${JSON.stringify(value)}`, () => {
    const route = parseCatalogueRoute(`?page=2&productId=${encodeURIComponent(value)}`)
    assert.equal(route.productId, null)
    assert.match(route.error, /product link is invalid/)
    assert.equal(route.query.page, 2)
  })
}
test('duplicate product IDs are rejected', () => {
  assert.match(parseCatalogueRoute('?productId=1&productId=2').error, /invalid/)
})
test('unknown or invalid browse filters are still rejected on detail URLs', () => {
  for (const input of ['?productId=1&unknown=2', '?productId=1&page=0', '?productId=1&keyword=a&keyword=b']) {
    assert.throws(() => parseCatalogueRoute(input))
  }
})
test('link builder rejects invalid IDs instead of creating unsafe paths', () => {
  for (const id of [0, -1, 1.5, 2147483648, NaN, Infinity, '../categories']) assert.throws(() => catalogueHref(defaultSearch, id))
})
