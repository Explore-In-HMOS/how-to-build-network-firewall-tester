import { BusinessError } from '@kit.BasicServicesKit';
import { lang } from '@kit.ArkTS';
import { sendablePreferences } from '@kit.ArkData';

export class SendablePreferenceHelper {
  private static instance: SendablePreferenceHelper;
  private preferences: sendablePreferences.Preferences | null = null;
  private context: Context | null = null;

  public static getInstance(): SendablePreferenceHelper {
    if (!SendablePreferenceHelper.instance) {
      SendablePreferenceHelper.instance = new SendablePreferenceHelper();
    }
    return SendablePreferenceHelper.instance;
  }

  public setContext(context: Context) {
    this.context = context;
  }

  public async init(): Promise<void> {
    if (!this.context) {
      return;
    }
    try {
      let options: sendablePreferences.Options = { name: 'sendable_store' };
      this.preferences = await sendablePreferences.getPreferences(this.context, options);
      console.info('SendablePreferences initialized');
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Init failed: ${error.code}, ${error.message}`);
    }
  }

  public async getValue(key: string, defValue: lang.ISendable): Promise<lang.ISendable> {
    if (!this.preferences) {
      return defValue;
    }
    try {
      let promise = this.preferences.get(key, defValue);
      let value = await promise;
      console.info(`Got value for key: ${key}`);
      return value;
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Get failed: ${error.code}, ${error.message}`);
      return defValue;
    }
  }

  public async putValue(key: string, value: lang.ISendable): Promise<void> {
    if (!this.preferences) {
      return;
    }
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
      console.info(`Put value for key: ${key}`);
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Put failed: ${error.code}, ${error.message}`);
    }
  }

  public async hasKey(key: string): Promise<boolean> {
    if (!this.preferences) {
      return false;
    }
    try {
      return await this.preferences.has(key);
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Has failed: ${error.code}, ${error.message}`);
      return false;
    }
  }

  public async deleteKey(key: string): Promise<void> {
    if (!this.preferences) {
      return;
    }
    try {
      await this.preferences.delete(key);
      await this.preferences.flush();
      console.info(`Deleted key: ${key}`);
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Delete failed: ${error.code}, ${error.message}`);
    }
  }
}
