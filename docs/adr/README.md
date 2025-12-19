# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) for the nav-e navigation engine project.

## What is an ADR?

An Architecture Decision Record (ADR) documents an important architectural decision made along with its context and consequences. ADRs help us:

- **Capture the "why"** behind architectural choices
- **Preserve context** for future maintainers
- **Document alternatives** considered and why they were rejected
- **Track evolution** of the system architecture
- **Facilitate onboarding** of new team members

## When to Create an ADR

Create an ADR when making decisions about:

- Architectural patterns (e.g., DDD, Hexagonal Architecture, CQRS)
- Technology choices (e.g., programming languages, frameworks, libraries)
- Integration approaches (e.g., FFI bridges, communication protocols)
- Data persistence strategies (e.g., databases, storage formats)
- External service dependencies (e.g., routing engines, geocoding services)
- Security and privacy measures
- Performance optimization strategies
- Testing strategies

Don't create ADRs for:

- Minor implementation details
- Temporary workarounds
- Routine bug fixes
- Cosmetic changes

## ADR Index

| Number | Title | Status | Date |
|--------|-------|--------|------|
| [0000](0000-template.md) | ADR Template | N/A | 2025-12-16 |
| [0001](0001-adopt-ddd-hexagonal-cqrs.md) | Adopt Domain-Driven Design with Hexagonal Architecture and CQRS | Accepted | 2025-12-16 |
| [0002](0002-rust-core-flutter-ui.md) | Use Rust for Core Navigation Engine with Flutter for UI | Accepted | 2025-12-16 |
| [0003](0003-osrm-routing-engine.md) | Choose OSRM as the Routing Engine | Accepted | 2025-12-16 |
| [0004](0004-nominatim-geocoding.md) | Use Nominatim/OpenStreetMap for Geocoding | Accepted | 2025-12-16 |
| [0005](0005-protocol-buffers-device-communication.md) | Implement Protocol Buffers for Device Communication | Accepted | 2025-12-16 |

## ADR Format

We use a consistent format for all ADRs based on the template in [0000-template.md](0000-template.md). Each ADR includes:

1. **Status** - Current state (Proposed, Accepted, Deprecated, Superseded)
2. **Context** - The problem and constraints
3. **Decision** - What we decided to do
4. **Consequences** - Positive, negative, and neutral outcomes
5. **Alternatives Considered** - What else we evaluated
6. **Implementation** - Where and how it was implemented
7. **References** - Related documentation and resources

## ADR Lifecycle

### Proposed
The decision is under discussion and not yet finalized.

### Accepted
The decision has been approved and is being or has been implemented.

### Deprecated
The decision is no longer current but remains for historical reference.

### Superseded
A new ADR has replaced this decision. The superseding ADR number should be noted.

## Contributing

When creating a new ADR:

1. Copy the [template](0000-template.md) to a new file numbered sequentially (e.g., `0006-my-decision.md`)
2. Fill in all sections with specific, concrete information
3. Update this README with an entry in the ADR Index table
4. Submit a pull request with the new ADR
5. Discuss and refine the ADR through review
6. Update status from "Proposed" to "Accepted" once approved

## References

- [Michael Nygard's ADR Documentation](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [ADR GitHub Organization](https://adr.github.io/)
- [Architecture Decision Records: A Primer](https://github.com/joelparkerhenderson/architecture-decision-record)
