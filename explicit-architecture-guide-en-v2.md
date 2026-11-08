# Explicit Architecture Design Guide (with CoT Reasoning Framework)

> Integrating DDD, Hexagonal, Onion, Clean Architecture, and CQRS
> This guide includes Chain of Thought reasoning frameworks for LLM-assisted architecture design decisions

---

## Table of Contents

1. [Architecture Knowledge Base](#1-architecture-knowledge-base)
   - 1.1 [Fundamental Blocks of the System](#11-fundamental-blocks-of-the-system)
   - 1.2 [Tools Classification](#12-tools-classification)
   - 1.3 [Ports & Adapters](#13-ports--adapters)
   - 1.4 [Application Core Organization](#14-application-core-organization)
   - 1.5 [Components](#15-components)
   - 1.6 [Layer Dependency Rules](#16-layer-dependency-rules)
   - 1.7 [The Four Major Code Types](#17-the-four-major-code-types)
   - 1.8 [Shared Kernel](#18-shared-kernel)
   - 1.9 [Language Extensions](#19-language-extensions)
   - 1.10 [Flow of Control](#110-flow-of-control)
2. [CoT Reasoning Framework](#2-cot-reasoning-framework)
3. [Decision Flow Trees](#3-decision-flow-trees)
4. [Reasoning Examples](#4-reasoning-examples)
5. [Quick Reference Card](#5-quick-reference-card)

---

# 1. Architecture Knowledge Base

## 1.1 Fundamental Blocks of the System

The system is divided into three fundamental blocks:

1. **User Interface (UI)**: Makes it possible to run the application through various interfaces (Web, Mobile, CLI, API)
2. **Application Core**: The system's business logic — this is the code that really matters
3. **Infrastructure**: Connects the Application Core to external tools (databases, search engines, 3rd party APIs)

### Typical Request Flow

```
User Interface → Application Core → Infrastructure → Application Core → User Interface
```

### Key Principle

The Application Core is what we should really care about. It IS our application. It might use several user interfaces (progressive web app, mobile, CLI, API, ...) but the code actually doing the work is the same and is located in the Application Core.

---

## 1.2 Tools Classification

| Type | Description | Examples | Identification |
|------|-------------|----------|----------------|
| **Driving** | Tools that tell the application to do something | CLI, Web Server, API Gateway | "Who initiates the request?" → External |
| **Driven** | Tools that are told by the application to do something | Database, Search Engine, Message Queue, Email Service | "Who initiates the request?" → Application |

---

## 1.3 Ports & Adapters

### Ports

- A Port is **a specification** of how the tool can use the application core, or how it is used by the Application Core
- Ports **belong inside the Application Core**
- Design Ports to fit the Application Core needs, **not simply mimic the tools' APIs**
- In most languages, a Port will be an Interface (possibly composed of several Interfaces and DTOs)

### Primary/Driving Adapters

- **Wrap around a Port** and use it to tell the Application Core what to do
- Translate whatever comes from a delivery mechanism into a method call in the Application Core
- Examples: Controllers, Console Commands
- They are injected with objects implementing the Port interface

```
[Controller] --uses--> [Port Interface] <--implements-- [Application Service]
```

### Secondary/Driven Adapters

- **Implement a Port** interface
- Are injected into the Application Core wherever the Port is required
- Examples: MySQL Repository, S3 Storage Adapter, SendGrid Email Adapter

```
[Application Core] --depends on--> [Port Interface] <--implements-- [MySQL Adapter]
```

### Inversion of Control

- The direction of dependencies is towards the center
- Business logic only depends on Ports (interfaces), not on concrete Adapters or tools
- This is the **Dependency Inversion Principle at the architectural level**

---

## 1.4 Application Core Organization

### Application Layer

**Responsibility**: Define Use Cases (business processes that can be triggered)

**Contains**:
- Application Services (and their interfaces)
- Ports & Adapters interfaces (ORM, search engines, messaging)
- Command Handlers / Query Handlers
- Application Events

**Typical Application Service Flow**:
1. Use a Repository to find one or several entities
2. Tell those entities to do some domain logic
3. Use the Repository to persist the entities again

**Application Events**:
- Represent some outcome of a use case
- Trigger side-effect logic (sending emails, notifying 3rd party APIs, push notifications)
- Can start another use case that belongs to a different component

### Domain Layer

**Contains**:
- Domain Services (domain logic involving multiple entities)
- Domain Model (Entities, Value Objects, Enums)
- Domain Events

#### Domain Services

- Handle domain logic that involves different entities and doesn't belong in the entities themselves
- Keep domain logic reusable across use cases
- Know nothing about Application Layer classes (Application Services, Repositories)

#### Domain Model

- Contains business objects that represent something in the domain
- Domain Events are triggered when specific data changes and carry those changes with them
- Suitable for Event Sourcing patterns

---

## 1.5 Components

### Component Division

- Segregate code according to **subdomains** and **bounded contexts**
- Use "Package by Component" rather than "Package by Layer"
- Example components: Billing, User, Review, Account, Order
- Components are cross-cutting to the layers (each component has its own layers)

### Component Decoupling Mechanisms

| Mechanism | Use Case | Coupling Level |
|-----------|----------|----------------|
| Domain Events | Internal state change notifications within component | Low |
| Application Events | Async cross-component communication | Low |
| Shared Kernel | Shared core concepts across components | Medium (use carefully) |
| HTTP Call + Discovery | Sync cross-component calls requiring response | Medium |
| Direct Dependency | Tightly related components | High (avoid) |

### Cross-Component Data Access

**Principle**: A component is not allowed to change data that it does not "own", but it is fine for it to query and use any data.

#### Shared Data Storage
- Component queries another component's data table directly
- Must use the data as **read-only** via Query Objects

#### Segregated Data Storage
Each component's data storage contains:
1. **Owned data**: The single source of truth, only this component can modify
2. **Copied data**: Read-only copies of other components' data, updated via events

---

## 1.6 Layer Dependency Rules

| Layer | Can Depend On | Cannot Depend On |
|-------|---------------|------------------|
| Domain | Nothing (pure domain logic) | Any outer layer |
| Application | Domain | Infrastructure, UI |
| Infrastructure | Application (interfaces), Domain | UI |
| UI | Application (interfaces) | Direct Domain access |

### Dependency Direction Rule

All dependencies that cross the Application Core boundary must point **inwards** (towards the center).

---

## 1.7 The Four Major Code Types

Beyond concentric layers, there are **four major types of code** at the macro level. Making them explicit in code organization is key to avoiding a big ball of mud.

```
┌─────────────────────────────────────────────────────────┐
│                    Application Code                      │
│  ┌─────────────────────────────────────────────────┐    │
│  │              User Interface Layer                │    │
│  ├─────────────────────────────────────────────────┤    │
│  │            Infrastructure Layer                  │    │
│  ├─────────────────────────────────────────────────┤    │
│  │            Application Layer                     │    │
│  ├─────────────────────────────────────────────────┤    │
│  │              Domain Layer                        │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Shared Kernel                         │
│  (Domain & Application code shared between BCs)          │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  Language Extensions                     │
│  (Code that compensates for language limitations)        │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                 Programming Language                     │
└─────────────────────────────────────────────────────────┘
```

### The Four Types

| Type | Description | Dependency Direction |
|------|-------------|---------------------|
| **Application Code** | The concentric layers (UI, Infrastructure, Application, Domain) | Depends on Shared Kernel |
| **Shared Kernel** | Code shared between bounded contexts for communication | Depends on Language Extensions |
| **Language Extensions** | Custom constructs that compensate for language limitations | Depends on Programming Language |
| **Programming Language** | The base language itself | Foundation |

---

## 1.8 Shared Kernel

### Definition

The Shared Kernel, as defined by Eric Evans, is the code that the development team decides to share between several bounded contexts:

> "Some subset of the domain model that the two teams agree to share. Of course this includes, along with this subset of the model, the subset of code or of the database design associated with that part of the model. This explicitly shared stuff has special status, and shouldn't be changed without consultation with the other team."

### What the Shared Kernel Contains

In the context of Explicit Architecture, the Shared Kernel contains **domain and application layer code** that is shared among bounded contexts for communication:

- **Events** triggered in one or more bounded contexts and listened to in others
- **Entity IDs** used to reference entities across boundaries
- **Value Objects** that are used by shared events
- **Enums** that represent shared concepts
- **Specifications** objects for shared business rules

### What the Shared Kernel Should NOT Contain

- Complex objects like full Entities (problematic to serialize/unserialize)
- Infrastructure code
- UI code
- Component-specific business logic

### Key Characteristics

1. **Completely decoupled from components**: Components depend on the Shared Kernel, but are decoupled from each other
2. **Explicitly identified**: Shared code is clearly marked and easily extractable
3. **Minimal**: Should be as small as possible; changes affect all components
4. **Language-agnostic for polyglot systems**: Use JSON, XML, YAML for event descriptions in microservices

### Position in Architecture

The Shared Kernel sits **below** the Application Code, not outside it. Dependencies still point inward:

```
Component A ──┐
              ├──► Shared Kernel
Component B ──┘
```

### Benefits

1. Components are decoupled from each other while coupled to a minimal shared core
2. Easy to extract bounded contexts into microservices (shared kernel becomes a library)
3. Clear boundaries for what is shared vs. component-specific

---

## 1.9 Language Extensions

### The Problem with Utils and Commons

When language constructs are insufficient, developers typically create a `Utils` or `Commons` package. This becomes a **bucket for code with no home**:

- No conceptual meaning
- No consistency or cohesion
- No explicitness
- Full of ambiguity

**Abolish Utils and Commons packages!**

### The Solution: Explicit Naming with Purpose

All packages must have:
- **Conceptual cohesion**
- **Explicit usage patterns**
- **No ambiguity**

### Two Approaches for Language Extensions

#### Approach 1: Infrastructure Package

If the code is application-specific infrastructure:

```
# Instead of:
Acme/Util/SpecialCli

# Use:
Acme/App/Infrastructure/Cli/SpecialCli
```

This tells us:
- This package is about the CLI
- It is part of the infrastructure of application 'App'
- There is a port in the application core to which this package complies

#### Approach 2: Language Extension Package

If the code should be treated as part of the language itself:

```
# Instead of:
Acme/Util/Uuid

# Use:
Acme/PhpExtension/Uuid
```

This tells us:
- This package should be seen as part of the language itself
- Its code should be used directly in the codebase as any language construct
- If we own the package, we can treat it as part of the language

### Examples of Language Extensions

| Concept | Should Be Language Extension? | Reasoning |
|---------|------------------------------|-----------|
| UUID | Yes | Generic, widespread, consistent concept |
| DateTime extensions | Yes | Fills gaps in standard library |
| Custom Collections | Yes | Generic data structures |
| ORM Query Language | Maybe | If treating it as standard query mechanism |
| Domain-specific validators | No | Should be in Domain layer |

### Usage Guidelines

- **If you own the package**: Can use directly as language construct
- **If depending on external package**: Consider creating port/adapter for swappability
- **Tradeoff consideration**: Risk of needing to swap vs. simplicity of direct use

---

## 1.10 Flow of Control

### Without Command/Query Bus

```
┌─────────────┐
│ Controller  │
└──────┬──────┘
       │ depends on
       ▼
┌─────────────────────┐
│ Application Service │ ◄── Port (Interface)
│     Interface       │
└──────┬──────────────┘
       │ implements
       ▼
┌─────────────────────┐
│ Application Service │
└──────┬──────────────┘
       │ uses
       ▼
┌─────────────────────┐     ┌────────────────┐
│ Repository Interface│ ◄───│ ORM Interface  │
└──────┬──────────────┘     └───────┬────────┘
       │ implements                 │ implements
       ▼                            ▼
┌─────────────────────┐     ┌────────────────┐
│ Repository (MySQL)  │────►│ ORM Adapter    │
└─────────────────────┘     └────────────────┘
```

**Query Flow**:
```
Controller → Query Object → DTO → ViewModel → View
```

### With Command/Query Bus

```
┌─────────────┐
│ Controller  │
└──────┬──────┘
       │ creates Command/Query
       ▼
┌─────────────┐
│    Bus      │ ◄── configured to route to Handler
└──────┬──────┘
       │ dispatches
       ▼
┌─────────────────────┐
│ Command/Query       │
│ Handler             │
└──────┬──────────────┘
       │ may use
       ▼
┌─────────────────────┐
│ Application Service │
└─────────────────────┘
```

**Important**: The Bus has no direct dependency on Command/Query/Handler. The routing is configured externally for good decoupling.

### Repository vs Persistence Interface

Both serve different purposes:

| Interface | Purpose | When to Change |
|-----------|---------|----------------|
| **Persistence Interface** | Abstraction over the ORM | When swapping ORM (e.g., Doctrine to Eloquent) |
| **Repository Interface** | Abstraction over the persistence engine | When swapping database type (e.g., MySQL to MongoDB) |

---

# 2. CoT Reasoning Framework

## 2.1 General Architecture Decision Thinking Process

When making architecture decisions, follow these steps sequentially:

```
[Step 1: Identify Problem Type]
           ↓
[Step 2: Determine Layer]
           ↓
[Step 3: Analyze Dependency Direction]
           ↓
[Step 4: Select Appropriate Pattern]
           ↓
[Step 5: Validate Decision]
           ↓
[Step 6: Output Design]
```

---

## 2.2 Step 1: Identify Problem Type

**Thinking Template**:

```
What type of problem am I dealing with?

□ Where should this new code live? → Enter "Code Placement Flow"
□ How should two modules communicate? → Enter "Communication Pattern Selection Flow"
□ How to abstract an external dependency? → Enter "Port/Adapter Design Flow"
□ How to divide system boundaries? → Enter "Component Division Flow"
□ How to handle cross-component data needs? → Enter "Data Access Strategy Flow"
□ Should this be in Shared Kernel? → Enter "Shared Kernel Evaluation Flow"
□ Is this a language extension candidate? → Enter "Language Extension Evaluation Flow"
```

---

## 2.3 Step 2: Determine Layer

**Thinking Template**:

```
What is the essence of this logic?

Question 1: Does this logic involve "business rules"?
  - Yes → Likely belongs to Domain Layer
  - No → Continue to next question

Question 2: Does this logic "coordinate a process" or "orchestrate multiple steps"?
  - Yes → Likely belongs to Application Layer
  - No → Continue to next question

Question 3: Does this logic "interact with external systems"?
  - Yes → Likely belongs to Infrastructure Layer
  - No → Continue to next question

Question 4: Does this logic "receive/present data to users"?
  - Yes → Likely belongs to UI Layer
  - No → Continue to next question

Question 5: Is this logic "shared between bounded contexts"?
  - Yes → Likely belongs to Shared Kernel
  - No → Continue to next question

Question 6: Does this logic "compensate for language limitations"?
  - Yes → Likely belongs to Language Extensions
  - No → Re-analyze the requirement
```

**Layer Characteristics Quick Reference**:

| Layer | Key Characteristics | Typical Verbs |
|-------|---------------------|---------------|
| Domain | Business rules, invariants, entity behavior | validate, calculate, apply, enforce |
| Application | Process orchestration, use cases, transaction boundaries | execute, handle, process, coordinate |
| Infrastructure | Technical implementation, external communication, persistence | save, fetch, send, connect, query |
| UI | Request handling, response formatting, routing | receive, respond, render, route |
| Shared Kernel | Cross-BC communication, shared events, shared IDs | trigger, listen, identify |
| Language Extensions | Generic utilities, language gaps | generate, parse, format, convert |

---

## 2.4 Step 3: Analyze Dependency Direction

**Thinking Template**:

```
Check if dependency direction is correct:

1. Which layer is my code in? → [Current Layer]
2. Which layer is the code I depend on? → [Target Layer]
3. Dependency direction check:
   - Current Layer → Target Layer
   - Is this direction "inward" or "outward"?

Valid dependency directions:
  UI → Application ✓
  Application → Domain ✓
  Application → Shared Kernel ✓
  Domain → Shared Kernel ✓
  Infrastructure → Application (interfaces) ✓
  Infrastructure → Domain ✓
  Any Layer → Language Extensions ✓

Invalid dependency directions (need inversion):
  Domain → Application ✗
  Domain → Infrastructure ✗
  Application → Infrastructure (implementations) ✗
  Application → UI ✗
  Shared Kernel → Application ✗
  Shared Kernel → Any Component ✗

If dependency direction is incorrect:
  → Introduce a Port (interface) for dependency inversion
  → Define the interface in the inner layer
  → Place the implementation in the outer layer
```

---

## 2.5 Step 4: Select Appropriate Pattern

### 4a. Code Placement Decision

```
Where should this code live?

IF logic is "behavior or rules of a single entity"
  THEN place in Entity or Value Object (Domain Layer)

ELSE IF logic is "domain rules across multiple entities"
  THEN place in Domain Service (Domain Layer)

ELSE IF logic is "orchestrating a complete business process"
  THEN place in Application Service or Command Handler (Application Layer)

ELSE IF logic is "concrete interaction with external systems"
  THEN place in Adapter (Infrastructure Layer)
  AND define corresponding Port (interface) in Application Layer

ELSE IF logic is "handling HTTP requests or formatting responses"
  THEN place in Controller (UI Layer)

ELSE IF logic is "event or ID shared between bounded contexts"
  THEN place in Shared Kernel

ELSE IF logic is "generic utility that compensates for language gaps"
  THEN place in Language Extensions
  AND ensure it has conceptual cohesion (NOT in Utils/Commons)
```

### 4b. Shared Kernel Evaluation

```
Should this code be in the Shared Kernel?

Question 1: Is this code used by multiple bounded contexts?
  - No → Keep in the component that owns it
  - Yes → Continue

Question 2: Is this code needed for cross-BC communication?
  - No → Consider if it's truly shared or just duplicated
  - Yes → Continue

Question 3: Is this code simple enough to serialize/unserialize?
  - No → Refactor to simpler types (IDs, Value Objects, DTOs)
  - Yes → Continue

Question 4: Can this code be kept minimal and stable?
  - No → Reconsider; changes affect all BCs
  - Yes → Place in Shared Kernel

Candidates for Shared Kernel:
  ✓ Domain Events (e.g., OrderCreated, UserRegistered)
  ✓ Entity IDs (e.g., UserId, OrderId)
  ✓ Simple Value Objects (e.g., Money, Email)
  ✓ Enums used across BCs (e.g., OrderStatus)
  ✓ Application Events for cross-BC triggers

NOT candidates for Shared Kernel:
  ✗ Full Entity classes
  ✗ Complex aggregates
  ✗ Repository interfaces
  ✗ Infrastructure code
```

### 4c. Language Extension Evaluation

```
Should this be a Language Extension?

Question 1: Is this a generic concept not specific to your domain?
  - No → Place in appropriate domain/application layer
  - Yes → Continue

Question 2: Could this reasonably be part of the standard library?
  - No → Consider if it's infrastructure instead
  - Yes → Continue

Question 3: Is this concept widespread and consistent enough?
  - No → Keep as internal utility within a component
  - Yes → Create as Language Extension

Question 4: Do you own/control this implementation?
  - No → Create Port/Adapter for it
  - Yes → Can use directly as language construct

Naming convention:
  {Company}/{Language}Extension/{Concept}
  Example: Acme/PhpExtension/Uuid

NOT Language Extensions (put elsewhere):
  ✗ Domain-specific validators → Domain Layer
  ✗ External service wrappers → Infrastructure Layer  
  ✗ Random utilities → Find proper home or delete
```

### 4d. Communication Pattern Selection

```
Component A needs to communicate with Component B. How to choose the pattern?

Question 1: Does A need to wait for B's response to continue?
  - No → Use Application Event (async)
  - Yes → Continue to next question

Question 2: Are A and B in the same deployment unit?
  - Yes → Consider direct call (via interface) or Event
  - No → Use HTTP Call + Discovery Service or Message Queue

Question 3: Will this communication happen frequently?
  - Yes → Consider performance impact; may need local cache or data replication
  - No → Simple Event or HTTP Call is sufficient

Recommended priority:
1. Application Event via Shared Kernel (lowest coupling)
2. Shared Kernel + Event (when shared concepts needed)
3. HTTP + Discovery (when sync response needed)
4. Direct dependency (last resort, only for tightly related components)
```

### 4e. Port/Adapter Design

```
Thinking process for designing Ports and Adapters:

Step 1: Identify the Application Core's "needs"
  - What capabilities does the core need? (e.g., store users, send notifications)
  - Describe in business language, not technical terms

Step 2: Define the Port (interface)
  - Name interface methods based on business needs
  - Example: UserRepository.save(user) NOT MySQLConnection.insert(table, data)
  - Place Port in Application Layer

Step 3: Implement the Adapter
  - Implement the Port interface for a specific technology
  - Example: MySQLUserRepository implements UserRepository
  - Place Adapter in Infrastructure Layer

Step 4: Configure Dependency Injection
  - In the Composition Root, inject Adapter wherever Port is required
```

---

## 2.6 Step 5: Validate Decision

**Checklist**:

```
□ Do all dependencies point towards the core (inward)?
□ Is the Domain Layer kept pure (no external dependencies)?
□ Are Ports designed based on business needs, not mimicking tool APIs?
□ Is Shared Kernel minimal and stable?
□ Are Language Extensions genuinely generic (not domain-specific)?
□ Is there any code in Utils/Commons that should be relocated?
□ Is this over-engineered? Is this abstraction level necessary for this project?
□ When changing an external tool, how much code needs modification?
□ Is this design easy to test?
□ Can the team understand and maintain this design?
□ Does the code organization explicitly communicate the architecture?
```

---

## 2.7 Step 6: Output Design

**Standard Output Format**:

```
## Architecture Decision Record

### Problem Description
[Describe the problem to be solved]

### Decision
[The chosen solution]

### Rationale
[Why this solution was chosen, which principles were referenced]

### Code Type Classification
- [ ] Application Code (which layer?)
- [ ] Shared Kernel
- [ ] Language Extension

### Layer Assignment
- Related code belongs to: [Layer]
- Involved components: [Component]

### Dependencies
[Describe new dependencies, confirm direction is correct]

### Code Structure
[Directory/file structure diagram]

### Alternatives Considered
[Solutions considered but not chosen, and why]
```

---

# 3. Decision Flow Trees

## 3.1 "Where Should Code Live" Decision Tree

```
                    [New Code/Logic]
                           │
                           ▼
              ┌─────────────────────────────┐
              │ Is this shared between      │
              │ bounded contexts?           │
              └─────────────┬───────────────┘
                            │
                   ┌────────┴────────┐
                   ▼                 ▼
                  Yes               No
                   │                 │
                   ▼                 ▼
          ┌───────────────┐  ┌──────────────────────┐
          │ Simple enough │  │ Is this a generic    │
          │ for Shared    │  │ language construct?  │
          │ Kernel?       │  └──────────┬───────────┘
          └───────┬───────┘             │
                  │              ┌──────┴──────┐
           ┌──────┴──────┐       ▼             ▼
           ▼             ▼      Yes           No
          Yes           No       │             │
           │             │       ▼             ▼
           ▼             ▼  [Language     [Continue to
      [Shared        [Refactor Extension]  Layer Decision]
       Kernel]        first]                   │
                                               ▼
                              ┌─────────────────────────────┐
                              │ Is this business rule/      │
                              │ domain logic?               │
                              └─────────────┬───────────────┘
                                            │
                                   ┌────────┴────────┐
                                   ▼                 ▼
                                  Yes               No
                                   │                 │
                                   ▼                 ▼
                          ┌───────────────┐  ┌──────────────────────┐
                          │ Involves      │  │ Is this process      │
                          │ single entity?│  │ orchestration?       │
                          └───────┬───────┘  └──────────┬───────────┘
                                  │                     │
                           ┌──────┴──────┐       ┌──────┴──────┐
                           ▼             ▼       ▼             ▼
                          Yes           No      Yes           No
                           │             │       │             │
                           ▼             ▼       ▼             ▼
                       [Entity/      [Domain  [App         [Infrastructure
                        Value         Service] Service/     or UI Layer]
                        Object]                Handler]
```

## 3.2 "Shared Kernel vs Component" Decision Tree

```
              [Code used by multiple bounded contexts]
                              │
                              ▼
                 ┌────────────────────────┐
                 │ Is this for cross-BC   │
                 │ communication?         │
                 └────────────┬───────────┘
                              │
                     ┌────────┴────────┐
                     ▼                 ▼
                    Yes               No
                     │                 │
                     ▼                 ▼
            ┌────────────────┐  ┌─────────────────┐
            │ Can be kept    │  │ Is this truly   │
            │ simple & stable│  │ shared or just  │
            │ ?              │  │ duplicated?     │
            └───────┬────────┘  └────────┬────────┘
                    │                    │
             ┌──────┴──────┐      ┌──────┴──────┐
             ▼             ▼      ▼             ▼
            Yes           No   Shared      Duplicated
             │             │      │             │
             ▼             ▼      ▼             ▼
        [Shared       [Keep in  [Shared    [Keep separate
         Kernel]       each BC   Kernel]    copies in
                       with                  each BC]
                       adapter]
```

## 3.3 "Language Extension vs Other" Decision Tree

```
                [Generic utility code]
                         │
                         ▼
            ┌────────────────────────┐
            │ Is this domain-        │
            │ specific?              │
            └────────────┬───────────┘
                         │
                ┌────────┴────────┐
                ▼                 ▼
               Yes               No
                │                 │
                ▼                 ▼
           [Domain or       ┌────────────────┐
            Application     │ Could this be  │
            Layer]          │ in std library?│
                            └───────┬────────┘
                                    │
                           ┌────────┴────────┐
                           ▼                 ▼
                          Yes               No
                           │                 │
                           ▼                 ▼
                  ┌────────────────┐  ┌─────────────────┐
                  │ Do you control │  │ Is this infra-  │
                  │ implementation?│  │ structure?      │
                  └───────┬────────┘  └────────┬────────┘
                          │                    │
                   ┌──────┴──────┐      ┌──────┴──────┐
                   ▼             ▼      ▼             ▼
                  Yes           No     Yes           No
                   │             │      │             │
                   ▼             ▼      ▼             ▼
              [Language     [Create  [Infra-     [Find proper
               Extension]    Port/    structure   home or
                            Adapter]  Layer]      delete]
```

## 3.4 "Cross-Component Communication" Decision Tree

```
                [Component A needs to interact with Component B]
                                    │
                                    ▼
                       ┌────────────────────────┐
                       │ Need synchronous       │
                       │ response?              │
                       └────────────┬───────────┘
                                    │
                           ┌────────┴────────┐
                           ▼                 ▼
                          Yes               No
                           │                 │
                           ▼                 ▼
                  ┌────────────────┐  ┌─────────────────┐
                  │ Same deployment│  │ Application     │
                  │ unit?          │  │ Event via       │
                  └───────┬────────┘  │ Shared Kernel   │
                          │           └─────────────────┘
                   ┌──────┴──────┐
                   ▼             ▼
                  Yes           No
                   │             │
                   ▼             ▼
            ┌────────────┐  ┌──────────────────┐
            │ Direct call│  │ HTTP Call +      │
            │ via inter- │  │ Discovery Service│
            │ face or    │  │ or Message Queue │
            │ Event      │  └──────────────────┘
            └────────────┘
```

---

# 4. Reasoning Examples

## Example 1: Adding "Send Order Confirmation Email" Feature

**Problem**: After a user places an order, the system needs to send an order confirmation email.

**CoT Reasoning Process**:

```
[Step 1: Identify Problem Type]
This is a "where should new code live" + "how to abstract external dependency" problem.

[Step 2: Determine Layer]
Thinking: What is the essence of this logic?

- "Sending email" itself is interaction with an external system (email service)
  → Implementation should be in Infrastructure Layer

- "Deciding when to send, to whom, and what content" is part of the business process
  → Triggering logic should be in Application Layer

- "Order confirmation email content template" is a business rule
  → May involve Domain Layer (if content relates to order state)

[Step 3: Analyze Dependency Direction]
- Application Service needs the capability to "send email"
- But should not directly depend on SendGrid or SES implementation
- Need to define a Port (interface) to ensure correct dependency direction

Dependency direction:
Application Service → EmailSender Port (interface) ← SendGridEmailAdapter (impl)
✓ Correct! Application depends on interface, Infrastructure implements interface

[Step 4: Select Appropriate Pattern]
Using Port/Adapter pattern:
- Port: EmailSender interface (in Application Layer)
- Adapter: SendGridEmailAdapter (in Infrastructure Layer)

Trigger timing:
- Option A: Directly call EmailSender in CreateOrderHandler
- Option B: Publish OrderCreated Event, Listener calls EmailSender

Choose B because:
- Decouples order creation from notification logic
- Easy to add other notification methods in the future (SMS, Push)
- Follows Single Responsibility Principle

[Step 5: Validate Decision]
□ Do all dependencies point towards the core? ✓
□ Is Domain Layer kept pure? ✓ (Domain not involved)
□ Is Port designed based on business needs? ✓ (EmailSender.sendOrderConfirmation)
□ Is this over-engineered? No, email service is likely to change in the future
□ When changing email service, how much code needs modification? Only add new Adapter
□ Is this design easy to test? ✓ Can mock EmailSender

[Step 6: Output Design]
```

**Design Result**:

```
src/
├── Application/
│   ├── Port/
│   │   └── EmailSenderInterface.php        # Port
│   ├── Handler/
│   │   └── CreateOrderHandler.php          # Publishes Event
│   └── Listener/
│       └── SendOrderConfirmationListener.php # Listens to Event, calls EmailSender
├── Domain/
│   └── Event/
│       └── OrderCreated.php                # Domain Event
└── Infrastructure/
    └── Email/
        └── SendGridEmailAdapter.php        # Adapter implementation
```

---

## Example 2: Deciding What Goes in Shared Kernel

**Problem**: Multiple bounded contexts need to react when a user registers.

**CoT Reasoning Process**:

```
[Step 1: Identify Problem Type]
This is a "should this be in Shared Kernel" problem.

[Step 2: Evaluate for Shared Kernel]

Question 1: Is this code used by multiple bounded contexts?
- User BC triggers the event
- Notification BC listens to send welcome email
- Analytics BC listens to track signups
- Marketing BC listens to add to campaigns
→ Yes, multiple BCs need this

Question 2: Is this code needed for cross-BC communication?
→ Yes, this is exactly for cross-BC communication

Question 3: Is this code simple enough to serialize/unserialize?
The event needs:
- UserId (Value Object) ✓ Simple
- Email (Value Object) ✓ Simple
- RegisteredAt (DateTime) ✓ Simple
- User Entity ✗ Too complex!
→ Yes, if we exclude the full User entity

Question 4: Can this code be kept minimal and stable?
- UserId is unlikely to change structure
- Basic registration event structure is stable
→ Yes

[Step 3: Design the Shared Kernel Contents]

What goes IN Shared Kernel:
- UserRegistered event (Application Event)
- UserId value object
- Email value object

What stays OUT of Shared Kernel:
- User entity (too complex, belongs to User BC)
- UserRepository (infrastructure concern)
- Registration business rules (domain logic of User BC)

[Step 4: Validate Decision]
□ Is Shared Kernel minimal? ✓ Only event + simple value objects
□ Is Shared Kernel stable? ✓ Basic structure unlikely to change
□ Are components decoupled from each other? ✓ They only depend on Shared Kernel
□ Easy to extract to library later? ✓ Clear boundaries

[Step 5: Output Design]
```

**Design Result**:

```
src/
├── SharedKernel/
│   ├── Domain/
│   │   └── ValueObject/
│   │       ├── UserId.php
│   │       └── Email.php
│   └── Application/
│       └── Event/
│           └── UserRegistered.php
├── User/                    # User Bounded Context
│   ├── Domain/
│   │   └── Entity/
│   │       └── User.php     # Full entity stays here
│   └── Application/
│       └── Handler/
│           └── RegisterUserHandler.php  # Triggers UserRegistered
├── Notification/            # Notification Bounded Context
│   └── Application/
│       └── Listener/
│           └── SendWelcomeEmailOnUserRegistered.php
└── Analytics/               # Analytics Bounded Context
    └── Application/
        └── Listener/
            └── TrackSignupOnUserRegistered.php
```

---

## Example 3: Refactoring Utils Package

**Problem**: The codebase has a `Utils` package with mixed code that needs proper organization.

**CoT Reasoning Process**:

```
[Step 1: Identify Problem Type]
This is a "Language Extension evaluation" + "code placement" problem.

[Step 2: Inventory the Utils Package]

Current Utils contents:
1. UuidGenerator - generates UUIDs
2. StringHelper - string manipulation utilities
3. OrderValidator - validates order business rules
4. SlackNotifier - sends Slack notifications
5. DateTimeHelper - date/time utilities
6. PriceCalculator - calculates prices with discounts

[Step 3: Classify Each Utility]

1. UuidGenerator
   - Domain-specific? No, generic concept
   - Could be in std library? Yes
   - Control implementation? Yes
   → Language Extension: Acme/PhpExtension/Uuid

2. StringHelper
   - Domain-specific? No, generic concept
   - Could be in std library? Yes
   - Control implementation? Yes
   → Language Extension: Acme/PhpExtension/String

3. OrderValidator
   - Domain-specific? YES! This is business logic
   - Belongs to Order bounded context
   → Domain Layer: Order/Domain/Service/OrderValidator

4. SlackNotifier
   - Domain-specific? No, but it's infrastructure
   - Interacts with external system
   → Infrastructure Layer with Port:
     - Port: Acme/App/Application/Port/TeamNotifier
     - Adapter: Acme/App/Infrastructure/Notification/SlackTeamNotifier

5. DateTimeHelper
   - Domain-specific? No, generic concept
   - Could be in std library? Yes
   → Language Extension: Acme/PhpExtension/DateTime

6. PriceCalculator
   - Domain-specific? YES! This is business logic
   - Involves business rules about pricing
   → Domain Layer: Billing/Domain/Service/PriceCalculator

[Step 4: Validate Decisions]
□ Is Utils package now empty? ✓ All code has proper home
□ Do all packages have conceptual cohesion? ✓
□ Is usage pattern explicit? ✓
□ No ambiguity? ✓

[Step 5: Output Design]
```

**Design Result**:

```
# BEFORE (problematic)
src/
└── Utils/
    ├── UuidGenerator.php
    ├── StringHelper.php
    ├── OrderValidator.php
    ├── SlackNotifier.php
    ├── DateTimeHelper.php
    └── PriceCalculator.php

# AFTER (organized)
src/
├── PhpExtension/                    # Language Extensions
│   ├── Uuid/
│   │   └── UuidGenerator.php
│   ├── String/
│   │   └── StringHelper.php
│   └── DateTime/
│       └── DateTimeHelper.php
├── Order/                           # Order Bounded Context
│   └── Domain/
│       └── Service/
│           └── OrderValidator.php   # Domain logic
├── Billing/                         # Billing Bounded Context
│   └── Domain/
│       └── Service/
│           └── PriceCalculator.php  # Domain logic
└── App/
    ├── Application/
    │   └── Port/
    │       └── TeamNotifierInterface.php  # Port
    └── Infrastructure/
        └── Notification/
            └── SlackTeamNotifier.php      # Adapter
```

---

## Example 4: Domain Service vs Application Service

**Problem**: Where should "calculate order discount" logic be placed?

**CoT Reasoning Process**:

```
[Step 1: Identify Problem Type]
This is a "code placement" problem.

[Step 2: Analyze Logic Essence]

Question: Does this logic involve "business rules"?

"Calculate discount" rules:
- Member level affects discount percentage
- Order amount threshold gives additional discount
- Specific products have fixed discounts
- Discounts cannot stack beyond upper limit

These are all business rules → Should be in Domain Layer

Question: Is this "single entity behavior" or "cross-entity logic"?

Concepts involved:
- Order
- Member
- Product
- DiscountPolicy

This involves collaboration of multiple entities → Domain Service

[Step 3: Confirm This Is Not Application Service]

Application Service characteristics:
- Orchestrates process (get entities → call domain logic → persist)
- Handles transaction boundaries
- Triggers events

"Calculate discount" characteristics:
- Pure business calculation
- No persistence involved
- No external system interaction
- Can be reused by multiple Use Cases

Conclusion: This is a Domain Service, not an Application Service

[Step 4: Validate Decision]

If placed in Application Service:
- Other Application Services needing this logic would duplicate code ✗
- Domain logic leaks to Application Layer ✗

If placed in Domain Service:
- Can be called by any Application Service ✓
- Domain logic concentrated in Domain Layer ✓
- Easy to unit test (no need to mock external dependencies) ✓

[Step 5: Output Design]
```

**Design Result**:

```
src/Order/
├── Domain/
│   ├── Service/
│   │   └── DiscountCalculator.php          # Domain Service
│   ├── Entity/
│   │   └── Order.php
│   └── ValueObject/
│       └── Discount.php
└── Application/
    └── Handler/
        └── CreateOrderHandler.php          # Calls DiscountCalculator
```

**Code Example**:

```php
// Domain Service - Pure domain logic
class DiscountCalculator
{
    public function calculate(Order $order, Member $member): Discount
    {
        // Business rule implementation
        // No dependency on any external system
    }
}

// Application Service - Process orchestration
class CreateOrderHandler
{
    public function handle(CreateOrderCommand $command): void
    {
        $member = $this->memberRepository->findById($command->memberId);
        $order = Order::create($command->items);
        
        // Call Domain Service
        $discount = $this->discountCalculator->calculate($order, $member);
        $order->applyDiscount($discount);
        
        $this->orderRepository->save($order);
        $this->eventDispatcher->dispatch($order->releaseEvents());
    }
}
```

---

# 5. Quick Reference Card

## Layer Quick Reference

| What I Need To Do | Target Layer | Reason |
|-------------------|--------------|--------|
| Validate entity business rules | Domain (Entity) | Entity's own invariants |
| Cross-entity business calculations | Domain (Service) | Domain logic, reusable |
| Handle a complete use case | Application (Handler) | Process orchestration |
| Connect to database/external services | Infrastructure (Adapter) | Technical implementation details |
| Handle HTTP requests | UI (Controller) | External interface |
| Share events/IDs between BCs | Shared Kernel | Cross-BC communication |
| Generic utilities (UUID, DateTime) | Language Extensions | Language gaps |

## The Four Code Types

| Type | Contains | Depends On |
|------|----------|------------|
| Application Code | UI, Infrastructure, Application, Domain layers | Shared Kernel |
| Shared Kernel | Cross-BC events, shared IDs, shared Value Objects | Language Extensions |
| Language Extensions | Generic utilities that compensate for language gaps | Programming Language |
| Programming Language | The base language | Nothing |

## Dependency Direction Quick Reference

```
Correct ✓                         Incorrect ✗
────────────────────────────      ────────────────────────────
Controller → AppService           AppService → Controller
AppService → Domain               Domain → AppService
AppService → SharedKernel         SharedKernel → Component
Adapter → Port (interface)        AppService → Adapter (impl)
Any → LanguageExtension           LanguageExtension → Domain
```

## Shared Kernel Checklist

```
Include in Shared Kernel:
  ✓ Application Events for cross-BC triggers
  ✓ Domain Events that multiple BCs listen to
  ✓ Entity IDs (UserId, OrderId, etc.)
  ✓ Simple Value Objects (Money, Email, etc.)
  ✓ Shared Enums

Exclude from Shared Kernel:
  ✗ Full Entity classes
  ✗ Complex Aggregates
  ✗ Repository interfaces
  ✗ Infrastructure code
  ✗ Domain Services
  ✗ Application Services
```

## Language Extension vs Utils

```
✗ WRONG: Acme/Utils/Everything

✓ RIGHT:
  Acme/PhpExtension/Uuid          # Generic, language-like
  Acme/PhpExtension/DateTime      # Generic, language-like
  Acme/App/Infrastructure/Cli     # App-specific infrastructure
  Order/Domain/Service/Validator  # Domain-specific logic
```

## Port Naming Guidelines

```
Name based on business needs, not technical terms:

✓ OrderRepository.findByCustomer(customerId)
✗ MySQLConnection.query("SELECT * FROM orders WHERE...")

✓ NotificationSender.notifyOrderShipped(order)
✗ SNSClient.publish(topic, message)

✓ PaymentGateway.charge(payment)
✗ StripeAPI.createCharge(amount, currency, source)
```

## Red Flags to Watch For

```
⚠️ Domain Entity importing infrastructure packages
⚠️ Application Service directly instantiating Adapters
⚠️ Controller containing business logic
⚠️ Domain Service accessing Repository directly
⚠️ Port interface mimicking 3rd party API structure
⚠️ Circular dependencies between components
⚠️ Component A modifying Component B's data directly
⚠️ Utils/Commons package with mixed concerns
⚠️ Full entities in Shared Kernel
⚠️ Shared Kernel depending on specific components
```

## Testing Strategy by Layer

| Layer | Test Type | What to Mock |
|-------|-----------|--------------|
| Domain | Unit Tests | Nothing (pure logic) |
| Application | Integration Tests | Ports (interfaces) |
| Infrastructure | Integration Tests | External services (use test containers) |
| UI | E2E Tests | Nothing or Application layer |
| Shared Kernel | Unit Tests | Nothing (simple data structures) |
| Language Extensions | Unit Tests | Nothing (pure utilities) |

---

## Key Principles Summary

### On Architecture

> "The architecture will always be there, the only question is: are we in control of it or not?!"

### On Code Organization

> "Explicitly organize the code so it helps communicate the architecture."

### On Shared Kernel

> "The shared kernel is completely decoupled from the remainder of the codebase, from the components. Components, although coupled to the shared kernel, are decoupled from each other."

### On Utils Packages

> "All packages must have conceptual cohesion! When and how a package is to be used must be explicit! There must be no ambiguity!"

### On Guidelines

> "These are just guidelines! The application is the territory, the reality, the concrete use case where we need to apply our knowledge."

Consider these factors when making decisions:
- Project functional requirements
- Time-frame to build the application
- Lifespan of the application
- Experience of the development team
- Current and expected scale
