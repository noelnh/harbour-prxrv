# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-prxrv

CONFIG += sailfishapp

SOURCES += src/harbour-prxrv.cpp

OTHER_FILES += qml/harbour-prxrv.qml \
    qml/cover/CoverPage.qml \
    qml/pages/*.qml \
    qml/js/*.js \
    qml/fonts/fontawesome-webfont.ttf \
    qml/images/* \
    rpm/harbour-prxrv.yaml \
    translations/*.ts \
    harbour-prxrv.desktop \
    harbour-prxrv.png

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-prxrv-zh.ts

