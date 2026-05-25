// RecorderScript — injected once at page load to capture all user interactions
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

// PickerScript — injected on demand when user taps "Pick Element"
// (kept here for reference; canonical Swift embed is in ElementPickerScript.swift)
