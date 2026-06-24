---
name: complypay-payments-api
description: Reference for the ComplyPay Payments API used in Crispa payment integrations. Use when initiating payments or working with payment states and endpoints.
---

# ComplyPay Payments API Reference

Quick reference for the ComplyPay Payments API used in our payment processing integrations.

## Authentication

- **JWT Token**: `POST /authenticate-jwt` → returns JWT, refresh with `POST /jwt-refresh`
- **API Key**: Via `Authorization` header
- **Basic HTTP**: Via `userLogin` scheme

## Payment Types

| Type | Description |
|------|-------------|
| `TRANSFER` | Payment between two wallets (e.g. SPLIT to VENDOR) |
| `PAY_IN` | Payment from external source to a Virtual IBAN |
| `WITHDRAWAL` | Payment from a wallet to an external IBAN |

## Payment States

| State | Description |
|-------|-------------|
| `PENDING` | Awaiting conditions to be met |
| `INITIATED_PAYMENT` | Registered in internal system |
| `PROCESSING_PAYMENT` | Sent for processing via bank partner |
| `PROCESSED` | Confirmed processed by banking partner |
| `REJECTED_COMPLIANCE` | Rejected by compliance provider |
| `REJECTED_APPROVAL` | Rejected via dashboard |
| `REJECTED_SIGNING` | Rejected via ComplyPay authenticator app |
| `CANCELLED` | Cancelled by user or API |
| `FAILED` | Payment failed |
| `REVERSED` | Processed payment reversed |
| `REFUNDED` | Refunded via refund endpoint |

## Core Payment Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/create-payment-object` | Create payment |
| `POST` | `/search-payment-objects` | Search payments (paginated) |
| `GET` | `/find-payment-object-by-id` | Retrieve by ID |
| `GET` | `/get-payment-error-logs-by-id` | Get error logs |
| `POST` | `/create-payment-batch-1` | Batch create payments |
| `POST` | `/batch-retrieve-payment-objects` | Batch retrieve (paginated) |
| `POST` | `/add-supporting-docs-1` | Add supporting documentation |
| `POST` | `/refund-payment` | Refund payment |
| `PATCH` | `/approve-payment-object` | Approve payment |
| `PATCH` | `/reject-payment-object` | Reject payment |
| `PATCH` | `/cancel-payment-object` | Cancel single payment |
| `PATCH` | `/cancel-payment-objects` | Cancel multiple payments |

## FX Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/fx-rate` | Get FX rate quote |
| `POST` | `/fx` | Execute FX exchange |

## Vendor Account Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/create-vendor-account` | Create vendor account |
| `GET` | `/get-vendor-account-by-id` | Retrieve by ID |
| `POST` | `/search-vendor-accounts` | Search vendor accounts |
| `PATCH` | `/update-vendor-account` | Update vendor account |
| `GET` | `/generate-iban_1_1` | Generate IBAN |
| `POST` | `/execute-vendor-payouts` | Batch payouts |
| `POST` | `/vendor-payout` | Single payout |
| `POST` | `/send-vendor-onboarding-email-1` | Send onboarding email |

## Payment Account Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/accounts-create` | Create account |
| `PATCH` | `/update-account` | Update account |
| `GET` | `/get-accounts` | List all accounts |
| `GET` | `/get-account` | Get specific account |
| `GET` | `/get-balances_1` | Get account balances |
| `POST` | `/payout` | Execute payout |
| `PATCH` | `/freeze-account-outbound_1` | Freeze outbound payouts |
| `PATCH` | `/unfreeze-account-outbound_1` | Unfreeze outbound payouts |
| `GET` | `/proof-of-account-pdf` | Get proof document |
| `GET` | `/list-account-types` | List account types |

## Webhook Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/create-webhook` | Create webhook |
| `POST` | `/batch-retrieve-webhooks` | Batch retrieve webhooks |
| `PATCH` | `/update-webhook` | Update webhook |
| `DELETE` | `/delete-webhook` | Delete webhook |

Webhooks notify your application when a PaymentObject changes state or when new ones are created.

## Compliance Notes

- All payments to payee wallets configured for payouts (e.g. Vendor wallets) require signing via the **ComplyPay Authentication App**
- New payments appear on dashboards for condition verification (approval, signing)
- Supporting documents can be attached to payment objects for compliance

## API Docs

Full documentation: https://docs.complypay.com/reference/payments
