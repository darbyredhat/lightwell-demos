// Slideshow player for a demo's slides/index.html.
// List the slides in order on the body: <body data-slides="opening.html recap.html">
// Keys: Right, Space, or click for next; Left for previous; Home and End; F for full screen.
// The URL hash holds the slide number, so index.html#2 opens on the second slide.
(function () {
  const WIDTH = 1920;
  const HEIGHT = 1080;
  const names = document.body.dataset.slides.trim().split(/\s+/);

  const style = document.createElement('style');
  style.textContent = `
    html, body { margin: 0; height: 100%; background: #000; overflow: hidden; cursor: pointer; }
    iframe {
      position: absolute; left: 50%; top: 50%; width: ${WIDTH}px; height: ${HEIGHT}px;
      border: 0; background: #fff; pointer-events: none; visibility: hidden;
    }
    iframe.current { visibility: visible; }
  `;
  document.head.appendChild(style);

  const frames = names.map((name) => {
    const frame = document.createElement('iframe');
    frame.src = name;
    frame.title = name;
    frame.tabIndex = -1;
    document.body.appendChild(frame);
    return frame;
  });

  let current = 0;

  function show(index) {
    current = Math.max(0, Math.min(frames.length - 1, index));
    frames.forEach((frame, i) => frame.classList.toggle('current', i === current));
    history.replaceState(null, '', '#' + (current + 1));
  }

  function fit() {
    const scale = Math.min(window.innerWidth / WIDTH, window.innerHeight / HEIGHT);
    frames.forEach((frame) => {
      frame.style.transform = `translate(-50%, -50%) scale(${scale})`;
    });
  }

  function toggleFullscreen() {
    if (document.fullscreenElement) {
      document.exitFullscreen();
    } else {
      document.documentElement.requestFullscreen();
    }
  }

  document.addEventListener('keydown', (event) => {
    switch (event.key) {
      case 'ArrowRight': case 'ArrowDown': case 'PageDown': case ' ':
        show(current + 1); break;
      case 'ArrowLeft': case 'ArrowUp': case 'PageUp': case 'Backspace':
        show(current - 1); break;
      case 'Home':
        show(0); break;
      case 'End':
        show(frames.length - 1); break;
      case 'f': case 'F':
        toggleFullscreen(); break;
      default:
        return;
    }
    event.preventDefault();
  });
  document.addEventListener('click', () => show(current + 1));
  window.addEventListener('resize', fit);

  fit();
  show((parseInt(location.hash.slice(1), 10) || 1) - 1);
})();
