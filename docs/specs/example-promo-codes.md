# Spec: Promo code support in pricing-service

*(Worked example — output of the spec-agent for the request
"Add promo-code support to pricing")*

## 1. Summary
Allow a customer to apply a promotional code at checkout so that an eligible
order receives a discount calculated by pricing-service.

## 2. Affected services
- `pricing-service` (owner of the change — price calculation)
- `order-service` (passes the optional promo code through at pricing time)

No other bounded context is touched. order-service does NOT compute discounts.

## 3. Acceptance criteria
1. Given a valid, active promo code, when an order is priced, then the discount
   is applied and reflected in the order total.
2. Given an expired or unknown code, when an order is priced, then the order is
   priced normally and a non-blocking "code not applied" reason is returned.
3. Given a code below its minimum-spend threshold, then it is not applied.
4. A code may be applied at most once per order (idempotent).

## 4. Edge cases & failure modes
- Empty / null code → treat as "no code", never error.
- Two codes on one order → out of scope (see below).
- pricing-service must remain idempotent if the price event is replayed.

## 5. Out of scope
- Stacking multiple codes on one order.
- Admin UI for creating codes (separate feature).

## 6. Open questions
- Should expired-code attempts be logged for analytics? (assumed: yes, non-PII)
