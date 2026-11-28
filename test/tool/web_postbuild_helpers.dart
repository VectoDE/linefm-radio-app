const String engineRev = '371f77202a73e8dff57a8b3bff75bca55c090aee';

String bootstrap() =>
    '''
(function(){})();
if (!window._flutter) {
  window._flutter = {};
}
_flutter.buildConfig = {"engineRevision":"$engineRev","wasmHashes":{"skwasm.wasm":"aa","main.dart.wasm":"bb"},"builds":[{"compileTarget":"dart2wasm","renderer":"skwasm","mainWasmPath":"main.dart.wasm","jsSupportRuntimePath":"main.dart.mjs"},{"compileTarget":"dart2js","renderer":"canvaskit","mainJsPath":"main.dart.js"}],"useLocalCanvasKit":true};
(function () {
  var config = {};
  /*__CANVASKIT_BASE_URL__*/
})();
''';
