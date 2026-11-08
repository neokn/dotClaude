# Architecture Reasoning Examples

Detailed Chain of Thought examples for common architectural decisions.

---

## Example 1: Send Order Confirmation Email

**Problem**: After order placement, send confirmation email.

### CoT Process

```
[Step 1: Problem Type]
→ "Where should code live" + "How to abstract external dependency"

[Step 2: Determine Layer]
- "Sending email" = External system interaction → Infrastructure
- "When/whom/what to send" = Business process → Application
- "Email content template" = May involve order state → Domain (optional)

[Step 3: Dependency Direction]
Application Service → EmailSender Port ← SendGridAdapter
✓ Correct: App depends on interface, Infra implements it

[Step 4: Pattern Selection]
Use Event-driven approach:
- CreateOrderHandler publishes OrderCreated event
- SendOrderConfirmationListener handles event, calls EmailSender

Why events?
- Decouples order creation from notification
- Easy to add SMS, Push later
- Single Responsibility Principle

[Step 5: Validation]
✓ Dependencies point inward
✓ Domain stays pure
✓ Port designed for business needs
✓ Easy to test (mock EmailSender)
```

### Result Structure

```
src/
├── Application/
│   ├── Port/
│   │   └── EmailSenderInterface.php
│   ├── Handler/
│   │   └── CreateOrderHandler.php       # Publishes event
│   └── Listener/
│       └── SendOrderConfirmationListener.php
├── Domain/
│   └── Event/
│       └── OrderCreated.php
└── Infrastructure/
    └── Email/
        └── SendGridEmailAdapter.php
```

---

## Example 2: Shared Kernel for User Registration

**Problem**: Multiple bounded contexts need to react when user registers.

### CoT Process

```
[Step 1: Problem Type]
→ "Should this be in Shared Kernel"

[Step 2: Shared Kernel Evaluation]

Q1: Used by multiple BCs?
- User BC triggers event
- Notification BC sends welcome email
- Analytics BC tracks signups
- Marketing BC adds to campaigns
→ Yes

Q2: For cross-BC communication?
→ Yes, exactly

Q3: Simple enough to serialize?
- UserId ✓ Simple
- Email ✓ Simple
- RegisteredAt ✓ Simple
- User Entity ✗ Too complex
→ Yes (excluding full entity)

Q4: Minimal and stable?
→ Yes

[Step 3: Design]

IN Shared Kernel:
- UserRegistered event
- UserId value object
- Email value object

OUT of Shared Kernel:
- User entity
- UserRepository
- Registration business rules
```

### Result Structure

```
src/
├── SharedKernel/
│   ├── Domain/ValueObject/
│   │   ├── UserId.php
│   │   └── Email.php
│   └── Application/Event/
│       └── UserRegistered.php
├── User/
│   ├── Domain/Entity/
│   │   └── User.php           # Full entity stays here
│   └── Application/Handler/
│       └── RegisterUserHandler.php
├── Notification/
│   └── Application/Listener/
│       └── SendWelcomeEmailOnUserRegistered.php
└── Analytics/
    └── Application/Listener/
        └── TrackSignupOnUserRegistered.php
```

---

## Example 3: Refactoring Utils Package

**Problem**: Mixed Utils package needs organization.

### Inventory

```
Utils/
├── UuidGenerator
├── StringHelper
├── OrderValidator
├── SlackNotifier
├── DateTimeHelper
└── PriceCalculator
```

### Classification Process

| Utility | Domain-specific? | Could be std lib? | Decision |
|---------|------------------|-------------------|----------|
| UuidGenerator | No | Yes | Language Extension |
| StringHelper | No | Yes | Language Extension |
| OrderValidator | **Yes** | No | Domain Layer |
| SlackNotifier | No (infrastructure) | No | Infrastructure + Port |
| DateTimeHelper | No | Yes | Language Extension |
| PriceCalculator | **Yes** | No | Domain Layer |

### Result Structure

```
src/
├── PhpExtension/           # Language Extensions
│   ├── Uuid/
│   ├── String/
│   └── DateTime/
├── Order/                  # Order BC
│   └── Domain/Service/
│       └── OrderValidator.php
├── Billing/                # Billing BC
│   └── Domain/Service/
│       └── PriceCalculator.php
└── App/
    ├── Application/Port/
    │   └── TeamNotifierInterface.php
    └── Infrastructure/Notification/
        └── SlackTeamNotifier.php
```

---

## Example 4: Domain Service vs Application Service

**Problem**: Where should "calculate order discount" live?

### CoT Process

```
[Step 1: Analyze Logic]

Discount rules:
- Member level → discount percentage
- Order amount threshold → additional discount
- Product-specific fixed discounts
- Stacking limit

All business rules → Domain Layer

[Step 2: Single entity or cross-entity?]

Involves:
- Order
- Member
- Product
- DiscountPolicy

Multiple entities → Domain Service

[Step 3: Confirm NOT Application Service]

Application Service traits:
- Orchestrates process ✗
- Transaction boundaries ✗
- External system calls ✗

Discount calculation traits:
- Pure business logic ✓
- No persistence ✓
- No external calls ✓
- Reusable across use cases ✓

→ Domain Service
```

### Code Example

```php
// Domain Service - Pure domain logic
class DiscountCalculator
{
    public function calculate(Order $order, Member $member): Discount
    {
        // Business rules only
        // No external dependencies
    }
}

// Application Service - Orchestrates
class CreateOrderHandler
{
    public function handle(CreateOrderCommand $cmd): void
    {
        $member = $this->memberRepo->findById($cmd->memberId);
        $order = Order::create($cmd->items);

        // Calls Domain Service
        $discount = $this->discountCalculator->calculate($order, $member);
        $order->applyDiscount($discount);

        $this->orderRepo->save($order);
        $this->eventDispatcher->dispatch($order->releaseEvents());
    }
}
```

---

## Decision Checklist

Before finalizing any architectural decision:

```
□ Is the dependency direction correct (inward)?
□ Is the Domain Layer free of external dependencies?
□ Are Ports named for business concepts, not tech?
□ Is Shared Kernel minimal (events, IDs, simple VOs only)?
□ Has Utils been eliminated in favor of proper locations?
□ Is this the simplest solution that works?
□ Can this be tested without complex mocking?
□ Will the team understand this in 6 months?
```
