import { parseSearch, searchParams } from './search.ts'
import type { Search } from './search.ts'

export function parseCatalogueRoute(location: string) {
  const params = new URLSearchParams(location)
  const ids = params.getAll('productId')
  params.delete('productId')
  const query = parseSearch(params)
  if (ids.length > 1 || (ids.length === 1 && (!/^[0-9]{1,10}$/.test(ids[0])
    || Number(ids[0]) < 1 || Number(ids[0]) > 2147483647))) {
    return { query, productId: null, error: 'This product link is invalid. Return to the catalogue and choose a product.' }
  }
  return { query, productId: ids.length ? Number(ids[0]) : null, error: '' }
}

// Query-only URLs work for the separate catalogue entry and preserve browse state.
export function catalogueHref(query: Search, productId?: number): string {
  const params = searchParams(query)
  if (productId !== undefined) {
    if (!Number.isInteger(productId) || productId < 1 || productId > 2147483647) throw new Error('Invalid product ID.')
    params.set('productId', String(productId))
  }
  return `?${params}`
}
