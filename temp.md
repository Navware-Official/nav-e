# Motorcycle Navigation System

## Vision

This project is a motorcycle-focused navigation system designed to work offline, scale from smartwatches to custom hardware, and provide a clean, efficient, and rider-optimized experience.  

Key goals:

- Fully offline operation  
- Motorcycle-specific routing  
- Scalable from smartwatch to custom dashboard  
- Efficient, structured communication between devices  
- Vector-based maps for compact storage and flexibility  

---

## System Roles

### Phone (Navigation Core)

The phone acts as the **brain** of the navigation system.  
Responsibilities:

- Route calculation and rerouting  
- Offline map management and region downloads  
- Preparing map and route data for connected devices  
- Sending structured navigation updates to display clients  

The phone handles all heavy processing; connected devices only render.

### Watch / Device (Rendering Client)

The smartwatch or future custom hardware acts as a **lightweight display client**.  
Responsibilities:

- Rendering map data and active route  
- Displaying navigation instructions and ride metrics  
- Requesting additional map data as needed  

The rendering client does **not calculate routes**, keeping the system modular and scalable.

---

## Offline Vector Maps

Maps are vector-based and downloaded to the phone, not the device.  

Advantages:

- Compact storage  
- Scalable across zoom levels and screen resolutions  
- Efficient transmission of only necessary map data  
- Future-proof for custom hardware devices  

The device receives only the visible portion of the map (via tiles), minimizing data transfer.

---

## Communication Philosophy

We do **not** stream rendered frames.  
Structured communication includes:

- Route geometry  
- Road segments  
- Navigation state  
- Tile-based map chunks  

Benefits:

- Efficient and low-bandwidth  
- Battery-friendly  
- Hardware-agnostic  
- Scalable  

---

## Map Data Strategy

Maps are organized in **regions**:

1. User selects a region to download  
2. Phone stores and indexes the region  
3. Device requests map tiles as needed  
4. Device caches tiles locally for rendering  

Tile-based delivery ensures predictable memory usage, efficient updates, and smooth rendering on the device.

---

## Rendering Model

The device renders:

- Base road geometry  
- Active route  
- User position  
- Turn indicators  

This keeps rendering independent of routing calculations and supports hardware flexibility (Pixel Watch → custom dashboard).

---

## Development Phases

1. **Route Display on Device**  
   - Send route from phone  
   - Render minimal navigation UI  
   - Validate communication stability  

2. **Tile-Based Map Rendering**  
   - Introduce map tiles  
   - Enable device-side caching  
   - Render nearby roads  

3. **Offline Region Management**  
   - Region download system  
   - Region selection UI  
   - Storage management  

4. **Optimization & Refinement**  
   - Smarter tile preloading  
   - Geometry refinement per zoom level  
   - UI improvements for safe riding  

---

## Long-Term Direction

- Full offline navigation  
- Scalable across devices and custom hardware  
- Motorcycle-optimized routing and analytics  
- Self-hosted or European-first infrastructure  

The system separates:

- Navigation logic  
- Map storage  
- Rendering  
- Communication  

This ensures flexibility, maintainability, and scalability.

---

## Guiding Principles

- **Phone computes, device renders**  
- **Vector-based maps** for efficiency and scalability  
- **Structured data transfer**, not pixel streaming  
- **Offline-first mindset**  
- **Modular, hardware-agnostic design**  

---

