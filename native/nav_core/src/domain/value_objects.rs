#![allow(dead_code)]
// Value Objects - Immutable objects defined by their attributes
use serde::{Deserialize, Serialize};

/// Geographic position (latitude, longitude)
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Position {
    pub latitude: f64,
    pub longitude: f64,
}

impl Position {
    pub fn new(latitude: f64, longitude: f64) -> anyhow::Result<Self> {
        if !(-90.0..=90.0).contains(&latitude) {
            anyhow::bail!("Latitude must be between -90 and 90");
        }
        if !(-180.0..=180.0).contains(&longitude) {
            anyhow::bail!("Longitude must be between -180 and 180");
        }
        Ok(Self {
            latitude,
            longitude,
        })
    }

    pub fn distance_to(&self, other: &Position) -> f64 {
        // Haversine formula
        let r = 6371000.0; // Earth radius in meters
        let lat1 = self.latitude.to_radians();
        let lat2 = other.latitude.to_radians();
        let delta_lat = (other.latitude - self.latitude).to_radians();
        let delta_lon = (other.longitude - self.longitude).to_radians();

        let a = (delta_lat / 2.0).sin().powi(2)
            + lat1.cos() * lat2.cos() * (delta_lon / 2.0).sin().powi(2);
        let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());

        r * c
    }
}

/// Device capabilities (value object)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceCapabilities {
    pub screen_width: u32,
    pub screen_height: u32,
    pub supports_color: bool,
    pub supports_haptic: bool,
    pub supports_voice: bool,
    pub battery_capacity_mah: u32,
}

impl DeviceCapabilities {
    pub fn new(screen_width: u32, screen_height: u32) -> Self {
        Self {
            screen_width,
            screen_height,
            supports_color: true,
            supports_haptic: false,
            supports_voice: false,
            battery_capacity_mah: 0,
        }
    }

    pub fn with_features(mut self, color: bool, haptic: bool, voice: bool) -> Self {
        self.supports_color = color;
        self.supports_haptic = haptic;
        self.supports_voice = voice;
        self
    }
}

/// Battery information (value object)
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct BatteryInfo {
    pub percentage: u8,
    pub is_charging: bool,
    pub time_remaining_minutes: Option<u32>,
}

impl BatteryInfo {
    pub fn new(percentage: u8, is_charging: bool) -> Self {
        Self {
            percentage: percentage.min(100),
            is_charging,
            time_remaining_minutes: None,
        }
    }

    pub fn with_time_remaining(mut self, minutes: u32) -> Self {
        self.time_remaining_minutes = Some(minutes);
        self
    }

    pub fn is_low(&self) -> bool {
        self.percentage < 20 && !self.is_charging
    }

    pub fn is_critical(&self) -> bool {
        self.percentage < 10 && !self.is_charging
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Position ─────────────────────────────────────────────────────────────

    #[test]
    fn position_new_valid() {
        assert!(Position::new(0.0, 0.0).is_ok());
        assert!(Position::new(90.0, 180.0).is_ok());
        assert!(Position::new(-90.0, -180.0).is_ok());
        assert!(Position::new(51.5, -0.12).is_ok());
    }

    #[test]
    fn position_new_rejects_invalid_latitude() {
        assert!(Position::new(90.1, 0.0).is_err());
        assert!(Position::new(-90.1, 0.0).is_err());
        assert!(Position::new(180.0, 0.0).is_err());
    }

    #[test]
    fn position_new_rejects_invalid_longitude() {
        assert!(Position::new(0.0, 180.1).is_err());
        assert!(Position::new(0.0, -180.1).is_err());
    }

    #[test]
    fn position_distance_same_point_is_zero() {
        let p = Position::new(51.5, -0.12).unwrap();
        assert!(p.distance_to(&p) < 1.0); // < 1 metre
    }

    #[test]
    fn position_distance_known_value() {
        // London → Paris ≈ 340 km
        let london = Position::new(51.5074, -0.1278).unwrap();
        let paris = Position::new(48.8566, 2.3522).unwrap();
        let dist = london.distance_to(&paris);
        assert!(dist > 330_000.0 && dist < 350_000.0, "got {dist}");
    }

    #[test]
    fn position_distance_is_symmetric() {
        let a = Position::new(40.7128, -74.006).unwrap();
        let b = Position::new(34.0522, -118.2437).unwrap();
        let diff = (a.distance_to(&b) - b.distance_to(&a)).abs();
        assert!(diff < 1e-6);
    }

    // ── BatteryInfo ──────────────────────────────────────────────────────────

    #[test]
    fn battery_percentage_clamped_at_100() {
        let b = BatteryInfo::new(255, false);
        assert_eq!(b.percentage, 100);
    }

    #[test]
    fn battery_is_low_threshold() {
        assert!(BatteryInfo::new(19, false).is_low());
        assert!(!BatteryInfo::new(20, false).is_low()); // boundary: not low at exactly 20
        assert!(!BatteryInfo::new(10, true).is_low()); // charging overrides
    }

    #[test]
    fn battery_is_critical_threshold() {
        assert!(BatteryInfo::new(9, false).is_critical());
        assert!(!BatteryInfo::new(10, false).is_critical()); // boundary: not critical at exactly 10
        assert!(!BatteryInfo::new(5, true).is_critical()); // charging overrides
    }

    #[test]
    fn battery_with_time_remaining() {
        let b = BatteryInfo::new(50, false).with_time_remaining(120);
        assert_eq!(b.time_remaining_minutes, Some(120));
    }

    // ── DeviceCapabilities ───────────────────────────────────────────────────

    #[test]
    fn device_capabilities_defaults() {
        let caps = DeviceCapabilities::new(240, 240);
        assert!(caps.supports_color);
        assert!(!caps.supports_haptic);
        assert!(!caps.supports_voice);
    }

    #[test]
    fn device_capabilities_with_features() {
        let caps = DeviceCapabilities::new(240, 240).with_features(false, true, true);
        assert!(!caps.supports_color);
        assert!(caps.supports_haptic);
        assert!(caps.supports_voice);
    }
}
