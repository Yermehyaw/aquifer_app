# aquifer_app

A Flutter application for hydration tracking and reminders.

## Team Members
Akor Jeremiah [https://github.com/yermehyaw]
Oluwatosin Ikhide
Victor Osimwanyi
Owobu isaac


## Getting Started

To use/develop the app, create a flutter project
```flutter create aquifer_app```

In another folder, clone this repo via:
```git clone https://github.com/Yermehyaw/aquifer_app```

Move the following from the cloned repo into your  aquifer_app dir:
- the lib dir 
- th assests dir
- the AndriodManifest.xml located at aquifer_app/android/app/src/AndriodManifest.xml
- the pubspec.yaml

Run
```flutter pub get``` 
to update dependencies and prepare yr IDE for development

Run/debug the app viz:
```flutter run --debug```

And continue development!


## POSSIBLE BUGS
- If device is restarted, the app might not remmeber to update its current time and user hydration level and therefore continue from a hallucinated hydration level of the user which might be the hydratio satte prior to the device resatart oe from a 100% hydrated level

- The app dosen;t continously check if notifications are enabled. If the user disables notification, this feature is disabled and a prompt requesting notifications isnt displayed
