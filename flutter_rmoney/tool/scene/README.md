# Finance Scene

The dashboard embeds a local Three.js scene through `webview_flutter`. It never
loads a CDN or sends transaction data over the network. Flutter sends only the
four displayed totals: expenses, savings, reserved funds, and available balance.
The ring shows their relative sizes, not percentages of income. An empty period
uses a neutral ring instead of invented data.

To rebuild the checked-in offline asset, from this directory run:

```sh
npm ci
npm run build
```

The source is `scene.js`; the generated file is
`../../assets/scene/scene.bundle.js`. Keep the Three.js license with the assets.
Horizontal dragging rotates the scene. Tapping a segment or its Flutter legend
selects it. Flutter provides pause/reset buttons and respects reduced motion.
If WebGL fails, totals remain available with a native static fallback.
