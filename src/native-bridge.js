import { Capacitor } from '@capacitor/core';
import { Filesystem } from '@capacitor/filesystem';
import { Share } from '@capacitor/share';

// The web UI is plain HTML, so expose the native plugin proxies explicitly.
window.WeightTimeNative = {
  isNative: () => Capacitor.isNativePlatform(),
  Filesystem,
  Share,
};
