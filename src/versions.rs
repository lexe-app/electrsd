#[cfg(target_os = "macos")]
const OS: &str = "macos";

#[cfg(target_os = "linux")]
const OS: &str = "linux";

#[cfg(not(any(target_os = "linux", target_os = "macos")))]
const OS: &str = "undefined";

const VERSION: &str = "ef15bf97b97814bc8ac771e8537dcf1c1779dade";

pub fn electrs_name() -> String {
    format!("electrs_{}_{}", OS, VERSION)
}
