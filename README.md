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