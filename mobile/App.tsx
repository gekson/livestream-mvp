// App.js
import React from 'react';
import { StatusBar, LogBox } from 'react-native';
import { Provider as PaperProvider, DefaultTheme } from 'react-native-paper';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ChatProvider } from './src/contexts/ChatContext';
import Navigation from './src/navigation';

// Ignorar avisos específicos
LogBox.ignoreLogs([
  'Warning: Async Storage has been extracted from react-native',
  'Setting a timer for a long period of time',
]);

const theme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: '#2196F3',
    accent: '#03A9F4',
  },
};

const App = () => {
  return (
    <SafeAreaProvider>
      <PaperProvider theme={theme}>
        <ChatProvider>
          <StatusBar barStyle="dark-content" />
          <Navigation />
        </ChatProvider>
      </PaperProvider>
    </SafeAreaProvider>
  );
};

export default App;