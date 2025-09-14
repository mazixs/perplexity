// Bootstrap to enhance deep link handling while delegating to ToDesktop main
// Imports must be at the top
const { app, BrowserWindow } = require('electron');

// Load the original ToDesktop main process bundle
// It will create the BrowserWindow and wire up most behavior
const startOriginal = () => {
  try {
    require('./main.js');
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('[bootstrap] failed to require main.js:', e);
  }
};

function withMainWindow(callback) {
  const existing = BrowserWindow.getAllWindows();
  if (existing && existing.length > 0 && !existing[0].isDestroyed()) {
    callback(existing[0]);
    return;
  }
  // If no window yet, wait for the first one to be created
  app.once('browser-window-created', (_evt, win) => {
    if (win && !win.isDestroyed()) callback(win);
  });
}

function handleDeepLink(rawUrl) {
  if (!rawUrl || typeof rawUrl !== 'string') return;
  if (!rawUrl.startsWith('perplexity-app://')) return;
  try {
    const u = new URL(rawUrl);
    const desktopRedirect = u.searchParams.get('desktopRedirect');
    if (desktopRedirect) {
      const target = decodeURIComponent(desktopRedirect);
      app.whenReady().then(() => {
        withMainWindow((win) => {
          try {
            if (win.isMinimized()) win.restore();
            win.focus();
            win.loadURL(target);
          } catch (e) {
            // eslint-disable-next-line no-console
            console.error('[bootstrap] failed to load desktopRedirect', target, e);
          }
        });
      });
    }
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('[bootstrap] failed to parse deep link', rawUrl, e);
  }
}

// Ensure single instance so deep links are delivered via 'second-instance'
const gotLock = app.requestSingleInstanceLock();

if (!gotLock) {
  // Another instance is running; quit this one
  app.quit();
} else {
  // Attach deep link listeners EARLY, before starting original main
  app.whenReady().then(() => {
    const deepLinkArg = (process.argv || []).find((a) => typeof a === 'string' && a.startsWith('perplexity-app://'));
    if (deepLinkArg) handleDeepLink(deepLinkArg);
  });

  app.on('second-instance', (_event, argv) => {
    const deepLinkArg = (argv || []).find((a) => typeof a === 'string' && a.startsWith('perplexity-app://'));
    if (deepLinkArg) handleDeepLink(deepLinkArg);
    // Bring the main window to front as well
    withMainWindow((win) => {
      try {
        if (win.isMinimized()) win.restore();
        win.focus();
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error('[bootstrap] failed to focus window', e);
      }
    });
  });

  // Normalize base host to www.perplexity.ai (OAuth cookies are set on www)
  app.on('browser-window-created', (_evt, win) => {
    if (!win || win.isDestroyed()) return;
    const handler = () => {
      try {
        const current = win.webContents.getURL();
        if (!current) return;
        const urlObj = new URL(current);
        if (urlObj.hostname === 'perplexity.ai') {
          urlObj.hostname = 'www.perplexity.ai';
          win.loadURL(urlObj.toString());
        }
      } catch (_) { /* noop */ }
    };
    win.webContents.once('did-finish-load', handler);
  });

  // Optionally ensure protocol client registration (mostly for Windows/macOS)
  try { app.setAsDefaultProtocolClient('perplexity-app'); } catch (_) {}

  // Start the original ToDesktop app in primary instance only
  startOriginal();
}
