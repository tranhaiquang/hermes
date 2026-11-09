# Disabling zoom on mobile Safari (iOS)

iOS Safari ignores `user-scalable=no` and `maximum-scale` in the viewport meta tag (accessibility policy since iOS 10). The meta tag alone never stops pinch zoom. Three distinct zoom paths exist; cover all of them:

## 1. Pinch zoom / double-tap zoom — CSS layer (the one that works)

Set on the root elements:

```css
html,body{ touch-action:pan-x pan-y }
```

`pan-x pan-y` allows scrolling but disables pinch-zoom and double-tap zoom; iOS 13+ Safari respects it. Belt-and-braces JS blockers (attach early, at boot):

```js
document.addEventListener('gesturestart', e=>e.preventDefault());
document.addEventListener('gesturechange', e=>e.preventDefault());
document.addEventListener('touchmove', e=>{ if(e.scale!==1) e.preventDefault(); }, {passive:false});
let __lastTap=0;
document.addEventListener('touchend', e=>{ const n=Date.now(); if(n-__lastTap<=300) e.preventDefault(); __lastTap=n; }, {passive:false});
```

The JS handlers alone are NOT sufficient on current iOS — the `touch-action` rule is what reliably kills the pinch gesture.

## 2. Focus auto-zoom on form fields — the 16px rule

Safari zooms the viewport when a focused input's computed font-size is under 16px. Inside the phone media query set:

```css
@media (max-width:900px){ input,select,textarea{ font-size:16px!important } }
```

Why element selector + `!important`: compound-class rules such as `.inp.sm{font-size:13px}` have higher specificity than a single-class rule like `.inp{font-size:16px}` and win regardless of source order, so a narrow rule silently leaves small inputs zoomable. Also audit variant selectors (e.g. `:root[data-ui="mobile"] .inp.sm{font-size:15px}`) — anything under 16px still triggers zoom.

## 3. Viewport meta — keep it, but expect it to be ignored on iOS

```html
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1.0,user-scalable=no,viewport-fit=cover">
```

Still worth setting: it works on Android/Chrome and older browsers; iOS Safari just ignores the zoom-related parts.

## Pitfalls

- Verify on a real iOS device or simulator. Desktop devtools device emulation does not reproduce Safari's gesture handling, so "works in Chrome devtools" proves nothing.
- When testing a deployed site, hard-refresh on the phone — Safari caches the old HTML/CSS aggressively and will keep the old zoom behavior after a deploy.
- `touch-action:pan-x pan-y` on `html,body` disables pinch-zoom app-wide, including image lightboxes. Re-enabling zoom for one element means overriding `touch-action` on it, but ancestor values constrain descendants — verify the override on a real device before relying on it.
