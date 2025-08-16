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