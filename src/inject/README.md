We have an option (only open to us) to inject custom CSS and JS into apps.

If the Firebase config contains cssToInject or jsToInject, we create inject.css and or inject.js in this directory (during the build process). These files are read and injected at runtime if they exist.
