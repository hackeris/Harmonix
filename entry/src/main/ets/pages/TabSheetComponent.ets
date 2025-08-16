import { FULL_PERCENT, STYLE_CONFIGURATION } from '../model/TabStyle';
import { TermModel } from '../model/TermModel';

const MAX_TABS = 8

@Component
export struct TabSheets {
  @Link tabArray: Array<TermModel>;
  @Link @Watch('onFocusIndexChange') focusIndex: number;
  @State middleIndex: number = this.focusIndex;
  @Require closeTabAndTerm: (id: number) => void
  @Require controller: TabsController

  onFocusIndexChange() {
    this.middleIndex = this.focusIndex;
  }

  build() {
    Row({ space: STYLE_CONFIGURATION.TAB_BAR_ITEM_GUTTER }) {
      ForEach(this.tabArray, (item: TermModel, index: number) => {
        Row({ space: STYLE_CONFIGURATION.TAB_BAR_CONTENT_GUTTER }) {
          Text($r('app.string.newSheet'))
            .textOverflow({ overflow: TextOverflow.Clip })
            .maxLines(1)
            .flexShrink(1)
          Stack() {
            Image($r('app.media.ic_public_cancel_filled'))
              .width(STYLE_CONFIGURATION.ICON_SIZE)
              .aspectRatio(1)
              .padding(2)
              .borderRadius(4)
              .onClick(() => {
                this.closeTabAndTerm(item.id)
              })
              .hoverEffect(HoverEffect.Highlight)
          }
        }
        .flexShrink(1)
        .padding({
          left: $r('sys.float.ohos_id_elements_margin_horizontal_m'),
          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
        })
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_xs'))
        .height(FULL_PERCENT)
        .backgroundColor(this.middleIndex === index ? '#222222' : $r('sys.color.ohos_id_color_sub_background'))
        .onClick(() => {
          this.controller.changeIndex(index);
          this.focusIndex = index;
        })

        Stack() {
          if (this.middleIndex !== index && this.middleIndex - 1 !== index) {
            Divider()
              .vertical(true)
              .strokeWidth(STYLE_CONFIGURATION.SEPARATOR_STROKE_WIDTH)
              .height('50%')
              .lineCap(LineCapStyle.Round)
          } else {
            Divider()
              .vertical(true)
              .strokeWidth(STYLE_CONFIGURATION.SEPARATOR_STROKE_WIDTH)
              .height('50%')
              .lineCap(LineCapStyle.Round)
              .color($r('sys.color.ohos_id_color_background_transparent'))
          }
        }
      }, (item: TermModel) => 'tab-' + item.id.toString())

      if (this.tabArray.length < MAX_TABS) {
        Image($r('app.media.ic_public_add_filled'))
          .width(STYLE_CONFIGURATION.ICON_SIZE)
          .aspectRatio(1)
          .padding(2)
          .borderRadius(4)
          .onClick(() => {

            const newArray = Array.from(this.tabArray)
            newArray.push(new TermModel(this.closeTabAndTerm));

            const newTabIndex: number = newArray.length - 1;

            this.tabArray = newArray;
            this.middleIndex = newTabIndex;
            this.getUIContext().animateTo({ duration: 200 }, () => {
              this.focusIndex = newTabIndex;
            })
          })
          .hoverEffect(HoverEffect.Highlight)
      }
    }
    .padding(STYLE_CONFIGURATION.TAB_SHEET_PADDING)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .width(FULL_PERCENT)
    .height(STYLE_CONFIGURATION.TAB_BAR_HEIGHT)
  }
}