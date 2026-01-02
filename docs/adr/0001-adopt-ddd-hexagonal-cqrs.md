# ADR-0001: Adopt Domain-Driven Design with Hexagonal Architecture and CQRS

## Status

**Accepted**

Date: 2025-12-16

## Context

Building a navigation engine requires managing complex business logic including route calculation, turn-by-turn navigation, device communication, traffic alerts, and position tracking. Traditional layered architectures often lead to:

- Business logic leaking into UI or infrastructure code
- Tight coupling between components making testing difficult
- Unclear boundaries between concerns
- Difficulty adapting to changing requirements
- Hard-to-maintain codebases as complexity grows

The nav-e project needed an architectural approach that would:

- Keep business logic pure and testable
- Support multiple external services (routing, geocoding, traffic)
- Enable multiple presentation layers (Flutter mobile, Wear OS, web)
- Allow swapping implementations without affecting core logic
- Scale as features and complexity increase
- Maintain code clarity as the team grows

## Decision

We adopt a combination of three complementary architectural patterns:

### 1. Domain-Driven Design (DDD)

Structure the core business logic around the navigation domain with:

- **Entities**: Objects with identity (NavigationSession, Route, Device, TrafficEvent)
- **Value Objects**: Immutable objects defined by attributes (Position, Waypoint, Instruction)
- **Domain Events**: Capture state changes (NavigationStartedEvent, PositionUpdatedEvent)
- **Ubiquitous Language**: Shared vocabulary between developers and domain experts

### 2. Hexagonal Architecture (Ports & Adapters)

Isolate core business logic from external concerns:

- **Domain Layer**: Pure business logic with zero external dependencies
- **Application Layer**: Orchestrates business operations
- **Infrastructure Layer**: Adapters implementing domain ports
- **Ports**: Interfaces defining contracts (RouteService, GeocodingService, DeviceCommunicationPort)
- **Adapters**: Concrete implementations (OsrmRouteService, ProtobufDeviceCommunicator)

### 3. CQRS (Command Query Responsibility Segregation)

Separate read and write operations:

- **Commands**: Write operations that change state (StartNavigationCommand, UpdatePositionCommand)
- **Queries**: Read operations that don't modify state (GetActiveSessionQuery, GetTrafficAlertsQuery)
- **Handlers**: Execute commands and queries with clear single responsibilities

## Consequences

### Positive

- **Testability**: Domain logic can be tested in isolation without external dependencies, infrastructure adapters can be mocked
- **Flexibility**: Easy to swap implementations (OSRM → Google Maps, Protobuf → JSON, in-memory → SQLite)
- **Maintainability**: Clear separation of concerns, each layer has a single well-defined responsibility
- **Scalability**: CQRS enables independent optimization of read and write paths
- **Domain Focus**: Business rules are explicit and centralized in the domain layer
- **Team Collaboration**: Ubiquitous language improves communication between technical and non-technical stakeholders
- **Onboarding**: New developers can understand the system by exploring domain entities and value objects
- **Future-Proofing**: Easy to add new features without breaking existing code

### Negative

- **Initial Complexity**: More files and abstractions compared to simple layered architecture
- **Learning Curve**: Team members need to understand DDD, Hexagonal Architecture, and CQRS concepts
- **Boilerplate Code**: Requires more interfaces, ports, and adapter classes
- **Over-Engineering Risk**: May be overkill for simple CRUD operations
- **Coordination Overhead**: Changes may require updates across multiple layers

### Neutral

- **File Count**: More granular file structure with separate files for entities, value objects, ports, commands, queries, handlers, and adapters
- **Async Throughout**: All operations are async, which adds complexity but matches modern patterns
- **Event Sourcing**: Domain events enable future implementation of event sourcing if needed

## Alternatives Considered

### Alternative 1: Traditional Layered Architecture (MVC/MVVM)

**Description:** Three-layer architecture with Presentation → Business Logic → Data Access

**Pros:**
- Simple and well-understood
- Less boilerplate code
- Faster initial development
- Fewer abstractions to learn

**Cons:**
- Business logic often leaks into controllers or viewmodels
- Tight coupling between layers
- Difficult to test in isolation
- Hard to swap external dependencies
- Unclear boundaries as complexity grows

**Why rejected:** Would become unmaintainable as navigation logic complexity increases, making testing and adapting to new requirements difficult

### Alternative 2: Clean Architecture

**Description:** Similar to Hexagonal Architecture but with more rigid layer dependencies (Entities → Use Cases → Interface Adapters → Frameworks)

**Pros:**
- Well-documented with many examples
- Clear dependency rules
- Good separation of concerns
- Testable

**Cons:**
- More prescriptive than Hexagonal Architecture
- Doesn't emphasize domain modeling as much as DDD
- Use case layer may be redundant with CQRS handlers
- Less flexible for our specific needs

**Why rejected:** Hexagonal Architecture provides similar benefits with more flexibility, and we wanted strong domain modeling from DDD

### Alternative 3: Microservices Architecture

**Description:** Split navigation engine into separate services (routing service, device communication service, traffic service)

**Pros:**
- Independent scaling
- Technology diversity
- Service isolation
- Team autonomy

**Cons:**
- Operational complexity (deployment, monitoring, networking)
- Latency from network calls
- Distributed system challenges
- Overkill for a mobile app navigation engine
- Increased infrastructure costs

**Why rejected:** Too much operational overhead for our use case; we can achieve modularity through Hexagonal Architecture without distributed system complexity

## Implementation

- **Implemented in:** feature/navigation-routing branch
- **Affected components:** 
  - `native/nav_engine/src/domain/` - Entities, value objects, ports, events
  - `native/nav_engine/src/application/` - Commands, queries, handlers
  - `native/nav_engine/src/infrastructure/` - Adapters (OSRM, Nominatim, Protobuf, repositories)
- **Migration path:** Initial implementation; all new Rust navigation logic follows this architecture

## References

- [Hexagonal Architecture (Alistair Cockburn)](https://alistair.cockburn.us/hexagonal-architecture/)
- [Domain-Driven Design (Martin Fowler)](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [CQRS Pattern (Martin Fowler)](https://martinfowler.com/bliki/CQRS.html)
- [Domain-Driven Design by Eric Evans](https://www.domainlanguage.com/ddd/)
- [Implementing Domain-Driven Design by Vaughn Vernon](https://www.amazon.com/Implementing-Domain-Driven-Design-Vaughn-Vernon/dp/0321834577)
- [docs/architecture/overview.md](../architecture/overview.md) - Detailed implementation guide

---

## Notes

This foundational architectural decision shapes all subsequent technical decisions in the nav-e project. As the project evolves, we should periodically review whether these patterns continue to serve our needs and adjust if necessary.
