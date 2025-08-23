import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { STYLE_CONFIGURATION } from '../model/TabStyle';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    if (canIUse('SystemCapability.Window.SessionManager')) {
      windowStage.getMainWindow((err: BusinessError, window: window.Window) => {
        if (err.code) {
          hilog.error(0x0000, 'testTag', 'Failed to get the main window. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        window.setWindowDecorVisible(false);
        window.setWindowDecorHeight(STYLE_CONFIGURATION.TAB_BAR_HEIGHT);
      });
    }

    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    await atManager.requestPermissionsFromUser(this.context, ['ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY']);
    await atManager.requestPermissionsFromUser(this.context, ['ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY']);
  }

  px2vp(px: number) {
    return px / display.getDefaultDisplaySync().densityPixels;
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}