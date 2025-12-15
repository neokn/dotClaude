---
name: api-design
description: Design RESTful APIs with best practices. Use when creating new endpoints, designing API contracts, or reviewing API structures.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# API Design Skill

Help design consistent, well-structured RESTful APIs.

## Principles

### URL Structure
- Use nouns for resources: `/users`, `/orders`
- Use plural forms: `/users` not `/user`
- Nest for relationships: `/users/{id}/orders`
- Keep URLs shallow (max 2-3 levels)

### HTTP Methods
- GET: Read (idempotent, cacheable)
- POST: Create
- PUT: Full update (idempotent)
- PATCH: Partial update
- DELETE: Remove (idempotent)

### Status Codes
- 200: Success
- 201: Created
- 204: No Content (successful DELETE)
- 400: Bad Request (client error)
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 409: Conflict
- 422: Unprocessable Entity (validation)
- 500: Server Error

### Response Format
```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "total": 100
  },
  "errors": [
    { "field": "email", "message": "Invalid format" }
  ]
}
```

### Pagination
- Use cursor-based for large datasets
- Use offset-based for simple cases
- Always include: `page`, `per_page`, `total`, `next_cursor`

### Versioning
- URL prefix: `/v1/users`
- Header: `Accept: application/vnd.api+json; version=1`

## Checklist for New Endpoints

- [ ] Clear resource naming
- [ ] Correct HTTP method
- [ ] Appropriate status codes
- [ ] Input validation
- [ ] Error response format
- [ ] Authentication required?
- [ ] Rate limiting needed?
- [ ] Documentation updated
