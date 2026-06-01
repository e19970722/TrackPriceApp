// ElementPickerScript.swift
// Embeds both JS scripts as Swift string constants for injection into WKWebView.
// The canonical JS source lives in Resources/ElementPicker.js — keep in sync.

enum ElementPickerScript {

    // Injected once when the page finishes loading.
    // Records every user click into window.__interactions so variant selections
    // made before activating the picker are captured.
    static let recorder = """
(function() {
  if (window.__interactions !== undefined) return;
  window.__interactions = [];

  function buildLocator(el) {
    if (el.id) return '#' + el.id;
    for (const attr of el.attributes) {
      if (attr.name.startsWith('data-') && attr.value && !attr.value.includes(' ') && attr.value.length < 64) {
        return '[' + attr.name + '="' + attr.value + '"]';
      }
    }
    const seg = el.tagName.toLowerCase();
    const parent = el.parentElement;
    if (!parent || parent.tagName === 'BODY' || parent.tagName === 'HTML') return seg;
    const parentSeg = parent.id ? '#' + parent.id : parent.tagName.toLowerCase();
    return parentSeg + ' > ' + seg;
  }

  document.addEventListener('click', function(e) {
    if (window.__pickerActive) return;
    window.__interactions.push({ type: 'click', locator: buildLocator(e.target) });
  }, true);
})();
"""

    // Injected on demand when the user taps "Pick Element".
    // Activates highlight mode; the next tap sends the full interactions array.
    static let javascript = """
(function() {
  if (window.__pickerActive) return;
  window.__pickerActive = true;
  if (!window.__interactions) window.__interactions = [];

  let highlighted = null;

  function highlight(el) {
    if (highlighted) highlighted.style.outline = '';
    highlighted = el;
    el.style.outline = '3px solid #FF6B35';
  }

  function buildLocator(el) {
    if (el.id) return '#' + el.id;
    for (const attr of el.attributes) {
      if (attr.name.startsWith('data-') && attr.value && !attr.value.includes(' ') && attr.value.length < 64) {
        return '[' + attr.name + '="' + attr.value + '"]';
      }
    }
    const seg = el.tagName.toLowerCase();
    const parent = el.parentElement;
    if (!parent || parent.tagName === 'BODY' || parent.tagName === 'HTML') return seg;
    const parentSeg = parent.id ? '#' + parent.id : parent.tagName.toLowerCase();
    return parentSeg + ' > ' + seg;
  }

  function parseCurrency(text) {
    const symbols = ['NT$', '$', '\\u20ac', '\\u00a3', '\\u00a5', '\\u20a9'];
    for (const sym of symbols) {
      if (text.includes(sym)) return sym;
    }
    return '';
  }

  function parsePrice(text) {
    const m = text.match(/[\\d,]+\\.?\\d*/);
    return m ? parseFloat(m[0].replace(/,/g, '')) : null;
  }

  document.addEventListener('mouseover', e => highlight(e.target), true);
  document.addEventListener('touchmove', e => {
    const t = document.elementFromPoint(e.touches[0].clientX, e.touches[0].clientY);
    if (t) highlight(t);
  }, { passive: true });

  document.addEventListener('click', e => {
    e.preventDefault(); e.stopPropagation();
    const el = e.target;
    const text = (el.innerText || el.textContent || '').trim();
    const finalStep = {
      type: 'click',
      locator: buildLocator(el),
      role: 'price',
      rawText: text,
      currentPrice: parsePrice(text),
      currencySymbol: parseCurrency(text)
    };
    window.__interactions.push(finalStep);
    const ogImage = document.querySelector('meta[property="og:image"]')?.content
      || document.querySelector('meta[name="og:image"]')?.content
      || null;
    const pageTitle = document.querySelector('meta[property="og:title"]')?.content
      || document.querySelector('meta[name="og:title"]')?.content
      || document.title
      || null;
    const payload = { interactions: window.__interactions, itemImageUrl: ogImage, pageTitle: pageTitle };
    window.webkit.messageHandlers.elementPicked.postMessage(JSON.stringify(payload));
    if (highlighted) highlighted.style.outline = '';
    window.__pickerActive = false;
  }, true);
})();
"""
}
