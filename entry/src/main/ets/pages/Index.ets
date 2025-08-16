import { webview } from '@kit.ArkWeb';
import { FULL_PERCENT } from '../model/TabStyle';
import { TabSheets } from './TabSheetComponent';
import { TermModel } from '../model/TermModel';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State tabArray: Array<TermModel> = [new TermModel(id => this.closeTabAndTerm(id))];
  @State focusIndex: number = 0;
  private controller: TabsController = new TabsController();

  aboutToAppear(): void {
    webview.WebviewController.setWebDebuggingAccess(true)
  }

  closeTabAndTerm(id: number): void {

    let index = this.tabArray.findIndex(it => it.id === id)

    if (this.tabArray.length > 1) {

      let newArray = Array.from(this.tabArray)

      const removed = newArray.splice(index, 1)[0];
      removed.controller.shutdown()

      this.tabArray = newArray;
      if (this.tabArray[index] === undefined) {
        this.focusIndex = index - 1;
      } else if (this.tabArray[index] !== undefined
        && this.focusIndex !== index) {
        this.focusIndex -= 1;
      }

      focusControl.requestFocus('tabs')
    } else {
      (this.getUIContext().getHostContext() as common.UIAbilityContext)?.terminateSelf()
    }
  }

  build() {
    Column() {
      TabSheets({
        tabArray: $tabArray,
        focusIndex: $focusIndex,
        closeTabAndTerm: id => this.closeTabAndTerm(id),
        controller: this.controller
      })

      Divider()
        .height(1)
        .width(FULL_PERCENT)
        .backgroundColor($r('sys.color.ohos_id_color_subheading_separator_dark'))

      Tabs({ barPosition: BarPosition.Start, index: this.focusIndex, controller: this.controller }) {
        ForEach(this.tabArray, (item: TermModel, index: number) => {
          TabContent() {
            Column() {
              NodeContainer(item.view)
                .width('100%')
                .height('100%')
            }
            .height(FULL_PERCENT)
          }
        }, (item: TermModel) => 'term-' + item.id.toString())
      }
      .id('tabs')
      .scrollable(false)
      .barHeight(0)
      .layoutWeight(1)
      .onChange((index: number) => {
        this.focusIndex = index;
      })
    }
    .width("100%")
    .height('100%')
  }
}