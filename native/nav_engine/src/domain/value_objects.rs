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
        Ok(Self { latitude, longitude })
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

/// A waypoint in a route
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Waypoint {
    pub position: Position,
    pub name: Option<String>,
    pub arrival_time: Option<u32>, // Estimated seconds from start
    pub is_visited: bool,
}

impl Waypoint {
    pub fn new(position: Position, name: Option<String>) -> Self {
        Self {
            position,
            name,
            arrival_time: None,
            is_visited: false,
        }
    }

    pub fn with_arrival_time(mut self, seconds: u32) -> Self {
        self.arrival_time = Some(seconds);
        self
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

/// Navigation instruction
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Instruction {
    pub text: String,
    pub distance_meters: u32,
    pub duration_seconds: u32,
    pub instruction_type: InstructionType,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum InstructionType {
    TurnLeft,
    TurnRight,
    Continue,
    Arrive,
    Depart,
    Merge,
    Roundabout,
}
