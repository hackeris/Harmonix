import { BuilderNode, NodeController } from "@kit.ArkUI";
import { FULL_PERCENT } from "../model/TabStyle";
import { TermController } from "../model/TermController";

@Builder
function buildWebView(item: TermController) {
  Web({
    src: $rawfile('term.html'),
    controller: item.webviewController
  })
    .javaScriptProxy({
      object: item,
      name: 'native',
      methodList: ['sendInput', 'resize', 'load'],
      controller: item.webviewController,
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
}

export class TermWebView extends NodeController {
  private textNode: BuilderNode<[TermController]> | null = null;
  private webviewController: TermController

  constructor(webviewController: TermController) {
    super();
    this.webviewController = webviewController;
  }

  makeNode(context: UIContext): FrameNode | null {
    // Creating a BuilderNode instance
    this.textNode = new BuilderNode(context);
    // Set the selfIdealSize property
    // this.textNode = new BuilderNode(context, {selfIdealSize: {width: 100, height :100}});
    // Build the component tree using the build method
    this.textNode.build(wrapBuilder<[TermController]>(buildWebView), this.webviewController);
    // Returns the node to be displayed
    return this.textNode.getFrameNode();
  }
}