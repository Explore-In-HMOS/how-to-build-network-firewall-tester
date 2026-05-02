import { DatabaseHelper } from '../database/DatabaseHelper';
import { PromptAction, promptAction } from '@kit.ArkUI';
import { Employee } from '../model/Employee';
import { SendablePreferenceHelper } from '../database/SendablePreferenceHelper';

@Entry
@Component
struct Index {
  @State employees: Employee[] = [];
  @State nullNameEmployees: Employee[] = [];
  @State dbVersion: number = 0;
  @State rebuiltStatus: string = '';
  @State newName: string = '';
  @State newAge: string = '';
  @State newSalary: string = '';
  private activeTab: number = 0;
  @State currentIndex: number = 0;
  @State sendableKey: string = '';
  @State sendableValue: string = '';
  @State sendableResult: string = '';
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    const version = await DatabaseHelper.getInstance().getDatabaseVersion();
    const rebuilt = await DatabaseHelper.getInstance().getRebuiltStatus();
    this.dbVersion = version;
    this.rebuiltStatus = rebuilt ? 'Yes' : 'No';
    this.employees = await DatabaseHelper.getInstance().getAllEmployees();
    this.nullNameEmployees = await DatabaseHelper.getInstance().getEmployeesWithNullName();
  }

  async addEmployee() {
    if (!this.newAge || !this.newSalary) {
      this.promptAction.showToast({ message: 'Fill all fields', duration: 1500 });
      return;
    }
    const age = parseInt(this.newAge);
    const salary = parseFloat(this.newSalary);
    const name = this.newName.trim() === '' ? null : this.newName;

    if (isNaN(age) || isNaN(salary)) {
      this.promptAction.showToast({ message: 'Invalid numbers', duration: 1500 });
      return;
    }

    await DatabaseHelper.getInstance().addEmployee(name, age, salary);
    await this.loadData();
    this.newName = '';
    this.newAge = '';
    this.newSalary = '';
    this.promptAction.showToast({ message: 'Added!', duration: 1500 });
  }

  async saveSendablePref() {
    if (!this.sendableKey.trim()) {
      this.promptAction.showToast({ message: 'Enter key', duration: 1000 });
      return;
    }
    await SendablePreferenceHelper.getInstance().putValue(this.sendableKey, this.sendableValue);
    this.sendableResult = `✓ Saved: ${this.sendableKey}=${this.sendableValue}`;
    this.promptAction.showToast({ message: 'Saved', duration: 1000 });
    this.sendableKey = '';
    this.sendableValue = '';
    setTimeout(() => this.sendableResult = '', 2000);
  }

  async getSendablePref() {
    if (!this.sendableKey.trim()) {
      this.promptAction.showToast({ message: 'Enter key', duration: 1000 });
      return;
    }
    let val = await SendablePreferenceHelper.getInstance().getValue(this.sendableKey, 'not found');
    this.sendableResult = `${this.sendableKey} = ${val}`;
    setTimeout(() => this.sendableResult = '', 2000);
  }

  @Builder
  tabBuilder(title: ResourceStr, targetIndex: number) {
    Column() {
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#ffffffff')
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Bold : FontWeight.Normal)
        .fontSize(14)
      Divider()
        .height(1)
        .color(this.currentIndex === targetIndex ? '#1698CE' : Color.Transparent)
        .width('90%')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(20)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text('Version').fontSize(10).fontColor('#ffc6c6c6')
          Text(`${this.dbVersion}`).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#007DFF')
        }.alignItems(HorizontalAlign.Center).margin({ right: 10 })

        Divider().vertical(true).height(30)

        Column() {
          Text('Rebuilt').fontSize(10).fontColor('#ffc6c6c6')
          Text(`${this.rebuiltStatus}`).fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor(this.rebuiltStatus === 'Yes' ? '#FF6B6B' : '#4CAF50')
        }.alignItems(HorizontalAlign.Center).margin({ left: 10 })
      }
      .width('50%')
      .height(32)
      .backgroundColor('#74696969')
      .borderRadius(50)
      .margin({ top: 15 })
      .padding({ top: 2, bottom: 2 })
      .justifyContent(FlexAlign.Center)

      Tabs({ index: this.activeTab }) {
        TabContent() {
          List({ space: 6 }) {
            ForEach(this.employees, (emp: Employee) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(emp.name === '' ? 'NULL' : emp.name).fontSize(12).fontWeight(FontWeight.Medium)
                      .fontColor(emp.name === '' ? '#FF6B6B' : '#ffffffff')
                    Text(`ID:${emp.id} Age:${emp.age}`).fontSize(10).fontColor('#999')
                  }
                  .alignItems(HorizontalAlign.Start)

                  Blank()
                  Text(`$${emp.salary.toFixed(0)}`).fontSize(14).fontColor('#4CAF50')
                }
                .width('100%')
                .padding({
                  top: 8,
                  bottom: 8,
                  left: 20,
                  right: 20
                })
                .backgroundColor('#74696969')
                .borderRadius(8)
              }
            }, (emp: Employee) => emp.id.toString())
          }
          .width('90%').layoutWeight(1)
        }
        .tabBar(this.tabBuilder('All', 0))

        TabContent() {
          Column() {
            if (this.nullNameEmployees.length === 0) {
              Text('No NULL names').fontSize(14).fontColor('#999').margin({ top: 30 })
              Text('Add with empty name').fontSize(11).fontColor('#999')
            } else {
              List({ space: 6 }) {
                ForEach(this.nullNameEmployees, (emp: Employee) => {
                  ListItem() {
                    Row() {
                      Column() {
                        Text('NULL NAME').fontSize(12).fontWeight(FontWeight.Medium).fontColor('#FF6B6B')
                        Text(`ID:${emp.id} Age:${emp.age}`).fontSize(10).fontColor('#999')
                      }.alignItems(HorizontalAlign.Start)

                      Blank()
                      Text(`$${emp.salary.toFixed(0)}`).fontSize(14).fontColor('#4CAF50')
                    }.width('100%')
                    .padding({
                      top: 8,
                      bottom: 8,
                      left: 20,
                      right: 20
                    })
                    .backgroundColor('#74696969')
                    .borderRadius(8)
                  }
                }, (emp: Employee) => emp.id.toString())
              }
              .width('90%').layoutWeight(1)
            }
          }
          .width('100%')
        }
        .tabBar(this.tabBuilder('NULL', 1))

        TabContent() {
          Scroll() {
            Column({ space: 6 }) {
              TextInput({ placeholder: 'Name (empty=NULL)', text: this.newName })
                .onChange(v => this.newName = v)
                .height(30)
                .placeholderFont({ size: 12 })
                .fontSize(12)
              TextInput({ placeholder: 'Age *', text: this.newAge })
                .onChange(v => this.newAge = v)
                .type(InputType.Number)
                .height(30)
                .placeholderFont({ size: 12 })
                .fontSize(12)
              TextInput({ placeholder: 'Salary *', text: this.newSalary })
                .onChange(v => this.newSalary = v)
                .type(InputType.Number)
                .height(30)
                .placeholderFont({ size: 12 })
                .fontSize(12)
              Button('Add')
                .width('50%')
                .height(30)
                .backgroundColor('#007DFF')
                .fontSize(12)
                .onClick(() => this.addEmployee())
                .margin({ bottom: 8, top: 4 })
            }
            .width('90%').padding(8).backgroundColor('#74696969').borderRadius(12)
          }
        }
        .tabBar(this.tabBuilder('Add', 2))

        TabContent() {
          Scroll() {
            Column({ space: 6 }) {
              Text('sendablePreferences.get / put').fontSize(10).fontColor('#007DFF')

              TextInput({ placeholder: 'Key', text: this.sendableKey })
                .onChange(v => this.sendableKey = v).height(30).placeholderFont({ size: 12 })
                .fontSize(12)

              TextInput({ placeholder: 'Value', text: this.sendableValue })
                .onChange(v => this.sendableValue = v).height(30).placeholderFont({ size: 12 })
                .fontSize(12)

              Row({ space: 10 }) {
                Button('GET')
                  .flexGrow(1)
                  .height(30)
                  .backgroundColor('#007DFF')
                  .fontSize(12)
                  .onClick(() => this.getSendablePref())
                Button('SET')
                  .flexGrow(1)
                  .height(30)
                  .backgroundColor('#ffffffff')
                  .fontColor('#007DFF')
                  .fontSize(12)
                  .onClick(() => this.saveSendablePref())
              }
              .width('74%').margin({ bottom: 16, top: 4 })

              if (this.sendableResult) {
                Text(this.sendableResult).fontSize(12).fontColor('#007DFF').margin({ top: 8, bottom: 8 })
              }
            }
            .width('90%').padding(8).backgroundColor('#74696969').borderRadius(12)
          }.width('100%').height('100%')
        }
        .tabBar(this.tabBuilder('Prefs', 3))
      }
      .width('100%').layoutWeight(1).barMode(BarMode.Fixed)
      .onSelected((index: number) => {
        this.currentIndex = index;
      })
    }.width('100%')
    .height('100%')
  }
}