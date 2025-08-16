import { webview } from '@kit.ArkWeb';
import { FULL_PERCENT } from '../model/TabStyle';
import { TabSheets } from './TabSheetComponent';
import { TermController } from '../model/TermController';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State tabArray: Array<TermController> = [new TermController(() => this.closeTab(0))];
  @State focusIndex: number = 0;
  private controller: TabsController = new TabsController();

  aboutToAppear(): void {
    webview.WebviewController.setWebDebuggingAccess(true)
  }

  closeTab(index: number): void {
    if (this.tabArray.length > 1) {

      let newArray = Array.from(this.tabArray)

      const removed = newArray.splice(index, 1)[0];
      removed.shutdown()

      this.tabArray = newArray;
      if (this.tabArray[index] === undefined) {
        this.focusIndex = index - 1;
      } else if (this.tabArray[index] !== undefined && this.focusIndex !== index) {
        this.focusIndex -= 1;
      }
    } else {
      (this.getUIContext().getHostContext() as common.UIAbilityContext)?.terminateSelf()
    }
  }

  build() {
    Column() {
      TabSheets({
        tabArray: $tabArray,
        focusIndex: $focusIndex,
        closeTab: this.closeTab,
        controller: this.controller
      })

      Divider()
        .width(FULL_PERCENT)
        .backgroundColor($r('sys.color.ohos_id_color_subheading_separator_dark'))

      Tabs({ barPosition: BarPosition.Start, index: this.focusIndex, controller: this.controller }) {
        ForEach(this.tabArray, (item: TermController, index: number) => {
          TabContent() {
            Column() {
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
            .height(FULL_PERCENT)
          }
        }, (item: TermController) => 'term-' + item.id.toString())
      }
      .scrollable(false)
      .barHeight(0)
      .onChange((index: number) => {
        this.focusIndex = index;
      })
    }
    .width("100%")
    .height('100%')
  }
}