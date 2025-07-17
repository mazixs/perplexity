This directory contains all needed icons for the menubar and tray. They get bundled in during the build process.

There will be a colourful trayIcon.png there for Windows.

There will be a menubarIconTemplate.png there for Mac only if the customer uploaded a file with the "Template" suffix. If not, there will be a menubarIcon.png. The app will first look for the template icon; if not, it'll use the regular icon.

An image with the "Template" suffix is preferred because it will be interpeted by Electron as a [Template image](https://electronjs.org/docs/api/native-image#template-image). Its colour will be inverted depending on the menbuar background colour, etc.

There are multiple sizes for each image; Electron will automatically use the other sizes when needed.
