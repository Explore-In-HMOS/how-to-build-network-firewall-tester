import { relationalStore } from '@kit.ArkData';

export class Employee {
  id: number;
  name: string | null;
  age: number;
  salary: number;
  assetData?: string;

  constructor(id: number, name: string | null, age: number, salary: number, assetData?: string) {
    this.id = id;
    this.name = name;
    this.age = age;
    this.salary = salary;
    this.assetData = assetData;
  }

  static fromResultSet(resultSet: relationalStore.ResultSet): Employee {
    return new Employee(
      resultSet.getLong(resultSet.getColumnIndex('ID')),
      resultSet.getString(resultSet.getColumnIndex('NAME')),
      resultSet.getLong(resultSet.getColumnIndex('AGE')),
      resultSet.getDouble(resultSet.getColumnIndex('SALARY')),
      resultSet.getString(resultSet.getColumnIndex('ASSET_DATA'))
    );
  }

  get displayName(): string {
    return this.name ?? 'NULL';
  }

  get isNullName(): boolean {
    return this.name === null;
  }

  get formattedSalary(): string {
    return `$${this.salary.toFixed(0)}`;
  }
}