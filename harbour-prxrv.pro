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

CONFIG += c++11

HEADERS += \
    src/pxvrequest.h \
    src/requestmgr.h \
    src/cachemgr.h \
    src/utils.h \
    src/pxvimageprovider.h \
    src/pxvnamfactory.h \
    src/pxvnetworkaccessmanager.h

SOURCES += src/harbour-prxrv.cpp \
    src/pxvrequest.cpp \
    src/requestmgr.cpp \
    src/cachemgr.cpp \
    src/utils.cpp \
    src/pxvimageprovider.cpp \
    src/pxvnamfactory.cpp \
    src/pxvnetworkaccessmanager.cpp

OTHER_FILES += qml/harbour-prxrv.qml \
    qml/cover/CoverPage.qml \
    qml/pages/*.qml \
    qml/js/*.js \
    qml/images/* \
    qml/fonts/fontawesome-webfont.ttf \
    rpm/harbour-prxrv.yaml \
    rpm/harbour-prxrv.changes \
    translations/*.ts \
    harbour-prxrv.desktop \
    harbour-prxrv.png

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-prxrv-zh_CN.ts
