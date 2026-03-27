import 'react-native-gesture-handler/jestSetup';

jest.doMock('react-native/Libraries/NativeComponent/ViewConfigIgnore', () => ({
  ConditionallyIgnoredEventHandlers: () => undefined,
  DynamicallyInjectedByGestureHandler: () => ({}),
  isIgnored: () => true,
}));
