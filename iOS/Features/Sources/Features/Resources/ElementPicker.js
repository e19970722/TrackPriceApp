// RecorderScript — injected once at page load to capture all user interactions
(function() {
  if (window.__interactions !== undefined) return;
  window.__interactions = [];

  function buildLocator(el) {
    if (el.id) return '#' + CSS.escape(el.id);
    for (const attr of el.attributes) {
      if (attr.name.startsWith('data-') && attr.value && !attr.value.includes(' ') && attr.value.length < 64) {
        return '[' + attr.name + '="' + attr.value + '"]';
      }
    }
    const tag = el.tagName.toLowerCase();
    if (el.classList.length > 0) {
      const classes = Array.from(el.classList).map(c => '.' + CSS.escape(c)).join('');
      return tag + classes;
    }
    const parent = el.parentElement;
    if (!parent || parent.tagName === 'BODY' || parent.tagName === 'HTML') return tag;
    const parentSeg = parent.id ? '#' + CSS.escape(parent.id) : parent.tagName.toLowerCase();
    return parentSeg + ' > ' + tag;
  }

  document.addEventListener('click', function(e) {
    if (window.__pickerActive) return;
    window.__interactions.push({ type: 'click', locator: buildLocator(e.target) });
  }, true);
})();

// PickerScript — injected on demand when user taps "Pick Element"
// (kept here for reference; canonical Swift embed is in ElementPickerScript.swift)
