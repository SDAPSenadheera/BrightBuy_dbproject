import { useState } from 'react'

export function PackageIcon() {
  return <svg viewBox="0 0 80 80" fill="none" aria-hidden="true"><path d="m40 12 26 14v29L40 70 14 55V26l26-14Z" /><path d="m14 26 26 15 26-15M40 41v29M27 19l26 15v14" /></svg>
}

export default function ProductImage({ src, name }: { src: string | null; name: string }) {
  const [failedSrc, setFailedSrc] = useState<string | null>(null)
  const safeImage = src && /^(https?:\/\/|\/[^/])/.test(src) ? src : null
  return safeImage && failedSrc !== safeImage
    ? <img src={safeImage} alt={name} loading="lazy" onError={() => setFailedSrc(safeImage)} />
    : <div className="catalogue-image-placeholder"><PackageIcon /><span>Image coming soon</span></div>
}
