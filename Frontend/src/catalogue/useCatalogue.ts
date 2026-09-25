import { useCallback, useEffect, useState, useSyncExternalStore } from 'react'
import { CatalogueHttpError, requestCatalogue, requestProductDetail } from './api'
import type { Search } from './search'
import { searchParams } from './search'

const apiBase = import.meta.env.VITE_CATALOGUE_API_URL || 'http://localhost:8080/api/catalogue'

export function useCatalogue<T>(path: string, decode: (value: unknown) => T) {
  const load = useCallback((signal: AbortSignal) => requestCatalogue(apiBase, path, decode, signal), [path, decode])
  return useRequest(path, load)
}

export function useProductDetail(productId: number) {
  const load = useCallback((signal: AbortSignal) => requestProductDetail(apiBase, productId, signal), [productId])
  return useRequest(`product:${productId}`, load)
}

function useRequest<T>(path: string, load: (signal: AbortSignal) => Promise<T>) {
  const [attempt, setAttempt] = useState(0)
  const key = `${path}:${attempt}`
  const [result, setResult] = useState<{ key: string; data?: T; error?: string; status?: number }>()
  useEffect(() => {
    const controller = new AbortController()
    load(controller.signal).then(
      data => { if (!controller.signal.aborted) setResult({ key, data }) },
      error => { if (!controller.signal.aborted) setResult({ key,
        error: error instanceof Error ? error.message : 'Catalogue request failed.',
        status: error instanceof CatalogueHttpError ? error.status : undefined,
      }) },
    )
    return () => controller.abort()
  }, [load, key])
  const current = result?.key === key ? result : undefined
  return { data: current?.data, error: current?.error, status: current?.status, loading: !current, retry: () => setAttempt(value => value + 1) }
}

function subscribe(callback: () => void) {
  window.addEventListener('popstate', callback)
  return () => window.removeEventListener('popstate', callback)
}
export function useSearchLocation() {
  return useSyncExternalStore(subscribe, () => window.location.search, () => '')
}
export function navigate(query: Search) {
  window.history.pushState(null, '', `${window.location.pathname}?${searchParams(query)}`)
  window.dispatchEvent(new PopStateEvent('popstate'))
}
