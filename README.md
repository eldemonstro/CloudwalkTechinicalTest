# Cloudwalk Technical Test

## Objective

This project has the object to create a minimum viable product (MVP) of a transaction approve system, given the conditions stated for the Cloudwalk Technical Test. 

## Description

Given the minimal product nature of this project, it was opted to create a "skeleton" of what a real project would look like, but created in a way that its modulated enough to insert new features without having to refactor too much of the code.

This project was created with microservices in mind, so instead of having to respond to outside API requests, it responds to the internal company requests, this choice was made with security in mind (it would be harder to access this application outside the company internal network), but it also has a security token system.

### Security

The security method applied is a authentication token, but it can be replaced with any other authentication method (e.g. [JWT](https://jwt.io/)), given the internal nature of the project it can also be protected by the server itself (using [NGINX](https://www.nginx.com/) for example) so it can only receive requests from selected servers.

### Architecture

For this project Sinatra was chosen because it offers a lightweight way to construct an API, and with the help of PostgreSQL and ActionModels a database can be created.

#### Database

The database contains 2 models:

- A transaction model for storing transaction, it has all info the comes with the payload plus:
  - A `score` to store the "validation score" of the model, it can be used further in to check if a transaction is close to dangerous and can be flagged, or refused all together.
  - A `chargeback` field that can be set later, it helps with the "has no previous chargeback" validation
- A configuration model to store configurations for the project, like max nightly amount or how many transactions a user can make in a row in a short period of time

#### Routes

- The base route (`/`) can receive a `POST` method with the transaction payload, and it will respond if the transaction shall be approved, flagged or refused
- The configuration route (`/configuration`) can receive a `POST` to create a new configuration
- The chargeback route (`/chargeback`) can receive a `PUT` with the `transaction_id` and a boolean `chargeback` value so it can flag a specific transaction as having a chargeback

## Running the application

The application is made with [Docker](https://www.docker.com/) in mind, but it can also run without Docker, PostgresSQL must be installed to run without it

### Running the application with Docker

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

### Running the application without Docker

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

## Tests

There are several tests in the `/tests` folder

### Run tests with Docker

```
docker-compose run api rake test
```

### Run tests without Docker

```
rake test
```

## Running stress test

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
