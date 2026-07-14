window.addEventListener('message', function (event) {
  var data = event.data;

  if (data.hasOwnProperty('type')) {
    var type = data.type;
    var drawable = data.value;
    var max = data.max;
    var text = document.getElementById('text');
    if (text) text.innerHTML = drawable + '/' + max + ' ' + type;
  }

  if (data.hasOwnProperty('start')) {
    var text = document.getElementById('text');
    var container = document.getElementById('container');
    if (text) text.innerHTML = 'Loading up ...';
    if (container) container.style.display = 'block';
  }

  if (data.hasOwnProperty('end')) {
    var text = document.getElementById('text');
    var container = document.getElementById('container');
    if (text) text.innerHTML = 'Finished!';
    if (container) {
      setTimeout(function () {
        container.style.display = 'none';
      }, 2000);
    }
  }

  if (data.hasOwnProperty('error')) {
    var type = data.error;
    var text = document.getElementById('text');
    var container = document.getElementById('container');
    if (type == 'weathersync') {
      if (text) text.innerHTML = 'Disable weathersync resource!';
    } else {
      if (text) text.innerHTML = 'Error!';
    }
    if (container) {
      setTimeout(function () {
        container.style.display = 'none';
      }, 2000);
    }
  }

  // Placement mode UI
  if (data.action === 'placement') {
    var el = document.getElementById('placement');
    if (!el) return;
    if (data.show) {
      el.style.display = 'flex';
      el.innerHTML =
        '<div class="placement-box">' +
        '<div class="placement-title">PLACEMENT MODE</div>' +
        '<div class="placement-model">' + data.modelName + ' (' + data.index + '/' + data.total + ')</div>' +
        '<div class="placement-keys">' +
        '<span class="key">ARROWS</span> Move object<br>' +
        '<span class="key">CTRL+UP/DOWN</span> Object Z<br>' +
        '<span class="key">SHIFT+LEFT/RIGHT</span> Rotate object<br>' +
        '<span class="key">WASD</span> Camera move<br>' +
        '<span class="key">Q/E</span> Camera up/down<br>' +
        '<span class="key">MOUSE</span> Camera look<br>' +
        '<span class="key">SCROLL</span> FOV<br>' +
        '<span class="key">ENTER</span> Confirm<br>' +
        '<span class="key">BACKSPACE</span> Cancel' +
        '</div></div>';
    } else {
      el.style.display = 'none';
    }
  }

  // Queue screenshot to local API (non-blocking)
  if (data.action === 'saveLocal' && data.dataUrl && data.filename && data.apiUrl) {
    fetch(data.apiUrl + '/queue', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        filename: data.filename + '.png',
        image: data.dataUrl,
        removeBg: true,
        tolerance: 50
      })
    }).then(function (res) {
      if (data.debug) console.log('[greenscreener] Queued: ' + data.filename);
    }).catch(function (err) {
      console.error('[greenscreener] Queue error: ' + err);
    });
  }
});
