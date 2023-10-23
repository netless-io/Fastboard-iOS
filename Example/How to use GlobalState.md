1. 声明你的数据类型，注意需要继承自 `WhiteGlobalState` 并且要标注 `@objc`

   ![1698051246659](image/HowtouseGlobalState/1698051246659.png)
2. 设置类型。需要在加入房间之前调用。

   ```
   WhiteDisplayerState.setCustomGlobalStateClass(HTState.self)
   ```
3. 设置监听。

   ```
   fastRoom.roomDelegate = self
   ```

![1698051541516](image/HowtouseGlobalState/1698051541516.png)

4. 主动设置。
   ![1698051596307](image/HowtouseGlobalState/1698051596307.png)
5. 主动查看。

   ![1698051634072](image/HowtouseGlobalState/1698051634072.png)
