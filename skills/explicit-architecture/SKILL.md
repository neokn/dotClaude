---
name: explicit-architecture
description: Design software architecture using DDD, Hexagonal, Clean Architecture, and CQRS patterns. Use when making architectural decisions, determining where code belongs, designing ports/adapters, dividing bounded contexts, or refactoring code structure. Includes Chain of Thought reasoning framework.
allowed-tools: Read, Write, Edit, Grep, Glob, Task
---

# Explicit Architecture Skill

Apply DDD, Hexagonal (Ports & Adapters), Onion, and Clean Architecture patterns with structured Chain of Thought reasoning.

## Core Principle

> "The architecture will always be there. The only question is: are we in control of it or not?!"

---

## System Blocks

```
[User Interface] → [Application Core] → [Infrastructure]
                         ↑
                   THE CODE THAT MATTERS
```

| Block | Responsibility | Examples |
|-------|----------------|----------|
| **User Interface** | Present/receive data | Web, Mobile, CLI, API |
| **Application Core** | Business logic | Use cases, Domain rules |
| **Infrastructure** | External connections | DB, Search, 3rd party APIs |

---

## The Four Code Types

```
Application Code     → UI, Infrastructure, Application, Domain layers
        ↓
Shared Kernel        → Cross-BC events, shared IDs, Value Objects
        ↓
Language Extensions  → Generic utilities (UUID, DateTime)
        ↓
Programming Language → Foundation
```

---

## Layer Responsibilities

| Layer | Contains | Can Depend On |
|-------|----------|---------------|
| **Domain** | Entities, Value Objects, Domain Services, Domain Events | Nothing (pure) |
| **Application** | Use Cases, Command/Query Handlers, Ports, App Events | Domain |
| **Infrastructure** | Adapters, ORM, External clients | Application interfaces, Domain |
| **UI** | Controllers, Views, API endpoints | Application interfaces |

### Dependency Rule
All dependencies must point **inward** (toward Domain layer).

---

## Ports & Adapters

### Ports (Interfaces)
- Belong in **Application Layer**
- Design based on **business needs**, NOT tool APIs

```
✓ OrderRepository.findByCustomer(customerId)
✗ MySQLConnection.query("SELECT * FROM...")
```

### Adapters (Implementations)
| Type | Direction | Example |
|------|-----------|---------|
| **Primary/Driving** | Uses the Port | Controller → Port |
| **Secondary/Driven** | Implements the Port | Port ← MySQLAdapter |

---

## CoT Reasoning Framework

### Step 1: Identify Problem Type

```
What type of problem am I dealing with?

□ Where should this code live?        → Code Placement
□ How should modules communicate?     → Communication Pattern
□ How to abstract external dependency?→ Port/Adapter Design
□ How to divide system boundaries?    → Component Division
□ Should this be in Shared Kernel?    → Shared Kernel Evaluation
□ Is this a language extension?       → Language Extension Evaluation
```

### Step 2: Determine Layer

```
Question 1: Does this involve "business rules"?
  → Yes: Domain Layer

Question 2: Does this "orchestrate a process"?
  → Yes: Application Layer

Question 3: Does this "interact with external systems"?
  → Yes: Infrastructure Layer

Question 4: Does this "receive/present data to users"?
  → Yes: UI Layer

Question 5: Is this "shared between bounded contexts"?
  → Yes: Shared Kernel

Question 6: Does this "compensate for language limitations"?
  → Yes: Language Extensions
```

### Step 3: Validate Dependency Direction

```
Valid ✓                          Invalid ✗ (need inversion)
─────────────────────────────    ─────────────────────────
UI → Application                 Domain → Application
Application → Domain             Domain → Infrastructure
Infrastructure → Port (interface) Application → Adapter (impl)
Any → Language Extensions        Shared Kernel → Component
```

### Step 4: Select Pattern

**Code Placement:**
```
Single entity behavior      → Entity/Value Object
Cross-entity domain logic   → Domain Service
Process orchestration       → Application Service/Handler
External system interaction → Adapter (with Port)
HTTP handling               → Controller
```

**Shared Kernel Evaluation:**
```
Include ✓                    Exclude ✗
─────────────────────────    ─────────────────────────
Application Events           Full Entities
Domain Events (cross-BC)     Complex Aggregates
Entity IDs (UserId, etc)     Repository interfaces
Simple Value Objects         Infrastructure code
Shared Enums                 Domain/App Services
```

### Step 5: Validate Decision

```
□ All dependencies point inward?
□ Domain Layer kept pure (no external deps)?
□ Ports designed for business needs?
□ Shared Kernel minimal and stable?
□ No code in Utils/Commons that should move?
□ Is this over-engineered for the project?
□ Easy to test?
□ Team can understand and maintain?
```

---

## Quick Decision Trees

### Where Should Code Live?

```
Is it business rules?
├─ Yes → Involves single entity?
│        ├─ Yes → Entity/Value Object
│        └─ No  → Domain Service
└─ No  → Is it process orchestration?
         ├─ Yes → Application Service
         └─ No  → External system interaction?
                  ├─ Yes → Infrastructure Adapter
                  └─ No  → UI Layer or rethink
```

### Domain Service vs Application Service?

| Aspect | Domain Service | Application Service |
|--------|---------------|---------------------|
| Logic type | Pure business rules | Process orchestration |
| Dependencies | Other domain objects only | Repositories, Ports |
| Persistence | Never | Yes (via Repository) |
| External calls | Never | Yes (via Ports) |
| Reusable by | Other Domain/App Services | Controllers only |

---

## Communication Patterns

| Need | Pattern | Coupling |
|------|---------|----------|
| Async notification | Application Event | Low |
| Cross-BC trigger | Event via Shared Kernel | Low |
| Sync response needed | HTTP + Discovery | Medium |
| Same deployment unit | Interface call or Event | Medium |
| Last resort only | Direct dependency | High |

---

## Red Flags

```
⚠️ Domain Entity importing infrastructure
⚠️ Application Service instantiating Adapters
⚠️ Controller containing business logic
⚠️ Port interface mimicking 3rd party API
⚠️ Circular dependencies between components
⚠️ Component A modifying Component B's data
⚠️ Utils/Commons with mixed concerns
⚠️ Full entities in Shared Kernel
```

---

## Abolish Utils!

```
✗ WRONG: Acme/Utils/Everything

✓ RIGHT:
  Acme/PhpExtension/Uuid      → Language Extension
  Order/Domain/Service/Calc   → Domain logic
  App/Infrastructure/Cli      → Infrastructure
```

All packages must have:
- Conceptual cohesion
- Explicit usage patterns
- No ambiguity

---

## Testing by Layer

| Layer | Test Type | Mock What |
|-------|-----------|-----------|
| Domain | Unit | Nothing (pure) |
| Application | Integration | Ports |
| Infrastructure | Integration | External services |
| Shared Kernel | Unit | Nothing |
| Language Extensions | Unit | Nothing |

---

## Architecture Decision Output Template

When making decisions, document:

```markdown
## Problem
[What needs to be solved]

## Decision
[The chosen approach]

## Code Type
- [ ] Application Code (Layer: ___)
- [ ] Shared Kernel
- [ ] Language Extension

## Dependencies
[New dependencies with direction validation]

## Structure
[File/directory layout]

## Validation
[Checklist results]
```
