'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "5aecac79c065847025e7e93be5dd19ef",
"version.json": "d0a9f4fe9316e5c29e0a71d35e7ddfb9",
"index.html": "d5bef24ce8fb75fb8cda50687be8ca56",
"/": "d5bef24ce8fb75fb8cda50687be8ca56",
"main.dart.js": "386cbd82c5c2c7defc26c46d366009db",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "0867c3e13649ac4d06fe34b7b3ddce08",
"assets/AssetManifest.json": "0455c772a15f0c4ab7bca347679d4b4d",
"assets/NOTICES": "661404f4c271a3b4829d3458a5cdef2b",
"assets/.superdeck/generated_assets.json": "7049e521b68b36871c330512256fc873",
"assets/.superdeck/assets/thumbnail_pukXIjvK.png": "2d02d44ee3990d8b9e8525b494f06414",
"assets/.superdeck/assets/thumbnail_14RbmSW5.png": "41c21de65e9161813da2ab0da97d5d97",
"assets/.superdeck/assets/thumbnail_H2GzZVSx.png": "15e9f1976c5c37effc8ea9c01c06651b",
"assets/.superdeck/assets/thumbnail_oglBIjM0.png": "d7b05c2ce1c8918f8de8d316b5870bce",
"assets/.superdeck/assets/thumbnail_mUUhzDVx.png": "64f160b883d0edb036a907c92343c92a",
"assets/.superdeck/assets/thumbnail_z34aal1W.png": "45ba0ef72f6a36fa6b137b0f513c0d2d",
"assets/.superdeck/assets/thumbnail_9mHDFwa9.png": "2ed85304690f2aee0caaf58f6b97dd80",
"assets/.superdeck/assets/thumbnail_3sLdrfsM.png": "a6af60b24ae8aa636683e2af88b6edb0",
"assets/.superdeck/assets/thumbnail_nPPBLQ6k.png": "ec89eca2487212d449140141f32239bf",
"assets/.superdeck/assets/thumbnail_RiDZbaFZ.png": "48b9268e68a0973303909abf17d9b672",
"assets/.superdeck/assets/thumbnail_CwxHOCpO.png": "19c37123020c2a23c6fdd88e19ff49b8",
"assets/.superdeck/assets/thumbnail_ybLDY8oi.png": "128566303c29ab1d53ea90bf5e76c02e",
"assets/.superdeck/assets/thumbnail_cS8UY7ii.png": "5b8345cbec6c8c194cd873a4b67015ff",
"assets/.superdeck/assets/thumbnail_9y5hBeTm.png": "b59ec0a2127963c9c851c5eed12b9d77",
"assets/.superdeck/assets/thumbnail_XeDZiCNk.png": "15d8dff0aa2ede713ab4bc0869afcced",
"assets/.superdeck/assets/thumbnail_aTAXFyQ7.png": "f260ed0f4e4facf6cbb3f7878a848873",
"assets/.superdeck/assets/thumbnail_F2fTbXOG.png": "e7fd8d62bb5b93838a44e1bd7da8da0c",
"assets/.superdeck/assets/thumbnail_0zqy1l5c.png": "dc1f82f63fc31e27d4b55b079beda8c1",
"assets/.superdeck/assets/thumbnail_Z40wIUYP.png": "f2f7133bdb46be650c2fc1985c6cc248",
"assets/.superdeck/assets/mermaid_srHRIuii.png": "f66baa993deba14402a1b65f79ca2f3a",
"assets/.superdeck/assets/thumbnail_SJncL4H2.png": "c49b0060d304689531787c94620d9017",
"assets/.superdeck/assets/thumbnail_9BmK4SPw.png": "74ed5b7f0473c6fc4fdabe7c4968d9e1",
"assets/.superdeck/superdeck.json": "3ddd191580efe4bb82a76eaf9d030df7",
"assets/FontManifest.json": "c75353fbeebcd695f0652f190c83d46c",
"assets/AssetManifest.bin.json": "f5f525d69666aeeef5f4d28df680239f",
"assets/packages/mesh/shaders/omesh.frag": "242b80a0ff93acfab4745ef36f76f6f2",
"assets/packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf": "c6b7a65d9869a13814fae31825154fbe",
"assets/packages/material_symbols_icons/lib/fonts/MaterialSymbolsOutlined.ttf": "fb130bde670810da1f18a4d8fd789462",
"assets/packages/material_symbols_icons/lib/fonts/MaterialSymbolsSharp.ttf": "eb066c73fd60e01b4e001a6ab1717ac5",
"assets/packages/syntax_highlight/grammars/sql.json": "957a963dfa0e8d634766e08c80e00723",
"assets/packages/syntax_highlight/grammars/serverpod_protocol.json": "cc9b878a8ae5032ca4073881e5889fd5",
"assets/packages/syntax_highlight/grammars/yaml.json": "7c2dfa28161c688d8e09478a461f17bf",
"assets/packages/syntax_highlight/grammars/dart.json": "b533a238112e4038ed399e53ca050e33",
"assets/packages/syntax_highlight/grammars/json.json": "e608a2cc8f3ec86a5b4af4d7025ae43f",
"assets/packages/syntax_highlight/themes/dark_vs.json": "2839d5be4f19e6b315582a36a6dcd1c3",
"assets/packages/syntax_highlight/themes/light_vs.json": "8025deae1ca1a4d1cb803c7b9f8528a1",
"assets/packages/syntax_highlight/themes/dark_plus.json": "b212b7b630779cb4955e27a1c228bf71",
"assets/packages/syntax_highlight/themes/light_plus.json": "2a29ad892e1f54e93062fee13b3688c6",
"assets/packages/superdeck/assets/iframe_template.html": "28417fda1b5e7832f38d11361bb7678d",
"assets/packages/superdeck/assets/grammars/mermaid.json": "f039db8062fc65efbf0e76021183a3b2",
"assets/packages/superdeck/assets/grammars/markdown.json": "d96cbef20f36810bf6f2b4097fb58891",
"assets/packages/superdeck/assets/grammars/python.json": "56cc793c1fb3dcb9fa6f09ea48ff7dc5",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "fdf1ba2f3fc4ecbfc70d57ae5b5addb8",
"assets/fonts/MaterialIcons-Regular.otf": "0f8597cb68aa4b6388fa698df676bdd1",
"assets/assets/widget_response.png": "594f2ca8f52032560e78bcc2910c8495",
"assets/assets/llm_tools.png": "39a04672f0efb5833cc4a253e21912a6",
"assets/assets/llm_interaction.png": "fcd3f12c86082c73067d5132e998beb8",
"assets/assets/structured_output.png": "44c029c87175c13327b4d25b692226fe",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
