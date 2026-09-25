export type Category = {
  category_id: number
  parent_category_id: number | null
  name: string
  description: string | null
  product_count: number
}

export type Product = {
  product_id: number
  sku: string
  name: string
  image_url: string | null
  min_price: number
  max_price: number
  matching_variant_count: number
  matching_stock_quantity: number
}

export type ProductPage = {
  page: number
  page_size: number
  sort: string
  total_products: number
  total_pages: number
  items: Product[]
}

// Detail categories do not include the browse endpoint's counts/description.
export type ProductCategory = Pick<Category, 'category_id' | 'parent_category_id' | 'name'>

export type ProductVariant = {
  variant_id: number
  warehouse_id: number | null
  variant_name: string | null
  colour: string | null
  memory_size: string | null
  price: number
  stock_quantity: number
}

export type ProductDetail = {
  product_id: number
  sku: string
  name: string
  description: string | null
  image_url: string | null
  categories: ProductCategory[]
  variants: ProductVariant[]
}

export class CatalogueHttpError extends Error {
  readonly status: number

  constructor(status: number, message: string, options?: ErrorOptions) {
    super(message, options)
    this.name = 'CatalogueHttpError'
    this.status = status
  }
}

function record(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}
function number(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0
}
function count(value: unknown): value is number { return number(value) && Number.isSafeInteger(value) }
function id(value: unknown): value is number { return count(value) && value > 0 }
function nullableText(value: unknown): value is string | null { return value === null || typeof value === 'string' }
function invalid(): never { throw new Error('The catalogue returned an unexpected response. Please try again.') }

export function decodeCategories(value: unknown): Category[] {
  if (!record(value) || !Array.isArray(value.items)) return invalid()
  return value.items.map((item: unknown) => {
    if (!record(item) || !id(item.category_id) || !(item.parent_category_id === null || id(item.parent_category_id))
      || typeof item.name !== 'string' || !nullableText(item.description) || !count(item.product_count)) return invalid()
    return item as Category
  })
}

export function decodeProducts(value: unknown): ProductPage {
  if (!record(value) || !id(value.page) || !id(value.page_size) || typeof value.sort !== 'string'
    || !count(value.total_products) || !count(value.total_pages) || !Array.isArray(value.items)) return invalid()
  for (const item of value.items) {
    if (!record(item) || !id(item.product_id) || typeof item.sku !== 'string' || typeof item.name !== 'string'
      || !nullableText(item.image_url) || !number(item.min_price) || !number(item.max_price)
      || item.min_price > item.max_price || !id(item.matching_variant_count)
      || !count(item.matching_stock_quantity)) return invalid()
  }
  return value as ProductPage
}

export function decodeProductDetail(value: unknown): ProductDetail {
  if (!record(value) || !id(value.product_id) || typeof value.sku !== 'string' || typeof value.name !== 'string'
    || !nullableText(value.description) || !nullableText(value.image_url)
    || !Array.isArray(value.categories) || !Array.isArray(value.variants) || value.variants.length === 0) return invalid()
  for (const category of value.categories) {
    if (!record(category) || !id(category.category_id)
      || !(category.parent_category_id === null || id(category.parent_category_id))
      || typeof category.name !== 'string') return invalid()
  }
  for (const variant of value.variants) {
    if (!record(variant) || !id(variant.variant_id)
      || !(variant.warehouse_id === null || id(variant.warehouse_id))
      || !nullableText(variant.variant_name) || !nullableText(variant.colour) || !nullableText(variant.memory_size)
      || !number(variant.price) || !count(variant.stock_quantity)) return invalid()
  }
  return value as ProductDetail
}

export async function requestProductDetail(baseUrl: string, productId: number,
  signal: AbortSignal, timeoutMs = 10000): Promise<ProductDetail> {
  if (!id(productId) || productId > 2147483647) {
    throw new Error('Product ID must be a whole number between 1 and 2147483647.')
  }
  try {
    return await requestCatalogue(baseUrl, `/products/${productId}`, value => {
      const product = decodeProductDetail(value)
      if (product.product_id !== productId) return invalid()
      return product
    }, signal, timeoutMs)
  } catch (error) {
    if (error instanceof CatalogueHttpError && error.status === 404) {
      throw new CatalogueHttpError(404, 'Product not found or unavailable.', { cause: error })
    }
    throw error
  }
}

// Used by both browser code and dependency-free Node tests. No Vite globals here.
export async function requestCatalogue<T>(baseUrl: string, path: string, decode: (value: unknown) => T,
  signal: AbortSignal, timeoutMs = 10000): Promise<T> {
  try {
    const response = await fetch(`${baseUrl.replace(/\/$/, '')}${path}`, {
      headers: { Accept: 'application/json' },
      credentials: 'omit',
      signal: AbortSignal.any([signal, AbortSignal.timeout(timeoutMs)]),
    })
    if (!response.ok) {
      // Never display raw server/proxy/SQL messages in the UI.
      if (response.status === 400) throw new CatalogueHttpError(400, 'These filters were rejected. Please check them and try again.')
      if (response.status === 404) throw new CatalogueHttpError(404, 'The catalogue endpoint was not found. Check the backend address.')
      throw new CatalogueHttpError(response.status, 'The catalogue is temporarily unavailable. Please try again.')
    }
    if (!response.headers.get('content-type')?.includes('application/json')) return invalid()
    return decode(await response.json())
  } catch (error) {
    if (signal.aborted) throw error
    if (error instanceof Error && error.name === 'TimeoutError') {
      throw new Error('The catalogue took too long to respond. Please try again.', { cause: error })
    }
    if (error instanceof TypeError) throw new Error('Cannot reach the catalogue. Check that the backend is running.', { cause: error })
    if (error instanceof SyntaxError) return invalid()
    throw error
  }
}
