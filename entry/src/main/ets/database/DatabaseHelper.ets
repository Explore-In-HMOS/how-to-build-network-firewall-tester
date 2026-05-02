import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { sendableRelationalStore } from '@kit.ArkData';
import { preferences } from '@kit.ArkData';
import { Employee } from '../model/Employee';

export class DatabaseHelper {
  private static instance: DatabaseHelper;
  private rdbStore: relationalStore.RdbStore | undefined = undefined;
  private context: common.UIAbilityContext | undefined = undefined;
  private dataPreferences: preferences.Preferences | undefined = undefined;

  public static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  public setContext(context: common.UIAbilityContext) {
    this.context = context;
  }

  public async initPreferences(): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(this.context!, 'employee_settings');
      console.info('Preferences initialized');
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Failed to get preferences: ${error.code}, ${error.message}`);
    }
  }

  public async getPreference(key: string, defaultValue: string): Promise<string> {
    if (!this.dataPreferences) {
      return defaultValue;
    }
    try {
      let promise = this.dataPreferences.get(key, defaultValue);
      let value = await promise;
      return value as string;
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Failed to get preference: ${error.code}, ${error.message}`);
      return defaultValue;
    }
  }

  public async setPreference(key: string, value: string): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    try {
      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();
      console.info(`Preference saved: ${key}=${value}`);
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Failed to set preference: ${error.code}, ${error.message}`);
    }
  }

  public async initializeDatabase(): Promise<relationalStore.RdbStore | undefined> {
    if (this.rdbStore) {
      return this.rdbStore;
    }

    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'EmployeeDB.db',
      securityLevel: relationalStore.SecurityLevel.S3
    };

    const SQL_CREATE_TABLE = `CREATE TABLE IF NOT EXISTS EMPLOYEE (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      NAME TEXT,
      AGE INTEGER,
      SALARY REAL,
      ASSET_DATA TEXT
    )`;

    try {
      this.rdbStore = await relationalStore.getRdbStore(this.context!, STORE_CONFIG);
      this.rdbStore.version = 2;
      console.info(`RDB Store version: ${this.rdbStore.version}, rebuilt: ${this.rdbStore.rebuilt}`);

      await this.rdbStore.executeSql(SQL_CREATE_TABLE);
      await this.insertSampleData();

      return this.rdbStore;
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Database init failed: ${error.code}, ${error.message}`);
      return undefined;
    }
  }

  private async insertSampleData(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    const checkPredicates = new relationalStore.RdbPredicates('EMPLOYEE');
    const resultSet = await this.rdbStore.query(checkPredicates);

    if (resultSet.rowCount === 0) {
      const employees: Array<Employee> = [
        new Employee(1, 'John Doe', 30, 50000 ),
        new Employee(2, 'Jane Smith', 25, 60000 ),
        new Employee(3, null, 28, 45000 ),
        new Employee(4, null, 32, 52000 ),
        new Employee(5, 'Alice Brown', 27, 58000 ),
        new Employee(6, 'Bob Wilson', 35, 65000 )
      ];

      for (const emp of employees) {
        const valueBucket: relationalStore.ValuesBucket = {
          'NAME': emp.name,
          'AGE': emp.age,
          'SALARY': emp.salary
        };
        await this.rdbStore.insert('EMPLOYEE', valueBucket);
      }
      console.info('Sample data inserted');
    }
    resultSet.close();
  }

  public createSendableAsset(): sendableRelationalStore.Asset {
    const asset: sendableRelationalStore.NonSendableAsset = {
      name: 'employee_photo',
      uri: 'file://employee/photo.jpg',
      path: '/data/employee/photo.jpg',
      createTime: Date.now().toString(),
      modifyTime: Date.now().toString(),
      size: '1024'
    };
    return sendableRelationalStore.toSendableAsset(asset);
  }

  public async getAllEmployees(): Promise<Employee[]> {
    if (!this.rdbStore) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates('EMPLOYEE');
    predicates.orderByAsc('ID');

    const resultSet = await this.rdbStore.query(predicates);
    const employees: Employee[] = [];

    while (resultSet.goToNextRow()) {
      employees.push(Employee.fromResultSet(resultSet));
    }

    resultSet.close();
    return employees;
  }

  public async getEmployeesWithNullName(): Promise<Employee[]> {
    if (!this.rdbStore) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates('EMPLOYEE');
    predicates.isNull('NAME');

    const resultSet = await this.rdbStore.query(predicates);
    const employees: Employee[] = [];

    while (resultSet.goToNextRow()) {
      employees.push(Employee.fromResultSet(resultSet));
    }

    resultSet.close();
    return employees;
  }

  public async addEmployee(name: string | null, age: number, salary: number): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'NAME': name,
      'AGE': age,
      'SALARY': salary
    };

    return await this.rdbStore.insert('EMPLOYEE', valueBucket);
  }

  public async getDatabaseVersion(): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    return this.rdbStore.version;
  }

  public async getRebuiltStatus(): Promise<relationalStore.RebuildType | undefined> {
    if (!this.rdbStore) {
      return undefined;
    }
    return this.rdbStore.rebuilt;
  }

  public async closeDatabase(): Promise<void> {
    if (this.rdbStore) {
      await this.rdbStore.close();
      this.rdbStore = undefined;
    }
  }

  public createSimpleAsset(assetName: string): sendableRelationalStore.Asset {
    const nonSendable: sendableRelationalStore.NonSendableAsset = {
      name: assetName,
      uri: `file:///data/${assetName}`,
      path: `/data/${assetName}`,
      createTime: Date.now().toString(),
      modifyTime: Date.now().toString(),
      size: '1024'
    };

    return sendableRelationalStore.toSendableAsset(nonSendable);
  }
}