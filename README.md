# Shenzhen Emotion Map

A static, participatory emotion map for Shenzhen.

Main entry:

- `index.html`

Deployment:

- Connect this repository to Netlify.
- Build command: leave empty.
- Publish directory: repository root.

Notes:

- User-added points are stored in browser `localStorage`.
- Use the in-page export/import JSON feature to move local points between browsers or deployments.
- The AMap JS API key is configured inside `index.html`; remember to add the Netlify domain to the AMap domain whitelist after deployment.
