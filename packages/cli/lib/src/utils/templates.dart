/// Custom index.html template with loading indicator
const String customIndexHtml = '''
<!DOCTYPE html>
<html>
<head>
  <base href="\$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">

  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="example">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>example</title>
  <link rel="manifest" href="manifest.json">

  <script>
    // The value below is injected by flutter build, do not touch.
    const serviceWorkerVersion = "{{flutter_service_worker_version}}";
  </script>
  <!-- This script adds the flutter initialization JS code -->
  <script src="flutter.js" defer></script>
  <style>
    /* Center the loading indicator */
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      background-color: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    }
    
    .loading-container {
      text-align: center;
    }
    
    /* Simple spinner animation */
    .spinner {
      width: 40px;
      height: 40px;
      margin: 0 auto 20px;
      border: 3px solid #f3f3f3;
      border-top: 3px solid #3498db;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    
    .loading-text {
      color: #666;
      font-size: 16px;
    }
    
    /* Hide loading indicator when app loads */
    .flutter-view {
      display: none;
    }
    
    body.loaded .loading-container {
      display: none;
    }
    
    body.loaded .flutter-view {
      display: block;
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <!-- Loading indicator -->
  <div class="loading-container">
    <div class="spinner"></div>
    <div class="loading-text">Loading presentation...</div>
  </div>
  
  <!-- Flutter view container -->
  <div class="flutter-view" id="flutter-view"></div>
  
  <script>
    window.addEventListener('load', function(ev) {
      // Download main.dart.js
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine().then(function(appRunner) {
            // Add loaded class to body when app starts running
            appRunner.runApp().then(function() {
              // Give Flutter a moment to render
              setTimeout(function() {
                document.body.classList.add('loaded');
              }, 100);
            });
          });
        }
      });
    });
  </script>
</body>
</html>
''';