# archi-ve

A personal, private photo-journal app for an architect. Capture what catches
your eye — site visits, references, exhibitions, details — tag it with two
taps, browse it later.

Single user, single device, no cloud, no accounts. Plain HTML/CSS/JS in one
file. Storage is local (IndexedDB).

## Live app

GitHub Pages: <https://samiabdulnour.github.io/archi-ve/>

Add to iPhone home screen for the full-screen PWA experience.

## Run locally

No build step. Open `index.html` in a browser, or serve the directory:

```
python3 -m http.server 8000
```

Then visit <http://localhost:8000>.

For camera access on a real iPhone over the local network, you need HTTPS — the
quickest path is a tunnel:

```
npx --yes localtunnel --port 8000
```

## Project shape

- `index.html` — the entire app (markup, styles, logic)
- `CLAUDE.md` — design brief and constraints (read this before changing
  taxonomy, scope, or stack)

## Status

The web app is feature-complete for daily personal use. Next: wrap in
[Capacitor](https://capacitorjs.com/) for App Store publication. See
`PUBLISHING.md` (coming) for the procedure.
