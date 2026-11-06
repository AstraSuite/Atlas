//! Process-wide QML singletons, recorded as the engine creates them so
//! services can reach each other the way the C++ `instance()` calls did.

use std::cell::Cell;
use std::pin::Pin;

pub struct Slot<T>(Cell<*mut T>);

// Slots are only ever touched from the Qt (GUI) thread.
unsafe impl<T> Sync for Slot<T> {}

impl<T> Slot<T> {
    pub const fn new() -> Self {
        Slot(Cell::new(std::ptr::null_mut()))
    }

    pub fn set(&self, object: Pin<&mut T>) {
        self.0.set(unsafe { object.get_unchecked_mut() as *mut T });
    }

    /// The live instance, if the engine has created it yet.
    #[allow(clippy::mut_from_ref)]
    pub fn get(&self) -> Option<Pin<&mut T>> {
        let ptr = self.0.get();
        if ptr.is_null() {
            None
        } else {
            Some(unsafe { Pin::new_unchecked(&mut *ptr) })
        }
    }
}

use super::*;

pub static APP_CONTROLLER: Slot<appcontroller::qobject::AppController> = Slot::new();
pub static TAB_MANAGER: Slot<tabmanager::qobject::TabManager> = Slot::new();
pub static FILE_OPERATIONS: Slot<fileoperations::qobject::FileOperations> = Slot::new();
pub static CATBOX_UPLOADER: Slot<catboxuploader::qobject::CatboxUploader> = Slot::new();
// PORT: pub static PLACES_MODEL: Slot<placesmodel::qobject::PlacesModel> = Slot::new();
// PORT: pub static PAPIRUS_WATCHER: Slot<papiruswatcher::qobject::PapirusWatcher> = Slot::new();
