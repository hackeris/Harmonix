import { BuilderNode, NodeController } from "@kit.ArkUI";
import { pasteboard } from '@kit.BasicServicesKit'
import { FULL_PERCENT } from "../model/TabStyle";
import { TermController } from "../model/TermController";
import { util } from "@kit.ArkTS";

@Component
struct WebView {
  @Require item: TermController

  @Builder
  contextMenu(webController: WebviewController) {
    Flex({
      direction: FlexDirection.Column
    }) {
      MenuItem({ content: '复制' })
        .width('100%')
        .onClick(async () => {
          const selection = await webController.runJavaScript('exports.copy()')
          if (selection !== '""') {
            let text: string = JSON.parse(selection);
            const board = pasteboard.getSystemPasteboard()
            const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
            board.setData(pasteData)
          }
        })
      MenuItem() {
        PasteButton({ buttonType: ButtonType.ROUNDED_RECTANGLE })
          .onClick(async (event: ClickEvent, result: PasteButtonOnClickResult) => {
            if (PasteButtonOnClickResult.SUCCESS === result) {
              let board = pasteboard.getSystemPasteboard();
              const data = await board.getData()
              const text = data.getPrimaryText()
              const array = util.TextEncoder.create().encodeInto(text)
              const base64 = new util.Base64Helper().encodeToStringSync(array)
              webController.runJavaScript(`exports.paste(atob('${base64}'))`)
            }
          })
          .width('100%')
          .align(Alignment.Start)
          .backgroundColor('#292e2b')
      }
    }
    .width('160vp')
  }

  build() {
    Web({
      src: $rawfile('term.html'),
      controller: this.item.webviewController
    })
      .javaScriptProxy({
        object: this.item,
        name: 'native',
        methodList: ['sendInput', 'resize', 'load'],
        controller: this.item.webviewController,
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
      .backgroundColor('#000')
      .height(FULL_PERCENT)
      .bindContextMenu(this.contextMenu(this.item.webviewController), ResponseType.RightClick)
  }
}

@Builder
function buildWebView(item: TermController) {
  WebView({ item: item })
}

export class TermWebView extends NodeController {
  private webNode: BuilderNode<[TermController]> | null = null;
  private state: TermController

  constructor(webviewController: TermController) {
    super();
    this.state = webviewController;
  }

  makeNode(context: UIContext): FrameNode | null {
    if (this.webNode != null) {
      return this.webNode.getFrameNode()
    }
    // Creating a BuilderNode instance
    this.webNode = new BuilderNode(context);
    // Set the selfIdealSize property
    // this.textNode = new BuilderNode(context, {selfIdealSize: {width: 100, height :100}});
    // Build the component tree using the build method
    this.webNode.build(wrapBuilder<[TermController]>(buildWebView), this.state);
    // Returns the node to be displayed
    return this.webNode.getFrameNode();
  }
}