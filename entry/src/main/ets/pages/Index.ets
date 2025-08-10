import util from '@ohos.util';
import { buffer } from '@kit.ArkTS';
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import napi from 'libentry.so';

const DOMAIN = 0x0001;

interface Size {
  width: number,
  height: number
}

function stringToArrayBuffer(str: string, encoding: buffer.BufferEncoding = 'utf-8'): ArrayBuffer {
  const buf = buffer.from(str, encoding);
  return buf.buffer;
}

class NativeProxy {
  webviewController: webview.WebviewController

  constructor(webviewController: webview.WebviewController) {
    this.webviewController = webviewController
  }

  propUpdate(key: object, value: object): void {
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'propUpdate: ' + key + ", value: " + value);
  }

  sendInput(data: string): void {
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'sendInput: ' + data);
    let buffer = stringToArrayBuffer(data, 'utf-8');
    napi.send(buffer)
  }

  async resize(): Promise<void> {
    const s = await this.getSize();
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'resize: ' + s.width + ", " + s.height)
  }

  focus(): void {
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'focus')
  }

  syncFocus(): void {
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'syncFocus')
  }

  newScrollHeight(h: number): void {
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'newScrollHeight: ' + h)
  }

  newScrollTop(h: number): void {
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'newScrollTop: ' + h)
  }

  openLink(url: string): void {
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'openLink: ' + url)
  }

  async load(): Promise<void> {
    hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'load')
    this.webviewController.runJavaScript('exports.setFocused(true)')

    const s: Size = await this.getSize();

    napi.subscribe((a: ArrayBuffer) => {
      let dec = util.TextDecoder.create('utf-8', { ignoreBOM: true })
      let s: string = dec.decodeToString(new Uint8Array(a))

      hilog.info(DOMAIN, 'WebTerminal', '%{public}s', 'write: ' + s)

      this.webviewController.runJavaScript('exports.write("' + s + '")')
    })

    napi.run(s.width, s.height)
  }

  private async getSize(): Promise<Size> {
    const ext = await this.webviewController.runJavaScriptExt('exports.getSize()');
    const arr = ext.getArray();
    const w = arr[0] as number, h = arr[1] as number;
    return { width: w, height: h };
  }
}

@Entry
@Component
struct Index {
  webviewController: webview.WebviewController = new webview.WebviewController()
  native: NativeProxy = new NativeProxy(this.webviewController);

  aboutToAppear(): void {
    webview.WebviewController.setWebDebuggingAccess(true)
    hilog.info(DOMAIN, 'testTag', 'Test NAPI 2 + 3 = %{public}d', napi.add(2, 3));
  }

  build() {
    Column() {
      Web({
        src: $rawfile('term.html'),
        controller: this.webviewController
      })
        .javaScriptProxy({
          object: this.native,
          name: 'native',
          methodList: ['propUpdate', 'sendInput', 'resize', 'focus', 'syncFocus',
            'newScrollHeight', 'newScrollTop', 'openLink', 'load', 'syncFocus'],
          controller: this.webviewController,
          asyncMethodList: [],
          permission: `{
  "javascriptProxyPermission": {
    "urlPermissionList": [
      {
        "scheme": "resource",
        "host": "rawfile",
        "port": "",
        "path": ""
      }
    ]
  }
}`
        })
    }
    .width('100%')
    .height('100%')
  }
}