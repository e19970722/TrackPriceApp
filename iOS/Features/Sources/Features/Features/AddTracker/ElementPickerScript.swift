// This file embeds ElementPicker.js as a Swift string constant so it can be
// injected into WKWebView without depending on Bundle.module resource loading.
// The canonical source is Resources/ElementPicker.js — keep the two in sync.

enum ElementPickerScript {
    static let javascript = """
(function() {
  if (window.__pickerActive) return;
  window.__pickerActive = true;

  let highlighted = null;

  function highlight(el) {
    if (highlighted) highlighted.style.outline = '';
    highlighted = el;
    el.style.outline = '3px solid #FF6B35';
  }

  function buildSelector(el) {
    const parts = [];
    while (el && el.nodeType === 1 && el.tagName !== 'HTML') {
      let seg = el.tagName.toLowerCase();
      if (el.id) { seg += '#' + el.id; parts.unshift(seg); break; }
      const siblings = Array.from(el.parentNode?.children || []).filter(s => s.tagName === el.tagName);
      if (siblings.length > 1) seg += ':nth-of-type(' + (siblings.indexOf(el) + 1) + ')';
      parts.unshift(seg);
      el = el.parentElement;
    }
    return parts.join(' > ');
  }

  function buildXPath(el) {
    const parts = [];
    while (el && el.nodeType === 1) {
      let idx = 1;
      let sib = el.previousSibling;
      while (sib) { if (sib.nodeType === 1 && sib.tagName === el.tagName) idx++; sib = sib.previousSibling; }
      parts.unshift(el.tagName.toLowerCase() + '[' + idx + ']');
      el = el.parentElement;
    }
    return '/' + parts.join('/');
  }

  function parseCurrency(text) {
    const symbols = { '$': 'USD', '\\u20ac': 'EUR', '\\u00a3': 'GBP', '\\u00a5': 'JPY', 'NT$': 'TWD', '\\u20a9': 'KRW' };
    for (const [sym, _] of Object.entries(symbols)) {
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
    const payload = {
      cssSelector: buildSelector(el),
      xpath: buildXPath(el),
      rawText: text,
      currentPrice: parsePrice(text),
      currencySymbol: parseCurrency(text)
    };
    window.webkit.messageHandlers.elementPicked.postMessage(JSON.stringify(payload));
    if (highlighted) highlighted.style.outline = '';
    window.__pickerActive = false;
  }, true);
})();
"""
}
