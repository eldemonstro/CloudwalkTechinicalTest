# Cloudwalk Technical Test

## Understanding the Industry

### The Money Flow

1. The consumer contracts a bank and open a credit card account, being issued a card with a unique account number.
2. The consumer then goes to a merchant and selects goods to purchase, using the credit card information to pay the transaction.
3. The merchant takes the credit card information and validates it through tests, then sends to the the acquiring bank to check if the account has enough credit to make the purchase.
  - How the information reaches the bank depends on what the merchant is using as a gateway or payment processor, both operating as a middleman in the transaction.
4. The acquiring bank requests the issuing bank if there is funds available on the card.
5. The issuing bank sets aside the amount of money required, and the approval response flows back to the merchant about the status the payment.
6. The merchant receives the approval response, if its approved the transaction is approved and the funds will be transferred to the merchant.
  - If the transaction is denied the order will be dismissed.
7. The consumer is informed by the merchant about the success or failure of the transaction by the merchant.
  - At the same time the consumer receives the information about the success or failure from his bank.

### Acquirer, Sub-Acquirer and Payment Gateway

- An **Acquirer** is a company that specializes in processing payments. A merchant will contract an acquirer to be able to process payments.
- A **Sub-Acquirer** is a company that processes the payment and transmits the generated data to other players in the payment flow, working together with the acquirer, can be seen as a intermediary player between the acquirer and the merchant.
- A **Payment Gateway** is how the merchant will communicate with the acquirer, making it able to follow the payment approval flow.

### Chargebacks vs Cancellations vs Refunds

- A cancellation occurs when the payment is still pending and the **merchant or consumer** wishes to cancel the payment
- A refund occurs when the **merchant** gives the money back to the consumer after the return of a product or dissatisfaction with a service
- A chargeback occurs when the **bank or card issuer** gives the credit to the consumer, typically happening when there is some dispute or fraudulent action related to the original purchase.

## Analyzing the transactional data

1. The table lists lots of transactions, many of them in rapid succession, for various (some times repeated) users
  - Some closely made transactions are made by the same user from the same device, which may be a signal of fraudulent transactions.
  - Some of the the transactions (for example lines 9 to 11) have chargebacks, which may be the result of fraudulent transactions (stolen credit card maybe?).
  - Some transactions seem repeated, other than the amount.
  - Some transactions have chargeback but are seemly isolated.

2. Other data that maybe can help in detecting frauds can be:
  - A user make a transaction with low amounts suddenly making lots transactions with big amounts
  - Seemly equal transactions in a short time

## Solving the problem

### Objective

This project has the object to create a minimum viable product (MVP) of a transaction approve system, given the conditions stated for the Cloudwalk Technical Test. 

### Description

Given the minimal product nature of this project, it was opted to create a "skeleton" of what a real project would look like, but created in a way that its modulated enough to insert new features without having to refactor too much of the code.

This project was created with microservices in mind, so instead of having to respond to outside API requests, it responds to the internal company requests, this choice was made with security in mind (it would be harder to access this application outside the company internal network), but it also has a security token system.

#### Security

The security method applied is a authentication token, but it can be replaced with any other authentication method (e.g. [JWT](https://jwt.io/)), given the internal nature of the project it can also be protected by the server itself (using [NGINX](https://www.nginx.com/) for example) so it can only receive requests from selected servers.

#### Architecture

For this project Sinatra was chosen because it offers a lightweight way to construct an API, and with the help of PostgreSQL and ActionModels a database can be created.

##### Database

The database contains 2 models:

- A transaction model for storing transaction, it has all info the comes with the payload plus:
  - A `score` to store the "validation score" of the model, it can be used further in to check if a transaction is close to dangerous and can be flagged, or refused all together.
  - A `chargeback` field that can be set later, it helps with the "has no previous chargeback" validation
- A configuration model to store configurations for the project, like max nightly amount or how many transactions a user can make in a row in a short period of time

##### Routes

- The base route (`/`) can receive a `POST` method with the transaction payload, and it will respond if the transaction shall be approved, flagged or refused
- The configuration route (`/configuration`) can receive a `POST` to create a new configuration
- The chargeback route (`/chargeback`) can receive a `PUT` with the `transaction_id` and a boolean `chargeback` value so it can flag a specific transaction as having a chargeback

### Running the application

The application is made with [Docker](https://www.docker.com/) in mind, but it can also run without Docker, PostgresSQL must be installed to run without it

#### Running the application with Docker

1. Build the docker container

```bash
docker-compose build
```

2. Configure Database

```bash
docker-compose run api rake db:reset
```

3. Start the application

```bash
docker-compose up 
```

Server will then be available at `0.0.0.0:3000`

#### Running the application without Docker

Make sure PostgresSql is installed

1. Install gems

```bash
bundle install
```

2. Configure Database

```bash
rake db:reset
```

3. Start the application

```bash
rake server
```

Server will then be available at `0.0.0.0:3000`

### Tests

There are several tests in the `/tests` folder

#### Run tests with Docker

```
docker-compose run api rake test
```

#### Run tests without Docker

```
rake test
```

### Running stress test

Given the `transactional-sample.csv`, we can run a stress test:

1. Given the CSV never changes, we need to reset database so there is no garbage data


```bash
docker-compose run api rake db:reset
```

or

```bash
rake db:reset
```

2. Run the server

3. In another terminal run

```bash
time ruby transactional_test.rb
```

At the end it will show some stats of the stress run
