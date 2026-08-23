cmake_minimum_required(VERSION 3.19)
project(prism VERSION 1.0.0 LANGUAGES CXX)

# Must be set before GNUInstallDirs / qt_standard_project_setup runs
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Default install prefix" FORCE)
endif()

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    QuickEffects
    Concurrent
    Svg
    Multimedia
    DBus
    Network
)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(prism_app
    src/main.cpp
    src/config/fontbuilder.hpp
    src/config/fontbuilder.cpp
    src/config/font.hpp
    src/config/font.cpp
    src/config/tokens.hpp
    src/config/tokens.cpp
    src/config/colours.hpp
    src/config/colours.cpp
    src/models/filesystemmodel.hpp
    src/models/filesystemmodel.cpp
    src/controllers/tabmanager.hpp
    src/controllers/tabmanager.cpp
    src/core/fileutils.hpp
    src/core/fileutils.cpp
    src/core/fileoperations.hpp
    src/core/fileoperations.cpp
    src/core/catboxuploader.hpp
    src/core/catboxuploader.cpp
    src/core/placesmodel.hpp
    src/core/placesmodel.cpp
    src/core/drivemanager.hpp
    src/core/drivemanager.cpp
    src/core/filemetadata.hpp
    src/core/filemetadata.cpp
    src/core/mimeservice.hpp
    src/core/mimeservice.cpp
    src/core/gitmanager.hpp
    src/core/gitmanager.cpp
    src/core/appintegration.hpp
    src/core/appintegration.cpp
    src/core/thumbnailprovider.hpp
    src/core/thumbnailprovider.cpp
    src/core/iconprovider.hpp
    src/core/iconprovider.cpp
    src/core/iconcatalog.hpp
    src/core/iconcatalog.cpp
    src/core/papiruswatcher.hpp
    src/core/papiruswatcher.cpp
    src/core/networkmanager.hpp
    src/core/networkmanager.cpp
    src/core/circularindicatormanager.hpp
    src/core/circularindicatormanager.cpp
    src/core/runnergame.hpp
    src/core/runnergame.cpp
    src/core/appcontroller.hpp
    src/core/appcontroller.cpp
)

set_target_properties(prism_app PROPERTIES
    OUTPUT_NAME "prism"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

target_include_directories(prism_app PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/config
    ${CMAKE_CURRENT_SOURCE_DIR}/src/models
    ${CMAKE_CURRENT_SOURCE_DIR}/src/controllers
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
)

qt_add_qml_module(prism_app
    URI "prism"
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/components/Anim.qml
        qml/components/CAnim.qml
        qml/components/StyledRect.qml
        qml/components/StyledText.qml
        qml/components/MaterialIcon.qml
        qml/components/StateLayer.qml
        qml/components/Mask.qml
        qml/components/StyledScrollBar.qml
        qml/components/StyledToolTip.qml
        qml/components/CachingIconImage.qml
        qml/components/filedialog/Sizes.qml
        qml/components/filedialog/CurrentItem.qml
        qml/components/filedialog/DialogButtons.qml
        qml/components/filedialog/HeaderBar.qml
        qml/components/filedialog/Sidebar.qml
        qml/components/filedialog/FolderContents.qml
        qml/components/filedialog/FileDialog.qml
        qml/components/tabs/TabBar.qml
        qml/components/tabs/M3TopTabBar.qml
        qml/components/navigation/NavigationBar.qml
        qml/components/panels/PlacesSidebar.qml
        qml/components/panels/PreviewPanel.qml
        qml/components/views/FileGridView.qml
        qml/components/views/FileDetailsView.qml
        qml/components/views/FileCompactView.qml
        qml/components/views/SplitViewContainer.qml
        qml/components/views/EmptyStateView.qml
        qml/components/views/LoadingOverlay.qml
        qml/components/views/ColumnResizeHandle.qml
        qml/components/menus/ContextMenu.qml
        qml/components/menus/TabContextMenu.qml
        qml/components/menus/PlaceContextMenu.qml
        qml/components/menus/DropActionMenu.qml
        qml/components/dialogs/NewItemModal.qml
        qml/components/dialogs/EditPlaceModal.qml
        qml/components/dialogs/PlacesManageModal.qml
        qml/components/dialogs/ConnectServerModal.qml
        qml/components/dialogs/PreferencesModal.qml
        qml/components/dialogs/PropertiesModal.qml
        qml/components/dialogs/OpenWithModal.qml
        qml/components/dialogs/GitModal.qml
        qml/components/dialogs/CompressModal.qml
        qml/components/dialogs/OperationsModal.qml
        qml/components/dialogs/ConfirmDeleteModal.qml
        qml/components/dialogs/VectorBloomOverlay.qml
        qml/components/dialogs/RunnerGameModal.qml
        qml/components/media/ImageViewer.qml
        qml/components/media/VideoPlayer.qml
        qml/components/media/MediaFilmstrip.qml
        qml/components/media/MediaViewerModal.qml
        qml/components/containers/VerticalFadeFlickable.qml
        qml/components/containers/VerticalFadeListView.qml
        qml/components/containers/VerticalFadeGridView.qml
        qml/components/controls/StyledSlider.qml
        qml/components/controls/StyledCheckBox.qml
        qml/components/controls/CircularProgress.qml
        qml/components/controls/CircularIndicator.qml
        qml/components/statusbar/StatusBar.qml
    RESOURCES
        assets/fonts/GoogleSansFlex.ttf
        assets/fonts/MaterialSymbolsRounded.ttf
        assets/material_icons.txt
        assets/prism.png
        assets/prism.svg
        assets/runner/assets/default_200_percent/200-offline-sprite.png
)

target_link_libraries(prism_app PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickEffects
    Qt6::Concurrent
    Qt6::Svg
    Qt6::Multimedia
    Qt6::Network
)

# Native XDG Desktop Portal FileChooser daemon for Prism
qt_add_executable(xdg_desktop_portal_prism
    src/portal/main.cpp
    src/portal/filechooserportal.hpp
    src/portal/filechooserportal.cpp
)

set_target_properties(xdg_desktop_portal_prism PROPERTIES
    OUTPUT_NAME "xdg-desktop-portal-prism"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

target_include_directories(xdg_desktop_portal_prism PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/portal
)

target_link_libraries(xdg_desktop_portal_prism PRIVATE
    Qt6::Core
    Qt6::DBus
)

install(TARGETS prism_app xdg_desktop_portal_prism
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES assets/prism.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

install(FILES assets/prism.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
    RENAME prism.svg
)

install(FILES assets/prism.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/pixmaps
    RENAME prism.svg
)

# Native XDG Desktop Portal definition & D-Bus service
install(FILES assets/portal/prism.portal
    DESTINATION ${CMAKE_INSTALL_DATADIR}/xdg-desktop-portal/portals
)

install(FILES assets/portal/org.freedesktop.impl.portal.desktop.prism.service
    DESTINATION ${CMAKE_INSTALL_DATADIR}/dbus-1/services
)

# OpenRC / non-systemd user portal lifecycle helper
install(PROGRAMS assets/portal/openrc-user-portal.sh
    DESTINATION ${CMAKE_INSTALL_BINDIR}
    RENAME prism-portal-openrc
)

# Portal configuration templates
install(FILES
    assets/portal/portals.conf
    DESTINATION ${CMAKE_INSTALL_DATADIR}/prism/portal
)

# Detect init system to decide service files to install
set(INIT_SYSTEM "auto" CACHE STRING "Init system to install service files for (auto, openrc, systemd, none)")

if(INIT_SYSTEM STREQUAL "auto")
    if(EXISTS "/etc/init.d" OR EXISTS "/sbin/openrc" OR EXISTS "/usr/bin/openrc" OR EXISTS "/run/openrc")
        set(DETECTED_INIT "openrc")
    elseif(EXISTS "/usr/lib/systemd" OR EXISTS "/etc/systemd")
        set(DETECTED_INIT "systemd")
    else()
        set(DETECTED_INIT "none")
    endif()
else()
    set(DETECTED_INIT "${INIT_SYSTEM}")
endif()

message(STATUS "Configuring service files for init system: ${DETECTED_INIT}")

if(DETECTED_INIT STREQUAL "openrc")
    install(PROGRAMS assets/init/xdg-desktop-portal-prism.initd
        DESTINATION /etc/init.d
        RENAME xdg-desktop-portal-prism
    )
elseif(DETECTED_INIT STREQUAL "systemd")
    install(FILES assets/init/xdg-desktop-portal-prism.service
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/systemd/user
    )
endif()
