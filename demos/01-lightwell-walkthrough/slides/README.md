# Demo 1 slides

| Slide | When | Source |
|---|---|---|
| [opening.png](opening.png) | Opening: the three questions, no results | [opening.html](opening.html) |
| [recap.png](recap.png) | Wrap-up: results, the Woodstox change, takeaways | [recap.html](recap.html) |

To present, open [index.html](index.html) in a browser: it plays the slides in order as a slideshow. Press F for full screen, the right arrow, Space, or a click for the next slide, and the left arrow to go back. `index.html#2` opens on the recap. The player is shared by all demos: [demos/slideshow.js](../../slideshow.js).

The PNGs are 1920×1080. To re-render after editing a slide's HTML, use Playwright (Node.js). From the repo root:

```sh
npm install --prefix /tmp/lw-slides playwright && npx --prefix /tmp/lw-slides playwright install chromium
node -e 'const path=require("path"); (async()=>{const {chromium}=require("/tmp/lw-slides/node_modules/playwright"); const b=await chromium.launch(); for (const n of ["opening","recap"]) { const p=await b.newPage({viewport:{width:1920,height:1080}}); await p.goto("file://"+path.resolve("demos/01-lightwell-walkthrough/slides/"+n+".html")); await p.screenshot({path:"demos/01-lightwell-walkthrough/slides/"+n+".png"}); } await b.close();})();'
```

If you change a number on a slide (for example the match count), change it in the Demo 1 script too.
