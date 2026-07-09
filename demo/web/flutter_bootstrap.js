// superdeck:managed bootstrap
{{flutter_js}}
{{flutter_build_config}}

;(() => {
  const loader = document.getElementById('flutter-loader');
  const loaderCopy = document.getElementById('flutter-loader-copy');
  const loaderErrorTimeout = window.setTimeout(() => {
    if (!loader || !loaderCopy || loader.classList.contains('is-hidden')) {
      return;
    }

    loaderCopy.classList.add('is-error');
    loaderCopy.textContent =
      'Startup is taking longer than expected. Refresh the page or check the browser console.';
  }, 15000);

  function updateLoaderCopy(text) {
    if (!loaderCopy) {
      return;
    }

    loaderCopy.classList.remove('is-error');
    loaderCopy.textContent = text;
  }

  function hideLoader() {
    if (!loader) {
      return;
    }

    window.clearTimeout(loaderErrorTimeout);
    loader.classList.add('is-hidden');
    window.setTimeout(() => loader.remove(), 220);
  }

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      updateLoaderCopy('Initializing engine…');
      const appRunner = await engineInitializer.initializeEngine();

      updateLoaderCopy('Starting app…');
      await appRunner.runApp();

      hideLoader();
    },
  });
})();
