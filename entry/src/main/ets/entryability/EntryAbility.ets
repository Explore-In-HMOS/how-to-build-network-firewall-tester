import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { SendablePreferenceHelper } from '../database/SendablePreferenceHelper';

export default class EntryAbility extends UIAbility {
  async onWindowStageCreate(windowStage: window.WindowStage) {
    DatabaseHelper.getInstance().setContext(this.context);
    await DatabaseHelper.getInstance().initPreferences();
    await DatabaseHelper.getInstance().initializeDatabase();

    // Test preferences
    await DatabaseHelper.getInstance().setPreference('last_visit', Date.now().toString());
    await DatabaseHelper.getInstance().getPreference('startup', 'default');

    // Test SendableAsset
    DatabaseHelper.getInstance().createSendableAsset();

    SendablePreferenceHelper.getInstance().setContext(this.context);
    await SendablePreferenceHelper.getInstance().init();

    try {
      let result = await SendablePreferenceHelper.getInstance().getValue('startup', 'default');
      let dataStr = result as string;
      console.info(`✅ SendablePreferences get: startup = ${dataStr}`);

      await SendablePreferenceHelper.getInstance().putValue('last_user', 'JohnDoe');

      let hasKey = await SendablePreferenceHelper.getInstance().hasKey('last_user');
      console.info(`Has last_user: ${hasKey}`);
    } catch (err) {
      console.error(`SendablePreferences test failed: ${err}`);
    }

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error(`Load error: ${err.code}`);
      }
    });
  }

  onWindowStageDestroy() {
    DatabaseHelper.getInstance().closeDatabase();
  }
}