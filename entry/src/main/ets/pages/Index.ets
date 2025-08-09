import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import napi from 'libentry.so';

const DOMAIN = 0x0001;

interface Size {
  width: number,
  height: number
}

class NativeProxy {
  webviewController: webview.WebviewController

  constructor(webviewController: webview.WebviewController) {
    this.webviewController = webviewController
  }

  propUpdate(key: object, value: object): void {
    hilog.info(DOMAIN, 'native', '%{public}s', 'propUpdate: ' + key + ", value: " + value);
  }

  sendInput(data: string): void {
    hilog.info(DOMAIN, 'native', '%{public}s', 'sendInput: ' + data);
    this.webviewController.runJavaScript('exports.write("' + data + '")')
  }

  async resize(): Promise<void> {
    const s = await this.getSize();
    hilog.info(DOMAIN, 'native', '%{public}s', 'resize: ' + s.width + ", " + s.height)
  }

  focus(): void {
    hilog.info(DOMAIN, 'native', '%{public}s', 'focus')
  }

  syncFocus(): void {
    hilog.info(DOMAIN, 'native', '%{public}s', 'syncFocus')
  }

  newScrollHeight(h: number): void {
    hilog.info(DOMAIN, 'native', '%{public}s', 'newScrollHeight: ' + h)
  }

  newScrollTop(h: number): void {
    hilog.info(DOMAIN, 'native', '%{public}s', 'newScrollTop: ' + h)
  }

  openLink(url: string): void {
    hilog.info(DOMAIN, 'native', '%{public}s', 'openLink: ' + url)
  }

  async load(): Promise<void> {
    hilog.info(DOMAIN, 'native', '%{public}s', 'load')
    this.webviewController.runJavaScript('exports.write("shell")')
    this.webviewController.runJavaScript('exports.setFocused(true)')

    const s: Size = await this.getSize();

    console.log('w: ' + s.width + ', h: ' + s.height)
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