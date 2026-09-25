# Catalogue frontend

Start the backend using [its catalogue profile instructions](../Backend/CATALOGUE_API.md),
then run from `Frontend`:

```sh
npm run dev -- --port 5173 --strictPort
```

Open `http://localhost:5173/catalogue.html` through the development server,
not by opening the HTML file with a `file://` URL. The shared `/` starter is
unchanged. If needed, set `VITE_CATALOGUE_API_URL` to the full catalogue API
base URL before starting Vite; its default is `http://localhost:8080/api/catalogue`.
Keep credentials out of frontend environment variables.

## Product details

Product-name links open details using `?productId=1` alongside the browse query
parameters. Direct links, refresh, browser history and opening in a new tab
work with normal links. Back to results preserves search, filters, sorting and
page. Category links from details start a fresh browse of that category.

The page shows name, SKU, description, image/fallback, categories, the price
range across **all** variants, and whether any variant is in stock. Prices on
a filtered browse card may cover fewer variants than the detail range.
No currency is assumed. Variant selection and cart actions are not implemented
in this milestone.

Loading is announced; invalid IDs are rejected before a detail request.
Missing/inactive products show an unavailable state with a return link.
Network/server/invalid-response failures offer a retry. Out-of-stock products
remain readable. Requests are cancelled when leaving or changing products.

## Checks (from Frontend)

```sh
node --test tests/catalogue*.test.mjs
npm run lint
npm run build
npx vite build --config vite.catalogue.config.ts
```

Use a Node release supporting native TypeScript stripping (validated with
Node 26). The rendering tests use the existing Vite/React dependencies, without
opening a browser or connecting to the backend. API tests mock HTTP responses.
The default build retains the shared starter; the separate catalogue build
outputs to `dist/catalogue`. Run the shared build before the catalogue build,
because the shared build clears `dist`.

Manual checks: open a product from filtered results, return and check the
filters/page, refresh a detail link, browse a category from details, check
an inactive/missing ID, retry after a connection failure, and check a narrow
screen. The team's actual MySQL 8 deployment still requires integration testing.
