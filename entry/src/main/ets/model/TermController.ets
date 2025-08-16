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

let termId = 0

export class TermController {
  webviewController: webview.WebviewController
  id: number
  close: () => void

  constructor(close: () => void) {
    this.webviewController = new webview.WebviewController()
    this.id = ++termId;
    this.close = close;
  }

  shutdown() {
    hilog.info(DOMAIN, 'WebTerminal', 'close, id: %{public}d', this.id);
    napi.close(this.id)
  }

  sendInput(data: string): void {

    hilog.info(DOMAIN, 'WebTerminal', 'sendInput, id: %{public}d, data: %{public}s', this.id, data);
    let buffer = stringToArrayBuffer(data, 'utf-8');

    napi.send(this.id, buffer)
  }

  async resize(): Promise<void> {
    const s = await this.getSize();

    hilog.info(DOMAIN, 'WebTerminal',
      'resize, id: %{public}d, (%{public}d, %{public}d)', this.id, s.width, s.height)

    napi.resize(this.id, s.width, s.height)
  }

  async load(): Promise<void> {

    hilog.info(DOMAIN, 'WebTerminal', 'load, id: %{public}d', this.id)

    this.webviewController.runJavaScript('exports.setFocused(true)')

    const s: Size = await this.getSize();

    napi.run(this.id, s.width, s.height, (a: ArrayBuffer) => {

      let dec = util.TextDecoder.create('utf-8', { ignoreBOM: true })
      let s: string = dec.decodeToString(new Uint8Array(a))

      hilog.info(DOMAIN, 'WebTerminal', 'write, id: %{public}d, data: %{public}s', this.id, s)

      this.webviewController.runJavaScript('exports.write("' + s + '")')
    }, () => this.close())
  }

  private async getSize(): Promise<Size> {
    const ext = await this.webviewController.runJavaScriptExt('exports.getSize()');
    const arr = ext.getArray();
    return { width: arr[0] as number, height: arr[1] as number };
  }
}