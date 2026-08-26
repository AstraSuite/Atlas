cmake_minimum_required(VERSION 3.19)
project(atlas VERSION 1.0.0 LANGUAGES CXX)

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
    Network
)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(atlas_app
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
    src/core/trashlocations.hpp
    src/core/trashlocations.cpp
    src/core/recentfiles.hpp
    src/core/recentfiles.cpp
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
    src/core/exifreader.hpp
    src/core/exifreader.cpp
    src/core/mimeservice.hpp
    src/core/mimeservice.cpp
    src/core/gitmanager.hpp
    src/core/gitmanager.cpp
    src/core/mediatools.hpp
    src/core/mediatools.cpp
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

set_target_properties(atlas_app PROPERTIES
    OUTPUT_NAME "atlas"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

target_include_directories(atlas_app PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/config
    ${CMAKE_CURRENT_SOURCE_DIR}/src/models
    ${CMAKE_CURRENT_SOURCE_DIR}/src/controllers
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
)

qt_add_qml_module(atlas_app
    URI "atlas"
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
        qml/components/effects/Elevation.qml
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
        qml/components/dialogs/MediaToolsModal.qml
        qml/components/dialogs/OperationsModal.qml
        qml/components/dialogs/BulkRenameModal.qml
        qml/components/dialogs/ConfirmDeleteModal.qml
        qml/components/dialogs/RunFileModal.qml
        qml/components/dialogs/VectorBloomOverlay.qml
        qml/components/dialogs/RunnerGameModal.qml
        qml/components/media/ImageViewer.qml
        qml/components/media/VideoPlayer.qml
        qml/components/media/MediaFilmstrip.qml
        qml/components/media/MediaViewerModal.qml
        qml/components/containers/VerticalFadeFlickable.qml
        qml/components/containers/VerticalFadeListView.qml
        qml/components/containers/VerticalFadeGridView.qml
        qml/components/containers/ConnectedRect.qml
        qml/components/controls/ButtonBase.qml
        qml/components/controls/TextButton.qml
        qml/components/controls/IconButton.qml
        qml/components/controls/IconTextButton.qml
        qml/components/controls/ButtonRow.qml
        qml/components/controls/ButtonRowItem.qml
        qml/components/controls/ButtonGroup.qml
        qml/components/controls/SlidingSelector.qml
        qml/components/controls/ButtonGroupItem.qml
        qml/components/controls/StyledSwitch.qml
        qml/components/controls/RowButton.qml
        qml/components/controls/ToggleRow.qml
        qml/components/controls/SplitButton.qml
        qml/components/controls/SplitButtonRow.qml
        qml/components/controls/Menu.qml
        qml/components/controls/MenuItem.qml
        qml/components/controls/StyledSlider.qml
        qml/components/controls/StyledCheckBox.qml
        qml/components/controls/CircularProgress.qml
        qml/components/controls/CircularIndicator.qml
        qml/components/statusbar/StatusBar.qml
    RESOURCES
        assets/fonts/GoogleSansFlex.ttf
        assets/fonts/MaterialSymbolsRounded.ttf
        assets/material_icons.txt
        assets/atlas.png
        assets/atlas.svg
        assets/runner/assets/default_200_percent/200-offline-sprite.png
        assets/runner/assets/default_200_percent/200-offline-sprite-inverted.png
        assets/runner/sounds/press.wav
        assets/runner/sounds/hit.wav
        assets/runner/sounds/reached.wav
)

target_link_libraries(atlas_app PRIVATE
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

# Optional EXIF metadata support via Exiv2; degrades gracefully when absent
find_package(exiv2 QUIET)
if(exiv2_FOUND)
    message(STATUS "Exiv2 found - EXIF metadata support enabled")
    target_link_libraries(atlas_app PRIVATE exiv2lib)
    target_compile_definitions(atlas_app PRIVATE ATLAS_HAVE_EXIV2 PRISM_HAVE_EXIV2)
else()
    message(STATUS "Exiv2 not found - building without EXIF metadata support")
endif()

install(TARGETS atlas_app
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES assets/atlas.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

install(FILES assets/atlas.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
    RENAME atlas.svg
)

install(FILES assets/atlas.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/pixmaps
    RENAME atlas.svg
)
